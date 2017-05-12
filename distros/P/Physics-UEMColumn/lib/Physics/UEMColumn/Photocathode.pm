package Physics::UEMColumn::Photocathode;

=head1 NAME

Physics::UEMColumn::Photocathode - Class representing a photocathode for the Physics::UEMColumn simulation

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Physics::UEMColumn alias => ':standard';

  my $photocathode = Photocathode->new(
    work_function => '4.25 eV',
  );

  # note that $photocathode must have some access to an appropriate Column object

  my $pulse = $photocathode->generate_pulse( 1e8 );

=cut

use Moose;
use namespace::autoclean;

use Method::Signatures;

use MooseX::Types::NumUnit qw/num_of_unit/;
use Physics::UEMColumn::Pulse;
use Physics::UEMColumn::Auxiliary qw/:constants/;

my $type_energy = num_of_unit( 'J' );

=head1 ATTRIBUTES

=over

=item C<work_function>

The "work function" of the material. Rquired. Unit: J

=cut

has 'work_function' => ( isa => $type_energy, is => 'ro', required => 1 );

=item C<location>

The location of the Photocathode in the Column. This value will be used as the location of the generated Pulse object. The default is C<0>.

=cut

has 'location' => ( isa => num_of_unit('m'), is => 'ro', default => 0 );

=item C<column>

Holder for a reference to the containing Column object. This should not be set manually, but will be done by adding the Photocathode object to the Column via its C<photocathode> attribute (either at creation or setter method).

=cut

has 'column' => ( isa => 'Physics::UEMColumn::Column', is => 'rw', predicate => 'has_column' );

=item C<energy_fermi>

The Fermi energy of the material. This was required in a previous version of the code (before using the Dowell result), it is no longer required nor used. Unit: J

=cut

has 'energy_fermi' => ( isa => $type_energy, is => 'ro', predicate => 'has_energy_fermi' ); 

=back

=head1 METHODS

=over

=item C<generate_pulse>

Takes a number which represents the number of electrons to be put in the pulse. This method uses the available information (some of it from the C<column> attribute) to generate a pulse in the manner of a flat metal photocathode. The behavior of this method is likely to change as the flat metal photocathode really ought to be a subclass of some more generic class.

=cut

method generate_pulse ( Num $num ) {
  die 'Photocathode requires access to column object' unless $self->has_column;
  my $column = $self->column;

  die 'Not enough information to create pulse' unless $column->can_make_pulse;

  my $laser = $column->laser;
  my $acc = $column->accelerator;

  my $tau = $laser->duration;
  my $e_laser = $laser->energy;
  my $work_function = $self->work_function;
  my $e_fermi = $self->energy_fermi;

  my $field = $acc->field;

  my $delta_E = $e_laser - $work_function;
  my $velfront = sqrt( 2 * $delta_E / me );

  my $eta_t = me / 3 * ( $e_laser - $work_function );
  my $sigma_z = (($velfront*$tau)**2) / 2 + ( qe / ( 4 * me ) * $field * ($tau**2))**2;

  my $pulse = Physics::UEMColumn::Pulse->new(
    velocity => 0,
    location => $self->location(),
    number   => $num,
    sigma_t  => (($laser->width)**2) / 2,
    sigma_z  => $sigma_z,
    eta_t    => $eta_t,
    eta_z    => $eta_t / 4,
    gamma_t  => 0,
    gamma_z  => sqrt($sigma_z) * ( me * $velfront + qe / sqrt(2) * $field * $tau),
  );

  return $pulse;
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

