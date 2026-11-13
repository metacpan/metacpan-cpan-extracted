package MojoX::Authentication;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Try::Catch;
use Ouch qw< :trytiny_var >;
use MojoX::Authentication::Model;
use Data::Dumper;
use MojoX::Authentication::Util qw< coercer_for >;

use constant DEFAULT_ROUTE_FOR => {
   ok     => 'protected_root',
   not_ok => 'public_root',
};

use constant DEFAULT_PROVIDER_NAME => 'saml2';

sub logsafe ($str) {
   $str //= '*undef*';
   return ($str =~ s{([^\x20-\x7e])}{sprintf '\\x{%02x}', ord($1)}regmxs);
}

sub truncate_message ($str, $length = 500) {
   return $str if $length <= 3 || length($str) <= $length;
   return substr($str, 0, $length - 3) . '...';
}

use namespace::clean;

has model => (is => 'ro', required => 1,
   coerce
     => coercer_for(authentication_model => 'MojoX::Authentication::Model')
);
has provider_name  => (is => 'ro', default => undef);
has user_stash_key => (is => 'ro', default => 'user');

around BUILDARGS => sub ($orig, $class, @args) {
   my $hash = { @args == 1 ? $args[0]->%* : @args };
   return $hash;
};

sub BUILD ($self, $hash) {
   if (defined(my $app = $hash->{'-startup'})) {
      $self->app_startup($app);
   }
   return $self;
};

sub app_startup ($self, $app) {
   ouch 400, 'undefined application' unless defined($app);

   my $authn = $self->model;

   # add Mojolicious::Plugin::Authentication with the "right" callbacks
   $app->plugin( Authentication => {
      load_user     => sub (@args) { $authn->load_user(@args)     },
      validate_user => sub (@args) { $authn->validate_user(@args) },
   });

   # set a hook to set the user's data in the stash, associated to the
   # requested user_stash_key. This stash key is always set anyway, to
   # avoid errors in the templates in case it's missing
   my $key = $self->user_stash_key;
   $app->hook(
      before_render => sub ($c, $args) {
         my $user = $c->is_user_authenticated ? $c->current_user : undef;
         $c->stash($key => $user);
         return $c;
      }
   );

   return $self;
}

# convention over configuration
sub ctr_credentials_login ($self, $c, $route_for = undef) {
   my $username = $c->param('username');
   try {
      ouch 403, 'bad CSRF token'
         if $c->validation->csrf_protect->has_error('csrf_token');
      my $password = $c->param('password');
      $c->authenticate($username, $password, {}) or die 'whatever';
      $c->log->info(logsafe("login successful (credentials): $username"));
      $c->flash(message => [ info => "Welcome, $username" ]);
      return $c->redirect_to($self->_route_for($route_for, 'ok'));
   }
   catch {
      $username = defined($username) ? qq{'$username'} : '*undef*';
      $c->log->error(logsafe("authentication error (credentials): $username")
         .  bleep());
      $c->flash(message => [ error => 'Authentication error' ]);
      $c->redirect_to($self->_route_for($route_for, 'not_ok'));
   };
   return;
}

sub ctr_logout ($self, $c, $redirect_route = undef) {
   my $csrf_error = $c->validation->csrf_protect->has_error('csrf_token');
   if (! $csrf_error && $c->is_user_authenticated) {
      my $user = $c->current_user;
      $c->log->info(logsafe("logout: $user->{uid}"));

      my $provider = $self->model->provider_named($user->{provider});
      if ($provider && $provider->can('logout')) {
         $provider->logout($c, $user);
      }
      else {
         $c->logout; # just make Mojolicious::Plugin::Authentication happy
      }
   }
   $c->redirect_to($redirect_route) if defined($redirect_route);
   return;
}

sub _get_provider_name ($self, $c) {
   return $self->provider_name
      // $c->param('provider')
      // DEFAULT_PROVIDER_NAME;
}

sub _get_provider ($self, $c) {
   return $self->model->provider_named($self->_get_provider_name($c));
}

sub _route_for ($self, $route_for, $outcome) {
   $route_for //= {};
   return $route_for->{$outcome} // DEFAULT_ROUTE_FOR->{$outcome};
}

sub ctr_saml2_login ($self, $c, $route_for) {
   try {
      my ($id, $url) = $self->_get_provider($c)->idp_login;
      $c->signed_cookie('saml-id' => $id, { path => '/' });
      $c->redirect_to($url);
   }
   catch {
      $c->log->error('ctr_saml2_login error: ' . bleep());
      $c->flash(message => [ error => 'error... ask the administrator!' ]);
      $c->redirect_to($self->_route_for($route_for, 'not_ok'));
   };

   return;
}

sub ctr_saml2_sso_post ($self, $c, $route_for = undef) {
   try {
      (my $saml_id = $c->signed_cookie('saml-id'))
         or ouch 400, 'Not expecting anything SAML-related', 'no id';
      defined(my $saml_response = $c->param('SAMLResponse'))
         or ouch 400, 'No SAMLResponse';

      my $model = $self->model;
      my $provider_name = $self->_get_provider_name($c);
      my $saml2 = $model->provider_named($provider_name)
         or ouch 401, 'unsupported provider';
      my $user = $saml2->parse_assertion($saml_id, $saml_response);
      my $uid = $user->{$saml2->user_key};

      # we're not using credentials here, so "username" and "password" do
      # not make sense. We use "auto_validate" instead and skip
      # validate_user altogether
      my $euid = $model->euid_join($provider_name, $uid);
      $c->authenticate(undef, undef, { auto_validate => $euid });
      $c->log->info(logsafe("login successful (SAML2): $uid"));

      # assuming a convention from consumers to set "fullname", we use it
      # but we fall back to the user identifier, which will always be
      # available
      my $uname = $user->{fullname};
      $uname = $uid unless length($uname // '');
      $c->flash(message => [ info => "Welcome, $uname" ]);

      $c->redirect_to($self->_route_for($route_for, 'ok'));
   }
   catch {
      my $message = bleep() || 'Error: invalid credentials';
      $c->log->error('authentication error (SAML2): '
         . truncate_message(logsafe($message)));

      $message .= ' ' . Dumper($_->data) if eval { $_->isa('Ouch') };
      $c->log->trace('full error: ' . $message);

      $c->flash(message => [ error => 'Authentication error' ]);
      $c->redirect_to($self->_route_for($route_for, 'not_ok'));
   };
   return;
}

1;
