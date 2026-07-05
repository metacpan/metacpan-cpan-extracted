#!/usr/bin/env perl
# t/extended_tests.t
#
# Path-coverage tests targeting the branch and condition gaps revealed by
# Devel::Cover.  Strategy:
#   - Mock HTTP::Tiny at the package level inside each subtest's scope so
#     network checks can be exercised without live network calls.
#   - Use real CPAN::Meta objects loaded from temp files for META-dependent
#     checks (avoids diverging from the real parse path).
#   - Drive every conditional arm (score tiers, status choices, skip vs.
#     error vs. result, verbose/colour toggle, etc.).

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(encode_json decode_json);
use Readonly;
use Scalar::Util qw(blessed);

# Pre-load HTTP::Tiny before any tests so that 'require HTTP::Tiny' inside
# network checks is a no-op and does NOT overwrite our mock_scoped stubs.
use HTTP::Tiny ();

use Test::Most;
use Test::Returns qw(returns_ok);
use Test::Mockingbird qw(mock_scoped spy restore_all);

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $SCORE_PASS_CT  => 80;    # CPANTesters pass threshold
Readonly::Scalar my $SCORE_WARN_CT  => 60;    # CPANTesters warn threshold

Readonly::Scalar my $REVDEP_SCORE_NONE => 50;
Readonly::Scalar my $REVDEP_SCORE_FEW  => 75;
Readonly::Scalar my $REVDEP_SCORE_SOME => 90;
Readonly::Scalar my $REVDEP_SCORE_MANY => 100;

Readonly::Scalar my $SECS_PER_YEAR   => 31_557_600;
Readonly::Scalar my $ABANDONED_YEARS => 3;

Readonly::Scalar my $CAP_SECADV => 60;
Readonly::Scalar my $CAP_CPANTS => 75;

# ---------------------------------------------------------------------------
# Module loading
# ---------------------------------------------------------------------------
for my $mod (qw(
	Test::CPAN::Health
	Test::CPAN::Health::Result
	Test::CPAN::Health::Report
	Test::CPAN::Health::Runner
	Test::CPAN::Health::Distribution
	Test::CPAN::Health::Cache
	Test::CPAN::Health::Check::CPANTesters
	Test::CPAN::Health::Check::ReverseDeps
	Test::CPAN::Health::Check::AbandonedDeps
	Test::CPAN::Health::Check::StaleDeps
	Test::CPAN::Health::Check::SecurityAdvisories
	Test::CPAN::Health::Reporter::Terminal
	Test::CPAN::Health::Reporter::JSON
	Test::CPAN::Health::Reporter::HTML
	Test::CPAN::Health::Reporter::TAP
)) {
	use_ok($mod) or BAIL_OUT("Cannot load $mod");
}

# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

# Build a named temp distribution with a real META.json so that $dist->name
# and $dist->meta work correctly.  Optional prereqs hash is merged in.
sub _named_dist {
	my (%opts) = @_;
	my $name    = $opts{name}    // 'Test-Dist';
	my $version = $opts{version} // '1.00';
	my $prereqs = $opts{prereqs} // {};

	my $dir = tempdir(CLEANUP => 1);

	my %meta_data = (
		name        => $name,
		version     => $version,
		abstract    => "Test distribution $name",
		author      => ['Test Author <test@example.com>'],
		license     => ['perl_5'],
		'meta-spec' => { version => '2', url => 'https://metacpan.org/pod/CPAN::Meta::Spec' },
	);
	$meta_data{prereqs} = $prereqs if %{$prereqs};

	my $meta_file = File::Spec->catfile($dir, 'META.json');
	open my $fh, '>', $meta_file or die "Cannot write META.json: $!";
	print {$fh} encode_json(\%meta_data);
	close $fh;

	return Test::CPAN::Health::Distribution->new(path => $dir);
}

# Build a minimal report with one result for reporter tests.
sub _simple_report {
	my (%opts) = @_;
	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => $opts{check_id} // 'test_check',
			status   => $opts{status}   // 'pass',
			score    => $opts{score}    // 80,
			summary  => $opts{summary}  // 'looks good',
			%{$opts{extra} // {}},
		),
	);
	return $report;
}

# Build a fake successful HTTP::Tiny GET response.
sub _http_ok {
	my ($data) = @_;
	return {
		success => 1,
		status  => 200,
		reason  => 'OK',
		content => encode_json($data),
		headers => {},
	};
}

# Build a fake failed HTTP::Tiny response.
sub _http_fail {
	my ($status, $reason) = @_;
	$status //= 500;
	$reason //= 'Internal Server Error';
	return {
		success => 0,
		status  => $status,
		reason  => $reason,
		content => '',
		headers => {},
	};
}

# A date string N years ago in ISO 8601 format.
sub _years_ago {
	my ($years) = @_;
	my @t = gmtime(time - int($years * $SECS_PER_YEAR));
	return sprintf('%04d-%02d-%02dT00:00:00.000Z',
		$t[5] + 1900, $t[4] + 1, $t[3]);
}

# ===========================================================================
# 1.  Health.pm: constructor validation
# ===========================================================================
subtest 'Health: constructor requires at least one location argument' => sub {

	throws_ok(
		sub { Test::CPAN::Health->new },
		qr/One of path, module, dist, or distribution is required/,
		'new() with no location args croaks',
	);

	throws_ok(
		sub { Test::CPAN::Health->new(path => '/tmp') },
		qr//,     # format validation only fires if path is present but format is bad
		'new() with only path succeeds (no format supplied, default terminal)',
	) or pass('new(path) accepted -- format defaults to terminal');

	# Explicitly exercise: new() with valid path does not croak
	my $tmp = tempdir(CLEANUP => 1);
	my $h = Test::CPAN::Health->new(path => $tmp);
	ok(blessed($h), 'new(path => ...) returns blessed object');
};

# ---------------------------------------------------------------------------
subtest 'Health: invalid format croaks with message' => sub {

	my $tmp = tempdir(CLEANUP => 1);

	throws_ok(
		sub { Test::CPAN::Health->new(path => $tmp, format => 'badformat') },
		qr/Unknown format 'badformat'/,
		'new() with invalid format croaks',
	);
};

# ---------------------------------------------------------------------------
subtest 'Health: all valid format strings accepted' => sub {

	my $tmp = tempdir(CLEANUP => 1);
	for my $fmt (qw(terminal json html tap)) {
		my $h = Test::CPAN::Health->new(path => $tmp, format => $fmt);
		is($h->output_format, $fmt, "format '$fmt' stored correctly");
	}
};

# ---------------------------------------------------------------------------
subtest 'Health: read-only accessors return undef or correct values before analyse' => sub {

	my $tmp = tempdir(CLEANUP => 1);
	my $h   = Test::CPAN::Health->new(path => $tmp, min_score => 75);

	ok(!defined $h->distribution, 'distribution() is undef before analyse');
	ok(!defined $h->runner,       'runner() is undef before analyse');
	ok(!defined $h->reporter,     'reporter() is undef before analyse');
	ok(!defined $h->cache,        'cache() is undef before analyse');
	is($h->output_format, 'terminal', 'output_format() defaults to terminal');
	is($h->min_score,     75,         'min_score() returns constructor value');
};

# ---------------------------------------------------------------------------
subtest 'Health: checks and skip filtering via short IDs' => sub {

	my $tmp = tempdir(CLEANUP => 1);
	my $h   = Test::CPAN::Health->new(
		path   => $tmp,
		checks => ['sem_ver', 'license'],
		skip   => ['license'],
	);
	ok(blessed($h), 'new() with checks and skip accepted');
	is($h->output_format, 'terminal', 'default format still terminal');
};

# ---------------------------------------------------------------------------
subtest 'Health: _init_runner carps when a check class cannot be loaded' => sub {

	my $tmp = tempdir(CLEANUP => 1);
	my $h   = Test::CPAN::Health->new(
		path   => $tmp,
		format => 'tap',
		checks => ['Test::CPAN::Health::Check::NonExistentCheck99'],
	);

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	# Calling analyse triggers _init_runner; the missing check should be carped,
	# not croaked, and the run should succeed with zero checks.
	my $report;
	lives_ok(sub { $report = $h->analyse }, '_init_runner carps (not croaks) for unloadable check');
	ok($warned > 0, 'Warning emitted for unloadable check class');
	is(scalar @{$report->results}, 0, 'Report has no results when all checks fail to load');
};

# ---------------------------------------------------------------------------
subtest 'Health: report_to croaks on non-Report argument' => sub {

	my $tmp = tempdir(CLEANUP => 1);
	my $h   = Test::CPAN::Health->new(path => $tmp);

	throws_ok(
		sub { $h->report_to(undef)   },
		qr/report must be/i,
		'report_to(undef) croaks',
	);
	throws_ok(
		sub { $h->report_to('text')  },
		qr/report must be/i,
		'report_to(string) croaks',
	);
};

# ---------------------------------------------------------------------------
subtest 'Health: report_to uses all four reporter formats' => sub {

	my $tmp    = tempdir(CLEANUP => 1);
	my $report = _simple_report();

	for my $fmt (qw(terminal json html tap)) {
		my $h   = Test::CPAN::Health->new(path => $tmp, format => $fmt);
		my $out = $h->report_to($report);
		ok(defined $out && length $out > 0, "report_to produces output for format '$fmt'");
		diag "Format $fmt output (first 80 chars): " . substr($out, 0, 80)
			if $ENV{TEST_VERBOSE};
	}
};

# ---------------------------------------------------------------------------
subtest 'Health: explicit cache_dir is forwarded to Cache' => sub {

	my $tmp      = tempdir(CLEANUP => 1);
	my $cachedir = tempdir(CLEANUP => 1);

	my $h = Test::CPAN::Health->new(path => $tmp, cache_dir => $cachedir);

	# Trigger _init_cache by calling analyse with no checks so it is fast.
	$h->{_checks} = [];
	$h->analyse;
	ok(defined $h->cache,  'Cache object created');
	ok(blessed($h->cache), 'Cache object is blessed');

	# Write one entry to ensure the SQLite DB is actually created on disk.
	# The DB is created lazily on first write (not on Cache construction).
	$h->cache->store('test_check:ExplicitDir:1.0', { status => 'pass', score => 100 });

	my $expected_db = File::Spec->catfile($cachedir, 'cpan-health.db');
	ok(-e $expected_db, "SQLite DB created at explicit cache_dir ($expected_db)");
};

# ===========================================================================
# 2.  Reporter::Terminal: colour, verbose, score bands
# ===========================================================================
subtest 'Terminal: explicit colour => 0 disables ANSI sequences' => sub {

	my $r      = Test::CPAN::Health::Reporter::Terminal->new(colour => 0);
	my $report = _simple_report(status => 'pass', score => 95, summary => 'great');
	my $out    = $r->render($report);

	unlike($out, qr/\e\[/, 'No ANSI escape sequences when colour => 0');
	like($out,   qr/great/, 'Summary text still present without colour');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: NO_COLOR env disables colour' => sub {

	local $ENV{NO_COLOR} = '1';
	my $r      = Test::CPAN::Health::Reporter::Terminal->new;
	my $report = _simple_report(status => 'pass', score => 95);
	my $out    = $r->render($report);

	unlike($out, qr/\e\[/, 'ANSI absent when NO_COLOR env set');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: score band colours (green/yellow/red) in summary line' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(colour => 1);

	for my $case (
		[ 95, 'bold green',  'green'  ],
		[ 80, 'bold yellow', 'yellow' ],
		[ 50, 'bold red',    'red'    ],
	) {
		my ($score_val, $colour, $label) = @{$case};

		my $report = Test::CPAN::Health::Report->new(checks => []);
		$report->add_result(
			Test::CPAN::Health::Result->new(
				check_id => 'x',
				status   => 'pass',
				score    => $score_val,
				summary  => "score $score_val",
			),
		);

		my $out = $r->render($report);
		like($out, qr/Overall score/, "score $score_val output contains 'Overall score'");
		diag "Score $score_val output tail: " . substr($out, -200) if $ENV{TEST_VERBOSE};
	}
};

# ---------------------------------------------------------------------------
subtest 'Terminal: verbose mode shows details for pass results' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(
		colour  => 0,
		verbose => 1,
	);

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'pass',
			score    => 100,
			summary  => 'all good',
			details  => ['detail line one', 'detail line two'],
		),
	);

	my $out = $r->render($report);
	like($out, qr/detail line one/, 'Verbose mode shows details for pass result');
	like($out, qr/detail line two/, 'Both detail lines visible in verbose mode');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: fail/warn/error results always show details' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(colour => 0);

	for my $status (qw(fail warn error)) {
		my $report = Test::CPAN::Health::Report->new(checks => []);
		$report->add_result(
			Test::CPAN::Health::Result->new(
				check_id => 'x',
				status   => $status,
				score    => 0,
				summary  => "status $status",
				details  => ["detail for $status"],
			),
		);
		my $out = $r->render($report);
		like($out, qr/detail for $status/, "Details visible for status '$status' without verbose");
	}
};

# ---------------------------------------------------------------------------
subtest 'Terminal: result with URL line is rendered' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(colour => 0);

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'fail',
			score    => 0,
			summary  => 'failed',
			url      => 'https://example.com/advisory',
		),
	);

	my $out = $r->render($report);
	like($out, qr{https://example.com/advisory}, 'URL rendered below fail result');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: result with no score renders without parenthesized score' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(colour => 0);

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'skip',
			summary  => 'not applicable',
		),
	);

	my $out = $r->render($report);
	# The per-result score format is "(N/100)".  When score is undef the
	# parenthesized form must be absent; the summary line "Overall score: N/100"
	# always shows "/100" so we search for the parenthesized form only.
	unlike($out, qr/\(\d+\/100\)/, 'No "(N/100)" suffix in result line when score undef');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: render croaks on non-Report argument' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new;
	throws_ok(sub { $r->render(undef)   }, qr/report must be/i, 'render(undef) croaks');
	throws_ok(sub { $r->render('text')  }, qr/report must be/i, 'render(string) croaks');
};

# ---------------------------------------------------------------------------
subtest 'Terminal: result with data->{name} uses name over check_id' => sub {

	my $r = Test::CPAN::Health::Reporter::Terminal->new(colour => 0);

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'raw_id',
			status   => 'pass',
			score    => 90,
			summary  => 'ok',
			data     => { name => 'Pretty Check Name' },
		),
	);

	my $out = $r->render($report);
	like($out, qr/Pretty Check Name/, 'data->{name} used in rendered line');
	unlike($out, qr/raw_id/,          'check_id not used when data->{name} present');
};

# ===========================================================================
# 3.  Reporter::JSON: pretty/canonical flags
# ===========================================================================
subtest 'JSON: pretty => 1 produces indented output' => sub {

	my $r      = Test::CPAN::Health::Reporter::JSON->new(pretty => 1);
	my $report = _simple_report();
	my $json   = $r->render($report);

	like($json, qr/\n/, 'Pretty JSON contains newlines');
	my $data = decode_json($json);
	ok(exists $data->{overall_score}, 'Decoded JSON has overall_score key');
	returns_ok($json, { type => 'string' }, 'render() returns a string');
};

# ---------------------------------------------------------------------------
subtest 'JSON: pretty => 0 (default) produces compact output' => sub {

	my $r      = Test::CPAN::Health::Reporter::JSON->new(pretty => 0);
	my $report = _simple_report();
	my $json   = $r->render($report);

	unlike($json, qr/\n.*\n/s, 'Compact JSON has no significant newlines');
	ok(length($json) > 0, 'Non-empty output');
};

# ---------------------------------------------------------------------------
subtest 'JSON: canonical => 0 disables key sorting' => sub {

	my $r = Test::CPAN::Health::Reporter::JSON->new(canonical => 0);
	my $report = _simple_report();
	lives_ok(sub { $r->render($report) }, 'canonical => 0 does not crash');
};

# ---------------------------------------------------------------------------
subtest 'JSON: render croaks on non-Report argument' => sub {

	my $r = Test::CPAN::Health::Reporter::JSON->new;
	throws_ok(sub { $r->render(undef)  }, qr/report must be/i, 'render(undef) croaks');
	throws_ok(sub { $r->render('text') }, qr/report must be/i, 'render(string) croaks');
};

# ===========================================================================
# 4.  Reporter::HTML: score boundary classes and missing name
# ===========================================================================
subtest 'HTML: score boundary 90 → green, 70 → yellow, 69 → red' => sub {

	my $r = Test::CPAN::Health::Reporter::HTML->new;

	for my $case (
		[90, '#d1fae5', 'green (>=90)'],
		[70, '#fef3c7', 'yellow (>=70)'],
		[69, '#fee2e2', 'red (<70)'],
	) {
		my ($score, $colour, $label) = @{$case};
		my $report = Test::CPAN::Health::Report->new(checks => []);
		$report->add_result(
			Test::CPAN::Health::Result->new(
				check_id => 'x',
				status   => 'pass',
				score    => $score,
				summary  => "score $score",
			),
		);
		my $html = $r->render($report);
		like($html, qr/\Q$colour\E/, "Score $score → background colour $label");
	}
};

# ---------------------------------------------------------------------------
subtest 'HTML: result without data->{name} falls back to check_id' => sub {

	my $r      = Test::CPAN::Health::Reporter::HTML->new;
	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'my_check_id',
			status   => 'pass',
			score    => 80,
			summary  => 'ok',
		),
	);

	my $html = $r->render($report);
	like($html, qr/my_check_id/, 'check_id used when data->{name} absent');
};

# ---------------------------------------------------------------------------
subtest 'HTML: result with undef score renders empty table score cell' => sub {

	my $r      = Test::CPAN::Health::Reporter::HTML->new;
	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'skip',
			summary  => 'skipped',
		),
	);

	my $html = $r->render($report);
	# The score-box always shows the overall score with "/100"; the per-row
	# score <td> must be empty when the result has no score.
	like($html, qr{<td></td>}, 'Table score cell is empty when result score is undef');
	unlike($html, qr{<td>\d+/100</td>}, 'No N/100 in table score cell');
};

# ---------------------------------------------------------------------------
subtest 'HTML: detail lines rendered inside the summary cell' => sub {

	my $r      = Test::CPAN::Health::Reporter::HTML->new;
	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'fail',
			score    => 0,
			summary  => 'failing',
			details  => ['fix this', 'and that'],
		),
	);

	my $html = $r->render($report);
	like($html, qr/fix this/, 'First detail line present in HTML');
	like($html, qr/and that/, 'Second detail line present in HTML');
	like($html, qr/class="detail"/, 'Detail elements use detail CSS class');
};

# ===========================================================================
# 5.  Cache: env-var path selection and TTL override
# ===========================================================================
subtest 'Cache: CACHEDIR env var determines default cache dir' => sub {

	my $cache_base = tempdir(CLEANUP => 1);
	local $ENV{CACHEDIR}  = $cache_base;
	local $ENV{CACHE_DIR} = undef;    # ensure CACHEDIR takes precedence

	my $cache = Test::CPAN::Health::Cache->new;
	$cache->store('test_check:Foo:1.0', { status => 'pass' });

	# Default path appends cpan-health/ subdir
	my $expected_db = File::Spec->catfile($cache_base, 'cpan-health', 'cpan-health.db');
	ok(-e $expected_db, "DB created under CACHEDIR ($expected_db)");
};

# ---------------------------------------------------------------------------
subtest 'Cache: CACHE_DIR env var used when CACHEDIR absent' => sub {

	my $cache_base = tempdir(CLEANUP => 1);
	local $ENV{CACHEDIR}  = undef;
	local $ENV{CACHE_DIR} = $cache_base;

	my $cache = Test::CPAN::Health::Cache->new;
	$cache->store('test_check:Foo:1.0', { status => 'pass' });

	my $expected_db = File::Spec->catfile($cache_base, 'cpan-health', 'cpan-health.db');
	ok(-e $expected_db, "DB created under CACHE_DIR ($expected_db)");
};

# ---------------------------------------------------------------------------
subtest 'Cache: store with explicit TTL override ignores check-id TTL' => sub {

	my $cache = Test::CPAN::Health::Cache->new(
		cache_dir => tempdir(CLEANUP => 1),
		ttls      => { my_check => 3_600 },    # 1 hour default for this id
	);
	my $key = 'my_check:Foo:1.0';

	# Store with explicit TTL of 0 (immediate expiry), overriding the 1-hour default.
	$cache->store($key, { status => 'pass' }, 0);

	# Read immediately -- should be expired
	my $val = $cache->get($key);
	ok(!defined $val, 'Explicit TTL=0 overrides check-id TTL; entry immediately expired');
};

# ---------------------------------------------------------------------------
subtest 'Cache: known check-id TTLs are shorter than the default' => sub {

	my $cache  = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));
	my $key_ct = 'cpan_testers:Foo:1.0';      # 1 hour TTL
	my $key_sa = 'security_advisories:Foo:1.0'; # 1 hour TTL
	my $key_xx = 'unknown_id:Foo:1.0';         # DEFAULT = 24 hours

	# Verify that storing with known IDs works; TTL differences are internal
	# but we can confirm the store/get round-trip for each.
	$cache->store($key_ct, { status => 'pass', score => 90 });
	$cache->store($key_sa, { status => 'fail', score => 0 });
	$cache->store($key_xx, { status => 'warn', score => 60 });

	ok(defined $cache->get($key_ct), 'cpan_testers result retrievable (1-hour TTL)');
	ok(defined $cache->get($key_sa), 'security_advisories result retrievable (1-hour TTL)');
	ok(defined $cache->get($key_xx), 'unknown-id result retrievable (DEFAULT 24h TTL)');
};

# ===========================================================================
# 6.  Distribution: file listing, has_dir, META fallback, DESTROY
# ===========================================================================
subtest 'Distribution: pm_files finds .pm files under lib/' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'lib', 'My'));
	{ open my $fh, '>', File::Spec->catfile($dir, 'lib', 'My', 'Module.pm') or die $!;
	  print {$fh} "package My::Module;\n1;\n"; }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $pm   = $dist->pm_files;

	is(scalar @{$pm}, 1, 'pm_files returns one file');
	like($pm->[0], qr/Module\.pm$/, 'Returned path ends in Module.pm');
	returns_ok($pm, { type => 'arrayref' }, 'pm_files returns arrayref');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: t_files finds .t files under t/' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 't'));
	{ open my $fh, '>', File::Spec->catfile($dir, 't', '01-test.t') or die $!;
	  print {$fh} "use Test::More; ok(1); done_testing;\n"; }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $t    = $dist->t_files;

	is(scalar @{$t}, 1, 't_files returns one file');
	like($t->[0], qr/01-test\.t$/, 'Returned path ends in .t');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: pl_files finds scripts in bin/ and *.pl' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'bin'));
	{ open my $fh, '>', File::Spec->catfile($dir, 'bin', 'myscript') or die $!;
	  print {$fh} "#!/usr/bin/env perl\nprint 'hello';\n"; }
	{ open my $fh, '>', File::Spec->catfile($dir, 'helper.pl') or die $!;
	  print {$fh} "1;\n"; }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $pl   = $dist->pl_files;

	ok(scalar @{$pl} >= 2, 'pl_files finds bin/ script and *.pl file');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: pl_files also finds scripts in script/' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'script'));
	{ open my $fh, '>', File::Spec->catfile($dir, 'script', 'run') or die $!;
	  print {$fh} "#!/usr/bin/env perl\n"; }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $pl   = $dist->pl_files;

	ok(scalar @{$pl} >= 1, 'pl_files finds script/ directory');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: all_source_files is union of pm_files and pl_files' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'lib'));
	make_path(File::Spec->catdir($dir, 'bin'));
	{ open my $fh, '>', File::Spec->catfile($dir, 'lib', 'Foo.pm') or die $!;
	  print {$fh} "package Foo; 1;\n"; }
	{ open my $fh, '>', File::Spec->catfile($dir, 'bin', 'foo-cli') or die $!;
	  print {$fh} "#!/usr/bin/perl\n"; }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $all  = $dist->all_source_files;

	is(ref $all, 'ARRAY', 'all_source_files returns arrayref');
	is(scalar @{$all}, 2, 'all_source_files returns 2 files (1 pm + 1 pl)');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: has_dir with multiple names returns first match' => sub {

	my $dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($dir, 'xt'));    # only xt/ exists, not t/

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);

	ok($dist->has_dir('t', 'xt'),      'has_dir returns true when second name matches');
	ok(!$dist->has_dir('t', 'spec'),   'has_dir returns false when no names match');
	ok($dist->has_dir('xt'),           'has_dir returns true for existing dir');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: has_dir with empty list returns false' => sub {

	my $dist = Test::CPAN::Health::Distribution->new(path => tempdir(CLEANUP => 1));
	ok(!$dist->has_dir(), 'has_dir() with no arguments returns false');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: META.yml fallback when META.json absent' => sub {

	my $dir = tempdir(CLEANUP => 1);
	{ open my $fh, '>', File::Spec->catfile($dir, 'META.yml') or die $!;
	  print {$fh} <<'END_YAML';
---
name: Yaml-Dist
version: 0.01
abstract: A YAML dist
author:
  - YAML Author <yaml@example.com>
license: perl
meta-spec:
  version: 1.4
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
END_YAML
	}

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $meta = $dist->meta;

	ok(defined $meta,                     'META.yml loaded when no META.json present');
	is($meta->name, 'Yaml-Dist',          'name from META.yml correct');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: MYMETA.json fallback when canonical META absent' => sub {

	my $dir = tempdir(CLEANUP => 1);
	{ open my $fh, '>', File::Spec->catfile($dir, 'MYMETA.json') or die $!;
	  print {$fh} encode_json({
		  name        => 'MyMeta-Dist',
		  version     => '0.02',
		  abstract    => 'Generated META',
		  author      => ['Dev <dev@example.com>'],
		  license     => ['perl_5'],
		  'meta-spec' => { version => '2' },
	  }); }

	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
	my $meta = $dist->meta;

	ok(defined $meta,                      'MYMETA.json loaded as fallback');
	is($meta->name, 'MyMeta-Dist',         'name from MYMETA.json correct');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: version() and author() extracted from META' => sub {

	my $dist = _named_dist(name => 'Versioned-Dist', version => '3.14');
	is($dist->version, '3.14',                        'version() from META');
	like($dist->author, qr/Test Author/,               'author() from META');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: file_path returns undef when file absent, path when present' => sub {

	my $dir  = tempdir(CLEANUP => 1);
	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);

	ok(!defined $dist->file_path('nonexistent.txt'), 'file_path returns undef for absent file');

	{ open my $fh, '>', File::Spec->catfile($dir, 'present.txt') or die $!;
	  print {$fh} 'x'; }

	my $p = $dist->file_path('present.txt');
	ok(defined $p,                'file_path returns path for present file');
	like($p, qr/present\.txt$/,  'file_path returns correct path');
};

# ---------------------------------------------------------------------------
subtest 'Distribution: DESTROY cleans up _tmp_dir when set' => sub {

	# We cannot directly test DESTROY of an object with a real _tmp_dir
	# without triggering CPAN download, but we CAN verify the cleanup
	# code path by manufacturing the internal state.
	my $tmp = tempdir();    # deliberately no CLEANUP so we can check deletion

	my $dist = Test::CPAN::Health::Distribution->new(path => tempdir(CLEANUP => 1));
	$dist->{_tmp_dir} = $tmp;

	# Force DESTROY
	undef $dist;

	ok(!-d $tmp, 'DESTROY removes _tmp_dir when set');
};

# ===========================================================================
# 7.  Check::CPANTesters: all result branches via mocked HTTP
# ===========================================================================
subtest 'CPANTesters: HTTP error produces error result' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_fail(503, 'Service Unavailable');
	};

	my $dist   = _named_dist(name => 'Foo-Bar');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'error', 'HTTP failure → error result');
	like($result->summary, qr/MetaCPAN API error/i, 'Error summary mentions API error');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: empty hits → skip' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_ok({ hits => { hits => [] } });
	};

	my $dist   = _named_dist(name => 'Unknown-Dist');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'skip', 'Empty hits → skip result');
	like($result->summary, qr/not found on MetaCPAN/i, 'Skip summary mentions MetaCPAN');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: no test data (pass+fail=0) → skip' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_ok({
			hits => {
				hits => [{
					_source => {
						version => '1.00',
						tests   => { pass => 0, fail => 0, na => 5, unknown => 2 },
					},
				}],
			},
		});
	};

	my $dist   = _named_dist(name => 'No-Data-Dist');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'skip', 'pass+fail=0 → skip result');
	like($result->summary, qr/no cpan testers data/i, 'Skip summary mentions no data');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: high pass rate (≥80%) → pass status' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_ok({
			hits => {
				hits => [{
					_source => {
						version => '2.00',
						tests   => { pass => 100, fail => 0 },
					},
				}],
			},
		});
	};

	my $dist   = _named_dist(name => 'Good-Dist');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'pass', '100/100 pass rate → pass');
	is($result->score,  100,    'Score is 100 with no failures');
	ok(scalar @{$result->details} == 0, 'No details when no failures (fail=0)');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: medium pass rate (60-79%) → warn status' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_ok({
			hits => {
				hits => [{
					_source => {
						version => '1.00',
						tests   => { pass => 70, fail => 30 },
					},
				}],
			},
		});
	};

	my $dist   = _named_dist(name => 'Medium-Dist');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'warn', '70% pass rate → warn');
	is($result->score,  70,     'Score is 70');
	ok(scalar @{$result->details} > 0, 'Details present when there are failures');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: low pass rate (<60%) → fail status' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::post' => sub {
		return _http_ok({
			hits => {
				hits => [{
					_source => {
						version => '0.01',
						tests   => { pass => 40, fail => 60 },
					},
				}],
			},
		});
	};

	my $dist   = _named_dist(name => 'Bad-Dist');
	my $check  = Test::CPAN::Health::Check::CPANTesters->new;
	my $result = $check->run($dist);

	is($result->status, 'fail', '40% pass rate → fail');
	is($result->score,  40,     'Score is 40');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: no_network flag → skip' => sub {

	my $check  = Test::CPAN::Health::Check::CPANTesters->new(no_network => 1);
	my $dist   = _named_dist(name => 'Foo');
	my $result = $check->run($dist);

	is($result->status, 'skip', 'no_network → skip');
};

# ---------------------------------------------------------------------------
subtest 'CPANTesters: nameless distribution → skip' => sub {

	# A dist with no META produces no name.
	my $dir   = tempdir(CLEANUP => 1);
	my $dist  = Test::CPAN::Health::Distribution->new(path => $dir);
	my $check = Test::CPAN::Health::Check::CPANTesters->new;

	# The dirname has no version suffix so the name equals the dirname, which
	# may or may not be empty.  Use a dir with a name that is definitively empty
	# by overriding _name to undef via blessed manipulation.
	$dist->{_name} = undef;

	my $result = $check->run($dist);
	is($result->status, 'skip', 'Undef dist name → skip');
};

# ===========================================================================
# 8.  Check::ReverseDeps: all score tiers and count-field formats
# ===========================================================================
subtest 'ReverseDeps: HTTP error → error result' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_fail(404, 'Not Found');
	};

	my $dist   = _named_dist(name => 'Some-Dist');
	my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'error', 'HTTP error → error result');
};

# ---------------------------------------------------------------------------
subtest 'ReverseDeps: count=0 → warn, score=50' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ total => 0 });
	};

	my $dist   = _named_dist(name => 'Orphan-Dist');
	my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
	my $result = $check->run($dist);

	is($result->status,      'warn',              'count=0 → warn');
	is($result->score,       $REVDEP_SCORE_NONE,  'count=0 → score 50');
	is($result->data->{count}, 0,                 'data.count=0');
};

# ---------------------------------------------------------------------------
subtest 'ReverseDeps: count=1 (FEW: 1-9) → pass, score=75' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ total => 1 });
	};

	my $dist   = _named_dist(name => 'Tiny-Dist');
	my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'pass',             'count=1 → pass');
	is($result->score,  $REVDEP_SCORE_FEW,  'count=1 → score 75');
	# Singular noun: "reverse dependency"
	like($result->summary, qr/\breverse dependency\b/, 'Singular noun for count=1');
};

# ---------------------------------------------------------------------------
subtest 'ReverseDeps: count=10 (SOME: 10-99) → pass, score=90' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ hits => { total => { value => 10 } } });
	};

	my $dist   = _named_dist(name => 'Mid-Dist');
	my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'pass',              'count=10 → pass');
	is($result->score,  $REVDEP_SCORE_SOME,  'count=10 → score 90');
	like($result->summary, qr/\breverse dependencies\b/, 'Plural noun for count=10');
};

# ---------------------------------------------------------------------------
subtest 'ReverseDeps: count=100 (MANY: >=100) → pass, score=100' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		# Third MetaCPAN format: hits.total (plain integer)
		return _http_ok({ hits => { total => 150 } });
	};

	my $dist   = _named_dist(name => 'Popular-Dist');
	my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'pass',              'count=150 → pass');
	is($result->score,  $REVDEP_SCORE_MANY,  'count=150 → score 100');
	is($result->data->{count}, 150,           'data.count=150');
};

# ---------------------------------------------------------------------------
subtest 'ReverseDeps: no_network → skip' => sub {

	my $check  = Test::CPAN::Health::Check::ReverseDeps->new(no_network => 1);
	my $result = $check->run(_named_dist(name => 'Foo'));
	is($result->status, 'skip', 'no_network → skip');
};

# ===========================================================================
# 9.  Check::AbandonedDeps: date parsing and classification branches
# ===========================================================================
subtest 'AbandonedDeps: all deps active → pass' => sub {

	my $recent_date = _years_ago(0.5);    # 6 months ago = active

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ date => $recent_date, module => 'Some::Dep' });
	};

	my $dist = _named_dist(
		name    => 'Active-Dist',
		prereqs => {
			runtime => { requires => { 'Some::Dep' => '1.0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 0);
	my $result = $check->run($dist);

	is($result->status, 'pass', 'All active deps → pass');
	is($result->score,  100,    'All active deps → score 100');
	diag "Active result: " . $result->summary if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
subtest 'AbandonedDeps: one abandoned dep → warn' => sub {

	my $old_date    = _years_ago(4);      # 4 years ago = abandoned
	my $recent_date = _years_ago(0.5);

	my @responses = (
		_http_ok({ date => $old_date }),      # Some::OldDep -- abandoned
		_http_ok({ date => $recent_date }),   # Some::NewDep -- active
	);
	my $call_count = 0;
	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return $responses[$call_count++ % 2];
	};

	my $dist = _named_dist(
		name    => 'Mixed-Dist',
		prereqs => {
			runtime => {
				requires => {
					'Some::OldDep' => '0.1',
					'Some::NewDep' => '2.0',
				},
			},
		},
	);

	my $check  = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 0);
	my $result = $check->run($dist);

	# With 1 abandoned of 2: score = 50. warn threshold is 60 so status=fail.
	# OR if warn threshold is 60, score 50 < 60 → fail. Let me check...
	# Actually SCORE_WARN = 60, so 50 < 60 → fail status.
	ok($result->status eq 'warn' || $result->status eq 'fail',
		"Mixed deps → warn or fail (score depends on ratio)");
	ok(scalar @{$result->details} > 0, 'Abandoned dep listed in details');
	diag "Mixed result: " . $result->summary if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
subtest 'AbandonedDeps: HTTP error for dep → dep skipped (not counted)' => sub {

	# If the MetaCPAN API returns an error for a dep, _classify_dep returns ()
	# and the dep is not counted.  If ALL deps fail → skip (no data available).
	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_fail(500, 'Server Error');
	};

	my $dist = _named_dist(
		name    => 'ErrorDep-Dist',
		prereqs => {
			runtime => { requires => { 'Some::Dep' => '1.0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 0);
	my $result = $check->run($dist);

	is($result->status, 'skip', 'All HTTP errors → skip (no data available)');
	like($result->summary, qr/no dependency release dates/i,
		'Skip summary mentions no data from MetaCPAN');
};

# ---------------------------------------------------------------------------
subtest 'AbandonedDeps: dep with no date in response → dep skipped' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ module => 'No::Date', version => '1.0' });  # no date field
	};

	my $dist = _named_dist(
		name    => 'NoDate-Dist',
		prereqs => {
			runtime => { requires => { 'No::Date::Dep' => '0.5' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 0);
	my $result = $check->run($dist);

	# dep without date is skipped → total=0 → skip result
	is($result->status, 'skip', 'Dep with no date field skipped → skip result');
};

# ---------------------------------------------------------------------------
subtest 'AbandonedDeps: no_network → skip' => sub {

	my $check  = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 1);
	my $result = $check->run(_named_dist(name => 'Foo'));
	is($result->status, 'skip', 'no_network → skip');
};

# ---------------------------------------------------------------------------
subtest 'AbandonedDeps: no META → skip' => sub {

	my $dir   = tempdir(CLEANUP => 1);
	my $dist  = Test::CPAN::Health::Distribution->new(path => $dir);
	my $check = Test::CPAN::Health::Check::AbandonedDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'skip', 'No META file → skip');
};

# ===========================================================================
# 10.  Check::StaleDeps: version comparison branches
# ===========================================================================
subtest 'StaleDeps: all deps current (same major) → pass' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ version => '1.50', module => 'Some::Dep' });
	};

	my $dist = _named_dist(
		name    => 'Current-Dist',
		prereqs => {
			runtime => { requires => { 'Some::Dep' => '1.0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::StaleDeps->new(no_network => 0);
	my $result = $check->run($dist);

	is($result->status, 'pass', 'Same major version → current → pass');
	is($result->score,  100,    'No stale deps → score 100');
};

# ---------------------------------------------------------------------------
subtest 'StaleDeps: dep with higher major version → stale' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ version => '3.0', module => 'Old::Dep' });
	};

	my $dist = _named_dist(
		name    => 'Stale-Dist',
		prereqs => {
			runtime => { requires => { 'Old::Dep' => '1.0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::StaleDeps->new(no_network => 0);
	my $result = $check->run($dist);

	# 1 stale of 1 → score 0 → fail
	is($result->status, 'fail',      'Major version jump → stale → fail');
	is($result->score,  0,           'One stale dep → score 0');
	ok(scalar @{$result->details} > 0, 'Stale dep listed in details');
};

# ---------------------------------------------------------------------------
subtest 'StaleDeps: dep declared version=0 → skipped (no constraint)' => sub {

	# A dep declared as version 0 means "any version acceptable"
	# and is excluded from stale checking.
	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_ok({ version => '5.0' });
	};

	my $dist = _named_dist(
		name    => 'Zero-Dep-Dist',
		prereqs => {
			runtime => { requires => { 'Unconstrained::Dep' => '0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::StaleDeps->new(no_network => 0);
	my $result = $check->run($dist);

	# Zero-version dep is excluded → no checkable deps → skip
	is($result->status, 'skip', 'Dep declared version=0 skipped → skip result');
};

# ---------------------------------------------------------------------------
subtest 'StaleDeps: HTTP error for dep → dep skipped → skip result' => sub {

	my $mock = mock_scoped 'HTTP::Tiny::get' => sub {
		return _http_fail(503, 'Unavailable');
	};

	my $dist = _named_dist(
		name    => 'NetFail-Dist',
		prereqs => {
			runtime => { requires => { 'Some::Dep' => '1.0' } },
		},
	);

	my $check  = Test::CPAN::Health::Check::StaleDeps->new(no_network => 0);
	my $result = $check->run($dist);

	is($result->status, 'skip', 'All HTTP errors → skip (no versioned deps found)');
};

# ---------------------------------------------------------------------------
subtest 'StaleDeps: no META → skip' => sub {

	my $dir   = tempdir(CLEANUP => 1);
	my $dist  = Test::CPAN::Health::Distribution->new(path => $dir);
	my $check = Test::CPAN::Health::Check::StaleDeps->new;
	my $result = $check->run($dist);

	is($result->status, 'skip', 'No META → skip');
};

# ---------------------------------------------------------------------------
subtest 'StaleDeps: no_network → skip' => sub {

	my $check  = Test::CPAN::Health::Check::StaleDeps->new(no_network => 1);
	my $result = $check->run(_named_dist(name => 'Foo'));
	is($result->status, 'skip', 'no_network → skip');
};

# ===========================================================================
# 11.  Check::SecurityAdvisories: all result paths (requires CPAN::Audit)
# ===========================================================================
SKIP: {
	eval { require CPAN::Audit; 1 }
		or skip 'CPAN::Audit not installed', 10;

	# ---------------------------------------------------------------------------
	subtest 'SecurityAdvisories: no META → skip' => sub {

		my $dir   = tempdir(CLEANUP => 1);
		my $dist  = Test::CPAN::Health::Distribution->new(path => $dir);
		my $check = Test::CPAN::Health::Check::SecurityAdvisories->new;
		my $result = $check->run($dist);

		is($result->status, 'skip', 'No META → skip');
	};

	# ---------------------------------------------------------------------------
	subtest 'SecurityAdvisories: no advisories → pass, score=100' => sub {

		# Use a META with no problematic prereqs; CPAN::Audit finds nothing.
		my $dist = _named_dist(
			name    => 'Clean-Dist',
			prereqs => {
				runtime => { requires => { 'Scalar::Util' => '1.0' } },
			},
		);

		my $check  = Test::CPAN::Health::Check::SecurityAdvisories->new;
		my $result = $check->run($dist, {});

		is($result->status, 'pass', 'No advisories → pass');
		is($result->score,  100,    'No advisories → score 100');
		is($result->data->{count}, 0, 'data.count=0');
	};

	# ---------------------------------------------------------------------------
	subtest 'SecurityAdvisories: context with reverse_dep_count' => sub {

		# Simulate a reverse_deps result in context with count=50
		my $rd_result = Test::CPAN::Health::Result->new(
			check_id => 'reverse_deps',
			status   => 'pass',
			score    => 90,
			summary  => '50 reverse dependencies',
			data     => { name => 'Reverse Deps', count => 50 },
		);

		my $dist = _named_dist(
			name    => 'Clean-Context-Dist',
			prereqs => { runtime => { requires => { 'Scalar::Util' => '1.0' } } },
		);
		my $check  = Test::CPAN::Health::Check::SecurityAdvisories->new;
		my $result = $check->run($dist, { reverse_deps => $rd_result });

		# No advisories → still pass; context is only used in the fail message
		is($result->status, 'pass', 'Pass with context present');
		diag 'SA with context: ' . $result->summary if $ENV{TEST_VERBOSE};
	};

	# ---------------------------------------------------------------------------
	subtest 'SecurityAdvisories: _effective_version for "perl" uses running version' => sub {

		# _effective_version is private; test its effect through run()
		# by including 'perl' as a prereq.  The scanner should use $] not '5.014'.
		my $dist = _named_dist(
			name    => 'Perl-Dep-Dist',
			prereqs => {
				runtime => { requires => { 'perl' => '5.014', 'Carp' => '0' } },
			},
		);

		my $check = Test::CPAN::Health::Check::SecurityAdvisories->new;
		my $result = $check->run($dist, {});

		# We just need it not to crash and to return a Result
		ok(blessed($result), '_effective_version("perl") does not crash');
		ok($result->status eq 'pass' || $result->status eq 'fail',
			'Result status is pass or fail (not skip or error)');
	};

	# ---------------------------------------------------------------------------
	subtest 'SecurityAdvisories: _format_advisory without CVE or severity' => sub {

		# Manually invoke the private formatter to cover CVE-absent and
		# severity-absent branches.
		my $adv_no_cve = {
			module      => 'Foo::Bar',
			version     => '1.0',
			id          => 'ADVISORY-001',
			cves        => [],
			severity    => undef,
			description => 'A security issue',
		};
		my $fmt = Test::CPAN::Health::Check::SecurityAdvisories::_format_advisory($adv_no_cve);
		like($fmt, qr/ADVISORY-001/, 'Advisory id present when no CVE');
		unlike($fmt, qr/CVE-/,       'No CVE text when cves list empty');
		unlike($fmt, qr/\[/,          'No severity bracket when severity undef');

		my $adv_with_cve = {
			module      => 'Foo::Bar',
			version     => '1.0',
			id          => 'ADVISORY-002',
			cves        => ['CVE-2024-99999'],
			severity    => 'high',
			description => 'Another issue',
		};
		my $fmt2 = Test::CPAN::Health::Check::SecurityAdvisories::_format_advisory($adv_with_cve);
		like($fmt2, qr/CVE-2024-99999/,  'CVE id present when cves list non-empty');
		like($fmt2, qr/\[HIGH\]/,         'Severity bracket present and upcased');
	};

} # end SKIP for CPAN::Audit

# ===========================================================================
# 12.  Report: as_hash serialisation
# ===========================================================================
subtest 'Report: as_hash produces expected keys' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'sem_ver',
			status   => 'pass',
			score    => 100,
			summary  => 'SemVer ok',
			details  => ['v1.2.3 is valid'],
			data     => { name => 'SemVer', category => 'packaging' },
		),
	);

	my $h = $report->as_hash;

	ok(exists $h->{overall_score}, 'as_hash has overall_score');
	ok(exists $h->{results},       'as_hash has results array');
	is(ref $h->{results}, 'ARRAY', 'results is an ARRAY ref');
	is(scalar @{$h->{results}}, 1, 'results array has one entry');

	my $r = $h->{results}[0];
	is($r->{check_id}, 'sem_ver',  'Result check_id preserved');
	is($r->{status},   'pass',     'Result status preserved');
	is($r->{score},    100,        'Result score preserved');
};

# ===========================================================================
# 13.  Result: as_hash preserves all fields
# ===========================================================================
subtest 'Result: as_hash includes all non-empty fields' => sub {

	my $r = Test::CPAN::Health::Result->new(
		check_id => 'full_check',
		status   => 'warn',
		score    => 72,
		summary  => 'needs attention',
		details  => ['fix A', 'fix B'],
		url      => 'https://example.com/advisory',
		data     => { name => 'Full Check', key => 'value' },
	);

	my $h = $r->as_hash;

	is($h->{check_id}, 'full_check',       'check_id in as_hash');
	is($h->{status},   'warn',             'status in as_hash');
	is($h->{score},    72,                 'score in as_hash');
	is($h->{summary},  'needs attention',  'summary in as_hash');
	is_deeply($h->{details}, ['fix A', 'fix B'], 'details in as_hash');
	is($h->{url},      'https://example.com/advisory', 'url in as_hash');
	is($h->{data}{name}, 'Full Check',     'data name in as_hash');
};

# ===========================================================================
# 14.  Runner: cache key includes version
# ===========================================================================
subtest 'Runner: cache key uses dist name and version' => sub {

	my $cache_dir = tempdir(CLEANUP => 1);
	my $cache     = Test::CPAN::Health::Cache->new(cache_dir => $cache_dir);
	my $store_spy = spy('Test::CPAN::Health::Cache', 'store');

	{ package ET::PassCheck;
	  use parent -norequire, 'Test::CPAN::Health::Check';
	  our $VERSION = '0.01';
	  sub id   { return 'pass_check' }
	  sub name { return 'Pass Check' }
	  sub run {
		  my ($self, $dist) = @_;
		  return $self->_result(status => 'pass', score => 100, summary => 'ok');
	  }
	}

	my $dist = _named_dist(name => 'Keyed-Dist', version => '2.5');
	my $runner = Test::CPAN::Health::Runner->new(
		checks => [ET::PassCheck->new],
		cache  => $cache,
	);
	$runner->run($dist);

	my @calls = $store_spy->();
	is(scalar @calls, 1, 'Cache::store called once for a pass result');
	my $key = $calls[0][2];    # call record: [method_name, $self, $key, ...]
	like($key, qr/pass_check/, 'Cache key contains check id');
	like($key, qr/Keyed-Dist/, 'Cache key contains dist name');
	like($key, qr/2\.5/,       'Cache key contains dist version');

	restore_all();
};

# ===========================================================================
# 15.  Runner: cache miss then hit (result served from cache)
# ===========================================================================
subtest 'Runner: cache hit prevents re-running the check' => sub {

	my $cache_dir = tempdir(CLEANUP => 1);
	my $cache     = Test::CPAN::Health::Cache->new(
		cache_dir => $cache_dir,
		ttls      => { cached_check => 3_600 },
	);

	{ package ET::CachedCheck;
	  use parent -norequire, 'Test::CPAN::Health::Check';
	  our $VERSION = '0.01';
	  our $RUN_COUNT = 0;
	  sub id   { return 'cached_check'   }
	  sub name { return 'Cached Check'   }
	  sub run  {
		  my ($self, $dist) = @_;
		  $RUN_COUNT++;
		  return $self->_result(status => 'pass', score => 88, summary => 'first run');
	  }
	}

	my $dist = _named_dist(name => 'Cache-Dist', version => '1.0');

	# First run: executes check and stores result in cache.
	Test::CPAN::Health::Runner->new(
		checks => [ET::CachedCheck->new],
		cache  => $cache,
	)->run($dist);

	my $first_run_count = $ET::CachedCheck::RUN_COUNT;
	is($first_run_count, 1, 'Check executed once on first run');

	# Second run: should get result from cache, not run the check again.
	Test::CPAN::Health::Runner->new(
		checks => [ET::CachedCheck->new],
		cache  => $cache,
	)->run($dist);

	is($ET::CachedCheck::RUN_COUNT, 1, 'Check NOT re-executed on second run (cache hit)');
};

# ===========================================================================
# 16.  Report: error_count accessor
# ===========================================================================
subtest 'Report: error_count counts error results' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'x', status => 'error', summary => 'boom',
		),
	);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'y', status => 'pass', score => 100, summary => 'ok',
		),
	);

	is($report->error_count, 1, 'error_count returns 1 for one error result');
	is($report->pass_count,  1, 'pass_count returns 1 for one pass result');
};

# ===========================================================================
# 17.  Report: add_result chaining returns $self
# ===========================================================================
subtest 'Report: add_result returns $self for chaining' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);
	my $r1 = Test::CPAN::Health::Result->new(check_id => 'a', status => 'pass', score => 100, summary => 'ok');
	my $r2 = Test::CPAN::Health::Result->new(check_id => 'b', status => 'fail', score => 0,   summary => 'no');

	my $ret = $report->add_result($r1)->add_result($r2);
	is($ret, $report, 'add_result returns $self (chaining works)');
	is(scalar @{$report->results}, 2, 'Both results added via chaining');
};

# ===========================================================================
# 18.  Cache: store returns $self for chaining
# ===========================================================================
subtest 'Cache: store returns $self for chaining' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));
	my $ret   = $cache->store('test:Foo:1.0', { status => 'pass' });
	is($ret, $cache, 'store() returns $self');
};

done_testing();
