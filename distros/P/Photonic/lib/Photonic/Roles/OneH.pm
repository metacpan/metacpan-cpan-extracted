package Photonic::Roles::OneH;
$Photonic::Roles::OneH::VERSION = '0.014';

=encoding UTF-8

=head1 NAME

Photonic::Roles::OneH

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

    use Photonic::LE::NR2::OneH;
    my $nr=Photonic::LE::NR2::OneH->new(geometry=>$geometry);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->nextState;

=over 4

=item (for developers)

    package Photonic::LE::NR2::OneH.pm;
    $Photonic::LE::NR2::OneH::VERSION= '0.014';
    use namespace::autoclean;
    use Moose;
    has...
    with 'Photonic::Roles::OneH';

=back

=head1 DESCRIPTION

Roles consumed by OneH objects to be used in a Photonic
calculation. Basic scheme for the calculation of one Haydock
coefficient and one Haydock state at a time.
See also the specific implementations.

=head1 METHODS

=over 4

=item * new(geometry=>$g[, smallH=>$s])

Create a new Photonic::...::OneH object with GeometryG0 $g and optional
smallness parameter  $s.

=back

=head1 ACCESORS (read only)

=over 4

=item * geometry Photonic::Types::GeometryG0

A Photonic::Geometry object defining the geometry of the system,
the charateristic function and the direction of the G=0 vector. Should
be given in the initializer.

=item * B dims r G GNorm L scale f

Accesors handled by geometry (see Photonic::Roles::Geometry)

=item * smallH

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * previousState currentState nextState

The n-1-th, n-th and n+1-th Haydock states

=item * current_a

The n-th Haydock coefficient a

=item * current_b2 next_b2 current_b next_b

The n-th and n+1-th b^2 and b Haydock coefficients

=item * iteration

Number of completed iterations

=back

=head1 METHODS

=over 4

=item * iterate

Performs a single Haydock iteration and updates current_a, next_b,
next_b2, next_state, shifting the current values where necessary. Returns
0 when unable to continue iterating.

=back

=cut

use Moose::Role;

use PDL::Lite;
use PDL::NiceSlice;
use PDL::FFTW3;
use PDL::Complex;
use List::Util;
use Carp;
#use Photonic::Types;
use Moose::Util::TypeConstraints;

requires
    '_firstState', #default first state
    'applyOperator', #Apply Hamiltonian to state
    'innerProduct', #Inner product between states
    'magnitude', #magnitude of a state
    'complexCoeffs', #Haydock coefficients are complex
    'changesign'; #change sign of $b2
has 'firstState' =>(is=>'ro', isa=>'PDL::Complex', lazy=>1,
		    builder=>'_firstState');
has 'previousState' =>(is=>'ro', isa=>'PDL::Complex', writer=>'_previousState',
    init_arg=>undef);
has 'currentState' => (is=>'ro', isa=>'PDL::Complex', writer=>'_currentState',
      lazy=>1, init_arg=>undef,  default=>sub {0+i*0});
has 'nextState' =>(is=>'ro', isa=>maybe_type('PDL::Complex'),
		   writer=>'_nextState',  lazy=>1,
		   builder=>'_firstRState', init_arg=>undef);
has 'current_a' => (is=>'ro', writer=>'_current_a',  init_arg=>undef);
has 'current_b2' => (is=>'ro', writer=>'_current_b2', init_arg=>undef);
has 'next_b2' => (is=>'ro', writer=>'_next_b2', init_arg=>undef,
		  builder=>'_cero');
has 'current_b' => (is=>'ro', writer=>'_current_b', init_arg=>undef);
has 'next_b' => (is=>'ro', writer=>'_next_b', init_arg=>undef,
		 builder=>'_cero');
has 'current_c' => (is=>'ro', writer=>'_current_c', init_arg=>undef);
has 'next_c' => (is=>'ro', writer=>'_next_c', init_arg=>undef,
		 builder=>'_cero');
has 'next_bc' => (is=>'ro', writer=>'_next_bc', init_arg=>undef,
		  builder=>'_cero');
has 'previous_g' => (is=>'ro', writer=>'_previous_g', init_arg=>undef);
has 'current_g' => (is=>'ro', writer=>'_current_g', init_arg=>undef,
     builder=>'_cero');
has 'next_g' => (is=>'ro', writer=>'_next_g', init_arg=>undef);
has 'iteration' =>(is=>'ro', writer=>'_iteration', init_arg=>undef,
                   default=>0);
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');

sub _cero {
    my $self=shift;
    return r2C(0) if $self->complexCoeffs;
    return 0;
}

sub iterate { #single Haydock iteration
    my $self=shift;
    #Note: calculate Current a, next b2, next b, next state
    #Done if there is no next state
    return 0 unless defined $self->nextState;
    $self->_iterate_indeed;
}

sub _fullorthogonalize_indeed {
    #stub for Reorthogonalize do nothing in OneH
    return $_[1];
}

sub _iterate_indeed {
    my $self=shift;
    #Notation: nm1 is n-1, np1 is n+1
    $self->_previousState(my $psi_nm1=$self->currentState);
    $self->_currentState(my $psi_n=$self->nextState);
    $self->_current_b2($self->next_b2);
    $self->_current_b(my $b_n=$self->next_b);
    $self->_current_c(my $c_n=$self->next_c);
    $self->_previous_g(my $g_nm1=$self->current_g);
    $self->_current_g(my $g_n=$self->next_g);
    #Make sure to increment counter before orthogonalizing.
    $self->_iteration($self->iteration+1); #increment counter
    my $opPsi=$self->applyOperator($psi_n);
    my $a_n=$g_n*$self->innerProduct($psi_n, $opPsi);
    my $bpsi_np1=$opPsi-$a_n*$psi_n-$c_n*$psi_nm1;
    $bpsi_np1=$self->_fullorthogonalize_indeed($bpsi_np1);
    my $b2_np1=$self->innerProduct($bpsi_np1, $bpsi_np1);
    my $g_np1=1;
    $g_np1=-1, $b2_np1=-$b2_np1 if $self->changesign($b2_np1);
    my $b_np1=sqrt($b2_np1);
    my $c_np1=$g_np1*$g_n*$b_np1;
    my $bc_np1=$g_np1*$g_n*$b2_np1;
    my $psi_np1;
    $psi_np1=$bpsi_np1/$b_np1 unless $b2_np1->abs<=$self->smallH;
    #save values
    $self->_current_a($self->_coerce($a_n));
    $self->_next_b2($self->_coerce($b2_np1));
    $self->_next_b($self->_coerce($b_np1));
    $self->_next_g($g_np1);
    $self->_next_c($self->_coerce($c_np1));
    $self->_next_bc($self->_coerce($bc_np1));
    $self->_nextState($psi_np1);
    return 1;
}

sub _firstRState {
    my $self=shift;
    my $phi=$self->firstState; #get state from implementation
    my $b2=$self->innerProduct($phi,$phi);
    my $g=1;
    $g=-1, $b2=-$b2 if $self->changesign($b2);
    $b=sqrt($b2);
    $phi=$phi/$b; #first state normalized with metric;
    #skip $self->current_a;
    $self->_next_b2($self->_coerce($b2));
    $self->_next_b($self->_coerce($b));
    $self->_next_c($self->_cero); #no c0
    $self->_next_bc($self->_cero); #no bc0
    $self->_next_g($g);
    return $phi; #goes into _nextState
}



sub _coerce {
    my $self=shift;
    my $val=shift;
    return $val if $self->complexCoeffs;
    return $val->re;
}

no Moose::Role;

1;
