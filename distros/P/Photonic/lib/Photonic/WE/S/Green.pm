package Photonic::WE::S::Green;
$Photonic::WE::S::Green::VERSION = '0.011';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::Green

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

   use Photonic::WE::S::Green;
   my $G=Photonic::WE::S::Green->new(metric=>$m, nh=>$nh);
   my $GreenTensor=$G->evaluate($epsB);

=head1 DESCRIPTION

Calculates the retarded green's tensor for a given fixed
Photonic::WE::S::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallH=>$smallH, smallE=>$smallE,
keepStates=>$k)

Initializes the structure.

$m Photonic::WE::S::Metric describing the structure and some parametres.

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

Array of Photonic::WE::S::AllH structures, one for each polarization

=item * greenP

Array of Photonic::WE::S::GreenP structures, one for each direction.

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

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
use Photonic::WE::S::AllH;
use Photonic::WE::S::GreenP;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'metric'=>(is=>'ro', isa => 'Photonic::WE::S::Metric',
       handles=>[qw(geometry ndims dims)],required=>1);

has 'haydock' =>(is=>'ro', isa=>'ArrayRef[Photonic::WE::S::AllH]',
            init_arg=>undef, lazy=>1, builder=>'_build_haydock',
	    documentation=>'Array of Haydock calculators');
has 'greenP'=>(is=>'ro', isa=>'ArrayRef[Photonic::WE::S::GreenP]',
             init_arg=>undef, lazy=>1, builder=>'_build_greenP',
             documentation=>'Array of projected G calculators');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All greenP evaluations converged');
has 'greenTensor'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
	      lazy=>1, builder=>'_build_greenTensor',
             documentation=>'Greens Tensor');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
with 'Photonic::Roles::KeepStates', 'Photonic::Roles::UseMask';

sub _build_greenTensor {
    my $self=shift;
    my @greenP; #array of Green's projections along different directions.
    my $converged=1;
    foreach(@{$self->greenP}){
	push @greenP, $_->Gpp;
	$converged &&=$_->converged;
    }
    $self->_converged($converged);
    my $reGreenP=PDL->pdl([map {$_->re} @greenP]);
    my $imGreenP=PDL->pdl([map {$_->im} @greenP]);
    my ($lu, $perm, $parity)=@{$self->geometry->unitDyadsLU};
    my $reGreen=lu_backsub($lu, $perm, $parity, $reGreenP);
    my $imGreen=lu_backsub($lu, $perm, $parity, $imGreenP);
    my $nd=$self->geometry->ndims;
    my $greenTensor=PDL->zeroes(2, $nd, $nd)->complex;
    my $n=0;
    for my $i(0..$nd-1){
	for my $j($i..$nd-1){
	    $greenTensor->(:,($i),($j)).=$reGreen->($n)+i*$imGreen->($n);
	    $greenTensor->(:,($j),($i)).=$reGreen->($n)+i*$imGreen->($n);
	    ++$n;
	}
    }
    return $greenTensor;
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my $self=shift;
    my @haydock;
    # This must change if G is not symmetric
    foreach(@{$self->geometry->unitPairs}){
	my $m=dclone($self->metric); #clone metric, to be safe
	my $e=$_->r2C; #polarization
	#Build a corresponding Photonic::WE::S::AllH structure
	my $haydock=Photonic::WE::S::AllH->new(
	    metric=>$m, polarization=>$e, nh=>$self->nh,
	    keepStates=>$self->keepStates, smallH=>$self->smallH,
	    reorthogonalize=>$self->reorthogonalize,
	    use_mask=>$self->use_mask,
	    mask=>$self->mask);
	push @haydock, $haydock;
    }
    return [@haydock]
}

sub _build_greenP {
    my $self=shift;
    my @greenP;
    foreach(@{$self->haydock}){
	my $g=Photonic::WE::S::GreenP->new(
	    haydock=>$_, nh=>$self->nh, smallE=>$self->smallE);
	push @greenP, $g;
    }
    return [@greenP]
}

__PACKAGE__->meta->make_immutable;

1;

__END__
