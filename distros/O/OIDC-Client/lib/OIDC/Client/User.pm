package OIDC::Client::User;
use utf8;
use Moose;
use MooseX::Params::Validate;
use namespace::autoclean;

use List::Util qw(any);

=encoding utf8

=head1 NAME

OIDC::Client::User - User class

=head1 DESCRIPTION

Class representing a user.

=cut

has 'login' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'lastname' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'firstname' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'email' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'roles' => (
  is       => 'ro',
  isa      => 'Maybe[ArrayRef[Str]]',
  required => 0,
);

has 'role_prefix' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'uo' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'title' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

=head1 METHODS

=head2 has_role( $role_to_check )

  my $has_role = $user->has_role( $role );

Returns whether the user has a specified role in his C<roles> attribute.

The C<role_prefix> attribute is used to avoid repeating a prefix common to
the roles to check.

The list parameters are:

=over 2

=item role_to_check

Role to check

=back

=cut

sub has_role {
  my $self = shift;
  my ($role_to_check) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });

  my $role_prefix = $self->role_prefix // '';

  return any { $_ eq $role_prefix . $role_to_check } @{ $self->roles || [] };
}

__PACKAGE__->meta->make_immutable;

1;
