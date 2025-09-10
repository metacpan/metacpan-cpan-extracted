package OIDC::Client::Plugin;
use 5.014;
use utf8;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use namespace::autoclean;

use Carp qw(croak);
use Data::UUID;
use List::Util qw(any);
use Module::Load qw(load);
use Mojo::URL;
use Try::Tiny;
use OIDC::Client::AccessToken;
use OIDC::Client::AccessTokenBuilder  qw(build_access_token_from_token_response
                                         build_access_token_from_claims);
use OIDC::Client::ApiUserAgentBuilder qw(build_api_useragent_from_access_token);
use OIDC::Client::Identity;
use OIDC::Client::Error;
use OIDC::Client::Error::Authentication;
use OIDC::Client::Error::Provider;

with 'OIDC::Client::Role::LoggerWrapper';

=encoding utf8

=head1 NAME

OIDC::Client::Plugin - Main module for the plugins

=head1 DESCRIPTION

Main module instanciated for the current request by an application plugin
(for example: L<Mojolicious::Plugin::OIDC>).

It contains all the methods available in the application.

=cut

enum 'RedirectType' => [qw/login logout/];

has 'request_params' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

has 'request_headers' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

has 'session' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

has 'stash' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

has 'redirect' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has 'client' => (
  is       => 'ro',
  isa      => 'OIDC::Client',
  required => 1,
);

has 'base_url' => (
  is       => 'ro',
  isa      => subtype(as 'Str', where { /^http/ || /^$/ }),
  required => 1,
);

has 'current_url' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'uuid_generator' => (
  is      => 'ro',
  isa     => 'Data::UUID',
  default => sub { Data::UUID->new() },
);

has 'login_redirect_uri' => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  builder => '_build_login_redirect_uri',
);

has 'logout_redirect_uri' => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  builder => '_build_logout_redirect_uri',
);

has 'is_base_url_local' => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  builder => '_build_is_base_url_local',
);

sub _build_is_base_url_local   { return shift->base_url =~ m[^http://localhost\b] }
sub _build_login_redirect_uri  { return shift->_build_redirect_uri_from_path('login') }
sub _build_logout_redirect_uri { return shift->_build_redirect_uri_from_path('logout') }

sub _build_redirect_uri_from_path {
  my $self = shift;
  my ($redirect_type) = pos_validated_list(\@_, { isa => 'RedirectType', optional => 0 });

  my $config_entry = $redirect_type eq 'login' ? 'signin_redirect_path'
                                               : 'logout_redirect_path';

  my $redirect_path = $self->client->config->{$config_entry}
    or return;

  my $base = Mojo::URL->new($self->base_url);

  return Mojo::URL->new($redirect_path)->base($base)->to_abs()->to_string();
}


=head1 METHODS

=head2 redirect_to_authorize( %args )

  $c->oidc->redirect_to_authorize();

Redirect the browser to the authorize URL to initiate an authorization code flow.
The C<state> parameter contains a generated UUID but other data can be added.

The optional hash parameters are:

=over 2

=item target_url

Specifies the URL to redirect to at the end of the authorization code flow.
Default to the current URL (attribute C<current_url>).

=item redirect_uri

Specifies the URL that the provider uses to redirect the user's browser back to
the application after the user has been authenticated.
Default to the URL built from the C<signin_redirect_path> configuration entry.

=item extra_params

Hashref which can be used to send extra query parameters.

=item other_state_params

List (arrayref) of strings to add before the auto-generated UUID string to build
the C<state> parameter. All these strings are separated by a comma.

=back

=cut

sub redirect_to_authorize {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    target_url         => { isa => 'Str', optional => 1 },
    redirect_uri       => { isa => 'Str', optional => 1 },
    extra_params       => { isa => 'HashRef', optional => 1 },
    other_state_params => { isa => 'ArrayRef[Str]', optional => 1 },
  );

  my $nonce = $self->_generate_uuid_string();
  my $state = join ',', (@{$params{other_state_params} || []}, $self->_generate_uuid_string());

  my %args = (
    nonce => $nonce,
    state => $state,
  );

  if (my $redirect_uri = $params{redirect_uri} || $self->login_redirect_uri) {
    $args{redirect_uri} = $redirect_uri;
  }

  if (my $extra_params = $params{extra_params}) {
    $args{extra_params} = $extra_params;
  }

  my $authorize_url = $self->client->auth_url(%args);

  $self->session->{oidc_auth}{$state} = {
    nonce      => $nonce,
    provider   => $self->client->provider,
    target_url => $params{target_url} ? $params{target_url}
                                      : $self->current_url,
  };

  $self->log_msg(debug => "OIDC: redirecting to provider : $authorize_url");
  $self->redirect->($authorize_url);
}


=head2 get_token( %args )

  my $identity = $c->oidc->get_token();

Checks that the state parameter received from the provider is identical
to the state parameter sent with the authorize URL.

From a code received from the provider, executes a request to get the token(s).

Checks the ID token if present and stores the token(s) in the session by default or stash
depending on your configured C<store_mode> (see L<OIDC::Client::Config>).

Returns the stored L<OIDC::Client::Identity> object.

The optional hash parameters are:

=over 2

=item redirect_uri

Specifies the URL that the provider uses to redirect the user's browser back to
the application after the user has been authenticated.
Default to the URL built from the C<signin_redirect_path> configuration entry.

=back

=cut

sub get_token {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    redirect_uri => { isa => 'Str', optional => 1 },
  );

  $self->log_msg(debug => 'OIDC: getting token');

  if ($self->request_params->{error}) {
    OIDC::Client::Error::Provider->throw({response_parameters => $self->request_params});
  }

  my $auth_data = $self->_extract_auth_data();

  my $redirect_uri = $params{redirect_uri} || $self->login_redirect_uri;

  my $token_response = $self->client->get_token(
    code => $self->request_params->{code},
    $redirect_uri ? (redirect_uri => $redirect_uri) : (),
  );

  if (my $id_token = $token_response->id_token) {
    my $claims_id_token = $self->client->verify_token(
      token             => $id_token,
      expected_audience => $self->client->id,
      expected_nonce    => $auth_data->{nonce},
    );
    $self->_store_identity(
      id_token => $id_token,
      claims   => $claims_id_token,
    );
    $self->log_msg(debug => "OIDC: identity has been stored");
  }
  elsif (($self->client->config->{scope} || '') =~ /\bopenid\b/) {
    OIDC::Client::Error::Authentication->throw(
      "OIDC: no ID token returned by the provider ?"
    );
  }

  if ($token_response->access_token) {
    my $access_token = build_access_token_from_token_response($token_response);
    $self->store_access_token($access_token);
    $self->log_msg(debug => "OIDC: access token has been stored");
  }

  if (my $refresh_token = $token_response->refresh_token) {
    $self->store_refresh_token($refresh_token);
    $self->log_msg(debug => "OIDC: refresh token has been stored");
  }

  return $self->get_stored_identity();
}


=head2 refresh_token( $audience_alias )

  my $stored_access_token = $c->oidc->refresh_token( $audience_alias );

Refreshes an access and/or ID token (usually because it has expired) for the default audience
(token for the current application) or for the audience corresponding to a given alias
(exchanged token for another application).

Stores the renewed token(s) and returns the new L<OIDC::Client::AccessToken> object.

Throws an error if no refresh token has been stored for the audience.

The optional list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

=cut

sub refresh_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->client->get_audience_for_alias($audience_alias)
                                 : $self->client->audience
    or croak("OIDC: no audience for alias '$audience_alias'");

  $self->log_msg(debug => "OIDC: refreshing token for audience $audience");

  my $refresh_token = $self->get_stored_refresh_token($audience_alias)
    or OIDC::Client::Error->throw("OIDC: no refresh token has been stored");

  my $token_response = $self->client->get_token(
    grant_type    => 'refresh_token',
    refresh_token => $refresh_token,
  );

  if (my $id_token = $token_response->id_token) {
    my $identity = $self->get_stored_identity()
      or OIDC::Client::Error->throw("OIDC: no identity has been stored");
    my $claims_id_token = $self->client->verify_token(
      token             => $id_token,
      expected_audience => $self->client->id,
      expected_nonce    => $identity->claims->{nonce},
    );
    $self->_store_identity(
      id_token => $id_token,
      claims   => $claims_id_token,
    );
    $self->log_msg(debug => "OIDC: identity has been renewed and stored");
  }

  if ($token_response->access_token) {
    my $access_token = build_access_token_from_token_response($token_response);
    $self->store_access_token($access_token, $audience_alias);
    $self->log_msg(debug => "OIDC: access token has been renewed and stored");
  }

  if (my $refresh_token = $token_response->refresh_token) {
    $self->store_refresh_token($refresh_token, $audience_alias);
    $self->log_msg(debug => "OIDC: refresh token has been renewed and stored");
  }

  return $self->get_stored_access_token($audience_alias);
}


=head2 exchange_token( $audience_alias )

  my $stored_exchanged_token = $c->oidc->exchange_token($audience_alias);

Exchange the access token received during the user's login, for an access token
that is accepted by a different OIDC application and stores it.

Stores and returns an L<OIDC::Client::AccessToken> object.

The list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

=cut

sub exchange_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  $self->log_msg(debug => 'OIDC: exchanging token');

  my $audience = $self->_get_audience_from_alias($audience_alias);

  my $access_token = $self->get_valid_access_token();

  my $exchanged_token_response = $self->client->exchange_token(
    token    => $access_token->token,
    audience => $audience,
  );

  my $exchanged_access_token = build_access_token_from_token_response($exchanged_token_response);
  $self->store_access_token($exchanged_access_token, $audience_alias);
  $self->log_msg(debug => "OIDC: access token has been exchanged and stored");

  $self->store_refresh_token($exchanged_token_response->refresh_token, $audience_alias);

  return $exchanged_access_token;
}


=head2 verify_token()

  my $access_token = $c->oidc->verify_token();

Verifies the JWT access token received in the Authorization header of the current request.
Throws an exception if an error occurs. Otherwise, stores an L<OIDC::Client::AccessToken> object
and returns the claims.

To bypass the token verification in local environment, you can configure the C<mocked_access_token>
entry (hashref) to be used to create an L<OIDC::Client::AccessToken> object that will be returned
by this method.

=cut

sub verify_token {
  my $self = shift;

  if ($self->is_base_url_local and my $mocked_access_token = $self->client->config->{mocked_access_token}) {
    return OIDC::Client::AccessToken->new($mocked_access_token);
  }

  my $token = $self->get_token_from_authorization_header()
    or OIDC::Client::Error->throw("OIDC: no token in authorization header");

  my $claims = $self->client->verify_token(token => $token);

  my $access_token = build_access_token_from_claims($claims, $token);
  $self->store_access_token($access_token);

  return $access_token;
}


=head2 get_token_from_authorization_header()

  my $token = $c->oidc->get_token_from_authorization_header();

Returns the token received in the Authorization header of the current request,
or returns undef if there is no token in this header.

=cut

sub get_token_from_authorization_header {
  my $self = shift;

  my $authorization = $self->request_headers->{Authorization}
    or return;

  my $token_type = $self->client->default_token_type;

  my ($token) = $authorization =~ /^$token_type\s+([^\s]+)/i;

  return $token;
}


=head2 get_userinfo()

  my $userinfo = $c->oidc->get_userinfo();

Returns the user informations from the userinfo endpoint.

This method should only be invoked when an access token has been stored.

To mock the userinfo returned by this method in local environment, you can configure
the C<mocked_userinfo> entry (hashref).

=cut

sub get_userinfo {
  my $self = shift;

  if ($self->is_base_url_local and my $mocked_userinfo = $self->client->config->{mocked_userinfo}) {
    return $mocked_userinfo;
  }

  my $stored_access_token = $self->get_valid_access_token();

  return $self->client->get_userinfo(
    access_token => $stored_access_token->token,
    token_type   => $stored_access_token->token_type,
  );
}


=head2 build_user_from_userinfo( $user_class )

  my $user = $c->oidc->build_user_from_userinfo();

Gets the user informations calling the provider (see L</"get_userinfo()">)
and returns a user object (L<OIDC::Client::User> by default) from this user
informations.

The C<claim_mapping> configuration entry is used to map user information to
user attributes.

The optional list parameters are:

=over 2

=item user_class

Class to be used to instantiate the user object.
Default to L<OIDC::Client::User>.

=back

=cut

sub build_user_from_userinfo {
  my $self = shift;
  my ($user_class) = pos_validated_list(\@_, { isa => 'Str', default => 'OIDC::Client::User' });

  my $userinfo = $self->get_userinfo();

  return $self->build_user_from_claims($userinfo, $user_class);
}


=head2 build_user_from_claims( $claims, $user_class )

  my $user = $c->oidc->build_user_from_claims($claims);

Returns a user object (L<OIDC::Client::User> by default) based on provided claims.

The C<claim_mapping> configuration entry is used to map claim keys to user attributes.

This method can be useful, for example, if the access token is a JWT token that has just been
verified with the L<verify_token()> method and already contains the relevant information
without having to call the C<userinfo> endpoint.

The list parameters are:

=over 2

=item claims

Hashref of claims.

=item user_class

Optional class to be used to instantiate the user object.
Default to L<OIDC::Client::User>.

=back

=cut

sub build_user_from_claims {
  my $self = shift;
  my ($claims, $user_class) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                      { isa => 'Str', default => 'OIDC::Client::User' });
  load($user_class);

  my $mapping     = $self->client->claim_mapping;
  my $role_prefix = $self->client->role_prefix;

  return $user_class->new(
    (
      map { $_ => $claims->{ $mapping->{$_} } }
      grep { exists $claims->{ $mapping->{$_} } }
      keys %$mapping
    ),
    defined $role_prefix ? (role_prefix => $role_prefix) : (),
  );
}


=head2 build_user_from_identity( $user_class )

  my $user = $c->oidc->build_user_from_identity();

Returns a user object (L<OIDC::Client::User> by default) from the claims
of the stored identity.

The C<claim_mapping> configuration entry is used to map identity claim keys
to user attributes.

This method should only be invoked when an identity has been stored, i.e.
when an authorisation flow has completed and an ID token has been returned
by the provider.

The optional list parameters are:

=over 2

=item user_class

Class to be used to instantiate the user object.
Default to L<OIDC::Client::User>.

=back

=cut

sub build_user_from_identity {
  my $self = shift;
  my ($user_class) = pos_validated_list(\@_, { isa => 'Str', default => 'OIDC::Client::User' });
  load($user_class);

  my $identity = $self->get_stored_identity()
    or OIDC::Client::Error->throw("OIDC: no identity has been stored");

  return $self->build_user_from_claims($identity->claims, $user_class);
}


=head2 build_api_useragent( $audience_alias )

  my $ua = $c->oidc->build_api_useragent( $audience_alias );

Builds a web client (L<Mojo::UserAgent> object) to perform requests
on another application with security context propagation.

The appropriate access token will be added in the authorization header
of each request.

The list parameters are:

=over 2

=item audience_alias

Optional alias configured for the audience of the other application.
If this parameter is missing, the default audience (current application) is used.

=back

=cut

sub build_api_useragent {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Str', optional => 1 });

  my $access_token = $self->get_valid_access_token($audience_alias);

  return build_api_useragent_from_access_token($access_token);
}


=head2 redirect_to_logout( %args )

  $c->oidc->redirect_to_logout();

Redirect the browser to the logout URL.

The optional hash parameters are:

=over 2

=item with_id_token

Specifies whether the stored id token should be sent to the provider.

=item target_url

Specifies the URL to redirect to after the browser is redirected to the logout
callback URL.

=item post_logout_redirect_uri

Specifies the URL that the provider uses to redirect the user's browser back to
the application after the logout has been performed.
Default to the URL built from the C<logout_redirect_path> configuration entry.

=item extra_params

Hashref which can be used to send extra query parameters.

=item other_state_params

List (arrayref) of strings to add before the auto-generated UUID string to build
the C<state> parameter. All these strings are separated by a comma.

=back

=cut

sub redirect_to_logout {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    with_id_token            => { isa => 'Bool', default => 1 },
    target_url               => { isa => 'Str', optional => 1 },
    post_logout_redirect_uri => { isa => 'Str', optional => 1 },
    extra_params             => { isa => 'HashRef', optional => 1 },
    other_state_params       => { isa => 'ArrayRef[Str]', optional => 1 },
  );

  my $state = join ',', (@{$params{other_state_params} || []}, $self->_generate_uuid_string());

  my %args = (
    state => $state,
  );

  if ($params{with_id_token} // $self->client->config->{logout_with_id_token}) {
    my $identity = $self->get_stored_identity()
      or OIDC::Client::Error->throw("OIDC: no identity has been stored");
    $args{id_token} = $identity->token;
  }

  if (my $redirect_uri = $params{post_logout_redirect_uri} || $self->logout_redirect_uri) {
    $args{post_logout_redirect_uri} = $redirect_uri;
  }

  if (my $extra_params = $params{extra_params}) {
    $args{extra_params} = $extra_params;
  }

  my $logout_url = $self->client->logout_url(%args);

  $self->session->{oidc_logout}{$state} = {
    provider   => $self->client->provider,
    target_url => $params{target_url},
  };

  $self->log_msg(debug => "OIDC: redirecting to idp for log out : $logout_url");
  $self->redirect->($logout_url);
}


=head2 get_valid_access_token( $audience_alias )

  my $valid_access_token = $c->oidc->get_valid_access_token( $audience_alias );

When an audience alias is specified and no access token has been stored for the audience,
returns the execution of the L</"exchange_token( $audience_alias )"> method.

Retrieves the stored L<OIDC::Client::AccessToken> object for the default audience
(current application) or for the audience corresponding to the given alias.

If this token has not expired, returns it, otherwise returns the execution
of the L</"refresh_token( $audience_alias )"> method.

If the refresh failed and the audience alias is specified, finally returns
the execution of the L</"exchange_token( $audience_alias )"> method.

The optional list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

In local environment, if the C<mocked_access_token> entry (hashref) is configured,
it is used to create an L<OIDC::Client::AccessToken> object that will be returned
by this method.

=cut

sub get_valid_access_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $stored_access_token = $self->get_stored_access_token($audience_alias);

  unless ($stored_access_token) {
    if ($audience_alias) {
      return $self->exchange_token($audience_alias);
    }
    else {
      OIDC::Client::Error->throw("OIDC: no access token has been stored");
    }
  }

  my $audience = $audience_alias ? $self->_get_audience_from_alias($audience_alias)
                                 : $self->client->audience;

  unless ($stored_access_token->expires_at) {
    $self->log_msg(debug => "OIDC: no expiration time for the access token with '$audience' audience. Hoping it's still valid.");
    return $stored_access_token;
  }

  if ($stored_access_token->has_expired($self->client->config->{expiration_leeway})) {
    $self->log_msg(debug => "OIDC: access token has expired for audience '$audience'");
    return try {
      $self->refresh_token($audience_alias)
        or OIDC::Client::Error->throw("OIDC: access token has not been refreshed");
    }
    catch {
      $self->log_msg(debug => "OIDC: error refreshing access token for audience '$audience' : $_");
      if ($audience_alias) {
        $self->exchange_token($audience_alias);
      }
      else {
        die $_;
      }
    };
  }
  else {
    $self->log_msg(debug => "OIDC: access token for audience '$audience' has been retrieved from store");
    return $stored_access_token;
  }
}


=head2 get_valid_identity()

  my $identity = $c->oidc->get_valid_identity();

Executes the L</"get_stored_identity()"> method to get the stored
L<OIDC::Client::Identity> object.

Returns undef if no identity has been stored or if the stored identity has expired
including the configured leeway.

Otherwise, returns the stored L<OIDC::Client::Identity> object.

=cut

sub get_valid_identity {
  my $self = shift;

  my $stored_identity = $self->get_stored_identity()
    or return;

  return if $stored_identity->has_expired($self->client->config->{expiration_leeway});

  return $stored_identity;
}


=head2 get_stored_identity()

  my $identity = $c->oidc->get_stored_identity();

Returns undef if no identity has been stored. Otherwise, returns the stored
L<OIDC::Client::Identity> object, even if the identity has expired.

By default, the C<expires_at> attribute comes directly from the C<exp> claim but
if the C<identity_expires_in> configuration entry is specified, it is added to the current
time (when the ID token is retrieved) to force an expiration time.

To bypass the OIDC flow in local environment, you can configure the C<mocked_identity>
entry (hashref) to be used to create an L<OIDC::Client::Identity> object that will
be returned by this method.

=cut

sub get_stored_identity {
  my $self = shift;

  if ($self->is_base_url_local and my $mocked_identity = $self->client->config->{mocked_identity}) {
    return OIDC::Client::Identity->new($mocked_identity);
  }

  my $audience = $self->client->id;
  my $identity = $self->_get_audience_store($audience)->{identity}
    or return;

  return OIDC::Client::Identity->new($identity);
}


sub _store_identity {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    id_token => { isa => 'Str', optional => 0 },
    claims   => { isa => 'HashRef', optional => 0 },
  );

  my $subject = $params{claims}->{sub};
  defined $subject
    or OIDC::Client::Error::Authentication->throw("OIDC: the 'sub' claim is not defined");

  my %identity = (
    subject => $subject,
    claims  => $params{claims},
    token   => $params{id_token},
  );

  my $expires_in = $self->client->config->{identity_expires_in};
  if (defined $expires_in) {
    if ($expires_in != 0) {
      $identity{expires_at} = time + $expires_in;
    }
  }
  else {
    $identity{expires_at} = $params{claims}->{exp}
      or $self->log_msg(warning => "OIDC: no 'exp' claim in the ID token");
  }

  my $audience = $self->client->id;

  # not stored as Identity object because we can't rely on the session engine to preserve its type
  $self->_get_audience_store($audience)->{identity} = \%identity;
}


=head2 get_stored_access_token( $audience_alias )

  my $access_token = $c->oidc->get_stored_access_token();

Returns the stored L<OIDC::Client::AccessToken> object for the specified audience alias,
even if this token has expired.

The optional list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

In local environment, if the C<mocked_access_token> entry (hashref) is configured,
it is used to create an L<OIDC::Client::AccessToken> object that will be returned
by this method.

=cut

sub get_stored_access_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->_get_audience_from_alias($audience_alias)
                                 : $self->client->audience;

  if ($self->is_base_url_local and my $mocked_access_token = $self->client->config->{mocked_access_token}) {
    return OIDC::Client::AccessToken->new($mocked_access_token);
  }

  my $access_token = $self->_get_audience_store($audience)->{access_token}
    or return;

  return OIDC::Client::AccessToken->new($access_token);
}


=head2 store_access_token( $access_token, $audience_alias )

  $c->oidc->store_access_token($access_token);

Stores an L<OIDC::Client::AccessToken> object in the session or stash depending
on your configured C<store_mode> (see L<OIDC::Client::Config>).

=cut

sub store_access_token {
  my $self = shift;
  my ($access_token, $audience_alias) = pos_validated_list(\@_, { isa => 'OIDC::Client::AccessToken', optional => 0 },
                                                                { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->_get_audience_from_alias($audience_alias)
                                 : $self->client->audience;

  # stored as a hashref because we can't rely on the session engine to preserve the object type
  $self->_get_audience_store($audience)->{access_token} = $access_token->to_hashref;
}


=head2 get_stored_refresh_token( $audience_alias )

  my $refresh_token = $c->oidc->get_stored_refresh_token();

Returns the stored refresh token (string) for the specified audience alias.

The optional list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

=cut

sub get_stored_refresh_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->_get_audience_from_alias($audience_alias)
                                 : $self->client->audience;

  return $self->_get_audience_store($audience)->{refresh_token};
}


=head2 store_refresh_token( $refresh_token, $audience_alias )

  $c->oidc->store_refresh_token($refresh_token);

Stores the refresh token (string) in the session or stash depending
on your configured C<store_mode> (see L<OIDC::Client::Config>).

=cut

sub store_refresh_token {
  my $self = shift;
  my ($refresh_token, $audience_alias) = pos_validated_list(\@_, { isa => 'Str', optional => 0 },
                                                                 { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->_get_audience_from_alias($audience_alias)
                                 : $self->client->audience;

  $self->_get_audience_store($audience)->{refresh_token} = $refresh_token;
}


sub _get_audience_from_alias {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $audience = $self->client->get_audience_for_alias($audience_alias)
    or croak("OIDC: no audience for alias '$audience_alias'");

  return $audience;
}


sub _get_values_from_space_delimited_string {
  my $self = shift;
  my ($str) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 0 });
  return [ grep { $_ ne '' } split(/\s+/, $str // '') ];
}


sub _generate_uuid_string {
  my $self = shift;
  return $self->uuid_generator->create_str();
}


sub _extract_auth_data {
  my $self = shift;

  my $state = $self->request_params->{state}
    or OIDC::Client::Error::Authentication->throw("OIDC: no state parameter in request");

  my $auth_data = delete $self->session->{oidc_auth}{$state}
    or OIDC::Client::Error::Authentication->throw("OIDC: no authorisation data for state : '$state'");

  return $auth_data;
}


sub _get_audience_store {
  my $self = shift;
  my ($audience) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $provider = $self->client->provider;

  return $self->_get_store()->{oidc}{provider}{$provider}{audience}{$audience} ||= {};
}


sub _get_store {
  my $self = shift;

  my $store_mode = $self->client->config->{store_mode} || 'session';

  return $store_mode eq 'session' ? $self->session
                                  : $self->stash;
}


=head2 delete_stored_data()

  $c->oidc->delete_stored_data();

Delete the tokens and other data stored in the session or stash depending
on your configured C<store_mode> (see L<OIDC::Client::Config>).

Note that only the data from the current provider is deleted.

=cut

sub delete_stored_data {
  my $self = shift;

  my $provider = $self->client->provider;

  delete $self->_get_store()->{oidc}{provider}{$provider};
}


__PACKAGE__->meta->make_immutable;

1;
