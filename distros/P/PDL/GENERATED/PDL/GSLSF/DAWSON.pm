#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::DAWSON;

our @EXPORT_OK = qw(gsl_sf_dawson );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::DAWSON ;







#line 4 "gsl_sf_dawson.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::DAWSON - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut
#line 42 "DAWSON.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_dawson

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Dawsons integral: Exp[-x^2] Integral[ Exp[t^2], {t,0,x}]

=for bad

gsl_sf_dawson does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_dawson = \&PDL::gsl_sf_dawson;







#line 42 "gsl_sf_dawson.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 96 "DAWSON.pm"

# Exit with OK status

1;
