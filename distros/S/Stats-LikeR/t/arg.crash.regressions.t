#!/usr/bin/env perl
# Arguments that used to kill the interpreter, hang it, or come back wrong.
#
# Every case below was reachable from ordinary Perl -- a typo, a stray
# reference, a column with no variance -- and none of them could be caught by
# the caller, because the failure was a signal, an unrecoverable allocator
# abort, or a plausible-looking number rather than a die.  Each is now a croak
# that eval sees.
#
# 1. matrix() raised SIGFPE.  nrow/ncol were read with SvUV(), so a
#    non-numeric string became 0, and the dimension inference divided by it
#    (`ncol = (data_len + nrow - 1) / nrow`) before the guard against a zero
#    dimension ran.  matrix([1..6], 0) and matrix([1..6], 'greater') both
#    exited on signal 8; eval cannot catch that.
#
# 2. prcomp() segfaulted on a HoH whose values were not all hash-refs.  The
#    shape was decided from whichever row hv_iternext() reached first and
#    nothing checked the rest, so both the column-name pass and the extraction
#    pass did SvRV() on every value and dereferenced the result as an HV.
#    Because the deciding row moves with hash order, the crash came and went
#    between runs on the same input -- hence the repeat loop below.
#
# 3. scale() segfaulted in matrix mode.  The per-row test was SvROK() alone,
#    so a reference to anything that is not an array -- a code ref, a scalar
#    ref -- was handed to av_fetch() as an AV.  Only row 0 is checked when the
#    matrix shape is detected.
#
# 4. merge() segfaulted on a left frame that was a reference to neither an
#    array nor a hash.  mg_shape() ran on nothing but an SvROK() test and
#    treated every non-array as an HV, so it reached hv_iterinit() on a
#    scalar ref before mg_prep() -- which is where a frame is really
#    validated -- could reject it.
#
# 5. bw_ucv() and bw_bcv() looped forever.  Their search interval is built
#    from sqrt(var(x)), which squares the data: on a double NV the variance of
#    c(1, 1e300, -1) is already +Inf, and Brent_fmin iterates until the
#    bracket closes, which a non-finite bound never does.  R does not reach
#    that either -- optimize() rejects the bounds first ("invalid 'xmin'
#    value") -- so this is the same check, moved to where the bounds are
#    built.  The threshold is a build property (about 1e155 for a double NV,
#    far higher for long double and __float128), so the test asserts on
#    finite-vs-not rather than on a fixed magnitude.
#
# 6. rnorm(), rbinom(), sample() and hist() died with perl's unrecoverable
#    "Out of memory in perl:util:safesysmalloc" when their size argument was
#    negative or a reference: SvUV(-1) is 2**64-1 and SvIV(\@x) is an address,
#    and both went straight to the allocator.  runif() already had a
#    hand-written check for exactly this; the other four now share one.
#
# 7. sample() returned data the caller could not tell from real data.  Asked
#    for more elements than the population holds, the array branch padded the
#    result to n with undef and the hash branch quietly returned fewer keys
#    than were asked for.  Both now croak, as R does.
#
# 8. cor_test() reported estimate 0, statistic 0 and p-value 1 when a column
#    had no variance -- a result indistinguishable from a real, supported
#    null.  R reports NA for all three.  Nothing else in the module agreed
#    with the old answer either: cor() croaks on the same input and
#    cor_test()'s own kendall branch already returned NaN.
#
# Provenance for every R behaviour quoted here: R 4.6.1 (2026-06-24).
#   * cor.test(c(1,1,1,1), c(1,2,3,4), method = m) for m in
#     pearson / kendall / spearman -> estimate NA, statistic NA, p-value NA;
#     df is 2 for pearson and absent for the other two.
#   * hist.default's own rule, src/library/graphics/R/hist.R lines 74-82:
#     stop("invalid number of 'breaks'") unless the value is finite and >= 1,
#     and warning("'breaks = %g' is too large and set to 1e6") above 1e6.
#     hist(1:5, breaks = 2) and hist(1:5, breaks = 2.7) both give breaks
#     0 2 4 6 with counts 2 2 1, which is what pins the truncation.
#   * sample(c(1,2,3), 10) -> "cannot take a sample larger than the
#     population when 'replace = FALSE'".
# No value here needs R, python3, NumPy or SciPy to be present.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'blib/lib', 'blib/arch';
use File::Spec;
use File::Temp ();
use Stats::LikeR qw(matrix prcomp scale merge bw_ucv bw_bcv density
                    rnorm rbinom runif sample hist cor_test cor min max);

# Run one snippet in a child perl and report how it ended.  A signal death
# (SIGFPE from matrix, SIGSEGV from prcomp/scale/merge) and an allocator abort
# both take the whole interpreter down, so eval in this process cannot see
# them and a plain dies_ok would itself die.  The child reports "croak" only
# when it exited 0 after catching the error.
#
# The snippet reaches the child in a file, and the child is spawned with the
# list form of system() -- no shell, so nothing in the snippet has to survive
# one.  Up to 0.316 this was `$^X @inc -e '$prog' 2>&1`, which is a sh command
# line: cmd.exe does not treat ' as a quote character at all, so on Windows
# perl was handed `'use` as its -e program and answered `Can't find string
# terminator "'" anywhere before EOF at -e line 1.` 26 of the 98 subtests here
# failed that way on a Strawberry 5.42 smoker (MSWin32-x64-multi-thread) with
# nothing whatever wrong in the module.  No single quoting is right for both
# shells -- and these snippets carry ', " and a literal NUL between them -- so
# the command line is the wrong place for the program.
#
# The verdict comes back in a file of its own, which the child opens by a path
# handed to it in @ARGV -- not on the child's stdout, and not embedded in the
# program text, where a Windows path's backslashes would need escaping.  What
# the child writes to stdout and stderr is captured too, by pointing this
# process's own handles at a file for the duration of the call, but only so
# that a failure has something to report: nothing is decided from it.  That is
# the half that depends on the child inheriting handles, and it is the half
# that can afford to.  Test::More is unaffected either way -- Test::Builder
# dups its handles when it loads.
my @inc = map { "-I$_" } grep { !ref $_ } @INC;
my $work      = File::Temp::tempdir(CLEANUP => 1);
my $prog_file = File::Spec->catfile($work, 'snippet.pl');
my $res_file  = File::Spec->catfile($work, 'snippet.res');
my $out_file  = File::Spec->catfile($work, 'snippet.out');
sub child_result {
	my ($code) = @_;
	my $prog = 'use Stats::LikeR; $SIG{__WARN__} = sub { };'
	         . ' my $ok = eval { ' . $code . '; 1 };'
	         . ' open my $R, ">", $ARGV[0] or exit 3;'
	         . ' print {$R} $ok ? "ok" : "croak";'
	         . ' close $R or exit 3; exit 0;';
	open my $pfh, '>', $prog_file or die "cannot write $prog_file: $!";
	print {$pfh} $prog             or die "cannot write $prog_file: $!";
	close $pfh                     or die "cannot write $prog_file: $!";
	unlink $res_file;	# so a stale verdict cannot be read as this one's

	open my $save_out, '>&', \*STDOUT or die "cannot save STDOUT: $!";
	open my $save_err, '>&', \*STDERR or die "cannot save STDERR: $!";
	open STDOUT, '>',  $out_file      or die "cannot redirect STDOUT: $!";
	open STDERR, '>&', \*STDOUT       or die "cannot redirect STDERR: $!";
	my $st = system($^X, @inc, $prog_file, $res_file);
	my $spawn_err = $!;	# read before the restores and the slurps clobber it
	open STDOUT, '>&', $save_out      or die "cannot restore STDOUT: $!";
	open STDERR, '>&', $save_err      or die "cannot restore STDERR: $!";

	my $slurp = sub {
		my ($f) = @_;
		open my $fh, '<', $f or return undef;
		local $/;
		my $c = <$fh>;
		close $fh;
		return defined $c ? $c : '';
	};
	my $out = $slurp->($out_file);
	$out = '' unless defined $out;
	return "not spawned ($spawn_err)" if $st == -1;
	return "signal " . ($st & 127) if $st & 127;
	return "exit " . ($st >> 8) . " ($out)" if ($st >> 8) != 0;
	my $verdict = $slurp->($res_file);
	return "no verdict ($out)" unless defined $verdict;
	return $verdict;
}

# --- 1. matrix: a zero or non-numeric dimension (was SIGFPE) ----------------
{
	for my $call ('matrix([1..6], 0)',
	              'matrix([1..6], undef, 0)',
	              'matrix(data => [1..6], nrow => 0)',
	              "matrix([1..6], q(greater))",
	              "matrix(data => [1..6], ncol => q(x))",
	              'matrix([1..6], -1)',
	              'matrix([1..6], 2, -1)') {
		is(child_result($call), 'croak', "matrix: $call croaks, no signal");
	}
	like(do { local $@; eval { matrix([1..6], 0) }; $@ },
	     qr/Dimensions must be greater than 0/,
	     'matrix: a zero dimension keeps its old message');
	like(do { local $@; eval { matrix([1..6], 'greater') }; $@ },
	     qr/matrix: nrow must be a number/,
	     'matrix: a non-numeric dimension names the argument');
	# R truncates: matrix(1:6, nrow = 2.7) is a two-row matrix.
	is(scalar @{ matrix([1..6], 2)   }, 2, 'matrix: nrow 2 still gives 2 rows');
	is(scalar @{ matrix([1..6], 2.7) }, 2, 'matrix: a fractional nrow truncates');
}

# --- 2. prcomp: a HoH with a value that is not a hash-ref (was SIGSEGV) -----
{
	# Hash order decides which row sets the shape, so one run proves little;
	# 40 runs of a fresh interpreter each get a different PERL_HASH_SEED.
	# The crash reproduced within the first two runs before the fix.
	for my $call ('prcomp({ c => {d=>1}, e => undef })',
	              'prcomp({ a => q(x), c => {d=>1}, e => {d=>2} })',
	              'prcomp({ c => {d=>1}, e => [1,2] })') {
		my %seen;
		$seen{ child_result($call) }++ for 1 .. 40;
		is_deeply([sort keys %seen], ['croak'],
		          "prcomp: $call croaks on every hash order")
			or diag explain \%seen;
	}
	# The HoA branch reached the same crash by a different route: column names
	# are copied with savepv() and looked up again with strlen(), so a name
	# holding a NUL byte truncates, hv_fetch() misses, and the NULL it returns
	# was dereferenced.
	is(child_result(q{prcomp({ "a\0b" => [1,2,3], c => [4,5,7] })}), 'croak',
	   'prcomp: a NUL in a HoA column name croaks rather than segfaulting');
	like(do { local $@; eval { prcomp({ "a\0b" => [1,2,3], c => [4,5,7] }) }; $@ },
	     qr/cannot be looked up by name/,
	     'prcomp: and says why');
	# An ordinary HoH still decomposes.
	my $ok = prcomp({ r1 => {a=>1, b=>2}, r2 => {a=>3, b=>5},
	                  r3 => {a=>4, b=>4}, r4 => {a=>7, b=>9} });
	ok(defined $ok->{sdev}, 'prcomp: an ordinary HoH still returns sdev');
}

# --- 3. scale: a matrix row that is a non-array reference (was SIGSEGV) -----
{
	# A row that is not an array-ref is treated as absent and reads as 0.0,
	# which is what this function has always done with a plain string or an
	# undef row (av_fetch() misses and the cell defaults).  The fix makes a
	# reference to the wrong thing take that same path instead of being
	# dereferenced as an AV; it deliberately does not start croaking, because
	# that would change what the two already-tolerated rows do.
	for my $call ('scale([[1,2], sub { 1 }])',
	              'scale([[1,2], \1])',
	              'scale([[1,2], bless({}, q(Foo))])',
	              'scale([[1,2], qr/x/])') {
		is(child_result($call), 'ok', "$call completes without a signal");
	}
	my @plain = scale([[1,2], undef]);
	ok(scalar @plain, 'scale: an undef row still returns a result');
	is_deeply([scale([[1,2], sub { 1 }])], [scale([[1,2], undef])],
	          'scale: a code-ref row reads the same as an undef row');
	my @good = scale([[1,3],[2,4]]);
	is(scalar @good, 1, 'scale: an ordinary matrix still returns one ref');
}

# --- 4. merge: a left frame that is neither AoH, HoA nor HoH (was SIGSEGV) --
{
	for my $call ('merge(\1, [{a=>1}])',
	              'merge(sub { 1 }, [{a=>1}])',
	              'merge(qr/x/, [{a=>1}])') {
		is(child_result($call), 'croak', "merge: $call croaks, no signal");
	}
	like(do { local $@; eval { merge(\1, [{a=>1}]) }; $@ },
	     qr/merge: left frame must be AoH\/HoA\/HoH/,
	     'merge: the frame check is the message the caller sees');
	# The join itself is untouched.
	my $j = merge([{id=>1, x=>10}], [{id=>1, y=>20}], on => 'id');
	is($j->[0]{y}, 20, 'merge: an ordinary inner join still works');
}

# --- 5. bw_ucv / bw_bcv: an overflowing variance (was an infinite loop) -----
{
	# 1e300 squared overflows a double NV.  On long double and __float128 it
	# does not, and there the call must still return a bandwidth -- so assert
	# on the two possible outcomes rather than on which one this build takes,
	# and assert that neither is a hang (the child would be killed by the
	# harness, not return).
	for my $fn (qw(bw_ucv bw_bcv)) {
		no strict 'refs';
		my $f = \&{"Stats::LikeR::$fn"};
		my $got = do { local $@; local $SIG{__WARN__} = sub { };
		               my $v = eval { $f->([1, 1e300, -1]) }; $@ ? "croak: $@" : $v };
		if ($got =~ /^croak/) {
			like($got, qr/search interval is not finite/,
			     "$fn: an overflowing variance croaks rather than looping");
		} else {
			ok($got > 0, "$fn: a wider NV computes a bandwidth instead");
		}
	}
	# density() reaches the same code through bw => 'ucv'.
	my $d = do { local $@; local $SIG{__WARN__} = sub { };
	             my $v = eval { density([1, 2, 3, 1e300], bw => 'ucv') }; $@ ? "croak: $@" : $v };
	ok(ref $d || $d =~ /^croak/, 'density(bw => ucv): returns or croaks, never hangs');
	# Data whose variance is finite is unaffected.
	my $ok = do { local $SIG{__WARN__} = sub { }; bw_ucv([1, 2, 3, 1e150]) };
	ok($ok > 0, 'bw_ucv: a finite variance still yields a bandwidth');
}

# --- 6. size arguments that are negative or a reference (was an OOM abort) --
{
	for my $call ('rnorm(-1)',
	              'rnorm(n => -1)',
	              'rbinom(n => -1, size => 2, prob => 0.5)',
	              'rbinom(n => 2, size => -1, prob => 0.5)',
	              'sample([1,2,3], [1])',
	              'sample([1,2,3], sub { 1 })',
	              'hist([1,2,3], sub { 1 })',
	              'hist([1,2,3], [1])') {
		is(child_result($call), 'croak', "$call croaks instead of aborting");
	}
	like(do { local $@; eval { rnorm(-1) }; $@ },
	     qr/rnorm: n must be an integer >= 0, not -1/,
	     'rnorm: the message names the function and the argument');
	like(do { local $@; eval { hist([1,2,3], sub { 1 }) }; $@ },
	     qr/hist: breaks must be a number/,
	     'hist: a reference in the breaks slot names the argument');
	# runif already had this check; the shared one must not change it.
	like(do { local $@; eval { runif(-1) }; $@ },
	     qr/runif: 'n' must be a non-negative integer/,
	     "runif: its own message is unchanged");
	is(scalar @{ rnorm(5) },                              5, 'rnorm(5) still returns 5');
	is(scalar @{ rbinom(n => 5, size => 3, prob => 0.5) }, 5, 'rbinom(n=>5) still returns 5');
}

# --- 7. hist breaks: R's own rule (hist.R lines 74-82) ----------------------
{
	for my $bad (0, -5, -1) {
		like(do { local $@; eval { hist([1,2,3,4,5], breaks => $bad) }; $@ },
		     qr/hist: breaks must be an integer >= 1/,
		     "hist: breaks => $bad is refused (R: invalid number of 'breaks')");
	}
	# R: hist(1:5, breaks = 2) and breaks = 2.7 both give 0 2 4 6, counts 2 2 1.
	my $h2 = hist([1,2,3,4,5], breaks => 2);
	is_deeply($h2->{breaks}, [0, 2, 4, 6], 'hist: breaks => 2 matches R');
	is_deeply($h2->{counts}, [2, 2, 1],    'hist: breaks => 2 counts match R');
	my $hf = hist([1,2,3,4,5], breaks => 2.7);
	is_deeply($hf->{breaks}, $h2->{breaks},
	          'hist: a fractional breaks truncates, as R does');
	# R clamps above 1e6 with a warning rather than erroring.
	my @warns;
	my $hb = do { local $SIG{__WARN__} = sub { push @warns, $_[0] };
	              hist([1,2,3,4,5], breaks => 2_000_000) };
	like(join('', @warns), qr/too large and set to 1000000/,
	     'hist: breaks above 1e6 warns, as R does');
	ok(scalar @{ $hb->{breaks} } > 1, 'hist: the clamped call still returns breaks');
}

# --- 8. sample: no drawing more than the population holds -------------------
{
	like(do { local $@; eval { sample([1,2,3], 10) }; $@ },
	     qr/sample: cannot take a sample of 10 from a population of 3/,
	     'sample: an over-large array draw croaks (R errors here too)');
	like(do { local $@; eval { sample({a=>1, b=>2}, 5) }; $@ },
	     qr/sample: cannot take a sample of 5 from a population of 2/,
	     'sample: the hash branch croaks the same way the array branch does');
	like(do { local $@; eval { sample('not a ref', 1) }; $@ },
	     qr/Usage: sample/,
	     'sample: a non-reference is a usage error, not a silent undef');
	# The ordinary draws are unchanged, and no element is ever undef.
	my $a = sample([qw(a b c d e)], 3);
	is(scalar @$a, 3, 'sample: an array draw returns exactly n elements');
	is(scalar(grep { !defined } @$a), 0, 'sample: no undef padding');
	my %pop = (a => 1, b => 2, c => 3, d => 4);
	my $h = sample(\%pop, 2);
	is(scalar keys %$h, 2, 'sample: a hash draw returns exactly n keys');
	is_deeply([sort keys %{ sample(\%pop, 4) }], [sort keys %pop],
	          'sample: n equal to the population is still allowed');
	is(scalar @{ sample([1,2,3], 0) }, 0, 'sample: n => 0 gives an empty draw');
	is(scalar @{ sample([1,2,3])    }, 1, 'sample: n defaults to 1');
}

# --- 9. cor_test with no variance: NA, not a fabricated null ----------------
{
	# R: cor.test(c(1,1,1,1), c(1,2,3,4)) reports cor NA, t NA, p-value NA,
	# df 2, for every method; only pearson carries a df at all.
	for my $method (qw(pearson kendall spearman)) {
		for my $alt (qw(two.sided less greater)) {
			my $r = cor_test([1,1,1,1], [1,2,3,4],
			                 method => $method, alternative => $alt);
			for my $f (qw(estimate statistic), 'p.value') {
				ok($r->{$f} != $r->{$f},
				   "cor_test $method/$alt: $f is NaN, as R reports NA");
			}
		}
	}
	my $p = cor_test([1,1,1,1], [1,2,3,4]);
	is($p->{parameter}, 2, 'cor_test pearson: df is still 2, as R reports');
	ok($p->{'conf.int'}[0] != $p->{'conf.int'}[0]
	   && $p->{'conf.int'}[1] != $p->{'conf.int'}[1],
	   'cor_test pearson: the interval is NaN too');
	# Either column, or both.
	for my $case ([[1,2,3,4], [5,5,5,5]], [[2,2,2,2], [5,5,5,5]]) {
		my $r = cor_test(@$case);
		ok($r->{estimate} != $r->{estimate},
		   'cor_test: a constant y, or two constants, is NaN as well');
	}
	# cor() croaks on the same input; the two disagreeing is what made the
	# old cor_test answer hard to spot.
	like(do { local $@; eval { cor([1,1,1,1], [1,2,3,4]) }; $@ },
	     qr/standard deviation of x is 0/,
	     'cor: still croaks, which is what cor_test now agrees with');
	# An ordinary correlation is untouched.
	my $good = cor_test([1,2,3,4,5], [2,1,4,3,5]);
	cmp_ok(abs($good->{estimate} - 0.8), '<', 1e-12,
	       'cor_test: an ordinary Pearson estimate is unchanged');
}

# --- 10. hist extrema are seeded from NV_MAX, not DBL_MAX ------------------
{
	# On a __float128 build every value above DBL_MAX failed `val < min_val`
	# and left min_val at 1.8e308, so hist([1e400, 1.05e400, 1.1e400]) put its
	# first break at 0 and its first bin empty while min() returned 1e400.
	# On a double build 1e400 is Inf, which hist() drops as R does
	# (x <- x[is.finite(x)]), so the case only exists on the wider NVs.
	my @big = (1e400, 1.05e400, 1.1e400);
	SKIP: {
		skip 'NV is not wide enough to hold 1e400', 2
			unless $big[0] < 9**9**9;
		my $h = hist(\@big);
		cmp_ok($h->{breaks}[0], '>=', min(\@big) * 0.5,
		       'hist: the first break tracks the data, not DBL_MAX');
		is($h->{counts}[0] > 0, 1, 'hist: the first bin is not empty');
	}
}

done_testing();
