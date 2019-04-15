
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::ERF;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_erfc PDLA::PP gsl_sf_log_erfc PDLA::PP gsl_sf_erf PDLA::PP gsl_sf_erf_Z PDLA::PP gsl_sf_erf_Q );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::ERF ;




=head1 NAME

PDLA::GSLSF::ERF - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_erfc

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complementary Error Function erfc(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,x,Infinity}]

=for bad

gsl_sf_erfc does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_erfc = \&PDLA::gsl_sf_erfc;





=head2 gsl_sf_log_erfc

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log Complementary Error Function

=for bad

gsl_sf_log_erfc does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_log_erfc = \&PDLA::gsl_sf_log_erfc;





=head2 gsl_sf_erf

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Error Function erf(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,0,x}]

=for bad

gsl_sf_erf does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_erf = \&PDLA::gsl_sf_erf;





=head2 gsl_sf_erf_Z

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Z(x) :  Abramowitz+Stegun 26.2.1

=for bad

gsl_sf_erf_Z does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_erf_Z = \&PDLA::gsl_sf_erf_Z;





=head2 gsl_sf_erf_Q

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Q(x) :  Abramowitz+Stegun 26.2.1

=for bad

gsl_sf_erf_Q does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_erf_Q = \&PDLA::gsl_sf_erf_Q;



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

		   