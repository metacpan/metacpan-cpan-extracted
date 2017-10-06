=head1 NAME

Photonic::NonRetarded::AllH

=head1 VERSION

version 0.009

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

=cut

package Photonic::NonRetarded::AllH;
$Photonic::NonRetarded::AllH::VERSION = '0.009';
use namespace::autoclean;
use PDL::Lite;
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

__PACKAGE__->meta->make_immutable;
    
1;
