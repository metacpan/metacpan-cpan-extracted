package Photonic::LE::S::Field;
$Photonic::LE::S::Field::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::LE::S::Field

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

   use Photonic::LE::S::Field;
   my $nrf=Photonic::LE::S::Field->new(...);
   my $field=$nrf->field;

=head1 DESCRIPTION

Calculates the non retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

Consumes L<Photonic::Roles::Field>
- please see for attributes.

=head1 ATTRIBUTES

=over 4

=item * epsL

Longitudinal dielectric response, obtained colaterally from last
evaluation of the field

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::LE::S::Haydock;
use Photonic::Utils qw(cgtsv GtoR linearCombineIt);
use Photonic::Types -all;
use Moo;
use MooX::StrictConstructor;

with 'Photonic::Roles::Field';

has 'epsL' =>(is=>'lazy', isa=>PDLComplex, init_arg=>undef,
		 writer=>'_epsL',
		 documentation=>'Longitudinal dielectric response');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_epsL {
    my $self=shift;
    my $field= $self->field; # epsL is side effect of field
    $self->epsL; # danger of infinite recursion?
}


sub _build_field {
    my $self=shift;
    my $as=$self->haydock->as;
    my $bs=$self->haydock->bs;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->haydock->iteration if $nh>$self->haydock->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=$bs->(0:$nh-1)->rotate(-1);
    my $supradiag=$subdiag;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my $result = cgtsv($subdiag, $diag, $supradiag, $rhs);
    # Obtain longitudinal macroscopic response from result
    # Add spinor normalization.
    my $epsL=1/$result->((0));
    $self->_epsL($epsL);
    my $norm=sqrt(2)*$epsL;
    # Normalize result so macroscopic field is 1.
    my $Es = $result*$norm;
    #states are xy,nx,ny...
    my $stateit=$self->haydock->states->slice("*1");
    #pmGnorm is xy,pm,nx,ny...
    my $pmGNorm=$self->haydock->pmGNorm;
    #field is xy,pm,nx,ny...
    my $field_G=linearCombineIt($Es, $pmGNorm*$stateit); #En ^G|psi_n>
    #Choose +k
    my $Esp=$field_G->(:,(0)); #xy,nx,ny
    $Esp *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($Esp, $self->haydock->B->ndims, 1);
    $field_R*=$self->haydock->B->nelem; #scale to have unit macroscopic field
    return $field_R; #result is xy,nx,ny,...
}

__PACKAGE__->meta->make_immutable;

1;
