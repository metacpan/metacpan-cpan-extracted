package Photonic::Roles::KeepStates;
$Photonic::Roles::KeepStates::VERSION = '0.011';

=encoding UTF-8

=head1 NAME

Photonic::Roles::KeepStates

=head1 VERSION

version 0.011

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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
   with 'Photonic::Roles::KeepStates;
   has 'myfield' => (is=>'ro');
   ...

=head1 DESCRIPTION

Fields that have been factored as they are common in different
Photonic subpackages to calculate the electromagnetic field

=head1 ACCESORS (read only)

=head2 keepStates

Flag to keep the states that make up a Haydock basis. Default: don't
keep states (0).

=cut

use Moose::Role;



has 'keepStates'=>(is=>'ro', required=>1, default=>0, writer=> '_keepStates',
         documentation=>'flag to save Haydock states');


no Moose::Role;

1;
