=head1 NAME

Photonic::NonRetarded::SH

=head1 VERSION

version 0.007

=head1 SYNOPSIS

   use Photonic::NonRetarded::SH;
   my $nrsh=Photonic::NonRetarded::SH->
             new(shp=>$shp, epsA1=>$epsA1, epsB1=>$epsB1,
                 epsA2=>$epsA2, epsB2=>$epsB2); 
   my $PL_G=$nrsh->selfConsistentL_G;


=head1 DESCRIPTION

Calculates the non retarded SH polarizations and fields of arbitrary a
periodic composite made up of centrosymmetric isotropic component materials,
using the continuous dipolium model. 

=head1 METHODS

=over 4

=item * new(shp=>$shp, epsA1=>$epsA1, epsB1=>$epsB1, epsA2=>$epsA2,
            epsB2=>epsB2);  

Initializes the structure

$shp is a Photonic::NonRetarded::SHP object with the invariant part of
the data structures for the calculations

$epsA1, $epsB1, $epsA2, $epsB2 are the dielectric functions of the A
and B materials at the fundamental and the second harmonic frequency

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

package Photonic::NonRetarded::SH;
$Photonic::NonRetarded::SH::VERSION = '0.007';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::FFTW3;
use Photonic::NonRetarded::AllH;
use Photonic::Utils qw(RtoG GtoR HProd cgtsl linearCombine);
use Moose;
use PDL::Constants qw(PI);

has 'shp'=>(is=>'ro', 'isa'=>'Photonic::NonRetarded::SHP', required=>1,
    handles=>[qw(ndims nrf densityA densityB density nr)],
    documentation=>'Object with invariant part of SHG calculation');
has 'epsA1'=>(is=>'ro', isa=>'PDL::Complex', required=>1,
    documentation=>'Fundamental dielectric function of host');
has 'epsB1'=>(is=>'ro', isa=>'PDL::Complex', 
        documentation=>'Fundamental dielectric function of inclusions');
has 'epsA2'=>(is=>'ro', isa=>'PDL::Complex', required=>1,
    documentation=>'SH Dielectric function of host');
has 'epsB2'=>(is=>'ro', isa=>'PDL::Complex', required=>1, 
        documentation=>'SH Dielectric function of inclusions');
has 'alpha1'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_alpha1', 
         documentation=>'Linear "atomic" polarizability');
has 'alpha2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_alpha2', 
         documentation=>'SH linear "atomic" polarizability');
has 'u1'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_u1', 
         documentation=>'Spectral variable at fundamental');
has 'u2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_u2',  
         documentation=>'Spectral variable at SH');
has 'dipolar'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_dipolar', 
         documentation=>'SH dipolar contribution to SH polarization');
has 'quadrupolar'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_quadrupolar', 
         documentation=>'SH quadrupolar contribution to SH polarization');
has 'external'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_external', 
         documentation=>'SH external contribution to SH polarization');
has 'external_G'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_external_G',
         documentation=>'SH ext. polarization in reciprocal space');
has 'externalL_G'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_externalL_G', 
         documentation=>
             'SH ext. longitudinal polarization in reciprocal space'); 
has 'HP' =>(is=>'ro', isa=>'Photonic::NonRetarded::AllH', init_arg=>undef,
         lazy=>1, builder=>'_build_HP',
         documentation=>
         'Structure to calculate Haydock basis for non linear polarization');
has 'externalL_n'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_externalL_n', 
         documentation=>
             'SH ext. longitudinal polarization in Haydock
               representation');
has 'selfConsistentL_n'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_selfConsistentL_n',
         documentation=>
             'SH self consistent longitudinal polarization 
              in Haydock representation');
has 'selfConsistentL_G'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_selfConsistentL_G',
         documentation=>
             'SH self consistent longitudinal polarization components in
               reciprocal space');
has 'selfConsistentVecL_G'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_selfConsistentVecL_G',
         documentation=>
             'SH self consistent longitudinal polarization vector
              field in reciprocal space');
has 'selfConsistentVecL'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_selfConsistentVecL',
         documentation=>
             'SH self consistent longitudinal polarization vector
              field in real space');
has 'P2'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_P2',
         documentation=>
             'SH self consistent total polarization vector
              field in real space');

has 'filterflag'=>(is=>'rw', 
         documentation=>'Filter results in reciprocal space');

sub BUILD {
    my $self=shift;
    $self->nrf->evaluate($self->epsA1, $self->epsB1); #solve linear field
    #my $nh=$self->nrf->nh;
    #$nh=$self->nrf->nr->iteration if $nh>=$self->nrf->nr->iteration;
    #$self->_nh($nh);
}

sub _alpha {
    my $self=shift;
    my $epsA1=shift;
    my $epsB1=shift;
    my $alphaA1=my $alphaB1=0+0*i;
    $alphaA1=($epsA1-1)/(4*$self->densityA*PI) unless
	$self->densityA==0; 
    $alphaB1=($epsB1-1)/(4*$self->densityB*PI) unless
	$self->densityB==0; 
    my $B=$self->nrf->nr->B;
    return $alphaA1*(1-$B)+$B*$alphaB1;
}

sub _build_alpha1 {
    my $self=shift;
    $self->_alpha($self->epsA1,$self->epsB1);
}

sub _build_alpha2 {
    my $self=shift;
    $self->_alpha($self->epsA2,$self->epsB2);
}


sub _build_dipolar {
    my $self=shift;
    my $field=$self->nrf->field;
    my $ndims=$self->ndims;
    #E^2 Square each complex component and sum over components
    #result is RorI, nx, ny...
    my $Esquare_R=Cmul($field, $field)->sumover;
    #Fourier transform
    # RorI nx ny...
    my $Esquare_G=fftn($Esquare_R->real, $ndims)->complex;
    #cartesian, nx, ny...
    my $G=$self->nrf->nr->G;
    #RorI cartesian nx ny
    my $iG=$G*i; 
    #RorI cartesian nx ny...
    my $iGE2=Cmul($iG, $Esquare_G->(,*1));
    #back to real space. Get cartesian out of the way and then back
    #RorI, cartesian, nx, ny... 
    my $nablaE2=ifftn($iGE2->mv(1,-1)->real, $ndims)->mv(-1,1)->complex; 
    my $factor=-$self->density*$self->alpha1*$self->alpha2/2;
       #RorI, nx, ny... 
    my $P=$factor->(,*1)*$nablaE2;
    #Should I filter in Fourier space before returning?
    return $P;
}

sub _build_quadrupolar {
    my $self=shift;
    my $field=$self->nrf->field;
    my $ndims=$self->ndims; #dims of space
    #E E tensor
    #result is RorI, cartesian, cartesian, nx, ny...
    my $EE_R=$field->(,*1)*$field->(,,*1); #use dummies for external product
    #RorI nx, ny...
    my $naa=$self->density*$self->alpha1*$self->alpha1/2;
    #RorI cartesian cartesian nx ny...
    my $naaEE_R=$naa->(,*1,*1)*$EE_R;
    #Fourier transform
    # RorI cartesian cartesian nx ny... Get cartesians out of the way
    # and thread
    my $naaEE_G=fftn($naaEE_R->mv(1,-1)->mv(1,-1)->real,
			$ndims)->mv(-1,1)->mv(-1,1)->complex;
    #cartesian, nx, ny...
    my $G=$self->nrf->nr->G;
    #RorI cartesian nx ny...
    my $iG=$G*i; 
    #RorI cartesian nx ny...
    #Note: sumover knows how to sum complex values.
    my $iGnaaEE_G=($iG->(,,*1)*$naaEE_G)->sumover; #dot
    #Filter. nx ny...
    #Note: System knows how to multiply complex by real.
    $iGnaaEE_G = $iGnaaEE_G*$self->nrf->filter->(*1) if $self->nrf->has_filter;
    #back to real space. Get cartesian out of the way and then back
    #RorI, cartesian, nx, ny... 
    my $P=
	ifftn($iGnaaEE_G->mv(1,-1)->real, $ndims)->mv(-1,1)->complex; 
    return $P;
}

sub _build_external {
    my $self=shift;
    return $self->dipolar+$self->quadrupolar;
}

sub _build_external_G {
    my $self=shift;
    my $filterflag=$self->filterflag;
    $self->filterflag(0);
    # RoI cartesian nx ny...
    my $result=RtoG($self->external, $self->ndims, 1);
    $self->filterflag($filterflag);
    $result=$self->_filter($result,1) if $filterflag;
    return $result;
}

sub _build_externalL_G {
    my $self=shift;
    # RoI cartesian nx ny...
    my $filterflag=$self->filterflag;
    $self->filterflag(0);
    my $result=$self->nrf->nr->geometry->Vec2LC_G($self->external_G);
    $self->filterflag($filterflag);
    $result=$self->_filter($result,0) if $filterflag;
    return $result;
}

sub _build_HP { #build haydock states for P2
    my $self=shift;
    my $ext=$self->externalL_G;
    my $normext=sqrt(Cabs2($ext)->sum);
    my $extnorm=$ext->complex/$normext;
    my $hp=Photonic::NonRetarded::AllH->new(	nh=>$self->nrf->nh, 
	geometry=>$self->nrf->nr->geometry, small=>$self->nrf->nr->small,
		keepStates=>1, nextState=>$extnorm);
    $hp->run;
    return $hp;
}

sub _build_externalL_n {
    my $self=shift;
    my $pol=$self->externalL_G;
    my $states=$self->HP->states;
    my $nh=$self->HP->iteration;
    my @Pn=map HProd($states->[$_],$pol), 0..$nh-1;
    return PDL->pdl([@Pn])->complex;
}
    
sub _build_selfConsistentL_n {
    my $self=shift;
    my $external=$self->externalL_n;
    my $nh=$self->HP->nh;
    my $as=$self->HP->as;
    my $bs=$self->HP->bs;
    my $u2=$self->u2;
    my $diag=$u2->complex - PDL->pdl([@$as])->(0:$nh-1);
    my $subdiag=-PDL->pdl(@$bs)->(0:$nh-1)->r2C;
    # rotate complex zero from first to last element.
    my $supradiag=$subdiag->mv(0,-1)->rotate(-1)->mv(-1,0);
    my ($result, $info)=cgtsl($subdiag, $diag, $supradiag, $external);
    die "Error solving tridiag system" unless $info == 0;
    $result *= $u2/$self->epsA2;
    return $result;
}    

sub _build_selfConsistentL_G {
    my $self=shift;
    my $filterflag=$self->filterflag;
    $self->filterflag(0);
    my $PLn=[$self->selfConsistentL_n->dog];
    my $states=$self->HP->states;
    my $result=linearCombine($PLn, $states);
    $self->filterflag($filterflag);
    $result=$self->_filter($result,0)  if $filterflag;
    return $result;
}

sub _build_selfConsistentVecL_G {
    my $self=shift;
    my $sf=$self->selfConsistentL_G;
    my $result=$self->nrf->nr->geometry->LC2Vec_G($sf);
    return $result;
}

sub _build_selfConsistentVecL {
    my $self=shift;
    my $svf=$self->selfConsistentVecL_G;
    my $result=GtoR($svf, $self->ndims, 1);
    return $result;
}

sub _build_P2 {
    my $self=shift;
    my $density=$self->density;
    my $alpha2=$self->alpha2;
    my $PL=$self->selfConsistentVecL;
    my $Pext=$self->external;
    my $P2=-4*PI*($alpha2*$density)->(,*1)*$PL+$Pext;
    return $P2;
}

sub _build_u1 {
    my $self=shift;
    #return 1/(1-$self->epsB1/$self->epsA1);
    return $self->nrf->u;
}

sub _build_u2 {
    my $self=shift;
    return 1/(1-$self->epsB2/$self->epsA2);
}

sub _filter { #Filter complex field in reciprocal space
    my $self=shift;
    my $field=shift;
    my $skip=shift; #dimensions to skip, 0 for scalar, 1 for vector, 2
		    #for tensor,  etc.
    return $field unless $self->nrf->has_filter;
    my $filter=$self->nrf->filter;
    $field=$field->mv(1,-1) foreach(0..$skip-1); #mv cartesian out of
                                                 #the way
    $field *=$filter;
    $field=$field->mv(-1,1) foreach(0..$skip-1); #mv cartesians back
    return $field;
}
    

__PACKAGE__->meta->make_immutable;
    
1;
