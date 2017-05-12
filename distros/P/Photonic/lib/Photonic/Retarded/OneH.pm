=head1 NAME

Photonic::Retarded::OneH

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Photonic::Retarded::OneH;
    my $nr=Photonic::Retarded::OneH->new(geometry=>$geometry);
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

=item * new(metric=>$m, polarization=>$e, [, small=>$s])

Create a new Ph::R::OneH object with PDL::Retarded::Metric $m, with a
field along the complex direction $e and with smallness parameter  $s.

=back

=head1 ACCESORS (read only)

=over 4

=item * metric Photonic::Retarded::Metric 

A Photonic::Retarded::Metric object defining the geometry of the
system, the charateristic function, the wavenumber, wavevector and
host dielectric function. Required in the initializer.

=item * polarization PDL::Complex

A non null vector defining the complex direction of the macroscopic
field. 

=item * small 

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * B ndims dims epsilon

Accesors handled by metric (see Photonic::Retarded::Metric, inherited
from Photonic::Geometry)

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
next_b2, next_c, next_g, shifting the current values where necessary. Returns 
0 when unable to continue iterating. 
 
=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=back

=cut

package Photonic::Retarded::OneH;
$Photonic::Retarded::OneH::VERSION = '0.007';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::FFTW3;
use PDL::Complex;
use List::Util;
use Carp;
use Moose;
#use Photonic::Types;

has 'metric'=>(is=>'ro', isa => 'Photonic::Retarded::Metric',
    handles=>[qw(B ndims dims epsilon)],required=>1
);

has 'polarization' =>(is=>'ro', required=>1, isa=>'PDL::Complex');

has 'small' => (is=>'ro', required=>1, default=>1e-7);

has 'previousState' =>(is=>'ro', isa=>'PDL::Complex',
    writer=>'_previousState', lazy=>1, init_arg=>undef, 
    default=>sub {0+i*0});

has 'currentState' => (is=>'ro', isa=>'PDL::Complex',
      writer=>'_currentState', 
      lazy=>1, init_arg=>undef,  default=>sub {0+i*0});

has 'nextState' =>(is=>'ro', isa=>'PDL::Complex|Undef', 
    writer=>'_nextState', init_arg=>undef);

has 'current_a' => (is=>'ro', writer=>'_current_a',
    init_arg=>undef);

has 'current_b2' => (is=>'ro', writer=>'_current_b2',
    init_arg=>undef);

has 'next_b2' => (is=>'ro', writer=>'_next_b2', init_arg=>undef, default=>0);

has 'current_b' => (is=>'ro', writer=>'_current_b', init_arg=>undef);

has 'next_b' => (is=>'ro', writer=>'_next_b', init_arg=>undef); 

has 'current_c' => (is=>'ro', writer=>'_current_c', init_arg=>undef); 

has 'next_c' => (is=>'ro', writer=>'_next_c', init_arg=>undef, default=>0);

has 'next_bc' => (is=>'ro', writer=>'_next_bc', init_arg=>undef, default=>0);

has 'previous_g' => (is=>'ro', writer=>'_previous_g', init_arg=>undef);

has 'current_g' => (is=>'ro', writer=>'_current_g', init_arg=>undef, 
     default=>0);

has 'next_g' => (is=>'ro', writer=>'_next_g', init_arg=>undef);

has 'iteration' =>(is=>'ro', writer=>'_iteration', init_arg=>undef,
                   default=>0);

sub iterate { #single Haydock iteration in N=1,2,3 dimensions
    my $self=shift;
    #Note: calculate Current a, next b2, next b, next state
    #Done if there is no next state
    return 0 unless defined $self->nextState;
    $self->_iterate_indeed; 
}

sub _iterate_indeed {
    my $self=shift;
    #Shift and fetch results of previous calculations
    #Notation: nm1 is n-1, np1 is n+1
    $self->_previousState(my $psi_nm1=$self->currentState);
    $self->_currentState(my $psi_n #state in reciprocal space 
			 =$self->nextState);
    $self->_current_b(my $b_n=$self->next_b);
    $self->_current_b2(my $b2_n=$self->next_b2);
    $self->_current_c(my $c_n=$self->next_c);
    $self->_previous_g(my $g_nm1=$self->current_g);
    $self->_current_g(my $g_n=$self->next_g);
    #Use eqs. 4.29-4.33 of Samuel's thesis.
    #state is RorI xy.. nx ny..
    my $gGG=$self->metric->value;
    #$gGG is xyz xyz nx ny nz, $psi_n is RorI xyz nx ny nz
    my $gpsi=($gGG*$psi_n(:,:,*1))->sumover; #seems real*complex works.
    # gpsi is RorI xyz nx ny nz. Get cartesian out of the way and
    # transform to real space. Note FFFTW3 wants real PDL's[2,...] 
    my $gpsi_nr=ifftn($gpsi->real->mv(1,-1), $self->ndims);
    #$gpsi_nr is RorI nx ny nz  xyz, B is nx ny nz
    # Multiply by characteristic function
    my $psi_np1r=Cscale($gpsi_nr, $self->B);
    #psi_np1r is RorI nx ny nz  xyz
    #the result is RorI, nx, ny,... cartesian
    #Transform to reciprocal space, move xyz back and make complex, 
    my $psi_np1=fftn($psi_np1r, $self->ndims)->mv(-1,1)->complex;
    # psi_np1 is RorI xyz nx ny nz
    my $gPsi_np1=($gGG*$psi_np1(:,:,*1))->sumover;
    # gPsi_np1 is RorI xyz nx ny nz
    # Eq. 4.41
    my $a_n=$g_n*($gpsi->Cconj*$psi_np1)->re->sum;
    my $err = $g_n*($gpsi->Cconj*$psi_np1)->im->sum;
    #croak "Imaginary part of \$a_n too large: $err" unless abs($err) < $small; 
    # Eq 4.43
    my $psi2_np1=($psi_np1->Cconj*$gPsi_np1)->re->sum;
    $err = ($psi_np1->Cconj*$gPsi_np1)->im->sum;
    #croak "Imaginary part of \$psi2_np1 too large: $err" unless
    #abs($err) < $small;
    # Eq. 4.30
    my $g_np1=1;
    my $b2_np1=$psi2_np1-$g_n*$a_n**2-$g_nm1*$b2_n;
    $g_np1=-1, $b2_np1=-$b2_np1 if $b2_np1 < 0;
    my $b_np1=sqrt($b2_np1);
    # Eq. 4.31
    my $c_np1=$g_np1*$g_n*$b_np1;
    my $bc_np1=$g_np1*$g_n*$b2_np1;
    # Eq. 4.33
    my $next_state=undef;
    $next_state=($psi_np1-$a_n*$psi_n-$c_n*$psi_nm1)/$b_np1 
	unless $b2_np1 < $self->small;
    #save values
    $self->_nextState($next_state);
    $self->_current_a($a_n);
    $self->_next_b2($b2_np1);
    $self->_next_b($b_np1);
    $self->_next_g($g_np1);
    $self->_next_c($c_np1);
    $self->_next_bc($bc_np1);
    $self->_iteration($self->iteration+1); #increment counter
    return 1;
}

sub BUILD {
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
    my $phi=$e*$v(*1); #initial state ordinarily normalized 
                       # RorI xyz nx ny nz
    my $gphi=($self->metric->value*$phi(:,:,*1))->sumover;
    my $g=1;
    my $b2=($phi->Cconj*$gphi)->re->sum;
    $g=-1, $b2=-$b2 if $b2<0;
    $b=sqrt($b2);
    $phi=$phi/$b; #initial state;
    $self->_nextState($phi);
    #skip $self->current_a;
    $self->_next_b2($b2);
    $self->_next_b($b);
    $self->_next_c(0); #no c0
    $self->_next_bc(0); #no bc0
    $self->_next_g($g);
}
    
__PACKAGE__->meta->make_immutable;
    
1;
