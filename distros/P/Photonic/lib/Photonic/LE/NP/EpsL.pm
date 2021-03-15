package Photonic::LE::NP::EpsL;
$Photonic::LE::NP::EpsL::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::LE::NP::EpsL

=head1 VERSION

version 0.015

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

   use Photonic::LE::NP::EpsL;
   my $eps=Photonic::LE::NP::EpsL->new(nr=>$nr, nh=>$nh);
   my $epsilonLongitudinal=$eps->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a given fixed
Photonic::LE::NP::AllH structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr is a Photonic::LE::NP::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence for the continued fraction and
determines the precision of the results. It defaults to 1e-7.

=back

=head1 ACCESORS (read only)

=over 4

=item * epsL

The longitudinal macroscopic function.

=item * nr

The LE::NP::AllH structure

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence for continued fraction. 0 means don't
check.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::LE::NP::AllH;
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

has 'nr' =>(is=>'ro', isa=>'Photonic::LE::NP::AllH', required=>1);
has 'epsL'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsL');
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');

sub BUILD {
    my $self=shift;
    $self->nr->run unless $self->nr->iteration;
    my $as=$self->nr->as;
    my $b2s=$self->nr->b2s;
    # Continued fraction evaluation: Lentz method
    # Numerical Recipes p. 171
    my $tiny=1.e-30;
    my $converged=0;
#    b0+a1/b1+a2/...
#	lo debo convertir a
#	a0-b1^2/a1-b2^2/
#	entonces bn->an y an->-b_n^2
    my $fn=$as->[0];
    $fn=r2C($tiny) if $fn->re==0 and $fn->im==0;
    my $n=1;
    my ($fnm1, $Cnm1, $Dnm1)=($fn, $fn, r2C(0)); #previous coeffs.
    my ($Cn, $Dn); #current coeffs.
    my $Deltan;
    while($n<$self->nh && $n<$self->nr->iteration){
	$Dn=$as->[$n]-$b2s->[$n]*$Dnm1;
	$Dn=r2C($tiny) if $Dn->re==0 and $Dn->im==0;
	$Cn=$as->[$n]-$b2s->[$n]/$Cnm1;
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
    $converged=1 if $self->nr->iteration < $self->nh;
    $self->_converged($converged);
    $self->_nhActual($n);
    $self->_epsL($fn);
}

__PACKAGE__->meta->make_immutable;

1;
