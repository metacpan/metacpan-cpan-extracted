=head1 NAME

Photonic::NonRetarded::AllH

=head1 VERSION

version 0.010

=head1 SYNOPSIS

   use Photonic::NonRetarded::AllH;
   my $iter=Photonic::NonRetarded::AllH->new(geometry=>$geometry,nh=>$Nh,
            keepStates=>$save); 
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;
   my $haydock_states=$iter->states;

=head1 DESCRIPTION

Iterates the calculation of Haydock coefficients and states and saves
them for later retrieval. 

=head1 METHODS

=over 4

=item * new(geometry=>$g, nh=>$nh, keepStates=>$k) 

Initializes an Ph::NR::AllH object. $nh is the maximum number of desired
coefficients, $k is a flag, non zero to save the Haydock states. All
other arguments are as in Photonic::NonRetarded::OneH.

=item * run

Runs the iteration to completion

=item * All the Photonic::NonRetarded::OneH methods

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

=item * All the Photonic::NonRetarded::OneH methods

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::NonRetarded::AllH;
$Photonic::NonRetarded::AllH::VERSION = '0.010';
use namespace::autoclean;
use Machine::Epsilon;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::Utils qw(HProd);
use Moose;
extends 'Photonic::NonRetarded::OneH';

has nh=>(is=>'ro', required=>1, 
         documentation=>'Maximum number of desired Haydock coefficients');
with 'Photonic::Roles::KeepStates';
has states=>(is=>'ro', isa=>'ArrayRef[PDL::Complex]', 
         default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved states');
has as=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved a coefficients');
has bs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b coefficients');
has b2s=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b^2 coefficients');
has reorthogonalize=>(is=>'ro', required=>1, default=>0,
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
#with b[n+1] in each iteration

before 'states' => sub {
    my $self=shift;
    die "Can't return states unless keepStates!=0" unless $self->keepStates;
};

before '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_state;
    $self->_save_b2;
    $self->_save_b;
};
after '_iterate_indeed' => sub {
    my $self=shift;
    $self->_save_a;
    $self->_checkorthogonalize if $self->reorthogonalize;
};

sub run { #run the iteration
    my $self=shift;
    while($self->iteration < $self->nh && $self->iterate){
    }
}

sub _save_state {
    my $self=shift;
    return unless $self->keepStates;
    push @{$self->states}, $self->nextState;
}

sub _save_b {
    my $self=shift;
    push @{$self->bs}, $self->next_b;
}

sub _save_b2 {
    my $self=shift;
    push @{$self->b2s}, $self->next_b2;
}

sub _save_a {
    my $self=shift;
    push @{$self->as}, $self->current_a;
}

sub _checkorthogonalize 
{
    my $self=shift;
    my $nextState=$self->nextState;
    return unless defined $nextState;
    my $a=PDL->pdl($self->as);
    my $b=PDL->pdl($self->bs);
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
	    *$previous_W);
	$next_W->(1:-1)+=$b->(1:-2)*$current_W->(0:-3) if ($n>=3);
	$next_W+=_sign($next_W)*2*$self->Accuracy;
	$next_W/=$self->next_b;
    }
    $next_W=$next_W->append($self->Accuracy) if $n>=1;
    $next_W=$next_W->append(1);
    $self->_next_W($next_W);
    return unless $n>=2;
    my $max=$next_W->(0:-2)->maximum;
    return unless $max > sqrt($self->Accuracy);
    #warn "Ortoghonalize at $n\n";
    my $states=$self->states;
    my $currentState=$self->currentState;
    pop(@{$states}); #should be currentState;
    my ($oldnext, $oldcurrent)=($nextState, $currentState);
    for my $s (@{$states}){
	($nextState,$currentState)=map {$_-$s*HProd($s, $_)}
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
    $nextState-=$currentState*HProd($currentState, $nextState);
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
