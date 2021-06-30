package Photonic::Roles::EpsL;
$Photonic::Roles::EpsL::VERSION = '0.017';

=encoding UTF-8

=head1 NAME

Photonic::Roles::EpsL

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

   use Photonic::LE::NR2::EpsL;
   my $eps=Photonic::LE::NR2::EpsL->new(nr=>$nr, nh=>$nh);
   my $epsilonLongitudinal=$eps->evaluate($epsA, $epsB);

=over 4

=item (for developers)

    package Photonic::LE::NR2::EpsL;
    $Photonic::LE::NR2::EpsL::VERSION= '0.017';
    use namespace::autoclean;
    use Moose;
    with 'Photonic::Roles::EpsL';
    has...

=back

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a
given fixed Photonic::...::AllH structure as a function of the
dielectric functions of the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr is a Photonic::...::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence for the continued fraction
(defaults to 1e-7)

=item * evaluate($epsA, $epsB)

Returns the macroscopic dielectric function for a given value of the
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESSORS (read only)

=over 4

=item * nr

The ...::AllH structure

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

=item * epsL

The longitudinal macroscopic function obtained in the last calculation.

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence for continued fraction. 0 means don't
check.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use Moose::Role;
use Photonic::Types;

has 'nr' =>(is=>'ro', isa=>'Photonic::Types::AllH', required=>1);
has 'nh' =>(is=>'ro', isa=>'Num', required=>1, lazy=>1, builder=>'_nh',
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsL'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
	     writer=>'_epsL',
	     documentation=>'Value of dielectric function'  );
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
		 writer=>'_nhActual',
		 documentation=>'Actual number of coefficients used' );
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef,
		  writer=>'_converged',
		  documentation=>'The calculation did converge');

sub BUILD {
    my $self=shift;
    $self->nr->run unless $self->nr->iteration;
}

sub _nh { #build desired number of Haydock coeffs to use.
    my $self=shift;
    return $self->nr->nh; #defaults to coefficients desired
}

no Moose::Role;

1;
