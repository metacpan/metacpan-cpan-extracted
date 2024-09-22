package Photonic::Geometry::FromEpsilon;
$Photonic::Geometry::FromEpsilon::VERSION = '0.022';

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
use Carp;
use Moo;
use Photonic::Types -all;

has 'epsilon'=>(is=>'ro', isa=>PDLComplex, required=>1,
		documentation=>'Dielectric function as function of position');

has 'B' =>(is=>'lazy', isa=>PDLObj, init_arg=>undef,
	   documentation=>'Characteristic function');

with 'Photonic::Roles::Geometry';

#Filling fraction is meaningless in this case (filling fraction is the
#ratio between volumes of b material and the unit cell, tells how much
#b material we have within the unit cell) .
before 'f' => sub {
    croak "Filling fraction is meaningless for "
	. "Photonic::Geometry::FromEpsilon";
};

sub _build_B {
    my $self=shift;
    return $self->epsilon->re; #value is irrelevant. Only
				#shape of pdl counts.
}
#Warning: B has the same shape as the characteristic function, but its
#values are not those of the characteristic function (1 and
#0). Nevertheless, some functions depend on its shape.

__PACKAGE__->meta->make_immutable; #faster execution

1;


=head1 NAME

Photonic::Geometry::FromEpsilon

=head1 VERSION

version 0.022

=head1 SYNOPSIS

     use Photonic::Geometry::FromEpsilon;
     $g=Photonic::Geometry::FromEpsilon->new(epsilon=>$pdl);
     $epsilon=$g->epsilon;


=head1 DESCRIPTION

Creates a geometry object to be used in a Photonic
calculation from a dielectric function which specifies
a complex dielectric function for each pixel or voxel within the unit
cell.

=head1 METHODS

=over 4

=item * new(epsilon=>$pdl[, L=>$L])

Creates a new Ph::G::FromEpsilon object

$pdl is a nx,ny,nz complex pdl whose value is the complex dielectric function for
each point (nx,ny,nz) within the unit cell. The number
of dimensions of its real and imaginary parts are the dimension of
space, and each dimension is the number of voxels of the unit cell along the
corresponding direction.

$L is the size of the unit cell along the cartesian axes. By
default, it is the number of voxels or pixels.

=back

=head1 ACCESSORS (read only)

=over 4

=item * B

The characteristic function as a PDL. Note: this is not the true
characteristic function, but just a PDL with the appropriate shape.

=item * epsilon

The dielectric function as PDL

=item * L

Unit cell sizes as a B->ndims pdl.

=back

=head1 SEE ALSO

L<Photonic::Roles::Geometry>

=begin Pod::Coverage

=head2    PI

=end Pod::Coverage

=cut
