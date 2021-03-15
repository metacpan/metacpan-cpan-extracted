
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::HYPERG;

@EXPORT_OK  = qw( PDL::PP gsl_sf_hyperg_0F1 PDL::PP gsl_sf_hyperg_1F1 PDL::PP gsl_sf_hyperg_U PDL::PP gsl_sf_hyperg_2F1 PDL::PP gsl_sf_hyperg_2F1_conj PDL::PP gsl_sf_hyperg_2F1_renorm PDL::PP gsl_sf_hyperg_2F1_conj_renorm PDL::PP gsl_sf_hyperg_2F0 );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::HYPERG ;




=head1 NAME

PDL::GSLSF::HYPERG - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_hyperg_0F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double c)

=for ref

/* Hypergeometric function related to Bessel functions 0F1[c,x] = Gamma[c]    x^(1/2(1-c)) I_{c-1}(2 Sqrt[x]) Gamma[c] (-x)^(1/2(1-c)) J_{c-1}(2 Sqrt[-x])

=for bad

gsl_sf_hyperg_0F1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_0F1 = \&PDL::gsl_sf_hyperg_0F1;





=head2 gsl_sf_hyperg_1F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Confluent hypergeometric function  for integer parameters. 1F1[a,b,x] = M(a,b,x)

=for bad

gsl_sf_hyperg_1F1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_1F1 = \&PDL::gsl_sf_hyperg_1F1;





=head2 gsl_sf_hyperg_U

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Confluent hypergeometric function  for integer parameters. U(a,b,x)

=for bad

gsl_sf_hyperg_U does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_U = \&PDL::gsl_sf_hyperg_U;





=head2 gsl_sf_hyperg_2F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Confluent hypergeometric function  for integer parameters. 2F1[a,b,c,x]

=for bad

gsl_sf_hyperg_2F1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_2F1 = \&PDL::gsl_sf_hyperg_2F1;





=head2 gsl_sf_hyperg_2F1_conj

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x]

=for bad

gsl_sf_hyperg_2F1_conj does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_2F1_conj = \&PDL::gsl_sf_hyperg_2F1_conj;





=head2 gsl_sf_hyperg_2F1_renorm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Renormalized Gauss hypergeometric function 2F1[a,b,c,x] / Gamma[c]

=for bad

gsl_sf_hyperg_2F1_renorm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_2F1_renorm = \&PDL::gsl_sf_hyperg_2F1_renorm;





=head2 gsl_sf_hyperg_2F1_conj_renorm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Renormalized Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x] / Gamma[c]

=for bad

gsl_sf_hyperg_2F1_conj_renorm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_2F1_conj_renorm = \&PDL::gsl_sf_hyperg_2F1_conj_renorm;





=head2 gsl_sf_hyperg_2F0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Mysterious hypergeometric function. The series representation is a divergent hypergeometric series. However, for x < 0 we have 2F0(a,b,x) = (-1/x)^a U(a,1+a-b,-1/x)

=for bad

gsl_sf_hyperg_2F0 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hyperg_2F0 = \&PDL::gsl_sf_hyperg_2F0;



;


=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut






# Exit with OK status

1;

		   