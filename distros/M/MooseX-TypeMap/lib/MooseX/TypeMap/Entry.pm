package MooseX::TypeMap::Entry;

use Moose;
use Scalar::Util qw(blessed);
use namespace::clean -except => [qw( meta )];

our $VERSION = '0.002000';

has data => ( is => 'ro' );
has type_constraint => (
  is => 'ro',
  isa => 'Moose::Meta::TypeConstraint',
  required => 1,
);

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  my $args = $class->$orig(@_);
  my $type = delete $args->{type_constraint};
  $args->{type_constraint} = blessed($type) eq 'MooseX::Types::TypeDecorator'
    ? $type->__type_constraint : $type;
  return $args;
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

MooseX::TypeMap::Entry - A type-constraint-to-data map entry

=head1 SYNOPSIS

    use MooseX::Types::Moose qw(Num);

    MooseX::TypeMap::Entry->new(
       data => 'number',
       type_constraint => Num,
    );

=head1 ATTRIBUTES

=head2 data

An optional read-only value of any kind.

The following methods are associated with this attribute:

=over 4

=item B<data> - reader

=back

=head2 type_constraint

A required, read-only L<Moose::Meta::TypeConstraint>.

The following methods are associated with this attribute:

=over 4

=item B<type_constraint> - reader

=back

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.
Accepts the following keys: C<data>, C<type_constraint>.

=head1 AUTHORS, COPYRIGHT AND LICENSE

Please see L<MooseX::TyeMap>

=cut
