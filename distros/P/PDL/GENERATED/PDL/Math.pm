#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Math;

our @EXPORT_OK = qw(acos asin atan cosh sinh tan tanh ceil floor rint pow acosh asinh atanh erf erfc bessj0 bessj1 bessy0 bessy1 bessjn bessyn lgamma isfinite erfi ndtri polyroots polyfromroots polyval );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Math ;







#line 13 "math.pd"

use strict;
use warnings;

=head1 NAME

PDL::Math - extended mathematical operations and special functions

=head1 SYNOPSIS

 use PDL::Math;

 use PDL::Graphics::TriD;
 imag3d [SURF2D,bessj0(rvals(zeroes(50,50))/2)];

=head1 DESCRIPTION

This module extends PDL with more advanced mathematical functions than
provided by standard Perl.

All the functions have one input pdl, and one output, unless otherwise
stated.

Many of the functions are linked from the system maths library or the
Cephes maths library (determined when PDL is compiled); a few are implemented
entirely in PDL.

=cut

### Kludge for backwards compatibility with older scripts
### This should be deleted at some point later than 21-Nov-2003.
BEGIN {use PDL::MatrixOps;}
#line 59 "Math.pm"


=head1 FUNCTIONS

=cut






=head2 acos

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

acos processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*acos = \&PDL::acos;






=head2 asin

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

asin processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*asin = \&PDL::asin;






=head2 atan

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

atan processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atan = \&PDL::atan;






=head2 cosh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

cosh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cosh = \&PDL::cosh;






=head2 sinh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

sinh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*sinh = \&PDL::sinh;






=head2 tan

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

tan processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*tan = \&PDL::tan;






=head2 tanh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

tanh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*tanh = \&PDL::tanh;






=head2 ceil

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

ceil processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ceil = \&PDL::ceil;






=head2 floor

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

floor processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*floor = \&PDL::floor;






=head2 rint

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format.

=for method

rint uses the 'round half to even' rounding method (also known as
banker's rounding).  Half-integers are rounded to the nearest even
number. This avoids a slight statistical bias inherent in always
rounding half-integers up or away from zero.

If you are looking to round half-integers up (regardless of sign), try
C<floor($x+0.5)>.  If you want to round half-integers away from zero,
try C<< ceil(abs($x)+0.5)*($x<=>0) >>. Works inplace.

=for bad

rint processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rint = \&PDL::rint;






=head2 pow

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Synonym for `**'. Works inplace.

=for bad

pow processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pow = \&PDL::pow;






=head2 acosh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

acosh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*acosh = \&PDL::acosh;






=head2 asinh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

asinh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*asinh = \&PDL::asinh;






=head2 atanh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

atanh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atanh = \&PDL::atanh;






=head2 erf

=for sig

  Signature: (a(); [o]b())

=for ref

The error function. Works inplace.

=for bad

erf processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erf = \&PDL::erf;






=head2 erfc

=for sig

  Signature: (a(); [o]b())

=for ref

The complement of the error function. Works inplace.

=for bad

erfc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erfc = \&PDL::erfc;






=head2 bessj0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj0 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessj0 = \&PDL::bessj0;






=head2 bessj1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj1 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessj1 = \&PDL::bessj1;






=head2 bessy0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy0 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessy0 = \&PDL::bessy0;






=head2 bessy1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy1 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessy1 = \&PDL::bessy1;






=head2 bessjn

=for sig

  Signature: (a(); int n(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n
.
This takes a second int argument which gives the order
of the function required.
 Works inplace.

=for bad

bessjn processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessjn = \&PDL::bessjn;






=head2 bessyn

=for sig

  Signature: (a(); int n(); [o]b())

=for ref

The regular Bessel function of the first kind, Y_n
.
This takes a second int argument which gives the order
of the function required.
 Works inplace.

=for bad

bessyn processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessyn = \&PDL::bessyn;






=head2 lgamma

=for sig

  Signature: (a(); [o]b(); int[o]s())

=for ref

log gamma function

This returns 2 ndarrays -- the first set gives the log(gamma) values,
while the second set, of integer values, gives the sign of the gamma
function.  This is useful for determining factorials, amongst other
things.

=for bad

lgamma processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*lgamma = \&PDL::lgamma;






=head2 isfinite

=for sig

  Signature: (a(); int [o]mask())

=for ref

Sets C<$mask> true if C<$a> is not a C<NaN> or C<inf> (either positive or negative). Works inplace.

=for bad

Bad values are treated as C<NaN> or C<inf>.

=cut




*isfinite = \&PDL::isfinite;






=head2 erfi

=for sig

  Signature: (a(); [o]b())

=for ref

The inverse of the error function. Works inplace.

=for bad

erfi processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erfi = \&PDL::erfi;






=head2 ndtri

=for sig

  Signature: (a(); [o]b())

=for ref

The value for which the area under the
Gaussian probability density function (integrated from
minus infinity) is equal to the argument (cf L</erfi>). Works inplace.

=for bad

ndtri processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ndtri = \&PDL::ndtri;






=head2 polyroots

=for sig

  Signature: (cr(n); ci(n); [o]rr(m=CALC($SIZE(n)-1)); [o]ri(m))

=for ref

Complex roots of a complex polynomial, given coefficients in order
of decreasing powers. Only works for degree >= 1.
As of 2.086, works with native-complex data.

=for usage

 $roots = polyroots($coeffs); # native complex
 ($rr, $ri) = polyroots($cr, $ci);

=for bad

polyroots does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 348 "math.pd"
sub PDL::polyroots {
  my @args = map PDL->topdl($_), @_;
  my $natcplx = !$args[0]->type->real;
  barf "need array context" if !$natcplx and !(wantarray//1);
  splice @args, 0, 1, map $args[0]->$_, qw(re im) if $natcplx;
  $_ //= PDL->null for @args[2,3];
  PDL::_polyroots_int(@args);
  $natcplx ? $args[2]->czip($args[3]) : @args[2,3];
}
#line 826 "Math.pm"

*polyroots = \&PDL::polyroots;






=head2 polyfromroots

=for sig

  Signature: (r(m); [o]c(n=CALC($SIZE(m)+1)))

=for ref

Calculates the complex coefficients of a polynomial from its complex
roots, in order of decreasing powers. Added in 2.086, works with
native-complex data. Currently C<O(n^2)>.

=for usage

 $coeffs = polyfromroots($roots); # native complex
 ($cr, $ci) = polyfromroots($rr, $ri);

=for bad

polyfromroots does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 388 "math.pd"
sub PDL::polyfromroots {
  my @args = map PDL->topdl($_), @_;
  my $natcplx = !$args[0]->type->real;
  barf "need array context" if !$natcplx and !(wantarray//1);
  if (!$natcplx) {
    splice @args, 0, 2, $args[0]->czip($args[1]); # r
  }
  my @ins = splice @args, 0, 1;
  my $explicit_out = my @outs = @args;
  if ($natcplx) {
    $_ //= PDL->null for $outs[0];
  } else {
    $_ //= PDL->null for @outs[0,1];
  }
  my @args_out = $natcplx ? @outs : PDL->null;
  PDL::_polyfromroots_int(@ins, @args_out);
  if (!$natcplx) {
    $outs[0] .= $args_out[0]->re;
    $outs[1] .= $args_out[0]->im;
  }
  $natcplx ? $outs[0] : @outs;
}
#line 886 "Math.pm"

*polyfromroots = \&PDL::polyfromroots;






=head2 polyval

=for sig

  Signature: (c(n); x(); [o]y())

=for ref

Complex value of a complex polynomial at given point, given coefficients
in order of decreasing powers. Uses Horner recurrence. Added in 2.086,
works with native-complex data.

=for usage

 $y = polyval($coeffs, $x); # native complex
 ($yr, $yi) = polyval($cr, $ci, $xr, $xi);

=for bad

polyval does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 433 "math.pd"
sub PDL::polyval {
  my @args = map PDL->topdl($_), @_;
  my $natcplx = !$args[0]->type->real;
  barf "need array context" if !$natcplx and !(wantarray//1);
  if (!$natcplx) {
    splice @args, 0, 2, $args[0]->czip($args[1]); # c
    splice @args, 1, 2, $args[1]->czip($args[2]); # x
  }
  my @ins = splice @args, 0, 2;
  my $explicit_out = my @outs = @args;
  if ($natcplx) {
    $_ //= PDL->null for $outs[0];
  } else {
    $_ //= PDL->null for @outs[0,1];
  }
  my @args_out = $natcplx ? @outs : PDL->null;
  PDL::_polyval_int(@ins, @args_out);
  if (!$natcplx) {
    $outs[0] .= $args_out[0]->re;
    $outs[1] .= $args_out[0]->im;
  }
  $natcplx ? $outs[0] : @outs;
}
#line 947 "Math.pm"

*polyval = \&PDL::polyval;







#line 470 "math.pd"

=head1 BUGS

Hasn't been tested on all platforms to ensure Cephes
versions are picked up automatically and used correctly.

=head1 AUTHOR

Copyright (C) R.J.R. Williams 1997 (rjrw@ast.leeds.ac.uk), Karl Glazebrook
(kgb@aaoepp.aao.gov.au) and Tuomas J. Lukka (Tuomas.Lukka@helsinki.fi).
Portions (C) Craig DeForest 2002 (deforest@boulder.swri.edu).

All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the PDL copyright notice should be included in the file.

=cut
#line 977 "Math.pm"

# Exit with OK status

1;
