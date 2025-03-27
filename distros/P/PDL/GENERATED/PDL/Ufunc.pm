#
# GENERATED WITH PDL::PP from lib/PDL/Ufunc.pd! Don't modify!
#
package PDL::Ufunc;

our @EXPORT_OK = qw(prodover dprodover cumuprodover dcumuprodover sumover dsumover cumusumover dcumusumover andover bandover borover bxorover firstnonzeroover orover xorover zcover numdiff diffcentred partial diff2 intover average avgover caverage cavgover daverage davgover minimum minover minimum_ind minover_ind minimum_n_ind minover_n_ind maximum maxover maximum_ind maxover_ind maximum_n_ind maxover_n_ind minmaximum minmaxover avg sum prod davg dsum dprod zcheck and band or bor xorall bxor min max median mode oddmedian any all minmax medover oddmedover modeover pctover oddpctover pct oddpct qsort qsorti qsortvec qsortveci magnover );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ufunc ;








#line 8 "lib/PDL/Ufunc.pd"

use strict;
use warnings;

=encoding utf8

=head1 NAME

PDL::Ufunc - primitive ufunc operations for pdl

=head1 DESCRIPTION

This module provides some primitive and useful functions defined
using PDL::PP based on functionality of what are sometimes called
I<ufuncs> (for example NumPY and Mathematica talk about these).
It collects all the functions generally used to C<reduce> or
C<accumulate> along a dimension. These all do their job across the
first dimension but by using the slicing functions you can do it
on any dimension.

The L<PDL::Reduce> module provides an alternative interface
to many of the functions in this module.

=head1 SYNOPSIS

 use PDL::Ufunc;

=cut

use PDL::Slices;
use Carp;
#line 59 "lib/PDL/Ufunc.pm"


=head1 FUNCTIONS

=cut






=head2 prodover

=for sig

 Signature: (a(n); int+ [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = prodover($a);
 prodover($a, $b);  # all arguments given
 $b = $a->prodover; # method call
 $a->prodover($b);

=for ref

Project via product to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the product along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

C<prodover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*prodover = \&PDL::prodover;






=head2 dprodover

=for sig

 Signature: (a(n); double [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = dprodover($a);
 dprodover($a, $b);  # all arguments given
 $b = $a->dprodover; # method call
 $a->dprodover($b);

=for ref

Project via product to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the product along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Unlike L</prodover>, the calculations are performed in double precision.

=pod

Broadcasts over its inputs.

=for bad

C<dprodover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dprodover = \&PDL::dprodover;






=head2 cumuprodover

=for sig

 Signature: (a(n); int+ [o]b(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = cumuprodover($a);
 cumuprodover($a, $b);  # all arguments given
 $b = $a->cumuprodover; # method call
 $a->cumuprodover($b);

=for ref

Cumulative product

This function calculates the cumulative product
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative product
is the first element of the parameter.

=pod

Broadcasts over its inputs.

=for bad

C<cumuprodover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cumuprodover = \&PDL::cumuprodover;






=head2 dcumuprodover

=for sig

 Signature: (a(n); double [o]b(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = dcumuprodover($a);
 dcumuprodover($a, $b);  # all arguments given
 $b = $a->dcumuprodover; # method call
 $a->dcumuprodover($b);

=for ref

Cumulative product

This function calculates the cumulative product
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative product
is the first element of the parameter.

Unlike L</cumuprodover>, the calculations are performed in double precision.

=pod

Broadcasts over its inputs.

=for bad

C<dcumuprodover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dcumuprodover = \&PDL::dcumuprodover;






=head2 sumover

=for sig

 Signature: (a(n); int+ [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = sumover($a);
 sumover($a, $b);  # all arguments given
 $b = $a->sumover; # method call
 $a->sumover($b);

=for ref

Project via sum to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the sum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

C<sumover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*sumover = \&PDL::sumover;






=head2 dsumover

=for sig

 Signature: (a(n); double [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = dsumover($a);
 dsumover($a, $b);  # all arguments given
 $b = $a->dsumover; # method call
 $a->dsumover($b);

=for ref

Project via sum to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the sum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Unlike L</sumover>, the calculations are performed in double precision.

=pod

Broadcasts over its inputs.

=for bad

C<dsumover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dsumover = \&PDL::dsumover;






=head2 cumusumover

=for sig

 Signature: (a(n); int+ [o]b(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = cumusumover($a);
 cumusumover($a, $b);  # all arguments given
 $b = $a->cumusumover; # method call
 $a->cumusumover($b);

=for ref

Cumulative sum

This function calculates the cumulative sum
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative sum
is the first element of the parameter.

=pod

Broadcasts over its inputs.

=for bad

C<cumusumover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cumusumover = \&PDL::cumusumover;






=head2 dcumusumover

=for sig

 Signature: (a(n); double [o]b(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = dcumusumover($a);
 dcumusumover($a, $b);  # all arguments given
 $b = $a->dcumusumover; # method call
 $a->dcumusumover($b);

=for ref

Cumulative sum

This function calculates the cumulative sum
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative sum
is the first element of the parameter.

Unlike L</cumusumover>, the calculations are performed in double precision.

=pod

Broadcasts over its inputs.

=for bad

C<dcumusumover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dcumusumover = \&PDL::dcumusumover;






=head2 andover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = andover($a);
 andover($a, $b);  # all arguments given
 $b = $a->andover; # method call
 $a->andover($b);

=for ref

Project via logical and to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the logical and along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*andover = \&PDL::andover;






=head2 bandover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $b = bandover($a);
 bandover($a, $b);  # all arguments given
 $b = $a->bandover; # method call
 $a->bandover($b);

=for ref

Project via bitwise and to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the bitwise and along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*bandover = \&PDL::bandover;






=head2 borover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $b = borover($a);
 borover($a, $b);  # all arguments given
 $b = $a->borover; # method call
 $a->borover($b);

=for ref

Project via bitwise or to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the bitwise or along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*borover = \&PDL::borover;






=head2 bxorover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $b = bxorover($a);
 bxorover($a, $b);  # all arguments given
 $b = $a->bxorover; # method call
 $a->bxorover($b);

=for ref

Project via bitwise xor to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the bitwise xor along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*bxorover = \&PDL::bxorover;






=head2 firstnonzeroover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = firstnonzeroover($a);
 firstnonzeroover($a, $b);  # all arguments given
 $b = $a->firstnonzeroover; # method call
 $a->firstnonzeroover($b);

=for ref

Project via first non-zero value to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the first non-zero value along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*firstnonzeroover = \&PDL::firstnonzeroover;






=head2 orover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = orover($a);
 orover($a, $b);  # all arguments given
 $b = $a->orover; # method call
 $a->orover($b);

=for ref

Project via logical or to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the logical or along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*orover = \&PDL::orover;






=head2 xorover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = xorover($a);
 xorover($a, $b);  # all arguments given
 $b = $a->xorover; # method call
 $a->xorover($b);

=for ref

Project via logical xor to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the logical xor along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*xorover = \&PDL::xorover;






=head2 zcover

=for sig

 Signature: (a(n); [o] b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = zcover($a);
 zcover($a, $b);  # all arguments given
 $b = $a->zcover; # method call
 $a->zcover($b);

=for ref

Project via == 0 to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the == 0 along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data (and its bad flag is set),
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut




*zcover = \&PDL::zcover;






=head2 numdiff

=for sig

 Signature: (x(t); [o]dx(t))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $dx = numdiff($x);
 numdiff($x, $dx);     # all arguments given
 $dx = $x->numdiff;    # method call
 $x->numdiff($dx);
 $x->inplace->numdiff; # can be used inplace
 numdiff($x->inplace);

=for ref

Numerical differencing. DX(t) = X(t) - X(t-1), DX(0) = X(0).
Combined with C<slice('-1:0')>, can be used for backward differencing.

Unlike L</diff2>, output vector is same length.
Originally by Maggie J. Xiong.

Compare to L</cumusumover>, which acts as the converse of this.
See also L</diff2>, L</diffcentred>, L</partial>, L<PDL::Primitive/pchip_chim>.

=pod

Broadcasts over its inputs.

=for bad

C<numdiff> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*numdiff = \&PDL::numdiff;






=head2 diffcentred

=for sig

 Signature: (a(n); [o]o(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $o = diffcentred($a);
 diffcentred($a, $o);  # all arguments given
 $o = $a->diffcentred; # method call
 $a->diffcentred($o);

=for ref

Calculates centred differences along a vector's 0th dimension.
Always periodic on boundaries; currently to change this, you must
pad your data, and/or trim afterwards. This is so that when using
with L</partial>, the size of data stays the same and therefore
compatible if differentiated along different dimensions, e.g.
calculating "curl".

By using L<PDL::Slices/xchg> etc. it is possible to use I<any> dimension.

See also L</diff2>, L</partial>, L</numdiff>, L<PDL::Primitive/pchip_chim>.

=pod

Broadcasts over its inputs.

=for bad

A bad value at C<n> means the affected output values at C<n-2>,C<n>
(if in boounds) are set bad.

=cut




*diffcentred = \&PDL::diffcentred;





#line 248 "lib/PDL/Ufunc.pd"

=head2 partial

=for ref

Take a numerical partial derivative along a given dimension, either
forward, backward, or centred.

See also L</numdiff>, L</diffcentred>,
L<PDL::Primitive/pchip_chim>, L<PDL::Primitive/pchip_chsp>,
and L<PDL::Slices/mv>, which are currently used to implement this.

Can be used to implement divergence and curl calculations (adapted
from Luis Mochán's work at
https://sourceforge.net/p/pdl/mailman/message/58843767/):

  use v5.36;
  use PDL;
  sub curl ($f) {
    my ($f0, $f1, $f2) = $f->using(0..2);
    my $o = {dir=>'c'};
    pdl(
      $f2->partial(1,$o) - $f1->partial(2,$o),
      $f0->partial(2,$o) - $f2->partial(0,$o),
      $f1->partial(0,$o) - $f0->partial(1,$o),
    )->mv(-1,0);
  }
  sub div ($f) {
    my ($f0, $f1, $f2) = $f->using(0..2);
    my $o = {dir=>'c'};
    $f0->partial(0,$o) + $f1->partial(1,$o) + $f2->partial(2,$o);
  }
  sub trim3d ($f) { $f->slice(':,1:-2,1:-2,1:-2') } # adjust if change "dir"
  my $z=zeroes(5,5,5);
  my $v=pdl(-$z->yvals, $z->xvals, $z->zvals)->mv(-1,0);
  say trim3d(curl($v));
  say div($v);

=for usage

  $pdl->partial(2);           # along dim 2, centred
  $pdl->partial(2, {d=>'c'}); # along dim 2, centred
  $pdl->partial(2, {d=>'f'}); # along dim 2, forward
  $pdl->partial(2, {d=>'b'}); # along dim 2, backward
  $pdl->partial(2, {d=>'p'}); # along dim 2, piecewise cubic Hermite
  $pdl->partial(2, {d=>'s'}); # along dim 2, cubic spline

=cut

my %dirtype2func = (
  f => \&numdiff,
  b => sub { $_[0]->slice('-1:0')->numdiff },
  c => \&diffcentred,
  p => sub {(PDL::Primitive::pchip_chim($_[0]->xvals, $_[0]))[0]},
  s => sub {(PDL::Primitive::pchip_chsp([0,0], [0,0], $_[0]->xvals, $_[0]))[0]},
);
*partial = \&PDL::partial;
sub PDL::partial {
  my ($f, $dim, $opts) = @_;
  $opts ||= {};
  my $difftype = $opts->{dir} || $opts->{d} || 'c';
  my $func = $dirtype2func{$difftype} || barf "partial: unknown 'dir' option '$difftype', only know (@{[sort keys %dirtype2func]})";
  $f = $f->mv($dim, 0) if $dim;
  my $ret = $f->$func;
  $dim ? $ret->mv(0, $dim) : $ret;
}
#line 996 "lib/PDL/Ufunc.pm"


=head2 diff2

=for sig

 Signature: (a(n); [o]o(nminus1=CALC($SIZE(n) - 1)))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $o = diff2($a);
 diff2($a, $o);  # all arguments given
 $o = $a->diff2; # method call
 $a->diff2($o);

=for ref

Numerically forward differentiates a vector along 0th dimension.

By using L<PDL::Slices/xchg> etc. it is possible to use I<any> dimension.
Unlike L</numdiff>, output vector is one shorter.
Combined with C<slice('-1:0')>, can be used for backward differencing.

See also L</numdiff>, L</diffcentred>, L</partial>, L<PDL::Primitive/pchip_chim>.

=for example

  print pdl(q[3 4 2 3 2 3 1])->diff2;
  # [1 -2 1 -1 1 -2]

=pod

Broadcasts over its inputs.

=for bad

On bad value, output value is set bad. On next good value, output value
is difference between that and last good value.

=cut




*diff2 = \&PDL::diff2;






=head2 intover

=for sig

 Signature: (a(n); float+ [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = intover($a);
 intover($a, $b);  # all arguments given
 $b = $a->intover; # method call
 $a->intover($b);

=for ref

Project via integral to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the integral along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Notes:

C<intover> uses a point spacing of one (i.e., delta-h==1). You will
need to scale the result to correct for the true point delta.

For C<n E<gt> 3>, these are all C<O(h^4)> (like Simpson's rule), but are
integrals between the end points assuming the pdl gives values just at
these centres: for such `functions', sumover is correct to C<O(h)>, but
is the natural (and correct) choice for binned data, of course.

=pod

Broadcasts over its inputs.

=for bad

C<intover> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*intover = \&PDL::intover;






=head2 average

=for sig

 Signature: (a(n); int+ [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = average($a);
 average($a, $b);  # all arguments given
 $b = $a->average; # method call
 $a->average($b);

=for ref

Project via average to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the average along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

C<average> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*average = \&PDL::average;





#line 415 "lib/PDL/Ufunc.pd"

=head2 avgover

=for ref

Synonym for L</average>.

=cut

*PDL::avgover = *avgover = \&PDL::average;
#line 1162 "lib/PDL/Ufunc.pm"


=head2 caverage

=for sig

 Signature: (a(n); cdouble [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = caverage($a);
 caverage($a, $b);  # all arguments given
 $b = $a->caverage; # method call
 $a->caverage($b);

=for ref

Project via average to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the average along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Unlike L<average|/average>, the calculation is performed in complex double
precision.

=pod

Broadcasts over its inputs.

=for bad

C<caverage> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*caverage = \&PDL::caverage;





#line 415 "lib/PDL/Ufunc.pd"

=head2 cavgover

=for ref

Synonym for L</caverage>.

=cut

*PDL::cavgover = *cavgover = \&PDL::caverage;
#line 1224 "lib/PDL/Ufunc.pm"


=head2 daverage

=for sig

 Signature: (a(n); double [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = daverage($a);
 daverage($a, $b);  # all arguments given
 $b = $a->daverage; # method call
 $a->daverage($b);

=for ref

Project via average to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the average along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Unlike L<average|/average>, the calculation is performed in double
precision.

=pod

Broadcasts over its inputs.

=for bad

C<daverage> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*daverage = \&PDL::daverage;





#line 415 "lib/PDL/Ufunc.pd"

=head2 davgover

=for ref

Synonym for L</daverage>.

=cut

*PDL::davgover = *davgover = \&PDL::daverage;
#line 1286 "lib/PDL/Ufunc.pm"


=head2 minimum

=for sig

 Signature: (a(n); [o]c())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = minimum($a);
 minimum($a, $c);  # all arguments given
 $c = $a->minimum; # method call
 $a->minimum($c);

=for ref

Project via minimum to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the minimum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

Output is set bad if no elements of the input are non-bad,
otherwise the bad flag is cleared for the output ndarray.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut




*minimum = \&PDL::minimum;





#line 415 "lib/PDL/Ufunc.pd"

=head2 minover

=for ref

Synonym for L</minimum>.

=cut

*PDL::minover = *minover = \&PDL::minimum;
#line 1349 "lib/PDL/Ufunc.pm"


=head2 minimum_ind

=for sig

 Signature: (a(n); indx [o] c())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = minimum_ind($a);
 minimum_ind($a, $c);  # all arguments given
 $c = $a->minimum_ind; # method call
 $a->minimum_ind($c);

=for ref

Like minimum but returns the first matching index rather than the value

=pod

Broadcasts over its inputs.

=for bad

Output is set bad if no elements of the input are non-bad,
otherwise the bad flag is cleared for the output ndarray.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut




*minimum_ind = \&PDL::minimum_ind;





#line 415 "lib/PDL/Ufunc.pd"

=head2 minover_ind

=for ref

Synonym for L</minimum_ind>.

=cut

*PDL::minover_ind = *minover_ind = \&PDL::minimum_ind;
#line 1406 "lib/PDL/Ufunc.pm"


=head2 minimum_n_ind

=for sig

 Signature: (a(n); indx [o]c(m); PDL_Indx m_size => m)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for ref

Returns the index of first C<m_size> minimum elements. As of 2.077, you can
specify how many by either passing in an ndarray of the given size
(DEPRECATED - will be converted to indx if needed and the input arg will
be set to that), or just the size, or a null and the size.

=for usage

  minimum_n_ind($pdl, $out = zeroes(5)); # DEPRECATED
  $out = minimum_n_ind($pdl, 5);
  minimum_n_ind($pdl, $out = null, 5);

=pod

Broadcasts over its inputs.

=for bad

Output bad flag is cleared for the output ndarray if sufficient non-bad elements found,
else remaining slots in C<$c()> are set bad.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut





#line 515 "lib/PDL/Ufunc.pd"
sub PDL::minimum_n_ind {
  my ($a, $c, $m_size) = @_;
  $m_size //= ref($c) ? $c->dim(0) : $c; # back-compat with pre-2.077
  my $set_out = 1;
  $set_out = 0, $c = null if !ref $c;
  $c = $c->indx if !$c->isnull;
  PDL::_minimum_n_ind_int($a, $c, $m_size);
  $set_out ? $_[1] = $c : $c;
}
#line 1459 "lib/PDL/Ufunc.pm"

*minimum_n_ind = \&PDL::minimum_n_ind;





#line 415 "lib/PDL/Ufunc.pd"

=head2 minover_n_ind

=for ref

Synonym for L</minimum_n_ind>.

=cut

*PDL::minover_n_ind = *minover_n_ind = \&PDL::minimum_n_ind;
#line 1478 "lib/PDL/Ufunc.pm"


=head2 maximum

=for sig

 Signature: (a(n); [o]c())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = maximum($a);
 maximum($a, $c);  # all arguments given
 $c = $a->maximum; # method call
 $a->maximum($c);

=for ref

Project via maximum to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the maximum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

Output is set bad if no elements of the input are non-bad,
otherwise the bad flag is cleared for the output ndarray.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut




*maximum = \&PDL::maximum;





#line 415 "lib/PDL/Ufunc.pd"

=head2 maxover

=for ref

Synonym for L</maximum>.

=cut

*PDL::maxover = *maxover = \&PDL::maximum;
#line 1541 "lib/PDL/Ufunc.pm"


=head2 maximum_ind

=for sig

 Signature: (a(n); indx [o] c())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = maximum_ind($a);
 maximum_ind($a, $c);  # all arguments given
 $c = $a->maximum_ind; # method call
 $a->maximum_ind($c);

=for ref

Like maximum but returns the first matching index rather than the value

=pod

Broadcasts over its inputs.

=for bad

Output is set bad if no elements of the input are non-bad,
otherwise the bad flag is cleared for the output ndarray.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut




*maximum_ind = \&PDL::maximum_ind;





#line 415 "lib/PDL/Ufunc.pd"

=head2 maxover_ind

=for ref

Synonym for L</maximum_ind>.

=cut

*PDL::maxover_ind = *maxover_ind = \&PDL::maximum_ind;
#line 1598 "lib/PDL/Ufunc.pm"


=head2 maximum_n_ind

=for sig

 Signature: (a(n); indx [o]c(m); PDL_Indx m_size => m)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for ref

Returns the index of first C<m_size> maximum elements. As of 2.077, you can
specify how many by either passing in an ndarray of the given size
(DEPRECATED - will be converted to indx if needed and the input arg will
be set to that), or just the size, or a null and the size.

=for usage

  maximum_n_ind($pdl, $out = zeroes(5)); # DEPRECATED
  $out = maximum_n_ind($pdl, 5);
  maximum_n_ind($pdl, $out = null, 5);

=pod

Broadcasts over its inputs.

=for bad

Output bad flag is cleared for the output ndarray if sufficient non-bad elements found,
else remaining slots in C<$c()> are set bad.

Note that C<NaNs> are considered to be valid values and will "win" over non-C<NaN>;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Bad/badmask>
for ways of masking NaNs.

=cut





#line 515 "lib/PDL/Ufunc.pd"
sub PDL::maximum_n_ind {
  my ($a, $c, $m_size) = @_;
  $m_size //= ref($c) ? $c->dim(0) : $c; # back-compat with pre-2.077
  my $set_out = 1;
  $set_out = 0, $c = null if !ref $c;
  $c = $c->indx if !$c->isnull;
  PDL::_maximum_n_ind_int($a, $c, $m_size);
  $set_out ? $_[1] = $c : $c;
}
#line 1651 "lib/PDL/Ufunc.pm"

*maximum_n_ind = \&PDL::maximum_n_ind;





#line 415 "lib/PDL/Ufunc.pd"

=head2 maxover_n_ind

=for ref

Synonym for L</maximum_n_ind>.

=cut

*PDL::maxover_n_ind = *maxover_n_ind = \&PDL::maximum_n_ind;
#line 1670 "lib/PDL/Ufunc.pm"


=head2 minmaximum

=for sig

 Signature: (a(n); [o]cmin(); [o] cmax(); indx [o]cmin_ind(); indx [o]cmax_ind())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 ($cmin, $cmax, $cmin_ind, $cmax_ind) = minmaximum($a);
 minmaximum($a, $cmin, $cmax, $cmin_ind, $cmax_ind);    # all arguments given
 ($cmin, $cmax, $cmin_ind, $cmax_ind) = $a->minmaximum; # method call
 $a->minmaximum($cmin, $cmax, $cmin_ind, $cmax_ind);

=for ref

Find minimum and maximum and their indices for a given ndarray;

=for example

 pdl> $x=pdl [[-2,3,4],[1,0,3]]
 pdl> ($min, $max, $min_ind, $max_ind)=minmaximum($x)
 pdl> p $min, $max, $min_ind, $max_ind
 [-2 0] [4 3] [0 1] [2 2]

See also L</minmax>, which clumps the ndarray together.

=pod

Broadcasts over its inputs.

=for bad

If C<a()> contains only bad data, then the output ndarrays will
be set bad, along with their bad flag.
Otherwise they will have their bad flags cleared,
since they will not contain any bad values.

=cut




*minmaximum = \&PDL::minmaximum;





#line 415 "lib/PDL/Ufunc.pd"

=head2 minmaxover

=for ref

Synonym for L</minmaximum>.

=cut

*PDL::minmaxover = *minmaxover = \&PDL::minmaximum;

#line 648 "lib/PDL/Ufunc.pd"

=head2 avg

=for ref

Return the average of all elements in an ndarray.

See the documentation for L</average> for more information.

=for usage

 $x = avg($data);

=for bad

This routine handles bad values.

=cut

*avg = \&PDL::avg;
sub PDL::avg { $_[0]->flat->average }

#line 648 "lib/PDL/Ufunc.pd"

=head2 sum

=for ref

Return the sum of all elements in an ndarray.

See the documentation for L</sumover> for more information.

=for usage

 $x = sum($data);

=for bad

This routine handles bad values.

=cut

*sum = \&PDL::sum;
sub PDL::sum { $_[0]->flat->sumover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 prod

=for ref

Return the product of all elements in an ndarray.

See the documentation for L</prodover> for more information.

=for usage

 $x = prod($data);

=for bad

This routine handles bad values.

=cut

*prod = \&PDL::prod;
sub PDL::prod { $_[0]->flat->prodover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 davg

=for ref

Return the average (in double precision) of all elements in an ndarray.

See the documentation for L</daverage> for more information.

=for usage

 $x = davg($data);

=for bad

This routine handles bad values.

=cut

*davg = \&PDL::davg;
sub PDL::davg { $_[0]->flat->daverage }

#line 648 "lib/PDL/Ufunc.pd"

=head2 dsum

=for ref

Return the sum (in double precision) of all elements in an ndarray.

See the documentation for L</dsumover> for more information.

=for usage

 $x = dsum($data);

=for bad

This routine handles bad values.

=cut

*dsum = \&PDL::dsum;
sub PDL::dsum { $_[0]->flat->dsumover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 dprod

=for ref

Return the product (in double precision) of all elements in an ndarray.

See the documentation for L</dprodover> for more information.

=for usage

 $x = dprod($data);

=for bad

This routine handles bad values.

=cut

*dprod = \&PDL::dprod;
sub PDL::dprod { $_[0]->flat->dprodover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 zcheck

=for ref

Return the check for zero of all elements in an ndarray.

See the documentation for L</zcover> for more information.

=for usage

 $x = zcheck($data);

=for bad

This routine handles bad values.

=cut

*zcheck = \&PDL::zcheck;
sub PDL::zcheck { $_[0]->flat->zcover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 and

=for ref

Return the logical and of all elements in an ndarray.

See the documentation for L</andover> for more information.

=for usage

 $x = and($data);

=for bad

This routine handles bad values.

=cut

*and = \&PDL::and;
sub PDL::and { $_[0]->flat->andover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 band

=for ref

Return the bitwise and of all elements in an ndarray.

See the documentation for L</bandover> for more information.

=for usage

 $x = band($data);

=for bad

This routine handles bad values.

=cut

*band = \&PDL::band;
sub PDL::band { $_[0]->flat->bandover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 or

=for ref

Return the logical or of all elements in an ndarray.

See the documentation for L</orover> for more information.

=for usage

 $x = or($data);

=for bad

This routine handles bad values.

=cut

*or = \&PDL::or;
sub PDL::or { $_[0]->flat->orover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 bor

=for ref

Return the bitwise or of all elements in an ndarray.

See the documentation for L</borover> for more information.

=for usage

 $x = bor($data);

=for bad

This routine handles bad values.

=cut

*bor = \&PDL::bor;
sub PDL::bor { $_[0]->flat->borover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 xorall

=for ref

Return the logical xor of all elements in an ndarray.

See the documentation for L</xorover> for more information.

=for usage

 $x = xorall($data);

=for bad

This routine handles bad values.

=cut

*xorall = \&PDL::xorall;
sub PDL::xorall { $_[0]->flat->xorover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 bxor

=for ref

Return the bitwise xor of all elements in an ndarray.

See the documentation for L</bxorover> for more information.

=for usage

 $x = bxor($data);

=for bad

This routine handles bad values.

=cut

*bxor = \&PDL::bxor;
sub PDL::bxor { $_[0]->flat->bxorover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 min

=for ref

Return the minimum of all elements in an ndarray.

See the documentation for L</minimum> for more information.

=for usage

 $x = min($data);

=for bad

This routine handles bad values.

=cut

*min = \&PDL::min;
sub PDL::min { $_[0]->flat->minimum }

#line 648 "lib/PDL/Ufunc.pd"

=head2 max

=for ref

Return the maximum of all elements in an ndarray.

See the documentation for L</maximum> for more information.

=for usage

 $x = max($data);

=for bad

This routine handles bad values.

=cut

*max = \&PDL::max;
sub PDL::max { $_[0]->flat->maximum }

#line 648 "lib/PDL/Ufunc.pd"

=head2 median

=for ref

Return the median of all elements in an ndarray.

See the documentation for L</medover> for more information.

=for usage

 $x = median($data);

=for bad

This routine handles bad values.

=cut

*median = \&PDL::median;
sub PDL::median { $_[0]->flat->medover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 mode

=for ref

Return the mode of all elements in an ndarray.

See the documentation for L</modeover> for more information.

=for usage

 $x = mode($data);

=for bad

This routine handles bad values.

=cut

*mode = \&PDL::mode;
sub PDL::mode { $_[0]->flat->modeover }

#line 648 "lib/PDL/Ufunc.pd"

=head2 oddmedian

=for ref

Return the oddmedian of all elements in an ndarray.

See the documentation for L</oddmedover> for more information.

=for usage

 $x = oddmedian($data);

=for bad

This routine handles bad values.

=cut

*oddmedian = \&PDL::oddmedian;
sub PDL::oddmedian { $_[0]->flat->oddmedover }

#line 674 "lib/PDL/Ufunc.pd"

=head2 any

=for ref

Return true if any element in ndarray set

Useful in conditional expressions:

=for example

 if (any $x>15) { print "some values are greater than 15\n" }

=for bad

See L</or> for comments on what happens when all elements
in the check are bad.

=cut

*any = \&or;
*PDL::any = \&PDL::or;

=head2 all

=for ref

Return true if all elements in ndarray set

Useful in conditional expressions:

=for example

 if (all $x>15) { print "all values are greater than 15\n" }

=for bad

See L</and> for comments on what happens when all elements
in the check are bad.

=cut

*all = \&and;
*PDL::all = \&PDL::and;

=head2 minmax

=for ref

Returns a list with minimum and maximum values of an ndarray.

=for usage

 ($mn, $mx) = minmax($pdl);

This routine does I<not> broadcast over the dimensions of C<$pdl>;
it returns the minimum and maximum values of the whole ndarray.
See L</minmaximum> if this is not what is required.
The two values are returned as Perl scalars,
and therefore ignore whether the values are bad.

=for example

 pdl> $x = pdl [1,-2,3,5,0]
 pdl> ($min, $max) = minmax($x);
 pdl> p "$min $max\n";
 -2 5

=cut

*minmax = \&PDL::minmax;
sub PDL::minmax { map $_->sclr, ($_[0]->flat->minmaximum)[0,1] }
#line 2222 "lib/PDL/Ufunc.pm"


=head2 medover

=for sig

 Signature: (a(n); [o]b(); [t]tmp(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = medover($a);
 medover($a, $b);  # all arguments given
 $b = $a->medover; # method call
 $a->medover($b);

=for ref

Project via median to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the median along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=pod

Broadcasts over its inputs.

=for bad

C<medover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*medover = \&PDL::medover;






=head2 oddmedover

=for sig

 Signature: (a(n); [o]b(); [t]tmp(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = oddmedover($a);
 oddmedover($a, $b);  # all arguments given
 $b = $a->oddmedover; # method call
 $a->oddmedover($b);

=for ref

Project via oddmedian to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the oddmedian along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The median is sometimes not a good choice as if the array has
an even number of elements it lies half-way between the two
middle values - thus it does not always correspond to a data
value. The lower-odd median is just the lower of these two values
and so it ALWAYS sits on an actual data value which is useful in
some circumstances.
	

=pod

Broadcasts over its inputs.

=for bad

C<oddmedover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*oddmedover = \&PDL::oddmedover;






=head2 modeover

=for sig

 Signature: (data(n); [o]out(); [t]sorted(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $out = modeover($data);
 modeover($data, $out);  # all arguments given
 $out = $data->modeover; # method call
 $data->modeover($out);

=for ref

Project via mode to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the mode along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The mode is the single element most frequently found in a
discrete data set.

It I<only> makes sense for integer data types, since
floating-point types are demoted to integer before the
mode is calculated.

C<modeover> treats BAD the same as any other value:  if
BAD is the most common element, the returned value is also BAD.

=pod

Broadcasts over its inputs.

=for bad

C<modeover> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*modeover = \&PDL::modeover;






=head2 pctover

=for sig

 Signature: (a(n); p(); [o]b(); [t]tmp(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = pctover($a, $p);
 pctover($a, $p, $b);  # all arguments given
 $b = $a->pctover($p); # method call
 $a->pctover($p, $b);

=for ref

Project via specified percentile to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the specified percentile along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The specified
percentile must be between 0.0 and 1.0.  When the specified percentile
falls between data points, the result is interpolated.  Values outside
the allowed range are clipped to 0.0 or 1.0 respectively.  The algorithm
implemented here is based on the interpolation variant described at
L<http://en.wikipedia.org/wiki/Percentile> as used by Microsoft Excel
and recommended by NIST.

=pod

Broadcasts over its inputs.

=for bad

C<pctover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pctover = \&PDL::pctover;






=head2 oddpctover

=for sig

 Signature: (a(n); p(); [o]b(); [t]tmp(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = oddpctover($a, $p);
 oddpctover($a, $p, $b);  # all arguments given
 $b = $a->oddpctover($p); # method call
 $a->oddpctover($p, $b);

=for ref

Project via specified percentile to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the specified percentile along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The specified
percentile must be between 0.0 and 1.0.  When the specified percentile
falls between two values, the nearest data value is the result.
The algorithm implemented is from the textbook version described
first at L<http://en.wikipedia.org/wiki/Percentile>.

=pod

Broadcasts over its inputs.

=for bad

C<oddpctover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*oddpctover = \&PDL::oddpctover;





#line 1022 "lib/PDL/Ufunc.pd"

=head2 pct

=for ref

Return the specified percentile of all elements in an ndarray. The
specified percentile (p) must be between 0.0 and 1.0.  When the
specified percentile falls between data points, the result is interpolated.

=for usage

 $x = pct($data, $pct);

=cut

*pct = \&PDL::pct;
sub PDL::pct {
	my($x, $p) = @_;
	$x->flat->pctover($p, my $tmp=PDL->nullcreate($x));
	$tmp;
}

#line 1022 "lib/PDL/Ufunc.pd"

=head2 oddpct

=for ref

Return the specified percentile of all elements in an ndarray. The
specified percentile (p) must be between 0.0 and 1.0.  When the
specified percentile falls between data points, the nearest data value is the result.

=for usage

 $x = oddpct($data, $pct);

=cut

*oddpct = \&PDL::oddpct;
sub PDL::oddpct {
	my($x, $p) = @_;
	$x->flat->oddpctover($p, my $tmp=PDL->nullcreate($x));
	$tmp;
}
#line 2530 "lib/PDL/Ufunc.pm"


=head2 qsort

=for sig

 Signature: (!complex a(n); !complex [o]b(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = qsort($a);
 qsort($a, $b);      # all arguments given
 $b = $a->qsort;     # method call
 $a->qsort($b);
 $a->inplace->qsort; # can be used inplace
 qsort($a->inplace);

=for ref

Quicksort a vector into ascending order.

=pod

Broadcasts over its inputs.

=for bad

Bad values are moved to the end of the array:

 pdl> p $y
 [42 47 98 BAD 22 96 74 41 79 76 96 BAD 32 76 25 59 BAD 96 32 BAD]
 pdl> p qsort($y)
 [22 25 32 32 41 42 47 59 74 76 76 79 96 96 96 98 BAD BAD BAD BAD]

=cut




*qsort = \&PDL::qsort;






=head2 qsorti

=for sig

 Signature: (!complex a(n); indx [o]indx(n))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $indx = qsorti($a);
 qsorti($a, $indx);  # all arguments given
 $indx = $a->qsorti; # method call
 $a->qsorti($indx);

=for ref

Quicksort a vector and return index of elements in ascending order.

=for example

 $ix = qsorti $x;
 print $x->index($ix); # Sorted list

=pod

Broadcasts over its inputs.

=for bad

Bad elements are moved to the end of the array:

 pdl> p $y
 [42 47 98 BAD 22 96 74 41 79 76 96 BAD 32 76 25 59 BAD 96 32 BAD]
 pdl> p $y->index( qsorti($y) )
 [22 25 32 32 41 42 47 59 74 76 76 79 96 96 96 98 BAD BAD BAD BAD]

=cut




*qsorti = \&PDL::qsorti;






=head2 qsortvec

=for sig

 Signature: (!complex a(n,m); !complex [o]b(n,m))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = qsortvec($a);
 qsortvec($a, $b);      # all arguments given
 $b = $a->qsortvec;     # method call
 $a->qsortvec($b);
 $a->inplace->qsortvec; # can be used inplace
 qsortvec($a->inplace);

=for ref

Sort a list of vectors lexicographically.

The 0th dimension of the source ndarray is dimension in the vector;
the 1st dimension is list order.  Higher dimensions are broadcasted over.

=for example

 print qsortvec pdl([[1,2],[0,500],[2,3],[4,2],[3,4],[3,5]]);
 [
  [  0 500]
  [  1   2]
  [  2   3]
  [  3   4]
  [  3   5]
  [  4   2]
 ]

=pod

Broadcasts over its inputs.

=for bad

Vectors with bad components are moved to the end of the array:

  pdl> p $p = pdl("[0 0] [-100 0] [BAD 0] [100 0]")->qsortvec

  [
   [-100    0]
   [   0    0]
   [ 100    0]
   [ BAD    0]
  ]

=cut




*qsortvec = \&PDL::qsortvec;






=head2 qsortveci

=for sig

 Signature: (!complex a(n,m); indx [o]indx(m))
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $indx = qsortveci($a);
 qsortveci($a, $indx);  # all arguments given
 $indx = $a->qsortveci; # method call
 $a->qsortveci($indx);

=for ref

Sort a list of vectors lexicographically, returning the indices of the
sorted vectors rather than the sorted list itself.

As with C<qsortvec>, the input PDL should be an NxM array containing M
separate N-dimensional vectors.  The return value is an integer M-PDL
containing the M-indices of original array rows, in sorted order.

As with C<qsortvec>, the zeroth element of the vectors runs slowest in the
sorted list.

Additional dimensions are broadcasted over: each plane is sorted separately,
so qsortveci may be thought of as a collapse operator of sorts (groan).

=pod

Broadcasts over its inputs.

=for bad

Vectors with bad components are moved to the end of the array as
for L</qsortvec>.

=cut




*qsortveci = \&PDL::qsortveci;






=head2 magnover

=for sig

 Signature: (a(n); float+ [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = magnover($a);
 magnover($a, $b);  # all arguments given
 $b = $a->magnover; # method call
 $a->magnover($b);

=for ref

Project via Euclidean (aka Pythagorean) distance to N-1 dimensions

This function reduces the dimensionality of an ndarray
by one by taking the Euclidean (aka Pythagorean) distance along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

Minimum C<float> precision output.
See also L<PDL::Primitive/inner>, L<PDL::Primitive/norm>.

=pod

Broadcasts over its inputs.

=for bad

C<magnover> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*magnover = \&PDL::magnover;







#line 1266 "lib/PDL/Ufunc.pd"

=head1 AUTHOR

Copyright (C) Tuomas J. Lukka 1997 (lukka@husc.harvard.edu).
Contributions by Christian Soeller (c.soeller@auckland.ac.nz)
and Karl Glazebrook (kgb@aaoepp.aao.gov.au).  All rights
reserved. There is no warranty. You are allowed to redistribute this
software / documentation under certain conditions. For details, see
the file COPYING in the PDL distribution. If this file is separated
from the PDL distribution, the copyright notice should be included in
the file.

=cut
#line 2808 "lib/PDL/Ufunc.pm"

# Exit with OK status

1;
