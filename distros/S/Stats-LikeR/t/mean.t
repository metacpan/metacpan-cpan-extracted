#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

sub is_approx {
	my ($got, $exp, $msg, $tol) = @_;
	$tol //= 1e-9;
	ok(abs($got - $exp) < $tol, $msg)
		or diag("got $got, expected $exp (tolerance $tol)");
}

# --- basic scalar mean ---------------------------------------------------
my $s;
no_leaks_ok { eval { $s = mean(1, 2, 3, 4) } } 'mean no leaks: scalars' unless $INC{'Devel/Cover.pm'};
is_approx $s, 2.5, 'mean of a flat scalar list';

# --- array-ref mean ------------------------------------------------------
my $a;
no_leaks_ok { eval { $a = mean([1, 2, 3, 4]) } } 'mean no leaks: array ref' unless $INC{'Devel/Cover.pm'};
is_approx $a, 2.5, 'mean of a single array ref';

# --- mixed scalars and array refs ----------------------------------------
my $m;
no_leaks_ok { eval { $m = mean(1, [2, 3], 4) } } 'mean no leaks: mixed' unless $INC{'Devel/Cover.pm'};
is_approx $m, 2.5, 'mean across scalars and array refs together';

# --- single element ------------------------------------------------------
my $one;
no_leaks_ok { eval { $one = mean(42) } } 'mean no leaks: single element' unless $INC{'Devel/Cover.pm'};
is_approx $one, 42, 'mean of one element is that element';

# --- negatives -----------------------------------------------------------
my $neg;
no_leaks_ok { eval { $neg = mean(-2, 0, 2) } } 'mean no leaks: negatives' unless $INC{'Devel/Cover.pm'};
is_approx $neg, 0, 'mean handles negative values';

# --- croak on empty input ------------------------------------------------
my $e_empty = '';
no_leaks_ok { eval { mean(); 1 } or $e_empty = $@ } 'mean no leaks: empty croak' unless $INC{'Devel/Cover.pm'};
like $e_empty, qr/mean needs >= 1 element/, 'mean croaks on empty input';

# --- croak on undef scalar arg: message must be FORMATTED ----------------
# This is the regression guard for the %zu / 5.10 croak-format bug:
# on a broken build the message reads "...argument index %zu..." instead
# of a real number, so we assert the number is present AND no % survives.
my $e_scalar = '';
no_leaks_ok { eval { mean(1, undef, 3); 1 } or $e_scalar = $@ } 'mean no leaks: undef scalar croak' unless $INC{'Devel/Cover.pm'};
like   $e_scalar, qr/\bargument index 1\b/, 'mean croak interpolates the real scalar index';
unlike $e_scalar, qr/%/,                    'mean croak leaves no literal % format directive (scalar)';

# --- croak on undef inside an array ref: same formatting guard -----------
my $e_aref = '';
no_leaks_ok { eval { mean([1, undef, 3]); 1 } or $e_aref = $@ } 'mean no leaks: undef in aref croak' unless $INC{'Devel/Cover.pm'};
like   $e_aref, qr/array ref index 1 \(argument 0\)/, 'mean croak interpolates real aref/argument indices';
unlike $e_aref, qr/%/,                                'mean croak leaves no literal % format directive (aref)';

done_testing();
