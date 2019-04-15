
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::AIRY;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_airy_Ai PDLA::PP gsl_sf_airy_Bi PDLA::PP gsl_sf_airy_Ai_scaled PDLA::PP gsl_sf_airy_Bi_scaled PDLA::PP gsl_sf_airy_Ai_deriv PDLA::PP gsl_sf_airy_Bi_deriv PDLA::PP gsl_sf_airy_Ai_deriv_scaled PDLA::PP gsl_sf_airy_Bi_deriv_scaled );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::AIRY ;




=head1 NAME

PDLA::GSLSF::AIRY - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_airy_Ai

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Airy Function Ai(x).

=for bad

gsl_sf_airy_Ai does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Ai = \&PDLA::gsl_sf_airy_Ai;





=head2 gsl_sf_airy_Bi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Airy Function Bi(x).

=for bad

gsl_sf_airy_Bi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Bi = \&PDLA::gsl_sf_airy_Bi;





=head2 gsl_sf_airy_Ai_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Scaled Airy Function Ai(x). Ai(x) for x < 0  and exp(+2/3 x^{3/2}) Ai(x) for  x > 0.

=for bad

gsl_sf_airy_Ai_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Ai_scaled = \&PDLA::gsl_sf_airy_Ai_scaled;





=head2 gsl_sf_airy_Bi_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Scaled Airy Function Bi(x). Bi(x) for x < 0  and exp(+2/3 x^{3/2}) Bi(x) for  x > 0.

=for bad

gsl_sf_airy_Bi_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Bi_scaled = \&PDLA::gsl_sf_airy_Bi_scaled;





=head2 gsl_sf_airy_Ai_deriv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Airy Function Ai`(x).

=for bad

gsl_sf_airy_Ai_deriv does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Ai_deriv = \&PDLA::gsl_sf_airy_Ai_deriv;





=head2 gsl_sf_airy_Bi_deriv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Airy Function Bi`(x).

=for bad

gsl_sf_airy_Bi_deriv does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Bi_deriv = \&PDLA::gsl_sf_airy_Bi_deriv;





=head2 gsl_sf_airy_Ai_deriv_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Scaled Airy Function Ai(x). Ai`(x) for x < 0  and exp(+2/3 x^{3/2}) Ai`(x) for  x > 0.

=for bad

gsl_sf_airy_Ai_deriv_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Ai_deriv_scaled = \&PDLA::gsl_sf_airy_Ai_deriv_scaled;





=head2 gsl_sf_airy_Bi_deriv_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Scaled Airy Function Bi(x). Bi`(x) for x < 0  and exp(+2/3 x^{3/2}) Bi`(x) for  x > 0.

=for bad

gsl_sf_airy_Bi_deriv_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_airy_Bi_deriv_scaled = \&PDLA::gsl_sf_airy_Bi_deriv_scaled;



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

		   