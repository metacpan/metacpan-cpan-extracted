package Photonic::WE::S::OneH;
$Photonic::WE::S::OneH::VERSION = '0.017';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::OneH

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use Photonic::WE::S::OneH;
    my $nr=Photonic::WE::S::OneH->new(metric=>$g, polarization=>$p);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->nextState;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the retarded dielectric function of arbitrary
periodic systems in arbitrary number of dimensions,  one
Haydock coefficient at a time. It uses the wave equation and the spinor representation.

=head1 METHODS

=over 4

=item * new(metric=>$m, polarization=>$e, [, smallH=>$s])

Create a new Ph::OneH::R2 object with PDL::Metric::R2 $m, with a
field along the complex direction $e and with small convergence parameter $s.

=back

=head1 ACCESSORS (read only)

=over 4

=item * metric Photonic::WE::S::Metric

A L<Photonic::WE::S::Metric> object defining the geometry of the
system, the charateristic function, the wavenumber, wavevector and
host dielectric function. Required in the initializer.

=item * polarization complex PDL

A non null vector defining the complex direction of the macroscopic
field.

=item * smallH

A small number used as tolerance to end the iteration. Small enough
b^2 coefficients are taken to be zero. From L<Photonic::Roles::EpsParams>.

=item * B ndims dims epsilon

Accesors handled by metric (see L<Photonic::WE::S::Metric>)

=item * previousState currentState nextState

The n-1-th, n-th and n+1-th Haydock states at the n-th iteration; a complex vector-spinor for each
reciprocal wavevector. Dimensions ri,xy,pm,nx,ny...

=item * current_a

The n-th Haydock coefficient a

=item * current_b2 next_b2 current_b next_b

The n-th and n+1-th b^2 and b Haydock coefficients

=item * next_c

The n+1-th c Haydock coefficient

=item * previous_g current_g next_g

The n-1-th n-th and n+1-th g Haydock coefficients

=item * iteration

Number n of completed iterations

=back

=head1 METHODS

=over 4

=item * iterate

Performs a single Haydock iteration and updates current_a, next_b,
next_b2, next_c, next_g, next_state, shifting the current values where
necessary. Returns 0 when unable to continue iterating.

=item * applyMetric($psi)

Returns the result of applying the metric to the state $psi.

=item * applyOperator($psi_G)

Apply the 'Hamiltonian' operator to state $psi_G. State is
ri,xy,pn,nx,ny... The Hamiltonian is the metric followed by the
dielectric esponse relative to the reference response.

=item * innerProduct($left, $right)

Returns the inner Euclidean product between states with the metric.

=item * magnitude($psi)

Returns the magnitude of a state as the square root of
the magnitude of inner product of the state with itself.

=item * changesign

Returns 0, as there is no need to change sign.

=back

=head1 INTERNAL METHODS

=over 4

=item * $s= _firstState($self)

Returns the first state $v.

=back

=cut



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


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Carp;
use Photonic::Types;
use Photonic::Utils qw(VSProd any_complex GtoR RtoG);
use Moose;
use MooseX::StrictConstructor;

has 'metric'=>(is=>'ro', isa => 'Photonic::WE::S::Metric',
	       handles=>{B=>'B', ndims=>'ndims', dims=>'dims',
			 geometry=>'geometry', epsilonR=>'epsilon'},
	       required=>1);
has 'polarization' =>(is=>'ro', required=>1, isa=>'Photonic::Types::PDLComplex');
has 'normalizedPolarization' =>(is=>'ro', isa=>'Photonic::Types::PDLComplex',
     init_arg=>undef, writer=>'_normalizedPolarization');
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>1,
		      documentation=>'Haydock coefficients are complex');
with 'Photonic::Roles::OneH',  'Photonic::Roles::UseMask', 'Photonic::Roles::EpsFromGeometry';

#Required by Photonic::Roles::OneH

sub applyOperator {
    my $self=shift;
    my $psi=shift; #psi is ri:xy:pm:nx:ny
    my $mask=undef;
    $mask=$self->mask if $self->use_mask;
    my $gpsi=$self->applyMetric($psi);
    # gpsi is ri:xy:pm:nx:ny. Get cartesian and pm out of the way and
    my $gpsi_r=GtoR($gpsi, $self->ndims, 2)->mv(0,-1)->mv(0,-1);
    #nx:ny:xy:pm
    my $H=($self->epsilonR-$self->epsilon)/$self->epsilonR;
    my $Hgpsi_r=$H*$gpsi_r; #nx:ny:xy:pm
    #Transform to reciprocal space, move xy and pm back and make complex,
    my $psi_G=RtoG($Hgpsi_r->mv(-1,0)->mv(-1,0), $self->ndims, 2);
    #Apply mask
    #psi_G is xy:pm:nx:ny mask is nx:ny
    $psi_G=$psi_G*$mask->(*1,*1) if defined $mask; #use dummies for xy:pm
    return $psi_G;
}

sub applyMetric {
    my $self=shift;
    my $psi=shift;
    #psi is xy:pm:nx:ny
    my $g=$self->metric->value;
    #$g is xy:xy:pm:nx:ny
    #real or complex matrix times complex vector
    my $gpsi=($g*$psi(*1)) #xy:xy:pm:nx:ny
	->sumover; #xy:pm:nx:ny
    return $gpsi;
}

sub innerProduct {  #Return Hermitian product with metric
    my $self=shift;
    my $psi1=shift;
    my $psi2=shift;
    my $gpsi2=$self->applyMetric($psi2);
    return VSProd($psi1, $gpsi2);
}


sub magnitude {
    my $self=shift;
    my $psi=shift;
    return $self->innerProduct($psi, $psi)->abs->sqrt;
}
sub changesign { #don't change sign
    return 0;
}

sub _firstState { #\delta_{G0}
    my $self=shift;
    my $v=PDL->zeroes(2,@{$self->dims})->r2C; #pm:nx:ny...
    my $arg=join ',', ':', ("(0)") x $self->ndims; #(0),(0),... ndims+1 times
    $v->slice($arg).=1/sqrt(2);
    my $e=$self->polarization; #xy
    my $d=$e->dim(0);
    confess "Polarization has wrong dimensions. " .
	  " Should be $d-dimensional complex vector, got ($e)."
	unless any_complex($e) && $e->dim(0)==$d;
    my $modulus2=$e->abs2->sumover;
    confess "Polarization should be non null" unless
	$modulus2 > 0;
    $e=$e/sqrt($modulus2);
    $self->_normalizedPolarization($e);
    #I'm using the same polarization for k and for -k. Could be
    #different (for chiral systems, for example
    my $phi=$e*$v(*1); #initial state ordinarily normalized
                       # xy:pm:nx:ny
    return $phi;
}


__PACKAGE__->meta->make_immutable;

1;
