package Mojolicious::Plugin::Hakkefuin;
use Mojo::Base 'Mojolicious::Plugin';

use CellBIS::Random;
use Mojo::Hakkefuin;
use Mojo::Hakkefuin::Utils;
use Mojo::Hakkefuin::Sessions;
use Mojo::Util qw(secure_compare);

# ABSTRACT: The Minimalistic Mojolicious Authentication
our $VERSION       = '0.1.3';
our $VERSION_STATE = 'Beta';
our $CODENAME      = 'YataMirror';

has mojo_hf => 'Mojo::Hakkefuin';
has utils   => sub {
  state $utils = Mojo::Hakkefuin::Utils->new(random => 'String::Random');
};
has cookies => sub {
  state $cookies = Mojolicious::Plugin::Hakkefuin::_cookies->new(
    utils  => shift->utils,
    random => 'String::Random'
  );
};
has cookies_lock => sub {
  state $cookie = Mojolicious::Plugin::Hakkefuin::_cookiesLock->new(
    utils  => shift->utils,
    random => 'String::Random'
  );
};
has random          => 'String::Random';
has crand           => sub { state $crand = CellBIS::Random->new };
has session_manager => sub {undef};

sub register {
  my ($self, $app, $conf) = @_;

  # Helper for version
  $app->helper(
    mojo_version => sub {
      return {
        'num'      => $VERSION,
        'state'    => $VERSION_STATE,
        'codename' => $CODENAME
      };
    }
  );

  # Home Dir
  my $home = $app->home->detect;

  # Check Config
  $conf                    //= {};
  $conf->{'helper.prefix'} //= 'mhf';
  $conf->{'stash.prefix'}  //= 'mhf';
  $conf->{'via'}           //= 'sqlite';
  $conf->{'dir'}           //= 'migrations';
  $conf->{'csrf.name'}     //= 'mhf_csrf_token';
  $conf->{'lock'}          //= 1;
  $conf->{'s.time'}        //= '1w';
  $conf->{'c.time'}        //= '1w';
  $conf->{'cl.time'}       //= '60m';
  $conf->{'callback'}      //= {
    'has_auth' => sub { },
    'sign_in'  => sub { },
    'sign_out' => sub { },
    'lock'     => sub { },
    'unlock'   => sub { }
  };

  my $time_cookies = {
    session => $self->utils->time_convert($conf->{'s.time'}),
    cookies => $self->utils->time_convert($conf->{'c.time'}),
    lock    => $self->utils->time_convert($conf->{'cl.time'}),
  };
  $conf->{'cookies'}
    //= {name => 'clg', path => '/', httponly => 1, secure => 0};
  $conf->{'cookies_lock'}
    //= {name => 'clglc', path => '/', httponly => 1, secure => 0};
  $conf->{'session'}
    //= {cookie_name => '_mhf', cookie_path => '/', secure => 0};
  $conf->{'session'}->{default_expiration} //= $time_cookies->{session};
  $conf->{dir} = $home . '/' . $conf->{'dir'};

  # Build Mojo::Hakkefuin Params
  my @mhf_params
    = $conf->{table_config} && $conf->{migration}
    ? (table_config => $conf->{table_config}, migration => $conf->{migration})
    : (via => $conf->{via}, dir => $conf->{dir});
  push @mhf_params, dir => $conf->{dir};
  push @mhf_params, via => $conf->{via};
  push @mhf_params, dsn => $conf->{dsn} if $conf->{dsn};
  my $mhf = $self->mojo_hf->new(@mhf_params);

  # Build shared sessions manager once
  my $sessions = $self->session_manager;
  unless ($sessions) {
    $sessions = Mojo::Hakkefuin::Sessions->new(%{$conf->{session}});
    $sessions->max_age(1) if $sessions->can('max_age');
    $self->session_manager($sessions);
  }

  # Check Database Migration
  $mhf->check_file_migration();
  $mhf->check_migration();

  # Helper Prefix
  my $pre = $conf->{'helper.prefix'};

  $app->hook(
    after_build_tx => sub {
      my ($tx, $c) = @_;

      # Reuse shared sessions object to avoid per-request allocation
      $c->sessions($sessions) unless $c->sessions && $c->sessions == $sessions;
    }
  );

  $app->helper($pre . '_lock'     => sub { $self->_lock($conf, $mhf, @_) });
  $app->helper($pre . '_unlock'   => sub { $self->_unlock($conf, $mhf, @_) });
  $app->helper($pre . '_signin'   => sub { $self->_sign_in($conf, $mhf, @_) });
  $app->helper($pre . '_signout'  => sub { $self->_sign_out($conf, $mhf, @_) });
  $app->helper($pre . '_has_auth' => sub { $self->_has_auth($conf, $mhf, @_) });
  $app->helper(
    $pre . '_auth_update' => sub { $self->_auth_update($conf, $mhf, @_) });

  $app->helper($pre . '_csrf' => sub { $self->_csrf($conf, @_) });
  $app->helper(
    $pre . '_csrf_regen' => sub { $self->_csrfreset($conf, $mhf, @_) });
  $app->helper($pre . '_csrf_get' => sub { $self->_csrf_get($conf, @_) });
  $app->helper($pre . '_csrf_val' => sub { $self->_csrf_val($conf, @_) });
  $app->helper(mhf_backend        => sub { $mhf->backend });
}

sub _normalize_override {
  my ($self, $opts) = @_;
  return {} unless $opts && ref $opts eq 'HASH';
  return $opts;
}

sub _timeframe {
  my ($self, $conf, $opts) = @_;

  $opts //= {};
  return {
    session => $self->utils->time_convert($opts->{s_time} // $conf->{'s.time'}),
    cookies => $self->utils->time_convert($opts->{c_time} // $conf->{'c.time'}),
    lock => $self->utils->time_convert($opts->{cl_time} // $conf->{'cl.time'}),
  };
}

sub _session_expiration {
  my ($self, $c, $seconds) = @_;
  return unless defined $seconds;
  $c->session(expiration => $seconds);
}

sub _lock {
  my ($self, $conf, $mhf, $c, $identify) = @_;

  return {result => 0, code => 400, data => 'lock disabled'}
    unless $conf->{lock};

  my $check_auth = $self->_has_auth($conf, $mhf, $c);
  return $check_auth
    if $check_auth->{result} == 0 || $check_auth->{result} == 3;
  return {result => 2, code => 423, data => $check_auth->{data}}
    if $check_auth->{result} == 2;    # already locked

  my $backend_id = $c->stash($conf->{'stash.prefix'} . '.backend-id');
  return {result => 0, code => 404, data => 'missing backend id'}
    unless $backend_id;

  my $times    = $self->_timeframe($conf);
  my $seed     = $check_auth->{data}->{cookie};
  my $lock_val = $self->cookies_lock->create($conf, $c, $seed, $times->{lock});

  my $upd_coolock = $mhf->backend->upd_coolock($backend_id, $lock_val);
  my $upd_state   = $mhf->backend->upd_lckstate($backend_id, 1);

  unless ($upd_coolock->{code} == 200 && $upd_state->{code} == 200) {
    $self->cookies_lock->delete($conf, $c);
    $mhf->backend->upd_coolock($backend_id, $check_auth->{data}->{cookie_lock})
      if $check_auth->{data}->{cookie_lock};
    return {result => 0, code => 500, data => 'failed to lock'};
  }

  my $result = {result => 1, code => 200, data => {lock => 1}};
  $conf->{callback}->{lock}->($c, $result)
    if ref $conf->{callback}->{lock} eq 'CODE';
  return $result;
}

sub _unlock {
  my ($self, $conf, $mhf, $c, $identify) = @_;

  return {result => 0, code => 400, data => 'lock disabled'}
    unless $conf->{lock};

  my $check_auth = $self->_has_auth($conf, $mhf, $c);
  return $check_auth
    if $check_auth->{result} == 0 || $check_auth->{result} == 3;

  my $backend_id = $c->stash($conf->{'stash.prefix'} . '.backend-id');
  return {result => 0, code => 404, data => 'missing backend id'}
    unless $backend_id;

  my $lock_cookie = $self->cookies_lock->check($c, $conf);
  my $stored_lock = $check_auth->{data}->{cookie_lock};

  if ($check_auth->{result} == 1) {
    $self->cookies_lock->delete($conf, $c);
    return {result => 1, code => 200, data => {lock => 0}};
  }
  return {result => 0, code => 401, data => 'lock cookie missing'}
    unless $lock_cookie && $stored_lock;
  return {result => 0, code => 401, data => 'lock cookie mismatch'}
    unless secure_compare $lock_cookie, $stored_lock;

  my $upd_coolock = $mhf->backend->upd_coolock($backend_id, 'no_lock');
  my $upd_state   = $mhf->backend->upd_lckstate($backend_id, 0);
  $self->cookies_lock->delete($conf, $c);

  unless ($upd_coolock->{code} == 200 && $upd_state->{code} == 200) {
    return {result => 0, code => 500, data => 'failed to unlock'};
  }

  my $result = {result => 1, code => 200, data => {lock => 0}};
  $conf->{callback}->{unlock}->($c, $result)
    if ref $conf->{callback}->{unlock} eq 'CODE';
  return $result;
}

sub _sign_in {
  my ($self, $conf, $mhf, $c, $identify, $opts) = @_;

  my $override = $self->_normalize_override($opts);
  my $times    = $self->_timeframe($conf, $override);
  my $backend  = $mhf->backend;
  $self->_session_expiration($c, $times->{session});
  $self->cookies_lock->delete($conf, $c);
  my $cv = $self->cookies->create($conf, $c, $times->{cookies});

  return $backend->create($identify, $cv->[0], $cv->[1], $times->{cookies});
}

sub _sign_out {
  my ($self, $conf, $mhf, $c, $identify) = @_;

  # Session Destroy :
  $c->session(expires => 1);

  $self->cookies_lock->delete($conf, $c);
  my $cookie = $self->cookies->delete($conf, $c);
  return $mhf->backend->delete($identify, $cookie);
}

sub _has_auth {
  my ($self, $conf, $mhf, $c) = @_;

  my $result   = {result => 0, code => 404, data => 'empty'};
  my $csrf_get = $conf->{'helper.prefix'} . '_csrf_get';
  my $coo      = $c->cookie($conf->{cookies}->{name});

  return $result unless $coo;

  my $auth_check = $mhf->backend->check(1, $coo);

  if ($auth_check->{result} == 1) {
    my $csrf_ok = secure_compare($auth_check->{data}->{csrf} // '',
      $c->$csrf_get() // '');
    if ($csrf_ok) {
      my $locked = $conf->{lock} ? $auth_check->{data}->{lock} : 0;
      if ($locked) {
        my $lock_cookie = $c->cookie($conf->{cookies_lock}->{name});
        my $match
          = $lock_cookie
          && $auth_check->{data}->{cookie_lock}
          && secure_compare($lock_cookie, $auth_check->{data}->{cookie_lock});
        $result = {
          result      => 2,
          code        => 423,
          data        => $auth_check->{data},
          lock_cookie => $match ? 1 : 0
        };
      }
      else {
        $result = {result => 1, code => 200, data => $auth_check->{data}};
      }
    }
    else {
      $result = {result => 3, code => 406, data => ''};
    }
    $c->stash(
      $conf->{'stash.prefix'} . '.backend-id' => $auth_check->{data}->{id});
    $c->stash(
      $conf->{'stash.prefix'} . '.identify' => $auth_check->{data}->{identify});
    $c->stash(
      $conf->{'stash.prefix'} . '.lock_state' => $auth_check->{data}->{lock});
  }
  return $result;
}

sub _auth_update {
  my ($self, $conf, $mhf, $c, $identify, $opts) = @_;

  my $override = $self->_normalize_override($opts);
  my $times    = $self->_timeframe($conf, $override);

  my $result = {result => 0};
  my $update = $self->cookies->update($conf, $c, 1, $times->{cookies});
  return $result unless $update;

  my $csrf = ref $update->[1] eq 'ARRAY' ? $update->[1]->[1] : $update->[1];
  $result = $mhf->backend->update($identify, $update->[0], $csrf);
  $self->_session_expiration($c, $times->{session});

  return $result;
}

sub _csrf {
  my ($self, $conf, $c) = @_;

  # Generate CSRF Token if not exists
  unless ($c->session($conf->{'csrf.name'})) {
    my $cook = $self->utils->gen_cookie(3);
    my $csrf = $self->crand->random($cook, 2, 3);

    $c->session($conf->{'csrf.name'} => $csrf);
    $c->res->headers->append((uc $conf->{'csrf.name'}) => $csrf);
  }
}

sub _csrfreset {
  my ($self, $conf, $mhf, $c, $id) = @_;

  my $coon = $self->utils->gen_cookie(3);
  my $csrf = $self->crand->random($coon, 2, 3);

  my $result = $mhf->backend->update_csrf($id, $csrf) if $id;

  $c->session($conf->{'csrf.name'} => $csrf);
  $c->res->headers->header((uc $conf->{'csrf.name'}) => $csrf);
  return [$result, $csrf];
}

sub _csrf_get {
  my ($self, $conf, $c) = @_;
  return $c->session($conf->{'csrf.name'})
    || $c->req->headers->header((uc $conf->{'csrf.name'}));
}

sub _csrf_val {
  my ($self, $conf, $c) = @_;

  my $get_csrf    = $c->session($conf->{'csrf.name'});
  my $csrf_header = $c->res->headers->header((uc $conf->{'csrf.name'}));
  return $csrf_header if $csrf_header eq $get_csrf;
}

package Mojolicious::Plugin::Hakkefuin::_cookies;
use Mojo::Base -base;

has 'random';
has 'utils';

sub _cookie_options {
  my ($self, $base, $ttl) = @_;

  my %opts = %{$base || {}};
  if (defined $ttl) {
    $opts{expires} = time + $ttl;
    $opts{max_age} = $ttl;
  }
  return \%opts;
}

sub create {
  my ($self, $conf, $app, $ttl) = @_;

  my $csrf_get = $conf->{'helper.prefix'} . '_csrf_get';
  my $csrf_reg = $conf->{'helper.prefix'} . '_csrf_regen';
  my $csrf     = $app->$csrf_get() || $app->$csrf_reg()->[1];

  my $cookie_key = $conf->{'cookies'}->{name};
  my $cookie_val
    = Mojo::Util::hmac_sha1_sum($self->utils->gen_cookie(5), $csrf);

  my $duration
    = defined $ttl ? $ttl : $self->utils->time_convert($conf->{'c.time'});
  $app->cookie($cookie_key, $cookie_val,
    $self->_cookie_options($conf->{'cookies'}, $duration));
  [$cookie_val, $csrf];
}

sub update {
  my ($self, $conf, $app, $csrf_reset, $ttl) = @_;

  if ($self->check($app, $conf)) {
    my $csrf
      = $conf->{'helper.prefix'} . ($csrf_reset ? '_csrf_regen' : '_csrf_get');
    $csrf = $app->$csrf();

    my $cookie_key = $conf->{'cookies'}->{name};
    my $cookie_val
      = Mojo::Util::hmac_sha1_sum($self->utils->gen_cookie(5), $csrf);
    my $duration
      = defined $ttl ? $ttl : $self->utils->time_convert($conf->{'c.time'});
    $app->cookie($cookie_key, $cookie_val,
      $self->_cookie_options($conf->{'cookies'}, $duration));
    return [$cookie_val, $csrf];
  }
  return undef;
}

sub delete {
  my ($self, $conf, $app) = @_;

  if (my $cookie = $self->check($app, $conf)) {
    $app->cookie($conf->{'cookies'}->{name} => '', {expires => 1});
    return $cookie;
  }
  return undef;
}

sub check {
  my ($self, $app, $conf) = @_;
  return $app->cookie($conf->{'cookies'}->{name});
}

package Mojolicious::Plugin::Hakkefuin::_cookiesLock;
use Mojo::Base -base;

has 'random';
has 'utils';

sub _cookie_options {
  my ($self, $base, $ttl) = @_;

  my %opts = %{$base || {}};
  if (defined $ttl) {
    $opts{expires} = time + $ttl;
    $opts{max_age} = $ttl;
  }
  return \%opts;
}

sub create {
  my ($self, $conf, $app, $seed, $ttl) = @_;

  my $base = $seed || $self->utils->gen_cookie(4);
  my $cookie_val
    = Mojo::Util::hmac_sha1_sum($self->utils->gen_cookie(6), $base);

  my $duration
    = defined $ttl ? $ttl : $self->utils->time_convert($conf->{'cl.time'});
  $app->cookie($conf->{'cookies_lock'}->{name},
    $cookie_val, $self->_cookie_options($conf->{'cookies_lock'}, $duration));
  return $cookie_val;
}

sub update {
  my ($self, $conf, $app, $seed, $ttl) = @_;

  return undef unless $self->check($app, $conf);
  return $self->create($conf, $app, $seed, $ttl);
}

sub delete {
  my ($self, $conf, $app) = @_;

  if ($self->check($app, $conf)) {
    $app->cookie($conf->{'cookies_lock'}->{name} => '', {expires => 1});
    return 1;
  }
  return 0;
}

sub check {
  my ($self, $app, $conf) = @_;
  return $app->cookie($conf->{'cookies_lock'}->{name});
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Hakkefuin - Mojolicious Web Authentication.

=head1 SYNOPSIS

Mojolicious::Lite example (SQLite default):

  use Mojolicious::Lite;

  plugin 'Hakkefuin' => {
    'helper.prefix' => 'fuin',
    'stash.prefix'  => 'fuin',
    via             => 'sqlite',        # or mariadb / pg
    dir             => 'migrations',
    'c.time'        => '1w',            # auth cookie TTL
    's.time'        => '1w',            # session TTL
    'lock'          => 1,               # enable lock/unlock helpers
  };

  post '/login' => sub {
    my $c   = shift;
    my $id  = $c->param('user');
    my $res = $c->fuin_signin($id);
    return $c->render(status => $res->{code}, json => $res);
  };

  # Override cookie/session TTL per request
  post '/login-custom' => sub {
    my $c = shift;
    my $res = $c->fuin_signin($c->param('user'), {c_time => '2h', s_time => '30m'});
    return $c->render(status => $res->{code}, json => $res);
  };

  under sub {
    my $c    = shift;
    my $auth = $c->fuin_has_auth;         # checks cookie+csrf, stashes data
    return $c->render(status => 423, json => $auth) if $auth->{result} == 2;
    return $c->render(status => 401, text => 'Unauthorized')
      unless $auth->{result} == 1;
    $c->fuin_csrf;                        # ensure CSRF is in session/headers
    return 1;
  };

  get '/me' => sub {
    my $c = shift;
    $c->render(json => {user => $c->stash('fuin.identify')});
  };

  # Rotate auth with custom TTLs without re-login
  get '/auth-update-custom' => sub {
    my $c   = shift;
    my $bid = $c->stash('fuin.backend-id');
    my $res = $c->fuin_auth_update($bid, {c_time => '45m', s_time => '20m'});
    $c->render(status => $res->{code}, json => $res);
  };

  post '/logout' => sub {
    my $c   = shift;
    my $res = $c->fuin_signout($c->stash('fuin.identify'));
    $c->render(status => $res->{code}, json => $res);
  };

  app->start;

Mojolicious (non-Lite) menambahkan plugin di dalam C<startup>:

  sub startup {
    my $self = shift;
    $self->plugin(Hakkefuin => { via => 'pg', dir => 'migrations/pg' });
    ...
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::Hakkefuin> is a L<Mojolicious> plugin for
Web Authentication. (Minimalistic and Powerful).

=head1 OPTIONS

=head2 helper.prefix

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'helper.prefix' => 'your_prefix_here'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'helper.prefix' => 'your_prefix_here'
  };

To change prefix of all helpers. By default, C<helper.prefix> is C<mhf>.

=head2 stash.prefix

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'stash.prefix' => 'your_stash_prefix_here'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'stash.prefix' => 'your_stash_prefix_here'
  };

To change prefix of stash. By default, C<stash.prefix> is C<mhf>.

=head2 csrf.name

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'csrf.name' => 'your_csrf_name_here'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'csrf.name' => 'your_csrf_name_here'
  };

To change csrf name in session and HTTP Headers. By default, C<csrf.name>
is C<mhf_csrf_token>.

=head2 via

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    via => 'mariadb', # OR
    via => 'pg'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    via => 'mariadb', # OR
    via => 'pg'
  };

Use one of C<'mariadb'> or C<'pg'> or C<'sqlite'>. (For C<'sqlite'> option
does not need to be specified, as it would by default be using C<'sqlite'>
if option C<via> is not specified).

=head2 dir

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    dir => 'your-custom-dirname-here'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    dir => 'your-custom-dirname-here'
  };

Specified directory for L<Mojolicious::Plugin::Hakkefuin> configure files.

=head2 c.time

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'c.time' => '1w'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'c.time' => '1w'
  };

To set a cookie expires time. By default is 1 week.

=head2 s.time

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    's.time' => '1w'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    's.time' => '1w'
  };

To set a cookie session expires time. By default is 1 week. For more
information of the abbreviation for time C<c.time> and C<s.time> helper,
see L<Mojo::Hakkefuin::Utils>.

=head2 lock

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'lock' => 1
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'lock' => 1
  };

To set C<Lock Screen> feature. By default is 1 (enable). If you won't use
that feature, you can give 0 (disable). This feature is additional
authentication method, beside C<login> and C<logout>. When enabled a
dedicated lock cookie is issued and tracked in the backend.

=head2 cl.time

  # Mojolicious
  $self->plugin('Hakkefuin' => {
    'cl.time' => '60m'
  });

  # Mojolicious Lite
  plugin 'Hakkefuin' => {
    'cl.time' => '60m'
  };

To set cookie lock expires time. By default is 60 minutes for the lock
cookie used by C<mhf_lock>/C<mhf_unlock>.

=head1 HELPERS

By default, prefix for all helpers using C<mhf>, but you can do change that
with option C<helper.prefix>.

=head2 mhf_lock

  $c->mhf_lock() # In the controllers

Helper to lock the current authenticated session; sets lock cookie and
marks backend as locked.

=head2 mhf_unlock

  $c->mhf_unlock(); # In the controllers

Helper to unlock a locked session; clears lock cookie and unlocks backend.

=head2 mhf_signin

  $c->mhf_signin('login-identify') # In the controllers

Helper for action sign-in (login) web application.

=head2 mhf_signout

  $c->mhf_signout('login-identify'); # In the controllers

Helper for action sign-out (logout) web application.

=head2 mhf_auth_update

  $c->mhf_auth_update('login-identify'); # In the controllers

Helper for rotating authentication cookie and CSRF token.

=head2 mhf_has_auth

  $c->mhf_has_auth; # In the controllers

Helper for checking if routes has authenticated.

=head2 mhf_csrf

  $c->mhf_csrf; # In the controllers
  <%= mhf_csrf %> # In the template.

Helper for generate csrf;

=head2 mhf_csrf_val

  $c->mhf_csrf_val; # In the controllers

Helper for comparing stored CSRF (session/header) and returning it when it
matches.

=head2 mhf_csrf_get

  $c->mhf_csrf_get; # In the controllers

Helper for retrieving the stored CSRF token.

=head2 mhf_csrf_regen

  $c->mhf_csrf_regen; # In the controllers

Helper for regenerating CSRF token and returning the new value.

=head2 mhf_backend

  $c->mhf_backend; # In the controllers

Helper for access to backend.

=head1 METHODS

L<Mojolicious::Plugin::Hakkefuin> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<https://github.com/CellBIS/mojo-hakkefuin>,
<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Achmad Yusri Afandi, C<yusrideb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut
