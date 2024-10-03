package Photonic::Roles::EpsL;
$Photonic::Roles::EpsL::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::Roles::EpsL

=head1 VERSION

version 0.023

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
   my $eps=Photonic::LE::NR2::EpsL->new(haydock=>$haydock, nh=>$nh, epsA=>$eA, epsB=>$eb);
   my $epsilonLongitudinal=$eps->epsL;

=over 4

=item (for developers)

    package Photonic::LE::NR2::EpsL;
    $Photonic::LE::NR2::EpsL::VERSION= '0.023';
    use namespace::autoclean;
    use Moo;
    with 'Photonic::Roles::EpsL';
    has...

=back

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a
given fixed Photonic::...::Haydock structure as a function of the
dielectric functions of the components.

The consuming class needs to supply these methods to inform lazy-building
of C<epsL>:

=over 4

=item * _build_epsL

=back

=head1 ATTRIBUTES

=over 4

=item * haydock

The ...::Haydock structure

=item * epsL

The longitudinal macroscopic function calculated from the parameters (lazy-built).

=item * nh

The maximum number of Haydock coefficients to use (required).

=item * nhActual

The actual number of Haydock coefficients used in the calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence for continued fraction. 0 means don't
check.
(defaults to 1e-7)

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use Moo::Role;
use Photonic::Types -all;

requires '_build_epsL';

has 'haydock' =>(is=>'ro', isa=>Haydock, required=>1);
has 'nh' =>(is=>'lazy', isa=>Num, required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsL'=>(is=>'lazy', isa=>PDLComplex,
	     documentation=>'Value of dielectric function'  );
has 'nhActual'=>(is=>'ro', isa=>Num, init_arg=>undef,
		 writer=>'_nhActual',
		 documentation=>'Actual number of coefficients used' );
has 'converged'=>(is=>'ro', isa=>Num, init_arg=>undef,
		  writer=>'_converged',
		  documentation=>'The calculation did converge');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_nh { #build desired number of Haydock coeffs to use.
    my $self=shift;
    return $self->haydock->nh; #defaults to coefficients desired
}

no Moo::Role;

1;
