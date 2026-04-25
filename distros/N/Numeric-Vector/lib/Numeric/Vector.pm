package Numeric::Vector;

use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Numeric::Vector', $VERSION);

sub import {
    my $class = shift;
    return unless @_;
    _nvec_install(scalar caller, @_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Numeric::Vector - SIMD-accelerated numeric vectors

=head1 SYNOPSIS

    # OO interface
    use Numeric::Vector;

    my $v = Numeric::Vector::new([1..8]);
    my $w = Numeric::Vector::ones(8);

    my $sum  = $v->sum;
    my $dot  = $v->dot($w);
    my $norm = $v->norm;

    my $added  = $v->add($w);    # or $v + $w
    my $scaled = $v->scale(2.5); # or $v * 2.5

    $v->add_inplace($w);         # $v += $w  in-place

    print $v->simd_info, "\n";

    # Functional interface — import specific functions as nvec_*
    use Numeric::Vector qw(new ones sum add dot);

    my $v = nvec_new([1..8]);
    my $w = nvec_ones(8);
    my $s = nvec_sum($v);
    my $r = nvec_add($v, $w);

=head1 DESCRIPTION

Numeric::Vector provides SIMD-accelerated numeric vectors for Perl. It
automatically selects the best available instruction set at compile time:
ARM NEON, x86 AVX2, AVX, SSE2, or a plain scalar fallback. All vectors
store C<double>-precision (64-bit) floating-point values.

Overloaded operators (C<+>, C<->, C<*>, C</>), in-place variants
(C<+=>, C<-=>, C<*=>, C</=>), unary negation, C<abs>, and string
interpolation are all supported.

=head1 IMPORTING

By default C<use Numeric::Vector> exports nothing. Pass a list of method
names to import them as C<nvec_*> functions into the current package:

    use Numeric::Vector qw(new zeros ones fill sum mean add mul scale dot norm);

    my $v = nvec_new([1..1000]);
    my $w = nvec_zeros(1000);
    nvec_add($v, $w);       # same as $v->add($w)
    my $s = nvec_sum($v);   # same as $v->sum

Every name in the import list corresponds to an existing method. Requesting
an unknown name is a compile-time error:

    use Numeric::Vector qw(frobnicate);  # dies: unknown function 'frobnicate'

The import mechanism is implemented entirely in XS and installs true
subroutine aliases (not wrappers), so there is no call overhead beyond the
XS dispatch that would occur anyway.

=head1 CONSTRUCTORS

=head2 new

    my $v = Numeric::Vector::new(\@array);

Create a vector from an arrayref of numbers.

=head2 zeros

    my $v = Numeric::Vector::zeros($n);

Create a vector of C<$n> zeros.

=head2 ones

    my $v = Numeric::Vector::ones($n);

Create a vector of C<$n> ones.

=head2 fill

    my $v = Numeric::Vector::fill($n, $value);

Create a vector of C<$n> elements all set to C<$value>.

=head2 range

    my $v = Numeric::Vector::range($start, $stop);
    my $v = Numeric::Vector::range($start, $stop, $step);

Create a vector of evenly-spaced values from C<$start> up to (but not
including) C<$stop>, advancing by C<$step> (default 1).

=head2 linspace

    my $v = Numeric::Vector::linspace($start, $stop, $n);

Create a vector of C<$n> evenly-spaced values between C<$start> and
C<$stop> inclusive.

=head2 random

    my $v = Numeric::Vector::random($n);

Create a vector of C<$n> uniform random values in [0, 1).

=head1 ELEMENT ACCESS

=head2 get

    my $val = $v->get($index);

Return the element at C<$index>. Croaks if out of bounds.

=head2 set

    $v->set($index, $value);

Set the element at C<$index> to C<$value>. Croaks if out of bounds or
if the vector is read-only.

=head2 len

    my $n = $v->len;

Return the number of elements.

=head2 to_array

    my $aref = $v->to_array;

Return a new Perl arrayref containing all elements.

=head2 copy

    my $w = $v->copy;

Return a deep copy of the vector.

=head2 slice

    my $w = $v->slice($from, $to);

Return a new vector containing elements at indices C<$from> through
C<$to> inclusive.

=head2 fill_range

    $v->fill_range($start, $len, $value);

Set C<$len> consecutive elements starting at C<$start> to C<$value>.
Negative C<$start> counts from the end. Modifies in-place.

=head1 ARITHMETIC

All arithmetic methods return a new vector and leave the original
unchanged unless the method name ends in C<_inplace>.

=head2 add

    my $c = $a->add($b);   # or  $a + $b

Element-wise addition. Vectors must have the same length.

=head2 sub

    my $c = $a->sub($b);   # or  $a - $b

Element-wise subtraction. Vectors must have the same length.

=head2 mul

    my $c = $a->mul($b);   # or  $a * $b  (vector * vector)

Element-wise multiplication. Vectors must have the same length.

=head2 div

    my $c = $a->div($b);   # or  $a / $b

Element-wise division. Vectors must have the same length.

=head2 scale

    my $c = $v->scale($scalar);   # or  $v * $scalar

Multiply every element by C<$scalar>.

=head2 add_scalar

    my $c = $v->add_scalar($scalar);

Add C<$scalar> to every element.

=head2 pow

    my $c = $v->pow($exp);

Raise every element to the power C<$exp>.

=head2 neg

    my $c = $v->neg;   # or  -$v

Negate every element.

=head2 abs

    my $c = $v->abs;   # or  abs($v)

Absolute value of every element.

=head2 axpy

    $y->axpy($a, $x);   # y = a*x + y  (in-place)

Scale C<$x> by the scalar C<$a> and add to C<$y> in-place (classic
BLAS DAXPY operation). C<$x> and C<$y> must have the same length.

=head1 IN-PLACE ARITHMETIC

These methods mutate the vector and return C<$self>.

=head2 add_inplace

    $a->add_inplace($b);   # or  $a += $b

Element-wise addition in-place.

=head2 sub_inplace

    $a->sub_inplace($b);   # or  $a -= $b

Element-wise subtraction in-place.

=head2 mul_inplace

    $a->mul_inplace($b);   # or  $a *= $b  (vector * vector)

Element-wise multiplication in-place.

=head2 div_inplace

    $a->div_inplace($b);   # or  $a /= $b

Element-wise division in-place.

=head2 scale_inplace

    $v->scale_inplace($scalar);   # or  $v *= $scalar

Multiply every element by C<$scalar> in-place.

=head2 add_scalar_inplace

    $v->add_scalar_inplace($scalar);

Add C<$scalar> to every element in-place.

=head2 clamp_inplace

    $v->clamp_inplace($min, $max);

Clamp every element to [C<$min>, C<$max>] in-place.

=head2 fma_inplace

    $c->fma_inplace($a, $b);   # c = a*b + c  (in-place)

Fused multiply-add: multiply corresponding elements of C<$a> and C<$b>
and add the result to C<$c> in-place. All three vectors must have the
same length.

=head1 MATH FUNCTIONS

Each method returns a new vector with the function applied element-wise.

=head2 sqrt

    my $c = $v->sqrt;

=head2 exp

    my $c = $v->exp;

=head2 log

    my $c = $v->log;

Natural logarithm.

=head2 log10

    my $c = $v->log10;

=head2 log2

    my $c = $v->log2;

=head2 floor

    my $c = $v->floor;

=head2 ceil

    my $c = $v->ceil;

=head2 round

    my $c = $v->round;

Round to the nearest integer (half-up).

=head2 sign

    my $c = $v->sign;

Returns -1.0, 0.0, or 1.0 for each element.

=head2 clip

    my $c = $v->clip($min, $max);

Return a new vector with each element clamped to [C<$min>, C<$max>].

=head1 TRIGONOMETRY

=head2 sin

    my $c = $v->sin;

=head2 cos

    my $c = $v->cos;

=head2 tan

    my $c = $v->tan;

=head2 asin

    my $c = $v->asin;

=head2 acos

    my $c = $v->acos;

=head2 atan

    my $c = $v->atan;

=head2 sinh

    my $c = $v->sinh;

=head2 cosh

    my $c = $v->cosh;

=head2 tanh

    my $c = $v->tanh;

=head1 REDUCTIONS

=head2 sum

    my $s = $v->sum;

Sum of all elements.

=head2 product

    my $p = $v->product;

Product of all elements.

=head2 mean

    my $m = $v->mean;

Arithmetic mean.

=head2 variance

    my $var = $v->variance;

Population variance (divides by N).

=head2 std

    my $sd = $v->std;

Population standard deviation (square root of variance).

=head2 median

    my $med = $v->median;

Median value. Does not modify the vector.

=head2 min

    my $m = $v->min;

Minimum element value.

=head2 max

    my $m = $v->max;

Maximum element value.

=head2 argmin

    my $idx = $v->argmin;

Index of the minimum element.

=head2 argmax

    my $idx = $v->argmax;

Index of the maximum element.

=head2 dot

    my $d = $a->dot($b);

Dot (inner) product. Vectors must have the same length.

=head2 norm

    my $n = $v->norm;

L2 (Euclidean) norm: C<sqrt(sum(x_i^2))>.

=head2 normalize

    my $u = $v->normalize;

Return a unit vector (L2 norm = 1). Returns a zero vector if the norm
is zero.

=head2 distance

    my $d = $a->distance($b);

Euclidean distance between two vectors. Vectors must have the same length.

=head2 cosine_similarity

    my $sim = $a->cosine_similarity($b);

Cosine similarity in [-1, 1]. Returns 0 if either vector has zero norm.
Vectors must have the same length.

=head1 COMPARISONS

Each method returns a new vector of 0.0/1.0 values.

=head2 eq

    my $mask = $a->eq($b);

Element-wise C<==>. Returns 1.0 where equal, 0.0 elsewhere.

=head2 ne

    my $mask = $a->ne($b);

Element-wise C<!=>. Returns 1.0 where not equal.

=head2 lt

    my $mask = $a->lt($b);

Element-wise C<< < >>.

=head2 le

    my $mask = $a->le($b);

Element-wise C<< <= >>.

=head2 gt

    my $mask = $a->gt($b);

Element-wise C<< > >>.

=head2 ge

    my $mask = $a->ge($b);

Element-wise C<< >= >>.

=head1 BOOLEAN REDUCTIONS

=head2 any

    my $bool = $v->any;

Returns true if any element is non-zero.

=head2 all

    my $bool = $v->all;

Returns true if all elements are non-zero.

=head2 count

    my $n = $v->count;

Count of non-zero elements.

=head1 PREDICATES

=head2 isnan

    my $mask = $v->isnan;

Returns a vector of 1.0 where the element is NaN, 0.0 elsewhere.

=head2 isinf

    my $mask = $v->isinf;

Returns a vector of 1.0 where the element is infinite, 0.0 elsewhere.

=head2 isfinite

    my $mask = $v->isfinite;

Returns a vector of 1.0 where the element is finite (not NaN or Inf),
0.0 elsewhere.

=head1 SELECTION AND TRANSFORMATION

=head2 where

    my $w = $v->where($mask);

Return a new vector containing only the elements of C<$v> where the
corresponding element of C<$mask> is non-zero.

=head2 concat

    my $w = $a->concat($b);

Return a new vector that is the concatenation of C<$a> and C<$b>.

=head2 reverse

    my $w = $v->reverse;

Return a new vector with elements in reverse order.

=head2 sort

    my $w = $v->sort;

Return a new vector with elements sorted in ascending order.

=head2 argsort

    my $idx = $v->argsort;

Return a vector of indices that would sort the vector in ascending order.

=head2 cumsum

    my $w = $v->cumsum;

Return a new vector of cumulative sums.

=head2 cumprod

    my $w = $v->cumprod;

Return a new vector of cumulative products.

=head2 diff

    my $w = $v->diff;

Return a new vector of first differences (C<v[i+1] - v[i]>). The
result has length C<len - 1>; returns an empty vector if C<len < 2>.

=head1 DIAGNOSTICS

=head2 simd_info

    print $v->simd_info;

Returns a string describing the SIMD instruction set compiled in
(e.g. C<"AVX2">, C<"NEON">, C<"scalar">).

=head1 OVERLOADED OPERATORS

    $a + $b      # add (vector+vector or vector+scalar)
    $a - $b      # sub
    $a * $b      # mul (vector*vector or vector*scalar)
    $a / $b      # div
    $a += $b     # add_inplace
    $a -= $b     # sub_inplace
    $a *= $b     # mul_inplace
    $a /= $b     # div_inplace
    -$v          # neg
    abs($v)      # abs
    "$v"         # stringify (space-separated values)
    $a == $b     # true if all elements equal (scalar bool)
    $a != $b     # true if any elements differ (scalar bool)

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION.

This software is licensed under the Artistic License 2.0.

=cut
