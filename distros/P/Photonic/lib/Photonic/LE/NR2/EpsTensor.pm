package Photonic::LE::NR2::EpsTensor;
$Photonic::LE::NR2::EpsTensor::VERSION = '0.011';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::EpsTensor

=head1 VERSION

version 0.011

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

   use Photonic::LE::NR2::EpsTensor;
   my $eps=Photonic::LE::NR2::EpsTensor->new(geometry=>$g);
   my $epsilonTensor=$eps->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor for a given fixed
Photonic::Geometry structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(geometry=>$g, nh=>$nh, smallH=>$smallH, smallE=>$smallE, keepStates=>$k)

Initializes the structure.

$g Photonic::Geometry describing the structure

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
the Haydock coefficients and the tensor calculations.

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsA, $epsB)

Returns the macroscopic dielectric function for a given value of the
dielectric functions of the host $epsA and the particle $epsB.

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

=item * nr

Array of Photonic::LE::NR2::AllH structures, one for each direction

=item * epsL

Array of Photonic::LE::NR2::EpsL structures, one for each direction.

=item * epsTensor

The dielectric tensor

=item * nh

The maximum number of Haydock coefficients to use.

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallH smallE

Criteria of convergence for Haydock and epsilon calculations. 0 means
don't check.
    *Check last remark*

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
use Photonic::LE::NR2::AllH;
use Photonic::LE::NR2::EpsL;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

has 'geometry'=>(is=>'ro', isa => 'Photonic::Types::Geometry',
    handles=>[qw(B ndims dims r G GNorm L scale f)],required=>1
);
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
has 'nr' =>(is=>'ro', isa=>'ArrayRef[Photonic::LE::NR2::AllH]',
            init_arg=>undef, lazy=>1, builder=>'_build_nr',
            documentation=>'Array of Haydock calculators');
has 'epsL'=>(is=>'ro', isa=>'ArrayRef[Photonic::LE::NR2::EpsL]',
             init_arg=>undef, lazy=>1, builder=>'_build_epsL',
             documentation=>'Array of epsilon calculators');
has 'epsTensor'=>(is=>'ro', isa=>'PDL', init_arg=>undef, writer=>'_epsTensor',
             documentation=>'Dielectric Tensor from last evaluation');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All EpsL evaluations converged in last evaluation');
has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

with 'Photonic::Roles::KeepStates', 'Photonic::Roles::UseMask';

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=shift);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my @eps; #array of @eps along different directions.
    my $converged=1;
    foreach(@{$self->epsL}){
	push @eps, $_->evaluate($epsA, $epsB);
	$converged &&=$_->converged;
    }
    $self->_converged($converged);
    my $reEpsL=PDL->pdl([map {$_->re} @eps]);
    my $imEpsL=PDL->pdl([map {$_->im} @eps]);
    my ($lu, $perm, $parity)=@{$self->geometry->unitDyadsLU};
    my $reEps=lu_backsub($lu, $perm, $parity, $reEpsL);
    my $imEps=lu_backsub($lu, $perm, $parity, $imEpsL);
    my $nd=$self->geometry->B->ndims;
    my $epsTensor=PDL->zeroes(2, $nd, $nd)->complex;
    my $n=0;
    for my $i(0..$nd-1){
	for my $j($i..$nd-1){
	    $epsTensor->(:,($i),($j)).=$reEps->($n)+i*$imEps->($n);
	    $epsTensor->(:,($j),($i)).=$reEps->($n)+i*$imEps->($n);
	    ++$n;
	}
    }
    $self->_epsTensor($epsTensor);
    return $epsTensor;
}

sub _build_nr { # One Haydock coefficients calculator per direction0
    my $self=shift;
    my @nr;
    foreach(@{$self->geometry->unitPairs}){
	my $g=dclone($self->geometry); #clone geometry
	$g->Direction0($_); #add G0 direction
	#Build a corresponding LE::NR2::AllH structure
	my $nr=Photonic::LE::NR2::AllH->new(
	    geometry=>$g, smallH=>$self->smallH,
	    nh=>$self->nh, keepStates=>$self->keepStates,
	    reorthogonalize=>$self->reorthogonalize,
	    use_mask=>$self->use_mask,
	    mask=>$self->mask);
	push @nr, $nr;
    }
    return [@nr]
}

sub _build_epsL {
    my $self=shift;
    my @eps;
    foreach(@{$self->nr}){
	my $e=Photonic::LE::NR2::EpsL->
	    new(nr=>$_, nh=>$self->nh, smallE=>$self->smallE);
	push @eps, $e;
    }
    return [@eps]
}


__PACKAGE__->meta->make_immutable;

1;

__END__
