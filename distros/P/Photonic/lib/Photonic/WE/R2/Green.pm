package Photonic::WE::R2::Green;
$Photonic::WE::R2::Green::VERSION = '0.017';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::Green

=head1 VERSION

version 0.017

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

   use Photonic::WE::R2::Green;
   my $G=Photonic::WE::R2::Green->new(metric=>$m, nh=>$nh);
   my $GreenTensor=$G->evaluate($epsB);

=head1 DESCRIPTION

Calculates the retarded green's tensor for a given fixed
Photonic::WE::R2::Metric structure as a function of the dielectric
functions of the components. Includes the antysimmetric part, unless
it is not desired.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallH=>$smallH, smallE=>$smallE, symmetric=>$s, keepStates=>$k)

Initializes the structure.

$m Photonic::WE::R2::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and continued fraction

$s flags that you only want the symmetric part of the Green's tensor

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic Green's operator for a given value of the
dielectric functions of the particle $epsB. The host's
response $epsA is taken from the metric.

=back

=head1 ACCESSORS (read only)

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

Array of Photonic::WE::R2::AllH structures, one for each polarization

=item * greenP

Array of Photonic::WE::R2::GreenP structures, one for each direction.

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
use Photonic::WE::R2::AllH;
use Photonic::WE::R2::GreenP;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;
use Photonic::Utils qw(make_haydock);
use List::Util qw(any);

extends 'Photonic::WE::R2::GreenS';

has 'cHaydock' =>(
    is=>'ro', isa=>'ArrayRef[Photonic::WE::R2::AllH]',
    init_arg=>undef, lazy=>1, builder=>'_build_cHaydock',
    documentation=>'Array of Haydock calculators for complex projection');

has 'cGreenP'=>(
    is=>'ro', isa=>'ArrayRef[Photonic::WE::R2::GreenP]',
    init_arg=>undef, lazy=>1, builder=>'_build_cGreenP',
    documentation=>'Array of projected G calculators for complex projection');

has 'symmetric' => (
    is=>'ro', required=>1, default=>0,
    documentation=>'Flags only symmetric part required');

around 'evaluate' => sub {
    my $orig=shift;
    my $self=shift;
    my $epsB=shift;
    my $sym=$self->$orig($epsB);
    #That's all unless you want the antisymmetric part
    return $sym if $self->symmetric;
    my @greenPc = map $_->evaluate($epsB), @{$self->cGreenP}; ; #array of Green's projections along complex directions.
    $self->_converged(any { $_->converged } $self, @{$self->cGreenP});
    my $nd=$self->geometry->B->ndims;
    my $asy=$sym->zeroes; #xy,xy, $ndx$nd
    my $cpairs=$self->geometry->cUnitPairs;
    my $m=0;
    for my $i(0..$nd-2){
	for my $j($i+1..$nd-1){
	    my $pair=$cpairs->(:,($m));
	    #$asy is xy,xy. First index is column
	    $asy(($i), ($j)).=PDL->i()*(
		$greenPc[$m]-
		($pair->conj->(*1) # column, row
		 *$pair->(:,*1)
		 *$sym)->sumover->sumover
		);
	    $asy(($j), ($i)).=-$asy(($i),($j));
	    $m++
	}
     }
    #print $asy, "\n";
    my $greenTensor= $sym+$asy;
    $self->_greenTensor($greenTensor);
    return $greenTensor;
};


sub _build_cHaydock {
    # One Haydock coefficients calculator per complex polarization
    my $self=shift;
    make_haydock($self, 'Photonic::WE::R2::AllH', $self->geometry->cUnitPairs, 0);
}

sub _build_cGreenP {
    my $self=shift;
    [ map Photonic::WE::R2::GreenP->new(haydock=>$_, nh=>$self->nh, smallE=>$self->smallE), @{$self->cHaydock} ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__
