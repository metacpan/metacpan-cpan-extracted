#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::LAGUERRE;

our @EXPORT_OK = qw(gsl_sf_laguerre_n );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::LAGUERRE ;







#line 4 "gsl_sf_laguerre.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::LAGUERRE - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "LAGUERRE.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_laguerre_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; double a)

=for ref

Evaluate generalized Laguerre polynomials.

=for bad

gsl_sf_laguerre_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_laguerre_n = \&PDL::gsl_sf_laguerre_n;







#line 39 "gsl_sf_laguerre.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 94 "LAGUERRE.pm"

# Exit with OK status

1;
