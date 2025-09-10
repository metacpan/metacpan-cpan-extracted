package OIDC::Client::AccessTokenBuilder;

use utf8;
use Moose;
use Moose::Exporter;
use MooseX::Params::Validate;
use List::Util qw(first);
use OIDC::Client::AccessToken;

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
  my $expires_at = _get_expiration_time_from_expires_in($token_response->expires_in);
  my $scopes     = _get_values_from_space_delimited_string($token_response->scope);

  return OIDC::Client::AccessToken->new(
    token => $token_response->access_token,
    defined $token_type ? (token_type    => $token_type) : (),
    defined $expires_at ? (expires_at    => $expires_at) : (),
    defined $scopes     ? (scopes        => $scopes) : (),
  );
}


=head2 build_access_token_from_claims( $claims, $token )

Builds an L<OIDC::Client::AccessToken> object from claims (hashref) and token (string).

=cut

sub build_access_token_from_claims {
  my ($claims, $token) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 },
                                                 { isa => 'Str', optional => 0 });

  my $expires_at = $claims->{exp};
  my $scopes     = _get_scopes_from_claims($claims);

  return OIDC::Client::AccessToken->new(
    token  => $token,
    claims => $claims,
    defined $expires_at ? (expires_at => $expires_at) : (),
    defined $scopes     ? (scopes     => $scopes) : (),
  );
}

sub _get_expiration_time_from_expires_in {
  my ($expires_in) = pos_validated_list(\@_, { isa => 'Maybe[Int]', optional => 0 });
  return defined $expires_in ? _get_time() + $expires_in : undef;
}

sub _get_scopes_from_claims {
  my ($claims) = pos_validated_list(\@_, { isa => 'HashRef', optional => 0 });

  my $claim_name = first { defined $claims->{$_} } qw( scp scope )
    or return;

  my $scopes = $claims->{$claim_name};

  unless (ref $scopes) {
    return _get_values_from_space_delimited_string($scopes);
  }

  return ref $scopes eq 'ARRAY' ? $scopes : [];
}

sub _get_values_from_space_delimited_string {
  my ($str) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 0 });
  return unless defined $str;
  return [ grep { $_ ne '' } split(/\s+/, $str) ];
}

# to be mocked in tests
sub _get_time {
  return time();
}

1;
