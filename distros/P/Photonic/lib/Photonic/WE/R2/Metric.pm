package Photonic::WE::R2::Metric;
$Photonic::WE::R2::Metric::VERSION = '0.016';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::Metric

=head1 VERSION

version 0.016

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

    use Photonic::WE::R2::Metric;
    my $gGG=Photonic::WE::R2::Metric->new(
            geometry=>$geometry, epsilon=>$eps,
            wavenumber => $q, wavevector=>$k);
    f($gGG->value);

=head1 DESCRIPTION

Calculates the retarded metric tensor g_{GG'}^{ij} for use in the
calculation of the retarded Haydock coefficients for the wave equation
in a binary medium where the host has no dissipation.

=head1 METHODS

=over 4

=item * new(geometry=>$g, epsilon=>$e, wavenumber=>$q, wavevector=>$k);

Create a new Ph::WE::R2::Metric object with Geometry $g, dielectric
function of the host $e, vacuum wavenumber $q=omega/c  and wavevector
$k. $q and $k are real.

=back

=head1 ACCESSORS (read only)

=over 4

=item * value

The actual metric tensor as a complex PDL (d,d,n1,n2..nd)
the first and second indices over cartesian indices for 0 to d-1 in d
dimensions, the next d indices n1,n2...nd identify the wavevector G.

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::MatrixOps;
use PDL::NiceSlice;
use Carp;
use Moose;
use MooseX::StrictConstructor;

has 'value'     => (is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
                   builder=>'_value',
                   documentation=>'Metric tensor');

with 'Photonic::Roles::Metric';

sub _value {
    # Evaluate the metric tensor. Eq. 4.37 of Samuel.
    my $self = shift;
    my $G=$self->G; #reciprocal lattice;
    # check epsilon, wavenumber, wavevector real
    my $q=$self->wavenumber;
    my $eps=$self->epsilon;
    my $k=$self->wavevector;
    croak "Wave vector must be ".$self->ndims."-dimensional vector" unless
	$k->dim(0)==$self->ndims and $k->ndims==1;
    my $kPG = $k+$G; #xyz nx ny nz
    # (k+G)(k+G) diad
    my $kPGkPG = $kPG->outer($kPG); #xyz xyz nx ny nz
    # interior product
    my $kPG2 = $kPG->inner($kPG); #nx ny nz
    my $id=identity($self->ndims);
    my $k02=$eps*$q*$q; # squared wavenumber in 'host'
    #xyz xyz nx ny nz
    #cartesian matrix for each wavevector.
    my $gGG=($k02*$id-$kPGkPG)/(($k02-$kPG2)->(*1,*1)); #xyz xyz nx ny nz
    return $gGG;
}


1;
