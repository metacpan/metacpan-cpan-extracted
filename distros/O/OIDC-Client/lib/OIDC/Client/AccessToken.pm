package OIDC::Client::AccessToken;
use utf8;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use Carp qw(croak);
use Digest::SHA qw(sha256 sha384 sha512);
use MIME::Base64 qw(encode_base64url);
use List::Util qw(any);
use OIDC::Client::Error::TokenValidation;

=encoding utf8

=head1 NAME

OIDC::Client::AccessToken - Access Token class

=head1 DESCRIPTION

Class representing an access token

=head1 ATTRIBUTES

=head2 token

The string of the access token. Required

=head2 token_type

The type of the access token

=head2 expires_at

The expiration time of the access token (number of seconds since 1970-01-01T00:00:00Z)

=head2 scopes

The scopes (arrayref) of the access token

=head2 claims

Hashref of claims coming from the access token. Optional, as an access token
is not always decoded, depending on the nature of the application.

=cut

has 'token' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'token_type' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'expires_at' => (
  is       => 'ro',
  isa      => 'Maybe[Int]',
  required => 0,
);

has 'scopes' => (
  is        => 'ro',
  isa       => 'Maybe[ArrayRef[Str]]',
  required  => 0,
  predicate => 'has_scopes',
);

has 'claims' => (
  is       => 'ro',
  isa      => 'Maybe[HashRef]',
  required => 0,
);

=head1 METHODS

=head2 has_scope( $expected_scope )

  my $has_scope = $access_token->has_scope($expected_scope);

Returns whether a scope is present in the scopes of the access token.

=cut

sub has_scope {
  my $self = shift;
  my ($expected_scope) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  return any { $_ eq $expected_scope } @{$self->scopes // []};
}


=head2 has_expired( $leeway )

  my $has_expired = $access_token->has_expired($leeway);

Returns whether the access token has expired.

Returns undef if the C<expires_at> attribute is not defined.

The list parameters are:

=over 2

=item leeway

Number of seconds of leeway for the token to be considered expired before it actually is.

=back

=cut

sub has_expired {
  my $self = shift;
  my ($leeway) = pos_validated_list(\@_, { isa => 'Maybe[Int]', optional => 1 });
  $leeway //= 0;

  return unless defined $self->expires_at;

  return ( $self->expires_at - $leeway ) < time;
}


=head2 compute_at_hash( $alg )

  my $at_hash = $access_token->compute_at_hash($alg);

Returns the computed C<at_hash> for access token. The C<at_hash> is created by
hashing the access token using the algorithm specified in the I<$alg> parameter,
taking the left-most half of the hash, and then base64url encoding it.

=cut

sub compute_at_hash {
  my $self = shift;
  my ($alg) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $digest_func = {
    HS256 => \&sha256, RS256 => \&sha256, PS256 => \&sha256, ES256 => \&sha256,
    HS384 => \&sha384, RS384 => \&sha384, PS384 => \&sha384, ES384 => \&sha384,
    HS512 => \&sha512, RS512 => \&sha512, PS512 => \&sha512, ES512 => \&sha512,
  }->{$alg} or croak("OIDC: unsupported signing algorithm: $alg");

  my $digest = $digest_func->($self->token);
  my $left_half = substr($digest, 0, length($digest)/2);
  return encode_base64url($left_half);
}


=head2 verify_at_hash( $expected_at_hash, $alg )

  $access_token->verify_at_hash($expected_at_hash, $alg);

If the value of the I<$expected_at_hash> parameter is undefined, returns a true value.
Throws an L<OIDC::Client::Error::TokenValidation> exception if the computed C<at_hash> for access
token and specified I<$alg> algorithm does not match the value of the I<$expected_at_hash> parameter.
Otherwise, returns a true value.

=cut

sub verify_at_hash {
  my $self = shift;
  my ($expected_at_hash, $alg) = pos_validated_list(\@_, { isa => 'Maybe[Str]', optional => 0 },
                                                         { isa => 'Str', optional => 0 });
  return 1 unless defined $expected_at_hash;

  my $at_hash = $self->compute_at_hash($alg);

  $at_hash eq $expected_at_hash
    or OIDC::Client::Error::TokenValidation->throw("OIDC: unexpected at_hash");

  return 1;
}


=head2 to_hashref()

  my $access_token_href = $access_token->to_hashref();

Returns a hashref of the access token data.

=cut

sub to_hashref {
  my $self = shift;

  return {
    map { $_ => $self->$_ }
    grep { defined $self->$_ }
    map { $_->name } $self->meta->get_all_attributes
  };
}


__PACKAGE__->meta->make_immutable;

1;
