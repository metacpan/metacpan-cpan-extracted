package Photonic::LE::NR2::Field;
$Photonic::LE::NR2::Field::VERSION = '0.024';


=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::Field

=head1 VERSION

version 0.024

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

   use Photonic::LE::NR2::Field;
   my $nrf=Photonic::LE::NR2::Field->new(epsA=>$epsA, epsB=>$epsB);
   my $field=$nrf->field;

=head1 DESCRIPTION

Calculates the non retarded microscopic electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

Consumes L<Photonic::Roles::Field>
- please see for attributes.

=head1 ATTRIBUTES

=over 4

=item * epsA

Dielectric function of component A

=item * epsB

Dielectric function of component B

=item * u

Spectral variable

=item * epsL

Longitudinal dielectric response, obtained colaterally from last
evaluation of the field

=back

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::LE::NR2::Haydock;
use Photonic::Utils qw(cgtsv GtoR linearCombineIt);
use Photonic::Types -all;
use Moo;
use MooX::StrictConstructor;

with 'Photonic::Roles::Field';

has 'epsL' =>(is=>'lazy', isa=>PDLComplex, init_arg=>undef,
		 writer=>'_epsL',
		 documentation=>'Longitudinal dielectric response');
has 'epsA'=>(is=>'ro', isa=>PDLComplex,
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>PDLComplex,
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'lazy', isa=>PDLComplex, init_arg=>undef,
    documentation=>'Spectral variable');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_epsL {
    my $self=shift;
    my $field= $self->field; # epsL is side effect of field
    $self->epsL; # danger of infinite recursion?
}

sub _build_u {
    my $self=shift;
    1/(1-$self->epsB/$self->epsA);
}

sub _build_field {
    my $self=shift;
    my $epsA=$self->epsA;
    my $epsB=$self->epsB;
    my $u=$self->u;
    my $as=$self->haydock->as;
    my $bs=$self->haydock->bs;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->haydock->iteration if $nh>=$self->haydock->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$u - $as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-$bs->(0:$nh-1)->rotate(-1)->r2C;
    my $supradiag=$subdiag;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my $result = cgtsv($subdiag, $diag, $supradiag, $rhs);
    # Obtain longitudinal macroscopic response from result
    my $Norm=1/$result->((0)); # Normalization for field, 1/E_M
    $self->_epsL($Norm*$epsA/$u);
    # Normalize result so macroscopic field is 1.
    #states are nx,ny...
    my $stateit=$self->haydock->states->dummy(0);
    my $Es= $result*$Norm;
    my $nrGnorm = $self->haydock->GNorm;
    #field is cartesian,nx,ny...
    my $field_G=linearCombineIt($Es, $nrGnorm*$stateit); #En ^G|psi_n>
    $field_G *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($field_G, $self->haydock->ndims, 1);
    $field_R*=$self->haydock->B->nelem; #scale to have unit macroscopic field
    return $field_R; #result is cartesian, nx, ny,...
}

__PACKAGE__->meta->make_immutable;

1;
