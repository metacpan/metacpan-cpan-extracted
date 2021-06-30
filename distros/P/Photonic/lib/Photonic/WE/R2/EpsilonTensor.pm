package Photonic::WE::R2::EpsilonTensor;
$Photonic::WE::R2::EpsilonTensor::VERSION = '0.017';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::EpsilonTensor

=head1 VERSION

version 0.017

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 SYNOPSIS

   use Photonic::WE::R2::EpsilonTensor;
   my $epsT=Photonic::WE::R2::EpsilonTensor->new(metric=>$m, nh=>$nh);
   my $EpsTensor=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor for a given fixed
Photonic::WE::R2::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallE=>$smallE, smallH=>$smallH,
keepStates=>$k)

Initializes the structure.

$m Photonic::WE::R2::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and for the continued fraction.

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic dielectric tensor for a given value of the
dielectric function of the particle $epsB. The host's
response $epsA is taken from the metric.

=back

=head1 ACCESSORS (read only)

=over 4

=item * epsilonTensor

The macroscopic dielectric tensor of the last operation

=item * All accesors of Photonic::WE::R2::Wave


=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::MatrixOps;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::WE::R2::Wave';

has 'epsilonTensor' =>  (is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
             writer=>'_epsilonTensor',
             documentation=>'Wave operator from last evaluation');

around 'evaluate' => sub {
    my $orig=shift;
    my $self=shift;
    my $wave=$self->$orig(@_);
    my $q=$self->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->metric->wavevector;
    my $k2=$k->inner($k);
    my $kk=$k->outer($k);
    my $id=identity($k);
    my $eps=$wave+$k2/$q2*$id - $kk/$q2;
    $self->_epsilonTensor($eps);
    return $eps;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
