package OIDC::Client::AccessTokenBuilder;

use utf8;
use Moose;
use Moose::Exporter;
use MooseX::Params::Validate;
use List::Util qw(first);
use OIDC::Client::AccessToken;
use OIDC::Client::Utils qw(get_values_from_space_delimited_string);

=encoding utf8

=head1 NAME

OIDC::Client::AccessTokenBuilder - AccessToken object builder

=head1 DESCRIPTION

Exports functions that help create an L<OIDC::Client::AccessToken> object.

=cut

Moose::Exporter->setup_import_methods(as_is => [qw/build_access_token_from_token_response
                                                   build_access_token_from_claims/]);


=head1 FUNCTIONS

=head2 build_access_token_from_token_response( $token_response )

Builds an L<OIDC::Client::AccessToken> object from an L<OIDC::Client::TokenResponse> object.

=cut

sub build_access_token_from_token_response {
  my ($token_response) = pos_validated_list(\@_, { isa => 'OIDC::Client::TokenResponse', optional => 0 });

  my $token_type = $token_response->token_type;
  my $expires_at = defined $token_response->expires_in ? _get_time() + $token_response->expires_in
                                                       : undef;
  my $scopes = defined $token_response->scope ? get_values_from_space_delimited_string($token_response->scope)
                                              : undef;

  return OIDC::Client::AccessToken->new(
    token => $token_response->access_token,
    defined $token_type ? (token_type => $token_type) : (),
    defined $expires_at ? (expires_at => $expires_at) : (),
    defined $scopes     ? (scopes     => $scopes    ) : (),
  );
}


=head2 build_access_token_from_claims( $claims, $token )

Builds an L<OIDC::Client::AccessToken> object from claims (hashref) and token (string).

=cut

sub build_access_token_from_claims {
  my ($claims, $token) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                 { isa => 'Str', optional => 0 });

  my $token_type = $claims->{token_type};
  my $expires_at = $claims->{exp};
  my $scopes     = _get_scopes_from_claims($claims);

  return OIDC::Client::AccessToken->new(
    token  => $token,
    claims => $claims,
    defined $token_type ? (token_type => $token_type) : (),
    defined $expires_at ? (expires_at => $expires_at) : (),
    defined $scopes     ? (scopes     => $scopes    ) : (),
  );
}

sub _get_scopes_from_claims {
  my ($claims) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 });

  my $claim_name = first { defined $claims->{$_} } qw( scp scope )
    or return;

  my $scopes = $claims->{$claim_name};

  unless (ref $scopes) {
    return get_values_from_space_delimited_string($scopes);
  }

  return ref $scopes eq 'ARRAY' ? $scopes : [];
}

# to be mocked in tests
sub _get_time {
  return time();
}

1;
