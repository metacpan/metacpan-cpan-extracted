package Photonic::WE::ST::GreenP;
$Photonic::WE::ST::GreenP::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::WE::ST::GreenP

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

   use Photonic::WE::ST::GreenP;
   my $green=Photonic::WE::ST::GreenP->new(haydock=>$h, nh=>$nh);
   my $greenProjection=$green->Gpp;
   my $WaveProjection=$green->waveOperator;
   my $EpsTensor=$green->epsilon;

=head1 DESCRIPTION

Calculates the dielectric function for a given fixed
L<Photonic::WE::ST::Haydock> structure as a function of the dielectric
functions of the components.

=head1 ATTRIBUTES

=over 4

=item * haydock

The L<Photonic::WE::ST::Haydock> structure (required).

=item * nh

The maximum number of Haydock coefficients to use.

=item * smallE

Criteria of convergence. 0 means don't check. (defaults to 1e-7)

=item * u

The spectral variable used in the calculation

=item * nhActual

The actual number of Haydock coefficients used in the calculation

=item * converged

Flags that the calculation converged before using up all coefficients

=item * waveOperator

The macroscopic wave operator calculated from the metric.

NOTE: Only works along principal directions, as it treats Green's
function as scalar.

=item * epsilon

The macroscopic dielectric projection

NOTE: Only works for polarizations along principal directions.

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use Photonic::WE::ST::Haydock;
use Photonic::Types -all;
use Photonic::Utils qw(lentzCF);
use List::Util qw(min);
use Moo;
use MooX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>Num, required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'haydock' =>(is=>'ro', isa=>Haydock, required=>1);
has 'nhActual'=>(is=>'ro', isa=>Num, init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>Num, init_arg=>undef, writer=>'_converged');
has 'Gpp'=>(is=>'lazy', isa=>PDLComplex, init_arg=>undef,
	      documentation=>'Value of projected Greens function');
has 'waveOperator' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
             documentation=>'Wave operator');
has 'epsilon' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
                   documentation=>'Projected dielectric function');

sub _build_Gpp {
    my $self=shift;
    my $h = $self->haydock;
    $h->run unless $h->iteration;
    my $epsR=$h->epsilonR;
    my $as=$h->as;
    my $bcs=$h->bcs;
    my $min= min($self->nh, $h->iteration);
    #    b0+a1/b1+a2/...
    #	lo debo convertir a
    #       1-a_0-g0g1b1^2/1-a1-g1g2b2^2/...
    #   entonces bn->1-an y an->-g{n-1}gnbn^2 o -bc_n
    my ($fn, $n)=lentzCF(1-$as, -$bcs, $min, $self->smallE);
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged
    $self->_converged($n<$min || $h->iteration<=$self->nh);
    $self->_nhActual($n);
    my $g0b02=$h->gs->slice("(0)")*$h->b2s->slice("(0)");
    return $g0b02/($epsR*$fn);
}

sub _build_waveOperator {
    my $self=shift;
    my $greenP=$self->Gpp;
    my $wave=1/$greenP; #only works along principal directions!!
    return $wave;
}

sub _build_epsilon {
    my $self=shift;
    my $wave=$self->waveOperator;
    my $q=$self->haydock->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->haydock->metric->wavevector;
    my $k2=($k*$k)->sumover; #inner. my $k2=$k->inner($k); only works on real
    my $p=$self->haydock->normalizedPolarization;
    #Note $p->inner($p) might be complex, so is not necessarily 1.
    my $p2=($p*$p)->sumover;
    my $pk=($p*$k)->sumover;
    my $proj=$p2*$k2/$q2 - $pk*$pk/$q2;
    my $eps=$wave+$proj;
    return $eps;
}

__PACKAGE__->meta->make_immutable;

1;
