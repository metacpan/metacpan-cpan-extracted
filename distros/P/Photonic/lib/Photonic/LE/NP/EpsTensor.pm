package Photonic::LE::NP::EpsTensor;
$Photonic::LE::NP::EpsTensor::VERSION = '0.018';

=encoding UTF-8

=head1 NAME

Photonic::LE::NP::EpsTensor

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

=head1 VERSION

version 0.018

=head1 SYNOPSIS

   use Photonic::LE::NP::EpsTensor;
   my $eps=Photonic::LE::NP::EpsTensor->new(
                     epsilon=>$e, geometry=>$g);
   my $epsilonTensor=$epsTensor;

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor for a given fixed
Photonic::Geometry structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(epsilon=>$e, geometry=>$g, nh=>$nh, smallH=>$smallH,
            smallE=>$smallE, keepStates=>$k)

Initializes the structure.

$e complex PDL is the dielectric function as a complex scalar field

$g Photonic::Geometry describing the structure

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
the Haydock coefficients and the tensor calculations.

$k is a flag to keep states in Haydock calculations (default 0)

=back

=head1 ACCESSORS (read only)

=over 4

=item * epsilon

A complex PDL giving the value of the dielectric function epsilon
for each pixel of the system

=item * keepStates

Value of flag to keep Haydock states

=item * nr

Array of Photonic::LE::NP::AllH structures, one for each direction

=item * epsL

Array of Photonic::LE::NP::EpsL structures, one for each direction.

=item * epsTensor

The valuated dielectric tensor

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
use Photonic::Utils qw(tensor make_haydock);
use List::Util qw(all);
use Photonic::LE::NP::AllH;
use Photonic::LE::NP::EpsL;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

has 'epsilon'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', required=>1);
has 'geometry'=>(is=>'ro', isa => 'Photonic::Types::Geometry',
    handles=>[qw(B dims r G GNorm L scale f)],required=>1
);
with 'Photonic::Roles::KeepStates';

has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
has 'nr' =>(is=>'ro', isa=>'ArrayRef[Photonic::LE::NP::AllH]',
            init_arg=>undef, lazy=>1, builder=>'_build_nr',
            documentation=>'Array of Haydock calculators');
has 'epsL'=>(is=>'ro', isa=>'ArrayRef[Photonic::LE::NP::EpsL]',
             init_arg=>undef, lazy=>1, builder=>'_build_epsL',
             documentation=>'Array of epsilon calculators');
has 'epsTensor'=>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
		  builder=>'_build_epsTensor',
		  documentation=>'Dielectric Tensor');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All EpsL evaluations converged in last evaluation');

sub _build_epsTensor {
    my $self=shift;
    $self->_converged(all { $_->converged } @{$self->epsL});
    tensor(pdl([map $_->epsL, @{$self->epsL}]), $self->geometry->unitDyadsLU, $self->geometry->B->ndims, 2);
}

sub _build_nr { # One Haydock coefficients calculator per direction0
    my $self=shift;
    make_haydock($self, 'Photonic::LE::NP::AllH', $self->geometry->unitPairs, 1, qw(epsilon reorthogonalize use_mask mask));
}

sub _build_epsL {
    my $self=shift;
    [ map Photonic::LE::NP::EpsL->new(nr=>$_, nh=>$self->nh, smallE=>$self->smallE), @{$self->nr} ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__
