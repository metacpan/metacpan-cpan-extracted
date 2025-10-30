package OIDC::Client::Role::ConfigurationChecker;
use utf8;
use Moose::Role;
use MooseX::Params::Validate;
use namespace::autoclean;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp qw(croak);
use List::MoreUtils qw(duplicates);

=encoding utf8

=head1 NAME

OIDC::Client::Role::ConfigurationChecker - Configuration checker

=head1 DESCRIPTION

This Moose role covers private methods for checking the configuration.

=cut


requires qw(config
            audience
            store_mode
            token_endpoint_grant_type);


sub _check_configuration ($self) {
  my @config = %{$self->config};

  validated_hash(
    \@config,
    provider                           => { isa => 'Str', optional => 1 },
    store_mode                         => { isa => 'StoreMode', optional => 1 },
    proxy_detect                       => { isa => 'Bool', optional => 1 },
    user_agent                         => { isa => 'Str', optional => 1 },
    id                                 => { isa => 'Str', optional => 1 },
    secret                             => { isa => 'Str', optional => 1 },
    private_jwk_file                   => { isa => 'Str', optional => 1 },
    private_jwk                        => { isa => 'HashRef', optional => 1 },
    private_key_file                   => { isa => 'Str', optional => 1 },
    private_key                        => { isa => 'Str', optional => 1 },
    audience                           => { isa => 'Str', optional => 1 },
    role_prefix                        => { isa => 'Str', optional => 1 },
    well_known_url                     => { isa => 'Str', optional => 1 },
    issuer                             => { isa => 'Str', optional => 1 },
    jwks_url                           => { isa => 'Str', optional => 1 },
    authorize_url                      => { isa => 'Str', optional => 1 },
    token_url                          => { isa => 'Str', optional => 1 },
    introspection_url                  => { isa => 'Str', optional => 1 },
    userinfo_url                       => { isa => 'Str', optional => 1 },
    end_session_url                    => { isa => 'Str', optional => 1 },
    signin_redirect_path               => { isa => 'Str', optional => 1 },
    signin_redirect_uri                => { isa => 'Str', optional => 1 },
    scope                              => { isa => 'Str', optional => 1 },
    refresh_scope                      => { isa => 'Str', optional => 1 },
    identity_expires_in                => { isa => 'Int', optional => 1 },
    expiration_leeway                  => { isa => 'Int', optional => 1 },
    max_id_token_age                   => { isa => 'Int', optional => 1 },
    jwt_decoding_options               => { isa => 'HashRef', optional => 1 },
    client_secret_jwt_encoding_options => { isa => 'HashRef', optional => 1 },
    private_key_jwt_encoding_options   => { isa => 'HashRef', optional => 1 },
    claim_mapping                      => { isa => 'HashRef[Str]', optional => 1 },
    audience_alias                     => { isa => 'HashRef[HashRef]', optional => 1 },
    authorize_endpoint_response_mode   => { isa => 'ResponseMode', optional => 1 },
    authorize_endpoint_extra_params    => { isa => 'HashRef', optional => 1 },
    token_validation_method            => { isa => 'TokenValidationMethod', optional => 1 },
    token_endpoint_grant_type          => { isa => 'GrantType', optional => 1 },
    client_auth_method                 => { isa => 'ClientAuthMethod', optional => 1 },
    token_endpoint_auth_method         => { isa => 'ClientAuthMethod', optional => 1 },
    introspection_endpoint_auth_method => { isa => 'ClientAuthMethod', optional => 1 },
    client_assertion_lifetime          => { isa => 'Int', optional => 1 },
    client_assertion_audience          => { isa => 'Str', optional => 1 },
    username                           => { isa => 'Str', optional => 1 },
    password                           => { isa => 'Str', optional => 1 },
    logout_redirect_path               => { isa => 'Str', optional => 1 },
    post_logout_redirect_uri           => { isa => 'Str', optional => 1 },
    logout_with_id_token               => { isa => 'Bool', optional => 1 },
    logout_extra_params                => { isa => 'HashRef', optional => 1 },
    cache_config                       => { isa => 'HashRef', optional => 1 },
    mocked_identity                    => { isa => 'HashRef', optional => 1 },
    mocked_access_token                => { isa => 'HashRef', optional => 1 },
    mocked_userinfo                    => { isa => 'HashRef', optional => 1 },
  );
}


sub _check_audiences_configuration ($self) {
  my %config_audience_alias = %{ $self->config->{audience_alias} || {} };

  my @possible_audiences = grep { $_ } ($self->audience,
                                        map { $_->{audience} } values %config_audience_alias);

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


sub _check_cache_configuration ($self) {
  if ($self->store_mode eq 'cache') {
    my $grant_type = $self->token_endpoint_grant_type;
    unless ($grant_type eq 'client_credentials' || $grant_type eq 'password') {
      croak("OIDC: you cannot use the 'cache' store mode with the '$grant_type' grant type, "
            . "but only with the 'client_credentials' or 'password' grant types");
    }
  }
}


1;
