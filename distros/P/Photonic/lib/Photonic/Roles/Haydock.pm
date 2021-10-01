package Photonic::Roles::Haydock;
$Photonic::Roles::Haydock::VERSION = '0.021';

=encoding UTF-8

=head1 NAME

Photonic::Roles::Haydock

=head1 VERSION

version 0.021

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
    $Photonic::LE::NR2::Haydock::VERSION= '0.021';
    use namespace::autoclean;
    use Moose;
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

=item * smallH

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * current_state next_state

The n-th and n+1-th Haydock states

=item * current_a

The n-th Haydock coefficient a

=item * next_b2 next_b

The n+1-th b^2 and b Haydock coefficients

=item * iteration

Number of completed iterations

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less (but it starts with a dummy zero).

=item * keepStates

Flag to keep (1) or discard (0) Haydock states

=item * state_iterator

Iterator to provide the previously calculated and saved states. It may
take the states from memory or from a file if provided.

=item * states

Array of Haydock states

=item * as

ndarray of Haydock a coefficients

=item * bs

ndarray of Haydock b coefficients.

=item * b2s

ndarray of Haydock b coefficients squared

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
0 when unable to continue iterating.

=item * run

Runs the iteration to completion.

=item * loadall

Load previously saved state from file, if provided.

=item * storeall

Store final state to file, if provided.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use Moose::Role;

use PDL::Lite;
use Photonic::Types;
use Moose::Util::TypeConstraints;
use Fcntl;
use Photonic::Iterator qw(:all);
use PDL::NiceSlice;
use IO::File;
use Storable qw(store_fd fd_retrieve);
use PDL::IO::Storable;
use Carp;

requires
    '_fullorthogonalize_indeed',
    '_firstState', #default first state
    'applyOperator', #Apply Hamiltonian to state
    'innerProduct', #Inner product between states
    'magnitude', #magnitude of a state
    'complexCoeffs', #Haydock coefficients are complex
    'changesign'; #change sign of $b2
has 'firstState' =>(is=>'ro', isa=>'Photonic::Types::PDLComplex', lazy=>1,
		    builder=>'_firstState');
has 'current_state' => (is=>'ro', isa=>'Photonic::Types::PDLComplex', writer=>'_current_state',
      lazy=>1, init_arg=>undef,  default=>sub {PDL::r2C(0)});
has 'next_state' =>(is=>'ro', isa=>maybe_type('Photonic::Types::PDLComplex'),
		   writer=>'_next_state',  lazy=>1,
		   builder=>'_firstRState', init_arg=>undef);
has 'current_a' => (is=>'ro', writer=>'_current_a',  init_arg=>undef);
my @cero_fields = qw(next_b2 next_b next_c next_bc current_g);
has $_ => (is=>'ro', writer=>"_$_", init_arg=>undef, builder=>'_cero')
  for @cero_fields;
has 'next_g' => (is=>'ro', writer=>'_next_g', init_arg=>undef);
has 'iteration' =>(is=>'ro', writer=>'_iteration', init_arg=>undef,
                   default=>0);
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');

has nh=>(is=>'ro', required=>1,
         documentation=>'Maximum number of desired Haydock coefficients');
has states=>(is=>'ro', isa=>'Photonic::Types::PDLComplex',
         default=>sub{PDL->null}, init_arg=>undef,
         writer=>'_states',
         documentation=>'Saved states');
my @poly_coeffs = (['a'], ['b'], [qw(b2 b^2)], ['c'], [qw(bc b*c)], ['g']);
has "$_->[0]s"=>(is=>'ro', default=>sub{PDL->null}, init_arg=>undef, writer=>"_$_->[0]s",
         isa=>'PDL', documentation=>"Saved @{[$_->[1]||$_->[0].'s']} coefficients")
         for @poly_coeffs;
has reorthogonalize=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize flag');
has 'stateFN'=>(is=>'ro', required=>1, default=>undef,
		documentation=>'Filename to save Haydock states');
has '_stateFD'=>(is=>'ro', init_arg=>undef, builder=>'_build_stateFD',
		lazy=>1, documentation=>'Filedescriptor to save
		Haydock states');
has '_statePos'=>(is=>'ro', init_arg=>undef, default=>sub {[0]},
		 lazy=>1, documentation=>'Position of each state in file');
has 'storeAllFN' =>(is=>'ro', required=>1, default=>undef,
		    documentation=>'Name of file to store everything');
has 'loadAllFN' =>(is=>'ro', required=>1, default=>undef,
		    documentation=>'Name of file to load everything from');
with 'Photonic::Roles::KeepStates', 'Photonic::Roles::Reorthogonalize';
requires qw(iterate magnitude innerProduct
    _checkorthogonalize);

my @allfields= (@cero_fields, (map "$_->[0]s", @poly_coeffs),
    qw(iteration keepStates current_a next_g current_state
    next_state));  # Fields to store and restore

sub _cero {
    my $self=shift;
    return PDL::r2C(0) if $self->complexCoeffs;
    return 0;
}

sub iterate { #single Haydock iteration
    my $self=shift;
    #Note: calculate Current a, next b2, next b, next state
    #Done if there is no next state
    return 0 unless defined $self->next_state;
    #a[n] is calculated together
    #with b[n+1] in each iteration
    my $b_n=$self->_save_val('b', 'next');
    $self->_save_val('b2', 'next');
    $self->_save_val('bc', 'next');
    my $c_n=$self->_save_val('c', 'next');
    my $g_n=$self->_save_val('g', 'next', 'current');
    #Notation: nm1 is n-1, np1 is n+1
    my $psi_nm1=$self->current_state;
    my $psi_n=$self->_save_state;
    $self->_current_state($self->next_state);
    #Make sure to increment counter before orthogonalizing.
    $self->_iteration($self->iteration+1); #increment counter
    my $opPsi=$self->applyOperator($psi_n);
    my $a_n=$g_n*$self->innerProduct($psi_n, $opPsi);
    my $bpsi_np1=$opPsi-$a_n*$psi_n-$c_n*$psi_nm1;
    $bpsi_np1=$self->_fullorthogonalize_indeed($bpsi_np1) if $self->reorthogonalize;
    my $b2_np1=$self->innerProduct($bpsi_np1, $bpsi_np1);
    my $g_np1=1;
    $g_np1=-1, $b2_np1=-$b2_np1 if $self->changesign($b2_np1);
    my $b_np1=sqrt($b2_np1);
    my $c_np1=$g_np1*$g_n*$b_np1;
    my $bc_np1=$g_np1*$g_n*$b2_np1;
    my $psi_np1;
    $psi_np1=$bpsi_np1/$b_np1 unless PDL::all($b2_np1->abs<=$self->smallH);
    #save values
    $self->_current_a($self->_coerce($a_n));
    $self->_next_b2($self->_coerce($b2_np1));
    $self->_next_b($self->_coerce($b_np1));
    $self->_next_g($g_np1);
    $self->_next_c($self->_coerce($c_np1));
    $self->_next_bc($self->_coerce($bc_np1));
    $self->_next_state($psi_np1);
    $self->_save_val('a', 'current');
    return 1 if !$self->reorthogonalize;
    my $to_unwind = $self->_checkorthogonalize;
    $self->_pop while $to_unwind-- > 0; #undoes stack
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
    return $phi; #goes into _next_state
}

sub _coerce {
    my $self=shift;
    my $val=shift;
    return $val if $self->complexCoeffs;
    return $val->re;
}

sub BUILD {
    my $self=shift;
    # Can't reorthogonalize without previous states
    $self->_keepStates(1) if  $self->reorthogonalize;
}

sub state_iterator {
    my $self=shift;
    confess "Can't return states unless keepStates!=0"
	unless $self->keepStates;
    my $n=0;
    my $s=$self->states;
    #warn "statePos: " . scalar(@{$self->_statePos}) . " iteration: "
    #. $self->iteration;
    return Photonic::Iterator->new(sub { #closure
	return if $n>=$self->iteration;
	return _top_slice($s, '('.$n++.')');
    }) unless defined $self->stateFN;
    my $fh=$self->_stateFD;
    return Photonic::Iterator->new(sub {
	return if $n>=$self->iteration;
	#return if $n>=@{$self->_statePos}-1;
	my $pos=$self->_statePos->[$n++];
	seek($fh, $pos, SEEK_SET);
	my $ref=fd_retrieve($fh);
	return $$ref;
    });
}

sub _build_stateFD {
    my $self=shift;
    my $fn=$self->stateFN;
    croak "You didn't provide a stateFN" unless defined $fn;
    my $fh=IO::File->new($fn, "w+")
	or croak "Couldn't open ".$self->stateFN.": $!";
    return $fh;
}

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
    map {my $k="_".$_;$self->$k($all->{$_})} @allfields;
    return unless $self->keepStates;
    foreach(0..$self->iteration-1){
	$self->_next_state(fd_retrieve($fh)); #note: clobber next_state
	$self->_save_state;
    }
    $self->_next_state($all->{next_state}); #restore next_state
}

sub storeall {
    my $self=shift;
    my $fn=$self->storeAllFN;
    return unless defined $fn; # unless you actually want to store everything
    my $fh=IO::File->new($fn, "w")
	or croak "Couldn't open $fn for writing: $!";
    #save all results but states
    my %all=  map {($_=>$self->$_)} @allfields;
    store_fd \%all, $fh or croak "Couldn't store all info; $!";
    return unless $self->keepStates;
    my $si=$self->state_iterator;
    while(defined (my $s=$si->nextval)){
	store_fd $s, $fh or croak "Couldn't store a state: $!";
    }
}

sub _save_val {
    my ($self, $valname, $method, $dest) = @_;
    my $valnames = $valname.'s';
    my $writer = "_$valnames";
    my $value = "${method}_$valname";
    my $pdl = $self->$valnames;
    my $the_value = $self->$value;
    $the_value = pdl($the_value) if !UNIVERSAL::isa($the_value, 'PDL');
    my $to_save = $pdl->isnull ? $the_value->dummy(-1) : $pdl->glue($pdl->getndims-1, $the_value);
    $self->$writer($to_save);
    return $the_value if !$dest;
    my $dest_writer = "_${dest}_$valname";
    $self->$dest_writer($the_value); # writer returns value
}

sub _top_slice {
    my ($pdl, $index) = @_;
    my $slice_arg = join ',', (map ':', 1..($pdl->ndims-1)), $index;
    $pdl->slice($slice_arg);
}

sub _pop_val {
    my ($self, $valname, $pop_dest, $last_dest) = @_;
    my $valnames = $valname.'s';
    my $writer = "_$valnames";
    my $pdl = $self->$valnames;
    confess "popped empty" if $pdl->isnull;
    my @dims = $pdl->dims;
    my $lastval = _top_slice($pdl, "(-1)");
    my $store = "_${pop_dest}_$valname";
    $self->$store($lastval);
    $dims[-1]--; # shrink
    my $copy = PDL->null;
    ($copy = $pdl->copy)->setdims(\@dims) if $dims[-1];
    $self->$writer($copy);
    return if !$last_dest;
    my $last = "_${last_dest}_$valname";
    $self->$last(_top_slice($copy, "(-1)"));
}

sub _save_state {
    my $self=shift;
    return $self->next_state unless $self->keepStates; #noop
    return $self->_save_val('state', 'next') unless defined $self->stateFN;
    my $fh=$self->_stateFD;
    my $lastpos=$self->_statePos->[-1];
    seek($fh, $lastpos, SEEK_SET);
    store_fd \(my $state=$self->next_state), $fh or croak "Couldn't store state: $!";
    my $pos=tell($fh);
    push @{$self->_statePos}, $pos;
    $state;
}

sub _pop_state {
    my $self=shift;
    croak "Can't pop state without keepStates=>1" unless
	$self->keepStates;
    return $self->_pop_val('state', 'next', 'current')
        unless defined $self->stateFN;
    pop @{$self->_statePos};
    my ($snm2, $snm1)=map {
	seek($self->_stateFD, $self->_statePos->[-$_], SEEK_SET);
	fd_retrieve($self->_stateFD);
    } (2,1);
    $self->_next_state($$snm1);
    $self->_current_state($$snm2);
}

sub _pop { # undo the changes done after, in and before iteration, for
	   # reorthogonalization, in reverse order
    my $self=shift;
    $self->_pop_state;
    $self->_pop_val('a', 'current');
    $self->_pop_val('b2', 'next');
    $self->_pop_val('b', 'next');
    $self->_pop_val('c', 'next');
    $self->_pop_val('bc', 'next');
    $self->_pop_val('g', 'next', 'current');
    $self->_iteration($self->iteration-1); #decrement counter
}

no Moose::Role;

1;
