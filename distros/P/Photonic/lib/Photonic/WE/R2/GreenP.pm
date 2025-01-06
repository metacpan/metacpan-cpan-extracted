package Photonic::WE::R2::GreenP;
$Photonic::WE::R2::GreenP::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::GreenP

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

   use Photonic::WE::R2::GreenP;
   my $green=Photonic::WE::R2::GreepP->new(haydock=>$h, nh=>$nh, epsB=>$epsB);
   my $greenProjection=$green->Gpp;
   my $WaveProjection=$green->waveOperator;
   my $EpsP=$green->epsilon;

=head1 DESCRIPTION

Calculates the macroscopic Green's function projected along some direction.
Based on the wave equation for a binary metamaterial, with a non-dissipative host.

=head1 ATTRIBUTES

=over 4

=item * haydock

Photonic::WE::R2::Haydock structure (required).

=item * nh

Maximum number of Haydock coefficients to use (required).

=item * epsB

The dielectric functions of component B (required)

=item * smallE

criteria of convergence (defaults to 1e-7)

=item * epsA

The dielectric functions of component A, got from the Haydock's epsilon

=item * u

The spectral variable from the calculation

=item * Gpp

Returns the macroscopic projected Green's function for a given complex
value of the dielectric functions of the particle C<epsB>.

=item * nhActual

The actual number of Haydock coefficients used in the calculation

=item * converged

Flags that the calculation converged before using up all coefficients

=item * waveOperator

Returns the macroscopic wave operator for a given value of the
dielectric functions of the particle C<epsB>. The host's
response C<epsA> is taken from the metric.

NOTE: Only works along principal directions, as it treats Green's
function as scalar.

=item * epsilon

Returns the macroscopic dielectric component for a given value of the
dielectric function of the particle C<epsB>. The host's
response C<epsA> is taken from the Haydock structure.

NOTE: Only works for polarizations along principal directions.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::WE::R2::Haydock;
use Photonic::Types -all;
use Photonic::Utils qw(lentzCF);
use List::Util qw(min);
use Moo;
use MooX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>Num, required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>PDLComplex, init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>PDLComplex, required=>1,
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>PDLComplex, init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

has 'haydock' =>(is=>'ro', isa=>InstanceOf['Photonic::WE::R2::Haydock'], required=>1);
has 'Gpp'=>(is=>'lazy', isa=>PDLComplex, init_arg=>undef);
has 'nhActual'=>(is=>'ro', isa=>Num, init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>Bool, init_arg=>undef, writer=>'_converged');
has 'waveOperator' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
             documentation=>'Wave operator from last evaluation');
has 'epsilon' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
             documentation=>'Wave projection from evaluation');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_Gpp {
    my $self=shift;
    my $h = $self->haydock;
    my $epsA=$h->epsilon->r2C;
    my $epsB=$self->epsB;
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=PDL::r2C($h->as);
    my $bcs=PDL::r2C($h->bcs);
    my $min= min($self->nh, $h->iteration);
    #    b0+a1/b1+a2/...
    #   lo debo convertir a
    #       u-a_0-g0g1b1^2/u-a1-g1g2b2^2/...
    #   entonces bn->u-an y an->-g{n-1}gnbn^2 o -bc_n
    my ($fn, $n)=lentzCF($u-$as, -$bcs, $min, $self->smallE);
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged
    $self->_converged($n<$min || $h->iteration<=$self->nh);
    $self->_nhActual($n);
    my $g0b02=$h->gs->slice("(0)")*$h->b2s->slice("(0)");
    $u*$g0b02/($epsA*$fn);
}

sub _build_waveOperator {
    1/shift->Gpp; #only works along principal directions!!
};

sub _build_epsilon {
    my $self=shift;
    my $wave=$self->waveOperator;
    my $q=$self->haydock->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->haydock->metric->wavevector;
    my $k2=$k->inner($k);
    #my $kk=$k->outer($k);
    my $p=$self->haydock->normalizedPolarization;
    #Note $p->inner($p) might be complex, so is not necessarily 1.
    my $p2=($p*$p)->sumover;
    my $pk=($p*$k)->sumover;
    my $proj=$p2*$k2/$q2 - $pk*$pk/$q2;
    $wave+$proj;
}

__PACKAGE__->meta->make_immutable;

1;
