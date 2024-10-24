
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::LOG;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_log PDLA::PP gsl_sf_complex_log );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::LOG ;




=head1 NAME

PDLA::GSLSF::LOG - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_log

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Provide a logarithm function with GSL semantics.

=for bad

gsl_sf_log does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_log = \&PDLA::gsl_sf_log;





=head2 gsl_sf_complex_log

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Complex Logarithm exp(lnr + I theta) = zr + I zi Returns argument in [-pi,pi].

=for bad

gsl_sf_complex_log does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_complex_log = \&PDLA::gsl_sf_complex_log;



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

		   