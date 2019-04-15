
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::TRANSPORT;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_transport_2 PDLA::PP gsl_sf_transport_3 PDLA::PP gsl_sf_transport_4 PDLA::PP gsl_sf_transport_5 );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::TRANSPORT ;




=head1 NAME

PDLA::GSLSF::TRANSPORT - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 


Transport function:
  J(n,x) := Integral[ t^n e^t /(e^t - 1)^2, {t,0,x}]

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_transport_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(2,x)

=for bad

gsl_sf_transport_2 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_transport_2 = \&PDLA::gsl_sf_transport_2;





=head2 gsl_sf_transport_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(3,x)

=for bad

gsl_sf_transport_3 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_transport_3 = \&PDLA::gsl_sf_transport_3;





=head2 gsl_sf_transport_4

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(4,x)

=for bad

gsl_sf_transport_4 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_transport_4 = \&PDLA::gsl_sf_transport_4;





=head2 gsl_sf_transport_5

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(5,x)

=for bad

gsl_sf_transport_5 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_transport_5 = \&PDLA::gsl_sf_transport_5;



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

		   