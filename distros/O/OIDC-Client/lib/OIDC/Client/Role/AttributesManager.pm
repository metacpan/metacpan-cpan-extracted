package OIDC::Client::Role::AttributesManager;
use utf8;
use Moose::Role;
use namespace::autoclean;
use feature 'signatures';
no warnings 'experimental::signatures';
use Readonly;
use Carp qw(croak);
use Data::UUID;
use Mojo::File;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;
use OIDC::Client::ResponseParser;
use OIDC::Client::TokenResponseParser;

=encoding utf8

=head1 NAME

OIDC::Client::Role::AttributesManager - Attributes manager

=head1 DESCRIPTION

This Moose role declares and builds the various attributes of the L<OIDC::Client> module.

=cut

requires qw(log_msg);

Readonly my %DEFAULT_JWT_DECODING_OPTIONS => (
  verify_exp => 1,   # require valid 'exp' claim
  verify_iat => 1,   # require valid 'iat' claim
  leeway     => 60,  # to account for clock skew
);
Readonly my %DEFAULT_CLIENT_SECRET_JWT_ENCODING_OPTIONS => (
  alg => 'HS256',
);
Readonly my %DEFAULT_PRIVATE_KEY_JWT_ENCODING_OPTIONS => (
  alg => 'RS256',
);
Readonly my %DEFAULT_CHI_CONFIG => (
  driver => 'Memory',
  global => 0,
);
Readonly my $DEFAULT_GRANT_TYPE                 => 'authorization_code';
Readonly my $DEFAULT_TOKEN_TYPE                 => 'Bearer';
Readonly my $DEFAULT_STORE_MODE                 => 'session';
Readonly my $DEFAULT_CLIENT_AUTH_METHOD         => 'client_secret_basic';
Readonly my $DEFAULT_TOKEN_VALIDATION_METHOD    => 'jwt';
Readonly my $DEFAULT_CLIENT_ASSERTION_LIFETIME  => 120;
Readonly my $DEFAULT_MAX_ID_TOKEN_AGE           => 30;  # in addition to the leeway to account for clock skew

has 'config' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

foreach my $attr_name (qw( private_key_file private_jwk_file role_prefix client_assertion_audience
                           signin_redirect_path signin_redirect_uri logout_redirect_path post_logout_redirect_uri
                           scope refresh_scope well_known_url ))  {
  has $attr_name => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub { shift->config->{$attr_name} },
  );
}

foreach my $attr_name (qw( username password ))  {
  has $attr_name => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub { shift->config->{$attr_name} },
  );
}

foreach my $attr_name (qw( expiration_leeway identity_expires_in )) {
  has $attr_name => (
    is      => 'ro',
    isa     => 'Maybe[Int]',
    lazy    => 1,
    default => sub { shift->config->{$attr_name} },
  );
}

foreach my $attr_name (qw( proxy_detect logout_with_id_token )) {
  has $attr_name => (
    is      => 'ro',
    isa     => 'Maybe[Bool]',
    lazy    => 1,
    default => sub { shift->config->{$attr_name} },
  );
}

foreach my $attr_name (qw( private_jwk mocked_identity mocked_access_token mocked_userinfo
                           authorize_endpoint_extra_params logout_extra_params )) {
  has $attr_name => (
    is      => 'ro',
    isa     => 'Maybe[HashRef]',
    lazy    => 1,
    default => sub { shift->config->{$attr_name} },
  );
}

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
  is      => 'rw',
  isa     => 'Maybe[Str]',
  lazy    => 1,
  builder => '_build_secret',
);

has 'private_key' => (
  is      => 'rw',
  isa     => 'HashRef|ScalarRef',
  lazy    => 1,
  builder => '_build_private_key',
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

has 'audience_alias' => (
  is      => 'ro',
  isa     => 'Maybe[HashRef[HashRef]]',
  lazy    => 1,
  default => sub { shift->config->{audience_alias} },
);

has 'authorize_endpoint_response_mode' => (
  is      => 'ro',
  isa     => 'Maybe[ResponseMode]',
  lazy    => 1,
  default => sub { shift->config->{authorize_endpoint_response_mode} },
);

has 'max_id_token_age' => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { shift->config->{max_id_token_age}
                     || $DEFAULT_MAX_ID_TOKEN_AGE },
);

has 'jwt_decoding_options' => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { shift->config->{jwt_decoding_options}
                     || \%DEFAULT_JWT_DECODING_OPTIONS },
);

has 'client_secret_jwt_encoding_options' => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { shift->config->{client_secret_jwt_encoding_options}
                     || \%DEFAULT_CLIENT_SECRET_JWT_ENCODING_OPTIONS },
);

has 'private_key_jwt_encoding_options' => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { shift->config->{private_key_jwt_encoding_options}
                     || \%DEFAULT_PRIVATE_KEY_JWT_ENCODING_OPTIONS },
);

has 'token_endpoint_grant_type' => (
  is      => 'ro',
  isa     => 'GrantType',
  lazy    => 1,
  default => sub { shift->config->{token_endpoint_grant_type}
                     || $DEFAULT_GRANT_TYPE },
);

has 'client_auth_method' => (
  is      => 'ro',
  isa     => 'Maybe[ClientAuthMethod]',
  lazy    => 1,
  default => sub { shift->config->{client_auth_method} },
);

has 'token_endpoint_auth_method' => (
  is      => 'ro',
  isa     => 'ClientAuthMethod',
  lazy    => 1,
  default => sub { my $self = shift;
                   $self->config->{token_endpoint_auth_method}
                     || $self->client_auth_method
                     || $DEFAULT_CLIENT_AUTH_METHOD },
);

has 'introspection_endpoint_auth_method' => (
  is      => 'ro',
  isa     => 'ClientAuthMethod',
  lazy    => 1,
  default => sub { my $self = shift;
                   $self->config->{introspection_endpoint_auth_method}
                     || $self->client_auth_method
                     || $DEFAULT_CLIENT_AUTH_METHOD },
);

has 'token_validation_method' => (
  is      => 'ro',
  isa     => 'TokenValidationMethod',
  lazy    => 1,
  default => sub { shift->config->{token_validation_method}
                     || $DEFAULT_TOKEN_VALIDATION_METHOD },
);

has 'client_assertion_lifetime' => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { shift->config->{client_assertion_lifetime}
                     || $DEFAULT_CLIENT_ASSERTION_LIFETIME },
);

has 'default_token_type' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub { $DEFAULT_TOKEN_TYPE },
);

has 'provider_metadata' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  builder => '_build_provider_metadata',
);

has 'store_mode' => (
  is      => 'ro',
  isa     => 'StoreMode',
  lazy    => 1,
  default => sub { shift->config->{store_mode}
                     || $DEFAULT_STORE_MODE },
);

has 'cache_config' => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { shift->config->{cache_config}
                     || \%DEFAULT_CHI_CONFIG },
);

has 'kid_keys' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  clearer => '_clear_kid_keys',
  builder => '_build_kid_keys',
);

has 'uuid_generator' => (
  is      => 'ro',
  isa     => 'Data::UUID',
  lazy    => 1,
  default => sub { Data::UUID->new() },
);

has 'response_parser' => (
  is      => 'ro',
  isa     => 'OIDC::Client::ResponseParser',
  lazy    => 1,
  default => sub { OIDC::Client::ResponseParser->new() },
);

has 'token_response_parser' => (
  is      => 'ro',
  isa     => 'OIDC::Client::TokenResponseParser',
  lazy    => 1,
  default => sub { OIDC::Client::TokenResponseParser->new() },
);

sub _build_provider ($self) {
  my $provider = $self->config->{provider}
    or croak('OIDC: no provider in config');
  return $provider;
}

sub _build_id ($self) {
  my $id = $self->config->{id}
    or croak('OIDC: no id in config');
  return $id;
}

sub _build_secret ($self) {
  my $secret = $self->config->{secret};
  unless ($secret) {
    my $provider = $self->provider;
    $secret = $ENV{uc "OIDC_${provider}_SECRET"};
  }
  $secret or croak("OIDC: no secret configured or set up in environment");
  return $secret;
}

sub _build_private_key ($self) {
  if (my $private_jwk_file = $self->private_jwk_file) {
    my $private_jwk = decode_json(Mojo::File->new($private_jwk_file)->slurp);
    return $private_jwk;
  }
  elsif (my $private_jwk = $self->private_jwk) {
    return $private_jwk;
  }
  elsif (my $private_key_file = $self->private_key_file) {
    my $private_key = Mojo::File->new($private_key_file)->slurp;
    return \$private_key;
  }
  elsif (my $private_key = $self->config->{private_key}) {
    return \$private_key;
  }
  else {
    croak('OIDC: no private_jwk_file, private_jwk, private_key_file or private_key has been configured');
  }
}

sub _build_audience ($self) {
  return $self->config->{audience} || $self->id;
}

sub _build_user_agent ($self) {
  my $ua = Mojo::UserAgent->new();

  if ($self->proxy_detect) {
    $ua->proxy->detect;
  }

  if (my $user_agent = $self->config->{user_agent}) {
    $ua->transactor->name($user_agent);
  }

  $ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->accept('application/json');
  });

  return $ua;
}

sub _build_claim_mapping ($self) {
  return $self->config->{claim_mapping} || {};
}

sub _build_provider_metadata ($self) {
  my $provider_metadata = {};

  if (my $well_known_url = $self->well_known_url) {
    $provider_metadata = $self->_get_provider_metadata($well_known_url);
  }

  # provider metadata can be overloaded by configuration
  for (qw/authorize_url end_session_url issuer token_url introspection_url userinfo_url jwks_url/) {
    $provider_metadata->{$_} = $self->config->{$_} if exists $self->config->{$_};
  }

  return $provider_metadata;
}

sub _build_kid_keys ($self) {
  my $provider = $self->provider;
  $self->log_msg(info => "OIDC/$provider: fetching JWT kid keys");

  my $jwks_url = $self->provider_metadata->{jwks_url}
    or croak("OIDC: jwks_url not found in provider metadata");

  my $res = $self->user_agent->get($jwks_url)->result;

  return $self->response_parser->parse($res);
}

sub _get_provider_metadata {
  my ($self, $well_known_url) = @_;

  my $provider = $self->provider;
  $self->log_msg(info => "OIDC/$provider: fetching OpenID configuration from $well_known_url");

  my $res = $self->user_agent->get($well_known_url)->result;
  my $provider_config = $self->response_parser->parse($res);

  return {
    authorize_url     => $provider_config->{authorization_endpoint},
    end_session_url   => $provider_config->{end_session_endpoint},
    issuer            => $provider_config->{issuer},
    token_url         => $provider_config->{token_endpoint},
    introspection_url => $provider_config->{introspection_endpoint},
    userinfo_url      => $provider_config->{userinfo_endpoint},
    jwks_url          => $provider_config->{jwks_uri},
  };
}

1;
