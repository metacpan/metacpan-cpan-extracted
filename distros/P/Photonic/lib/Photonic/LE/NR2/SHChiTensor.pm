package Photonic::LE::NR2::SHChiTensor;
$Photonic::LE::NR2::SHChiTensor::VERSION = '0.014';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::SHChiTensor

=head1 VERSION

version 0.014

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 SYNOPSIS

   use Photonic::LE::NR2::SHChiTensor;
   my $chi=Photonic::LE::NR2::SHChiTensor->new(geometry=>$g,
           $densityA=>$dA, $densityB=>$dB, nh=>$nh, nhf=>$nhf,
           filter=>$f, filterflag=>$ff);
   my $chiTensor=$chi->evaluate($epsA1, $epsB1, $epsA2, $epsB2);

=head1 DESCRIPTION

Calculates the second harmonic susceptibility tensor for a given fixed
Photonic::Geometry structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(geometry=>$g, densityA=>$da, densityB=>$db, nh=>$nh, nhf=>$nhf[, filter=>$ff][, smallH=>$smallH][, smallE=>$smallE])

Initializes the structure.

$g Photonic::Geometry describing the structure

$da, $db number densities for material A and B (in which units?)

$nh is the maximum number of Haydock coefficients to use.

$nhf is the maximum number of Haydock coefficients for the field calculation.

$ff is a (maybe smooth) cutoff function in reciprocal space to smothen the geometry.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
haydock coefficients and continued fraction.

=item * evaluate($epsA1, $epsB1, $epsA2, $epsB2, [kind=>$kind,] [mask=>$mask] )

Returns the macroscopic second Harmonic susceptibility function for a
given value of the dielectric functions of the host $epsA and the
particle $epsB at the fundamental 1 and second harmonic 2 frequency.
$kind is an optional letter for testing purposes with values 'd' for
dipolar, 'q' for quadrupolar, 'e' for external and 'f' for full
selfconsistent calculation (the default). Mask is a mask with ones and
zeroes, to evaluate the contribution of certain regions to the
susceptibility.


=back

=head1 ACCESORS (read only)

=over 4

=item * geometry

Photonic::Geometry structure describing the geometry of the
metamaterial

=item * B dims r G GNorm L scale f

Accesors handled by geometry.

=item * densityA, densityB

Dipole entities density in mediums A and B

=item * nhf

Maximum number of Haydock coefficients for field calculation

=item * filter

Optional filter to multiply by in reciprocal space

=item * epsA1, epsB1, epsA2, epsB2

Dielectric functions of components A and B at fundamental and SH frequency

=item * nrshp

Array of Photonic::LE::NR2::SHP Haydock SH polarization calculators,
one for each direction

=item * chiTensor

The dielectric tensor

=item * nh

The maximum number of Haydock coefficients to use.

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallH smallE

Criteria of convergence for Haydock coefficients and for fields. 0
means don't check.

=back

=head1 ACCESORS (missing)

=over 4

=item * u1, u2

Spectral variables

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
use Photonic::Types;
use Photonic::LE::NR2::EpsTensor;
use Photonic::Utils qw(cmatmult);

use Moose;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1, lazy=>1, builder=>'_nh',
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsL'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
	     writer=>'_epsL',
	     documentation=>'Value of dielectric function'  );
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
		 writer=>'_nhActual',
		 documentation=>'Actual number of coefficients used' );
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef,
		  writer=>'_converged',
		  documentation=>'The calculation did converge');

sub _nh { #build desired number of Haydock coeffs to use.
    my $self=shift;
    return $self->nr->nh; #defaults to coefficients desired
}



#required parameters
has 'geometry'=>(is=>'ro', isa => 'Photonic::Types::Geometry',
    handles=>[qw(B dims r G GNorm L scale f)],required=>1
);
has 'densityA'=>(is=>'ro', isa=>'Num', required=>1,
         documentation=>'Normalized dipole entities density in medium A');
has 'densityB'=>(is=>'ro', isa=>'Num', required=>1,
         documentation=>'Normalized dipole entities density in medium B');
has 'nhf'=>(is=>'ro', required=>1,
         documentation=>'Maximum number of desired Haydock
                         coefficients for field calculation');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');

#optional parameters
has 'filter'=>(is=>'ro', isa=>'PDL', predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');

#accesors
has 'epsA1'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA1',
    documentation=>'Dielectric function of host');
has 'epsB1'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB1',
        documentation=>'Dielectric function of inclusions');
has 'epsA2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA2',
    documentation=>'Dielectric function of host');
has 'epsB2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB2',
        documentation=>'Dielectric function of inclusions');
has 'nrshp' =>(is=>'ro', isa=>'ArrayRef[Photonic::LE::NR2::SHP]',
            init_arg=>undef, lazy=>1, builder=>'_build_nrshp',
            documentation=>'Array of Haydock SH polarization calculators');
has 'epsTensor'=>(is=>'ro', isa=>'Photonic::LE::NR2::EpsTensor',
         init_arg=>undef,
         lazy=>1,  builder=>'_build_epsTensor',
         documentation=>'diel. tensor at 2w');
has 'chiTensor'=>(is=>'ro', isa=>'PDL', init_arg=>undef, writer=>'_chiTensor',
             documentation=>'SH Susceptibility from last evaluation');

has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');

sub evaluate {
    my $self=shift;
    $self->_epsA1(my $epsA1=shift);
    $self->_epsB1(my $epsB1=shift);
    $self->_epsA2(my $epsA2=shift);
    $self->_epsB2(my $epsB2=shift);
    my %options=@_; #the rest are options. Currently, kind and mask.
    my $kind=lc($options{kind}); # Undocumented, for testing: Use full (f) P2 or
		    # (d) dipolar or  (q) quadrupolar or (e) external
    my $mask=$options{mask};
    my $nd=$self->geometry->B->ndims;
    my $epsT=$self->epsTensor->evaluate($epsA2, $epsB2);
    my @P2M; #array of longitudinal polarizations along different directions.
    foreach(@{$self->nrshp}){
	my $nrsh=Photonic::LE::NR2::SH->new(
	    shp=>$_, epsA1=>$epsA1, epsB1=>$epsB1, epsA2=>$epsA2,
	    epsB2=>$epsB2, filterflag=>0);
	# RorI, XorY,nx,ny
	# dipolar, quadrupolar, external, full
	my $P2;
	$P2=$nrsh->P2 if not defined $kind;
	$P2=$nrsh->P2 if $kind eq 'f';
	$P2=$nrsh->selfConsistentVecL if $kind eq 'l';
	$P2=$nrsh->P2LMCalt if $kind eq 'a';
	$P2=$nrsh->dipolar if $kind eq 'd';
	$P2=$nrsh->quadrupolar if $kind eq 'q';
	$P2=$nrsh->external if $kind eq 'e';
	$P2=$nrsh->externalVecL if $kind eq 'el';
	my $P2M=$P2->mv(0,-1)->mv(0,-1)
	    ->clump(-3) #linear index, RorI, XorY
	    ->mv(-2,0) #RorI, index, XorY
	    ->complex->sumover  #RorI, XorY
	    /$self->geometry->npoints;
	my $k=$_->nrf->nr->geometry->Direction0;
	my $FPChi=$epsT-identity($nd); #four pi chi linear 2w
	my $P2MLC=($k*$P2M)->sumover; #Longitudinal component
	my $P2ML=$k*$P2MLC; #longitudinal projection
	my $Dep2=($FPChi*$P2ML)->sumover; # depolarization polarization
	my $P2Mmask=$P2M; #masked macroscopic polarization
	my $f=1; #filling fraction of masked region.
	if (defined $mask){ # is there a real mask?
	    $f=$mask->sum/$self->geometry->npoints; #filling fraction
				#of mask
	    $P2=$P2*$mask->(*1); #masked polarization
	    $P2Mmask=$P2->mv(0,-1)->mv(0,-1) #masked macroscopic polarization
	    ->clump(-3) #linear index, RorI, XorY
	    ->mv(-2,0) #RorI, index, XorY
	    ->complex->sumover  #RorI, XorY
		/$self->geometry->npoints;
	}
	$P2Mmask = $P2Mmask + $f*$Dep2 if $kind eq 'f' or $kind eq 'l'
	    or $kind eq 'a'; # substract masked macro depolarization field
	push @P2M, $P2Mmask;
    }
    #NOTE. Maybe I have to correct response to D-> response to E
    #I have to convert from the array of polarizations for given
    #directions to the actual cartesian chi's.
    #$reP2M and $imP2M have cartesian, dyad indices
    my $reP2M=PDL->pdl([map {$_->re} @P2M]);
    my $imP2M=PDL->pdl([map {$_->im} @P2M]);
    my ($lu, $perm, $parity)=@{$self->geometry->unitDyadsLU};
    #$reChi, $imChi have cartesian, dyad indices
    #Get cartesian indices out of the way, solve the system of
    #equations, and move the cartesian indices back
    my $reChi=lu_backsub($lu, $perm, $parity, $reP2M->mv(0,-1))->mv(-1,0);
    my $imChi=lu_backsub($lu, $perm, $parity, $imP2M->mv(0,-1))->mv(-1,0);
    #chi has three cartesian indices
    my $chiTensor=PDL->zeroes(2, $nd, $nd, $nd)->complex;
    #convert dyadic to cartesian indices
    my $n=0;
    for my $i(0..$nd-1){
	for my $j($i..$nd-1){
	    $chiTensor->(:,:,($i),($j)).=$reChi(:,$n)+i*$imChi(:,$n);
	    $chiTensor->(:,:,($j),($i)).=$reChi(:,$n)+i*$imChi(:,$n);
	    ++$n;
	}
    }
    $self->_chiTensor($chiTensor);
    return $chiTensor;
}

#Need geometry, maximum number of Haydock coefficients for LE::NR2::ALL nh

sub _build_nrshp { # One Haydock coefficients calculator per direction0
    my $self=shift;
    my @nrshp;
    foreach(@{$self->geometry->unitPairs}){
	my $g=dclone($self->geometry); #clone geometry
	#OJO: Cuánto vale el campo macroscópico? Hay que normalizar esto?
	$g->Direction0($_); #add G0 direction
	#Build a corresponding LE::NR2::AllH structure
	my $nr=Photonic::LE::NR2::AllH->new(
	    nh=>$self->nh, geometry=>$g, keepStates=>1,
	    reorthogonalize=>$self->reorthogonalize, smallH=>$self->smallH);
	my @args=(nr=>$nr, nh=>$self->nhf, smallE=>$self->smallE);
	push @args, filter=>$self->filter if $self->has_filter;
	my $nrf=Photonic::LE::NR2::Field->new(@args);
	my $nrshp=Photonic::LE::NR2::SHP->
	    new(nrf=>$nrf, densityA=>$self->densityA,
		densityB=>$self->densityB);
	push @nrshp, $nrshp;
    }
    return [@nrshp]
}

sub _build_epsTensor {
    my $self=shift;
    my $geometry=$self->geometry;
    my $nh=$self->nh; #desired number of Haydock terms
    my $smallH=$self->smallH; #smallness
    my $smallE=$self->smallE; #smallness
    my $eT=Photonic::LE::NR2::EpsTensor
	->new(geometry=>$self->geometry, nh=>$self->nh,
	      reorthogonalize=>$self->reorthogonalize, smallH=>$self->smallH,
	      smallE=>$self->smallE);
    return $eT;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
