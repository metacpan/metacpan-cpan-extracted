package Photonic::Roles::UseMask;
$Photonic::Roles::UseMask::VERSION = '0.016';

=encoding UTF-8

=head1 NAME

Photonic::Roles::UseMask

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

=head1 SYNOPSIS

    package 'Mypackage';
    with 'Photonic::Roles::UseMask';
    .
    .
    .
    my $mask=$self->mask if $self->use_mask;

=head1 DESCRIPTION

Factors out use of masks in reciprocal space.

=head1 ATTRIBUTES

=over 4

=item * use_mask

Flag to use a mask.

=item * mask

The actual mask. Default: A mask that filters out the largest
reciprocal vector for each even dimension of reciprocal space.

=back

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Moose::Role;

has 'use_mask'=>(is=>'ro', default=>1, documentation=>'Use mask if present');
has 'mask'=>(is=>'ro', lazy=>1, builder=>'_build_mask',
    documentation=>'Mask in reciprocal space');
#ndims returns the number of dimensions and dims a reference to an
#array with each dimension
requires qw(ndims dims);


sub _build_mask { #default mask kills G_max for even dims.
    my $self=shift;
    my $ndims=$self->ndims;
    my $dims=$self->dims;
    my $mask=PDL->ones(@$dims);
    my $masked=0;
    foreach(0..$ndims-1){
	my $N=$dims->[$_];
	next unless $N%2==0; #ignore odd dimensions.
	$mask->mv($_,0)->(($N/2)).=0; #zero terms corresponding to \pm G_max
	$masked=1;
    }
    return $mask if $masked;
    return undef;
}

no Moose::Role;

1;
