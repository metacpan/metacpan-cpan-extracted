package MojoX::Authentication;
{ our $VERSION = '0.003' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Try::Catch;
use Ouch qw< :trytiny_var >;
use MojoX::Authentication::Model;
use Scalar::Util qw< blessed >;
use Data::Dumper;

use constant DEFAULT_ROUTE_FOR => {
   ok => 'protected_root',
   t_ok => 'public_root',
};

use namespace::clean;

has app   => (is => 'rwp', weak_ref => 1, default => sub { ... });
has model => (is => 'rwp', lazy => 1);
has saml2_provider_name => (is => 'ro', default => 'saml2');
has user_stash_key => (is => 'ro', default => 'user');

# if we're building, we assume that it's in the app. Convention over
# configuration. This is most probably never called actually
sub _build_model ($self) { $self->app->model->authentication }

around BUILDARGS => sub ($orig, $class, @args) {
   my $hash = { @args == 1 ? $args[0]->%* : @args };
   $hash->{model} = MojoX::Authentication::Model->new($hash->{model})
      if exists($hash->{model}) && ! blessed($hash->{model});
   return $hash;
};

sub BUILD ($self, $hash) {
   $self->app_startup if $hash->{'-startup'};
   return $self;
};

sub app_startup ($self, $app = undef) {
   $self->_set_app($app) if defined($app);
   $app = $self->app;
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

sub ctr_logout ($self, $c) {
   return unless $c->is_user_authenticated;

   my $user = $c->current_user;
   $c->log->info("logout: ");

   my $provider = $self->model->provider_named($user->{provider});
   return $provider->logout($c, $user)
      if $provider && $provider->can('logout');

   $c->logout; # just make Mojolicious::Plugin::Authentication happy
   return;
}

# convention over configuration
sub ctr_credentials_login ($self, $c, $route_for = undef) {
   my $username = $c->param('username');
   try {
      my $password = $c->param('password');
      $c->authenticate($username, $password, {}) or die 'whatever';
      $c->log->info("login successful (credentials): $username");
      my $user = $c->current_user;
      $c->log->trace(Dumper($user));
      $c->flash(message => [ info => "Welcome, $username" ]);
      return $c->redirect_to($self->_route_for($route_for, 'ok'));
   }
   catch {
      $username = defined($username) ? qq{'$username'} : '*undef*';
      $c->log->error("authentication error (credentials): $username " .  bleep());
      $c->flash(message => [ error => 'Authentication error' ]);
      $c->redirect_to($self->_route_for($route_for, 'not_ok'));
   };
   return;
}

sub _get_provider ($self, $c) {
   my $pname = $c->param('provider') // $self->saml2_provider_name;
   return $self->model->provider_named($pname);
}

sub _route_for ($self, $route_for, $outcome) {
   $route_for //= {};
   return $route_for->{$outcome} // DEFAULT_ROUTE_FOR->{$outcome};
}

sub ctr_saml2_login ($self, $c, $route_for) {
   try {
      my ($id, $url) = $self->_get_provider($c)->idp_login;
      $c->session->{'saml-id'} = $id;
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

      my $saml2 = $self->_get_provider($c);
      my $user = $saml2->parse_assertion($saml_id, $saml_response);
      my $uid = $user->{$saml2->user_key};

      # we're not using credentials here, so "username" and "password" do
      # not make sense. We use "auto_validate" instead and skip
      # validate_user altogether
      $c->authenticate(undef, undef, { auto_validate => $uid });
      $c->log->info("login successful (SAML2): $uid");
      $c->flash(message => [ info => "Welcome, $user->{fullname}" ]);
      $c->redirect_to($self->_route_for($route_for, 'ok'));
   }
   catch {
      my $message = bleep() || 'Error: invalid credentials';
      $message .= ' ' . Dumper($_->data) if eval { $_->isa('Ouch') };
      $c->log->error('authentication error (SAML2): ' . $message);
      $c->flash(message => [ error => 'Authentication error' ]);
      $c->redirect_to($self->_route_for($route_for, 'not_ok'));
   };
   return;
}

1;
