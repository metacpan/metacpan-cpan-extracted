#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::ELEMENTARY;

our @EXPORT_OK = qw(gsl_sf_multiply gsl_sf_multiply_err );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::ELEMENTARY ;







#line 4 "gsl_sf_elementary.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::ELEMENTARY - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "ELEMENTARY.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_multiply

=for sig

  Signature: (double x(); double xx(); double [o]y(); double [o]e())

=for ref

Multiplication.

=for bad

gsl_sf_multiply does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply = \&PDL::gsl_sf_multiply;






=head2 gsl_sf_multiply_err

=for sig

  Signature: (double x(); double xe(); double xx(); double xxe(); double [o]y(); double [o]e())

=for ref

Multiplication with associated errors.

=for bad

gsl_sf_multiply_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply_err = \&PDL::gsl_sf_multiply_err;







#line 51 "gsl_sf_elementary.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 121 "ELEMENTARY.pm"

# Exit with OK status

1;
