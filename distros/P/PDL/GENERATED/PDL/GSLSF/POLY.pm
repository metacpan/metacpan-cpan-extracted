#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::POLY;

our @EXPORT_OK = qw(gsl_poly_eval );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::POLY ;







#line 4 "gsl_sf_poly.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::POLY - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

NOTE: this should actually be PDL::POLY for consistency but I don't want to get into edits
changing the directory structure at this time.  These fixes should allow things to build.

=cut
#line 43 "POLY.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_poly_eval

=for sig

  Signature: (double x(); double c(m); double [o]y())

=for ref

c[0] + c[1] x + c[2] x^2 + ... + c[m-1] x^(m-1)

=for bad

gsl_poly_eval does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_poly_eval = \&PDL::gsl_poly_eval;







#line 41 "gsl_sf_poly.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 97 "POLY.pm"

# Exit with OK status

1;
