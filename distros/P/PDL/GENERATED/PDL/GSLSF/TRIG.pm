#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::TRIG;

our @EXPORT_OK = qw(gsl_sf_sin gsl_sf_cos gsl_sf_hypot gsl_sf_complex_sin gsl_sf_complex_cos gsl_sf_complex_logsin gsl_sf_lnsinh gsl_sf_lncosh gsl_sf_polar_to_rect gsl_sf_rect_to_polar gsl_sf_angle_restrict_symm gsl_sf_angle_restrict_pos gsl_sf_sin_err gsl_sf_cos_err );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::TRIG ;







#line 4 "gsl_sf_trig.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::TRIG - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 40 "TRIG.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_sin

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Sin(x) with GSL semantics.

=for bad

gsl_sf_sin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin = \&PDL::gsl_sf_sin;






=head2 gsl_sf_cos

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Cos(x) with GSL semantics.

=for bad

gsl_sf_cos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos = \&PDL::gsl_sf_cos;






=head2 gsl_sf_hypot

=for sig

  Signature: (double x(); double xx(); double [o]y(); double [o]e())

=for ref

Hypot(x,xx) with GSL semantics.

=for bad

gsl_sf_hypot does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hypot = \&PDL::gsl_sf_hypot;






=head2 gsl_sf_complex_sin

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Sin(z) for complex z

=for bad

gsl_sf_complex_sin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_sin = \&PDL::gsl_sf_complex_sin;






=head2 gsl_sf_complex_cos

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Cos(z) for complex z

=for bad

gsl_sf_complex_cos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_cos = \&PDL::gsl_sf_complex_cos;






=head2 gsl_sf_complex_logsin

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Log(Sin(z)) for complex z

=for bad

gsl_sf_complex_logsin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_logsin = \&PDL::gsl_sf_complex_logsin;






=head2 gsl_sf_lnsinh

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log(Sinh(x)) with GSL semantics.

=for bad

gsl_sf_lnsinh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnsinh = \&PDL::gsl_sf_lnsinh;






=head2 gsl_sf_lncosh

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log(Cos(x)) with GSL semantics.

=for bad

gsl_sf_lncosh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lncosh = \&PDL::gsl_sf_lncosh;






=head2 gsl_sf_polar_to_rect

=for sig

  Signature: (double r(); double t(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Convert polar to rectlinear coordinates.

=for bad

gsl_sf_polar_to_rect does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_polar_to_rect = \&PDL::gsl_sf_polar_to_rect;






=head2 gsl_sf_rect_to_polar

=for sig

  Signature: (double x(); double y(); double [o]r(); double [o]t(); double [o]re(); double [o]te())

=for ref

Convert rectlinear to polar coordinates. return argument in range [-pi, pi].

=for bad

gsl_sf_rect_to_polar does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_rect_to_polar = \&PDL::gsl_sf_rect_to_polar;






=head2 gsl_sf_angle_restrict_symm

=for sig

  Signature: (double [o]y())

=for ref

Force an angle to lie in the range (-pi,pi].

=for bad

gsl_sf_angle_restrict_symm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_symm = \&PDL::gsl_sf_angle_restrict_symm;






=head2 gsl_sf_angle_restrict_pos

=for sig

  Signature: (double [o]y())

=for ref

Force an angle to lie in the range [0,2 pi).

=for bad

gsl_sf_angle_restrict_pos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_pos = \&PDL::gsl_sf_angle_restrict_pos;






=head2 gsl_sf_sin_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Sin(x) for quantity with an associated error.

=for bad

gsl_sf_sin_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin_err = \&PDL::gsl_sf_sin_err;






=head2 gsl_sf_cos_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Cos(x) for quantity with an associated error.

=for bad

gsl_sf_cos_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos_err = \&PDL::gsl_sf_cos_err;







#line 203 "gsl_sf_trig.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 445 "TRIG.pm"

# Exit with OK status

1;
