package Photonic::WE::S::Field;
$Photonic::WE::S::Field::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::Field

=head1 VERSION

version 0.023

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

   use Photonic::WE::S::Field;
   my $nrf=Photonic::WE::S::Field->new(...);
   my $field=$nrf->field;

=head1 DESCRIPTION

Calculates the retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

Consumes L<Photonic::Roles::Field>
- please see for attributes.

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::WE::S::Haydock;
use Photonic::Utils qw(cgtsv GtoR linearCombineIt);
use Photonic::Types -all;
use Moo;
use MooX::StrictConstructor;

with 'Photonic::Roles::Field';

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_field {
    my $self=shift;
    my $as=$self->haydock->as;
    my $bs=$self->haydock->bs;
    my $cs=$self->haydock->cs;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->haydock->iteration if $nh>$self->haydock->iteration;
    # calculate using lapack for tridiag system
    my $diag = 1-$as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag = -$bs->(0:$nh-1)->rotate(-1);
    my $supradiag =-$cs->(0:$nh-1)->rotate(-1);
    my $rhs=PDL->zeroes($nh); #build a nh pdl
    $rhs->slice((0)).=1;
    $rhs=$rhs->r2C;
    #coefficients of g^{-1}E
    my $giEs= cgtsv($subdiag, $diag, $supradiag, $rhs);
    #states are xy,pm,nx,ny...
    my $stateit=$self->haydock->states;
    my $ndims=$self->haydock->B->ndims; # num. of dims of space
    #field is xy,pm,nx,ny...
    my $field_G=linearCombineIt($giEs, $stateit); #En ^G|psi_n>
    my $Es=$self->haydock->applyMetric($field_G);
    #Comment as normalization below makes it useless
    #$Es*=$bs->((0))/$self->haydock->metric->epsilon;
    my $Esp=$Es(:,(0)); # choose +k spinor component.
    my $e_0=1/($Esp->slice(":" . ",(0)" x $ndims)
	       *$self->haydock->polarization->conj)->sumover;
    # Normalize result so macroscopic field is 1.
    $Esp*=$e_0;
    $Esp *= $self->filter->(*1) if $self->has_filter;
    ##get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($Esp, $ndims, 1);
    $field_R*=$self->haydock->B->nelem; #scale to have unit macroscopic field
    return $field_R; #result is xy,nx,ny...
}

__PACKAGE__->meta->make_immutable;

1;
