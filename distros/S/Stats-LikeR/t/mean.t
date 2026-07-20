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

# The tested value is computed OUTSIDE the leak block: the whole no_leaks_ok
# statement is skipped under Devel::Cover (its instrumentation SVs look like
# leaks), so a variable assigned inside it would be undef under coverage --
# and with "use warnings FATAL => 'all'" the undef arithmetic below would be a
# fatal error, not just a failed assertion.

# --- basic scalar mean ---------------------------------------------------
my $s = mean(1, 2, 3, 4);
is_approx $s, 2.5, 'mean of a flat scalar list';
no_leaks_ok { eval { my $x = mean(1, 2, 3, 4) } } 'mean no leaks: scalars' unless $INC{'Devel/Cover.pm'};

# --- array-ref mean ------------------------------------------------------
my $a = mean([1, 2, 3, 4]);
is_approx $a, 2.5, 'mean of a single array ref';
no_leaks_ok { eval { my $x = mean([1, 2, 3, 4]) } } 'mean no leaks: array ref' unless $INC{'Devel/Cover.pm'};

# --- mixed scalars and array refs ----------------------------------------
my $m = mean(1, [2, 3], 4);
is_approx $m, 2.5, 'mean across scalars and array refs together';
no_leaks_ok { eval { my $x = mean(1, [2, 3], 4) } } 'mean no leaks: mixed' unless $INC{'Devel/Cover.pm'};

# --- single element ------------------------------------------------------
my $one = mean(42);
is_approx $one, 42, 'mean of one element is that element';
no_leaks_ok { eval { my $x = mean(42) } } 'mean no leaks: single element' unless $INC{'Devel/Cover.pm'};

# --- negatives -----------------------------------------------------------
my $neg = mean(-2, 0, 2);
is_approx $neg, 0, 'mean handles negative values';
no_leaks_ok { eval { my $x = mean(-2, 0, 2) } } 'mean no leaks: negatives' unless $INC{'Devel/Cover.pm'};

# --- croak on empty input ------------------------------------------------
my $e_empty = '';
eval { mean(); 1 } or $e_empty = $@;
like $e_empty, qr/mean needs >= 1 element/, 'mean croaks on empty input';
no_leaks_ok { eval { mean() } } 'mean no leaks: empty croak' unless $INC{'Devel/Cover.pm'};

# --- croak on undef scalar arg: message must be FORMATTED ----------------
# This is the regression guard for the %zu / 5.10 croak-format bug:
# on a broken build the message reads "...argument index %zu..." instead
# of a real number, so we assert the number is present AND no % survives.
my $e_scalar = '';
eval { mean(1, undef, 3); 1 } or $e_scalar = $@;
like   $e_scalar, qr/\bargument index 1\b/, 'mean croak interpolates the real scalar index';
unlike $e_scalar, qr/%/,                    'mean croak leaves no literal % format directive (scalar)';
no_leaks_ok { eval { mean(1, undef, 3) } } 'mean no leaks: undef scalar croak' unless $INC{'Devel/Cover.pm'};

# --- croak on undef inside an array ref: same formatting guard -----------
my $e_aref = '';
eval { mean([1, undef, 3]); 1 } or $e_aref = $@;
like   $e_aref, qr/array ref index 1 \(argument 0\)/, 'mean croak interpolates real aref/argument indices';
unlike $e_aref, qr/%/,                                'mean croak leaves no literal % format directive (aref)';
no_leaks_ok { eval { mean([1, undef, 3]) } } 'mean no leaks: undef in aref croak' unless $INC{'Devel/Cover.pm'};

done_testing();
