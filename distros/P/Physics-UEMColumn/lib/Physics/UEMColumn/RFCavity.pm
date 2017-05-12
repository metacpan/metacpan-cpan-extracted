package Physics::UEMColumn::RFCavity;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Physics::UEMColumn::Element'; }

use Method::Signatures;

use Physics::UEMColumn::Auxiliary ':constants';
use MooseX::Types::NumUnit qw/num_of_unit/;

has 'strength'  => (isa => num_of_unit('v/m'), is => 'rw', required => 1);
has 'frequency' => (isa => num_of_unit('Hz') , is => 'ro', required => 1);
#has 'radius'    => (isa => 'Num', is => 'ro', required => 1);

has 'phase'     => (isa => 'Num', is => 'ro', default => 0);
has 'order'     => (isa => 'Int', is => 'ro', default => 2);

method effect () {

  my $lens_z = $self->location;
  my $length = $self->length;
  my $str    = $self->strength;
  my $order  = $self->order;
  my $freq   = $self->frequency;
  my $phase  = $self->phase;

  my $cutoff = $self->cutoff;

  my $code_z = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    my $prox = ($pulse_z - $lens_z) / ( $length / 2 );
    if (abs($prox) > $cutoff) {
      return 0;
    }

    my $return = 
      qe / $pulse_v * $str * 2 * pi * $freq 
      * cos( 2 * pi * $freq * ( $pulse_z - $lens_z ) / $pulse_v + $phase)
      * exp( - $prox**(2 * $order));

    return $return;

  };

  my $code_t = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    my $prox = ($pulse_z - $lens_z) / ( $length / 2 );
    if (abs($prox) > $cutoff) {
      return 0;
    }

    my $trig_arg = 2 * pi * $freq * ( $pulse_z - $lens_z ) / $pulse_v + $phase;

    my $mag_comp = 
      $pulse_v / (vc**2) * 2 * pi * $freq 
      * cos( $trig_arg );

    my $end_comp = 
      2 * $order / $length * ($prox**(2 * $order - 1))
      * sin( $trig_arg );

    return -$str * qe * ($mag_comp + $end_comp) * exp( - $prox**(2 * $order));

  };

  my $code_acc = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    my $prox = ($pulse_z - $lens_z) / ( $length / 2 );
    if (abs($prox) > $cutoff) {
      return 0;
    }

    my $return = 
      qe * $str
      * sin( 2 * pi * $freq * ( $pulse_z - $lens_z ) / $pulse_v + $phase)
      * exp( - $prox**(2 * $order));

  };

  return {M_t => $code_t, M_z => $code_z, acc => $code_acc};

}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::RFCavity - A class representing an RF cavity in a UEM system

=head1 SYNOPSIS

 use Physics::UEMColumn alias => ':standard';
 my $rf_cav = RFCavity->new(
   location  => $location . 'cm',
   length    => '2 cm',
   strength  => '230 kilovolts / m',
   frequency => '3 gigahertz',
 );

=head1 DESCRIPTION

L<Physics::UEMColumn::RFCavity> is a class representing a RF cavity (z lens) in a UEM system. It is a subclass of L<Physics::UEMColumn::Element> and inherits its attributes and methods. Additionally it provides:

=head1 ATTRIBUTES

=over

=item C<stength>

The electric field strength of the RF cavity. Unit: V/m

=item C<frequency>

The resonant frequency of the RF Cavity. Unit: Hz

=item C<phase>

The phase offset in radians (i.e. 0 - 2*pi) of the electric field oscillation. In practice this determines the the mode of operation of the cavity (compressor, accelerator). Default is C<0>.

=item C<order>

The super-Gaussian order C<exp( - $x ** ( 2 * $order ) )> determining the shape of the lens. Default is C<2>.

=back

=head1 METHODS

=over

=item C<effect>

Returns a hash reference of effect subroutine references (C<M_t>, C<M_z>, C<acc_z>). See L<Physics::UEMColumn::Element/METHODS> for more.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


