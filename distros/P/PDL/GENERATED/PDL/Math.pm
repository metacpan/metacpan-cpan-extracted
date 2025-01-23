#
# GENERATED WITH PDL::PP from lib/PDL/Math.pd! Don't modify!
#
package PDL::Math;

our @EXPORT_OK = qw(acos asin atan cosh sinh tan tanh ceil floor rint pow acosh asinh atanh erf erfc bessj0 bessj1 bessy0 bessy1 bessjn bessyn lgamma isfinite erfi ndtri polyroots polyfromroots polyval csqrt clog cacos casin cacosh catanh csqrt_up );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Math ;








#line 44 "lib/PDL/Math.pd"

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
#line 60 "lib/PDL/Math.pm"


=head1 FUNCTIONS

=cut






=head2 acos

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = acos($a);
 acos($a, $b);      # all arguments given
 $b = $a->acos;     # method call
 $a->acos($b);
 $a->inplace->acos; # can be used inplace
 acos($a->inplace);

The usual trigonometric function.

=pod

Broadcasts over its inputs.

=for bad

C<acos> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*acos = \&PDL::acos;






=head2 asin

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = asin($a);
 asin($a, $b);      # all arguments given
 $b = $a->asin;     # method call
 $a->asin($b);
 $a->inplace->asin; # can be used inplace
 asin($a->inplace);

The usual trigonometric function.

=pod

Broadcasts over its inputs.

=for bad

C<asin> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*asin = \&PDL::asin;






=head2 atan

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = atan($a);
 atan($a, $b);      # all arguments given
 $b = $a->atan;     # method call
 $a->atan($b);
 $a->inplace->atan; # can be used inplace
 atan($a->inplace);

The usual trigonometric function.

=pod

Broadcasts over its inputs.

=for bad

C<atan> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atan = \&PDL::atan;






=head2 cosh

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = cosh($a);
 cosh($a, $b);      # all arguments given
 $b = $a->cosh;     # method call
 $a->cosh($b);
 $a->inplace->cosh; # can be used inplace
 cosh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<cosh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cosh = \&PDL::cosh;






=head2 sinh

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = sinh($a);
 sinh($a, $b);      # all arguments given
 $b = $a->sinh;     # method call
 $a->sinh($b);
 $a->inplace->sinh; # can be used inplace
 sinh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<sinh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*sinh = \&PDL::sinh;






=head2 tan

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = tan($a);
 tan($a, $b);      # all arguments given
 $b = $a->tan;     # method call
 $a->tan($b);
 $a->inplace->tan; # can be used inplace
 tan($a->inplace);

The usual trigonometric function.

=pod

Broadcasts over its inputs.

=for bad

C<tan> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*tan = \&PDL::tan;






=head2 tanh

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float double ldouble)

=for usage

 $b = tanh($a);
 tanh($a, $b);      # all arguments given
 $b = $a->tanh;     # method call
 $a->tanh($b);
 $a->inplace->tanh; # can be used inplace
 tanh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<tanh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*tanh = \&PDL::tanh;






=head2 ceil

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = ceil($a);
 ceil($a, $b);      # all arguments given
 $b = $a->ceil;     # method call
 $a->ceil($b);
 $a->inplace->ceil; # can be used inplace
 ceil($a->inplace);

=for ref

Round to integer values in floating-point format.

=pod

Broadcasts over its inputs.

=for bad

C<ceil> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ceil = \&PDL::ceil;






=head2 floor

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = floor($a);
 floor($a, $b);      # all arguments given
 $b = $a->floor;     # method call
 $a->floor($b);
 $a->inplace->floor; # can be used inplace
 floor($a->inplace);

=for ref

Round to integer values in floating-point format.

=pod

Broadcasts over its inputs.

=for bad

C<floor> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*floor = \&PDL::floor;






=head2 rint

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = rint($a);
 rint($a, $b);      # all arguments given
 $b = $a->rint;     # method call
 $a->rint($b);
 $a->inplace->rint; # can be used inplace
 rint($a->inplace);

=for ref

Round to integer values in floating-point format.

This is the C99 function; previous to 2.096, the doc referred to a
bespoke function that did banker's rounding, but this was not used
as a system version will have been detected and used.

If you are looking to round half-integers up (regardless of sign), try
C<floor($x+0.5)>.  If you want to round half-integers away from zero,
try C<< ceil(abs($x)+0.5)*($x<=>0) >>.

=pod

Broadcasts over its inputs.

=for bad

C<rint> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rint = \&PDL::rint;






=head2 pow

=for sig

 Signature: (a(); b(); [o]c())
 Types: (cfloat cdouble cldouble sbyte byte short ushort long
   ulong indx ulonglong longlong float double ldouble)

=for usage

 $c = pow($a, $b);
 pow($a, $b, $c);      # all arguments given
 $c = $a->pow($b);     # method call
 $a->pow($b, $c);
 $a->inplace->pow($b); # can be used inplace
 pow($a->inplace,$b);

=for ref

Synonym for `**'.

=pod

Broadcasts over its inputs.

=for bad

C<pow> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pow = \&PDL::pow;






=head2 acosh

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = acosh($a);
 acosh($a, $b);      # all arguments given
 $b = $a->acosh;     # method call
 $a->acosh($b);
 $a->inplace->acosh; # can be used inplace
 acosh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<acosh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*acosh = \&PDL::acosh;






=head2 asinh

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = asinh($a);
 asinh($a, $b);      # all arguments given
 $b = $a->asinh;     # method call
 $a->asinh($b);
 $a->inplace->asinh; # can be used inplace
 asinh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<asinh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*asinh = \&PDL::asinh;






=head2 atanh

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = atanh($a);
 atanh($a, $b);      # all arguments given
 $b = $a->atanh;     # method call
 $a->atanh($b);
 $a->inplace->atanh; # can be used inplace
 atanh($a->inplace);

The standard hyperbolic function.

=pod

Broadcasts over its inputs.

=for bad

C<atanh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atanh = \&PDL::atanh;






=head2 erf

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = erf($a);
 erf($a, $b);      # all arguments given
 $b = $a->erf;     # method call
 $a->erf($b);
 $a->inplace->erf; # can be used inplace
 erf($a->inplace);

=for ref

The error function.

=pod

Broadcasts over its inputs.

=for bad

C<erf> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erf = \&PDL::erf;






=head2 erfc

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = erfc($a);
 erfc($a, $b);      # all arguments given
 $b = $a->erfc;     # method call
 $a->erfc($b);
 $a->inplace->erfc; # can be used inplace
 erfc($a->inplace);

=for ref

The complement of the error function.

=pod

Broadcasts over its inputs.

=for bad

C<erfc> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erfc = \&PDL::erfc;






=head2 bessj0

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessj0($a);
 bessj0($a, $b);      # all arguments given
 $b = $a->bessj0;     # method call
 $a->bessj0($b);
 $a->inplace->bessj0; # can be used inplace
 bessj0($a->inplace);

=for ref

The regular Bessel function of the first kind, J_n

=pod

Broadcasts over its inputs.

=for bad

C<bessj0> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessj0 = \&PDL::bessj0;






=head2 bessj1

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessj1($a);
 bessj1($a, $b);      # all arguments given
 $b = $a->bessj1;     # method call
 $a->bessj1($b);
 $a->inplace->bessj1; # can be used inplace
 bessj1($a->inplace);

=for ref

The regular Bessel function of the first kind, J_n

=pod

Broadcasts over its inputs.

=for bad

C<bessj1> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessj1 = \&PDL::bessj1;






=head2 bessy0

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessy0($a);
 bessy0($a, $b);      # all arguments given
 $b = $a->bessy0;     # method call
 $a->bessy0($b);
 $a->inplace->bessy0; # can be used inplace
 bessy0($a->inplace);

=for ref

The regular Bessel function of the second kind, Y_n.

=pod

Broadcasts over its inputs.

=for bad

C<bessy0> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessy0 = \&PDL::bessy0;






=head2 bessy1

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessy1($a);
 bessy1($a, $b);      # all arguments given
 $b = $a->bessy1;     # method call
 $a->bessy1($b);
 $a->inplace->bessy1; # can be used inplace
 bessy1($a->inplace);

=for ref

The regular Bessel function of the second kind, Y_n.

=pod

Broadcasts over its inputs.

=for bad

C<bessy1> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessy1 = \&PDL::bessy1;






=head2 bessjn

=for sig

 Signature: (a(); int n(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessjn($a, $n);
 bessjn($a, $n, $b);      # all arguments given
 $b = $a->bessjn($n);     # method call
 $a->bessjn($n, $b);
 $a->inplace->bessjn($n); # can be used inplace
 bessjn($a->inplace,$n);

=for ref

The regular Bessel function of the first kind, J_n
.
This takes a second int argument which gives the order
of the function required.

=pod

Broadcasts over its inputs.

=for bad

C<bessjn> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessjn = \&PDL::bessjn;






=head2 bessyn

=for sig

 Signature: (a(); int n(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = bessyn($a, $n);
 bessyn($a, $n, $b);      # all arguments given
 $b = $a->bessyn($n);     # method call
 $a->bessyn($n, $b);
 $a->inplace->bessyn($n); # can be used inplace
 bessyn($a->inplace,$n);

=for ref

The regular Bessel function of the first kind, Y_n
.
This takes a second int argument which gives the order
of the function required.

=pod

Broadcasts over its inputs.

=for bad

C<bessyn> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bessyn = \&PDL::bessyn;






=head2 lgamma

=for sig

 Signature: (a(); [o]b(); int[o]s())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 ($b, $s) = lgamma($a);
 lgamma($a, $b, $s);    # all arguments given
 ($b, $s) = $a->lgamma; # method call
 $a->lgamma($b, $s);

=for ref

log gamma function

This returns 2 ndarrays -- the first set gives the log(gamma) values,
while the second set, of integer values, gives the sign of the gamma
function.  This is useful for determining factorials, amongst other
things.

=pod

Broadcasts over its inputs.

=for bad

C<lgamma> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*lgamma = \&PDL::lgamma;






=head2 isfinite

=for sig

 Signature: (a(); int [o]mask())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $mask = isfinite($a);
 isfinite($a, $mask);  # all arguments given
 $mask = $a->isfinite; # method call
 $a->isfinite($mask);

=for ref

Sets C<$mask> true if C<$a> is not a C<NaN> or C<inf> (either positive or negative).

=pod

Broadcasts over its inputs.

=for bad

Bad values are treated as C<NaN> or C<inf>.

=cut




*isfinite = \&PDL::isfinite;






=head2 erfi

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = erfi($a);
 erfi($a, $b);      # all arguments given
 $b = $a->erfi;     # method call
 $a->erfi($b);
 $a->inplace->erfi; # can be used inplace
 erfi($a->inplace);

=for ref

erfi

=pod

Broadcasts over its inputs.

=for bad

C<erfi> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*erfi = \&PDL::erfi;






=head2 ndtri

=for sig

 Signature: (a(); [o]b())
 Types: (float double ldouble)

=for usage

 $b = ndtri($a);
 ndtri($a, $b);      # all arguments given
 $b = $a->ndtri;     # method call
 $a->ndtri($b);
 $a->inplace->ndtri; # can be used inplace
 ndtri($a->inplace);

=for ref

ndtri

=pod

Broadcasts over its inputs.

=for bad

C<ndtri> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ndtri = \&PDL::ndtri;






=head2 polyroots

=for sig

 Signature: (cr(n); ci(n); [o]rr(m=CALC($SIZE(n)-1)); [o]ri(m))
 Types: (double)

=for ref

Complex roots of a complex polynomial, given coefficients in order
of decreasing powers. Only works for degree >= 1.
Uses the Jenkins-Traub algorithm (see
L<https://en.wikipedia.org/wiki/Jenkins%E2%80%93Traub_algorithm>).
As of 2.086, works with native-complex data.

=for usage

 $roots = polyroots($coeffs); # native complex
 polyroots($coeffs, $roots=null); # native complex
 ($rr, $ri) = polyroots($cr, $ci);
 polyroots($cr, $ci, $rr, $ri);

=pod

Broadcasts over its inputs.

=for bad

C<polyroots> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 357 "lib/PDL/Math.pd"
sub PDL::polyroots {
  my @args = map PDL->topdl($_), @_;
  my $natcplx = !$args[0]->type->real;
  barf "need array context if give real data and no outputs"
    if !$natcplx and @_ < 3 and !(wantarray//1);
  splice @args, 0, 1, map $args[0]->$_, qw(re im) if $natcplx;
  my @ins = splice @args, 0, 2;
  my $explicit_out = my @outs = @args;
  if ($natcplx) {
    $_ //= PDL->null for $outs[0];
  } else {
    $_ //= PDL->null for @outs[0,1];
  }
  my @args_out = $natcplx ? (map PDL->null, 1..2) : @outs; # opposite from polyfromroots
  PDL::_polyroots_int(@ins, @args_out);
  return @args_out if !$natcplx;
  $outs[0] .= PDL::czip(@args_out[0,1]);
}
#line 1194 "lib/PDL/Math.pm"

*polyroots = \&PDL::polyroots;






=head2 polyfromroots

=for sig

 Signature: (r(m); [o]c(n=CALC($SIZE(m)+1)))
 Types: (cdouble)

=for ref

Calculates the complex coefficients of a polynomial from its complex
roots, in order of decreasing powers. Added in 2.086, works with
native-complex data.

Algorithm is from Octave poly.m, O(n^2), per
L<https://cs.stackexchange.com/questions/116643/what-is-the-most-efficient-algorithm-to-compute-polynomial-coefficients-from-its>;
using an FFT would allow O(n*log(n)^2).

=for usage

 $coeffs = polyfromroots($roots); # native complex
 ($cr, $ci) = polyfromroots($rr, $ri);

=pod

Broadcasts over its inputs.

=for bad

C<polyfromroots> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 406 "lib/PDL/Math.pd"
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
#line 1263 "lib/PDL/Math.pm"

*polyfromroots = \&PDL::polyfromroots;






=head2 polyval

=for sig

 Signature: (c(n); x(); [o]y())
 Types: (cdouble)

=for ref

Complex value of a complex polynomial at given point, given coefficients
in order of decreasing powers. Uses Horner recurrence. Added in 2.086,
works with native-complex data.

=for usage

 $y = polyval($coeffs, $x); # native complex
 ($yr, $yi) = polyval($cr, $ci, $xr, $xi);

=pod

Broadcasts over its inputs.

=for bad

C<polyval> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 455 "lib/PDL/Math.pd"
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
#line 1329 "lib/PDL/Math.pm"

*polyval = \&PDL::polyval;






=head2 csqrt

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = csqrt($i);
 csqrt($i, $o);  # all arguments given
 $o = $i->csqrt; # method call
 $i->csqrt($o);

=for ref

Takes real or complex data, returns the complex C<sqrt>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<csqrt> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csqrt = \&PDL::csqrt;






=head2 clog

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = clog($i);
 clog($i, $o);  # all arguments given
 $o = $i->clog; # method call
 $i->clog($o);

=for ref

Takes real or complex data, returns the complex C<log>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<clog> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clog = \&PDL::clog;






=head2 cacos

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = cacos($i);
 cacos($i, $o);  # all arguments given
 $o = $i->cacos; # method call
 $i->cacos($o);

=for ref

Takes real or complex data, returns the complex C<acos>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<cacos> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cacos = \&PDL::cacos;






=head2 casin

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = casin($i);
 casin($i, $o);  # all arguments given
 $o = $i->casin; # method call
 $i->casin($o);

=for ref

Takes real or complex data, returns the complex C<asin>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<casin> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*casin = \&PDL::casin;






=head2 cacosh

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = cacosh($i);
 cacosh($i, $o);  # all arguments given
 $o = $i->cacosh; # method call
 $i->cacosh($o);

=for ref

Takes real or complex data, returns the complex C<acosh>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<cacosh> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cacosh = \&PDL::cacosh;






=head2 catanh

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = catanh($i);
 catanh($i, $o);  # all arguments given
 $o = $i->catanh; # method call
 $i->catanh($o);

=for ref

Takes real or complex data, returns the complex C<atanh>.

Added in 2.099.

=pod

Broadcasts over its inputs.

=for bad

C<catanh> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*catanh = \&PDL::catanh;






=head2 csqrt_up

=for sig

 Signature: (i(); complex [o] o())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $o = csqrt_up($i);
 csqrt_up($i, $o);  # all arguments given
 $o = $i->csqrt_up; # method call
 $i->csqrt_up($o);

Take the complex square root of a number choosing that whose imaginary
part is not negative, i.e., it is a square root with a branch cut
'infinitesimally' below the positive real axis.

=pod

Broadcasts over its inputs.

=for bad

C<csqrt_up> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csqrt_up = \&PDL::csqrt_up;







#line 529 "lib/PDL/Math.pd"

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
#line 1639 "lib/PDL/Math.pm"

# Exit with OK status

1;
