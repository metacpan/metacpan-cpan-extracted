
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::POW_INT;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_pow_int );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::POW_INT ;




=head1 NAME

PDLA::GSLSF::POW_INT - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_pow_int

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Calculate x^n.

=for bad

gsl_sf_pow_int does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_pow_int = \&PDLA::gsl_sf_pow_int;



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

		   