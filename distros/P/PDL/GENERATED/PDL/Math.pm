#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Math;

our @EXPORT_OK = qw(acos asin atan cosh sinh tan tanh ceil floor rint pow acosh asinh atanh erf erfc bessj0 bessj1 bessy0 bessy1 bessjn bessyn lgamma badmask isfinite erfi ndtri polyroots );
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
#line 58 "Math.pm"






=head1 FUNCTIONS

=cut




#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 acos

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

acos processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 92 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*acos = \&PDL::acos;
#line 99 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 asin

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

asin processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 123 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*asin = \&PDL::asin;
#line 130 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 atan

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

atan processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 154 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*atan = \&PDL::atan;
#line 161 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 cosh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

cosh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 185 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*cosh = \&PDL::cosh;
#line 192 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 sinh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

sinh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 216 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*sinh = \&PDL::sinh;
#line 223 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 tan

=for sig

  Signature: (a(); [o]b())

The usual trigonometric function.
 Works inplace.

=for bad

tan processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 247 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*tan = \&PDL::tan;
#line 254 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 tanh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

tanh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 278 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*tanh = \&PDL::tanh;
#line 285 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 ceil

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

ceil processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 310 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*ceil = \&PDL::ceil;
#line 317 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 floor

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

floor processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 342 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*floor = \&PDL::floor;
#line 349 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



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
#line 385 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*rint = \&PDL::rint;
#line 392 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 pow

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Synonym for `**'. Works inplace.

=for bad

pow processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 417 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*pow = \&PDL::pow;
#line 424 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 acosh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

acosh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 448 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*acosh = \&PDL::acosh;
#line 455 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 asinh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

asinh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 479 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*asinh = \&PDL::asinh;
#line 486 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 atanh

=for sig

  Signature: (a(); [o]b())

The standard hyperbolic function.
 Works inplace.

=for bad

atanh processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 510 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*atanh = \&PDL::atanh;
#line 517 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 erf

=for sig

  Signature: (a(); [o]b())

=for ref

The error function. Works inplace.

=for bad

erf processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 542 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*erf = \&PDL::erf;
#line 549 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 erfc

=for sig

  Signature: (a(); [o]b())

=for ref

The complement of the error function. Works inplace.

=for bad

erfc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 574 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*erfc = \&PDL::erfc;
#line 581 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 bessj0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj0 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 606 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessj0 = \&PDL::bessj0;
#line 613 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 bessj1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj1 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 638 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessj1 = \&PDL::bessj1;
#line 645 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 bessy0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy0 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 670 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessy0 = \&PDL::bessy0;
#line 677 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 bessy1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy1 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 702 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessy1 = \&PDL::bessy1;
#line 709 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



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
#line 738 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessjn = \&PDL::bessjn;
#line 745 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



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
#line 774 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*bessyn = \&PDL::bessyn;
#line 781 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



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
#line 813 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*lgamma = \&PDL::lgamma;
#line 820 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 badmask

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Clears all C<infs> and C<nans> in C<$a> to the corresponding value in C<$b>.

badmask can be run with C<$x> inplace:

  badmask($x->inplace,0);
  $x->inplace->badmask(0);



=for bad

If bad values are present, these are also cleared.

=cut
#line 850 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*badmask = \&PDL::badmask;
#line 857 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 isfinite

=for sig

  Signature: (a(); int [o]mask())

=for ref

Sets C<$mask> true if C<$a> is not a C<NaN> or C<inf> (either positive or negative). Works inplace.

=for bad

Bad values are treated as C<NaN> or C<inf>.

=cut
#line 880 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*isfinite = \&PDL::isfinite;
#line 887 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 erfi

=for sig

  Signature: (a(); [o]b())

=for ref

The inverse of the error function. Works inplace.

=for bad

erfi processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 912 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*erfi = \&PDL::erfi;
#line 919 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



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
#line 946 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*ndtri = \&PDL::ndtri;
#line 953 "Math.pm"



#line 1058 "../../blib/lib/PDL/PP.pm"



=head2 polyroots

=for sig

  Signature: (cr(n); ci(n); [o]rr(m); [o]ri(m))



=for ref

Complex roots of a complex polynomial, given coefficients in order
of decreasing powers.

=for usage

 ($rr, $ri) = polyroots($cr, $ci);



=for bad

polyroots does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 987 "Math.pm"



#line 1060 "../../blib/lib/PDL/PP.pm"

*polyroots = \&PDL::polyroots;
#line 994 "Math.pm"





#line 402 "math.pd"


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
#line 1021 "Math.pm"




# Exit with OK status

1;
