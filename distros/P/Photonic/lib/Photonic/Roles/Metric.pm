package Photonic::Roles::Metric;
$Photonic::Roles::Metric::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::Roles::Metric

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

    use Photonic::WE::R2::Metric;
    my $gGG=Photonic::WE::R2::Metric->new(
            geometry=>$geometry, epsilon=>$eps,
            wavenumber => $q, wavevector=>k);
    f($gGG->value);

=head1 DESCRIPTION

Calculates the retarded metric tensor g_{GG'}^{ij} for use in the
calculation of the retarded Haydock coefficients for the wave
equation.

=head1 METHODS

=over 4

=item * new(geometry=>$g, epsilon=>$e, wavenumber=>$q, wavevector=>$k);

Create a new Ph::WE::R2::Metric object with Geometry $g, dielectric
function of the reference $e, vacuum wavenumber $q=omega/c  and wavevector
$k. $q and $k are real.

=back

=head1 ACCESORS (read only)

=over 4

=item * geometry

The L<Photonic::Types::Geometry> object that describes the geometry of
the system.

=item * epsilon

A reference real dielectric function.

=item * wavenumber

The vacuum wavenumber, w/c, 2PI/lambda.

=item * wavevector

The wavevector.

=item * value

The actual metric tensor as a complex PDL. Provided by implementation.

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use Moose::Role;
use Photonic::Types;

has 'geometry'  => (is=>'ro', isa=>'Photonic::Types::Geometry', required=>1,
                    handles=>[qw(B dims ndims r G GNorm L scale f)],
                    required=>1,
                    documentation=>'Geometry');
has 'epsilon'   => (is=>'ro', isa=>'PDL', required=>1,
		    default=>sub{PDL->pdl(1)},
                   documentation=>'Real reference dielectric function');
has 'wavenumber'=> (is=>'ro', isa=>'PDL', required=>1,
                   documentation=>'Vacuum wavenumber w/c');
has 'wavevector'=> (is=>'ro', isa=>'PDL', required=>1,
                   documentation=>'Wave vector');
requires qw(value); #provided by metric instances

no Moose::Role;

1;
