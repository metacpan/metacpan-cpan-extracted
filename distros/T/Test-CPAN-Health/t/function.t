#!/usr/bin/env perl
#
# White-box function tests for all modules under lib/.
# Covers constructors, accessors, predicates, and every private helper that
# the unit tests in t/unit/ do not exercise directly.
#
# Strategy: pure/stateless helpers are called by their fully-qualified package
# name; stateful objects are constructed with real temp directories where
# filesystem access is needed; Test::Mockingbird is used to intercept external
# I/O (network, DBI) so the suite runs offline and without side effects.

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);

use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_ok returns_isnt);
use Test::Memory::Cycle;

# Shared constants eliminate magic literals across all subtests.
Readonly::Hash my %STATUS => (
	PASS  => 'pass',
	WARN  => 'warn',
	FAIL  => 'fail',
	SKIP  => 'skip',
	ERROR => 'error',
);
Readonly::Scalar my $CHECK_ID => 'test_check';
Readonly::Scalar my $SCORE_FULL   => 100;
Readonly::Scalar my $SCORE_HALF   => 50;
Readonly::Scalar my $SCORE_ZERO   => 0;
Readonly::Scalar my $CAP_SECURITY => 60;
Readonly::Scalar my $CAP_CI       => 75;

# ---------------------------------------------------------------------------
# Helper: create a minimal Distribution temp dir.
# Returns the directory path.
# ---------------------------------------------------------------------------
sub _make_dist_dir {
	my (%opts) = @_;

	my $dir = tempdir(CLEANUP => 1);

	make_path(File::Spec->catdir($dir, 'lib'))  if $opts{lib};
	make_path(File::Spec->catdir($dir, 't'))    if $opts{t};
	make_path(File::Spec->catdir($dir, 'bin'))  if $opts{bin};

	if ($opts{lib_pm}) {
		# Write a minimal .pm file under lib/ with content supplied by caller.
		my $pm_dir = File::Spec->catdir($dir, 'lib');
		make_path($pm_dir);
		my $pm_file = File::Spec->catfile($pm_dir, 'MyModule.pm');
		open my $fh, '>', $pm_file or die "Cannot write: $!";
		print {$fh} $opts{lib_pm};
		close $fh;
	}

	return $dir;
}

# ---------------------------------------------------------------------------
# Helper: write a file with given content and return its path.
# ---------------------------------------------------------------------------
sub _write_file {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# Helper: build a minimal Result object for use in Report and Runner tests.
# ---------------------------------------------------------------------------
sub _make_result {
	my (%extra) = @_;
	require Test::CPAN::Health::Result;
	return Test::CPAN::Health::Result->new(
		check_id => $extra{check_id} // $CHECK_ID,
		status   => $extra{status}   // $STATUS{PASS},
		score    => $extra{score}    // $SCORE_FULL,
		summary  => $extra{summary}  // 'All good',
		%extra,
	);
}

# ---------------------------------------------------------------------------
# Inline minimal check and distribution stubs used by Runner tests.
# These packages are declared once and reused.
# ---------------------------------------------------------------------------
{
	package MockCheck;

	use parent -norequire, 'Test::CPAN::Health::Check';

	# The check simply returns whatever $MockCheck::RETURN_VALUE is set to,
	# making it easy to inject different outcomes per test.
	our $RETURN_VALUE;
	our @CALLS;

	sub id       { return 'mock_check' }
	sub name     { return 'Mock Check' }
	sub weight   { return 2 }
	sub category { return 'quality' }

	sub run {
		my ($self, $dist, $context) = @_;
		push @MockCheck::CALLS, { dist => $dist, context => $context };
		return $MockCheck::RETURN_VALUE;
	}
}

{
	package MockDist;

	use parent -norequire, 'Test::CPAN::Health::Distribution';

	# Override the constructor so we do not touch the filesystem.
	# Use exists-checks for name/version so callers can pass explicit undef
	# to test the "no name" / "no version" code paths in Runner::_cache_key.
	sub new {
		my ($class, %args) = @_;
		return bless {
			_path    => $args{path} // '/fake/path',
			_name    => (exists $args{name}    ? $args{name}    : 'Fake-Dist'),
			_version => (exists $args{version} ? $args{version} : '1.00'),
		}, $class;
	}
	sub path    { return $_[0]->{_path}    }
	sub name    { return $_[0]->{_name}    }
	sub version { return $_[0]->{_version} }
	sub meta    { return undef }
}

# ===========================================================================
# 1. Test::CPAN::Health::Result
# ===========================================================================
subtest 'Result: constructor, accessors, predicates, as_hash' => sub {
	require Test::CPAN::Health::Result;

	# --- valid construction ---

	my $r = Test::CPAN::Health::Result->new(
		check_id => 'sem_ver',
		status   => $STATUS{PASS},
		score    => $SCORE_FULL,
		summary  => 'Version 1.2.3 is valid semver',
		details  => ['hint one', 'hint two'],
		url      => 'https://example.com',
		data     => { foo => 'bar' },
	);

	ok(blessed($r) && $r->isa('Test::CPAN::Health::Result'), 'constructor returns blessed object');

	is($r->check_id, 'sem_ver',                   'check_id accessor');
	is($r->status,   $STATUS{PASS},               'status accessor');
	is($r->score,    $SCORE_FULL,                 'score accessor');
	is($r->summary,  'Version 1.2.3 is valid semver', 'summary accessor');
	is_deeply($r->details, ['hint one', 'hint two'], 'details accessor');
	is($r->url, 'https://example.com',            'url accessor');
	is_deeply($r->data, { foo => 'bar' },         'data accessor');

	# --- predicates: one fires, the rest must not ---

	ok( $r->is_pass,   'is_pass true when status=pass');
	ok(!$r->is_warn,   'is_warn false when status=pass');
	ok(!$r->is_fail,   'is_fail false when status=pass');
	ok(!$r->is_skip,   'is_skip false when status=pass');
	ok(!$r->is_error,  'is_error false when status=pass');

	for my $status (qw(warn fail skip error)) {
		my $obj = _make_result(status => $status, score => undef);
		my $pred = "is_$status";
		ok($obj->$pred(), "$pred true when status=$status");
	}

	# --- invalid status must croak with a useful message ---

	throws_ok {
		Test::CPAN::Health::Result->new(
			check_id => 'x',
			status   => 'bogus',
		);
	} qr/Invalid status 'bogus'/, 'constructor croaks on invalid status';

	# --- as_hash produces a plain hashref with independent copies ---

	my $h = $r->as_hash;
	returns_ok($h, { type => 'hashref' }, 'as_hash returns hashref');
	is($h->{check_id}, 'sem_ver',      'as_hash check_id');
	is($h->{status},   $STATUS{PASS},  'as_hash status');
	is($h->{score},    $SCORE_FULL,    'as_hash score');

	# Mutating the returned arrayref/hashref must not corrupt the original.
	push @{$h->{details}}, 'injected';
	is(scalar @{$r->details}, 2, 'as_hash details is a deep copy');
	$h->{data}{injected} = 1;
	ok(!exists $r->data->{injected}, 'as_hash data is a deep copy');

	# --- optional fields default properly ---

	my $bare = Test::CPAN::Health::Result->new(
		check_id => 'x',
		status   => $STATUS{FAIL},
	);
	is($bare->summary, '', 'summary defaults to empty string');
	is_deeply($bare->details, [], 'details defaults to empty arrayref');
	is_deeply($bare->data,    {}, 'data defaults to empty hashref');
	ok(!defined $bare->score,     'score defaults to undef');
	ok(!defined $bare->url,       'url defaults to undef');

	memory_cycle_ok($r, 'Result has no circular references');
};

# ===========================================================================
# 2. Test::CPAN::Health::Report
# ===========================================================================
subtest 'Report: scoring, hard caps, grouping, caching, counts' => sub {
	require Test::CPAN::Health::Report;

	# Build minimal check stubs that provide id() and weight() for the Report.
	my $make_check = sub {
		my ($id, $weight) = @_;
		return bless { id => $id, weight => $weight },
			'Test::CPAN::Health::_FakeCheck';
	};

	{
		no strict 'refs';   ## no critic (ProhibitNoStrict)
		*{'Test::CPAN::Health::_FakeCheck::id'}     = sub { return $_[0]->{id}     };
		*{'Test::CPAN::Health::_FakeCheck::weight'} = sub { return $_[0]->{weight} };
	}

	# --- basic weighted mean ---

	my $ck_a = $make_check->('check_a', 2);
	my $ck_b = $make_check->('check_b', 3);

	my $report = Test::CPAN::Health::Report->new(checks => [$ck_a, $ck_b]);
	ok(blessed($report) && $report->isa('Test::CPAN::Health::Report'), 'constructor returns Report');

	my $r_a = _make_result(check_id => 'check_a', status => $STATUS{PASS}, score => 80);
	my $r_b = _make_result(check_id => 'check_b', status => $STATUS{PASS}, score => 60);

	$report->add_result($r_a)->add_result($r_b);

	# Expected: (80*2 + 60*3) / (2+3) = (160+180)/5 = 340/5 = 68, rounded = 68
	is($report->overall_score, 68, 'weighted mean computed correctly');

	# --- add_result returns $self for chaining ---

	returns_ok(
		$report->add_result(_make_result(check_id => 'extra')),
		{ type => 'object' },
		'add_result returns object for chaining',
	);

	# --- add_result croaks on non-Result ---

	throws_ok {
		$report->add_result({ fake => 1 });
	} qr/result must be a Test::CPAN::Health::Result/, 'add_result croaks on non-Result';

	# --- score is cached; add_result invalidates the cache ---

	my $report2 = Test::CPAN::Health::Report->new;
	$report2->add_result(_make_result(score => 100));
	my $first  = $report2->overall_score;
	my $second = $report2->overall_score;
	is($first, $second, 'score is cached between identical calls');

	$report2->add_result(_make_result(score => 0));
	my $after_add = $report2->overall_score;
	isnt($after_add, $first, 'add_result invalidates cached score');

	# --- skip results are excluded from the weighted mean ---

	my $rep_skip = Test::CPAN::Health::Report->new;
	$rep_skip->add_result(_make_result(score => 100, status => $STATUS{PASS}));
	$rep_skip->add_result(_make_result(check_id => 'skip_me', status => $STATUS{SKIP}));
	# If skip were included with an undef score it would corrupt the weight sum.
	is($rep_skip->overall_score, 100, 'skip results excluded from weighted mean');

	# --- hard cap: security_advisories fail caps overall at 60 ---

	my $rep_sec = Test::CPAN::Health::Report->new;
	$rep_sec->add_result(_make_result(
		check_id => 'security_advisories',
		status   => $STATUS{FAIL},
		score    => $SCORE_ZERO,
	));
	$rep_sec->add_result(_make_result(check_id => 'other', score => 100));

	ok($rep_sec->overall_score <= $CAP_SECURITY,
		"security_advisories fail caps score at $CAP_SECURITY");

	# --- hard cap: cpan_testers fail caps overall at 75 ---

	my $rep_ci = Test::CPAN::Health::Report->new;
	$rep_ci->add_result(_make_result(
		check_id => 'cpan_testers',
		status   => $STATUS{FAIL},
		score    => $SCORE_ZERO,
	));
	$rep_ci->add_result(_make_result(check_id => 'other2', score => 100));

	ok($rep_ci->overall_score <= $CAP_CI,
		"cpan_testers fail caps score at $CAP_CI");

	# --- when both caps apply, the lower cap wins ---

	my $rep_both = Test::CPAN::Health::Report->new;
	$rep_both->add_result(_make_result(check_id => 'security_advisories', status => $STATUS{FAIL}, score => 0));
	$rep_both->add_result(_make_result(check_id => 'cpan_testers',        status => $STATUS{FAIL}, score => 0));
	$rep_both->add_result(_make_result(check_id => 'other3', score => 100));

	ok($rep_both->overall_score <= $CAP_SECURITY,
		'when both caps active, lower cap (security) wins');

	# --- by_status groups correctly ---

	my $rep_grp = Test::CPAN::Health::Report->new;
	$rep_grp->add_result(_make_result(check_id => 'a', status => $STATUS{PASS}));
	$rep_grp->add_result(_make_result(check_id => 'b', status => $STATUS{FAIL}));
	$rep_grp->add_result(_make_result(check_id => 'c', status => $STATUS{FAIL}));
	$rep_grp->add_result(_make_result(check_id => 'd', status => $STATUS{SKIP}));

	my $by_st = $rep_grp->by_status;
	returns_ok($by_st, { type => 'hashref' }, 'by_status returns hashref');
	is(scalar @{$by_st->{pass}}, 1, 'by_status: 1 pass');
	is(scalar @{$by_st->{fail}}, 2, 'by_status: 2 fail');
	is(scalar @{$by_st->{skip}}, 1, 'by_status: 1 skip');

	# --- by_category reads the data.category field ---

	my $rep_cat = Test::CPAN::Health::Report->new;
	$rep_cat->add_result(_make_result(
		check_id => 'sec_check',
		data     => { category => 'security' },
	));
	$rep_cat->add_result(_make_result(
		check_id => 'qual_check',
		data     => { category => 'quality' },
	));
	my $by_cat = $rep_cat->by_category;
	is(scalar @{$by_cat->{security}}, 1, 'by_category: 1 security');
	is(scalar @{$by_cat->{quality}},  1, 'by_category: 1 quality');

	# Results with no category field fall into 'unknown'.
	my $rep_unk = Test::CPAN::Health::Report->new;
	$rep_unk->add_result(_make_result(check_id => 'nc', data => {}));
	ok(exists $rep_unk->by_category->{unknown}, 'missing category becomes "unknown"');

	# --- count methods ---

	my $rep_cnt = Test::CPAN::Health::Report->new;
	$rep_cnt->add_result(_make_result(status => $STATUS{PASS}));
	$rep_cnt->add_result(_make_result(status => $STATUS{WARN}));
	$rep_cnt->add_result(_make_result(status => $STATUS{WARN}));
	$rep_cnt->add_result(_make_result(status => $STATUS{FAIL}));
	$rep_cnt->add_result(_make_result(status => $STATUS{SKIP}));
	$rep_cnt->add_result(_make_result(status => $STATUS{ERROR}));

	is($rep_cnt->pass_count,  1, 'pass_count');
	is($rep_cnt->warn_count,  2, 'warn_count');
	is($rep_cnt->fail_count,  1, 'fail_count');
	is($rep_cnt->skip_count,  1, 'skip_count');
	is($rep_cnt->error_count, 1, 'error_count');

	# --- as_hash ---

	my $h = $rep_cnt->as_hash;
	returns_ok($h, { type => 'hashref' }, 'as_hash returns hashref');
	ok(exists $h->{overall_score}, 'as_hash has overall_score');
	ok(exists $h->{results},       'as_hash has results array');
	returns_ok($h->{results}, { type => 'arrayref' }, 'as_hash results is arrayref');

	# --- empty report scores zero ---

	is(Test::CPAN::Health::Report->new->overall_score, 0,
		'empty report scores zero');

	memory_cycle_ok($rep_grp, 'Report has no circular references');
};

# ===========================================================================
# 3. Test::CPAN::Health::Check (abstract base class)
# ===========================================================================
subtest 'Check: constructor, abstract-method croaks, helper builders' => sub {
	require Test::CPAN::Health::Check;
	require Test::CPAN::Health::Result;

	# Use a concrete subclass because Check itself is abstract.
	# The inline MockCheck package defined at the top of this file
	# implements only id/name/run; everything else uses base defaults.

	require Test::CPAN::Health::Check;

	# --- constructor defaults ---

	my $ck = MockCheck->new;
	ok(blessed($ck) && $ck->isa('Test::CPAN::Health::Check'), 'new returns blessed object');
	is($ck->severity,   3, 'severity defaults to 3');
	is($ck->no_network, 0, 'no_network defaults to 0');
	is($ck->no_cover,   0, 'no_cover defaults to 0');

	# --- constructor respects overrides ---

	my $ck_custom = MockCheck->new(severity => 5, no_network => 1, no_cover => 1);
	is($ck_custom->severity,   5, 'severity override');
	is($ck_custom->no_network, 1, 'no_network override');
	is($ck_custom->no_cover,   1, 'no_cover override');

	# --- base class abstract methods croak with the subclass name ---
	# This verifies that Check's interface enforcement works correctly.

	{
		package AbstractCheck;
		use parent -norequire, 'Test::CPAN::Health::Check';
	}

	my $abs = bless {}, 'AbstractCheck';

	throws_ok { $abs->id }   qr/AbstractCheck must implement id\(\)/,   'id() croaks in base';
	throws_ok { $abs->name } qr/AbstractCheck must implement name\(\)/, 'name() croaks in base';
	throws_ok { $abs->run } qr/AbstractCheck must implement run\(\)/,  'run() croaks in base';

	# --- default implementations return sane values ---

	is($abs->description, '',        'description() defaults to empty string');
	is($abs->weight,      1,         'weight() defaults to 1');
	is($abs->category,    'quality', 'category() defaults to "quality"');

	# --- _result builds a Result stamped with check's own id ---

	my $res = $ck->_result(status => $STATUS{PASS}, score => $SCORE_FULL, summary => 'ok');
	ok($res->isa('Test::CPAN::Health::Result'), '_result returns Result');
	is($res->check_id, $ck->id, '_result stamps check_id from self->id');

	# --- _skip builds a skip Result ---

	my $skip_res = $ck->_skip('not applicable here');
	is($skip_res->status,  $STATUS{SKIP},             '_skip sets status=skip');
	is($skip_res->summary, 'not applicable here',     '_skip sets summary from argument');

	my $default_skip = $ck->_skip;
	is($default_skip->summary, 'Not applicable', '_skip defaults summary to "Not applicable"');

	# --- _error builds an error Result ---

	my $err_res = $ck->_error('something went wrong');
	is($err_res->status,  $STATUS{ERROR},         '_error sets status=error');
	is($err_res->summary, 'something went wrong', '_error sets summary from argument');

	my $default_err = $ck->_error;
	is($default_err->summary, 'Unknown error', '_error defaults summary to "Unknown error"');

	memory_cycle_ok($ck, 'Check has no circular references');
};

# ===========================================================================
# 4. Test::CPAN::Health::Cache
# ===========================================================================
subtest 'Cache: TTL lookup, get/store/purge, default dir, DESTROY' => sub {
	require Test::CPAN::Health::Cache;

	my $tmp = tempdir(CLEANUP => 1);

	# --- _ttl_for: check-id prefix determines TTL ---

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => $tmp);

	# Access _ttl_for as a method call to test against known TTL values.
	Readonly::Hash my %EXPECTED_TTLS => (
		'cpan_testers:Foo-Bar:1.0'        => 3_600,
		'security_advisories:Baz:2.0'     => 3_600,
		'stale_deps:Some-Dist:0.1'        => 86_400,
		'abandoned_deps:Some-Dist:0.1'    => 86_400,
		'reverse_deps:Some-Dist:0.1'      => 86_400,
		'kwalitee:Some-Dist:0.1'          => 86_400,
		'sem_ver:Foo-Bar:1.0'             => 86_400,   # falls through to DEFAULT
	);

	while (my ($key, $expected) = each %EXPECTED_TTLS) {
		is($cache->_ttl_for($key), $expected, "_ttl_for: '$key' -> $expected seconds");
	}

	# Key without a colon: entire key is the check_id prefix; not in map -> DEFAULT
	is($cache->_ttl_for('unknown_check_id'), 86_400,
		'_ttl_for: unknown check_id falls back to DEFAULT (86400)');

	# --- get: miss returns undef ---

	ok(!defined $cache->get('missing:key'), 'get returns undef on cache miss');

	# --- get: croaks on empty key ---

	throws_ok { $cache->get('') }     qr/key is required/, 'get croaks on empty key';
	throws_ok { $cache->get(undef) }  qr/key is required/, 'get croaks on undef key';

	# --- store + get: round-trip ---

	my $payload = { status => $STATUS{PASS}, score => $SCORE_FULL };
	$cache->store('sem_ver:Foo-Bar:1.00', $payload);
	my $retrieved = $cache->get('sem_ver:Foo-Bar:1.00');
	is_deeply($retrieved, $payload, 'store+get round-trip preserves data');

	# --- store returns $self for chaining ---

	is(ref($cache->store('k:x:1', { a => 1 })), 'Test::CPAN::Health::Cache',
		'store returns $self');

	# --- store: croaks on missing key ---

	throws_ok { $cache->store(undef, {}) } qr/key is required/,   'store croaks on undef key';
	throws_ok { $cache->store('',    {}) } qr/key is required/,   'store croaks on empty key';
	throws_ok { $cache->store('k',  undef) } qr/value is required/, 'store croaks on undef value';
	throws_ok { $cache->store('k',  'str') } qr/value is required/, 'store croaks on non-hashref value';

	# --- get: expired entry returns undef ---
	# Store with a negative TTL so the entry is already expired at creation time.

	my $tmp2 = tempdir(CLEANUP => 1);
	my $cache2 = Test::CPAN::Health::Cache->new(cache_dir => $tmp2);
	$cache2->store('sem_ver:Foo-Bar:1.00', { score => 99 }, -1);  # expired immediately
	ok(!defined $cache2->get('sem_ver:Foo-Bar:1.00'), 'expired entry returns undef from get');

	# --- purge removes expired rows and returns the count ---

	my $tmp3 = tempdir(CLEANUP => 1);
	my $cache3 = Test::CPAN::Health::Cache->new(cache_dir => $tmp3);
	$cache3->store('stale:a:1', { x => 1 }, -100);   # expired
	$cache3->store('stale:b:1', { x => 2 }, -100);   # expired
	$cache3->store('fresh:c:1', { x => 3 },  9999);  # not expired

	my $deleted = $cache3->purge;
	is($deleted, 2, 'purge returns count of deleted rows');
	ok(!defined $cache3->get('stale:a:1'), 'purge removed stale entry a');
	ok(!defined $cache3->get('stale:b:1'), 'purge removed stale entry b');
	is_deeply($cache3->get('fresh:c:1'), { x => 3 }, 'purge kept fresh entry');

	# --- _default_cache_dir respects CACHEDIR env var ---
	# Use File::Spec to build portable paths so the regexes work on Windows too.
	{
		my $base = File::Spec->catdir(File::Spec->rootdir(), 'custom', 'cache');
		local $ENV{CACHEDIR}   = $base;
		local $ENV{CACHE_DIR}  = undef;
		my $dir = Test::CPAN::Health::Cache::_default_cache_dir();
		like($dir, qr{\Q$base\E},        '_default_cache_dir: uses CACHEDIR');
		like($dir, qr{\Qcpan-health\E$}, '_default_cache_dir: CACHEDIR appends cpan-health subdir');
	}

	# --- _default_cache_dir falls back to CACHE_DIR when CACHEDIR is not set ---
	{
		my $alt = File::Spec->catdir(File::Spec->rootdir(), 'alt', 'cache');
		local $ENV{CACHEDIR}  = undef;
		local $ENV{CACHE_DIR} = $alt;
		my $dir = Test::CPAN::Health::Cache::_default_cache_dir();
		like($dir, qr{\Q$alt\E},         '_default_cache_dir: uses CACHE_DIR as fallback');
		like($dir, qr{\Qcpan-health\E$}, '_default_cache_dir: CACHE_DIR appends cpan-health subdir');
	}

	# --- DESTROY disconnects without crashing ---

	{
		my $tmp4 = tempdir(CLEANUP => 1);
		my $temp_cache = Test::CPAN::Health::Cache->new(cache_dir => $tmp4);
		$temp_cache->store('x:y:1', { v => 1 });   # forces _dbh initialisation
		lives_ok { $temp_cache->DESTROY } 'DESTROY does not die';
		ok(!defined $temp_cache->{_dbh}, 'DESTROY sets _dbh to undef');
	}

	memory_cycle_ok($cache, 'Cache has no circular references');

	diag('Cache _ttl_for and get/store/purge OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 5. Test::CPAN::Health::Runner
# ===========================================================================
subtest 'Runner: _cache_key, run, context propagation, error handling' => sub {
	require Test::CPAN::Health::Runner;

	# --- constructor ---

	my $runner = Test::CPAN::Health::Runner->new;
	ok(blessed($runner) && $runner->isa('Test::CPAN::Health::Runner'), 'new returns Runner');

	# --- run: croaks on non-Distribution ---

	throws_ok {
		$runner->run({ fake => 1 });
	} qr/dist must be a Test::CPAN::Health::Distribution/, 'run croaks on non-Distribution';

	# --- _cache_key: key is "check_id:dist_name:dist_version" ---

	my $ck   = MockCheck->new;
	my $dist = MockDist->new(name => 'Foo-Bar', version => '2.00');

	is(
		$runner->_cache_key($ck, $dist),
		'mock_check:Foo-Bar:2.00',
		'_cache_key produces "check_id:name:version"',
	);

	# --- _cache_key: returns undef when dist has no name ---

	my $nameless = MockDist->new(name => undef, version => '1.0');
	ok(!defined $runner->_cache_key($ck, $nameless),
		'_cache_key returns undef when dist name is undef');

	# --- run: undef from check is silently dropped ---

	@MockCheck::CALLS = ();
	$MockCheck::RETURN_VALUE = undef;

	my $runner_no_result = Test::CPAN::Health::Runner->new(checks => [MockCheck->new]);
	my $rep = $runner_no_result->run(MockDist->new);
	is(scalar @{$rep->results}, 0, 'undef result from check is not added to report');

	# --- run: exception in check produces error Result ---

	{
		package ExplodingCheck;
		use parent -norequire, 'Test::CPAN::Health::Check';
		sub id       { return 'exploder' }
		sub name     { return 'Exploder' }
		sub category { return 'quality'  }
		sub run      { die "simulated failure\n" }
	}

	my $runner_ex  = Test::CPAN::Health::Runner->new(checks => [ExplodingCheck->new]);
	my $rep_ex;
	# Runner carps when a check throws; capture it so STDERR stays clean during test runs.
	warnings_like { $rep_ex = $runner_ex->run(MockDist->new) }
		qr/Check 'exploder' failed with exception/,
		'runner carps with check id when a check throws';
	is(scalar @{$rep_ex->results}, 1, 'exception produces one error Result');
	is($rep_ex->results->[0]->status, $STATUS{ERROR}, 'error Result has status=error');
	like($rep_ex->results->[0]->summary, qr/simulated failure/,
		'error Result summary contains exception message');

	# --- run: category is stamped onto result.data ---

	$MockCheck::RETURN_VALUE = _make_result(check_id => 'mock_check', data => {});
	my $runner_cat = Test::CPAN::Health::Runner->new(checks => [MockCheck->new]);
	my $rep_cat    = $runner_cat->run(MockDist->new);
	is($rep_cat->results->[0]->data->{category}, 'quality',
		'runner stamps check category onto result.data');

	# --- run: context propagation: second check sees first check's result ---

	{
		package ContextProbeCheck;
		use parent -norequire, 'Test::CPAN::Health::Check';
		our $OBSERVED_CONTEXT;
		sub id       { return 'ctx_probe' }
		sub name     { return 'Context Probe' }
		sub category { return 'quality' }
		sub run {
			my ($self, $dist, $context) = @_;
			$ContextProbeCheck::OBSERVED_CONTEXT = { %{$context} };
			return $self->_result(
				status  => $STATUS{PASS},
				score   => $SCORE_FULL,
				summary => 'saw context',
			);
		}
	}

	my $first_check  = MockCheck->new;
	my $probe_check  = ContextProbeCheck->new;
	my $first_result = _make_result(check_id => 'mock_check');
	$MockCheck::RETURN_VALUE = $first_result;

	my $runner_ctx = Test::CPAN::Health::Runner->new(
		checks => [$first_check, $probe_check],
	);
	$runner_ctx->run(MockDist->new);

	ok(exists $ContextProbeCheck::OBSERVED_CONTEXT->{mock_check},
		'second check receives first check result in context');

	# --- _run_one: cache hit bypasses check execution ---

	my $tmp = tempdir(CLEANUP => 1);
	require Test::CPAN::Health::Cache;
	my $cache = Test::CPAN::Health::Cache->new(cache_dir => $tmp);

	# Pre-populate the cache with a result for our mock check.
	my $cached_payload = {
		check_id => 'mock_check',
		status   => $STATUS{PASS},
		score    => $SCORE_FULL,
		summary  => 'from cache',
	};
	$cache->store('mock_check:Fake-Dist:1.00', $cached_payload);

	@MockCheck::CALLS = ();
	my $runner_cached = Test::CPAN::Health::Runner->new(
		checks => [MockCheck->new],
		cache  => $cache,
	);
	my $dist_for_cache = MockDist->new(name => 'Fake-Dist', version => '1.00');
	$runner_cached->run($dist_for_cache);

	is(scalar @MockCheck::CALLS, 0, 'cache hit: check->run() is not called');

	memory_cycle_ok($runner_no_result, 'Runner has no circular references');
};

# ===========================================================================
# 6. Test::CPAN::Health::Distribution
# ===========================================================================
subtest 'Distribution: path, meta, name, has_dir, file_path, file lists' => sub {
	require Test::CPAN::Health::Distribution;

	# --- constructor: croaks on non-existent path ---

	throws_ok {
		Test::CPAN::Health::Distribution->new(path => '/no/such/dir/ever/xyz');
	} qr/does not exist/, 'constructor croaks on non-existent path';

	# --- path accessor returns absolute path ---

	my $dir = _make_dist_dir(lib => 1, t => 1);
	my $dist = Test::CPAN::Health::Distribution->new(path => $dir);

	ok(-d $dist->path, 'path accessor returns a real directory');
	File::Spec->file_name_is_absolute($dist->path)
		and pass('path is absolute')
		or fail('path is absolute');

	# --- has_dir: single name ---

	ok( $dist->has_dir('lib'), 'has_dir: existing dir returns true');
	ok(!$dist->has_dir('nonexistent_subdir_xyz'), 'has_dir: missing dir returns false');

	# --- has_dir: multiple names (first match wins) ---

	ok($dist->has_dir('nonexistent_xyz', 'lib'), 'has_dir: matches second name in list');

	# --- file_path: existing file ---

	_write_file(File::Spec->catfile($dir, 'Changes'), "version 1.0\n");
	ok(defined $dist->file_path('Changes'), 'file_path returns defined for existing file');

	# --- file_path: non-existing file ---

	ok(!defined $dist->file_path('NoSuchFile.xyz'), 'file_path returns undef for absent file');

	# --- pm_files: returns .pm files under lib/ ---

	my $lib = File::Spec->catdir($dir, 'lib');
	_write_file(File::Spec->catfile($lib, 'Alpha.pm'), "1;\n");
	_write_file(File::Spec->catfile($lib, 'Beta.pm'),  "1;\n");

	my $pm = $dist->pm_files;
	returns_ok($pm, { type => 'arrayref' }, 'pm_files returns arrayref');
	is(scalar @{$pm}, 2, 'pm_files finds 2 .pm files');

	# --- t_files: returns .t files under t/ ---

	my $t_dir = File::Spec->catdir($dir, 't');
	_write_file(File::Spec->catfile($t_dir, '01-load.t'), "use Test::More; done_testing;\n");

	my $t = $dist->t_files;
	returns_ok($t, { type => 'arrayref' }, 't_files returns arrayref');
	is(scalar @{$t}, 1, 't_files finds 1 .t file');

	# --- name: derived from path basename when no META file present ---

	my $named_dir = tempdir('Foo-Bar-1.23-XXXX', TMPDIR => 1, CLEANUP => 1);
	my $named_dist = Test::CPAN::Health::Distribution->new(path => $named_dir);
	# No META file -> name comes from directory basename.
	ok(defined $named_dist->name, 'name returns something even without META');

	# --- meta: prefers META.json over MYMETA.json ---

	my $meta_dir = tempdir(CLEANUP => 1);
	_write_file(File::Spec->catfile($meta_dir, 'META.json'), <<'META_JSON');
{
	"name":"Preferred-Dist","version":"1.0","abstract":"test",
	"author":["A N Author"],"license":["perl_5"],
	"meta-spec":{"version":"2","url":"http://search.cpan.org/perldoc?CPAN::Meta::Spec"}
}
META_JSON

	_write_file(File::Spec->catfile($meta_dir, 'MYMETA.json'), <<'MYMETA_JSON');
{
	"name":"Fallback-Dist","version":"0.1","abstract":"test",
	"author":["A N Author"],"license":["perl_5"],
	"meta-spec":{"version":"2","url":"http://search.cpan.org/perldoc?CPAN::Meta::Spec"}
}
MYMETA_JSON

	my $meta_dist = Test::CPAN::Health::Distribution->new(path => $meta_dir);
	my $meta = $meta_dist->meta;
	if (defined $meta) {
		is($meta->name, 'Preferred-Dist', 'meta prefers META.json over MYMETA.json');
	} else {
		skip 'CPAN::Meta not available', 1;
	}

	# --- meta: falls back to MYMETA.json when META.json is absent ---

	my $mymeta_dir = tempdir(CLEANUP => 1);
	_write_file(File::Spec->catfile($mymeta_dir, 'MYMETA.json'), <<'MYMETA_ONLY');
{
	"name":"MyMeta-Dist","version":"0.5","abstract":"test",
	"author":["A N Author"],"license":["perl_5"],
	"meta-spec":{"version":"2","url":"http://search.cpan.org/perldoc?CPAN::Meta::Spec"}
}
MYMETA_ONLY

	my $mymeta_dist = Test::CPAN::Health::Distribution->new(path => $mymeta_dir);
	my $mymeta = $mymeta_dist->meta;
	if (defined $mymeta) {
		is($mymeta->name, 'MyMeta-Dist', 'meta falls back to MYMETA.json');
	} else {
		skip 'CPAN::Meta not available', 1;
	}

	memory_cycle_ok($dist, 'Distribution has no circular references');
};

# ===========================================================================
# 7. Check::SemVer::_decimal_to_semver (private helper)
# ===========================================================================
subtest 'SemVer::_decimal_to_semver: decimal-to-semver conversions' => sub {
	require Test::CPAN::Health::Check::SemVer;

	my $fn = \&Test::CPAN::Health::Check::SemVer::_decimal_to_semver;

	# Canonical three-part version number with Perl decimal packing.
	# 1.002003 encodes major=1, minor=002, patch=003 -> 1.2.3
	is($fn->('1.002003'), '1.2.3', '1.002003 -> 1.2.3');

	# A version already carrying two dots passes through unchanged.
	is($fn->('1.5.0'), '1.5.0', 'three-part version passes through unchanged');

	# The v-prefix is stripped before processing.
	is($fn->('v1.2.3'), '1.2.3', 'v-prefix stripped and result unchanged');

	# Major-only version (no dot): split gives empty $frac, padded to '000000'
	is($fn->('3'), '3.0.0', 'major-only integer -> x.0.0');

	# Large minor-encoding like 1.012000 -> minor=012=12, patch=000=0 -> 1.12.0
	is($fn->('1.012000'), '1.12.0', '1.012000 -> 1.12.0');

	diag("_decimal_to_semver results verified") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 8. Check::SecurityAdvisories private helpers
# ===========================================================================
subtest 'SecurityAdvisories: _effective_version, _format_advisory, _advisory_url' => sub {
	require Test::CPAN::Health::Check::SecurityAdvisories;

	my $eff_ver = \&Test::CPAN::Health::Check::SecurityAdvisories::_effective_version;
	my $fmt_adv = \&Test::CPAN::Health::Check::SecurityAdvisories::_format_advisory;
	my $adv_url = \&Test::CPAN::Health::Check::SecurityAdvisories::_advisory_url;
	my $inst_ver = \&Test::CPAN::Health::Check::SecurityAdvisories::_installed_version;

	# --- _effective_version: 'perl' always returns the running interpreter version ---
	# Using the declared minimum (e.g. 5.014) would flood results with ancient CVEs.

	my $perl_ver = $eff_ver->('perl', '5.014');
	like($perl_ver, qr/^ \d+ \. \d+ $/x, '_effective_version(perl) returns numeric string');
	ok($perl_ver > 5, '_effective_version(perl) is greater than 5 (running interpreter)');

	# --- _effective_version: version '0' -> installed version (or undef) ---

	# 'Carp' is a core module guaranteed to be installed.
	my $carp_v = $eff_ver->('Carp', '0');
	ok(defined $carp_v, '_effective_version(Carp, "0") returns installed version');
	diag("Carp installed version: $carp_v") if $ENV{TEST_VERBOSE};

	# Non-existent module with version '0' returns undef so caller can skip it.
	my $not_installed = $eff_ver->('No::Such::Module::XYZ999', '0');
	ok(!defined $not_installed, '_effective_version with uninstalled module+version=0 returns undef');

	# undef declared version is treated the same as '0'.
	my $undef_v = $eff_ver->('Carp', undef);
	ok(defined $undef_v, '_effective_version with undef declared version uses installed version');

	# --- _effective_version: non-zero declared version passes through unchanged ---

	is($eff_ver->('DBI', '1.640'), '1.640',
		'_effective_version passes through explicit non-zero version');

	# --- _installed_version: returns version string for installed module ---

	my $carp_installed = $inst_ver->('Carp');
	ok(defined $carp_installed, '_installed_version(Carp) returns a value');

	my $missing_installed = $inst_ver->('No::Such::Module::ABC999');
	ok(!defined $missing_installed, '_installed_version returns undef for missing module');

	# --- _format_advisory: full advisory with CVE and severity ---

	my $adv_full = {
		module      => 'Foo-Bar',
		version     => '0.9',
		id          => 'CPANSA-Foo-2022-001',
		cves        => ['CVE-2022-12345'],
		severity    => 'high',
		description => 'A critical vulnerability',
	};
	my $formatted = $fmt_adv->($adv_full);
	like($formatted, qr/Foo-Bar 0\.9/,             '_format_advisory includes module+version');
	like($formatted, qr/CPANSA-Foo-2022-001/,       '_format_advisory includes advisory id');
	like($formatted, qr/CVE-2022-12345/,            '_format_advisory includes CVE');
	like($formatted, qr/\[HIGH\]/,                  '_format_advisory includes severity in uppercase');
	like($formatted, qr/A critical vulnerability/,  '_format_advisory includes description');

	# --- _format_advisory: no CVE (empty cves arrayref) ---

	my $adv_no_cve = {
		module      => 'Baz',
		version     => '1.0',
		id          => 'CPANSA-Baz-2023-001',
		cves        => [],
		severity    => 'medium',
		description => 'Some issue',
	};
	my $no_cve_str = $fmt_adv->($adv_no_cve);
	unlike($no_cve_str, qr/CVE-/, '_format_advisory without CVE omits CVE segment');
	like($no_cve_str, qr/CPANSA-Baz-2023-001/, '_format_advisory without CVE keeps advisory id');

	# --- _format_advisory: undef severity ---

	my $adv_no_sev = {
		module      => 'Qux',
		version     => '2.0',
		id          => 'CPANSA-Qux-2023-002',
		cves        => [],
		severity    => undef,
		description => 'Minor problem',
	};
	unlike($fmt_adv->($adv_no_sev), qr/\[/, '_format_advisory without severity has no brackets');

	# --- _format_advisory: missing description falls back to advisory URL prompt ---

	my $adv_no_desc = {
		module   => 'Widget',
		version  => '1.0',
		id       => 'CPANSA-Widget-2024',
		cves     => [],
		severity => undef,
	};
	like($fmt_adv->($adv_no_desc), qr/see advisory URL/,
		'_format_advisory without description falls back to "see advisory URL"');

	# --- _advisory_url: module :: -> dist - in URL ---

	is($adv_url->('LWP-UserAgent'),
		'https://security.metacpan.org/advisories/LWP-UserAgent',
		'_advisory_url with dist name produces correct URL');

	# Module names with :: should also work (callers usually pass dist names).
	my $url_ns = $adv_url->('Foo::Bar');
	like($url_ns, qr{metacpan\.org/advisories/Foo-Bar}, '_advisory_url replaces :: with -');

	diag('SecurityAdvisories helpers OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 9. Check::PODCoverage::_parse_file (private helper)
# ===========================================================================
subtest 'PODCoverage::_parse_file: sub discovery and POD heading detection' => sub {
	require Test::CPAN::Health::Check::PODCoverage;

	my $fn = \&Test::CPAN::Health::Check::PODCoverage::_parse_file;
	my $tmp = tempdir(CLEANUP => 1);

	# --- fully documented public sub ---

	my $full = _write_file(File::Spec->catfile($tmp, 'full.pm'), <<'PM_FULL');
package Full;

=head1 NAME

Full - test

=head2 greet

Does a greeting.

=cut

sub greet { return 1 }

1;
PM_FULL

	my ($subs, $pod) = $fn->($full);
	is_deeply($subs, ['greet'], 'finds public sub "greet"');
	ok($pod->{greet}, 'greet appears in POD names hash');

	# --- private sub is excluded ---

	my $priv = _write_file(File::Spec->catfile($tmp, 'priv.pm'), <<'PM_PRIV');
package Priv;

sub public_method { return 1 }
sub _private_helper { return 1 }

1;
PM_PRIV

	my ($priv_subs) = $fn->($priv);
	ok(grep { $_ eq 'public_method' } @{$priv_subs},
		'public_method is in the list');
	ok(!grep { $_ eq '_private_helper' } @{$priv_subs},
		'_private_helper is excluded from the list');

	# --- exempt subs (DESTROY, BEGIN, AUTOLOAD, etc.) are excluded ---

	my $exempt = _write_file(File::Spec->catfile($tmp, 'exempt.pm'), <<'PM_EXEMPT');
package Exempt;

sub new     { return 1 }
sub DESTROY { return 1 }
sub BEGIN   { }
sub END     { }
sub AUTOLOAD { return 1 }
sub import  { return 1 }

1;
PM_EXEMPT

	my ($exempt_subs) = $fn->($exempt);
	ok( grep { $_ eq 'new' } @{$exempt_subs},    '"new" is a public sub (not exempt)');
	ok(!grep { $_ eq 'DESTROY'  } @{$exempt_subs}, 'DESTROY is exempt');
	ok(!grep { $_ eq 'BEGIN'    } @{$exempt_subs}, 'BEGIN is exempt');
	ok(!grep { $_ eq 'END'      } @{$exempt_subs}, 'END is exempt');
	ok(!grep { $_ eq 'AUTOLOAD' } @{$exempt_subs}, 'AUTOLOAD is exempt');
	ok(!grep { $_ eq 'import'   } @{$exempt_subs}, 'import is exempt');

	# --- POD state machine: =cut resets pod state; directive line itself processed ---
	# A heading immediately after =pod must be recognized.

	my $state = _write_file(File::Spec->catfile($tmp, 'state.pm'), <<'PM_STATE');
package State;

=pod

=head2 documented_sub

Something.

=cut

sub documented_sub { return 1 }
sub undocumented   { return 1 }

1;
PM_STATE

	my ($st_subs, $st_pod) = $fn->($state);
	ok($st_pod->{documented_sub}, 'heading inside =pod/=cut block is recognized');
	ok( grep { $_ eq 'documented_sub' } @{$st_subs}, 'documented_sub found in subs list');
	ok( grep { $_ eq 'undocumented'   } @{$st_subs}, 'undocumented found in subs list');

	# --- empty file produces empty results ---

	my $empty = _write_file(File::Spec->catfile($tmp, 'empty.pm'), '');
	my ($e_subs, $e_pod) = $fn->($empty);
	is_deeply($e_subs, [], 'empty file: no subs found');
	is_deeply($e_pod,  {}, 'empty file: no pod names found');

	diag('_parse_file tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 10. Check::DuplicateCode::_code_lines (private helper)
# ===========================================================================
subtest 'DuplicateCode::_code_lines: filtering logic' => sub {
	require Test::CPAN::Health::Check::DuplicateCode;

	my $fn  = \&Test::CPAN::Health::Check::DuplicateCode::_code_lines;
	my $tmp = tempdir(CLEANUP => 1);

	my $mixed = _write_file(File::Spec->catfile($tmp, 'mixed.pm'), <<'PM_MIXED');
package Mixed;

# This is a comment -- should be excluded
use strict;         # excluded: use strict
use warnings;       # excluded: use warnings
use autodie qw(:all); # excluded: use autodie

=head1 NAME

Mixed - test

=cut

my $x = 1;          # real code line -- should be retained
my $y = 2;

1;                  # excluded
PM_MIXED

	my @lines = $fn->($mixed);

	# POD should be stripped entirely.
	ok(!grep { /^=/ || /Mixed - test/ } @lines, 'POD lines stripped');

	# Comments-only lines stripped.
	ok(!grep { /^#/ } @lines, 'pure comment lines stripped');

	# Common use pragmas stripped.
	# Use !(grep {...} @list) rather than !grep {...} @list, 'msg' to prevent
	# the test description string from being included in the grep's argument list.
	ok(!(grep { /^use strict/ }   @lines), 'use strict stripped');
	ok(!(grep { /^use warnings/ } @lines), 'use warnings stripped');
	ok(!(grep { /^use autodie/ }  @lines), 'use autodie stripped');

	# The file-end marker '1;' stripped.
	ok(!grep { $_ eq '1;' } @lines, '"1;" stripped');

	# Real code lines retained.
	ok(grep { /my \$x = 1/ } @lines, 'real code line "my $x = 1" retained');
	ok(grep { /my \$y = 2/ } @lines, 'real code line "my $y = 2" retained');

	# Whitespace normalised: leading/trailing removed, internal runs collapsed.
	my $ws = _write_file(File::Spec->catfile($tmp, 'ws.pm'), <<'PM_WS');
package WS;
   my   $z   =   3;
PM_WS
	my @ws_lines = $fn->($ws);
	my ($ws_line) = grep { /\$z/ } @ws_lines;
	is($ws_line, 'my $z = 3;', 'whitespace normalised to single spaces');

	diag('_code_lines tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 11. Check::StaleDeps::_major (private helper)
# ===========================================================================
subtest 'StaleDeps::_major: leading integer extraction from version strings' => sub {
	require Test::CPAN::Health::Check::StaleDeps;

	my $fn = \&Test::CPAN::Health::Check::StaleDeps::_major;

	Readonly::Hash my %CASES => (
		'1.23'   => 1,
		'v2.0.0' => 2,
		'0.99'   => 0,
		'10.00'  => 10,
		'0'      => 0,
		''       => 0,
	);

	while (my ($input, $expected) = each %CASES) {
		is($fn->($input), $expected, "_major('$input') => $expected");
	}

	is($fn->(undef), 0, '_major(undef) => 0');
	is($fn->('v10.2.3'), 10, '_major with double-digit v-version');

	diag('_major tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 12. Check::AbandonedDeps::_iso8601_to_epoch (private helper)
# ===========================================================================
subtest 'AbandonedDeps::_iso8601_to_epoch: ISO 8601 date parsing' => sub {
	require Test::CPAN::Health::Check::AbandonedDeps;

	my $fn = \&Test::CPAN::Health::Check::AbandonedDeps::_iso8601_to_epoch;

	# Known fixed point: 2000-01-01T00:00:00Z is Unix epoch 946684800.
	my $epoch_2000 = $fn->('2000-01-01T00:00:00.000Z');
	ok(defined $epoch_2000, '_iso8601_to_epoch returns a value for a valid date');
	is($epoch_2000, 946684800, '2000-01-01 -> correct epoch 946684800');

	# A date string with only the date part (no time component) should still parse.
	my $date_only = $fn->('2020-06-15T12:34:56');
	ok(defined $date_only, '_iso8601_to_epoch accepts datetime without Z suffix');

	# Ordering: a date in the future should produce a larger epoch than one in the past.
	my $past   = $fn->('2010-01-01T00:00:00Z');
	my $future = $fn->('2030-01-01T00:00:00Z');
	ok($future > $past, 'later date produces larger epoch value');

	# undef input returns undef.
	ok(!defined $fn->(undef), '_iso8601_to_epoch(undef) returns undef');

	# Invalid input returns undef without crashing.
	ok(!defined $fn->('not-a-date'), '_iso8601_to_epoch on garbage returns undef');
	ok(!defined $fn->(''),           '_iso8601_to_epoch on empty string returns undef');

	diag('_iso8601_to_epoch tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 13. Check::DocQuality private helpers
# ===========================================================================
subtest 'DocQuality: _pod_sections and _count_pod_errors' => sub {
	require Test::CPAN::Health::Check::DocQuality;

	my $sections_fn = \&Test::CPAN::Health::Check::DocQuality::_pod_sections;
	# DocQuality.pm loads Pod::Checker lazily inside run(); pre-load it here
	# so _count_pod_errors can call Pod::Checker->new when invoked directly.
	require Pod::Checker;
	my $errors_fn   = \&Test::CPAN::Health::Check::DocQuality::_count_pod_errors;

	my $tmp = tempdir(CLEANUP => 1);

	# --- _pod_sections: finds =head1 sections by title ---

	my $pod_file = _write_file(File::Spec->catfile($tmp, 'pod_secs.pm'), <<'PM_POD');
package PodSecs;

=head1 NAME

PodSecs - test

=head1 SYNOPSIS

Some synopsis.

=head1 LICENSE AND COPYRIGHT

Copyright stuff.

=cut

1;
PM_POD

	my %secs = $sections_fn->($pod_file);
	ok(exists $secs{NAME},    '_pod_sections finds NAME');
	ok(exists $secs{SYNOPSIS},'_pod_sections finds SYNOPSIS');

	# "LICENSE AND COPYRIGHT" should populate both synthetic keys.
	ok(exists $secs{LICENSE},   '_pod_sections aliases LICENSE from "LICENSE AND COPYRIGHT"');
	ok(exists $secs{COPYRIGHT}, '_pod_sections aliases COPYRIGHT from "LICENSE AND COPYRIGHT"');

	# --- _pod_sections: sections in code (not POD) are not counted ---

	my $code_file = _write_file(File::Spec->catfile($tmp, 'code.pm'), <<'PM_CODE');
package Code;

# =head1 This is a comment
my $head1 = '=head1 FAKE';

=head1 REAL

Real section.

=cut

1;
PM_CODE

	my %code_secs = $sections_fn->($code_file);
	ok(!exists $code_secs{FAKE}, 'section names in code/comments not collected');
	ok( exists $code_secs{REAL}, 'real POD section collected');

	# --- _pod_sections: trailing whitespace trimmed from titles ---

	my $ws_pod = _write_file(File::Spec->catfile($tmp, 'ws_pod.pm'), <<"PM_WS_POD");
package WSPod;

=head1 METHODS

Some text.

=cut

1;
PM_WS_POD

	my %ws_secs = $sections_fn->($ws_pod);
	ok(exists $ws_secs{METHODS}, 'trailing whitespace trimmed from section title');

	# --- _count_pod_errors: file with no POD returns 0 (not -1) ---

	my $no_pod = _write_file(File::Spec->catfile($tmp, 'nopod.pm'), "package NoPod;\n1;\n");
	my $errs = $errors_fn->($no_pod);
	is($errs, 0, '_count_pod_errors: file with no POD returns 0 (not -1)');

	# --- _count_pod_errors: well-formed POD returns 0 errors ---

	my $good_pod = _write_file(File::Spec->catfile($tmp, 'goodpod.pm'), <<'PM_GOOD');
package GoodPod;

=head1 NAME

GoodPod - a fine module

=cut

1;
PM_GOOD

	is($errors_fn->($good_pod), 0, '_count_pod_errors: well-formed POD returns 0');

	diag('DocQuality helper tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 14. Reporter::TAP
# ===========================================================================
subtest 'Reporter::TAP: plan, pass/fail/warn/skip, hash escaping, diagnostics' => sub {
	require Test::CPAN::Health::Reporter::TAP;
	require Test::CPAN::Health::Report;

	my $rep = Test::CPAN::Health::Reporter::TAP->new;
	ok(blessed($rep) && $rep->isa('Test::CPAN::Health::Reporter::TAP'), 'new returns TAP reporter');

	# --- render: croaks on non-Report ---

	throws_ok {
		$rep->render({ fake => 1 });
	} qr/report must be a Test::CPAN::Health::Report/, 'render croaks on non-Report';

	# Build a report with one result of each status for comprehensive rendering tests.
	my $report = Test::CPAN::Health::Report->new;
	$report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'aa_check',
		status   => $STATUS{PASS},
		score    => $SCORE_FULL,
		summary  => 'All passed',
		data     => { name => 'Alpha Check' },
	));
	$report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'bb_check',
		status   => $STATUS{FAIL},
		score    => $SCORE_ZERO,
		summary  => 'Something failed',
		data     => { name => 'Beta Check' },
	));
	$report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'cc_check',
		status   => $STATUS{WARN},
		score    => $SCORE_HALF,
		summary  => 'Could be better',
		data     => { name => 'Gamma Check' },
	));
	$report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'dd_check',
		status   => $STATUS{SKIP},
		summary  => 'Not applicable',
		data     => { name => 'Delta Check' },
	));

	my $tap = $rep->render($report);

	# --- plan line ---

	like($tap, qr/^1\.\.4\n/, 'TAP output begins with plan line "1..4"');

	# --- pass: "ok N - ..." ---

	like($tap, qr/^ok \d+ - Alpha Check: All passed$/m, 'pass result: "ok N - name: summary"');

	# --- fail: "not ok N - ..." ---

	like($tap, qr/^not ok \d+ - Beta Check: Something failed$/m, 'fail: "not ok N - ..."');

	# --- warn: "ok N - ... # WARN" ---

	like($tap, qr/^ok \d+ - Gamma Check: Could be better # WARN$/m, 'warn: "ok N - ... # WARN"');

	# --- skip: "ok N # SKIP ..." ---

	like($tap, qr/^ok \d+ # SKIP Delta Check: Not applicable$/m, 'skip: "ok N # SKIP ..."');

	# --- hash character in summary replaced with [#] ---

	my $hash_report = Test::CPAN::Health::Report->new;
	$hash_report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'hash_check',
		status   => $STATUS{PASS},
		score    => 100,
		summary  => 'Found #42 and #99 issues',
		data     => { name => 'Hash Check' },
	));
	my $hash_tap = $rep->render($hash_report);
	unlike($hash_tap, qr/Found #42/, 'literal # in summary replaced with [#]');
	like($hash_tap,   qr/Found \[#\]42/, 'hash chars replaced correctly');

	# --- details emitted as TAP diagnostic lines ---

	my $detail_report = Test::CPAN::Health::Report->new;
	$detail_report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'detail_check',
		status   => $STATUS{FAIL},
		score    => $SCORE_ZERO,
		summary  => 'Fail',
		details  => ['First detail', 'Second detail'],
		data     => { name => 'Detail Check' },
	));
	my $dtap = $rep->render($detail_report);
	like($dtap, qr/^# First detail$/m,  'first detail line emitted as TAP diagnostic');
	like($dtap, qr/^# Second detail$/m, 'second detail line emitted as TAP diagnostic');

	# --- overall score summary appears as diagnostics at the end ---

	like($tap, qr/^# Overall score:/m, 'overall score diagnostic present');
	like($tap, qr/^# Passed:/m,         'pass/warn/fail count diagnostic present');

	diag('Reporter::TAP tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 15. Reporter::HTML::_esc (private helper)
# ===========================================================================
subtest 'Reporter::HTML::_esc: XSS-safe HTML escaping' => sub {
	require Test::CPAN::Health::Reporter::HTML;

	my $esc = \&Test::CPAN::Health::Reporter::HTML::_esc;

	# Each of the five HTML-special characters must be encoded.
	is($esc->('a & b'),   'a &amp; b',  '_esc encodes &');
	is($esc->('a < b'),   'a &lt; b',   '_esc encodes <');
	is($esc->('a > b'),   'a &gt; b',   '_esc encodes >');
	is($esc->('"foo"'),   '&quot;foo&quot;', '_esc encodes "');
	is($esc->("it's"),    'it&#39;s',    '_esc encodes single quote');

	# All five in one string.
	is($esc->('< & > " \''), '&lt; &amp; &gt; &quot; &#39;', '_esc encodes all five chars');

	# undef input returns empty string (avoids "Use of uninitialized value" warnings in templates).
	is($esc->(undef), '', '_esc(undef) returns empty string');

	# Plain text passes through unchanged.
	is($esc->('Hello World 123'), 'Hello World 123', '_esc passes plain text through');

	# --- render: croaks on non-Report ---

	my $html_rep = Test::CPAN::Health::Reporter::HTML->new;
	throws_ok {
		$html_rep->render({ not_a_report => 1 });
	} qr/report must be a Test::CPAN::Health::Report/, 'HTML render croaks on non-Report';

	# --- render: produces valid HTML with score and DOCTYPE indication ---

	require Test::CPAN::Health::Report;
	my $report = Test::CPAN::Health::Report->new;
	$report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'sem_ver',
		status   => $STATUS{PASS},
		score    => $SCORE_FULL,
		summary  => 'Version 1.2.3',
		data     => { name => 'Semantic Versioning' },
	));

	my $html = $html_rep->render($report);
	like($html, qr/<!DOCTYPE html>/i, 'HTML output contains DOCTYPE');
	like($html, qr/100\/100/,         'HTML output contains overall score');

	# --- render: XSS in summary is escaped ---

	my $xss_report = Test::CPAN::Health::Report->new;
	$xss_report->add_result(Test::CPAN::Health::Result->new(
		check_id => 'xss_check',
		status   => $STATUS{FAIL},
		score    => $SCORE_ZERO,
		summary  => '<script>alert(1)</script>',
		data     => { name => 'XSS Check' },
	));
	my $xss_html = $html_rep->render($xss_report);
	unlike($xss_html, qr/<script>alert/,  'raw <script> tag not present in HTML output');
	like($xss_html,   qr/&lt;script&gt;/, 'script tag is HTML-escaped in output');

	diag('Reporter::HTML::_esc tests OK') if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 16. Check::Examples and Check::Benchmarks run() paths
# ===========================================================================
subtest 'Check::Examples::run: fail/warn/pass based on directory state' => sub {
	require Test::CPAN::Health::Check::Examples;

	my $check = Test::CPAN::Health::Check::Examples->new;

	# Verify check metadata.
	is($check->id,       'examples', 'id');
	is($check->weight,   2,          'weight');
	is($check->category, 'quality',  'category');

	# --- fail: no examples directory exists ---

	my $no_dir = tempdir(CLEANUP => 1);
	my $dist_no = Test::CPAN::Health::Distribution->new(path => $no_dir);
	my $r_fail  = $check->run($dist_no);

	is($r_fail->status, $STATUS{FAIL},  'fail: no examples dir -> fail status');
	is($r_fail->score,  $SCORE_ZERO,    'fail: no examples dir -> score 0');
	ok(scalar @{$r_fail->details} > 0,  'fail: details array contains advice');

	# --- warn: examples dir exists but is empty ---

	my $empty_dir = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($empty_dir, 'examples'));
	my $dist_empty = Test::CPAN::Health::Distribution->new(path => $empty_dir);
	my $r_warn     = $check->run($dist_empty);

	is($r_warn->status, $STATUS{WARN}, 'warn: empty examples dir -> warn status');
	is($r_warn->score,  $SCORE_HALF,   'warn: empty examples dir -> score 50');

	# --- pass: examples dir exists and contains at least one file ---

	my $full_dir = tempdir(CLEANUP => 1);
	my $eg_path  = File::Spec->catdir($full_dir, 'examples');
	make_path($eg_path);
	_write_file(File::Spec->catfile($eg_path, 'basic.pl'), "print 'hello';\n");
	my $dist_full = Test::CPAN::Health::Distribution->new(path => $full_dir);
	my $r_pass    = $check->run($dist_full);

	is($r_pass->status, $STATUS{PASS}, 'pass: non-empty examples dir -> pass');
	is($r_pass->score,  $SCORE_FULL,   'pass: non-empty examples dir -> score 100');

	# --- eg/ is an accepted alternative to examples/ ---

	my $eg_dir  = tempdir(CLEANUP => 1);
	my $eg_sub  = File::Spec->catdir($eg_dir, 'eg');
	make_path($eg_sub);
	_write_file(File::Spec->catfile($eg_sub, 'demo.pl'), "1;\n");
	my $dist_eg = Test::CPAN::Health::Distribution->new(path => $eg_dir);
	is($check->run($dist_eg)->status, $STATUS{PASS}, '"eg/" accepted as examples directory');

	# --- croak on non-Distribution ---
	# Use a wrong-class blessed ref; the checks use ref($dist) && $dist->isa(...)
	# which throws "Can't call method 'isa' on unblessed reference" for plain
	# hashrefs before reaching the croak. A blessed wrong-class ref exercises the
	# real guard path.

	throws_ok {
		$check->run(bless {}, 'NotADistribution');
	} qr/dist must be a Test::CPAN::Health::Distribution/, 'run croaks on non-Distribution';
};

subtest 'Check::Benchmarks::run: fail/warn/pass based on directory state' => sub {
	require Test::CPAN::Health::Check::Benchmarks;

	my $check = Test::CPAN::Health::Check::Benchmarks->new;

	is($check->id,       'benchmarks', 'id');
	is($check->weight,   1,            'weight');
	is($check->category, 'quality',    'category');

	# --- fail: no bench directory exists ---

	my $no_dir  = tempdir(CLEANUP => 1);
	my $dist_no = Test::CPAN::Health::Distribution->new(path => $no_dir);
	my $r_fail  = $check->run($dist_no);

	is($r_fail->status, $STATUS{FAIL}, 'fail: no bench dir -> fail status');
	is($r_fail->score,  $SCORE_ZERO,   'fail: no bench dir -> score 0');
	ok(scalar @{$r_fail->details} > 0, 'fail: details include advice');

	# --- pass: benchmarks/ dir with a file ---

	my $bench_dir  = tempdir(CLEANUP => 1);
	my $bench_path = File::Spec->catdir($bench_dir, 'benchmarks');
	make_path($bench_path);
	_write_file(File::Spec->catfile($bench_path, 'speed.pl'), "use Benchmark;\n");
	my $dist_bench = Test::CPAN::Health::Distribution->new(path => $bench_dir);
	is($check->run($dist_bench)->status, $STATUS{PASS},
		'pass: non-empty benchmarks/ dir -> pass');

	# --- bench/ is an accepted alternative to benchmarks/ ---

	my $b_dir   = tempdir(CLEANUP => 1);
	my $b_sub   = File::Spec->catdir($b_dir, 'bench');
	make_path($b_sub);
	_write_file(File::Spec->catfile($b_sub, 'time.pl'), "1;\n");
	my $dist_b = Test::CPAN::Health::Distribution->new(path => $b_dir);
	is($check->run($dist_b)->status, $STATUS{PASS}, '"bench/" accepted as benchmarks directory');
};

done_testing;
