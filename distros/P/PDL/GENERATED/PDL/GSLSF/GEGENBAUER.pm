#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::GEGENBAUER;

our @EXPORT_OK = qw(gsl_sf_gegenpoly_n gsl_sf_gegenpoly_array );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::GEGENBAUER ;







#line 4 "gsl_sf_gegenbauer.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::GEGENBAUER - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "GEGENBAUER.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_gegenpoly_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; double lambda)

=for ref

Evaluate Gegenbauer polynomials.

=for bad

gsl_sf_gegenpoly_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_n = \&PDL::gsl_sf_gegenpoly_n;






=head2 gsl_sf_gegenpoly_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num; double lambda)

=for ref

Calculate array of Gegenbauer polynomials from 0 to n-1.

=for bad

gsl_sf_gegenpoly_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_array = \&PDL::gsl_sf_gegenpoly_array;







#line 49 "gsl_sf_gegenbauer.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 121 "GEGENBAUER.pm"

# Exit with OK status

1;
