package Photonic::WE::S::GreenP;
$Photonic::WE::S::GreenP::VERSION = '0.016';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::GreenP

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

   use Photonic::WE::S::GreenP;
   my $green=Photonic::WE::S::GreepP(haydock=>$h, nh=>$nh);
   my $greenProjection=$green->evaluate($epsB);

=head1 DESCRIPTION

Calculates the dielectric function for a given fixed
Photonic::WE::S::AllH structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$h is a Photonic::WE::S::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence (defaults to 1e-7)

=item * evaluate($epsB)

Returns the macroscopic projected green'S function for a given complex
value of the  dielectric functions of the particle $epsB.

=back

=head1 ACCESSORS (read only)

=over 4

=item * haydock

The WE::S::AllH structure

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

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
use PDL::Complex;
use Photonic::WE::S::AllH;
use Photonic::Types;
use Photonic::Utils qw(lentzCF);
use List::Util qw(min);
use Moose;
use MooseX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'haydock' =>(is=>'ro', isa=>'Photonic::WE::S::AllH', required=>1);
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');
has 'Gpp'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
	    lazy=>1, builder=>'_build_Gpp',
	      documentation=>'Value of projected Greens function');

sub _build_Gpp {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
    my $epsR=$self->haydock->epsilonR;
    my $as=pdl(map r2C($_), @{$self->haydock->as})->cplx;
    my $bcs=pdl(map r2C($_), @{$self->haydock->bcs})->cplx;
    my $min= min($self->nh, $self->haydock->iteration);
    #    b0+a1/b1+a2/...
    #	lo debo convertir a
    #       1-a_0-g0g1b1^2/1-a1-g1g2b2^2/...
    #   entonces bn->1-an y an->-g{n-1}gnbn^2 o -bc_n
    my ($fn, $n)=lentzCF(1-$as, -$bcs, $min, $self->smallE);
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged
    $self->_converged($n<$min || $self->haydock->iteration<=$self->nh);
    $self->_nhActual($n);
    my $g0b02=$self->haydock->gs->[0]*$self->haydock->b2s->[0];
    return $g0b02/($epsR*$fn);
}


__PACKAGE__->meta->make_immutable;

1;
