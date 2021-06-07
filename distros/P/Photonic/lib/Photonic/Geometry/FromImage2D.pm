package Photonic::Geometry::FromImage2D;
$Photonic::Geometry::FromImage2D::VERSION = '0.016';

=encoding UTF-8

=head1 NAME

Photonic::Geometry::FromImage2D

=head1 VERSION

version 0.016

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

   use Photonic::Geometry::FromImage2D;
   my $g=Photonic::Geometry::FromImage2D->new(path=>$filename);
   my $path=$g->path;
   my $B=$g->B;
   my $G=$g->G;

=head1 DESCRIPTION

Creates a geometry object to be used in a Homogeneization
calculation using as input a monochromatic 2D image.

=head1 METHODS

=over 4

=item * new(path=>$p, L=>$L, inverted=>$i)

Creates a new H::G::F object

$p is the filename of a 2D monochromatic image with white regions
corresponding to the B region and black corresponding to A, unless
inverted. Its size must be odd along both directions.

$L is the size of the unit cell along the cartesian axes. By
default, it is the number of pixels.

$i controls whether the characteriztic function ought to be
inverted: 1 means invert, 0 don't invert. Default: 0

=back

=head1 ACCESSORS (read only)

=over 4

=item * path

The filename containing the image

=item * For the other accesors, see Photonic::Geometry

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=head1 SEE ALSO

L<Photonic::Roles::Geometry>


=cut

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

BEGIN {
# Put inoffensive path. Or else, PDL::IO::Pic fails in taint mode.
    $ENV{'PATH'} = '/bin:/usr/bin';
}

use PDL::Lite;
use PDL::IO::Pic qw();
use Carp;

has 'path' => ( is => 'ro', required => 1,
	       documentation => 'File name of 2D monochrome image' );
has 'B' => (is=>'ro', init_arg=>undef, lazy=>1, builder=>'_build_B' );
has 'inverted' => (is=>'ro', default=> 0,
               documentation=>'Flag to invert black/white');

with 'Photonic::Roles::Geometry';

sub _build_B {
    my $self=shift;
    my $path=$self->path;
    ( $path ) = ($path =~ m|^([A-Z0-9_.-\\/]+)$|ig);
    ($ENV{PATH})=($ENV{PATH}=~m|^([A-Z0-9_.-\\/]+)$|ig);
    confess
	"Only letters, numbers, underscores, dots, slashes and hyphens " .
	"allowed in file names"
	unless $path;
    # Risky: use internal routine PDL::IO::Pic::chkform to get image type
    my $canread=PDL->rpiccan(PDL::IO::Pic::chkform($path));
    confess "Unknown image format of file $path" unless $canread;
    my $B=PDL->rpic($path);
    confess "Please convert image $self->path to 2D monochrome B/W first"
	if $B->ndims != 2 || (($B|!$B)!=1)->any;
    $B=!$B if $self->inverted;
    return $B;
}

__PACKAGE__->meta->make_immutable; #faster execution


1;
