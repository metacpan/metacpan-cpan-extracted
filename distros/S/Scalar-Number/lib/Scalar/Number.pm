=head1 NAME

Scalar::Number - numeric aspects of scalars

=head1 SYNOPSIS

	use Scalar::Number qw(scalar_num_part);

	$num = scalar_num_part($scalar);

	use Scalar::Number qw(sclnum_is_natint sclnum_is_float);

	if(sclnum_is_natint($value)) { ...
	if(sclnum_is_float($value)) { ...

	use Scalar::Number qw(sclnum_val_cmp sclnum_id_cmp);

	@sorted_nums = sort { sclnum_val_cmp($a, $b) } @floats;
	@sorted_nums = sort { sclnum_id_cmp($a, $b) } @floats;

=head1 DESCRIPTION

This module is about the numeric part of plain (string) Perl scalars.
A scalar has a numeric value, which may be expressed in either the
native integer type or the native floating point type.  Many values
are expressible both ways, in which case the exact representation is
insignificant.  To fully understand Perl arithmetic it is necessary to
know about both of these representations, and the differing behaviours
of numbers according to which way they are expressible.

This module provides functions to extract the numeric part of a scalar,
classify a number by expressibility, and compare numbers across
representations.

This module is implemented in XS, with a pure Perl backup version for
systems that can't handle XS.

=cut

package Scalar::Number;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.006";

use parent "Exporter";
our @EXPORT_OK = qw(
	scalar_num_part
	sclnum_is_natint sclnum_is_float
	sclnum_val_cmp sclnum_id_cmp
);

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
};

if($@ eq "") {
	close(DATA);
	*scalar_num_part = sub($) {
		no warnings qw(numeric uninitialized);
		return _warnable_scalar_num_part($_[0]);
	};
} else {
	local $/ = undef;
	my $pp_code = <DATA>;
	close(DATA);
	{
		local $SIG{__DIE__};
		eval $pp_code;
	}
	die $@ if $@ ne "";
}

1;

__DATA__

use Carp qw(croak);
use Data::Float 0.008 qw(
	have_signed_zero significand_bits max_integer
	float_is_infinite pow2 mult_pow2
);
use Data::Integer 0.003 qw(natint_bits min_natint max_natint hex_natint);
use overload ();

BEGIN {
	# In perl 5.6, arithmetic is performed in floating point by default,
	# even if the arguments are native integers that lose precision upon
	# conversion to float.  If there are such native integers then these
	# semantics make it impossible in some cases to tell the difference
	# between an integer and a nearby floating point value.  Specifically,
	# the maximum integer and its float approximation (which has a
	# numeric value 1 higher) are indistinguishable.  In that case, this
	# module cannot be implemented in pure Perl.  Detect that here by
	# max_natint-2 appearing to be even.  (perl 5.6.0 has even more messed
	# up arithmetic, such that max_natint%2 misleadingly gives the result
	# 1.)
	if((max_natint-2) % 2 != 1) {
		die "Scalar::Number cannot operate in pure Perl due to there ".
			"being native integer values not exactly ".
			"representable as native floats combined with ".
			"uncooperative numeric semantics";
	}
	# With that case excluded, it is guaranteed that default arithmetic
	# will operate correctly on all native integer values when performing
	# operations within the native integer range.  The correctness is
	# either due to perl 5.8+ numeric semantics, which perform such
	# operations in native integer arithmetic, or due to all native
	# integers being losslessly representable in floating point.
}

# Floating point constants arount max_natint: high_max has the value
# max_natint+1, and low_max is the next lower floating point value.
# reduced_high_max is the difference between them.  These are only
# valid if there are native integers that are not representable in
# floating point.  In other cases they have unpredictable values and
# are not used.
#
# Note: bug in Perl (bug in v5.8.8, bug ID #41288): floating point values
# in the high positive part of the native integer range don't necessarily
# get translated to native integers for integer operations as they're
# supposed to.  Therefore it is vital that low_max below is defined using
# integer arithmetic.

use constant high_max => pow2(natint_bits);
use constant low_max => ((1 << (natint_bits-1)) -
			 (1 << (natint_bits - (significand_bits+1)))) +
			(1 << (natint_bits-1));
use constant reduced_high_max => 1 << (natint_bits - (significand_bits+1));

BEGIN {
	# We need the refaddr() function from Scalar::Util.  However, if
	# Scalar::Util isn't available then we can reimplement it less
	# efficiently.
	eval { local $SIG{__DIE__}; require Scalar::Util; };
	if($@ eq "") {
		*_refaddr = \&Scalar::Util::refaddr;
	} else {
		*_refaddr = sub($) {
			overload::StrVal($_[0]) =~ /0x([0-9a-f]+)\)\z/
				or die "don't understand StrVal output";
			return hex_natint($1);
		};
	}
}

=head1 FUNCTIONS

Each "sclnum_" function takes one or more scalar numeric arguments
to operate on.  These arguments must be numeric; giving non-numeric
arguments will cause mayhem.  See L<Params::Classify/is_number> for a way
to check for numericness.  Only the numeric value of the scalar is used;
the string value is completely ignored, so dualvars are not a problem.

=head2 Decomposition

=over

=item scalar_num_part(SCALAR)

Extracts the numeric value of SCALAR, and returns it as a pure numeric
scalar.  The argument is permitted to be any scalar.

Every scalar has both a string value and a numeric value.  In pure string
scalars, those resulting from string literals or string operations,
the numeric value is determined from the string value.  In pure numeric
scalars, those resulting from numeric literals or numeric operations,
the string value is determined from the numeric value.  In the general
case, however, a plain scalar's string and numeric values may be
set independently, which is known as a dualvar.  Non-plain scalars,
principally references, determine their string and numeric values in other
ways, and in particular a reference to a blessed object can stringify
and numerify however the class wishes.

This function does not warn if given an ostensibly non-numeric argument,
because the whole point of it is to extract the numeric value of scalars
that are not pure numeric.

=cut

my %zero = (
	"+0+0" => 0,
	"+0-0" => +0.0,
	"-0+0" => -0.0,
);
sub scalar_num_part($) {
	my($val) = @_;
	no warnings qw(numeric uninitialized);
	while(ref($val) ne "") {
		my $meth = overload::Method($val, "0+");
		return _refaddr($val) unless defined $meth;
		my $newval = eval { local $SIG{__DIE__};
			$meth->($val, undef, "");
		};
		if($@ ne "" || (ref($newval) ne "" &&
				_refaddr($newval) == _refaddr($val))) {
			return _refaddr($val);
		}
		$val = $newval;
	}
	if(have_signed_zero && (my $tval = $val) == 0) {
		if(!defined($val) || ref(\$val) eq "GLOB") {
			$val = 0.0;
		} elsif(do {
			my $warned;
			local $SIG{__WARN__} = sub { $warned = 1; };
			use warnings qw(numeric uninitialized);
			no warnings "void";
			0 + (my $tval = $val);
			$warned;
		}) {
			$val = "0";
		}
		return my $zero = $zero{sprintf("%+.f%+.f", $val, -$val)};
	} else {
		return 0 + $val;
	}
}

=back

=head2 Classification

=over

=item sclnum_is_natint(VALUE)

Returns a truth value indicating whether the provided VALUE can be represented
in the native integer data type.  If the floating point type includes
signed zeroes then they do not qualify; the only zero representable in
the integer type is unsigned.

=cut

sub sclnum_is_natint($) {
	my($val) = @_;
	if(have_signed_zero && $val == 0) {
		$val = $_[0];
		return sprintf("%+.f%+.f", $val, -$val) eq "+0+0";
	} elsif(int($val) != $val) {
		return 0;
	} elsif(significand_bits+1 >= natint_bits) {
		# all native integers are representable as floats, so
		# straight comparison against max_natint works
		return $val >= min_natint && $val <= max_natint;
	} else {
		# Some native integers can't be exactly represented as
		# floats, so naive comparisons will cause lossy
		# conversions.  min_natint, being the negation of a power
		# of two, can be represented correctly as a float, but
		# max_natint cannot.  We have two float constants, low_max
		# and high_max, which are the adjacent representable
		# values bracketing the value of max_natint.  A value
		# below low_max compares so, and so is easily accepted.
		# A float that is above high_max compares so, and so is
		# easily rejected.
		#
		# What remains is the float values low_max and high_max
		# themselves, and all the integers in the range [low_max,
		# high_max).  The only one of these values that is to be
		# rejected is high_max itself, but it can't be directly
		# detected because any of the integers except for low_max
		# might convert to high_max when floated for comparison.
		# The solution is to subtract out low_max, leaving much
		# smaller values that are all exactly representable as
		# integers.  high_max can then be correctly detected.
		return $val >= min_natint &&
			($val < low_max ||
			 ($val <= high_max &&
			  $val - low_max != reduced_high_max));
	}
}

=item sclnum_is_float(VALUE)

Returns a truth value indicating whether the provided VALUE can be represented
in the native floating point data type.  If the floating point type
includes signed zeroes then an unsigned zero (from the native integer
type) does not qualify.

=cut

sub sclnum_is_float($) {
	my($val) = @_;
	if(have_signed_zero && $val == 0.0) {
		$val = $_[0];
		return sprintf("%+.f%+.f", $val, -$val) ne "+0+0";
	} elsif(int($val) != $val || float_is_infinite($val)) {
		return 1;
	} elsif(significand_bits+1 >= natint_bits) {
		# all native integers are representable as floats
		# (except possibly zero, handled above)
		return 1;
	} else {
		# any integer within the continuous integer range of the
		# float type is a float
		return 1 if $val >= -max_integer() && $val <= max_integer;
		# Anything outside the native integer range is trivially
		# a float.  We can't reliably detect the upper end of this
		# range, because max_natint isn't representable as a
		# float, so compare against the representable high_max.
		return 1 if $val < min_natint || $val > high_max;
		# What remains is an integer that is either high_max or
		# representable as a native integer.  Whether it is a
		# float depends on the length of its binary representation.
		if($val > low_max) {
			# Might be high_max, so we can't use integer
			# arithmetic on it directly.  Shift it down one
			# bit so that we definitely can.  If the bit we
			# lose is set then it's definitely not a float.
			$val -= (1 << (natint_bits-1));
			return 0 if ($val & 1);
			$val = ($val >> 1) + (1 << (natint_bits-2));
		} else {
			$val = abs($val);
		}
		while($val >= (1 << (significand_bits+1))) {
			return 0 if ($val & 1);
			$val >>= 1;
		}
		return 1;
	}
}

=back

=head2 Comparison

=over

=item sclnum_val_cmp(A, B)

Numerically compares the values A and B.  Integer and floating point
values are compared correctly with each other, even if there is no
available format in which both values can be accurately represented.
Returns -1, 0, +1, or undef, indicating whether A is less than, equal
to, greater than, or not comparable with B.  The "not comparable"
situation arises if either value is a floating point NaN (not-a-number).
All flavours of zero compare equal.

This is very similar to Perl's built-in <=> operator.  The only difference
is the capability to compare integer against floating point (where neither
can be represented exactly in the other's format).  <=> performs such
comparisons in floating point, losing accuracy of the integer value.

=cut

sub sclnum_val_cmp($$) {
	my($a, $b) = @_;
	# Due to perl bug #41202, a text->float conversion sometimes
	# gives the wrong answer, but if a text->integer conversion is
	# done first then a later integer->float conversion can give a
	# more accurate answer.  Here we trigger such text->integer
	# conversions, in the situations where it is useful.
	{
		no warnings "void";
		0 + $a;
		0 + $b;
	}
	# Comparison between an integer and a float might be lossy.
	# Specifically, it could show values as equal when they're
	# not.  It can never show equal values as unequal, or give
	# the opposite of the correct order.  So first do the basic
	# comparison, and perform further analysis only if that
	# shows equality and integer->float conversion is in fact
	# lossy.
	my $cmp = $a <=> $b;
	return $cmp unless natint_bits > significand_bits+1 &&
			   defined($cmp) && $cmp == 0;
	# do the rest in positive values
	($a, $b) = (-$b, -$a) if $a < 0;
	# Subtract out powers of two until a difference is detected or we
	# get into the safely comparable range.  Powers of two can be
	# represented as both float and int, so all the arithmetic is exact.
	for(my $t = -min_natint(); $t != (1 << significand_bits); $t >>= 1) {
		next unless $a >= $t && $b >= $t;
		$a -= $t;
		$b -= $t;
		$cmp = $a <=> $b;
		return $cmp unless $cmp == 0;
	}
	return 0;
}

=item sclnum_id_cmp(A, B)

This is a comparison function supplying a total ordering of scalar
numeric values.  Returns -1, 0, or +1, indicating whether A is to be
sorted before, the same as, or after B.

The ordering is of the identities of numeric values, not their numerical
values.  If floating point zeroes are signed, then the three types
(positive, negative, and unsigned) are considered to be distinct.
NaNs compare equal to each other, but different from all numeric values.
The exact ordering provided is mostly numerical order: NaNs come first,
followed by negative infinity, then negative finite values, then negative
zero, then unsigned zero, then positive zero, then positive finite values,
then positive infinity.

In addition to sorting, this function can be useful to check for a zero
of a particular sign.

=cut

my %zero_order = (
	"-0+0" => 0,
	"+0+0" => 1,
	"+0-0" => 2,
);
sub sclnum_id_cmp($$) {
	my($a, $b) = @_;
	if($a != $a) {
		return $b != $b ? 0 : -1;
	} elsif($b != $b) {
		return +1;
	} elsif(have_signed_zero && $a == 0 && $b == 0) {
		($a, $b) = @_;
		return $zero_order{sprintf("%+.f%+.f", $a, -$a)} <=>
			$zero_order{sprintf("%+.f%+.f", $b, -$b)};
	} else {
		return sclnum_val_cmp($a, $b);
	}
}

=back

=head1 BUGS

In Perl 5.6, if configured with a wider-than-usual native integer type
such that there are native integers that can't be represented exactly in
the native floating point type, it is not always possible to distinguish
between integer and floating point values in pure Perl code.  In order
to get the full benefit of either type, one is expected (by the numeric
semantics) to know in advance which of them one is using.  The pure Perl
version of this module can't operate on such a system, but the XS version
works fine.  This problem is resolved by Perl 5.8's new numeric semantics.

=head1 SEE ALSO

L<Data::Float>,
L<Data::Integer>,
L<perlnumber(1)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2009, 2010 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
