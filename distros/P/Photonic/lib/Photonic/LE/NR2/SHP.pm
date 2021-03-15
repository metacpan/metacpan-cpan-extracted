package Photonic::LE::NR2::SHP;
$Photonic::LE::NR2::SHP::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::SHP

=head1 VERSION

version 0.015

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

   use Photonic::LE::NR2::SHP;
   my $nrshp=Photonic::LE::NR2::SHP->
             new(nrf=>$nrf, densityA=>$dA, densityB=>$dB));



=head1 DESCRIPTION

Prepares the data for the calculation of the non retarded SH
polarization of an arbitrary periodic composite made up of
centrosymmetric isotropic component materials, using the continuous
dipolium model.

=head1 METHODS

=over 4

=item * new(nrf=>$nrf, densityA=>$dA, densityB=>$dB)

Initializes the structure

$nrf Photonic::LE::NR2::Field is a Haydock field calculator for the
structure.

$dA is the density of polarizable entities in medium A

$dB is the density of polarizable entities in medium B

=back

=head1 ACCESORS (read only)

=over 4

=item * nrf

Photonic::LE::NR2::Field Haydock field calculator

=item * densityA, densityB

Normalized (to what?) dipole entities density in media A and B

=item * density

Density field over unit cell

=item * ndims

Number of dimensions of the system

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Moose;
use MooseX::StrictConstructor;

has 'nrf'=>(is=>'ro', isa=>'Photonic::LE::NR2::Field', required=>1,
         documentation=>'Haydock field calculator');
has 'densityA'=>(is=>'ro', isa=>'Num', required=>1,
         documentation=>'Normalized dipole entities density in medium A');
has 'densityB'=>(is=>'ro', isa=>'Num', required=>1,
         documentation=>'Normalized dipole entities density in medium B');
has 'density'=>(is=>'ro', isa=>'PDL', writer=>'_density', init_arg=>undef,
         documentation=>'Normalized dipole entities density over unit cell');
has 'ndims' =>(is=>'ro', isa=>'Int', init_arg=>undef, lazy=>1,
         builder=>'_ndims',
         documentation=>'Number of dimensions of system');

sub BUILD {
    my $self=shift;
    my $B=$self->nrf->nr->B;
    $self->_density($self->densityA*(1-$B)+$self->densityB*$B);
}

sub _ndims {
    my $self=shift;
    return $self->nrf->nr->B->ndims;
}

__PACKAGE__->meta->make_immutable;

1;
