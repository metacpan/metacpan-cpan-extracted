package Physics::UEMColumn::Column;

=head1 NAME

Physics::UEMColumn::Column - Class representing a column for the Physics::UEMColumn simulation

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Physics::UEMColumn alias => ':standard';

  my $column = Column->new(
    length => '100 cm',
  );

  my $lens = MagneticLens->new(...);
  $column->add_element($lens);

=cut

use Moose;
use namespace::autoclean;

use Method::Signatures;
use MooseX::Types::NumUnit qw/num_of_unit/;

=head1 ATTRIBUTES

=over

=item C<laser>

Holder for an optional L<Physics::UEMColumn::Laser> object. Predicate: C<has_laser>.

=cut

has laser => ( isa => 'Physics::UEMColumn::Laser', is => 'ro', predicate => 'has_laser' );

=item C<accelerator>

Holder for an optional L<Physics::UEMColumn::Accelerator> object. Predicate: C<has_accelerator>.

=cut

has accelerator => ( 
  isa => 'Physics::UEMColumn::Accelerator', 
  is => 'ro', 
  predicate => 'has_accelerator',
  trigger => \&_trigger_accelerator,
);

method _trigger_accelerator ($acc, $old_acc?) {
  my $elements = $self->elements;

  if (eval{ $elements->[0]->isa('Physics::UEMColumn::Accelerator') }) {
    shift @$elements;
  }

  unshift @$elements, $acc;
  
}

=item C<photocathode>

Holder for an optional L<Physics::UEMColumn::Photocathode> object. Predicate: C<has_photocathode>.

=cut

has photocathode => ( 
  isa => 'Physics::UEMColumn::Photocathode', 
  is => 'ro', 
  predicate => 'has_photocathode',
  trigger => sub { $_[1]->column( $_[0] ) },
);

=item C<elements>

An array reference of all the elements in the column. This attribute should rarely be used directly, instead prefer the C<add_element> method.

=cut

has elements => ( 
  traits => ['Array'],
  isa => 'ArrayRef[Physics::UEMColumn::Element]',
  is => 'rw',
  handles => {
    add_element  => 'push',
  },
  default => sub{ [] },
);

=item C<length>

The length of the column. This value is required. This value defines then end of the simulation, in that when the pulse reaches the end of the column, the simulation is complete. Unit: meters.

=cut

has 'length' => ( isa => num_of_unit('m'), is => 'rw', required => 1 );

=back

=head1 METHODS

=over 

=item C<add_element>

Pushes a given L<Physics::UEMColumn::Element> object into the C<elements> attribute. Takes one or more such elements.

=item C<can_make_pulse>

Returns a true value if the column contains enough information to generate a pulse. This specifically means having all of a laser, accelerator, and photocathode objects. Note that should this method return false, a L<Physics::UEMColumn::Pulse> object will have to be manually created and given to the main simulation object (see L<Physics::UEMColumn>).

=cut

method can_make_pulse () {
  return $self->has_laser && $self->has_accelerator && $self->has_photocathode;
}

=back

=cut

__PACKAGE__->meta->make_immutable;

1;

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


