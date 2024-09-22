package Photonic::LE::NR2::SHChiTensor;
$Photonic::LE::NR2::SHChiTensor::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::SHChiTensor

=head1 VERSION

version 0.022

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

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
           densityA=>$dA, densityB=>$dB, nh=>$nh, nhf=>$nhf,
           epsA1=>$epsA1, epsB1=>$epsB1, epsA2=>$epsA2, epsB2=>$epsB2,
           filter=>$f, filterflag=>$ff);
   my $chiTensor=$chi->evaluate;

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

=item * evaluate([kind=>$kind,] [mask=>$mask])

Returns the macroscopic second Harmonic susceptibility function for a
given value of the dielectric functions of the host $epsA and the
particle $epsB at the fundamental 1 and second harmonic 2 frequency.

$kind is an optional letter for testing purposes with values
'd' for dipolar contribution,
'q' for quadrupolar contribution,
'e' for external contribution (dipolar+quadrupolar),
'l' for self consistent polarization without macroscopic depolarization,
'a' for self-consistent polarization (alternative, dubious),
'el' for longitudinal projection of external polarization
'f' for full selfconsistent calculation (the default).

Mask is a mask with ones and zeroes, to evaluate the contribution of
certain regions to the susceptibility.

=back

=head1 ACCESSORS (read only)

=over 4

=item * geometry

Photonic::Geometry structure describing the geometry of the
metamaterial

=item * B dims r G GNorm L scale f

Accessors handled by geometry.

=item * densityA, densityB

Dipole entities density in mediums A and B

=item * nhf

Maximum number of Haydock coefficients for field calculation

=item * filter

Optional filter to multiply by in reciprocal space

=item * epsA1, epsB1, epsA2, epsB2

Dielectric functions of components A and B at fundamental and SH frequency

=item * epsL

Value of dielectric function

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

=item * reorthogonalize

Reorthogonalize haydock flag

=back

=head1 ACCESSORS (missing)

=over 4

=item * u1, u2

Spectral variables

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::MatrixOps;
use PDL::IO::Storable;
use Photonic::Utils qw(make_haydock tensor incarnate_as);
use Photonic::Types -all;
use Photonic::LE::NR2::EpsTensor;
use Moo;

has 'nh' =>(is=>'ro', isa=>Num, required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'epsL'=>(is=>'ro', isa=>PDLComplex, init_arg=>undef,
	     writer=>'_epsL',
	     documentation=>'Value of dielectric function'  );
has 'converged'=>(is=>'ro', isa=>Num, init_arg=>undef,
		  writer=>'_converged',
		  documentation=>'The calculation did converge');

#required parameters
has 'geometry'=>(is=>'ro', isa => Geometry,
    handles=>[qw(B dims r G GNorm L scale f ndims)],required=>1
);
has 'densityA'=>(is=>'ro', isa=>Num, required=>1,
         documentation=>'Normalized dipole entities density in medium A');
has 'densityB'=>(is=>'ro', isa=>Num, required=>1,
         documentation=>'Normalized dipole entities density in medium B');
has 'nhf'=>(is=>'ro', required=>1,
         documentation=>'Maximum number of desired Haydock
                         coefficients for field calculation');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');

#optional parameters
has 'filter'=>(is=>'ro', isa=>PDLObj, predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');

#accessors
has 'epsA1'=>(is=>'ro', isa=>PDLComplex, required => 1,
    documentation=>'Dielectric function of host');
has 'epsB1'=>(is=>'ro', isa=>PDLComplex, required => 1,
        documentation=>'Dielectric function of inclusions');
has 'epsA2'=>(is=>'ro', isa=>PDLComplex, required=>1,
    documentation=>'Dielectric function of host at SH');
has 'epsB2'=>(is=>'ro', isa=>PDLComplex, required=>1,
        documentation=>'Dielectric function of inclusions');
has 'nrshp' =>(is=>'lazy', isa=>ArrayRef[InstanceOf['Photonic::LE::NR2::SHP']],
            init_arg=>undef,
            documentation=>'Array of Haydock SH polarization calculators');
has 'epsTensor'=>(is=>'lazy', isa=>InstanceOf['Photonic::LE::NR2::EpsTensor'],
         init_arg=>undef,
         documentation=>'diel. tensor at 2w');
has 'chiTensor'=>(is=>'ro', isa=>PDLObj, init_arg=>undef, writer=>'_chiTensor',
             documentation=>'SH Susceptibility from last evaluation');

has 'smallH'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');

with 'Photonic::Roles::KeepStates', 'Photonic::Roles::UseMask';

my %KIND2METHOD = (
  f => 'P2',
  l => 'selfConsistentVecL',
  a => 'P2LMCalt',
  d => 'dipolar',
  q => 'quadrupolar',
  e => 'external',
  el => 'externalVecL',
);
my %KIND2SUBTRACT = map +($_=>1), qw(f l a);


sub evaluate {
    my $self=shift;
    my $epsA1=$self->epsA1;
    my $epsB1=$self->epsB1;
    my $epsA2=$self->epsA2;
    my $epsB2=$self->epsB2;
    my %options=@_; #the rest are options. Currently, kind and mask.
    my $kind=lc($options{kind}//'f');
    my $mask=$options{mask};
    my $nd=$self->geometry->B->ndims;
    my $epsT=$self->epsTensor->epsTensor;
    my @P2M; #array of longitudinal polarizations along different directions.
    my $method = $KIND2METHOD{$kind};
    foreach(@{$self->nrshp}){
	my $nrsh=Photonic::LE::NR2::SH->new(
	    shp=>$_, epsA1=>$epsA1, epsB1=>$epsB1, epsA2=>$epsA2, epsB2=>$epsB2,
	    filterflag=>0);
	# XorY,nx,ny
	# dipolar, quadrupolar, external, full
	my $P2 = $nrsh->$method;
	my $P2M=$P2->mv(0,-1)
	    ->clump(-2) #linear index, XorY
	    ->sumover  #XorY
	    /$self->geometry->npoints;
	my $k=$_->haydock->geometry->Direction0;
	my $FPChi=$epsT-identity($nd); #four pi chi linear 2w
	my $P2MLC=($k*$P2M)->sumover; #Longitudinal component
	my $P2ML=$k*$P2MLC; #longitudinal projection
	my $Dep2=($FPChi*$P2ML)->sumover; # depolarization polarization
	my $P2Mmask=$P2M; #masked macroscopic polarization
	my $f=1; #filling fraction of masked region.
	if (defined $mask){ # is there a real mask?
	    $f=$mask->sum/$self->geometry->npoints; #filling fraction
				#of mask
	    $P2*=$mask->(*1); #masked polarization
	    $P2Mmask=$P2->mv(0,-1) #masked macroscopic polarization
	    ->clump(-2) #linear index, XorY
	    ->sumover  #XorY
		/$self->geometry->npoints;
	}
	$P2Mmask += $f*$Dep2 if $KIND2SUBTRACT{$kind}; # subtract masked macro depolarization field
	push @P2M, $P2Mmask;
    }
    #NOTE. Maybe I have to correct response to D-> response to E
    #I have to convert from the array of polarizations for given
    #directions to the actual cartesian chi's.
    #$P2Mp has cartesian, dyad indices
    my $P2Mp = PDL->pdl(@P2M);
    #Get cartesian indices out of the way, solve the system of
    #equations, and move the cartesian indices back
    my $chiTensor=tensor($P2Mp, $self->geometry->unitDyadsLU, $nd, 3, 1);
    $self->_chiTensor($chiTensor);
    return $chiTensor;
}

#Need geometry, maximum number of Haydock coefficients for LE::NR2::ALL nh

sub _build_nrshp { # One Haydock coefficients calculator per direction0
    my $self=shift;
    my $haydock = make_haydock($self, 'Photonic::LE::NR2::Haydock', $self->geometry->unitPairs, 1, qw(reorthogonalize use_mask mask));
    my @args=(nh=>$self->nhf);
    push @args, filter=>$self->filter if $self->has_filter;
    [ map Photonic::LE::NR2::SHP->new(
	    @args, haydock=>$_,
	    densityA=>$self->densityA, densityB=>$self->densityB,
    ), @$haydock ];
}

my @EPS_ATTRS = qw(geometry nh reorthogonalize smallH smallE);
sub _build_epsTensor {
    my $self=shift;
    incarnate_as('Photonic::LE::NR2::EpsTensor', $self, \@EPS_ATTRS, epsA=>$self->epsA2, epsB=>$self->epsB2);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
