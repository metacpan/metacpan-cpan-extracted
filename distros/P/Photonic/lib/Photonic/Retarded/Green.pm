=head1 NAME

Photonic::Retarded::Green

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   use Photonic::Retarded::Green;
   my $G=Photonic::Retarded::Green->new(metric=>$m, nh=>$nh);
   my $GreenTensor=$G->evaluate($epsB);

=head1 DESCRIPTION

Calculates the retarded green's tensor for a given fixed
Photonic::Retarded::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallH=>$smallH, smallE=>$smallE,
keepStates=>$k)  

Initializes the structure.

$m Photonic::Retarded::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and continued fraction

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic Green's operator for a given value of the
dielectric functions of the particle $epsB. The host's
response $epsA is taken from the metric.  

=back

=head1 ACCESORS (read only)

=over 4

=item * keepStates

Value of flag to keep Haydock states

=item * epsA

Dielectric function of component A

=item * epsB

Dielectric function of componente B

=item * u 

Spectral variable

=item * haydock

Array of Photonic::Retarded::AllH structures, one for each polarization

=item * greenP

Array of Photonic::Retarded::GreenP structures, one for each direction.

=item * greenTensor

The Green's tensor of the last evaluation

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallH, smallE

Criteria of convergence of Haydock coefficients and continued
fraction. 0 means don't check. 

=back

=cut

package Photonic::Retarded::Green;
$Photonic::Retarded::Green::VERSION = '0.009';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
use Photonic::Retarded::AllH;
use Photonic::Retarded::GreenP;
use Moose;
use Photonic::Types;
with 'Photonic::Roles::KeepStates';
with 'Photonic::Roles::EpsParams';

has 'metric'=>(is=>'ro', isa => 'Photonic::Retarded::Metric',
    handles=>[qw(geometry B dims r G GNorm L scale f)],required=>1
);
has 'haydock' =>(is=>'ro', isa=>'ArrayRef[Photonic::Retarded::AllH]',
            init_arg=>undef, lazy=>1, builder=>'_build_haydock',
            documentation=>'Array of Haydock calculators');
has 'greenP'=>(is=>'ro', isa=>'ArrayRef[Photonic::Retarded::GreenP]',
             init_arg=>undef, lazy=>1, builder=>'_build_greenP',
             documentation=>'Array of projected G calculators');
has 'greenTensor'=>(is=>'ro', isa=>'PDL', init_arg=>undef,
             writer=>'_greenTensor',   
             documentation=>'Greens Tensor from last evaluation');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All greenP evaluations converged in last evaluation'); 
sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=$self->metric->epsilon->r2C);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my @greenP; #array of Green's projections along different directions.
    my $converged=1;
    foreach(@{$self->greenP}){
	push @greenP, $_->evaluate($epsB);
	$converged &&=$_->converged;
    }
    $self->_converged($converged);
    my $reGreenP=PDL->pdl([map {$_->re} @greenP]);
    my $imGreenP=PDL->pdl([map {$_->im} @greenP]);
    my ($lu, $perm, $parity)=@{$self->geometry->unitDyadsLU};
    my $reGreen=lu_backsub($lu, $perm, $parity, $reGreenP);
    my $imGreen=lu_backsub($lu, $perm, $parity, $imGreenP);
    my $nd=$self->geometry->B->ndims;
    my $greenTensor=PDL->zeroes(2, $nd, $nd)->complex;
    my $n=0;
    for my $i(0..$nd-1){
	for my $j($i..$nd-1){
	    $greenTensor->(:,($i),($j)).=$reGreen->($n)+i*$imGreen->($n);
	    $greenTensor->(:,($j),($i)).=$reGreen->($n)+i*$imGreen->($n);
	    ++$n;
	}
    }
    $self->_greenTensor($greenTensor);
    return $greenTensor;
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my $self=shift;
    my @haydock;
    # This must change if G is not symmetric
    foreach(@{$self->geometry->unitPairs}){
	my $m=dclone($self->metric); #clone metric, to be safe
	my $e=$_->r2C; #polarization
	#Build a corresponding Photonic::Retarded::AllH structure
	my $haydock=Photonic::Retarded::AllH->new(
	    metric=>$m, polarization=>$e, nh=>$self->nh,
	    keepStates=>$self->keepStates, smallH=>$self->smallH);
	push @haydock, $haydock;
    }
    return [@haydock]
}

sub _build_greenP {
    my $self=shift;
    my @greenP;
    foreach(@{$self->haydock}){
	my $g=Photonic::Retarded::GreenP->new(
	    haydock=>$_, nh=>$self->nh, smallE=>$self->smallE);
	push @greenP, $g;
    }
    return [@greenP]
}


__PACKAGE__->meta->make_immutable;
    
1;

__END__
