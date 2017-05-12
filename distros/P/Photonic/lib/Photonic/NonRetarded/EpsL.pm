=head1 NAME

Photonic::NonRetarded::EpsL

=head1 VERSION

version 0.007

=head1 SYNOPSIS

   use Photonic::NonRetarded::EpsL;
   my $eps=Photonic::NonRetarded::EpsL(nr=>$nr, nh=>$nh);
   my $epsilonLongitudinal=$eps->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the longitudinal dielectric function for a given fixed
Photonic::NonRetarded::AllH structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, small=>$small)

Initializes the structure.

$nr is a Photonic::NonRetarded::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$small is the criteria of convergence (defaults to 1e-7)

=item * evaluate($epsA, $epsB)

Returns the macroscopic dielectric function for a given value of the
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESORS (read only)

=over 4

=item * nr

The NonRetarded::AllH structure

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

=item * epsL

The longitudinal macroscopic function obtained in the last calculation.

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * small

Criteria of convergence. 0 means don't check.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::NonRetarded::EpsL;
$Photonic::NonRetarded::EpsL::VERSION = '0.007';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::NonRetarded::AllH;
use Moose;
use Photonic::Types;

with 'Photonic::Roles::EpsParams';
has 'nr' =>(is=>'ro', isa=>'Photonic::NonRetarded::AllH', required=>1);
has 'epsL'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsL');
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef, 
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');

sub BUILD {
    my $self=shift;
    $self->nr->run unless $self->nr->iteration;
}

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=shift);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=$self->nr->as;
    my $b2s=$self->nr->b2s;
    # Continued fraction evaluation: Lentz method
    # Numerical Recipes p. 171
    my $tiny=1.e-30;
    my $converged=0;
#    b0+a1/b1+a2/...
#	lo debo convertir a
#	u-a0-b1^2/u-a1-b2^2/
#	entonces bn->u-an y an->-b_n^2
    my $fnm1=$u-$as->[0];
    $fnm1=r2C($tiny) if $fnm1->re==0 and $fnm1->im==0;
    my $n=1;
    my ($Cnm1, $Dnm1)=($fnm1, r2C(0)); #previous coeffs.
    my ($fn, $Cn, $Dn); #current coeffs.
    my $Deltan;
    while($n<=$self->nh && $n<=$self->nr->iteration){
	$Dn=$u-$as->[$n]-$b2s->[$n]*$Dnm1;
	$Dn=r2C($tiny) if $Dn->re==0 and $Dn->im==0;
	$Cn=$u-$as->[$n]-$b2s->[$n]/$Cnm1;
	$Cn=r2C($tiny) if $Cn->re==0 and $Cn->im==0;
	$Dn=1/$Dn;
	$Deltan=$Cn*$Dn;
	$fn=$fnm1*$Deltan;
	last if $converged=$Deltan->approx(1, $self->small)->all;
	$fnm1=$fn;
	$Dnm1=$Dn;
	$Cnm1=$Cn;
	$n++;
    }
    $self->_converged($converged);
    $self->_nhActual($n);
    $self->_epsL($epsA*$fn/$u);
    return $self->epsL;
}

__PACKAGE__->meta->make_immutable;
    
1;
