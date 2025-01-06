package Photonic::Roles::Haydock;
$Photonic::Roles::Haydock::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::Roles::Haydock

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

    use Photonic::LE::NR2::Haydock;
    my $nr=Photonic::LE::NR2::Haydock->new(geometry=>$geometry,nh=>$Nh,
            keepStates=>$save);
    $nr->run;
    my $haydock_as=$iter->as;
    my $haydock_bs=$iter->bs;
    my $haydock_b2s=$iter->b2s;

    # or one iteration:
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->next_state;

=over 4

=item (for developers)

    package Photonic::LE::NR2::Haydock;
    $Photonic::LE::NR2::Haydock::VERSION= '0.024';
    use namespace::autoclean;
    use Moo;
    has...
    with 'Photonic::Roles::Haydock';

=back

=head1 DESCRIPTION

Role consumed by Haydock objects to be used in a Photonic
calculation. Basic scheme for the calculation of one Haydock
coefficient and one Haydock state at a time.

Iterates the calculation of Haydock coefficients and states and saves
them for later retrieval.

Consumes L<Photonic::Roles::KeepStates>, L<Photonic::Roles::Reorthogonalize>
- please see those for attributes.

=head1 ATTRIBUTES

=over 4

=item * stateFN

File where the states will be read from and stored, memory-mapped.
See L<PDL::IO::FastRaw> for more information. Ensure that the geometry
dimensions are the same as the states'.

=item * storeAllFN

File in which important attributes will be stored, plus the
calculated coefficients. If no C<stateFN> as above is given, one will
be assumed that is this value suffixed with C<.states>.

=item * loadAllFN

File from which the attributes, coefficients and states will be loaded.
The states will be expected in a file suffixed with C<.states>, and
needs to have been memory-mapped as above.

=item * smallH

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * current_state next_state

The n-th and n+1-th Haydock states

=item * current_a next_a

The n-th and n+1-th Haydock coefficient a

=item * current_b2 next_b2 current_b next_b

The n-th and n+1-th b^2 and b Haydock coefficients

=item * current_bc next_bc current_c next_c current_g next_g

The n-th and n+1-th b*c, c, and g Haydock coefficients

=item * iteration

Number of completed iterations

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less (but it starts with a dummy zero).

=item * keepStates

Flag to keep (1) or discard (0) Haydock states

=item * states

ndarray of Haydock states

=item * as

ndarray of Haydock a coefficients

=item * bs

ndarray of Haydock b coefficients.

=item * b2s

ndarray of Haydock b coefficients squared

=item * bcs

ndarray of Haydock b*c coefficients

=item * cs

ndarray of Haydock c coefficients

=item * gs

ndarray of Haydock g coefficients

=item * converged

Flag that the calculation converged

=item * reorthogonalize

Flag that the calculation should be reorthogonalised

=back

=head1 REQUIRED ATTRIBUTES

These must be supplied by the consuming class:

=over 4

=item * applyOperator($psi_G)

Apply the relevant operator to state $psi_G.

=item * innerProduct($left, $right)

Returns the inner product between states $left and $right.

=item * magnitude($psi_G)

Returns the magnitude of state $psi_G.

=item * changesign

Whether there is a need to change sign.

=item * complexCoeffs

Whether the coefficients are complex.

=back

=head1 METHODS

=over 4

=item * iterate

Performs a single Haydock iteration and updates current_a, next_b,
next_b2, next_state, shifting the current values where necessary. Returns
false when b^2 <= smallH.

=item * run

Runs the iteration to completion.

=item * loadall

Load previously saved state from file, if provided.

=item * storeall

Store final state to file, if provided.

=back

=begin Pod::Coverage

=head2 BUILD

=head2 BUILDARGS

=end Pod::Coverage

=cut

use Moo::Role;

use PDL::Lite;
use Photonic::Types -all;
use Photonic::Utils qw(top_slice);
use PDL::NiceSlice;
use IO::File;
use Storable qw(store_fd fd_retrieve);
use PDL::IO::Storable;
use Carp;

requires
    '_fullorthogonalize_indeed',
    '_build_firstState', #default first state
    'applyOperator', #Apply Hamiltonian to state
    'innerProduct', #Inner product between states
    'magnitude', #magnitude of a state
    'complexCoeffs', #Haydock coefficients are complex
    'changesign'; #change sign of $b2
has 'firstState' =>(is=>'lazy', isa=>PDLComplex);
has 'iteration' =>(is=>'ro', writer=>'_iteration', init_arg=>undef,
                   default=>0);
has 'smallH'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');

has nh=>(is=>'ro', required=>1,
         documentation=>'Maximum number of desired Haydock coefficients');
has "_state_pdl"=>(is=>'lazy', init_arg=>undef, isa=>PDLComplex);
my @poly_coeffs = qw(a b b2 c bc g);
has "_${_}_pdl"=>(is=>'ro', lazy=>1, builder=>'_build_coeff_pdl', init_arg=>undef, isa=>PDLObj)
         for @poly_coeffs;
has reorthogonalize=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize flag');
has 'stateFN'=>(is=>'ro', required=>1, default=>undef,
		documentation=>'Filename to save Haydock states');
has 'storeAllFN' =>(is=>'ro', required=>1, default=>undef,
		    documentation=>'Name of file to store everything');
has 'loadAllFN' =>(is=>'ro', required=>1, default=>undef,
		    documentation=>'Name of file to load everything from');
with 'Photonic::Roles::KeepStates', 'Photonic::Roles::Reorthogonalize';
has 'converged'=>(is=>'ro', isa=>Bool, init_arg=>undef,
                  writer=>'_converged',
                  documentation=>'The calculation did converge');
requires qw(iterate magnitude innerProduct
    _checkorthogonalize);   # why iterate if defined below?

# Fields to store and restore
my @allfields= qw(iteration keepStates converged);

for (@poly_coeffs) {
  no strict 'refs';
  no warnings 'redefine';
  my $pdl_method = "_${_}_pdl";
  # iteration is the quantity finished, so zero-based needs -1
  # the temp var is to avoid a problem on at least 5.14.1
  *{"current_$_"} = sub :lvalue { my ($self)=@_; my $t=top_slice($self->$pdl_method, '('.($self->iteration-1).')'); };
  *{"next_$_"} = sub :lvalue { my ($self)=@_; my $t=top_slice($self->$pdl_method, '('.($self->iteration).')'); };
  *{$_."s"} = sub {
    my ($self)=@_;
    my $i=$self->iteration;
    $i ? top_slice($self->$pdl_method, '0:'.($i-1)) : PDL->null;
  };
}

sub _build_coeff_pdl {
    my ($self) = @_;
    my $pdl = PDL->zeroes($self->nh+1); # +1 to capture "next" coefficients
    $self->complexCoeffs ? $pdl->r2C : $pdl;
}

sub current_state :lvalue {
    my ($self)=@_;
    my $i=$self->iteration;
    my $t=$i ? top_slice($self->_state_pdl, '('.($i-1).')') : PDL::r2C(0);
}
sub next_state :lvalue {
    my ($self)=@_;
    my $t=top_slice($self->_state_pdl, '('.($self->iteration).')');
}
sub states {
    my ($self)=@_;
    my $i=$self->iteration;
    $i ? top_slice($self->_state_pdl, '0:'.($i-1)) : PDL->null;
}

sub _build__state_pdl {
    my ($self) = @_;
    my $fs = $self->_firstRState;
    my $pdl;
    if (my $fn=$self->stateFN) {
	require PDL::IO::FastRaw;
	$pdl = PDL::IO::FastRaw::mapfraw(
	    $fn,
	    {Datatype=>$fs->type, Dims=>[$fs->dims, $self->nh+1], Creat=>!-f $fn},
	);
    } else {
	$pdl = PDL->zeroes($fs->type, $fs->dims, $self->nh+1); # +1 to capture "next"
    }
    (my $t=top_slice($pdl, '(0)')) .= $fs;
    $pdl;
}

sub iterate { #single Haydock iteration
    my $self=shift;
    return 0 if $self->converged;
    #Note: calculate Current a, next b2, next b, next state
    #a[n] is calculated together
    #with b[n+1] in each iteration
    #Notation: nm1 is n-1, np1 is n+1
    my $psi_nm1=$self->current_state;
    $self->_iteration($self->iteration+1); # inc at start so = one we're on
    my $b_n=$self->current_b;
    my $c_n=$self->current_c;
    my $g_n=$self->current_g;
    my $psi_n=$self->current_state;
    my $opPsi=$self->applyOperator($psi_n);
    my $a_n=$g_n*$self->innerProduct($psi_n, $opPsi);
    my $bpsi_np1=$opPsi-$a_n*$psi_n-$c_n*$psi_nm1;
    $bpsi_np1=$self->_fullorthogonalize_indeed($bpsi_np1, $self->gs) if $self->reorthogonalize;
    my $b2_np1=$self->innerProduct($bpsi_np1, $bpsi_np1);
    my $g_np1=1;
    $g_np1=-1, $b2_np1=-$b2_np1 if $self->changesign($b2_np1);
    my $b_np1=sqrt($b2_np1);
    my $c_np1=$g_np1*$g_n*$b_np1;
    my $bc_np1=$g_np1*$g_n*$b2_np1;
    my $psi_np1;
    $psi_np1=$bpsi_np1/$b_np1 unless PDL::all($b2_np1->abs<=$self->smallH);
    #save values
    $self->current_a .= $self->_coerce($a_n);
    $self->next_b2 .= $self->_coerce($b2_np1);
    $self->next_b .= $self->_coerce($b_np1);
    $self->next_g .= $g_np1;
    $self->next_c .= $self->_coerce($c_np1);
    $self->next_bc .= $self->_coerce($bc_np1);
    $self->next_state .= $psi_np1 if defined $psi_np1;
    if ($self->reorthogonalize and defined $psi_np1) {
	my $to_unwind = $self->_checkorthogonalize(
	    map $self->$_, qw(iteration as bs cs next_b current_g next_g)
	);
	$self->_pop while $to_unwind-- > 0; #undoes stack
    }
    $self->_converged(1) if !defined $psi_np1;
    defined $psi_np1; #Done if there is no next state
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
    $self->next_b2 .= $self->_coerce($b2);
    $self->next_b .= $self->_coerce($b);
    $self->next_g .= $g;
    $phi;
}

sub _coerce {
    my $self=shift;
    my $val=shift;
    return $val if $self->complexCoeffs;
    return $val->re;
}

sub BUILD {
    my $self=shift;
    $self->_state_pdl; # trigger build which sets b2, b, g
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    # Can't reorthogonalize without previous states
    $args{keepStates} = 1 if $args{reorthogonalize};
    $args{stateFN} = "$args{storeAllFN}.states"
	if $args{keepStates} and defined $args{storeAllFN} and !defined $args{stateFN};
    $class->$orig(%args);
};

sub run { #run the iteration
    my $self=shift;
    $self->loadall;
    while($self->iteration < $self->nh && $self->iterate){
    }
    $self->storeall;
}

sub loadall {
    my $self=shift;
    my $fn=$self->loadAllFN;
    return unless defined $fn; #nothing to load
    my $fh=IO::File->new($fn, "r")
	or croak "Couldn't open $fn for reading: $!";
    my $all=fd_retrieve($fh);
    map {my $k="_$_";$self->$k($all->{$_})} @allfields;
    my $i = $self->iteration; # not "-1" to capture "next" values calculated
    for (@poly_coeffs) {
	my $pdl_method = "_${_}_pdl";
	(my $t=top_slice($self->$pdl_method, "0:$i")) .= $all->{$_}; # avoid 5.14.1 oddity
    }
    return unless $self->keepStates;
    $fn .= ".states";
    require PDL::IO::FastRaw;
    my $pdl = PDL::IO::FastRaw::mapfraw($fn);
    my $s=$self->_state_pdl;
    (my $t=top_slice($s, "0:$i")) .= top_slice($pdl, "0:$i");
}

sub storeall {
    my $self=shift;
    my $fn=$self->storeAllFN;
    return unless defined $fn; # unless you actually want to store everything
    my $fh=IO::File->new($fn, "w")
	or croak "Couldn't open $fn for writing: $!";
    #save all results but states
    my %all=map +($_=>$self->$_), @allfields;
    my $i = $self->iteration; # not "-1" to capture "next" values calculated
    for (@poly_coeffs) {
	my $pdl_method = "_${_}_pdl";
	$all{$_}=top_slice($self->$pdl_method, "0:$i")->copy;
    }
    store_fd \%all, $fh or croak "Couldn't store all info; $!";
}

sub _pop { # undo the changes done after, in and before iteration, for
	   # reorthogonalization, in reverse order
    my $self=shift;
    $self->_iteration($self->iteration-1); #decrement counter
}

no Moo::Role;

1;
