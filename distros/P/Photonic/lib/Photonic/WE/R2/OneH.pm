package Photonic::WE::R2::OneH;
$Photonic::WE::R2::OneH::VERSION = '0.015';

=encoding UTF-8

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
use PDL::FFTW3;
use PDL::Complex;
use List::Util;
use Carp;
use Moose;
use MooseX::StrictConstructor;
use Photonic::Utils qw(MHProd);

has 'metric'=>(is=>'ro', isa => 'Photonic::WE::R2::Metric',
    handles=>[qw(B ndims dims epsilon)],required=>1);
has 'polarization' =>(is=>'ro', required=>1, isa=>'PDL::Complex');
has 'normalizedPolarization' =>(is=>'ro', isa=>'PDL::Complex',
     init_arg=>undef, writer=>'_normalizedPolarization');
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>0,
		      documentation=>'Haydock coefficients are real');
with 'Photonic::Roles::OneH', 'Photonic::Roles::UseMask';


sub applyOperator {
    my $self=shift;
    my $psi=shift;
    my $mask=undef;
    $mask=$self->mask if $self->use_mask;
    my $gpsi=$self->applyMetric($psi);
    # gpsi is RorI xyz nx ny nz. Get cartesian out of the way and
    # transform to real space. Note FFFTW3 wants real PDL's[2,...]
    my $gpsi_r=ifftn($gpsi->real->mv(1,-1), $self->ndims);
    #$psi_r is RorI nx ny nz  xyz, B is nx ny nz
    # Multiply by characteristic function
    my $Bgpsi_r=Cscale($gpsi_r,$self->B);
    #Bpsi_r is RorI nx ny nz  xyz
    #Transform to reciprocal space, move xyz back and make complex,
    my $psi_G=fftn($Bgpsi_r, $self->ndims)->mv(-1,1)->complex;
    #Apply mask
    #psi_G is ri:xy:nx:ny mask is nx:ny
    $psi_G=$psi_G*$mask->(*1) if defined $mask; #use dummy for xy
    return $psi_G;
}

sub applyMetric {
    my $self=shift;
    my $psi=shift;
    #psi is RorI xy.. nx ny..
    my $g=$self->metric->value;
    #$g is xyz xyz nx ny nz
    my $gpsi=($g*$psi(:,:,*1))->sumover; #matrix times vector
    #$gpsi is RorI xy.. nx ny..
    return $gpsi;
}

sub innerProduct {  #Return Hermitian product with metric
    my $self=shift;
    my $psi1=shift;
    my $psi2=shift;
    my $g=$self->metric->value;
    return MHProd($psi1, $psi2, $g);
}

sub magnitude {
    my $self=shift;
    my $psi=shift;
    return $self->innerProduct($psi, $psi)->abs->sqrt;
}

sub changesign { #flag change sign required if b^2 negative
    return $_[1]->re < 0;
}

sub _firstState {
    my $self=shift;
    my $d=$self->ndims;
    my $v=PDL->zeroes(@{$self->dims}); #build a nx ny nz pdl
    my $arg="(0)" . ",(0)" x ($d-1); #(0),(0),... ndims times
    $v->slice($arg).=1; #delta_{G0}
    my $e=$self->polarization; #RorI xyz
    croak "Polarization has wrong dimensions. " .
	  " Should be $d-dimensional complex vector."
	unless $e->isa('PDL::Complex') && $e->ndims==2 &&
	[$e->dims]->[0]==2 && [$e->dims]->[1]==$d;
    my $modulus2=$e->Cabs2->sumover;
    croak "Polarization should be non null" unless
	$modulus2 > 0;
    $e=$e/sqrt($modulus2);
    $self->_normalizedPolarization($e);
    my $phi=$e*$v(*1); #initial state ordinarily normalized
                       # RorI xyz nx ny nz
    return $phi;
}


__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Photonic::OneH::R2

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Photonic::OneH::R2;
    my $nr=Photonic::OneH::R2->new(metric=>$g, polarization=>$p);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->nextState;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the retarded dielectric function of arbitrary
periodic two component systems in arbitrary number of dimentions. One
Haydock coefficient at a time.

=head1 METHODS

=over 4

=item * new(metric=>$m, polarization=>$e, [, smallH=>$s])

Create a new Ph::OneH::R2 object with PDL::Metric::R2 $m, with a
field along the complex direction $e and with smallness parameter  $s.

=back

=head1 ACCESORS (read only)

=over 4

=item * metric Photonic::Metric::R2

A Photonic::Metric::R2 object defining the geometry of the
system, the charateristic function, the wavenumber, wavevector and
host dielectric function. Required in the initializer.

=item * polarization PDL::Complex

A non null vector defining the complex direction of the macroscopic
field.

=item * smallH

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * B ndims dims epsilon

Accesors handled by metric (see Photonic::Metric::R2)

=item * previousState currentState nextState

The n-1-th, n-th and n+1-th Haydock states; a complex vector for each
reciprocal wavevector

=item * current_a

The n-th Haydock coefficient a

=item * current_b2 next_b2 current_b next_b

The n-th and n+1-th b^2 and b Haydock coefficients

=item * next_c

The n+1-th c Haydock coefficient

=item * previous_g current_g next_g

The n-1-th n-th and n+1-th g Haydock coefficients

=item * iteration

Number of completed iterations

=back

=head1 METHODS

=over 4

=item * iterate

Performs a single Haydock iteration and updates current_a, next_b,
next_b2, next_c, next_g, next_state, shifting the current values where
necessary. Returns 0 when unable to continue iterating.

=item * applyMetric($psi)

Returns the result of applying the metric 'g' to the state; $psi.

=item * applyOperator($psi_G)

Apply the Hamiltonian operator to state. The Hamiltonian is Bg, with g
the metric and B the characteriztic function. Also applies an optional
mask in reciprocal space.

=item * innerProduct($left, $right)

Returns the inner Hermitian product between states using the metric.

=item * $s=magnitude($self, $psi)

Returns the magnitude of a state as the square root of
the inner product of the state with itself.

=item * changesign

Returns 1 if sign change is required to ensure b^2 is positive.

=back

=head1 INTERNAL METHODS

=over 4

=item *  _firstState

Returns the fisrt state $v.

=back

=cut
