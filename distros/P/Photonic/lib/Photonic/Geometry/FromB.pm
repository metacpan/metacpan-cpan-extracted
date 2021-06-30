package Photonic::Geometry::FromB;
$Photonic::Geometry::FromB::VERSION = '0.017';

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
use Moose;
use MooseX::StrictConstructor;

has 'B' =>(is=>'ro', isa=>'PDL', required=>1,
	   documentation=>'Charateristic function');

with 'Photonic::Roles::Geometry';


__PACKAGE__->meta->make_immutable; #faster execution

1;


=head1 NAME

Photonic::Geometry::FromB

=head1 VERSION

version 0.017

=head1 SYNOPSIS

     use Photonic::Geometry::FromB;
     my $g=Photonic::Geometry::FromB->new(B=>$pdl);
     my $B=$g->B;
     my $G=$g->G;

=head1 DESCRIPTION

Creates a geometry object to be used in a Photonic
calculation from a characteristic function B. B is a pdl that takes
the values 0 for each pixel or voxel within material A and 1 within
=material B.

=head1 METHODS

=over 4

=item * new(B=>$pdl[, L=>$L])

Creates a new Ph::G::FromB object

$pdl is a boolean array with 1's and 0's representing the characteriztic
function within the unit cell. Its dimensions must be odd. Its number
of dimensions is the dimension of space

$L is the size of the unit cell along the cartesian axes. By
default, it is the number of pixels.

=back

=head1 ACCESSORS (read only)

=over 4

=item * B

The characteristic function as PDL

=item * L

Unit cell sizes as a B->ndims pdl.

=back

=head1 SEE ALSO

L<Photonic::Roles::Geometry>

=begin Pod::Coverage

=head2    PI

=end Pod::Coverage

=cut
