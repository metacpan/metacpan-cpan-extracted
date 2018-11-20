=head1 NAME

Photonic::Retarded::AllH

=head1 VERSION

version 0.010

=head1 SYNOPSIS

   use Photonic::Retarded::AllH;
   my $iter=Photonic::Retarded::AllH->new(metric=>$metric,
            nh=>$Nh, polarization=>$p, keepStates=>$save); 
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;
   my $haydock_b2s=$iter->b2s;
   my $haydock_b2s=$iter->b2s;
   my $haydock_cs=$iter->cs;
   my $haydock_bcs=$iter->bcs;
   my $haydock_gs=$iter->gs;
   my $haydock_states=$iter->states;

=head1 DESCRIPTION

Iterates the calculation of Haydock coefficients and states in the
retarded regime and saves them for later retrieval. 

=head1 METHODS

=over 4

=item * new(metric=>$m, polarization=>$p, nh=>$nh[, keepStates=>$k, smallH=>$s]) 

Initializes an Ph::NR::AllH object. $m is the retarded metric to use,
$p is the polarization of the field, $nh is the maximum number of desired
coefficients to calculate, $k is a flag, non zero to save the Haydock
states, $s is a number to be considered negligible. Other arguments
are as in Photonic::Retarded::OneH.

=item * run

Runs the iteration to completion

=item * All the Photonic::Retarded::OneH methods

=back

=head1 ACCESORS (read only)

=over 4

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less.

=item * keepStates

Flag to keep (1) or discard (0) Haydock states

=item * states

Array of Haydock states

=item * as

Array of Haydock a coefficients

=item * bs

Array of Haydock b coefficients

=item * b2s

Array of Haydock b coefficients squared

=item * cs

Array of Haydock c coefficients 

=item * bcs

Array of Haydock b times c coefficients

=item * gs

Array of Haydock g coefficients 

=item * All the Photonic::Retarded::OneH methods

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage


=cut

package Photonic::Retarded::AllH;
$Photonic::Retarded::AllH::VERSION = '0.010';
use namespace::autoclean;
use Machine::Epsilon;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::Utils qw(MHProd);
use Moose;
use Carp;

extends 'Photonic::Retarded::OneH';

has nh=>(is=>'ro', required=>1, 
         documentation=>'Maximum number of desired Haydock coefficients');

with 'Photonic::Roles::KeepStates';

# why rw? Could it be ro? rw introduced by Lucila
has states=>(is=>'rw', isa=>'ArrayRef[PDL::Complex]', 
         default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved states');

has as=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved a coefficients');

has bs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b coefficients');

has b2s=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b^2 coefficients');

has cs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved c coefficients');

has bcs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b*c coefficients');

has gs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved g coefficients');

has reorthogonalize=>(is=>'ro', required=>1, default=>1,
         documentation=>'Reorthogonalize flag');

has 'previous_W' =>(is=>'ro', isa=>'PDL',
     writer=>'_previous_W', lazy=>1, init_arg=>undef,
     default=>sub{PDL->pdl([0])},
     documentation=>"Row of error matrix"
);
has 'current_W' =>(is=>'ro', isa=>'PDL',
     writer=>'_current_W', lazy=>1, init_arg=>undef,
     default=>sub{PDL->pdl([0])},
     documentation=>"Row of error matrix"
);
has 'next_W' =>(is=>'ro', isa=>'PDL',
     writer=>'_next_W', lazy=>1, init_arg=>undef,
     default=>sub {PDL->pdl([1])},
     documentation=>"Next row of error matrix"
);
has 'Accuracy'=>(is=>'ro', default=>sub{machine_epsilon()},
                documentation=>'Desired or machine precision');

sub BUILD {
    my $self=shift;
    # Can't reorthogonalize without previous states
    $self->_keepstates(1) if  $self->reorthogonalize;
}

#I use before and after trick (below), as a[n] is calculated together
# with b[n+1], c[n+1] and g[n+1] and  in each iteration

before 'states' => sub {
    my $self=shift;
    croak "Can't return states unless keepStates!=0" unless $self->keepStates;
};

before '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_state;
    $self->_save_b2;
    $self->_save_b;
    $self->_save_c;
    $self->_save_bc;
    $self->_save_g;
};

after '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_a;
    $self->_checkorthogonalize if $self->reorthogonalize;
};

sub run { #run the iteration
    my $self=shift;
    my $niter=0;
    while($niter++ < $self->nh && $self->iterate){
    }
}

sub _save_state {
    my $self=shift;
    return unless $self->keepStates;
    push @{$self->states}, $self->nextState;
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


sub _checkorthogonalize 
{
    my $self=shift;
    my $nextState=$self->nextState;
    return unless defined $nextState;
    my $a=PDL->pdl($self->as);
    my $b=PDL->pdl($self->bs);
    my $g=PDL->pdl($self->gs);
    my $m=$self->metric->value;
    #$m is xyz xyz nx ny nz
    my $n=$self->iteration;
    $self->_previous_W(my $previous_W=$self->current_W);
    $self->_current_W(my $current_W=$self->next_W);
    my $next_W=PDL->pdl([]);    
    if($n>=2){
	$next_W=(
	    $b->(1:-1)
	    *
	    $current_W->(1:-1) 
	    + ($a->(0:-2)
	       -$a->(($n-1)))
	    *$current_W->(0:-2)  
	    -$b->(($n-1))
	    *$g->(($n-1))
	    *$g->(($n-2))
	    *$previous_W);
	$next_W->(1:-1)+=$b->(1:-2)*$g->(1:-2)*$g->(0:-3)
	    *$current_W->(0:-3) if ($n>=3);
	$next_W+=_sign($next_W)*2*$self->Accuracy;
	$next_W/=$self->next_b;
    }
    $next_W=$next_W->append($self->Accuracy) if $n>=1;
    $next_W=$next_W->append(1);
    $self->_next_W($next_W);
    return unless $n>=2;
    my $max=$next_W->(0:-2)->maximum;
    return unless $max > sqrt($self->Accuracy);
    #print "Ortoghonalize at $n\n";
    my $states=$self->states;
    my $currentState=$self->currentState;
    pop(@{$states}); #should be currentState;
    my ($oldnext, $oldcurrent)=($nextState, $currentState);
    for my $s (@{$states}){
	($nextState,$currentState)=map {$_-$s*MHProd($s, $_, $m)}
	($nextState, $currentState);
    }
    #warn "Current change: ", ($currentState-$oldcurrent)->Cabs2->sum, "\n";
    #warn "Next change: " . ($nextState-$oldnext)->Cabs2->sum, "\n";
    my $sc=sqrt($currentState->Cabs2->sum);
    # Is there a danger that $sc<$self->smallH?
#    print "scold $scold sc $sc\n";
    $currentState/=$sc;
    $self->_currentState($currentState);
    push @{$self->states}, $currentState;
    #necessary?:
    $nextState-=$currentState*MHProd($currentState, $nextState, $m);
    my $sn=sqrt($nextState->Cabs2->sum);
    $nextState/=$sn;
    $self->_nextState($nextState);
    $current_W(0:-2).=$self->Accuracy;
    $next_W(0:-2).=$self->Accuracy;
    $self->_current_W($current_W);
    $self->_next_W($next_W);
};

sub _replace_state {
    my $self=shift;
    pop @{$self->states};
    push @{$self->states}, $self->currentState;
}

   
sub _sign {
    my $s=shift;
    return 2*($s>=0)-1;
}


__PACKAGE__->meta->make_immutable;
    
1;
