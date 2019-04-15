
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::EXP;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_exp PDLA::PP gsl_sf_exprel_n PDLA::PP gsl_sf_exp_err );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::EXP ;




=head1 NAME

PDLA::GSLSF::EXP - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_exp

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Exponential

=for bad

gsl_sf_exp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_exp = \&PDLA::gsl_sf_exp;





=head2 gsl_sf_exprel_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

N-relative Exponential. exprel_N(x) = N!/x^N (exp(x) - Sum[x^k/k!, {k,0,N-1}]) = 1 + x/(N+1) + x^2/((N+1)(N+2)) + ... = 1F1(1,1+N,x)

=for bad

gsl_sf_exprel_n does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_exprel_n = \&PDLA::gsl_sf_exprel_n;





=head2 gsl_sf_exp_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Exponential of a quantity with given error.

=for bad

gsl_sf_exp_err does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_exp_err = \&PDLA::gsl_sf_exp_err;



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

		   