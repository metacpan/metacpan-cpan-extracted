package Photonic::WE::R2::GreenS;
$Photonic::WE::R2::GreenS::VERSION = '0.018';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::GreenS

=head1 VERSION

version 0.018

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

   use Photonic::WE::R2::GreenS;
   my $G=Photonic::WE::R2::GreenS->new(metric=>$m, nh=>$nh);
   my $GreenTensor=$G->evaluate($epsB);

=head1 DESCRIPTION

Calculates the retarded green's tensor for a given fixed
Photonic::WE::R2::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallH=>$smallH, smallE=>$smallE,
keepStates=>$k)

Initializes the structure.

$m Photonic::WE::R2::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and continued fraction

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic Green's operator for a given value of the
dielectric functions of the particle $epsB. The host's
response $epsA is taken from the metric. It is assumed the tensor is
symmetric.

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
use Photonic::WE::R2::AllH;
use Photonic::WE::R2::GreenP;
use Photonic::Types;
use Photonic::Utils qw(tensor make_haydock make_greenp);
use List::Util qw(all);
use Moose;
use MooseX::StrictConstructor;

has 'metric'=>(is=>'ro', isa => 'Photonic::WE::R2::Metric',
       handles=>[qw(geometry B dims ndims r G GNorm L scale f)],required=>1);
has 'haydock' =>(is=>'ro', isa=>'ArrayRef[Photonic::WE::R2::AllH]',
            init_arg=>undef, lazy=>1, builder=>'_build_haydock',
	    documentation=>'Array of Haydock calculators');
has 'greenP'=>(is=>'ro', isa=>'ArrayRef[Photonic::WE::R2::GreenP]',
             init_arg=>undef, lazy=>1, builder=>'_build_greenP',
             documentation=>'Array of projected G calculators');
has 'greenTensor'=>(is=>'ro', isa=>'PDL', init_arg=>undef,
             writer=>'_greenTensor',
             documentation=>"Green's Tensor from last evaluation");
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All greenP evaluations converged in last evaluation');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

with 'Photonic::Roles::KeepStates',  'Photonic::Roles::UseMask';

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=$self->metric->epsilon->r2C);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    $self->_converged(all { $_->converged } @{$self->greenP});
    my $greenTensor = tensor(pdl([map $_->evaluate($epsB), @{$self->greenP}]), $self->geometry->unitDyadsLU, $self->geometry->ndims, 2);
    $self->_greenTensor($greenTensor);
    $greenTensor;
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my ($self) = @_;
    make_haydock($self, 'Photonic::WE::R2::AllH', $self->geometry->unitPairs, 0, qw(reorthogonalize use_mask mask));
}

sub _build_greenP {
    make_greenp(shift, 'Photonic::WE::R2::GreenP');
}

__PACKAGE__->meta->make_immutable;

1;

__END__
