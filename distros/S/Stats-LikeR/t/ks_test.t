#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# These tests exercise Stats::LikeR::ks_test() through its public API. Each
# block is labelled with the bug it guards against; the comment notes how the
# ORIGINAL (buggy) code behaved, so a failure here pinpoints a regression.
#
#   #1 named-arg parsing       #2 OOB read on odd trailing arg
#   #3 NV/double sort mismatch  #4 all-missing 'x' (1-sample) div-by-zero
#   #5 aliased x/y (restrict)   #6 forced exact beyond the auto-gate
#
# Run:  prove -lb t/ks_test.t      (after building the XS module)

BEGIN {
    eval { require Stats::LikeR; Stats::LikeR->import('ks_test'); 1 }
        or plan skip_all => "Stats::LikeR not built: $@";
}

# Test::Exception (dies_ok/throws_ok/lives_ok) and Test::LeakTrace (no_leaks_ok)
# are optional. Load them if present; otherwise install prototyped stubs that
# turn each call into a skip, so the file still compiles and runs everywhere.
# The imports happen in BEGIN so the (&;$) prototypes are known when the block-
# form calls below are compiled.
our ($HAVE_EXCEPTION, $HAVE_LEAKTRACE);
BEGIN {
	$HAVE_EXCEPTION = eval { require Test::Exception; Test::Exception->import; 1 };
	unless ($HAVE_EXCEPTION) {
		no strict 'refs';
		for my $n (qw(dies_ok lives_ok)) {
			*{"main::$n"} = sub (&;$) { SKIP: { skip "Test::Exception not installed", 1 } };
		}
		*{"main::throws_ok"} = sub (&$;$) { SKIP: { skip "Test::Exception not installed", 1 } };
	}

	$HAVE_LEAKTRACE = eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 };
	unless ($HAVE_LEAKTRACE) {
		no strict 'refs';
		*{"main::no_leaks_ok"} = sub (&;$) { SKIP: { skip "Test::LeakTrace not installed", 1 } };
	}
}

# ---- helpers ---------------------------------------------------------------

# Run a coderef, returning ($return_value_or_undef, $error, \@warnings).
sub run {
    my ($code) = @_;
    my @warns;
    my $ret;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ok = eval { $ret = $code->(); 1 };
    return ($ok ? $ret : undef, $ok ? undef : ($@ || 'died'), \@warns);
}

sub is_result_hash {
    my ($r, $label) = @_;
    ok(ref($r) eq 'HASH', "$label: returns hashref")
        or return 0;
    ok(exists $r->{statistic} && exists $r->{p_value}
        && exists $r->{method} && exists $r->{alternative},
        "$label: has statistic/p_value/method/alternative");
    ok($r->{p_value} >= 0 && $r->{p_value} <= 1, "$label: p_value in [0,1]");
    return 1;
}

my @SEP_X = (1, 2, 3, 4);
my @SEP_Y = (5, 6, 7, 8);   # completely separated from X  => D = 1, D+ = 1, D- = 0

#
# Correctness anchors (also exercise the statistic + comparator paths)
#

my ($r, $err) = run(sub { ks_test(\@SEP_X, \@SEP_Y) });
is($err, undef, "separated 2-sample: no exception");
is_result_hash($r, "separated 2-sample");
cmp_ok(abs($r->{statistic} - 1.0), '<', 1e-9, "separated 2-sample: D == 1");
cmp_ok($r->{p_value}, '<', 0.05, "separated 2-sample: small p-value");
like($r->{method}, qr/Two-sample/, "separated 2-sample: method labelled");

# Bug #3: input is sorted internally; unsorted input must give the same D.
# On a long-double / quadmath Perl a `double*` comparator would mis-sort and
# corrupt this. Equal D for shuffled vs sorted input catches that.
{
    my ($sorted)   = run(sub { ks_test([1,2,3,4],     [5,6,7,8])     });
    my ($shuffled) = run(sub { ks_test([4,1,3,2],     [7,5,8,6])     });
    cmp_ok(abs($sorted->{statistic} - $shuffled->{statistic}), '<', 1e-12,
        "#3 comparator: shuffled input yields identical D (NV-correct sort)");
    cmp_ok(abs($shuffled->{statistic} - 1.0), '<', 1e-9,
        "#3 comparator: shuffled D == 1");
}

# alternative => greater/less must select D+ / D-.
my ($g) = run(sub { ks_test(\@SEP_X, \@SEP_Y, alternative => 'greater') });
my ($l) = run(sub { ks_test(\@SEP_X, \@SEP_Y, alternative => 'less')    });
cmp_ok(abs($g->{statistic} - 1.0), '<', 1e-9, "alternative greater => D+ (==1)");
cmp_ok(abs($l->{statistic} - 0.0), '<', 1e-9, "alternative less => D- (==0)");
is($g->{alternative}, 'greater', "alternative echoed back: greater");
is($l->{alternative}, 'less',    "alternative echoed back: less");

# Invalid alternative must croak.
{
    my (undef, $err) = run(sub { ks_test(\@SEP_X, \@SEP_Y, alternative => 'up') });
    like($err, qr/alternative must be/, "invalid alternative croaks");
}

# ===========================================================================
# Bug #1 — named-argument parsing
#   Original: a named key string (the first positional string) was swallowed as
#   a 1-sample CDF name, so fully-named calls croaked with
#   "unknown argument 'ARRAY(0x..)'", and ks_test(\@x, exact=>1) croaked with
#   "Unsupported 1-sample distribution 'exact'".
# ===========================================================================

($r, $err) = run(sub { ks_test(x => \@SEP_X, 'y' => \@SEP_Y) });
is($err, undef, "#1 fully-named x=>/y=> does not croak");
is_result_hash($r, "#1 fully-named");
cmp_ok(abs($r->{statistic} - 1.0), '<', 1e-9, "#1 fully-named: correct D");

# 'x' positional, then a named key whose name happens to be a bareword
# string: it must be parsed as a key, NOT as a CDF. With no 'y' supplied
# this is an error about the MISSING y, never about an unsupported dist.
(undef, $err) = run(sub { ks_test([1,2,3,4], exact => 1) });
like($err, qr/Invalid arguments for 'y'/,
  "#1 'exact' key not mistaken for a CDF (errors on missing y)");
unlike($err, qr/Unsupported 1-sample distribution/,
  "#1 'exact' key not reported as an unsupported distribution");

# Mixed: positional x + positional CDF + trailing named arg (odd trailing
# count => the string really is the CDF). Must run a 1-sample test.
($r, $err) = run(sub { ks_test([-1,0,1], 'pnorm', exact => 0) });
is($err, undef, "#1 positional CDF + named arg parses");
like($r->{method}, qr/One-sample/, "#1 1-sample method selected");

# ===========================================================================
# Bug #2 — out-of-bounds stack read on a dangling named argument
#   Original: the key/value loop read ST(arg_idx+1) before checking bounds, so
#   an odd trailing arg read past the Perl stack (UB / possible crash).
#   Fixed code must croak cleanly about the missing value.
# ===========================================================================

(undef, $err) = run(sub { ks_test(\@SEP_X, \@SEP_Y, 'exact') });
like($err, qr/missing a value/,
  "#2 dangling named arg croaks cleanly (no OOB stack read)");

# ===========================================================================
# Bug #4 — all-missing 'x' in the 1-sample path
#   Original: the pnorm branch had no valid_nx guard, so all-non-numeric x fed
#   0 into divisions / K2x (NaN or div-by-zero). Must croak instead.
# ===========================================================================

{
    my (undef, $err) = run(sub { ks_test(['a','b','c'], 'pnorm') });
    like($err, qr/Not enough non-missing 'x'/,
        "#4 all-missing x (1-sample) croaks rather than dividing by zero");
}

{
 # Two-sample all-missing y is also guarded.
 my (undef, $err) = run(sub { ks_test([1,2,3], ['x','y','z']) });
 like($err, qr/Not enough non-missing/,
     "#4b all-missing y (2-sample) croaks");
}

{
 # Mixed valid/invalid: non-numeric entries are dropped, not fatal.
 my ($r, $err) = run(sub { ks_test([1,2,undef,3,'foo',4], \@SEP_Y) });
 is($err, undef, "#4c mixed valid/invalid x: non-numbers dropped, no croak");
 cmp_ok(abs($r->{statistic} - 1.0), '<', 1e-9,
     "#4c surviving 4 values still fully separated (D==1)");
}

# ===========================================================================
# Bug #5 — aliased x and y (same arrayref)
#   The C locals were marked `restrict` while the same SV could be passed as
#   both x and y, a restrict violation. Behaviour must be well-defined:
#   identical samples => D == 0, p ~ 1.
# ===========================================================================

{
 my @a = (1, 2, 3, 4, 5);
 my ($r, $err) = run(sub { ks_test(\@a, \@a) });
 is($err, undef, "#5 aliased x/y: no exception");
 cmp_ok(abs($r->{statistic} - 0.0), '<', 1e-9, "#5 aliased x/y: D == 0");
 cmp_ok($r->{p_value}, '>', 0.99, "#5 aliased x/y: p ~ 1");
}

# ===========================================================================
# Ties handling — exact path must warn and fall back to asymptotic.
# ===========================================================================

{
 # Small samples => exact is auto-selected; shared values create ties.
 my ($r, $err, $warns) = run(sub { ks_test([1,2,2,3], [2,3,3,4], exact => 1) });
 is($err, undef, "ties: no exception");
 ok((grep { /ties/i } @$warns), "ties: warns about exact-with-ties")
     or diag("warnings: @$warns");
 like($r->{method}, qr/asymptotic/, "ties: fell back to asymptotic method");
}

# ===========================================================================
# Bug #6 — forced exact beyond the auto-gate
#   Original: psmirnov_exact_uniq_upper took (int m, int n) while valid_nx/ny
#   are size_t; a forced exact run on large samples could truncate dimensions.
#   With size_t params a moderately-large forced exact must still run exactly
#   and return a valid p-value.
# ===========================================================================

{
	# 150 x 150 = 22500 > the 10000 auto-gate, so exact only happens if forced.
	my @x = map { $_ * 1.0 } 1 .. 150;
	my @y = map { $_ + 0.5 } 1 .. 150;     # interleaved, distinct, no ties
	my ($r, $err) = run(sub { ks_test(\@x, \@y, exact => 1) });
	is($err, undef, "#6 forced exact on 150x150: no exception");
	is_result_hash($r, "#6 forced exact 150x150");
	like($r->{method}, qr/exact/,
	  "#6 forced exact actually used the exact method (size_t dims)");
}

#
# Misc robustness
#

# 'x' is required.
(undef, $err) = run(sub { ks_test(y => \@SEP_Y) });
like($err, qr/'x' is a required argument/, "missing x croaks");

{
    # Unsupported distribution name still reported clearly.
    my (undef, $err) = run(sub { ks_test(\@SEP_X, 'pcauchy') });
    like($err, qr/Unsupported 1-sample distribution 'pcauchy'/,
        "unsupported 1-sample distribution croaks with its name");
}

{
    # One-sample statistic sanity: x = (-1,0,1) vs N(0,1) => D ~ 0.1746.
    my ($r, $err) = run(sub { ks_test([-1, 0, 1], 'pnorm') });
    is($err, undef, "1-sample pnorm: no exception");
    cmp_ok(abs($r->{statistic} - 0.1746), '<', 0.01,
        "1-sample pnorm: D ~ 0.1746 (allows approx_pnorm error)");
}

# ===========================================================================
# Death tests via Test::Exception (dies_ok / throws_ok / lives_ok)
#   Same failure conditions as the run()/like() checks above, but asserted in
#   the Test::Exception idiom. throws_ok also pins the croak message, so a
#   regression that dies for the *wrong* reason is still caught.
# ===========================================================================

dies_ok { ks_test() }              'no arguments dies';
dies_ok { ks_test(y => \@SEP_Y) }  'missing x dies';

throws_ok { ks_test(y => \@SEP_Y) }
	qr/'x' is a required argument/,
	'missing x: required-argument message';

throws_ok { ks_test([]) }
	qr/Not enough 'x' observations/,
	'empty x array: message';

throws_ok { ks_test(\@SEP_X, \@SEP_Y, alternative => 'up') }
	qr/alternative must be/,
	'invalid alternative: message';

throws_ok { ks_test(\@SEP_X, \@SEP_Y, 'exact') }
	qr/missing a value/,
	'#2 dangling named argument: missing-value message';

throws_ok { ks_test(\@SEP_X, \@SEP_Y, bogus => 1) }
	qr/unknown argument 'bogus'/,
	'unknown named argument: message';

throws_ok { ks_test([1,2,3,4], exact => 1) }
	qr/Invalid arguments for 'y'/,
	'#1 named key not taken as a CDF (errors on missing y)';

throws_ok { ks_test(['a','b','c'], 'pnorm') }
	qr/Not enough non-missing 'x'/,
	'#4 all-missing x (1-sample): message';

throws_ok { ks_test([1,2,3], ['x','y','z']) }
	qr/Not enough non-missing/,
	'#4b all-missing y (2-sample): message';

throws_ok { ks_test(\@SEP_X, 'pcauchy') }
	qr/Unsupported 1-sample distribution 'pcauchy'/,
	'unsupported distribution: message includes the name';

lives_ok { ks_test(\@SEP_X, \@SEP_Y) }            'valid 2-sample lives';
lives_ok { ks_test([-1, 0, 1], 'pnorm') }          'valid 1-sample lives';
lives_ok { ks_test(x => \@SEP_X, y => \@SEP_Y) }   '#1 fully-named call lives';

# ===========================================================================
# Memory-leak checks via Test::LeakTrace.
#   Every call is wrapped in eval {} so the error-path cases (which croak
#   *after* allocating the C buffers) still let no_leaks_ok finish its run —
#   those croak-after-malloc paths are exactly where a missing Safefree would
#   leak. Skipped under Devel::Cover, whose instrumentation allocates and would
#   otherwise be reported as leaks.
# ===========================================================================

# If Test::LeakTrace is missing, no_leaks_ok is the stub above (one skip per
# call). If Devel::Cover is active, the per-statement `unless` suppresses the
# check entirely (cover allocations would look like leaks).

# ---- happy paths ----
no_leaks_ok {
	eval { ks_test(\@SEP_X, \@SEP_Y) }
} 'Kolmogorov-Smirnov test ok without memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { ks_test([-1, 0, 1], 'pnorm') }
} '1-sample pnorm: no memory leak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { ks_test(\@SEP_X, \@SEP_Y, alternative => 'greater') }
} 'one-sided (greater): no memory leak' unless $INC{'Devel/Cover.pm'};

# ---- exact DP buffer: alloc + free of u[] in psmirnov ----
{
	my @x = map { $_ * 1.0 } 1 .. 30;
	my @y = map { $_ + 0.5 } 1 .. 30;   # distinct, no ties => exact runs
	no_leaks_ok {
		eval { ks_test(\@x, \@y, exact => 1) }
	} 'forced-exact DP buffer: no memory leak' unless $INC{'Devel/Cover.pm'};
}

# ---- ties fallback (warns, then takes the asymptotic branch) ----
#no_leaks_ok {
#	eval { ks_test([1,2,2,3], [2,3,3,4], exact => 1) }
#} 'ties fallback path: no memory leak' unless $INC{'Devel/Cover.pm'};

# ---- error paths: croak AFTER allocating x_data (and y_data). The eval {}
#      swallows the exception so the tracer can complete. These are the
#      leak-prone spots if a Safefree is ever dropped. ----
no_leaks_ok {
	eval { ks_test([1,2,3], ['x','y','z']) }
} 'croak after x_data+y_data alloc (all-missing y): no leak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { ks_test(\@SEP_X, 'pcauchy') }
} 'croak after x_data alloc (unsupported dist): no leak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { ks_test([1,2,3,4], exact => 1) }
} 'croak after x_data alloc (invalid y): no leak' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { ks_test([1,2,3,4], \@SEP_Y, alternative => 'up') }
} 'croak after x_data+y_data alloc (bad alternative): no leak' unless $INC{'Devel/Cover.pm'};

# ---- error path that croaks BEFORE any C buffer is allocated ----
no_leaks_ok {
	eval { ks_test(\@SEP_X, \@SEP_Y, 'exact') }
} 'croak during arg parse (no alloc): no leak' unless $INC{'Devel/Cover.pm'};

done_testing();
