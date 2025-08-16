package OIDC::Client::Identity;
use utf8;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

has 'subject' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'claims' => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

has 'token' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'expires_at' => (
  is       => 'ro',
  isa      => 'Maybe[Int]',
  required => 0,
);

=encoding utf8

=head1 NAME

OIDC::Client::Identity - Identity class

=head1 DESCRIPTION

Class representing an identity

=head1 ATTRIBUTES

=head2 subject

The subject identifier coming from the ID token. Required

=head2 claims

Hashref of claims coming from the ID token. Required

=head2 token

The string of the ID token. Required

=head2 expires_at

The expiration time of the identity (number of seconds since 1970-01-01T00:00:00Z)

=head1 METHODS

=head2 has_expired( $leeway )

  my $has_expired = $identity->has_expired();

Returns whether the identity has expired.

Returns undef if the C<expires_at> attribute is not defined.

The list parameters are:

=over 2

=item leeway

Number of seconds of leeway for the identity to be considered expired before it actually is.

=back

=cut

sub has_expired {
  my $self = shift;
  my ($leeway) = pos_validated_list(\@_, { isa => 'Maybe[Int]', optional => 1 });
  $leeway //= 0;

  return unless defined $self->expires_at;

  return ( $self->expires_at - $leeway ) < time;
}

__PACKAGE__->meta->make_immutable;

1;
