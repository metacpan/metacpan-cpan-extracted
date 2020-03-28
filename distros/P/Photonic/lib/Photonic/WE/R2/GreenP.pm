package Photonic::WE::R2::GreenP;
$Photonic::WE::R2::GreenP::VERSION = '0.014';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::GreenP

=head1 VERSION

version 0.014

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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

   use Photonic::WE::R2::GreenP;
   my $green=Photonic::WE::R2::GreepP(haydock=>$h, nh=>$nh);
   my $greenProjection=$green->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic Green's function projected along some direction.
Based on the wave equation for a binary metamaterial, with a non-dissipative host.

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$h is a Photonic::WE::R2::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence (defaults to 1e-7)

=item * evaluate($epsB)

Returns the macroscopic projected green'S function for a given complex
value of the  dielectric functions of the particle $epsB.

=back

=head1 ACCESORS (read only)

=over 4

=item * haydock

The WE::R2::AllH structure

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

=item * Gpp

The projected Green's function of the last calculation.

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence. 0 means don't check.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::WE::R2::AllH;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

has 'haydock' =>(is=>'ro', isa=>'Photonic::WE::R2::AllH', required=>1);
has 'Gpp'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_Gpp');
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=$self->haydock->epsilon->r2C);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=$self->haydock->as;
    my $bcs=$self->haydock->bcs;
    # Continued fraction evaluation: Lentz method
    # Numerical Recipes p. 171
    my $tiny=1.e-30;
    my $converged=0;
    #    b0+a1/b1+a2/...
    #	lo debo convertir a
    #       u-a_0-g0g1b1^2/u-a1-g1g2b2^2/...
    #   entonces bn->u-an y an->-g{n-1}gnbn^2 o -bc_n
    my $fn=$u-$as->[0];
    $fn=r2C($tiny) if $fn->re==0 and $fn->im==0;
    my $n=1;
    my ($fnm1, $Cnm1, $Dnm1)=($fn, $fn, r2C(0)); #previous coeffs.
    my ($Cn, $Dn); #current coeffs.
    my $Deltan;
    while($n<$self->nh && $n<$self->haydock->iteration){
	$Dn=$u-$as->[$n]-$bcs->[$n]*$Dnm1;
	$Dn=r2C($tiny) if $Dn->re==0 and $Dn->im==0;
	$Cn=$u-$as->[$n]-$bcs->[$n]/$Cnm1;
	$Cn=r2C($tiny) if $Cn->re==0 and $Cn->im==0;
	$Dn=1/$Dn;
	$Deltan=$Cn*$Dn;
	$fn=$fnm1*$Deltan;
	last if $converged=$Deltan->approx(1, $self->smallE)->all;
	$fnm1=$fn;
	$Dnm1=$Dn;
	$Cnm1=$Cn;
	$n++;
    }
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged
    $converged=1 if $self->haydock->iteration < $self->nh;
    $self->_converged($converged);
    $self->_nhActual($n);
    my $g0b02=$self->haydock->gs->[0]*$self->haydock->b2s->[0];
    $self->_Gpp($u*$g0b02/($epsA*$fn));
    return $self->Gpp;
}

__PACKAGE__->meta->make_immutable;

1;
