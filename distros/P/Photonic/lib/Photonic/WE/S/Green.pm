package Photonic::WE::S::Green;
$Photonic::WE::S::Green::VERSION = '0.021';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::Green

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

Array of Photonic::WE::S::Haydock structures, one for each polarization

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
use Photonic::WE::S::Haydock;
use Photonic::WE::S::GreenP;
use Photonic::Types;
use Photonic::Utils qw(tensor make_haydock make_greenp);
use List::Util qw(all);
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

has 'haydock' =>(is=>'ro', isa=>'ArrayRef[Photonic::WE::S::Haydock]',
            init_arg=>undef, lazy=>1, builder=>'_build_haydock',
	    documentation=>'Array of Haydock calculators');
has 'greenP'=>(is=>'ro', isa=>'ArrayRef[Photonic::WE::S::GreenP]',
             init_arg=>undef, lazy=>1, builder=>'_build_greenP',
             documentation=>'Array of projected G calculators');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All greenP evaluations converged');
has 'greenTensor'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
	      lazy=>1, builder=>'_build_greenTensor',
             documentation=>'Greens Tensor');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
with 'Photonic::Roles::KeepStates', 'Photonic::Roles::UseMask';

sub _build_greenTensor {
    my $self=shift;
    $self->_converged(all { $_->converged } @{$self->greenP});
    tensor(pdl([map $_->Gpp, @{$self->greenP}]), $self->geometry->unitDyadsLU, $self->geometry->ndims, 2);
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my ($self) = @_;
    make_haydock($self, 'Photonic::WE::S::Haydock', $self->geometry->unitPairs, 0, qw(reorthogonalize use_mask mask));
}

sub _build_greenP {
    make_greenp(shift, 'Photonic::WE::S::GreenP');
}

__PACKAGE__->meta->make_immutable;

1;

__END__
