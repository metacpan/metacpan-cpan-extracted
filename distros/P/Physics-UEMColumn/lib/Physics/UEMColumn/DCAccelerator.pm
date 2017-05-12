package Physics::UEMColumn::DCAccelerator;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Physics::UEMColumn::Accelerator'; }

use Method::Signatures;

use Physics::UEMColumn::Auxiliary ':constants';
use Math::Trig qw/tanh sech/;
use MooseX::Types::NumUnit qw/num_of_unit/;

has 'voltage' => ( isa => num_of_unit('V'), is => 'ro', required => 1 );
has 'sharpness' => ( isa => 'Num', is => 'ro', default => 10 );

method field () {
  $self->voltage / $self->length;
}

method effect () {
  my $anode_pos = $self->length;
  my $acc_voltage = $self->voltage;
  my $force = qe * $acc_voltage / $anode_pos;
  my $sharpness = $self->sharpness;

  # cutoff is used oddly here
  my $cutoff = $self->cutoff;

  my $acc = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    if ($pulse_z / $anode_pos > $cutoff) {
      return 0;
    }

    return $force / ( 2 * me ) * ( 1 - tanh( ($pulse_z - $anode_pos) * $sharpness / $anode_pos ) );

  };

  my $acc_mt = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    if ($pulse_z / $anode_pos > $cutoff) {
      return 0;
    }

    return - $force * $sharpness / ( 4 * $anode_pos ) * sech( ($pulse_z - $anode_pos) * $sharpness / $anode_pos ) ** 2;
  };

  my $acc_mz = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    if ($pulse_z / $anode_pos > $cutoff) {
      return 0;
    }

    return $force * $sharpness / ( 2 * $anode_pos ) * sech( ($pulse_z - $anode_pos) * $sharpness / $anode_pos ) ** 2;
  };

  #TODO add anode effects
  return {acc => $acc, M_t => $acc_mt, M_z => $acc_mz};

}

method est_exit_vel () {
  return sqrt( 2 * qe * $self->voltage / me );
}

method est_exit_time () {
  # assumes pulse has initial vel zero
  return $self->length() * sqrt( 2 * me / ( qe * $self->voltage ) );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::DCAccelerator - A class representing a DC acceleration region in a UEM system

=head1 SYNOPSIS

 use Physics::UEMColumn alias => ':standard';
 my $acc = DCAccelerator->new(
   length  => '20 mm',
   voltage => '20 kilovolts',
 );

=head1 DESCRIPTION

L<Physics::UEMColumn::Accelerator> is a class representing a DC (static electric field) acceleration region in a UEM system. It is a subclass of L<Physics::UEMColumn::Accelerator> and inherits its attributes and methods. Additionally it provides:

=head1 ATTRIBUTES

=over

=item C<voltage>

The static electric potential in the accelerator. Unit: V

=item C<sharpness>

The potential is modeled as a C<tanh>, this parameter (defaults to 10) is related to the slope of the tanh near the end of the region. For example a value approaching infinity approximates a step function.

=back

=head1 METHODS

=over

=item C<field>

Defined as C<voltage> / C<length>

=item C<effect>

Returns a hash reference of effect subroutine references (C<M_t>, C<M_z>, C<acc_z>). See L<Physics::UEMColumn::Element/METHODS> for more.

=item C<est_exit_vel>

Returns an estimate of the velocity of the pulse on exiting the region. This in not likely to be exact. It is used in estimating the end time of the simulation. This overrides the base class and is specific to DC accelerators.

=item C<est_exit_time>

Returns an estimate of the time that the pulse on exits the region. This in not likely to be exact. It is used in estimating the end time of the simulation. This overrides the base class and is specific to DC accelerators.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

