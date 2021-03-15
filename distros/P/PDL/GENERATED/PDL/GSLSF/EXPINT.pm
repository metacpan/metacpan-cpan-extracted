
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::EXPINT;

@EXPORT_OK  = qw( PDL::PP gsl_sf_expint_E1 PDL::PP gsl_sf_expint_E2 PDL::PP gsl_sf_expint_Ei PDL::PP gsl_sf_Shi PDL::PP gsl_sf_Chi PDL::PP gsl_sf_expint_3 PDL::PP gsl_sf_Si PDL::PP gsl_sf_Ci PDL::PP gsl_sf_atanint );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::EXPINT ;




=head1 NAME

PDL::GSLSF::EXPINT - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_expint_E1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

E_1(x) := Re[ Integrate[ Exp[-xt]/t, {t,1,Infinity}] ]

=for bad

gsl_sf_expint_E1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_expint_E1 = \&PDL::gsl_sf_expint_E1;





=head2 gsl_sf_expint_E2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

E_2(x) := Re[ Integrate[ Exp[-xt]/t^2, {t,1,Infity}] ]

=for bad

gsl_sf_expint_E2 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_expint_E2 = \&PDL::gsl_sf_expint_E2;





=head2 gsl_sf_expint_Ei

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ei(x) := PV Integrate[ Exp[-t]/t, {t,-x,Infinity}]

=for bad

gsl_sf_expint_Ei does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_expint_Ei = \&PDL::gsl_sf_expint_Ei;





=head2 gsl_sf_Shi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Shi(x) := Integrate[ Sinh[t]/t, {t,0,x}]

=for bad

gsl_sf_Shi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_Shi = \&PDL::gsl_sf_Shi;





=head2 gsl_sf_Chi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Chi(x) := Re[ M_EULER + log(x) + Integrate[(Cosh[t]-1)/t, {t,0,x}] ]

=for bad

gsl_sf_Chi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_Chi = \&PDL::gsl_sf_Chi;





=head2 gsl_sf_expint_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ei_3(x) := Integral[ Exp[-t^3], {t,0,x}]

=for bad

gsl_sf_expint_3 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_expint_3 = \&PDL::gsl_sf_expint_3;





=head2 gsl_sf_Si

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Si(x) := Integrate[ Sin[t]/t, {t,0,x}]

=for bad

gsl_sf_Si does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_Si = \&PDL::gsl_sf_Si;





=head2 gsl_sf_Ci

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ci(x) := -Integrate[ Cos[t]/t, {t,x,Infinity}]

=for bad

gsl_sf_Ci does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_Ci = \&PDL::gsl_sf_Ci;





=head2 gsl_sf_atanint

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

AtanInt(x) := Integral[ Arctan[t]/t, {t,0,x}]

=for bad

gsl_sf_atanint does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_atanint = \&PDL::gsl_sf_atanint;



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

		   