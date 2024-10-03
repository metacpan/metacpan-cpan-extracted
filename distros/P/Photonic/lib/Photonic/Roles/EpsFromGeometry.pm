package Photonic::Roles::EpsFromGeometry;
$Photonic::Roles::EpsFromGeometry::VERSION = '0.023';

=encoding UTF-8

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

use Moo::Role;
use Photonic::Types -all;

requires 'geometry';

has 'epsilon'=>(is=>'lazy', isa=>PDLComplex, required=>1);

sub _build_epsilon { shift->geometry->epsilon }

no Moo::Role;

1;

=head1 NAME

Photonic::Roles::EpsFromGeometry

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    package Photonic::LE::NP::Haydock;
    use Moo;
    with 'Photonic::Roles::EpsFromGeometry';

=head1 DESCRIPTION

Encapsulates having an C<epsilon> attribute that can either be provided,
or built from a C<geometry> attribute.

=cut

1;
