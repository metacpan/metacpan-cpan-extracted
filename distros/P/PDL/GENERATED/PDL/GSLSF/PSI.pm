#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::PSI;

our @EXPORT_OK = qw(gsl_sf_psi gsl_sf_psi_1piy gsl_sf_psi_n );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::PSI ;







#line 4 "gsl_sf_psi.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::PSI - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

Poly-Gamma Functions

  psi(m,x) := (d/dx)^m psi(0,x) = (d/dx)^{m+1} log(gamma(x))

=cut
#line 44 "PSI.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_psi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Di-Gamma Function psi(x).

=for bad

gsl_sf_psi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi = \&PDL::gsl_sf_psi;






=head2 gsl_sf_psi_1piy

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Di-Gamma Function Re[psi(1 + I y)]

=for bad

gsl_sf_psi_1piy does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_1piy = \&PDL::gsl_sf_psi_1piy;






=head2 gsl_sf_psi_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Poly-Gamma Function psi^(n)(x)

=for bad

gsl_sf_psi_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_n = \&PDL::gsl_sf_psi_n;







#line 69 "gsl_sf_psi.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 152 "PSI.pm"

# Exit with OK status

1;
