package Net::Heroku;
use Mojo::Base -base;
use Net::Heroku::UserAgent;
use Mojo::JSON;
use Mojo::Util 'url_escape';

our $VERSION = 0.10;

has host => 'api.heroku.com';
has ua => sub { Net::Heroku::UserAgent->new(host => shift->host) };
has 'api_key';

sub new {
  my $self   = shift->SUPER::new(@_);
  my %params = @_;

  # Assume email & pass
  $self->ua->api_key(
    defined $params{email}
    ? $self->_retrieve_api_key(@params{qw/ email password /})
    : $params{api_key} ? $params{api_key}
    :                    ''
  );

  return $self;
}

sub error {
  my $self = shift;
  my $res  = $self->ua->tx->res;

  return if $res->code =~ /^2\d{2}$/;

  return (
    code    => $res->code,
    message => ($res->json ? $res->json->{error} : $res->body)
  );
}

sub _retrieve_api_key {
  my ($self, $email, $password) = @_;

  return $self->ua->post(
    '/login' => form => {email => $email, password => $password})
    ->res->json('/api_key');
}

sub apps {
  my ($self, $name) = @_;

  return @{$self->ua->get('/apps')->res->json || []};
}

sub app_created {
  my ($self, %params) = (shift, @_);

  return 1
    if $self->ua->put('/apps/' . $params{name} . '/status')->res->code == 201;
}

sub destroy {
  my ($self, %params) = @_;

  my $res = $self->ua->delete('/apps/' . $params{name})->res;
  return 1 if $res->{code} == 200;
}

sub create {
  my ($self, %params) = (shift, @_);

  # Empty space names no longer allowed
  #delete $params{name} if !$params{name};

  my @ar = map +("app[$_]" => $params{$_}) => keys %params;
  %params = (
    'app[stack]' => 'cedar',
    @ar,
  );

  my $res = $self->ua->post('/apps' => form => \%params)->res;

  return $res->json && $res->code == 202 ? %{$res->json} : ();
}

sub add_config {
  my ($self, %params) = (shift, @_);

  return %{$self->ua->put(
          '/apps/'
        . (defined $params{name} and delete($params{name}))
        . '/config_vars' => Mojo::JSON->new->encode(\%params)
      )->res->json
      || {}
  };
}

sub config {
  my ($self, %params) = (shift, @_);

  return
    %{$self->ua->get('/apps/' . $params{name} . '/config_vars')->res->json
      || []};
}

sub add_key {
  my ($self, %params) = (shift, @_);

  return 1
    if $self->ua->post('/user/keys' => $params{key})->res->{code} == 200;
}

sub keys {
  my ($self, %params) = (shift, @_);

  return @{$self->ua->get('/user/keys')->res->json || []};
}

sub remove_key {
  my ($self, %params) = (shift, @_);

  my $res =
    $self->ua->delete('/user/keys/' . url_escape($params{key_name}))->res;
  return 1 if $res->{code} == 200;
}

sub ps {
  my ($self, %params) = (shift, @_);

  return @{$self->ua->get('/apps/' . $params{name} . '/ps')->res->json || []};
}

sub run {
  my ($self, %params) = (shift, @_);

  return
    %{$self->ua->post('/apps/' . $params{name} . '/ps' => form => \%params)
      ->res->json || {}};
}

sub restart {
  my ($self, %params) = (shift, @_);

  return 1
    if $self->ua->post(
    '/apps/' . $params{name} . '/ps/restart' => form => \%params)->res->code
    == 200;
}

sub stop {
  my ($self, %params) = (shift, @_);

  return 1
    if $self->ua->post(
    '/apps/' . $params{name} . '/ps/stop' => form => \%params)->res->code
    == 200;
}

sub releases {
  my ($self, %params) = (shift, @_);

  my $url =
      '/apps/'
    . $params{name}
    . '/releases'
    . ($params{release} ? '/' . $params{release} : '');

  my $releases = $self->ua->get($url)->res->json || [];

  return $params{release} ? %$releases : @$releases;
}

sub rollback {
  my ($self, %params) = (shift, @_);

  $params{rollback} = delete $params{release};

  return $params{rollback}
    if $self->ua->post(
    '/apps/' . $params{name} . '/releases' => form => \%params)->res->code
    == 200;
}

sub add_domain {
  my ($self, %params) = (shift, @_);

  my $url = '/apps/' . $params{name} . '/domains';

  return 1
    if $self->ua->post(
    $url => form => {'domain_name[domain]' => $params{domain}})->res->code
    == 200;
}

sub domains {
  my ($self, %params) = (shift, @_);

  my $url = '/apps/' . $params{name} . '/domains';

  return @{$self->ua->get($url)->res->json || []};
}

sub remove_domain {
  my ($self, %params) = (shift, @_);

  return 1
    if $self->ua->delete(
    '/apps/' . $params{name} . '/domains/' . url_escape($params{domain}))
    ->res->code == 200;
}

1;

=head1 NAME

Net::Heroku - Heroku API

=head1 DESCRIPTION

Heroku API

Requires Heroku account - free @ L<http://heroku.com>

=head1 USAGE

    my $h = Net::Heroku->new(api_key => api_key);
    - or -
    my $h = Net::Heroku->new(email => $email, password => $password);

    my %res = $h->create;

    $h->add_config(name => $res{name}, BUILDPACK_URL => ...);
    $h->restart(name => $res{name});

    say $_->{name} for $h->apps;

    $h->destroy(name => $res{name});


    warn 'Error:' . $h->error                     # Error: App not found.
      if not $h->destroy(name => $res{name});

    if (!$h->destroy(name => $res{name})) {
      my %err = $h->error;
      warn "$err{code}, $err{message}";           # 404, App not found.
    }

=head1 METHODS

=head2 new

    my $h = Net::Heroku->new(api_key => $api_key);
    - or -
    my $h = Net::Heroku->new(email => $email, password => $password);

Requires api key or user/pass. Returns Net::Heroku object.

=head2 apps

    my @apps = $h->apps;

Returns list of hash references with app information

=head2 destroy

    my $bool = $h->destroy(name => $name);

Requires app name.  Destroys app.  Returns true if successful.

=head2 create

    my $app = $h->create;

Creates a Heroku app.  Accepts optional hash list as values, returns hash list.  Returns empty list on failure.

=head2 add_config

    my %config = $h->add_config(name => $name, config_key => $config_value);

Requires app name.  Adds config variables passed in hash list.  Returns hash config.

=head2 config

    my %config = $h->config(name => $name);

Requires app name.  Returns hash reference of config variables.

=head2 add_key

    my $bool = $h->add_key(key => ...);

Requires key.  Adds ssh public key.

=head2 keys

    my @keys = $h->keys;

Returns list of keys

=head2 remove_key

    my $bool = $h->remove_key(key_name => $key_name);

Requires name associated with key.  Removes key.

=head2 ps

    my @processes = $h->ps(name => $name);

Requires app name.  Returns list of processes.

=head2 run

    my $process = $h->run(name => $name, command => $command);

Requires app name and command.  Runs command once.  Returns hash response.

=head2 restart

    my $bool = $h->restart(name => $name);
    my $bool = $h->restart(name => $name, ps => $ps, type => $type);

Requires app name.  Restarts app.  If ps is supplied, only process is restarted.

=head2 stop

    my $bool = $h->stop(name => $name, ps => $ps, type => $type);

Requires app name.  Stop app process.

=head2 releases

    my @releases = $h->releases(name => $name);
    my %release  = $h->releases(name => $name, release => $release);

Requires app name.  Returns list of hashrefs.
If release name specified, returns hash.

=head2 add_domain

    my $bool = $h->add_domain(name => $name, domain => $domain);

Requires app name.  Adds domain.

=head2 domains

    my @domains = $h->domains(name => $name);

Requires app name.  Returns list of hashrefs describing assigned domains.

=head2 remove_domain

    my $bool = $h->remove_domain(name => $name, domain => $domain);

Requires app name associated with domain.  Removes domain.

=head2 rollback

    my $bool = $h->rollback(name => $name, release => $release);

Rolls back to a specified releases

=head2 error

    my $message = $h->error;
    my %err     = $h->error;

In scalar context, returns error message from last request

In list context, returns hash with keys: code, message.

If the last request was successful, returns empty list.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<http://mojolicio.us/perldoc/Mojo/UserAgent#DEBUGGING>, L<https://api-docs.heroku.com/>

=head1 SOURCE

L<http://github.com/tempire/net-heroku>

=head1 VERSION

0.10

=head1 AUTHOR

Glen Hinkle C<tempire@cpan.org>

=cut
