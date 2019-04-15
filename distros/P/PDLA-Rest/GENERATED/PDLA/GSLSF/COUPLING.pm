
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::COUPLING;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_coupling_3j PDLA::PP gsl_sf_coupling_6j PDLA::PP gsl_sf_coupling_9j );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::COUPLING ;




=head1 NAME

PDLA::GSLSF::COUPLING - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_coupling_3j

=for sig

  Signature: (ja(); jb(); jc(); ma(); mb(); mc(); double [o]y(); double [o]e())

=for ref

3j Symbols:  (ja jb jc) over (ma mb mc).

=for bad

gsl_sf_coupling_3j does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coupling_3j = \&PDLA::gsl_sf_coupling_3j;





=head2 gsl_sf_coupling_6j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); double [o]y(); double [o]e())

=for ref

6j Symbols:  (ja jb jc) over (jd je jf).

=for bad

gsl_sf_coupling_6j does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coupling_6j = \&PDLA::gsl_sf_coupling_6j;





=head2 gsl_sf_coupling_9j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); jg(); jh(); ji(); double [o]y(); double [o]e())

=for ref

9j Symbols:  (ja jb jc) over (jd je jf) over (jg jh ji).

=for bad

gsl_sf_coupling_9j does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coupling_9j = \&PDLA::gsl_sf_coupling_9j;



;

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDLA distribution. If this file is separated from the
PDLA distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut






# Exit with OK status

1;

		   