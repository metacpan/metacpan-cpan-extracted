package Photonic::LE::NR2::SH;
$Photonic::LE::NR2::SH::VERSION = '0.015';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::SH

=head1 VERSION

version 0.015

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

   use Photonic::LE::NR2::SH;
   my $nrsh=Photonic::LE::NR2::SH->
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

$shp is a Photonic::LE::NR2::SHP object with the invariant part of
the data structures for the calculations

$epsA1, $epsB1, $epsA2, $epsB2 are the dielectric functions of the A
and B materials at the fundamental and the second harmonic frequency

=back

=head1 ACCESORS (read only)

=over 4

=item * shp

Invariant part of SHG calculator.

=item * ndims nrf densityA densityB density nr

Accesors handled by shp

=item * epsA1, epsB1

Dielectric functions of materials A and B at the fundamental frequency

=item * epsA2, epsB2

Dielectric functions of materials A and B at the second harmonic frequency

=item * alpha1

Polarizabity field at the fundamental frequency

=item * alpha2

Polarizabity field at the second harmonic frequency

=item * u1

Spectral variable at fundamental frequency

=item * u2

Spectral variable at second harmonic frequency

=item * field1

longitudinal field at fundamental

=item * field2

longitudinal field at second harmonic

=item * dipolar

Dipolar contribution to SH polarization field

=item * quadrupolar

SH quadrupolar contribution to SH polarization field

=item * external

External contribution to SH polarization field (quadrupolar + dipolar)

=item * external_G

External SH polarization field in reciprocal space

=item * externalL_G

Longitudinal projection of external polarization field in reciprocal space

=item * HP

Photonic::LE::NR2::AllH structure to calculate Haydock basis for
non linear polarization

=item * externalL_n

External SH polarization field represented in Haydock basis

=item * selfConsistentL_n

SH self consistent longitudinal polarization in Haydock representation

=item * selfConsistentL_G

SH self consistent longitudinal polarization components in reciprocal
space

=item * selfConsistentVecL_G

SH self consistent longitudinal polarization vector field projection in
reciprocal space

=item * selfConsistentVecL

SH self consistent longitudinal polarization vector projection field
in real space

=item * P2

SH self consistent total polarization vector field in real space

=back

=head1 ACCESORS (read/write)

=over 4

=item * filterflag

Flag to filter results in reciprocal space to smooth non linear
polarization using the field (nrf) filter.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::FFTW3;
use Photonic::LE::NR2::AllH;
use Photonic::Utils qw(RtoG GtoR HProd linearCombineIt);
use Photonic::ExtraUtils qw(cgtsv);
use Photonic::Iterator;
use PDL::Constants qw(PI);
use Moose;
use MooseX::StrictConstructor;

has 'shp'=>(is=>'ro', 'isa'=>'Photonic::LE::NR2::SHP', required=>1,
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
has 'field1'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_field1',
         documentation=>'longitudinal field at fundamental');
has 'field2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_field2',
         documentation=>'longitudinal field at second harmonic');
has 'epsL2'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         writer=>'_epsL2', predicate=>'has_epsL2',
         documentation=>'longitudinal dielectric function at 2w');
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
             'SH ext. longitudinal polarization comp. in reciprocal space');
has 'externalVecL_G'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_externalVecL_G',
         documentation=>
             'SH ext. longitudinal polarization proj. in recip. space');
has 'externalVecL'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
         lazy=>1, builder=>'_build_externalVecL',
         documentation=>
             'SH ext. longitudinal polarization proj. in real space');
has 'HP' =>(is=>'ro', isa=>'Photonic::LE::NR2::AllH', init_arg=>undef,
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

has 'P2LMCalt'=>(is=>'ro', isa=>'PDL::Complex',
         init_arg=>undef, lazy=>1,
         builder=>'_build_P2LMCalt',
         documentation=>
             'SH self consistent total macroscopic polarization
              in real space. Alternative');

has 'filterflag'=>(is=>'rw',
         documentation=>'Filter results in reciprocal space');

#sub BUILD {
#    my $self=shift;
#    #solve linear longitudinal field at w and 2w
#    $self->_field1($self->nrf->evaluate($self->epsA1, $self->epsB1));
#    $self->_field2($self->nrf->evaluate($self->epsA2, $self->epsB2));
#    #my $nh=$self->nrf->nh;
#    #$nh=$self->nrf->nr->iteration if $nh>=$self->nrf->nr->iteration;
#    #$self->_nh($nh);
#}

sub _alpha {
    my $self=shift;
    my $epsA1=shift;
    my $epsB1=shift;
    my $alphaA1=my $alphaB1=0+0*i;
    $alphaA1=($epsA1-1)/(4*$self->densityA*PI) unless
	$self->densityA==0;
    $alphaB1=($epsB1-1)/(4*$self->densityB*PI) unless
	$self->densityB==0;
    $alphaA1=$alphaB1 if $self->densityA==0;
    $alphaB1=$alphaA1 if $self->densityB==0;
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


sub _build_field1 {
    my $self=shift;
    $self->nrf->evaluate($self->epsA1, $self->epsB1);
}

sub _build_field2 {
    my $self=shift;
    $self->nrf->evaluate($self->epsA2, $self->epsB2);
    $self->_epsL2($self->nrf->epsL);
}

sub _build_dipolar {
    my $self=shift;
    my $field=$self->field1;
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
    my $field=$self->field1;
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

sub _build_externalVecL_G {
    my $self=shift;
    my $extG=$self->externalL_G;
    my $result=$self->nrf->nr->geometry->LC2Vec_G($extG);
    return $result;
}

sub _build_externalVecL {
    my $self=shift;
    my $extG=$self->externalVecL_G;
    my $result=GtoR($extG, $self->ndims, 1);
    return $result;
}

sub _build_HP { #build haydock states for P2
    my $self=shift;
    my $ext=$self->externalL_G;
    my $normext=sqrt(Cabs2($ext)->sum);
    my $extnorm=$ext->complex/$normext;
    my $hp=Photonic::LE::NR2::AllH->new(nh=>$self->nrf->nh,
	geometry=>$self->nrf->nr->geometry, smallH=>$self->nrf->nr->smallH,
		keepStates=>1, firstState=>$extnorm);
    $hp->run;
    return $hp;
}

sub _build_externalL_n {
    my $self=shift;
    my $pol=$self->externalL_G;
    my $stateit=$self->HP->state_iterator;
    my $nh=$self->HP->iteration;
    # innecesario: \propto \delta_{n0}
    #my @Pn=map HProd($states->[$_],$pol), 0..$nh-1;
    my @Pn=map {0+0*i} 0..$nh-1;
    #$Pn[0]=$pol->(:,(0),(0));
    $Pn[0]=HProd($stateit->nextval,$pol);
    #print join " Pn ", @Pn[0..3], "\n";
    return PDL->pdl([@Pn])->complex;
}

sub _build_selfConsistentL_n {
    my $self=shift;
    my $external=$self->externalL_n;
    my $nh=$self->HP->iteration;
    my $as=$self->HP->as;
    my $bs=$self->HP->bs;
    my $u2=$self->u2;
    my $diag=$u2->complex - PDL->pdl($as)->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-PDL->pdl(@$bs)->(0:$nh-1)->r2C->mv(0,-1)->rotate(-1)->mv(-1,0)->complex;
    my $supradiag=$subdiag;
    my ($result, $info)= cgtsv($subdiag, $diag, $supradiag, $external);
    die "Error solving tridiag system" unless $info == 0;
    $result->complex;
    $result *= $u2/$self->epsA2;
    return $result;
}

sub _build_selfConsistentL_G {
    my $self=shift;
    my $filterflag=$self->filterflag;
    $self->filterflag(0);
    my $PLn=[$self->selfConsistentL_n->dog];
    my $stateit=$self->HP->state_iterator;
    my $result=linearCombineIt($PLn, $stateit);
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

sub _build_P2LMCalt {
    my $self=shift;
    my $PexL_G=$self->externalL_G; #external long 2w polarization
    my $PexM=$self->external_G->(:,:,(0),(0)); #macroscopic external.
    my $ndims=$self->nrf->nr->geometry->ndims;
    my $nelem=$self->nrf->nr->geometry->npoints;
    my $k=$self->nrf->nr->geometry->Direction0;
    my $GNorm=$self->nrf->nr->geometry->GNorm;
    my $epsA2=$self->epsA2;
    my $u2=$self->u2;
    my $B=$self->nrf->nr->geometry->B;
    my $as=$self->nrf->nr->as;
    my $bs=$self->nrf->nr->bs;
    my $states=$self->nrf->nr->states;
    my $nh=$self->nrf->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->nrf->nr->iteration if $nh>=$self->nrf->nr->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=|0>.
    my $diag=$self->u2->Cconj->complex - PDL->pdl([@$as])->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-PDL->pdl(@$bs)->(0:$nh-1)->r2C->mv(0,-1)->rotate(-1)->mv(-1,0)->complex;
    my $supradiag=$subdiag->real->mv(0,-1)->rotate(-1)->mv(-1,0)->complex;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my ($phi_n, $info)= cgtsv($subdiag, $diag, $supradiag, $rhs);
    die "Error solving tridiag system" unless $info == 0;
    my $phi_G=linearCombine([$phi_n->dog], $states);
    my $Pphi=$k*(1-$epsA2)*$u2/$epsA2*HProd($phi_G, $PexL_G);

    my $beta_G=RtoG($B*GtoR($states->[0],$ndims,0), $ndims,0);
    #my $beta_G=RtoG(GtoR($states->[0],$ndims,0), $ndims,0);
    my $betaV_G=$beta_G->(,*1)*$GNorm;
    #my $betaV_G=$beta_G->(,*1)*$k;
    my $betaV_n=PDL->pdl(
	[map {HProd($betaV_G,$states->[$_]->(,*1), 1)} (0..$nh-1)]
	)->complex;
    my @Ppsi;
    foreach(0..$ndims-1){
	my ($psi_n, $psiinfo)=
	    cgtsv($subdiag, $diag, $supradiag, $betaV_n->(:,($_),:));
	die "Error solving tridiag system" unless $psiinfo == 0;
	# RorI nx ny .... cartesian
	my $psi_G=linearCombine([$psi_n->dog], $states);
	my $Ppsi=HProd($psi_G, $PexL_G);
	push @Ppsi, $Ppsi;
    }
    my $Ppsi=PDL->pdl(@Ppsi)->complex;
    #my $P2M=$Pphi+$Ppsi;
    my $P2M=$Pphi+$Ppsi+$PexM*$nelem; # Unnormalize Pex !!
    #my $P2M=$Pphi;#+$Ppsi;
    #my $P2M=$Ppsi;#+$Ppsi;
    #my $P2M=PDL->pdl(@P2M)->complex;
    # RorI nx ny .... cartesian
    #my $psiV_n=PDL->pdl(@psi_ns);
    #my $psi_G=linearCombine([$psiV_n->dog], $states);
    #my $Pphi=(1-$epsA2)*$u2/$epsA2*HProd($phi_G, $PexL_G);
    #my $Ppsi=HProd($psi_G, $PexL_G);
    #my $P2M=$k*($Pphi+$Ppsi);
    return $P2M->(,,*1,*1);
    #return $prod->(,*1)*$self->nrf->nr->geometry->Direction0;
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
