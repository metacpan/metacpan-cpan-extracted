package Mojolicious::Plugin::OIDC;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Carp qw(croak);
use Clone qw(clone);
use Scalar::Util qw(blessed);
use Try::Tiny;
use OIDC::Client;
use OIDC::Client::Plugin;
use OIDC::Client::Error::Authentication;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::OIDC - Mojolicious plugin for OIDC protocol integration

=head1 DESCRIPTION

This plugin makes it easy to integrate the OpenID Connect protocol
into a Mojolicious application.

=cut

has '_oidc_config';
has '_oidc_client_by_provider';


=head1 METHODS

=head2 register

Code executed once when the application is loaded.

Depending on the configuration, creates and keeps in memory one or more clients
(L<OIDC::Client> stateless objects) and automatically adds the callback routes
to the application.

=cut

sub register ($self, $app, $config) {

  keys %$config
    or $config = ($app->config->{oidc_client} || {});
  $self->_oidc_config($config);

  my %client_by_provider;
  my %seen_path;

  foreach my $provider (keys %{ $config->{provider} || {} }) {
    my $config_provider = clone($config->{provider}{$provider});
    $config_provider->{provider} = $provider;

    $client_by_provider{$provider} = OIDC::Client->new(
      config => $config_provider,
      log    => $app->log,
    );

    # dynamically add the callback routes to the application
    foreach my $action_type (qw/ login logout /) {
      my $path = $action_type eq 'login' ? $config_provider->{signin_redirect_path}
                                         : $config_provider->{logout_redirect_path};
      next if !$path || $seen_path{$path}++;
      my $method = $action_type eq 'login' ? '_login_callback' : '_logout_callback';
      my $name   = $action_type eq 'login' ? 'oidc_login_callback' : 'oidc_logout_callback';
      $app->routes->any(['GET', 'POST'] => $path => sub { $self->$method(@_) } => $name);
    }
  }
  $self->_oidc_client_by_provider(\%client_by_provider);

  $app->helper('oidc' => sub { $self->_helper_oidc(@_) });
}


=head1 METHODS ADDED TO THE APPLICATION

=head2 oidc( $provider )

  # with just one provider
  my $oidc = $c->oidc;
  # or
  my $oidc = $c->oidc('my_provider');

  # with several providers
  my $oidc = $c->oidc('my_provider_1');

Creates and returns an instance of L<OIDC::Client::Plugin> with the data
from the current request and session.

If several providers are configured, the I<$provider> parameter is mandatory.

This is the application's entry point to the library. Please see the
L<OIDC::Client::Plugin> documentation to find out what methods are available.

=cut

sub _helper_oidc ($self, $c, $provider = undef) {

  my $client = $self->_get_client_for_provider($provider);
  my $plugin = $c->stash->{oidc}{plugin};

  return $plugin
    if $plugin && $plugin->client->provider eq $client->provider;

  $plugin = $c->stash->{oidc}{plugin} = OIDC::Client::Plugin->new(
    log             => $c->log,
    store_mode      => $self->_oidc_config->{store_mode} || 'session',
    request_params  => $c->req->params->to_hash,
    request_headers => $c->req->headers->to_hash,
    session         => $c->session,
    stash           => $c->stash,
    get_flash       => sub { return $c->flash($_[0]); },
    set_flash       => sub { $c->flash($_[0], $_[1]); return; },
    redirect        => sub { $c->redirect_to($_[0]); return; },
    client          => $client,
    base_url        => $c->req->url->base->to_string,
    current_url     => $c->req->url->to_string,
  );

  return $plugin;
}

# code executed on callback after authentication attempt
sub _login_callback ($self, $c) {

  my @providers = keys %{ $self->_oidc_client_by_provider };
  my $provider = @providers == 1 ? $providers[0]
                                 : $c->flash('oidc_provider');
  try {
    $c->oidc($provider)->get_token();
    $c->redirect_to($c->flash('oidc_target_url') || $c->url_for('/'));
  }
  catch {
    my $e = $_;
    die $e unless blessed($e) && $e->isa('OIDC::Client::Error');
    if (my $error_path = $self->_oidc_config->{authentication_error_path}) {
      $c->flash('error_message' => $e->message);
      $c->redirect_to($c->url_for($error_path));
    }
    else {
      OIDC::Client::Error::Authentication->throw($e->message);
    }
  };
}

# code executed on callback after user logout
sub _logout_callback ($self, $c) {

  $c->log->debug('Logging out');
  $c->session(expires => 1);

  $c->redirect_to($c->flash('oidc_target_url') || $c->url_for('/'));
}

sub _get_client_for_provider ($self, $provider) {

  unless ($provider) {
    my @providers = keys %{ $self->_oidc_client_by_provider };
    if (@providers == 1) {
      $provider = $providers[0];
    }
    elsif (@providers > 1) {
      croak(q{OIDC: more than one provider are configured, the provider is mandatory : $c->oidc('my_provider')});
    }
    else {
      croak("OIDC: no provider configured");
    }
  }

  my $client = $self->_oidc_client_by_provider->{$provider}
    or croak("OIDC: no client for provider $provider");

  return $client;
}

=head1 CONFIGURATION

Section to be added to your configuration file :

  oidc_client => {
    provider => {
      provider_name => {
        id                   => 'my-app-id',
        secret               => 'xxxxxxxxx',
        well_known_url       => 'https://yourprovider.com/oauth2/.well-known/openid-configuration',
        signin_redirect_path => '/oidc/login/callback',
        scope                => 'openid profile roles email',
        expiration_leeway    => 20,
        claim_mapping => {
          login     => 'sub',
          lastname  => 'lastName',
          firstname => 'firstName',
          email     => 'email',
          roles     => 'roles',
        },
        audience_alias => {
          other_app_name => {
            audience => 'other-app-audience',
          }
        }
      }
    }
  }

This is an example, see the detailed possibilities in L<OIDC::Client::Config>.

=head1 SAMPLES

Here are some samples by category. Although you will have to adapt them to your needs,
they should be a good starting point.

=head2 Setup

To setup the plugin when the application is launched :

  $app->plugin('OIDC');

=head2 Authentication

To authenticate the end-user :

  $app->hook(before_dispatch => sub {
    my $c = shift;

    my $path = $c->req->url->path;

    # Public routes
    return if $path =~ m[^/oidc/]
           || $path =~ m[^/error/];

    # Authentication
    if (my $identity = $c->oidc->get_stored_identity()) {
      $c->remote_user($identity->{subject});
    }
    elsif (uc($c->req->method) eq 'GET' && !$c->is_ajax_request()) {
      $c->oidc->redirect_to_authorize();
    }
    else {
      $c->render(template => 'error',
                 message  => "You have been logged out. Please try again after refreshing the page.",
                 status   => 401);
    }
  });

=head2 API call

To make an API call with propagation of the security context (token exchange) :

  # Retrieving a web client (Mojo::UserAgent object)
  my $ua = try {
    $c->oidc->build_api_useragent('other_app_name')
  }
  catch {
    $c->log->warn("Unable to exchange token : $_");
    $c->render(template => 'error',
               message  => "Authorization problem. Please try again after refreshing the page.",
               status   => 403);
    return;
  } or return;

  # Usual call to the API
  my $res = $ua->get($url)->result;

=head2 Resource Server

To check an access token from a Resource Server, assuming it's a JWT token.
For example, with an application using L<Mojolicious::Plugin::OpenAPI>, you can
define a security definition that checks that the access token is intended for all
the expected scopes :

  $app->plugin(OpenAPI => {
    url      => "data:///swagger.yaml",
    security => {
      oidc => sub {
        my ($c, $definition, $scopes, $cb) = @_;

        my $claims = try {
          return $c->oidc->verify_token();
        }
        catch {
          $c->log->warn("Token validation : $_");
          return;
        } or return $c->$cb("Invalid or incomplete token");

        foreach my $expected_scope (@$scopes) {
          unless ($c->oidc->has_scope($expected_scope)) {
            return $c->$cb("Insufficient scopes");
          }
        }

        return $c->$cb();
      },
    }
  });

Another security definition that checks that the user has at least
one expected role :

  $app->plugin(OpenAPI => {
    url      => "data:///swagger.yaml",
    security => {
      oidc => sub {
        my ($c, $definition, $roles_to_check, $cb) = @_;

        my $user = try {
          $c->oidc->verify_token();
          return $c->oidc->build_user_from_userinfo();
        }
        catch {
          $c->log->warn("Token/User validation : $_");
          return;
        } or return $c->$cb('Unauthorized');

        foreach my $role_to_check (@$roles_to_check) {
          if ($user->has_role($role_to_check)) {
            return $c->$cb();
          }
        }

        return $c->$cb("Insufficient roles");
      },
    }
  });

=head1 SECURITY RECOMMENDATION

It is highly recommended to configure the framework to store session data,
including sensitive tokens such as access and refresh tokens, on the backend
rather than in client-side cookies. Although cookies can be signed and encrypted,
storing tokens in the client exposes them to potential security threats.

=head1 SEE ALSO

=over 2

=item * L<Mojolicious::Plugin::OAuth2>

=back

=cut

1;
