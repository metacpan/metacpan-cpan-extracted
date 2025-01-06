package Photonic::LE::NP::EpsTensor;
$Photonic::LE::NP::EpsTensor::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::LE::NP::EpsTensor

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

=head1 VERSION

version 0.024

=head1 SYNOPSIS

   use Photonic::LE::NP::EpsTensor;
   my $eps=Photonic::LE::NP::EpsTensor->new(
                     epsilon=>$e, geometry=>$g);
   my $epsilonTensor=$eps->epsTensor;

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor for a given fixed
Photonic::Geometry structure as a function of the dielectric
functions of the components.

Consumes L<Photonic::Roles::EpsTensor>, L<Photonic::Roles::KeepStates>
- please see those for attributes.

=head1 ATTRIBUTES

=over 4

=item * epsilon

A complex PDL giving the value of the dielectric function epsilon
for each pixel of the system

=back

=cut

use namespace::autoclean;
use Photonic::LE::NP::Haydock;
use Photonic::LE::NP::EpsL;
use Photonic::Types -all;
use Moo;
use MooX::StrictConstructor;

has allh_class=>(is=>'ro', default=>'Photonic::LE::NP::Haydock');
has allh_attrs=>(is=>'ro', default=>sub{[qw(reorthogonalize epsilon)]});
has epsl_class=>(is=>'ro', default=>'Photonic::LE::NP::EpsL');
has epsl_attrs=>(is=>'ro', default=>sub{[qw(nh smallE)]});

has 'epsilon'=>(is=>'ro', isa=>PDLComplex, required=>1);

with 'Photonic::Roles::EpsTensor', 'Photonic::Roles::KeepStates';

__PACKAGE__->meta->make_immutable;

1;

__END__
