package OIDC::Client;
use 5.020;
use utf8;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use namespace::autoclean;

use Readonly;
use Carp qw(croak);
use List::Util qw(first);
use List::MoreUtils qw(duplicates);
use Try::Tiny;
use Crypt::JWT ();
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode);
use OIDC::Client::ResponseParser;
use OIDC::Client::TokenResponseParser;
use OIDC::Client::Error::TokenValidation;

our $VERSION = '0.01';

with 'OIDC::Client::Role::LoggerWrapper';

=encoding utf8

=head1 NAME

OIDC::Client - OpenID Connect Client

=head1 SYNOPSIS

  my $client = OIDC::Client->new(
    provider          => 'my_provider',
    id                => 'my_client_id',
    secret            => 'my_client_secret',
    provider_metadata => \%provider_metadata,
    log               => $app->log,
  );

  # or...

  my $client = OIDC::Client->new(
    config => $config_provider,
    log    => $app->log,
  );

  my $token_response = $client->get_token(
    code         => $code,
    redirect_uri => q{http://yourapp/oidc/callback},
  );

=head1 DESCRIPTION

Client module for OpenID Connect protocol.

Use this module directly from a batch or a simple script. For use from within
an application, you should instead use the framework plugin included in the
L<OIDC-Client|https://metacpan.org/dist/OIDC-Client> distribution.

=cut

enum 'ResponseMode' => [qw/query form_post/];
enum 'GrantType'    => [qw/authorization_code client_credentials password refresh_token/];
enum 'AuthMethod'   => [qw/post basic/];

Readonly my %DEFAULT_DECODE_JWT_OPTIONS => (
  leeway => 60,  # to account for clock skew
);

Readonly my $DEFAULT_TOKEN_ENDPOINT_GRANT_TYPE  => 'authorization_code';
Readonly my $DEFAULT_TOKEN_ENDPOINT_AUTH_METHOD => 'post';
Readonly my $DEFAULT_TOKEN_TYPE                 => 'Bearer';

has 'config' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

has 'provider' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_provider',
);

has 'id' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_id',
);

has 'secret' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_secret',
);

has 'audience' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_audience',
);

has 'user_agent' => (
  is      => 'ro',
  isa     => 'Mojo::UserAgent',
  lazy    => 1,
  builder => '_build_user_agent',
);

has 'claim_mapping' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_build_claim_mapping',
);

has 'decode_jwt_options' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_build_decode_jwt_options',
);

has 'role_prefix' => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  default => sub { shift->config->{role_prefix} },
);

has 'default_token_type' => (
  is      => 'ro',
  isa     => 'Str',
  default => sub { $DEFAULT_TOKEN_TYPE },
);

has 'provider_metadata' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_build_provider_metadata',
);

has 'kid_keys' => (
  is      => 'rw',  # not 'ro' because can be rebuilt when a key has changed
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_get_kid_keys',
);

has 'response_parser' => (
  is      => 'ro',
  isa     => 'OIDC::Client::ResponseParser',
  default => sub { OIDC::Client::ResponseParser->new() },
);

has 'token_response_parser' => (
  is      => 'ro',
  isa     => 'OIDC::Client::TokenResponseParser',
  default => sub { OIDC::Client::TokenResponseParser->new() },
);

sub _build_provider {
  my $self = shift;

  my $provider = $self->config->{provider}
    or croak('OIDC: no provider in config');

  return $provider;
}

sub _build_id {
  my $self = shift;

  my $id = $self->config->{id}
    or croak('OIDC: no id in config');

  return $id;
}

sub _build_secret {
  my $self = shift;

  my $secret = $self->config->{secret};

  unless ($secret) {
    my $provider = $self->provider;

    $secret = $ENV{uc "OIDC_${provider}_SECRET"};
  }

  $secret or croak("OIDC: no secret configured or set up in environment");

  return $secret;
}

sub _build_audience {
  my $self = shift;

  return $self->config->{audience} || $self->id;
}

sub _build_user_agent {
  my $self = shift;

  my $ua = Mojo::UserAgent->new();

  if ($self->config->{proxy_detect}) {
    $ua->proxy->detect;
  }

  if (my $user_agent = $self->config->{user_agent}) {
    $ua->transactor->name($user_agent);
  }

  return $ua;
}

sub _build_claim_mapping {
  my $self = shift;

  return $self->config->{claim_mapping} || {};
}

sub _build_decode_jwt_options {
  my $self = shift;

  return $self->config->{decode_jwt_options} || \%DEFAULT_DECODE_JWT_OPTIONS;
}

sub _build_provider_metadata {
  my $self = shift;

  my $provider_metadata = {};

  if (my $well_known_url = $self->config->{well_known_url}) {
    $provider_metadata = $self->_get_provider_metadata($well_known_url);
  }

  # provider metadata can be overloaded by configuration
  for (qw/authorize_url end_session_url issuer token_url userinfo_url jwks_url/) {
    $provider_metadata->{$_} = $self->config->{$_} if exists $self->config->{$_};
  }

  return $provider_metadata;
}


=head1 METHODS

=head2 BUILD

Called after the object is created. Makes some basic checks and forces
the retrieval of provider metadata and kid keys.

=cut

sub BUILD {
  my $self = shift;

  $self->_check_configuration();
  $self->_check_audiences_configuration();

  $self->provider;
  $self->id;
  $self->secret;

  $self->provider_metadata;
  $self->kid_keys;
}


=head2 auth_url( %args )

  my $authorize_url = $client->auth_url(%args);

Returns a scalar or a L<Mojo::URL> object containing the initial authorization URL.
This is the URL to use to initiate an authorization code flow.

The optional parameters are:

=over 2

=item response_mode

Defines how tokens are sent by the provider.

Can take one of these values:

=over 2

=item query

Tokens are sent in query parameters.

=item form_post

Tokens are sent in a POST form.

=back

=item redirect_uri

Redirection URI to which the response will be sent.
Can also be specified in the C<signin_redirect_uri> configuration entry.

=item state

String which is sent during the request to the identity provider
and sent back from the IDP along with the Code.

=item nonce

String which is sent during the request to the identity provider
and sent back from the IDP in the returned ID Token.

=item scope

Specifies the desired scope of the requested token.
Must be a string with space separators.
Can also be specified in the C<scope> configuration entry.

=item audience

Specifies the audience/resource that the access token is intended for.
Can also be specified in the C<audience> configuration entry.

=item extra_params

Hashref which can be used to send extra query parameters.
Can also be specified in the C<authorize_endpoint_extra_params> configuration entry.

=item want_mojo_url

Defines whether you want this method to return a L<Mojo::URL> object
instead of a scalar. False by default.

=back

=cut

sub auth_url {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    response_mode => { isa => 'ResponseMode', optional => 1 },
    redirect_uri  => { isa => 'Str', optional => 1 },
    state         => { isa => 'Str', optional => 1 },
    nonce         => { isa => 'Str', optional => 1 },
    scope         => { isa => 'Str', optional => 1 },
    audience      => { isa => 'Str', optional => 1 },
    extra_params  => { isa => 'HashRef', optional => 1 },
    want_mojo_url => { isa => 'Bool', default => 0 },
  );

  my $authorize_url = $self->provider_metadata->{authorize_url}
    or croak "OIDC: authorize url not found in provider metadata";

  my %args = (
    response_type => 'code',
    client_id     => $self->id,
  );

  if (my $response_mode = $params{response_mode} || $self->config->{authorize_endpoint_response_mode}) {
    $args{response_mode} = $response_mode;
  }

  if (my $redirect_uri = $params{redirect_uri} || $self->config->{signin_redirect_uri}) {
    $args{redirect_uri} = $redirect_uri;
  }

  foreach my $param_name (qw/state nonce/) {
    if (defined $params{$param_name}) {
      $args{$param_name} = $params{$param_name};
    }
  }

  if (my $scope = $params{scope} || $self->config->{scope}) {
    $args{scope} = $scope;
  }

  if (my $audience = $params{audience} || $self->config->{audience}) {
    $args{audience} = $audience;
  }

  if (my $extra_params = $params{extra_params} || $self->config->{authorize_endpoint_extra_params}) {
    foreach my $param_name (keys %$extra_params) {
      $args{$param_name} = $extra_params->{$param_name};
    }
  }

  my $auth_url = Mojo::URL->new($authorize_url);
  $auth_url->query(%args);

  return $params{want_mojo_url} ? $auth_url : $auth_url->to_string;
}


=head2 get_token( %args )

  my $token_response = $client->get_token(
    code         => $code,
    redirect_uri => q{http://yourapp/oidc/callback},
  );

Fetch token(s) from an OAuth2/OIDC provider and returns a
L<OIDC::Client::TokenResponse> object.

This method doesn't execute any verification. Call the L<verify_token>
method to do so.

The optional parameters are:

=over 2

=item grant_type

Specifies how the client wants to interact with the identity provider.
Accepted here : C<authorization_code>, C<client_credentials>, C<password>
or C<refresh_token>.
Can also be specified in the C<token_endpoint_grant_type> configuration entry.
Default to C<authorization_code>.

=item auth_method

Specifies how the client credentials are sent to the identity provider.
Accepted here : C<post> or C<basic>.
Can also be specified in the C<token_endpoint_auth_method> configuration entry.
Default to C<post>.

=item code

Authorization-code that is issued beforehand by the identity provider.
Used only for the C<authorization_code> grant-type.

=item redirect_uri

Redirection URI to which the response will be sent.
Can also be specified in the C<signin_redirect_uri> configuration entry.
Used only for the C<authorization_code> grant-type.

=item username / password

User credentials for authorization
Can also be specified in the C<username> and C<password> configuration entries.
Used only the for C<password> grant-type.

=item audience

Specifies the Relaying Party for which the token is intended.
Can also be specified in the C<audience> configuration entry.
Not used for the C<refresh_token> grant-type.

=item scope

Specifies the desired scope of the requested token.
Must be a string with space separators.
Can also be specified in the C<scope> configuration entry.
Not used for the C<authorization_code> nor the C<refresh_token> grant-type.

=item refresh_token

Token that can be used to renew the associated access token before it expires.
Used only for the C<refresh_token> grant-type.

=back

=cut

sub get_token {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    grant_type    => { isa => 'GrantType', optional => 1 },
    auth_method   => { isa => 'AuthMethod', optional => 1 },
    code          => { isa => 'Str', optional => 1 },
    redirect_uri  => { isa => 'Str', optional => 1 },
    username      => { isa => 'Str', optional => 1 },
    password      => { isa => 'Str', optional => 1 },
    audience      => { isa => 'Str', optional => 1 },
    scope         => { isa => 'Str', optional => 1 },
    refresh_token => { isa => 'Str', optional => 1 },
  );

  my $grant_type = $params{grant_type}
                     || $self->config->{token_endpoint_grant_type}
                     || $DEFAULT_TOKEN_ENDPOINT_GRANT_TYPE;

  my $auth_method = $params{auth_method}
                      || $self->config->{token_endpoint_auth_method}
                      || $DEFAULT_TOKEN_ENDPOINT_AUTH_METHOD;

  my $token_url = $self->provider_metadata->{token_url}
    or croak "OIDC: token url not found in provider metadata";

  my %args  = (grant_type => $grant_type);
  my %headers = ();

  if ($auth_method eq 'basic') {
    $headers{Authorization} = sprintf('Basic %s', b64_encode(join(':', $self->id, $self->secret), ''));
  }
  else {
    $args{client_id}     = $self->id;
    $args{client_secret} = $self->secret;
  }

  if ($grant_type eq 'authorization_code') {
    $args{code} = $params{code}
      or croak "OIDC: code is missing";

    if (my $redirect_uri = $params{redirect_uri} || $self->config->{signin_redirect_uri}) {
      $args{redirect_uri} = $redirect_uri;
    }
  }
  elsif ($grant_type eq 'password') {
    foreach my $required_field (qw/username password/) {
      $args{$required_field} = ($params{$required_field} || $self->config->{$required_field})
        or croak "OIDC: $required_field is missing";
    }
  }
  elsif ($grant_type eq 'refresh_token') {
    $args{refresh_token} = $params{refresh_token}
      or croak "OIDC: refresh_token is missing";
  }

  unless ($grant_type =~ /^(authorization_code|refresh_token)$/) {
    if (my $scope = ($params{scope} || $self->config->{scope})) {
      $args{scope} = $scope;
    }
  }

  unless ($grant_type eq 'refresh_token') {
    if (my $audience = $params{audience} || $self->config->{audience}) {
      $args{audience} = $audience;
    }
  }

  $self->log_msg(debug => 'OIDC: calling provider to get token');

  my $res = $self->user_agent->post($token_url, \%headers, form => \%args)->result;

  return $self->token_response_parser->parse($res);
}


=head2 verify_token( %args )

  my $claims = $client->verify_token(
    token             => $token,
    expected_audience => $audience,
    expected_nonce    => $nonce,
  );

Checks the structure, claims and signature of the JWT token.
Throws an L<OIDC::Client::Error::TokenValidation> exception if an error occurs.
Otherwise, returns the claims.

This method automatically manages a JWK key rotation. If a JWK key error
is detected during token verification, the JWK keys in memory are refreshed
by retrieving them again from the JWKS URL. The token is checked again, and if
an error occurs, an L<OIDC::Client::Error::TokenValidation> exception is thrown.

The following claims are validated :

=over 2

=item "exp" (Expiration Time) claim

By default, must be valid (not in the future) if present.

=item "iat" (Issued At) claim

By default, must be valid (not in the future) if present.

=item "nbf" (Not Before) claim

By default, must be valid (not in the future) if present.

=item "iss" (Issuer) claim

Must be the issuer recorded in the provider metadata.

=item "aud" (Audience) claim

Must be the expected audience (see parameters beelow).

=item "sub" (Subject) claim

Must be the expected subject defined in the parameters (see beelow).

=back

The [Crypt::JWT::decode_jwt()](https://metacpan.org/pod/Crypt::JWT#decode_jwt)
function is used to validate and decode a JWT token. Remember that you can change
the options transmitted to this function (see L<OIDC::Client::Config>).

The parameters are:

=over 2

=item token

The JWT token to validate.
Required.

=item expected_audience

If the token is not intended for the expected audience, an exception is thrown.
Default to the C<audience> configuration entry or otherwise the client id.

=item expected_subject

If the C<subject> claim value is not the expected subject, an exception is thrown.
Optional.

=item expected_nonce

If the C<nonce> claim value is not the expected nonce, an exception is thrown.
Optional.

=back

=cut

sub verify_token {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    token             => { isa => 'Str', optional => 0 },
    expected_audience => { isa => 'Str', default => $self->audience },
    expected_subject  => { isa => 'Str', optional => 1 },
    expected_nonce    => { isa => 'Str', optional => 1 },
  );

  # checks the signature, the issuer and the timestamps
  my $claims = $self->_decode_token($params{token});

  # checks the audience
  {
    my $claim_audience = $claims->{aud};
    defined $claim_audience
      or croak "OIDC: the audience is not defined";
    ref $claim_audience
      and croak "OIDC: multiple audiences not implemented";
    $claim_audience eq $params{expected_audience}
      or OIDC::Client::Error::TokenValidation->throw(
        "OIDC: unexpected audience, expected '$params{expected_audience}' but got '$claim_audience'"
      );
  }

  # checks the subject
  if (my $expected_subject = $params{expected_subject}) {
    my $claim_subject = $claims->{sub};
    defined $claim_subject
      or croak "OIDC: the subject is not defined";
    $claim_subject eq $expected_subject
      or OIDC::Client::Error::TokenValidation->throw(
        "OIDC: unexpected subject, expected '$expected_subject' but got '$claim_subject'"
      );
  }

  # checks the nonce
  if (my $expected_nonce = $params{expected_nonce}) {
    my $claim_nonce = $claims->{nonce} || '';
    $claim_nonce eq $expected_nonce
      or OIDC::Client::Error::TokenValidation->throw(
        "OIDC: unexpected nonce, expected '$expected_nonce' but got '$claim_nonce'"
      );
  }

  return $claims;
}


=head2 has_expired( $expiration_time )

  my $has_expired = $client->has_expired($token->{expires_at});

Returns true if the timestamp passed in parameter has expired.
The configuration entry C<expiration_leeway> is included
in the calculation if present.

=cut

sub has_expired {
  my $self = shift;
  my ($expiration_time) = pos_validated_list(\@_, { isa => 'Int', optional => 0 });

  my $now = time;
  my $leeway = $self->config->{expiration_leeway} || 0;
  my $including_leeway = $expiration_time - $leeway;
  $self->log_msg(debug => "OIDC: expiration time (leeway = $leeway) : $including_leeway");

  return $including_leeway < $now;
}


=head2 get_userinfo( %args )

  my $userinfo = $client->get_userinfo(
    access_token => $stored_token->{token},
    token_type   => $stored_token->{token_type},
  );

Get and returns the user information from an OAuth2/OIDC provider.

The parameters are:

=over 2

=item access_token

Content of the valid access token obtained through OIDC authentication.

=item token_type

Optional, default to C<Bearer>.

=back

=cut

sub get_userinfo {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    access_token => { isa => 'Str', optional => 0 },
    token_type   => { isa => 'Maybe[Str]', optional => 1 },
  );

  my $userinfo_url = $self->provider_metadata->{userinfo_url}
    or croak "OIDC: userinfo_url not found in provider metadata";

  my $token_type = $params{token_type} || $self->default_token_type;

  my $authorization = "$token_type $params{access_token}";

  $self->log_msg(debug => 'OIDC: calling provider to fetch userinfo');

  my $res = $self->user_agent->get($userinfo_url, { Authorization => $authorization })
                             ->result;

  return $self->response_parser->parse($res);
}


=head2 get_audience_for_alias( $audience_alias )

  my $audience = $client->get_audience_for_alias($audience_alias);

Returns the audience for an alias that has been configured in the configuration
entry C<audience_alias>/C<$audience_alias>/C<audience>.

=cut

sub get_audience_for_alias {
  my $self = shift;
  my ($alias) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $config_audience_alias = $self->config->{audience_alias}
    or return;

  my $config_audience = $config_audience_alias->{$alias}
    or return;

  return $config_audience->{audience};
}


=head2 get_scope_for_audience( $audience )

  my $scope = $client->get_scope_for_audience($audience);

Returns the scope for an audience that has been configured in the configuration
entry C<audience_alias>/C<$audience_alias>/C<scope>.

=cut

sub get_scope_for_audience {
  my $self = shift;
  my ($audience) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $config_audience_alias = $self->config->{audience_alias}
    or return;

  my $audience_config = first { $_->{audience} eq $audience  } values %$config_audience_alias
    or return;

  return $audience_config->{scope};
}


=head2 exchange_token( %args )

  my $exchanged_token_response = $client->exchange_token(
    token    => $token,
    audience => $audience,
  );

Exchanges an access token, obtained through OIDC authentication, for another access
token that is accepted by a different OIDC application.

Returns a L<OIDC::Client::TokenResponse> object.

The parameters are:

=over 2

=item token

Content of the valid access token obtained through OIDC authentication.

=item audience

Audience of the target application.

=item scope

Specifies the desired scope of the requested token.
Must be a string with space separators.
Optional.

=back

=cut

sub exchange_token {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    token    => { isa => 'Str', optional => 0 },
    audience => { isa => 'Str', optional => 0 },
    scope    => { isa => 'Str', optional => 1 },
  );

  my %args = (
    client_id          => $self->id,
    client_secret      => $self->secret,
    audience           => $params{audience},
    grant_type         => 'urn:ietf:params:oauth:grant-type:token-exchange',
    subject_token      => $params{token},
    subject_token_type => 'urn:ietf:params:oauth:token-type:access_token',
  );

  if (my $scope = ($params{scope} || $self->get_scope_for_audience($params{audience}))) {
    $args{scope} = $scope;
  }

  my $token_url = $self->provider_metadata->{token_url}
    or croak "OIDC: token url not found in provider metadata";

  $self->log_msg(debug => 'OIDC: calling provider to exchange token');

  my $res = $self->user_agent->post($token_url, form => \%args)->result;

  return $self->token_response_parser->parse($res);
}


=head2 build_api_useragent( %args )

  my $ua = $client->build_api_useragent(
    token      => $token,
    token_type => $token_type,
  );

Builds a web client (L<Mojo::UserAgent> object) that will have the given token
in the authorization header for each request.

The optional parameters are:

=over 2

=item token

Content of the access token to send to the other application.

If it is not passed as parameter, the method L<get_token> is invoked
without any parameter to retrieve the token from the provider.
This can be useful if the client is configured for a password grant
or a client credentials grant.

=item token_type

Token type. Default to "Bearer".

=back

=cut

sub build_api_useragent {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    token      => { isa => 'Str', optional => 1 },
    token_type => { isa => 'Maybe[Str]', optional => 1 },
  );

  my ($token, $token_type);

  if ($token = $params{token}) {
    $token_type = $params{token_type};
  }
  else {
    my $token_response = $self->get_token();
    $token      = $token_response->access_token;
    $token_type = $token_response->token_type;
  }

  $token_type ||= $self->default_token_type;

  my $ua = Mojo::UserAgent->new();

  $ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->authorization("$token_type $token");
  });

  return $ua;
}


=head2 logout_url( %args )

  my $logout_url = $client->logout_url(%args);

URL allowing the end-user to logout.
Returns a scalar or a L<Mojo::URL> object which contain the logout URL.

The optional parameters are:

=over 2

=item id_token

Content of the end-user's ID token.

=item state

String to add to the logout request that will be included when redirecting
to the C<post_logout_redirect_uri>.

=item post_logout_redirect_uri

Redirect URL value that indicates where to redirect the user after logout.
Can also be specified in the C<post_logout_redirect_uri> configuration entry.

=item extra_params

Hashref which can be used to send extra query parameters.

=item want_mojo_url

Defines whether you want this method to return a L<Mojo::URL> object
instead of a scalar. False by default.

=back

=cut

sub logout_url {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    id_token                 => { isa => 'Str', optional => 1 },
    state                    => { isa => 'Str', optional => 1 },
    post_logout_redirect_uri => { isa => 'Str', optional => 1 },
    extra_params             => { isa => 'HashRef', optional => 1 },
    want_mojo_url            => { isa => 'Bool', default => 0 },
  );

  my $end_session_url = $self->provider_metadata->{end_session_url}
    or croak "OIDC: end_session_url not found in provider metadata";

  my %args = (
    client_id => $self->id,
  );

  if (my $id_token = $params{id_token}) {
    $args{id_token_hint} = $id_token;
  }

  if (defined $params{state}) {
    $args{state} = $params{state};
  }

  if (my $redirect_uri = $params{post_logout_redirect_uri} || $self->config->{post_logout_redirect_uri}) {
    $args{post_logout_redirect_uri} = $redirect_uri;
  }

  if (my $extra_params = $params{extra_params} || $self->config->{logout_extra_params}) {
    foreach my $param_name (keys %$extra_params) {
      $args{$param_name} = $extra_params->{$param_name};
    }
  }

  my $logout_url = Mojo::URL->new($end_session_url);
  $logout_url->query(%args);

  return $params{want_mojo_url} ? $logout_url : $logout_url->to_string;
}


=head2 get_claim_value( %args )

  my $claim_value = $client->get_claim_value(name => 'login', claims => $claims);

Returns the value of a claim by its configured name.

The hash parameters are:

=over 2

=item name

Name of the claim configured in the C<claim_mapping> section.

=item claims

Hashref of the claims.

=item optional

Defines whether the wanted claim must exist in the claims.

=back

=cut

sub get_claim_value {
  my $self = shift;
  my (%params) = validated_hash(
    \@_,
    name     => { isa => 'Str', optional => 0 },
    claims   => { isa => 'HashRef', optional => 0 },
    optional => { isa => 'Bool', default => 0 },
  );

  my $claim_key = $self->claim_mapping->{$params{name}}
    or croak("OIDC: no claim key in config for name '$params{name}'");

  unless ($params{optional}) {
    exists $params{claims}->{$claim_key}
      or croak("OIDC: the '$claim_key' claim is not present");
  }

  return $params{claims}->{$claim_key};
}


sub _get_provider_metadata {
  my ($self, $well_known_url) = @_;

  my $provider = $self->provider;
  $self->log_msg(info => "OIDC/$provider: fetching OpenID configuration from $well_known_url");

  my $res = $self->user_agent->get($well_known_url)->result;
  my $provider_config = $self->response_parser->parse($res);

  return {
    authorize_url   => $provider_config->{authorization_endpoint},
    end_session_url => $provider_config->{end_session_endpoint},
    issuer          => $provider_config->{issuer},
    token_url       => $provider_config->{token_endpoint},
    userinfo_url    => $provider_config->{userinfo_endpoint},
    jwks_url        => $provider_config->{jwks_uri},
  };
}


sub _get_kid_keys {
  my ($self) = @_;

  my $provider = $self->provider;
  $self->log_msg(info => "OIDC/$provider: fetching JWT kid keys");

  my $jwks_url = $self->provider_metadata->{jwks_url}
    or croak "OIDC: jwks_url not found in provider metadata";

  my $res = $self->user_agent->get($jwks_url)->result;

  return $self->response_parser->parse($res);
}


=head2 decode_jwt( %args )

Simple pass-through of the Crypt::JWT::decode_jwt() function that can be mocked in tests

=cut

sub decode_jwt { Crypt::JWT::decode_jwt(@_) }


sub _decode_token {
  my ($self, $token, $has_already_update_keys) = @_;

  return try {
    decode_jwt(%{ $self->decode_jwt_options },
               verify_iss => $self->provider_metadata->{issuer},
               token      => $token,
               kid_keys   => $self->kid_keys);
  }
  catch {
    my $e = $_;
    if ($e =~ /kid_keys/i && !$has_already_update_keys) {
      $self->log_msg(info => "OIDC: couldn't decode the token. Let's retry after updating the keys : $e");
      $self->kid_keys($self->_get_kid_keys());
      return $self->_decode_token($token, 1);
    }
    else {
      OIDC::Client::Error::TokenValidation->throw("$e");
    }
  };
}


sub _check_configuration {
  my $self = shift;

  my @config = %{$self->config};

  validated_hash(
    \@config,
    provider                         => { isa => 'Str', optional => 1 },
    proxy_detect                     => { isa => 'Bool', optional => 1 },
    user_agent                       => { isa => 'Str', optional => 1 },
    id                               => { isa => 'Str', optional => 1 },
    secret                           => { isa => 'Str', optional => 1 },
    audience                         => { isa => 'Str', optional => 1 },
    role_prefix                      => { isa => 'Str', optional => 1 },
    well_known_url                   => { isa => 'Str', optional => 1 },
    issuer                           => { isa => 'Str', optional => 1 },
    jwks_url                         => { isa => 'Str', optional => 1 },
    authorize_url                    => { isa => 'Str', optional => 1 },
    token_url                        => { isa => 'Str', optional => 1 },
    userinfo_url                     => { isa => 'Str', optional => 1 },
    end_session_url                  => { isa => 'Str', optional => 1 },
    signin_redirect_path             => { isa => 'Str', optional => 1 },
    signin_redirect_uri              => { isa => 'Str', optional => 1 },
    scope                            => { isa => 'Str', optional => 1 },
    expiration_leeway                => { isa => 'Int', optional => 1 },
    decode_jwt_options               => { isa => 'HashRef', optional => 1 },
    claim_mapping                    => { isa => 'HashRef[Str]', optional => 1 },
    audience_alias                   => { isa => 'HashRef[HashRef]', optional => 1 },
    authorize_endpoint_response_mode => { isa => 'ResponseMode', optional => 1 },
    authorize_endpoint_extra_params  => { isa => 'HashRef[Str]', optional => 1 },
    token_endpoint_grant_type        => { isa => 'GrantType', optional => 1 },
    token_endpoint_auth_method       => { isa => 'AuthMethod', optional => 1 },
    username                         => { isa => 'Str', optional => 1 },
    password                         => { isa => 'Str', optional => 1 },
    logout_redirect_path             => { isa => 'Str', optional => 1 },
    post_logout_redirect_uri         => { isa => 'Str', optional => 1 },
    logout_with_id_token             => { isa => 'Str', optional => 1 },
    logout_extra_params              => { isa => 'HashRef[Str]', optional => 1 },
    mocked_identity                  => { isa => 'HashRef[Str]', optional => 1 },
    mocked_claims                    => { isa => 'HashRef[Str]', optional => 1 },
    mocked_userinfo                  => { isa => 'HashRef[Str]', optional => 1 },
  );
}


sub _check_audiences_configuration {
  my $self = shift;

  my %config_audience_alias = %{ $self->config->{audience_alias} || {} };

  my @possible_audiences = grep { $_ } $self->audience,
                                       map { $_->{audience} } values %config_audience_alias;

  if (my @duplicates_audiences = duplicates(@possible_audiences)) {
    croak(sprintf('OIDC: these configured audiences are duplicated: %s', join(', ', @duplicates_audiences)));
  }

  foreach my $audience_alias (keys %config_audience_alias) {
    my @config_audience = %{$config_audience_alias{$audience_alias} || {}};
    validated_hash(
      \@config_audience,
      audience => { isa => 'Str', optional => 0 },
      scope    => { isa => 'Str', optional => 1 },
    );
  }
}


__PACKAGE__->meta->make_immutable;


1;

=head1 CONFIGURATION

To use this module directly via a batch or script, here is the section to add
to your configuration file:

  oidc_client:
    provider:                  provider_name
    id:                        my-app-id
    secret:                    xxxxxxxxx
    audience:                  other_app_name
    well_known_url:            https://yourprovider.com/oauth2/.well-known/openid-configuration
    scope:                     roles
    token_endpoint_grant_type: password
    username:                  TECHXXXX
    password:                  xxxxxxxx

This is an example, see the detailed possibilities in L<OIDC::Client::Config>.

=head1 SAMPLES

Here are some samples by category. Although you will have to adapt them to your needs,
they should be a good starting point.

=head2 API call

To make an API call to another application :

  my $oidc_client = OIDC::Client->new(
    log    => $self->log,
    config => $self->config->{oidc_client},
  );

  # Retrieving a web client (Mojo::UserAgent object)
  my $ua = $oidc_client->build_api_useragent();

  # Usual call to the API
  my $res = $ua->get($url)->result;

Here, there is no token exchange because the audience has been configured
to get the access token intended for the other application.

=head1 AUTHOR

Sébastien Mourlhou

=head1 COPYRIGHT AND LICENSE

Copyright (C) Sébastien Mourlhou

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

=over 2

=item * L<OIDC::Lite>

=back

=cut
