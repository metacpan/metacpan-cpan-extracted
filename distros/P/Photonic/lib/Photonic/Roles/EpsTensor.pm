package Photonic::Roles::EpsTensor;
$Photonic::Roles::EpsTensor::VERSION = '0.021';

=encoding UTF-8

=head1 NAME

Photonic::Roles::EpsTensor

=head1 VERSION

version 0.021

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

   use Photonic::LE::S::EpsTensor;
   my $eps=Photonic::LE::S::EpsTensor->new(
                     epsilon=>$e, geometry=>$g);
   my $epsilonTensor=$eps->epsTensor;

=over 4

=item (for developers)

    package Photonic::LE::S::EpsTensor;
    $Photonic::LE::S::EpsTensor::VERSION= '0.021';
    use namespace::autoclean;
    use Moose;
    with 'Photonic::Roles::EpsTensor';
    has...

=back

=head1 DESCRIPTION

Role for classes that calculate the macroscopic dielectric tensor for a
given fixed Photonic::Geometry structure as a function of the dielectric
functions of the components.

The consuming class needs to supply these methods to inform lazy-building
of C<haydock> and C<epsL>:

=over 4

=item * allh_class

=item * allh_attrs

=item * epsl_class

=item * epsl_attrs

=back

=head1 ATTRIBUTES

=over 4

=item * geometry

L<Photonic::Geometry> describing the structure

=item * nh

Maximum number of Haydock coefficients to use.

=item * smallH and smallE

Criteria of convergence (default 1e-7) for the Haydock coefficients and
the tensor calculations.
0 means don't check.
    *Check last remark*

=item * keepStates

Flag to keep states in Haydock calculations (default 0)

=item * haydock

Array of L<Photonic::Role::Haydock> structures, one for each direction
(lazy-built from geometry if not given). Since this is expensive, once
calculated you are encouraged to use the accessor to pass the value to
construct other C<EpsTensor> with different epsilon.

=item * epsL

Array of L<Photonic::Role::EpsL> structures, one for each direction
(lazy-built if not given).

=item * epsTensor

The macroscopic dielectric function for a given value of the
dielectric functions of the host epsA and the particle epsB, calculated
from previous two parameters.

=item * nh

The maximum number of Haydock coefficients to use.

=item * converged

Flags that the last calculation converged before using up all coefficients

=back

=begin Pod::Coverage

=head2 dims

=head2 ndims

=end Pod::Coverage

=cut

use Moose::Role;
use namespace::autoclean;
use PDL::Lite;
use Photonic::Utils qw(tensor make_haydock incarnate_as);
use List::Util qw(all);
use Photonic::Types;

requires qw(allh_class allh_attrs epsl_class epsl_attrs);

sub dims; # Forward declarations to allow some role compositions
sub ndims; # recommended by Moose::Manual::Roles
sub geometry;

has 'geometry'=>(is=>'ro', isa => 'Photonic::Types::Geometry',
    handles=>[qw(B ndims dims r G GNorm L scale f)],required=>1
);
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
has 'haydock' =>(is=>'ro', isa=>'ArrayRef[Photonic::Roles::Haydock]',
            lazy=>1, builder=>'_build_haydock',
            documentation=>'Array of Haydock calculators');
has 'epsL'=>(is=>'ro', isa=>'ArrayRef[Photonic::Roles::EpsL]',
             init_arg=>undef, lazy=>1, builder=>'_build_epsL',
             documentation=>'Array of epsilon calculators');
has 'epsTensor'=>(is=>'ro', isa=>'PDL', lazy=>1, builder=>'_build_epsTensor',
             documentation=>'Dielectric Tensor');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All EpsL evaluations converged in last evaluation');
has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
            documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
            documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
            documentation=>'Convergence criterium for use of Haydock coeff.');

sub _build_epsTensor {
    my $self=shift;
    my @epsLs = map $_->epsL, my @objs = @{$self->epsL};
    $self->_converged(all { $_->converged } @objs);
    tensor(pdl(\@epsLs), $self->geometry->unitDyadsLU, $self->geometry->B->ndims, 2);
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my $self=shift;
    make_haydock($self, $self->allh_class, $self->geometry->unitPairs, 1, @{$self->allh_attrs});
}

sub _build_epsL {
    my $self=shift;
    [ map incarnate_as($self->epsl_class, $self, $self->epsl_attrs, haydock=>$_), @{$self->haydock} ];
}

no Moose::Role;

1;
