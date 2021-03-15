package Photonic::Roles::AllH;
$Photonic::Roles::AllH::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::Roles::AllH

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

=head1 SYNOPSIS

   use Photonic::LE::NR2::AllH;
   my $iter=Photonic::LE::NR2::AllH->new(geometry=>$geometry,nh=>$Nh,
            keepStates=>$save);
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;
   my $haydock_states=$iter->states;

=over 4

=item (for developers)

    package Photonic::LE::NR2::AllH;
    $Photonic::LE::NR2::AllH::VERSION= '0.015';
    use namespace::autoclean;
    use Moose;
    has...
    with 'Photonic::Roles::OneH';

=back

=head1 DESCRIPTION

Roles consumed by AllH objects to be used in a Photonic
calculation. See also specific implementations. Iterates the
calculation of Haydock coefficients and states and saves them for later retrieval.

=head1 METHODS

=over 4

=item * new(nh=>$nh, geometry=>$g, keepStates=>$k)

Initializes an Ph::...::AllH object. $nh is the maximum number of desired
coefficients, $k is a flag, non zero to save the Haydock
states. All other arguments are as in Photonic::...::OneH.

=item * run

Runs the iteration to completion.

=item * loadall

Load previously saved state from file, if provided.

=item * storeall

Store final state to file, if provided.

=item * All the Photonic::...::OneH methods

=back

=head1 ACCESORS (read only)

=over 4

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

Array of Haydock a coefficients

=item * bs

Array of Haydock b coefficients.

=item * b2s

Array of Haydock b coefficients squared

=item * All the Photonic::...::OneH methods

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use Fcntl;
use Machine::Epsilon;
use Photonic::Iterator qw(:all);
use PDL::Lite;
use PDL::Complex;
use PDL::NiceSlice;
use IO::File;
use Storable qw(store_fd fd_retrieve);
use PDL::IO::Storable;
use Carp;
use Moose::Role;

has nh=>(is=>'ro', required=>1,
         documentation=>'Maximum number of desired Haydock coefficients');
# Moved to Role below
#has 'keepStates'=>(is=>'ro', required=>1, default=>0, writer=> '_keepStates',
#         documentation=>'flag to keep Haydock states');
has _states=>(is=>'ro', isa=>'ArrayRef[PDL::Complex]',
         default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved states');
# why not pdl?
has as=>(is=>'ro', default=>sub{[]}, init_arg=>undef, writer=>'_as',
         documentation=>'Saved a coefficients');
has bs=>(is=>'ro', default=>sub{[]}, init_arg=>undef,  writer=>'_bs',
         documentation=>'Saved b coefficients');
has b2s=>(is=>'ro', default=>sub{[]}, init_arg=>undef,  writer=>'_b2s',
         documentation=>'Saved b^2 coefficients');
has cs=>(is=>'ro', default=>sub{[]},
	 init_arg=>undef,  writer=>'_cs',
         documentation=>'Saved c coefficients');
has bcs=>(is=>'ro', default=>sub{[]},
	  init_arg=>undef, writer=>'_bcs',
         documentation=>'Saved b*c coefficients');
has gs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]},
	 init_arg=>undef,  writer=>'_gs',
         documentation=>'Saved g coefficients');
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
with 'Photonic::Roles::KeepStates';
#provided by OneH instance
requires qw(iterate _iterate_indeed magnitude innerProduct
    _checkorthogonalize);

my @allfields= qw(iteration keepStates as bs b2s cs bcs gs current_a next_b
    next_b2 next_bc next_c current_g next_g previousState currentState
    nextState);  # Fields to store and restore


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
    my $s=$self->_states;
    #warn "statePos: " . scalar(@{$self->_statePos}) . " iteration: "
    #. $self->iteration;
    return Photonic::Iterator->new(sub { #closure
	return if $n>=$self->iteration;
	return $s->[$n++];
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

sub states {
    croak "Don't use 'states'. Use state_iterator instead";
}

sub _build_stateFD {
    my $self=shift;
    my $fn=$self->stateFN;
    croak "You didn't provide a stateFN" unless defined $fn;
    my $fh=IO::File->new($fn, "w+")
	or croak "Couldn't open ".$self->stateFN.": $!";
    return $fh;
}


#I use before and after trick (below), as a[n] is calculated together
#with b[n+1] in each iteration

#before 'states' => sub {
#    my $self=shift;
#    confess "Can't return states unless keepStates!=0" unless $self->keepStates;
#};

before '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_b;
    $self->_save_b2;
    $self->_save_bc;
    $self->_save_c;
    $self->_save_g;
    $self->_save_state;
};
after '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_a;
    $self->_checkorthogonalize;
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
    map {my $k="_".$_;$self->$k($all->{$_})} @allfields;
    return unless $self->keepStates;
    foreach(0..$self->iteration-1){
	$self->_nextState(fd_retrieve($fh)); #note: clobber nextState
	$self->_save_state;
    }
    $self->_nextState($all->{nextState}); #restore nextState
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

sub _save_a {
    my $self=shift;
    push @{$self->as}, $self->current_a;
}

sub _save_b {
    my $self=shift;
    push @{$self->bs}, $self->next_b;
}

sub _save_b2 {
    my $self=shift;
    push @{$self->b2s}, $self->next_b2;
}

sub _save_bc {
    my $self=shift;
    push @{$self->bcs}, $self->next_bc;
}

sub _save_c {
    my $self=shift;
    push @{$self->cs}, $self->next_c;
}

sub _save_g {
    my $self=shift;
    push @{$self->gs}, $self->next_g;
}

sub _save_state {
    my $self=shift;
    return unless $self->keepStates; #noop
    push(@{$self->_states}, $self->nextState), return
	unless defined $self->stateFN;
    my $fh=$self->_stateFD;
    my $lastpos=$self->_statePos->[-1];
    seek($fh, $lastpos, SEEK_SET);
    store_fd \$self->nextState, $fh or croak "Couldn't store state: $!";
    my $pos=tell($fh);
    push @{$self->_statePos}, $pos;
}

sub _pop_state {
    my $self=shift;
    croak "Can't pop state without keepStates=>1" unless
	$self->keepStates;
    unless(defined $self->stateFN){
	$self->_nextState(pop @{$self->_states});
	$self->_currentState($self->_states->[-1]);
	my $s2 = $self->_states->[-2];
	$s2 = r2C(0) if !defined $s2;
	$self->_previousState($s2);
	return;
    }
    pop @{$self->_statePos};
    my ($snm3, $snm2, $snm1)=map {
	seek($self->_stateFD, $self->_statePos->[-$_], SEEK_SET);
	fd_retrieve($self->_stateFD);
    } (3,2,1);
    $self->_nextState($$snm1);
    $self->_currentState($$snm2);
    $self->_previousState($$snm3);
}

sub _pop { # undo the changes done after, in and before iteration, for
	   # reorthogonalization, in reverse order
    my $self=shift;
    $self->_pop_state;
    $self->_current_a(pop @{$self->as});
    $self->_next_b2(pop @{$self->b2s});
    $self->_current_b2($self->b2s->[-1]);
    $self->_next_b(pop @{$self->bs});
    $self->_current_b($self->bs->[-1]);
    $self->_next_c(pop @{$self->cs});
    $self->_current_c($self->cs->[-1]);
    $self->_next_bc(pop @{$self->bcs});
    $self->_next_g(pop @{$self->gs});
    $self->_current_g($self->gs->[-1]);
    $self->_previous_g($self->gs->[-2]);
    $self->_iteration($self->iteration-1); #decrement counter
}

no Moose::Role;

1;
