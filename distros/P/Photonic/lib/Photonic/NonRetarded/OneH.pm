=head1 NAME

Photonic::NonRetarded::OneH

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Photonic::NonRetarded::OneH;
    my $nr=Photonic::NonRetarded::OneH->new(geometry=>$geometry);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->nextState;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the non retarded dielectric function of arbitrary
periodic two component systems in arbitrary number of dimentions. One
Haydock coefficient at a time.

=head1 METHODS

=over 4

=item * new(geometry=>$g[, small=>$s])

Create a new Ph::NR::OneH object with GeometryG0 $g and optional
smallness parameter  $s.

=back

=head1 ACCESORS (read only)

=over 4

=item * geometry Photonic::Types::GeometryG0 

A Photonic::Geometry object defining the geometry of the system,
the charateristic function and the direction of the G=0 vector. Should
be given in the initializer.

=item * B dims r G GNorm L scale f

Accesors handled by geometry (see Photonic::Geometry)

=item * small 

A small number used as tolerance to end the iteration. Small negative
b^2 coefficients are taken to be zero.

=item * previousState currentState nextState 

The n-1-th, n-th and n+1-th Haydock states; a complex number for each pixel

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

Performs a single Haydock iteration and updates current_a, next_state,
next_b2, next_b, shifting the current values where necessary. Returns
0 when unable to continue iterating. 
 
=back

=cut

package Photonic::NonRetarded::OneH;
$Photonic::NonRetarded::OneH::VERSION = '0.007';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::FFTW3;
use PDL::Complex;
use List::Util;
use Carp;
use Moose;
use Photonic::Types;

has 'geometry'=>(is=>'ro', isa => 'Photonic::Types::GeometryG0',
    handles=>[qw(B dims r G GNorm L scale f)],required=>1
);
has 'small' => (is=>'ro', required=>1, default=>1e-7);
has 'currentState' => (is=>'ro', isa=>'PDL::Complex', writer=>'_currentState',
      lazy=>1, init_arg=>undef,  default=>sub {0+i*0});
has 'previousState' =>(is=>'ro', isa=>'PDL::Complex', writer=>'_previousState',
    init_arg=>undef);
has 'nextState' =>(is=>'ro', isa=>'PDL::Complex|Undef', writer=>'_nextState',
    lazy=>1, default=>\&_firstState);
has 'current_a' => (is=>'ro', writer=>'_current_a',
    init_arg=>undef);
has 'current_b2' => (is=>'ro', writer=>'_current_b2',
    init_arg=>undef);
has 'next_b2' => (is=>'ro', writer=>'_next_b2', init_arg=>undef, default=>0);
has 'current_b' => (is=>'ro', writer=>'_current_b', init_arg=>undef);
has 'next_b' => (is=>'ro', writer=>'_next_b', init_arg=>undef, default=>0);
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
    $self->_previousState($self->currentState);
    $self->_currentState(my $psi_G #state in reciprocal space 
			 =$self->nextState);
    $self->_current_b2($self->next_b2);
    $self->_current_b($self->next_b);
    #state is RorI, nx, ny... gnorm=cartesian,nx,ny...
    #Multiply by vector ^G.
    #Have to get cartesian out of the way, thread over it and iterate
    #over the rest 
    my $Gpsi_G=Cscale($psi_G, $self->GNorm->mv(0,-1)); #^G |psi>
    #the result is RorI, nx, ny,... cartesian
    #Take inverse Fourier transform over all space dimensions,
    #thread over cartesian indices
    #Notice that (i)fftn wants a real 2,nx,ny... piddle, not a complex
    #one. Thus, I have to convert complex to real and back here and
    #downwards. 
    my $Gpsi_R=ifftn($Gpsi_G->real, $self->B->ndims); #real space ^G|psi>
    #the result is RorI, nx, ny,... cartesian
    #Multiply by characteristic function. Thread cartesian
    my $BGpsi_R=Cscale($Gpsi_R, $self->B); #B^G|psi> in Real Space
    #the result is RorI, nx, ny,... cartesian
    #Transform to reciprocal space
    my $BGpsi_G=fftn($BGpsi_R, $self->B->ndims); #reciprocal space B^G|psi>
    #the result is RorI, nx, ny,... cartesian
    #Scalar product with Gnorm
    my $GBGpsi_G=Cscale($BGpsi_G, $self->GNorm->mv(0,-1)) #^GB^G|psi>
	# RorI, nx, ny,... cartesian
	# Move cartesian to front and sum over
	->mv(-1,0)->sumover->complex; #^G.B^G|psi>
    # Result is RorI, nx, ny,...
    #Normalization should have been taken care of by fftw3
    # Calculate Haydock coefficients
    # current_a is (real part) of Hermitean product
    my $current_a=(Cmul(Cconj($psi_G), $GBGpsi_G))->re->sum;
    # was ->((0))->real->sum;
    # next b^2
    my $next_b2=Cabs2($GBGpsi_G)->sum #square magnitude of state
	-$current_a**2 - $self->current_b2;
    carp "\$next_b2=$next_b2 is too negative!" if $next_b2 < -$self->small;
    $next_b2=0 if $next_b2<0; 
    my $next_b=sqrt($next_b2);
    #If b is too small, time to quit.
    my $next_state=undef;
    $next_state=$GBGpsi_G - $current_a*$psi_G -
	$self->current_b*$self->previousState,  
	$next_state=Cscale($next_state,1/$next_b)
	unless $next_b2 < $self->small;
    #save values
    $self->_current_a($current_a);
    $self->_next_b2($next_b2);
    $self->_next_b($next_b);
    $self->_nextState($next_state);
    $self->_iteration($self->iteration+1); #increment counter
    return 1;
}

sub _firstState { #\delta_{G0}
    my $self=shift;
    my $v=PDL->zeroes(2,@{$self->dims})->complex; #RorI, nx, ny...
    my $arg="(0)" . ",(0)" x $self->B->ndims; #(0),(0),... ndims+1 times
    $v->slice($arg).=1; #delta_{G0}
    return $v;
}


__PACKAGE__->meta->make_immutable;
    
1;
