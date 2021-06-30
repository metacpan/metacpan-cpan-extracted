package Photonic::Types;
$Photonic::Types::VERSION = '0.017';

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


use Moose::Util::TypeConstraints;
use Photonic::Utils qw(any_complex);

subtype 'Photonic::Types::OddInt' =>
    as 'Int',
    where { $_ % 2 == 1 },
    message { "Number $_ must be odd" };

subtype 'Photonic::Types::ArrayOfOddInts' =>
    as 'ArrayRef[Photonic::Types::OddInt]',
    message { "Numbers [".join(", ", @$_). "] must have been odd" };

subtype 'Photonic::Types::Geometry' =>
  as 'Ref',
  where { $_->does('Photonic::Roles::Geometry')},
  message { "Expected a Geometry" };

subtype 'Photonic::Types::GeometryG0' =>
  as 'Photonic::Types::Geometry',
  where { $_->has_Direction0 },
  message { "You should define a direction for G=0 reciprocal vector" };

subtype 'Photonic::Types::AllH' =>
  as 'Ref',
  where { $_->does('Photonic::Roles::AllH')},
  message { "Expected an AllH" };

subtype 'Photonic::Types::AllHSave' =>
  as 'Photonic::Types::AllH',
  where { $_->keepStates == 1 },
    message { "Can't calculate fields if you don't keepStates" };

subtype 'Photonic::Types::PDLComplex' =>
  as 'PDL',
  where { any_complex($_) },
  ;

no Moose::Util::TypeConstraints;

__END__

=head1 NAME

Photonic::Types

=head1 VERSION

version 0.008

=head1 SYNOPSIS

   use Photonic::Types;
   package MyPackage;
   use Moose;
   has 'n' => {is => 'ro', isa =>'Photonic::Types::OddInt'}

=head1 DESCRIPTION

Define types that are useful in constraining values for Photonic
calculations.

=head1 TYPES

=over 4

=item * Photonic::Types::OddInt

Odd integer

=item * Photonic::Types::ArrayOfOddInts

Array of OddInts

=item * Photonic::Types::GeometryG0

Photonic::Geometry with a direction for G=0 reciprocal vector

=item * Photonic::Types::NonRetarded::AllHSave

Photonic::NonRetarded:AllH object where the keepStates flag has been
turned on.

=back

=cut
