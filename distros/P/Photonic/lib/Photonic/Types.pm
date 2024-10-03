package Photonic::Types;
$Photonic::Types::VERSION = '0.023';

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

use Type::Library -base, -declare =>
  qw(Geometry GeometryG0 Haydock HaydockSave PDLObj PDLComplex
  );
use Type::Utils -all;
BEGIN { extends 'Types::Standard' }
use Photonic::Utils qw(any_complex);

declare Geometry =>
  as ConsumerOf['Photonic::Roles::Geometry'],
  message { "Expected a Geometry" };

declare GeometryG0 =>
  as Geometry,
  where { $_->has_Direction0 },
  message { "You should define a direction for G=0 reciprocal vector" };

declare Haydock =>
  as ConsumerOf['Photonic::Roles::Haydock'],
  message { "Expected a Haydock" };

declare HaydockSave =>
  as Haydock,
  where { $_->keepStates == 1 },
    message { "Can't calculate fields if you don't keepStates" };

declare PDLObj =>
  as InstanceOf['PDL'],
  ;

declare PDLComplex =>
  as PDLObj,
  where { any_complex($_) },
  ;

declare PDLComplexMatrix =>
  as PDLComplex,
  where { $_->ndims>=2 && $_->dim(0)==$_->dim(1)},
  ;

declare PDLComplexMatrixField => # NxN matrix for each point in N dimensional space
  as PDLComplexMatrix,
  where { $_->dim(0)==$_->ndims-2},
  ;

__END__

=head1 NAME

Photonic::Types

=head1 VERSION

version 0.023

=head1 SYNOPSIS

   use Photonic::Types -all;
   package MyPackage;
   use Moo;
   has 'n' => {is => 'ro', isa =>Geometry}

=head1 DESCRIPTION

Define types that are useful in constraining values for Photonic
calculations.

=head1 TYPES

=over 4

=item * Geometry

L<Photonic::Roles::Geometry> object.

=item * GeometryG0

L</Geometry> with a direction for G=0 reciprocal vector

=item * Haydock

L<Photonic::Roles::Haydock> object.

=item * HaydockSave

L</Haydock> object where the keepStates flag has been turned on.

=item * PDLComplex

L<PDL> object with complex values.

=back

=cut
