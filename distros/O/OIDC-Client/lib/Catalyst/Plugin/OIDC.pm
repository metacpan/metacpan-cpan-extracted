package Catalyst::Plugin::OIDC;
use utf8;
use Moose;
use namespace::autoclean;
with 'Catalyst::ClassData';

use feature 'signatures';
no warnings 'experimental::signatures';

use Catalyst::Action;
use Carp qw(croak);
use Clone qw(clone);
use List::Util qw(first);
use Scalar::Util qw(blessed);
use Try::Tiny;
use OIDC::Client;
use OIDC::Client::Plugin;
use OIDC::Client::Error::Authentication;

=encoding utf8

=head1 NAME

Catalyst::Plugin::OIDC - Catalyst plugin for OIDC protocol integration

=head1 DESCRIPTION

This plugin makes it easy to integrate the OpenID Connect protocol
into a Catalyst application.

=cut

__PACKAGE__->mk_classdata('_oidc_config');
__PACKAGE__->mk_classdata('_oidc_client_by_provider');


=head1 METHODS

=head2 setup_finalize

Code executed once when the application is loaded.

Depending on the configuration, creates and keeps in memory one or more clients
(L<OIDC::Client> stateless objects) and automatically adds the callback routes
to the application.

=cut

sub setup_finalize ($app) {

  my $config = $app->config->{'oidc_client'}
    or croak('no oidc_client config');

  $app->_oidc_config($config);

  my %client_by_provider;
  my %seen_path;

  my $dispatch_path = first { $_->isa('Catalyst::DispatchType::Path') } @{$app->dispatcher->dispatch_types};

  foreach my $provider (keys %{ $config->{provider} || {} }) {
    my $config_provider = clone($config->{provider}{$provider});
    $config_provider->{provider} = $provider;

    $client_by_provider{$provider} = OIDC::Client->new(
      config => $config_provider,
      log    => $app->log,
    );

    # didn't find a better way to dynamically add the callback routes to the application
    my @new_actions;
    foreach my $action_type (qw/ login logout /) {
      my $path = $action_type eq 'login' ? $config_provider->{signin_redirect_path}
                                         : $config_provider->{logout_redirect_path};
      next if !$path || $seen_path{$path}++;
      push @new_actions, Catalyst::Action->new(
        class      => __PACKAGE__,
        namespace  => '',
        code       => $action_type eq 'login' ? \&_oidc_login_callback : \&_oidc_logout_callback,
        name       => "oidc_${action_type}_callback",
        reverse    => "oidc/${action_type}_callback",
        attributes => { Path => [ $path ] },
      );
    }
    $dispatch_path->register($app, $_) for @new_actions;
  }

  $app->_oidc_client_by_provider(\%client_by_provider);
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

sub oidc ($c, $provider = undef) {

  my $client = $c->_oidc_get_client_for_provider($provider);
  my $plugin = $c->stash->{oidc}{plugin};

  return $plugin
    if $plugin && $plugin->client->provider eq $client->provider;

  $plugin = $c->stash->{oidc}{plugin} = OIDC::Client::Plugin->new(
    log             => $c->log,
    store_mode      => $c->_oidc_config->{store_mode} || 'session',
    request_params  => $c->req->params,
    request_headers => { $c->req->headers->flatten },
    session         => $c->session,
    stash           => $c->stash,
    get_flash       => sub { return $c->flash->{$_[0]}; },
    set_flash       => sub { $c->flash->{$_[0]} = $_[1]; return; },
    redirect        => sub { $c->response->redirect($_[0]); return; },
    client          => $client,
    base_url        => $c->req->base->as_string,
    current_url     => $c->req->uri->as_string,
  );

  return $plugin;
}

# code executed on callback after authentication attempt
sub _oidc_login_callback ($self, $c) {

  my @providers = keys %{ $c->_oidc_client_by_provider };
  my $provider = @providers == 1 ? $providers[0]
                                 : $c->flash->{oidc_provider};
  try {
    $c->oidc($provider)->get_token();
    $c->response->redirect($c->flash->{oidc_target_url} || $c->uri_for('/'));
  }
  catch {
    my $e = $_;
    die $e unless blessed($e) && $e->isa('OIDC::Client::Error');
    if (my $error_path = $c->_oidc_config->{authentication_error_path}) {
      $c->flash->{error_message} = $e->message;
      $c->response->redirect($c->uri_for($error_path));
    }
    else {
      OIDC::Client::Error::Authentication->throw($e->message);
    }
  };
}

# code executed on callback after user logout
sub _oidc_logout_callback ($self, $c) {

  $c->log->debug('Logging out');
  $c->delete_session;

  $c->response->redirect($c->flash->{oidc_target_url} || $c->uri_for('/'));
}

sub _oidc_get_client_for_provider ($c, $provider) {

  unless ($provider) {
    my @providers = keys %{ $c->_oidc_client_by_provider };
    if (@providers == 1) {
      $provider = $providers[0];
    }
    elsif (@providers > 1) {
      croak(q{OIDC: more than one provider are configured, the provider is mandatory : $c->oidc('my_provider')});
    }
    else {
      croak("OIDC: no provider is configured");
    }
  }

  my $client = $c->_oidc_client_by_provider->{$provider}
    or croak("OIDC: no client for provider $provider");

  return $client;
}

=head1 CONFIGURATION

Section to be added to your configuration file :

  <oidc_client>
      <provider provider_name>
          id                    my-app-id
          secret                xxxxxxxxx
          well_known_url        https://yourprovider.com/oauth2/.well-known/openid-configuration
          signin_redirect_path  /oidc/login/callback
          scope                 openid profile email
          expiration_leeway     20
          <claim_mapping>
              login      sub
              lastname   lastName
              firstname  firstName
              email      email
              roles      roles
          </claim_mapping>
          <audience_alias other_app_name>
              audience    other-app-audience
          </audience_alias>
      </provider>
  </oidc_client>

This is an example, see the detailed possibilities in L<OIDC::Client::Config>.

=head1 SAMPLES

Here are some samples by category. Although you will have to adapt them to your needs,
they should be a good starting point.

=head2 Setup

To setup the plugin when the application is launched :

  my @plugin = (
    ...
    'OIDC',
  );
  __PACKAGE__->setup(@plugin);

=head2 Authentication

To authenticate the end-user :

  if (my $identity = $c->oidc->get_stored_identity()) {
    $c->request->remote_user($identity->{subject});
  }
  elsif (uc($c->request->method) eq 'GET' && !$c->is_ajax_request()) {
    $c->oidc->redirect_to_authorize();
  }
  else {
    MyApp::Exception::Authentication->throw(
      error => "You have been logged out. Please try again after refreshing the page.",
    );
  }

=head2 API call

To make an API call with propagation of the security context (token exchange) :

  # Retrieving a web client (Mojo::UserAgent object)
  my $ua = try {
    $c->oidc->build_api_useragent('other_app_name')
  }
  catch {
    $c->log->warn("Unable to exchange token : $_");
    MyApp::Exception::Authorization->throw(
      error => "Authorization problem. Please try again after refreshing the page.",
    );
  };

  # Usual call to the API
  my $res = $ua->get($url)->result;

=head1 SECURITY RECOMMENDATION

It is highly recommended to configure the framework to store session data,
including sensitive tokens such as access and refresh tokens, on the backend
rather than in client-side cookies. Although cookies can be signed and encrypted,
storing tokens in the client exposes them to potential security threats.

=cut

__PACKAGE__->meta->make_immutable;

1;
