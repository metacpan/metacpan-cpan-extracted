#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::ELLINT;

our @EXPORT_OK = qw(gsl_sf_ellint_Kcomp gsl_sf_ellint_Ecomp gsl_sf_ellint_F gsl_sf_ellint_E gsl_sf_ellint_P gsl_sf_ellint_D gsl_sf_ellint_RC gsl_sf_ellint_RD gsl_sf_ellint_RF gsl_sf_ellint_RJ );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::ELLINT ;







#line 5 "gsl_sf_ellint.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::ELLINT - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library.

=cut
#line 40 "ELLINT.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_ellint_Kcomp

=for sig

  Signature: (double k(); double [o]y(); double [o]e())

=for ref

Legendre form of complete elliptic integrals K(k) = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}].

=for bad

gsl_sf_ellint_Kcomp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Kcomp = \&PDL::gsl_sf_ellint_Kcomp;






=head2 gsl_sf_ellint_Ecomp

=for sig

  Signature: (double k(); double [o]y(); double [o]e())

=for ref

Legendre form of complete elliptic integrals E(k) = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}]

=for bad

gsl_sf_ellint_Ecomp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Ecomp = \&PDL::gsl_sf_ellint_Ecomp;






=head2 gsl_sf_ellint_F

=for sig

  Signature: (double phi(); double k(); double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals F(phi,k)   = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_F does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_F = \&PDL::gsl_sf_ellint_F;






=head2 gsl_sf_ellint_E

=for sig

  Signature: (double phi(); double k(); double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals E(phi,k)   = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_E does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_E = \&PDL::gsl_sf_ellint_E;






=head2 gsl_sf_ellint_P

=for sig

  Signature: (double phi(); double k(); double n();
              double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals P(phi,k,n) = Integral[(1 + n Sin[t]^2)^(-1)/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_P does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_P = \&PDL::gsl_sf_ellint_P;






=head2 gsl_sf_ellint_D

=for sig

  Signature: (double phi(); double k();
              double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals D(phi,k)

=for bad

gsl_sf_ellint_D does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_D = \&PDL::gsl_sf_ellint_D;






=head2 gsl_sf_ellint_RC

=for sig

  Signature: (double x(); double yy(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RC(x,y)   = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1)], {t,0,Inf}

=for bad

gsl_sf_ellint_RC does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RC = \&PDL::gsl_sf_ellint_RC;






=head2 gsl_sf_ellint_RD

=for sig

  Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RD(x,y,z) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-3/2), {t,0,Inf}]

=for bad

gsl_sf_ellint_RD does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RD = \&PDL::gsl_sf_ellint_RD;






=head2 gsl_sf_ellint_RF

=for sig

  Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RF(x,y,z) = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2), {t,0,Inf}]

=for bad

gsl_sf_ellint_RF does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RF = \&PDL::gsl_sf_ellint_RF;






=head2 gsl_sf_ellint_RJ

=for sig

  Signature: (double x(); double yy(); double z(); double p(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RJ(x,y,z,p) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2) (t+p)^(-1), {t,0,Inf}]

=for bad

gsl_sf_ellint_RJ does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RJ = \&PDL::gsl_sf_ellint_RJ;







#line 171 "gsl_sf_ellint.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>,
2002 Christian Soeller.
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 340 "ELLINT.pm"

# Exit with OK status

1;
