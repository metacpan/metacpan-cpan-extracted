package Local::Mojolicious::Plugin::OIDC;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Carp qw(croak);
use Clone qw(clone);
use Scalar::Util qw(blessed);
use Try::Tiny;
use OIDC::Client;
use OIDC::Client::Plugin;
use OIDC::Client::Error;
use OIDC::Client::Error::Authentication;

has '_oidc_config';
has '_oidc_client_by_provider';

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

sub _helper_oidc ($self, $c, $provider = undef) {

  my $client = $self->_get_client_for_provider($provider);
  my $plugin = $c->stash->{oidc}{plugin};

  return $plugin
    if $plugin && $plugin->client->provider eq $client->provider;

  $plugin = $c->stash->{oidc}{plugin} = OIDC::Client::Plugin->new(
    log             => $c->log,
    request_params  => $c->req->params->to_hash,
    request_headers => $c->req->headers->to_hash,
    session         => $c->session,
    stash           => $c->stash,
    redirect        => sub { $c->redirect_to($_[0]); return; },
    client          => $client,
    base_url        => $c->req->url->base->to_string,
    current_url     => $c->req->url->to_string,
  );

  return $plugin;
}

# code executed on callback after authentication attempt
sub _login_callback ($self, $c) {

  my $auth_data = $self->_get_auth_data($c);

  try {
    $c->oidc($auth_data->{provider})->get_token();
    $c->redirect_to($auth_data->{target_url} || $c->url_for('/'));
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

sub _get_auth_data ($self, $c) {
  my $state = $c->req->param('state')
    or OIDC::Client::Error::Authentication->throw("OIDC: no state parameter in login callback request");

  my $auth_data = $c->session->{oidc_auth}{$state}
    or OIDC::Client::Error::Authentication->throw("OIDC: no authorisation data");

  return $auth_data;
}

# code executed on callback after user logout
sub _logout_callback ($self, $c) {

  $c->log->debug('Logging out');
  my $logout_data = $self->_extract_logout_data($c);

  $c->oidc($logout_data->{provider})->delete_stored_data();

  $c->redirect_to($logout_data->{target_url} || $c->url_for('/'));
}

sub _extract_logout_data ($self, $c) {
  my $state = $c->req->param('state')
    or OIDC::Client::Error->throw("OIDC: no state parameter in logout callback request");

  my $logout_data = delete $c->session->{oidc_logout}{$state}
    or OIDC::Client::Error->throw("OIDC: no logout data");

  return $logout_data;
}

sub _get_client_for_provider ($self, $provider) {
  $provider //= $self->_oidc_config->{default_provider};

  unless (defined $provider) {
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

1;
