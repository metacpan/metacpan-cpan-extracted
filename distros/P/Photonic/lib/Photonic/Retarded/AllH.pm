=head1 NAME

Photonic::Retarded::AllH

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   use Photonic::Retarded::AllH;
   my $iter=Photonic::Retarded::AllH->new(metric=>$metric,nh=>$Nh,
            keepStates=>$save); 
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

=cut

package Photonic::Retarded::AllH;
$Photonic::Retarded::AllH::VERSION = '0.009';
use namespace::autoclean;
use Carp;
use PDL::Lite;
use Moose;

extends 'Photonic::Retarded::OneH';

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

has cs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved c coefficients');

has bcs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved b*c coefficients');

has gs=>(is=>'ro', isa=>'ArrayRef[Num]', default=>sub{[]}, init_arg=>undef,
         documentation=>'Saved g coefficients');

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


__PACKAGE__->meta->make_immutable;
    
1;
