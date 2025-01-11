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
use OIDC::Client::Error::Authentication;
use OIDC::Client::Error::Provider;

with 'OIDC::Client::Role::LoggerWrapper';

=encoding utf8

=head1 NAME

OIDC::Client::Plugin - Main module for the plugins

=head1 DESCRIPTION

Main module instanciated for the current request by the application plugin
(L<Mojolicious::Plugin::OIDC> or L<Catalyst::Plugin::OIDC>).

It contains all the methods available in the application.

=cut

enum 'RedirectType' => [qw/login logout/];
enum 'StoreMode'    => [qw/session stash/];

has 'store_mode' => (
  is       => 'ro',
  isa      => 'StoreMode',
  required => 1,
);

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

has 'get_flash' => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has 'set_flash' => (
  is       => 'ro',
  isa      => 'CodeRef',
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
  isa      => subtype(as 'Str', where { /^http/ }),
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

List (arrayref) of strings to add to the C<state> parameter.

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

  $self->set_flash->(oidc_nonce      => $nonce);
  $self->set_flash->(oidc_state      => $state);
  $self->set_flash->(oidc_provider   => $self->client->provider);
  $self->set_flash->(oidc_target_url => $params{target_url} ? $params{target_url}
                                                            : $self->current_url);

  $self->log_msg(debug => "OIDC: redirecting to provider : $authorize_url");
  $self->redirect->($authorize_url);
}


=head2 get_token( %args )

  my $identity = $c->oidc->get_token();

Checks that the state parameter received from the provider is identical
to the state parameter sent with the authorize URL.

From a code received from the provider, executes a request to get the token(s).

Checks the ID token if present and stores the token(s) in the session by default or stash
if preferred.

Returns the stored identity object (see L<get_stored_identity> method) for details
of the returned object.

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

  $self->_check_state_parameter();

  my $redirect_uri = $params{redirect_uri} || $self->login_redirect_uri;

  my $token_response = $self->client->get_token(
    code => $self->request_params->{code},
    $redirect_uri ? (redirect_uri => $redirect_uri) : (),
  );

  if (my $id_token = $token_response->id_token) {
    my $claims_id_token = $self->client->verify_token(
      token             => $id_token,
      expected_audience => $self->client->id,
      expected_nonce    => $self->get_flash->('oidc_nonce'),
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

  if (my $access_token = $token_response->access_token) {
    my $expires_at = $self->_get_expiration_time(token_response => $token_response);
    $self->_store_access_token(
      audience      => $self->client->audience,
      access_token  => $access_token,
      refresh_token => $token_response->refresh_token,
      token_type    => $token_response->token_type,
      expires_at    => $expires_at,
    );
    $self->log_msg(debug => "OIDC: access token has been stored");
  }

  return $self->get_stored_identity();
}


=head2 refresh_token( $audience_alias )

  my $stored_access_token = $c->oidc->refresh_token( $audience_alias );

Refreshes a token (usually because it has expired) for the default audience (token
for the current application) or for the audience corresponding to a given alias
(exchanged token for another application). Stores the new access token, replacing
the old one.

Returns the stored access token object. See L<get_valid_access_token> method for details
of the returned object.

Returns undef if no refresh token has been stored for the audience.

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

  $self->log_msg(debug => "OIDC: refreshing access token for audience $audience");

  my $stored_token = $self->_get_stored_access_token($audience)
    or croak("OIDC: no access token has been stored");

  my $refresh_token = $stored_token->{refresh_token};

  unless ($refresh_token) {
    $self->log_msg(debug => "OIDC: no refresh token has been stored");
    return;
  }

  my $token_response = $self->client->get_token(
    grant_type    => 'refresh_token',
    refresh_token => $refresh_token,
  );
  my $expires_at = $self->_get_expiration_time(token_response => $token_response);

  $self->_store_access_token(
    audience      => $audience,
    access_token  => $token_response->access_token,
    refresh_token => $token_response->refresh_token,
    token_type    => $token_response->token_type,
    expires_at    => $expires_at,
  );

  $self->log_msg(debug => "OIDC: token has been refreshed and stored");

  return $self->_get_stored_access_token($audience);
}


=head2 exchange_token( $audience_alias )

  my $stored_exchanged_token = $c->oidc->exchange_token($audience_alias);

Exchange the access token received during the user's login, for an access token
that is accepted by a different OIDC application and stores it.

Returns the stored access token object (see L<get_valid_access_token> method) for details
of the returned object.

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

  my $audience = $self->client->get_audience_for_alias($audience_alias)
    or croak("OIDC: no audience for alias '$audience_alias'");

  my $access_token = $self->get_valid_access_token()
    or croak("OIDC: cannot retrieve the access token");

  my $exchanged_token_response = $self->client->exchange_token(
    token    => $access_token->{token},
    audience => $audience,
  );
  my $expires_at = $self->_get_expiration_time(token_response => $exchanged_token_response);

  $self->_store_access_token(
    audience      => $audience,
    access_token  => $exchanged_token_response->access_token,
    refresh_token => $exchanged_token_response->refresh_token,
    token_type    => $exchanged_token_response->token_type,
    expires_at    => $expires_at,
  );

  $self->log_msg(debug => "OIDC: token has been exchanged and stored");

  return $self->_get_stored_access_token($audience);
}


=head2 verify_token()

  my $claims = $c->oidc->verify_token();

Verifies the JWT access token received in the Authorization header of the current request.
Throws an exception if an error occurs. Otherwise, stores the token and returns the claims.

To bypass the token verification in local environment, you can configure the C<mocked_claims>
entry (hashref) to be returned by this method.

=cut

sub verify_token {
  my $self = shift;

  if ($self->is_base_url_local and my $mocked_claims = $self->client->config->{mocked_claims}) {
    return $mocked_claims;
  }

  my $token = $self->get_token_from_authorization_header()
    or croak("OIDC: no token in authorization header");

  my $claims = $self->client->verify_token(token => $token);

  my $expires_at = $self->_get_expiration_time(claims => $claims);
  my $scopes     = $self->_get_scopes_from_claims($claims);

  $self->_store_access_token(
    audience     => $self->client->audience,
    access_token => $token,
    expires_at   => $expires_at,
    scopes       => $scopes,
  );

  return $claims;
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


=head2 has_scope( $expected_scope )

  my $has_scope = $c->oidc->has_scope($expected_scope);

Returns whether a scope is present in the scopes of the stored access token.

This method should only be invoked after a call to the L</"verify_token( %args )">
method.

=cut

sub has_scope {
  my $self = shift;
  my ($expected_scope) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $stored_token = $self->get_valid_access_token()
    or croak("OIDC: cannot retrieve the access token");

  my $scopes = $stored_token->{scopes}
    or return 0;

  return any { $_ eq $expected_scope } @$scopes;
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

  my $stored_token = $self->get_valid_access_token()
    or croak("OIDC: cannot retrieve the access token");

  return $self->client->get_userinfo(
    access_token => $stored_token->{token},
    token_type   => $stored_token->{token_type},
  );
}


=head2 build_user_from_userinfo( $user_class )

  my $user = $c->oidc->build_user_from_userinfo();

Gets the user informations calling the provider (see L</"get_userinfo()">)
and returns a user object (L<OIDC::Client::User> by default) from this user
informations.

The optional list parameters are:

=over 2

=item user_class

Class to be used to instantiate the user.
Default to L<OIDC::Client::User>.

=back

=cut

sub build_user_from_userinfo {
  my $self = shift;
  my ($user_class) = pos_validated_list(\@_, { isa => 'Str', default => 'OIDC::Client::User' });
  load($user_class);

  my $userinfo    = $self->get_userinfo();
  my $mapping     = $self->client->claim_mapping;
  my $role_prefix = $self->client->role_prefix;

  return $user_class->new(
    (
      map { $_ => $userinfo->{ $mapping->{$_} } }
      grep { exists $userinfo->{ $mapping->{$_} } }
      keys %$mapping
    ),
    defined $role_prefix ? (role_prefix => $role_prefix) : (),
  );
}


=head2 build_user_from_identity( $user_class )

  my $user = $c->oidc->build_user_from_identity();

Returns a user object (L<OIDC::Client::User> by default) from the stored identity.
This method should only be invoked when an identity has been stored, i.e.
when an authorisation flow has completed and an ID token has been returned
by the provider.

The optional list parameters are:

=over 2

=item user_class

Class to be used to instantiate the user.
Default to L<OIDC::Client::User>.

=back

=cut

sub build_user_from_identity {
  my $self = shift;
  my ($user_class) = pos_validated_list(\@_, { isa => 'Str', default => 'OIDC::Client::User' });
  load($user_class);

  my $identity = $self->get_stored_identity()
    or croak("OIDC: no identity has been stored");

  my $role_prefix = $self->client->role_prefix;

  return $user_class->new(
    %$identity,
    defined $role_prefix ? (role_prefix => $role_prefix) : (),
  );
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

Alias configured for the audience of the other application.

=back

=cut

sub build_api_useragent {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $exchanged_token = try {
    return $self->get_valid_access_token($audience_alias);
  }
  catch {
    $self->log_msg(warning => "OIDC: error getting valid access token : $_");
    return;
  };

  $exchanged_token ||= $self->exchange_token($audience_alias);

  return $self->client->build_api_useragent(
    token      => $exchanged_token->{token},
    token_type => $exchanged_token->{token_type},
  );
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

=item state

String which can be send in the C<state> parameter.

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
    state                    => { isa => 'Str', optional => 1 },
  );

  my %args;

  if ($params{with_id_token} // $self->client->config->{logout_with_id_token}) {
    my $identity = $self->get_stored_identity()
      or croak("OIDC: no identity has been stored");
    $args{id_token} = $identity->{token};
  }

  if (my $redirect_uri = $params{post_logout_redirect_uri} || $self->logout_redirect_uri) {
    $args{post_logout_redirect_uri} = $redirect_uri;
  }

  $args{state} = $params{state} if defined $params{state};

  if (my $extra_params = $params{extra_params}) {
    $args{extra_params} = $extra_params;
  }

  my $logout_url = $self->client->logout_url(%args);

  if (my $target_url = $params{target_url}) {
    $self->set_flash->(oidc_target_url => $target_url);
  }

  $self->log_msg(debug => "OIDC: redirecting to idp for log out : $logout_url");
  $self->redirect->($logout_url);
}


=head2 has_access_token_expired( $audience_alias )

  my $has_expired = $c->oidc->has_access_token_expired( $audience_alias );

Returns whether the stored access token for a specified audience has expired.

The list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

=cut

sub has_access_token_expired {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->client->get_audience_for_alias($audience_alias)
                                 : $self->client->audience
    or croak("OIDC: no audience for alias '$audience_alias'");

  my $stored_token = $self->_get_stored_access_token($audience)
    or croak("OIDC: no access token has been stored for audience '$audience'");

  if ($self->client->has_expired($stored_token->{expires_at})) {
    $self->log_msg(debug => "OIDC: access token has expired for audience '$audience'");
    return 1;
  }

  return 0;
}


=head2 get_valid_access_token( $audience_alias )

  my $stored_token = $c->oidc->get_valid_access_token( $audience_alias );

Returns a valid (not expired) token object (hashref) for the default audience
or for the audience corresponding to a given alias.

Returns undef if no access token has been stored for the audience.

The token can be retrieved from the store or after a refresh.

The optional list parameters are:

=over 2

=item audience_alias

Alias configured for the audience of the other application.

=back

Returns a hashref with the keys :

=over 2

=item token

Access token (String)

=item expires_at

The expiration time of this access token (Integer timestamp)

=item refresh_token

Token to "refresh" the access token when it has expired (String)

=item token_type

Type of the token (String)

=item scopes

Token scopes (arrayref of strings). Present only after a call
to the L</"verify_token( %args )"> method.

=back

In local environment, if the C<mocked_claims> entry (hashref) is configured,
mocked token and scopes are returned.

=cut

sub get_valid_access_token {
  my $self = shift;
  my ($audience_alias) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 1 });

  my $audience = $audience_alias ? $self->client->get_audience_for_alias($audience_alias)
                                 : $self->client->audience
    or croak("OIDC: no audience for alias '$audience_alias'");

  if ($self->is_base_url_local and my $mocked_claims = $self->client->config->{mocked_claims}) {
    my $scopes = $self->_get_scopes_from_claims($mocked_claims);
    return { token  => "mocked token for audience '$audience'",
             scopes => $scopes };
  }

  my $stored_token = $self->_get_stored_access_token($audience);

  unless ($stored_token) {
    $self->log_msg(debug => "OIDC: no access token has been stored for audience '$audience'");
    return;
  }

  if ($self->client->has_expired($stored_token->{expires_at})) {
    $self->log_msg(debug => "OIDC: access token has expired for audience '$audience'");
    return $self->refresh_token($audience_alias);
  }
  else {
    $self->log_msg(debug => "OIDC: access token for audience '$audience' has been retrieved from store");
    return $stored_token;
  }
}


=head2 get_stored_identity()

  my $identity = $c->oidc->get_stored_identity();

Returns the stored identity, a hashref with at least these keys :

=over 2

=item token

Id token (String)

=item subject

Subject identifier (String)

=back

If a claim mapping is configured in the C<claim_mapping> section, the claim names/values
are present in the stored identity and therefore returned by this method.

To bypass the OIDC flow in local environment, you can configure the C<mocked_identity>
entry (hashref) to be returned by this method.

=cut

sub get_stored_identity {
  my $self = shift;

  if ($self->is_base_url_local and my $mocked_identity = $self->client->config->{mocked_identity}) {
    return $mocked_identity;
  }

  my $provider = $self->client->provider;

  return $self->_store->{oidc}{provider}{$provider}{identity};
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
    or croak("OIDC: the 'sub' claim is not defined");

  my %identity = (
    token   => $params{id_token},
    subject => $subject,
  );

  foreach my $claim_name (keys %{ $self->client->claim_mapping }) {
    $identity{$claim_name} //= $self->client->get_claim_value(
      name     => $claim_name,
      claims   => $params{claims},
      optional => 1,
    );
  }

  my $provider = $self->client->provider;

  $self->_store->{oidc}{provider}{$provider}{identity} = \%identity;
}


sub _get_stored_access_token {
  my $self = shift;
  my ($audience) = pos_validated_list(\@_, { isa => 'Str', optional  => 0 });

  my $provider = $self->client->provider;

  return $self->_store->{oidc}{provider}{$provider}{access_token}{audience}{$audience};
}


sub _store_access_token {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    audience      => { isa => 'Str', optional => 0 },
    access_token  => { isa => 'Str', optional => 0 },
    expires_at    => { isa => 'Maybe[Int]', optional => 1 },
    refresh_token => { isa => 'Maybe[Str]', optional => 1 },
    token_type    => { isa => 'Maybe[Str]', optional => 1 },
    scopes        => { isa => 'ArrayRef[Str]', optional => 1 },
  );

  my $provider = $self->client->provider;

  my %to_store = (
    token => $params{access_token},
  );
  for (qw/ expires_at refresh_token token_type scopes /) {
    $to_store{$_} = $params{$_} if defined $params{$_};
  }

  $self->_store->{oidc}{provider}{$provider}{access_token}{audience}{$params{audience}} = \%to_store;
}


sub _get_expiration_time {
  my $self = shift;
  my %params = validated_hash(
    \@_,
    token_response  => { isa => 'OIDC::Client::TokenResponse', optional => 1 },
    claims          => { isa => 'HashRef', optional => 1 },
  );

  if (my $claims = $params{claims}) {
    my $expiration_time = $claims->{exp};
    return $expiration_time if defined $expiration_time;
  }

  if (my $token_response = $params{token_response}) {
    return time + $token_response->expires_in if defined $token_response->expires_in;
  }

  return;
}


sub _get_scopes_from_claims {
  my $self = shift;
  my ($claims) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 });

  return exists $claims->{scp}   ? ($claims->{scp} // [])
       : exists $claims->{scope} ? [split(/\s+/, ($claims->{scope} // ''))]
                                 : [];
}


sub _generate_uuid_string {
  my $self = shift;
  return $self->uuid_generator->to_string($self->uuid_generator->create());
}


sub _check_state_parameter {
  my $self = shift;

  my $state          = $self->request_params->{state} || '';
  my $expected_state = $self->get_flash->('oidc_state') || '';

  if (! $state || ! $expected_state || $state ne $expected_state) {
    OIDC::Client::Error::Authentication->throw(
      "OIDC: invalid state parameter (got '$state' but expected '$expected_state')"
    );
  }
}


sub _store {
  my $self = shift;

  return $self->store_mode eq 'session' ? $self->session
                                        : $self->stash;
}


__PACKAGE__->meta->make_immutable;

1;
