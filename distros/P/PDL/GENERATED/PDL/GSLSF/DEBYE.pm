#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::DEBYE;

our @EXPORT_OK = qw(gsl_sf_debye_1 gsl_sf_debye_2 gsl_sf_debye_3 gsl_sf_debye_4 );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::DEBYE ;







#line 4 "gsl_sf_debye.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::DEBYE - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "DEBYE.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_debye_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_1 = \&PDL::gsl_sf_debye_1;






=head2 gsl_sf_debye_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_2 = \&PDL::gsl_sf_debye_2;






=head2 gsl_sf_debye_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_3 = \&PDL::gsl_sf_debye_3;






=head2 gsl_sf_debye_4

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_4 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_4 = \&PDL::gsl_sf_debye_4;







#line 74 "gsl_sf_debye.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 175 "DEBYE.pm"

# Exit with OK status

1;
