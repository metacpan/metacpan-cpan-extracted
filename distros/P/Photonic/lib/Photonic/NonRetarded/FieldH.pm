=head1 NAME

Photonic::NonRetarded::FieldH

=head1 VERSION

version 0.010

=head1 SYNOPSIS

   use Photonic::NonRetarded::FieldH;
   my $nrf=Photonic::NonRetarded::FieldH->new(...);
   my $field=$nrf->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the non retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr Photonic::NonRetarded::AllH is a Haydock calculator for the
structure, *initialized* with the flag keepStates=>1
(Photonic::Types::NonRetarded::AllHSave, as defined in Photonic::Types).

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criteria of convergence (default 1e-7) for
Field calculations  

=item * evaluate($epsA, $epsB...)

Returns the microscopic electric field for given 
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESORS (read only)

=over 4

=item * nr

Photonic::NonRetarded::AllH structure

=item * nh 

Maximum number of Haydock coefficients to use.

=item * smallE

Criteria of convergence. 0 means don't check. From Photonic::Roles::EpsParams

=item * epsA

Dielectric function of component A

=item * epsB

Dielectric function of componente B

=item * u 

Spectral variable

=item * Es

Array of field coefficients

=item * filter

optional reciprocal space filter 

=item * field

real space field in format RorI, cartesian, nx, ny,...

=item * epsL 

Longitudinal dielectric response, obtained colateraly from last
evaluation of the field

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::NonRetarded::FieldH;
$Photonic::NonRetarded::FieldH::VERSION = '0.010';

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::FFTW3;
use Photonic::NonRetarded::AllH;
use Photonic::ExtraUtils qw(cgtsl);
use Moose;
use Photonic::Types;
with 'Photonic::Roles::EpsParams';

has 'nr'=>(is=>'ro', isa=>'Photonic::Types::NonRetarded::AllHSave', required=>1,  
           documentation=>'Haydock recursion calculator');
has 'Es'=>(is=>'ro', isa=>'ArrayRef[PDL::Complex]', init_arg=>undef, 
           writer=>'_Es', documentation=>'Field coefficients');
has 'filter'=>(is=>'ro', isa=>'PDL', predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'field'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
           writer=>'_field', documentation=>'Calculated real space field');
has 'epsL' =>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
		 writer=>'_epsL', 
		 documentation=>'Longitudinal dielectric response');
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
    my $bs=$self->nr->bs;
    my $states=$self->nr->states;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->nr->iteration if $nh>=$self->nr->iteration;
    # calculate using linpack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$u->complex - PDL->pdl([@$as])->(0:$nh-1);
    my $subdiag=-PDL->pdl(@$bs)->(0:$nh-1)->r2C;
    # rotate complex zero from first to last element.
    my $supradiag=$subdiag->real->mv(0,-1)->rotate(-1)->mv(-1,0)->complex;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my ($result, $info)= cgtsl($subdiag, $diag, $supradiag, $rhs); 
    die "Error solving tridiag system" unless $info == 0;
    # Obtain longitudinal macroscopic response from result
    $self->_epsL(my $epsL=1/$result->(:,(0)));
    # Normalize result so macroscopic field is 1.
    $result*=$epsL;
    my @Es= map {PDL->pdl($_)->complex} @{$result->unpdl};
    #states are RorI,nx,ny...
    #field is RorY,cartesian,nx,ny...
    my $ndims=$self->nr->B->ndims; # num. of dims of space
    my @dims=$self->nr->B->dims; # actual dims of space
    my $field_G=PDL->zeroes(2, $ndims, @dims)->complex;
    #field is RorI, cartesian, nx, ny...
    for(my $n=0; $n<$nh; ++$n){
	my $GPsi_G=Cscale($states->[$n], 
			  $self->nr->GNorm->mv(0,-1))->mv(-1,1);#^G|psi_n>
	#the result is RorI, cartesian, nx, ny,... 
	my $EnGPsi_G=Cmul($GPsi_G,$Es[$n]); #En ^G|psi_n>
	$field_G+=$EnGPsi_G;
    }
    #filter RandI for each cartesian
    $field_G *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=ifftn($field_G->mv(1,-1)->real, $ndims)->mv(-1,1)->complex; 
    $field_R*=$self->nr->B->nelem; #scale to have unit macroscopic field
    #result is RorI, cartesian, nx, ny,...
    $self->_field($field_R);
    #my $EM=$field_R->mv(0,-1)->mv(0,-1)->clump(-3)->mv(-2,0)->sumover->mv(-1,1)/$self->nr->B->nelem; 
    #print "EM=$EM\n";
    return $field_R;
}


__PACKAGE__->meta->make_immutable;
    
1;
