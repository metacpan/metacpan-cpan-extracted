package Photonic::Roles::EpsParams;
$Photonic::Roles::EpsParams::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::Roles::EpsParams

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

   package Photonic::MyPackage;
   use Moose;
   with 'Photonic::Roles::EpsParams;
   has 'myfield' => (is=>'ro');
   ...

=head1 DESCRIPTION

Object fields that have been factored as they are common in different
Photonic subpackages to calculate the macroscopic dielectric function.

=head1 ACCESORS (read only)

=head2 nh

Desired no. of Haydock coefficients

=head2 smallH

Convergence criterium for calculations of Haydock coefficients. Default is 1e-7.

=head2 smallE

Convergence criterium for field calculations using Haydock coefficient use. Default is 1e-7.

=head2 epsA

Dielectric function of host

=head2 epsB

Dielectric function of inclusions

=head2 u

Spectral variable

=cut





use Moose::Role;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

no Moose::Role;

1;
