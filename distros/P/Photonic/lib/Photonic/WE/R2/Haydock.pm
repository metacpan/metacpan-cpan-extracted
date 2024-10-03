package Photonic::WE::R2::Haydock;
$Photonic::WE::R2::Haydock::VERSION = '0.023';

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
use Carp;
use Moo;
use MooX::StrictConstructor;
use Photonic::Utils qw(MHProd any_complex GtoR RtoG);
use Photonic::Types -all;

has 'metric'=>(is=>'ro', isa => InstanceOf['Photonic::WE::R2::Metric'],
    handles=>[qw(B ndims dims epsilon)],required=>1);
has 'polarization' =>(is=>'ro', required=>1, isa=>PDLComplex);
has 'normalizedPolarization' =>(is=>'ro', isa=>PDLComplex,
     init_arg=>undef, writer=>'_normalizedPolarization');
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>0,
		      documentation=>'Haydock coefficients are real');
with 'Photonic::Roles::Haydock', 'Photonic::Roles::UseMask';

sub applyOperator {
    my $self=shift;
    my $psi=shift;
    my $mask=undef;
    $mask=$self->mask if $self->use_mask;
    my $gpsi=$self->applyMetric($psi);
    # gpsi is xyz nx ny nz. Get cartesian out of the way and
    # transform to real space. Note FFTW3 wants real PDL's[2,...]
    my $gpsi_r=GtoR($gpsi, $self->ndims, 1)->mv(0,-1);
    #$psi_r is nx ny nz  xyz, B is nx ny nz
    # Multiply by characteristic function
    my $Bgpsi_r=$gpsi_r * $self->B->r2C;
    #Bpsi_r is nx ny nz  xyz
    #Transform to reciprocal space, move xyz back and make complex,
    my $psi_G=RtoG($Bgpsi_r->mv(-1,0), $self->ndims, 1);
    #Apply mask
    #psi_G is xy:nx:ny mask is nx:ny
    $psi_G=$psi_G*$mask->(*1) if defined $mask; #use dummy for xy
    return $psi_G;
}

sub applyMetric {
    my $self=shift;
    my $psi=shift;
    #psi is xy.. nx ny..
    my $g=$self->metric->value;
    #$g is xyz xyz nx ny nz
    my $gpsi=($g*$psi(:,*1))->sumover; #matrix times vector
    #$gpsi is xy.. nx ny..
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

sub _build_firstState {
    my $self=shift;
    my $d=$self->ndims;
    my $v=PDL->zeroes(@{$self->dims}); #build a nx ny nz pdl
    my $arg=join ',', ("(0)") x $d; #(0),(0),... ndims times
    $v->slice($arg).=1; #delta_{G0}
    my $e=$self->polarization; #xyz
    confess "Polarization has wrong dimensions. " .
	  " Should be $d-dimensional complex vector, got ($e)."
	unless any_complex($e) && $e->dim(0)==$d;
    my $modulus2=$e->abs2->sumover;
    confess "Polarization should be non null" unless
	$modulus2 > 0;
    $e=$e/sqrt($modulus2);
    $self->_normalizedPolarization($e);
    my $phi=$e*$v(*1); #initial state ordinarily normalized
                       # xyz nx ny nz
    return $phi;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Photonic::WE::R2::Haydock

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use Photonic::WE::R2::Haydock;
    my $nr=Photonic::WE::R2::Haydock->new(metric=>$g, polarization=>$p);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->next_state;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the retarded dielectric function of arbitrary
periodic two component systems in arbitrary number of dimentions. One
Haydock coefficient at a time.

Consumes L<Photonic::Roles::Haydock>, L<Photonic::Roles::UseMask>
- please see those for attributes.

=head1 ATTRIBUTES

=over 4

=item * metric

A Photonic::Metric::R2 object defining the geometry of the
system, the characteristic function, the wavenumber, wavevector and
host dielectric function. Required in the initializer.

=item * B ndims dims epsilon

Accessors handled by metric (see Photonic::Metric::R2)

=item * polarization

A non null vector defining the complex direction of the macroscopic
field.

=item * normalizedPolarization

The polarisation, normalised

=back

=head1 METHODS

=over 4

=item * applyMetric($psi)

Returns the result of applying the metric 'g' to the state; $psi.

=back

=head1 ATTRIBUTES SUPPLIED FOR ROLE

=over 4

=item * applyOperator($psi_G)

Apply the Hamiltonian operator to state. The Hamiltonian is Bg, with g
the metric and B the characteristic function. Also applies an optional
mask in reciprocal space.

=item * innerProduct($left, $right)

Returns the inner Hermitian product between states using the metric.

=item * $s=magnitude($psi)

Returns the magnitude of a state as the square root of
the inner product of the state with itself.

=item * changesign

Returns 1 if sign change is required to ensure b^2 is positive.

=item * complexCoeffs

Haydock coefficients are real

=back

=cut
