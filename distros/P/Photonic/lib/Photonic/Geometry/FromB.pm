package Photonic::Geometry::FromB;
$Photonic::Geometry::FromB::VERSION = '0.023';

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


use namespace::autoclean;
use Moo;
use Photonic::Types -all;

has 'B' =>(is=>'ro', isa=>PDLObj, required=>1,
	   documentation=>'Characteristic function');

with 'Photonic::Roles::Geometry';


__PACKAGE__->meta->make_immutable; #faster execution

1;


=head1 NAME

Photonic::Geometry::FromB

=head1 VERSION

version 0.023

=head1 SYNOPSIS

     use Photonic::Geometry::FromB;
     my $g=Photonic::Geometry::FromB->new(B=>$pdl);
     my $B=$g->B;
     my $G=$g->G;

=head1 DESCRIPTION

Creates a geometry object to be used in a Photonic
calculation from a characteristic function B. B is a pdl that takes
the values 0 for each pixel or voxel within material A and 1 within
material B.

Consumes L<Photonic::Roles::Geometry>. Please see it for attributes.

=head1 METHODS

=over 4

=item * new(B=>$pdl[, L=>$L] [,units=>$units])

Creates a new Ph::G::FromB object

$L is the size of the unit cell along the cartesian axes. By
default, it is the number of pixels.

$units is an ndarray with the directions of the basis vectors of the
lattice. $units(i,n) is the i-th coordinate of the n-th basis
vector. By default, it is given by the cartesian directions.

=back

=head1 ATTRIBUTES

=head2 B

Characteristic function: a boolean array with 1's and 0's representing
the characteristic function within the unit cell. Its dimensions must
be odd. Its number of dimensions is the dimension of space

=head1 SEE ALSO

L<Photonic::Roles::Geometry>

=cut
