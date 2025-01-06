package Photonic::LE::S::EpsTensor;
$Photonic::LE::S::EpsTensor::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::LE::S::EpsTensor

=head1 VERSION

version 0.024

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

   use Photonic::LE::S::EpsTensor;
   my $eps=Photonic::LE::S::EpsTensor->new(
                     epsilon=>$e, geometry=>$g);
   my $epsilonTensor=$eps->epsTensor;

=head1 DESCRIPTION

Calculates the dielectric tensor for a given fixed
Photonic::Geometry structure as a function of the dielectric
functions of the components.

Consumes L<Photonic::Roles::EpsTensor>, L<Photonic::Roles::KeepStates>,
L<Photonic::Roles::UseMask>, L<Photonic::Roles::EpsFromGeometry>
- please see those for attributes.

=cut

use namespace::autoclean;
use Photonic::LE::S::Haydock;
use Photonic::LE::S::EpsL;
use Moo;
use MooX::StrictConstructor;

has allh_class=>(is=>'ro', default=>'Photonic::LE::S::Haydock');
has allh_attrs=>(is=>'ro', default=>sub{[qw(reorthogonalize use_mask mask)]});
has epsl_class=>(is=>'ro', default=>'Photonic::LE::S::EpsL');
has epsl_attrs=>(is=>'ro', default=>sub{[qw(nh smallE)]});

with 'Photonic::Roles::UseMask', 'Photonic::Roles::EpsTensor',
    'Photonic::Roles::KeepStates', 'Photonic::Roles::EpsFromGeometry';


__PACKAGE__->meta->make_immutable;

1;
