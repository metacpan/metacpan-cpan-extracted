#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::GAMMA;

our @EXPORT_OK = qw(gsl_sf_lngamma gsl_sf_gamma gsl_sf_gammastar gsl_sf_gammainv gsl_sf_lngamma_complex gsl_sf_taylorcoeff gsl_sf_fact gsl_sf_doublefact gsl_sf_lnfact gsl_sf_lndoublefact gsl_sf_lnchoose gsl_sf_choose gsl_sf_lnpoch gsl_sf_poch gsl_sf_pochrel gsl_sf_gamma_inc_Q gsl_sf_gamma_inc_P gsl_sf_lnbeta gsl_sf_beta );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::GAMMA ;







#line 4 "gsl_sf_gamma.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::GAMMA - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "GAMMA.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_lngamma

=for sig

  Signature: (double x(); double [o]y(); double [o]s(); double [o]e())

=for ref

Log[Gamma(x)], x not a negative integer Uses real Lanczos method. Determines the sign of Gamma[x] as well as Log[|Gamma[x]|] for x < 0. So Gamma[x] = sgn * Exp[result_lg].

=for bad

gsl_sf_lngamma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma = \&PDL::gsl_sf_lngamma;






=head2 gsl_sf_gamma

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Gamma(x), x not a negative integer

=for bad

gsl_sf_gamma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma = \&PDL::gsl_sf_gamma;






=head2 gsl_sf_gammastar

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Regulated Gamma Function, x > 0 Gamma^*(x) = Gamma(x)/(Sqrt[2Pi] x^(x-1/2) exp(-x)) = (1 + 1/(12x) + ...),  x->Inf

=for bad

gsl_sf_gammastar does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammastar = \&PDL::gsl_sf_gammastar;






=head2 gsl_sf_gammainv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

1/Gamma(x)

=for bad

gsl_sf_gammainv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammainv = \&PDL::gsl_sf_gammainv;






=head2 gsl_sf_lngamma_complex

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Log[Gamma(z)] for z complex, z not a negative integer. Calculates: lnr = log|Gamma(z)|, arg = arg(Gamma(z))  in (-Pi, Pi]

=for bad

gsl_sf_lngamma_complex does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma_complex = \&PDL::gsl_sf_lngamma_complex;






=head2 gsl_sf_taylorcoeff

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

x^n / n!

=for bad

gsl_sf_taylorcoeff does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_taylorcoeff = \&PDL::gsl_sf_taylorcoeff;






=head2 gsl_sf_fact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

n!

=for bad

gsl_sf_fact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fact = \&PDL::gsl_sf_fact;






=head2 gsl_sf_doublefact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

n!! = n(n-2)(n-4)

=for bad

gsl_sf_doublefact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_doublefact = \&PDL::gsl_sf_doublefact;






=head2 gsl_sf_lnfact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

ln n!

=for bad

gsl_sf_lnfact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnfact = \&PDL::gsl_sf_lnfact;






=head2 gsl_sf_lndoublefact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

ln n!!

=for bad

gsl_sf_lndoublefact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lndoublefact = \&PDL::gsl_sf_lndoublefact;






=head2 gsl_sf_lnchoose

=for sig

  Signature: (n(); m(); double [o]y(); double [o]e())

=for ref

log(n choose m)

=for bad

gsl_sf_lnchoose does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnchoose = \&PDL::gsl_sf_lnchoose;






=head2 gsl_sf_choose

=for sig

  Signature: (n(); m(); double [o]y(); double [o]e())

=for ref

n choose m

=for bad

gsl_sf_choose does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_choose = \&PDL::gsl_sf_choose;






=head2 gsl_sf_lnpoch

=for sig

  Signature: (double x(); double [o]y(); double [o]s(); double [o]e(); double a)

=for ref

Logarithm of Pochammer (Apell) symbol, with sign information. result = log( |(a)_x| ), sgn    = sgn( (a)_x ) where (a)_x := Gamma[a + x]/Gamma[a]

=for bad

gsl_sf_lnpoch does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnpoch = \&PDL::gsl_sf_lnpoch;






=head2 gsl_sf_poch

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Pochammer (Apell) symbol (a)_x := Gamma[a + x]/Gamma[x]

=for bad

gsl_sf_poch does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_poch = \&PDL::gsl_sf_poch;






=head2 gsl_sf_pochrel

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Relative Pochammer (Apell) symbol ((a,x) - 1)/x where (a,x) = (a)_x := Gamma[a + x]/Gamma[a]

=for bad

gsl_sf_pochrel does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_pochrel = \&PDL::gsl_sf_pochrel;






=head2 gsl_sf_gamma_inc_Q

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Normalized Incomplete Gamma Function Q(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,x,Infinity} ]

=for bad

gsl_sf_gamma_inc_Q does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_Q = \&PDL::gsl_sf_gamma_inc_Q;






=head2 gsl_sf_gamma_inc_P

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Complementary Normalized Incomplete Gamma Function P(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,0,x} ]

=for bad

gsl_sf_gamma_inc_P does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_P = \&PDL::gsl_sf_gamma_inc_P;






=head2 gsl_sf_lnbeta

=for sig

  Signature: (double a(); double b(); double [o]y(); double [o]e())

=for ref

Logarithm of Beta Function Log[B(a,b)]

=for bad

gsl_sf_lnbeta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnbeta = \&PDL::gsl_sf_lnbeta;






=head2 gsl_sf_beta

=for sig

  Signature: (double a(); double b();double [o]y(); double [o]e())

=for ref

Beta Function B(a,b)

=for bad

gsl_sf_beta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_beta = \&PDL::gsl_sf_beta;







#line 270 "gsl_sf_gamma.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 580 "GAMMA.pm"

# Exit with OK status

1;
