#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::COUPLING;

our @EXPORT_OK = qw(gsl_sf_coupling_3j gsl_sf_coupling_6j gsl_sf_coupling_9j );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::COUPLING ;







#line 4 "gsl_sf_coupling.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::COUPLING - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "COUPLING.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_coupling_3j

=for sig

  Signature: (ja(); jb(); jc(); ma(); mb(); mc(); double [o]y(); double [o]e())

=for ref

3j Symbols:  (ja jb jc) over (ma mb mc).

=for bad

gsl_sf_coupling_3j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_3j = \&PDL::gsl_sf_coupling_3j;






=head2 gsl_sf_coupling_6j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); double [o]y(); double [o]e())

=for ref

6j Symbols:  (ja jb jc) over (jd je jf).

=for bad

gsl_sf_coupling_6j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_6j = \&PDL::gsl_sf_coupling_6j;






=head2 gsl_sf_coupling_9j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); jg(); jh(); ji(); double [o]y(); double [o]e())

=for ref

9j Symbols:  (ja jb jc) over (jd je jf) over (jg jh ji).

=for bad

gsl_sf_coupling_9j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_9j = \&PDL::gsl_sf_coupling_9j;







#line 64 "gsl_sf_coupling.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 148 "COUPLING.pm"

# Exit with OK status

1;
