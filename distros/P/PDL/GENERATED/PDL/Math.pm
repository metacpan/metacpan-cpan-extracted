
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Math;

@EXPORT_OK  = qw( PDL::PP acos PDL::PP asin PDL::PP atan PDL::PP cosh PDL::PP sinh PDL::PP tan PDL::PP tanh PDL::PP ceil PDL::PP floor PDL::PP rint PDL::PP pow PDL::PP acosh PDL::PP asinh PDL::PP atanh PDL::PP erf PDL::PP erfc PDL::PP bessj0 PDL::PP bessj1 PDL::PP bessy0 PDL::PP bessy1 PDL::PP bessjn PDL::PP bessyn PDL::PP lgamma PDL::PP badmask PDL::PP isfinite PDL::PP erfi PDL::PP ndtri PDL::PP polyroots );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Math ;




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







=head1 FUNCTIONS



=cut






=head2 acos

=for sig

  Signature: (a(); [o]b())

=for ref

The usual trigonometric function. Works inplace.

=for bad

acos processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*acos = \&PDL::acos;





=head2 asin

=for sig

  Signature: (a(); [o]b())

=for ref

The usual trigonometric function. Works inplace.

=for bad

asin processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*asin = \&PDL::asin;





=head2 atan

=for sig

  Signature: (a(); [o]b())

=for ref

The usual trigonometric function. Works inplace.

=for bad

atan processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*atan = \&PDL::atan;





=head2 cosh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

cosh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cosh = \&PDL::cosh;





=head2 sinh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

sinh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sinh = \&PDL::sinh;





=head2 tan

=for sig

  Signature: (a(); [o]b())

=for ref

The usual trigonometric function. Works inplace.

=for bad

tan processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*tan = \&PDL::tan;





=head2 tanh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

tanh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*tanh = \&PDL::tanh;





=head2 ceil

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

ceil processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ceil = \&PDL::ceil;





=head2 floor

=for sig

  Signature: (a(); [o]b())

=for ref

Round to integer values in floating-point format. Works inplace.

=for bad

floor processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
try C<< floor(abs($x)+0.5)*($x<=>0) >>. Works inplace.

=for bad

rint processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*rint = \&PDL::rint;





=head2 pow

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Synonym for `**'. Works inplace.

=for bad

pow processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pow = \&PDL::pow;





=head2 acosh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

acosh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*acosh = \&PDL::acosh;





=head2 asinh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

asinh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*asinh = \&PDL::asinh;





=head2 atanh

=for sig

  Signature: (a(); [o]b())

=for ref

The standard hyperbolic function. Works inplace.

=for bad

atanh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*atanh = \&PDL::atanh;





=head2 erf

=for sig

  Signature: (a(); [o]b())

=for ref

The error function. Works inplace.

=for bad

erf processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*erf = \&PDL::erf;





=head2 erfc

=for sig

  Signature: (a(); [o]b())

=for ref

The complement of the error function. Works inplace.

=for bad

erfc processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*erfc = \&PDL::erfc;





=head2 bessj0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj0 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bessj0 = \&PDL::bessj0;





=head2 bessj1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the first kind, J_n Works inplace.

=for bad

bessj1 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bessj1 = \&PDL::bessj1;





=head2 bessy0

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy0 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bessy0 = \&PDL::bessy0;





=head2 bessy1

=for sig

  Signature: (a(); [o]b())

=for ref

The regular Bessel function of the second kind, Y_n. Works inplace.

=for bad

bessy1 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bessyn = \&PDL::bessyn;





=head2 lgamma

=for sig

  Signature: (a(); [o]b(); int[o]s())

=for ref

log gamma function

This returns 2 piddles -- the first set gives the log(gamma) values,
while the second set, of integer values, gives the sign of the gamma
function.  This is useful for determining factorials, amongst other
things.



=for bad

lgamma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*lgamma = \&PDL::lgamma;





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






*badmask = \&PDL::badmask;





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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*erfi = \&PDL::erfi;





=head2 ndtri

=for sig

  Signature: (a(); [o]b())

=for ref

The value for which the area under the
Gaussian probability density function (integrated from
minus infinity) is equal to the argument (cf L<erfi|/erfi>). Works inplace.

=for bad

ndtri processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ndtri = \&PDL::ndtri;





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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*polyroots = \&PDL::polyroots;



;


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





# Exit with OK status

1;

		   