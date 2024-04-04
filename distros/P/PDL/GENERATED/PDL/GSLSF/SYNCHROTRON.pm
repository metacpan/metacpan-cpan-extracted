#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::SYNCHROTRON;

our @EXPORT_OK = qw(gsl_sf_synchrotron_1 gsl_sf_synchrotron_2 );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::SYNCHROTRON ;







#line 4 "gsl_sf_synchrotron.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::SYNCHROTRON - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "SYNCHROTRON.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_synchrotron_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

First synchrotron function: synchrotron_1(x) = x Integral[ K_{5/3}(t), {t, x, Infinity}]

=for bad

gsl_sf_synchrotron_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_1 = \&PDL::gsl_sf_synchrotron_1;






=head2 gsl_sf_synchrotron_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Second synchroton function: synchrotron_2(x) = x * K_{2/3}(x)

=for bad

gsl_sf_synchrotron_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_2 = \&PDL::gsl_sf_synchrotron_2;







#line 50 "gsl_sf_synchrotron.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 121 "SYNCHROTRON.pm"

# Exit with OK status

1;
