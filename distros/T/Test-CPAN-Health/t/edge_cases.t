#!/usr/bin/env perl
# t/edge_cases.t
# Destructive, boundary-condition, pathological, and security-focused tests.
# Each subtest targets a specific module with hostile inputs, state abuse, or
# known vulnerability patterns.  If a test reveals a bug, the fix lives in
# the corresponding .pm file and the test documents the intended behaviour.

use strict;
use warnings;

use Carp qw(croak);
use DBI;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);

use Test::Most;
use Test::Returns qw(returns_ok);
use Test::Mockingbird qw(spy restore_all);

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Constants -- no magic strings/numbers anywhere below this block
# ---------------------------------------------------------------------------
Readonly::Scalar my $SCORE_MIN      => 0;
Readonly::Scalar my $SCORE_MAX      => 100;
Readonly::Scalar my $CAP_SECADV     => 60;     # SecurityAdvisories hard cap
Readonly::Scalar my $CAP_CPANTS     => 75;     # CPANTesters hard cap
Readonly::Scalar my $WEIGHT_HEAVY   => 100;    # weight to make raw score dominate

Readonly::Scalar my $XSS_SCRIPT  => '<script>alert(1)</script>';
Readonly::Scalar my $XSS_ATTR    => '" onmouseover="alert(1)';
Readonly::Scalar my $XSS_SQUOTE  => "' onerror='bad'";
Readonly::Scalar my $AMP_ENTITY  => '&amp;<b>injected</b>';
Readonly::Scalar my $SQL_INJECT  => "'; DROP TABLE cache; --";

Readonly::Hash my %ALL_STATUSES => (
	pass  => 'pass',
	warn  => 'warn',
	fail  => 'fail',
	skip  => 'skip',
	error => 'error',
);

# ---------------------------------------------------------------------------
# Module loading
# ---------------------------------------------------------------------------
for my $mod (qw(
	Test::CPAN::Health::Result
	Test::CPAN::Health::Report
	Test::CPAN::Health::Runner
	Test::CPAN::Health::Distribution
	Test::CPAN::Health::Cache
	Test::CPAN::Health::Check
	Test::CPAN::Health::Reporter::HTML
	Test::CPAN::Health::Reporter::TAP
)) {
	use_ok($mod) or BAIL_OUT("Cannot load $mod");
}

# ---------------------------------------------------------------------------
# Inline test-double packages
#
# All inherit from Check so they can call _result/_skip/_error.
# Defined with -norequire because the parent is already loaded above.
# ---------------------------------------------------------------------------

# Returns a plain string instead of a Result -- exposes the Runner non-Result bug.
{ package EC::BadReturnCheck;
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id   { return 'bad_return_check'            }
  sub name { return 'Bad Return Check'            }
  sub run  { return 'this is not a Result object' }
}

# Always returns undef (check not applicable).
{ package EC::NullCheck;
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id   { return 'null_check' }
  sub name { return 'Null Check' }
  sub run  { return }
}

# Always throws a Carp exception.
{ package EC::ExplodingCheck;
  use Carp qw(croak);
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id   { return 'exploding_check'      }
  sub name { return 'Exploding Check'      }
  sub run  { croak 'simulated check kaboom' }
}

# Always returns a skip result.
{ package EC::SkipCheck;
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id   { return 'skip_check' }
  sub name { return 'Skip Check' }
  sub run  {
      my ($self) = @_;
      return $self->_skip('always skipped for testing');
  }
}

# Produces a security_advisories fail result (triggers the hard cap).
{ package EC::CapCheck;
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id       { return 'security_advisories'           }
  sub name     { return 'Security Advisories (mock)'    }
  sub category { return 'security'                      }
  sub weight   { return 1                               }    # low weight so heavy_pass dominates
  sub run {
      my ($self, $dist) = @_;
      return $self->_result(status => 'fail', score => 0, summary => 'mock CVE found');
  }
}

# Produces a very-high-weighted pass result (forces raw score > 60 before cap).
{ package EC::HeavyPassCheck;
  use parent -norequire, 'Test::CPAN::Health::Check';
  our $VERSION = '0.01';
  sub id     { return 'heavy_pass'           }
  sub name   { return 'Heavy Pass (mock)'    }
  sub weight { return $WEIGHT_HEAVY          }
  sub run {
      my ($self, $dist) = @_;
      return $self->_result(status => 'pass', score => 100, summary => 'excellent');
  }
}

# ---------------------------------------------------------------------------
# Helper: create a minimal temp distribution directory (no META files).
# ---------------------------------------------------------------------------
sub _bare_dist {
	my $dir = tempdir(CLEANUP => 1);
	return Test::CPAN::Health::Distribution->new(path => $dir);
}

# ===========================================================================
# 1. Result: hostile constructor inputs
# ===========================================================================
subtest 'Result: hostile constructor inputs' => sub {

	# Empty check_id must fail PVS min-length validation.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => '', status => 'pass') },
		qr/check_id/,
		'Empty string check_id croaks (PVS min=1)',
	);

	# Invalid status must croak with an exact message mentioning the bad value.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'invalid') },
		qr/Invalid status 'invalid'/,
		'Invalid status croaks with expected message',
	);

	# Status value that is the empty string.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => '') },
		qr/status/,
		'Empty string status croaks',
	);

	# Boundary score 0: just inside the valid range.
	my $r0 = Test::CPAN::Health::Result->new(
		check_id => 'x', status => 'pass', score => $SCORE_MIN,
	);
	is($r0->score, $SCORE_MIN, 'Score 0 (boundary minimum) is valid');

	# Boundary score 100: just inside the valid range.
	my $r100 = Test::CPAN::Health::Result->new(
		check_id => 'x', status => 'pass', score => $SCORE_MAX,
	);
	is($r100->score, $SCORE_MAX, 'Score 100 (boundary maximum) is valid');

	# Score -1: one below the minimum.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'pass', score => -1) },
		qr/must be at least 0/,
		'Score -1 croaks (one below minimum)',
	);

	# Score 101: one above the maximum.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'pass', score => 101) },
		qr/must be no more than 100/,
		'Score 101 croaks (one above maximum)',
	);

	# Score is optional: no score is valid.
	my $no_score = Test::CPAN::Health::Result->new(check_id => 'x', status => 'skip');
	ok(!defined $no_score->score, 'Missing score is valid (optional field)');

	# data must be a hashref; an arrayref must croak.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'pass', data => []) },
		qr/data/,
		'data as arrayref croaks (must be hashref)',
	);

	# details must be an arrayref; a plain scalar must croak.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'pass', details => 'bad') },
		qr/details/,
		'details as scalar croaks (must be arrayref)',
	);

	# PVS strict mode: unknown keys must croak.
	throws_ok(
		sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'pass', rogue => 99) },
		qr/Unknown parameter/i,
		'Unknown constructor key croaks (PVS strict)',
	);

	diag 'Result hostile input tests complete' if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 2. Result: as_hash isolation (shallow copy)
# ===========================================================================
subtest 'Result: as_hash returns a shallow copy' => sub {

	my $r = Test::CPAN::Health::Result->new(
		check_id => 'iso_test',
		status   => 'warn',
		score    => 50,
		summary  => 'original summary',
		details  => ['detail one', 'detail two'],
		data     => { name => 'original', count => 7 },
	);

	my $h = $r->as_hash;

	# Scalars in the top-level hash copy are independent.
	$h->{status}  = 'pass';
	$h->{summary} = 'hijacked';
	is($r->status,  'warn',             'Mutating hash copy does not change status');
	is($r->summary, 'original summary', 'Mutating hash copy does not change summary');

	# The details arrayref in as_hash is a new array (copy of elements).
	push @{$h->{details}}, 'injected';
	is(scalar @{$r->details}, 2, 'Push onto copy does not extend original details array');

	# The data hashref in as_hash is a shallow copy: top-level scalar values
	# (strings, numbers) are independent copies, so mutating them in the copy
	# does NOT affect the original.  Only nested REFERENCES would be shared.
	$h->{data}{count} = 999;
	is($r->data->{count}, 7, 'Mutating a scalar in the copy does not affect original data');

	# Nested refs ARE shared (shallow copy semantics).  Add a nested ref to test.
	my $shared_ref = { inner => 'hello' };
	my $r2 = Test::CPAN::Health::Result->new(
		check_id => 'ref_test',
		status   => 'pass',
		data     => { nested => $shared_ref },
	);
	my $h2 = $r2->as_hash;
	$h2->{data}{nested}{inner} = 'mutated via shared ref';
	is($r2->data->{nested}{inner}, 'mutated via shared ref',
		'Nested ref IS shared between original and as_hash copy (shallow semantics)');

	diag "as_hash: h->{status}=$h->{status}, original status=" . $r->status
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 3. Result: status predicates are exhaustive and mutually exclusive
# ===========================================================================
subtest 'Result: status predicates are mutually exclusive' => sub {

	for my $status (values %ALL_STATUSES) {
		my $r = Test::CPAN::Health::Result->new(check_id => 'x', status => $status);
		my $true_count = 0;
		for my $other (values %ALL_STATUSES) {
			my $method = "is_$other";
			if ($other eq $status) {
				ok($r->$method, "is_$other() true for status '$status'");
				$true_count++;
			} else {
				ok(!$r->$method, "is_$other() false for status '$status'");
			}
		}
		is($true_count, 1, "Exactly one predicate true for status '$status'");
	}
};

# ===========================================================================
# 4. Report: empty and all-skip reports score 0
# ===========================================================================
subtest 'Report: empty/all-skip reports score 0' => sub {

	# Empty Report: no results at all.
	my $empty = Test::CPAN::Health::Report->new(checks => []);
	is($empty->overall_score, 0, 'Empty Report overall_score is 0 (no divide-by-zero)');

	# Report with only skip results: no scorable results → score 0.
	my $all_skip = Test::CPAN::Health::Report->new(checks => []);
	$all_skip->add_result(
		Test::CPAN::Health::Result->new(check_id => 'a', status => 'skip'),
	);
	$all_skip->add_result(
		Test::CPAN::Health::Result->new(check_id => 'b', status => 'skip'),
	);
	is($all_skip->overall_score, 0, 'All-skip Report scores 0 (skip results excluded from average)');

	returns_ok($empty->overall_score, { type => 'integer' }, 'overall_score returns an integer');
};

# ===========================================================================
# 5. Report: dirty-bit cache invalidation
# ===========================================================================
subtest 'Report: score cache is invalidated by add_result' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	$report->add_result(
		Test::CPAN::Health::Result->new(check_id => 'a', status => 'pass', score => 100),
	);
	my $score_before = $report->overall_score;
	is($score_before, 100, 'Score is 100 with one pass/100 result');

	# A second call must return the cached value (not recompute).
	my $score_cached = $report->overall_score;
	is($score_cached, $score_before, 'Second overall_score call returns cached value');

	# add_result must invalidate the cache.
	$report->add_result(
		Test::CPAN::Health::Result->new(check_id => 'b', status => 'fail', score => 0),
	);
	my $score_after = $report->overall_score;
	is($score_after, 50, 'Score drops to 50 after add_result invalidates cache');

	ok($score_after < $score_before, 'add_result correctly invalidated cached score');
};

# ===========================================================================
# 6. Report: SecurityAdvisories hard cap (60)
# ===========================================================================
subtest 'Report: SecurityAdvisories hard cap limits score' => sub {

	# EC::HeavyPassCheck has weight 100 so the raw average is ~99 before the cap.
	# EC::CapCheck has weight 1 and produces a security_advisories fail.
	# Expected: raw ~99 is capped to 60.
	my $report = Test::CPAN::Health::Report->new(
		checks => [EC::CapCheck->new, EC::HeavyPassCheck->new],
	);

	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'security_advisories',
			status   => 'fail',
			score    => 0,
			summary  => 'mock advisory',
		),
	);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'heavy_pass',
			status   => 'pass',
			score    => 100,
			summary  => 'excellent',
		),
	);

	my $score = $report->overall_score;
	# Raw ≈ (0*1 + 100*100) / 101 ≈ 99; min(99, 60) = 60.
	is($score, $CAP_SECADV, "Score capped at $CAP_SECADV when security_advisories fails (raw was ~99)");
	diag "SecurityAdvisories cap score: $score" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 6b. Report: cap does NOT raise scores below the ceiling
# ===========================================================================
subtest 'Report: hard cap does not raise scores already below the ceiling' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	# security_advisories fail with a very low raw score (no heavy passing check).
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'security_advisories',
			status   => 'fail',
			score    => 0,
			summary  => 'CVE found',
		),
	);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'another',
			status   => 'fail',
			score    => 20,
			summary  => 'also bad',
		),
	);

	# Raw average: (0 + 20) / 2 = 10; min(10, 60) = 10.
	my $score = $report->overall_score;
	cmp_ok($score, '<', $CAP_SECADV,
		"Score ($score) not raised to cap -- cap is a ceiling, not a floor");
};

# ===========================================================================
# 7. Report: add_result rejects non-Result inputs
# ===========================================================================
subtest 'Report: add_result rejects non-Result inputs' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	throws_ok(sub { $report->add_result(undef)  }, qr/result must be/i, 'add_result(undef) croaks');
	throws_ok(sub { $report->add_result('text') }, qr/result must be/i, 'add_result(string) croaks');
	throws_ok(sub { $report->add_result({})     }, qr/result must be/i, 'add_result(hashref) croaks');
};

# ===========================================================================
# 8. Report: by_category falls back to 'unknown' for missing category key
# ===========================================================================
subtest 'Report: by_category uses unknown for results without category in data' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	# Result with no 'category' key in data -- Runner stamps it; without Runner it is absent.
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'no_cat',
			status   => 'pass',
			score    => 80,
			summary  => 'fine',
		),
	);

	# Result with explicit category.
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'with_cat',
			status   => 'warn',
			score    => 60,
			summary  => 'meh',
			data     => { category => 'quality' },
		),
	);

	my $by_cat = $report->by_category;

	ok(exists $by_cat->{unknown}, 'Result with missing category key bucketed as unknown');
	is(scalar @{$by_cat->{unknown}}, 1, 'Exactly one result in unknown bucket');
	ok(exists $by_cat->{quality},   'Result with category=quality bucketed correctly');
	is(scalar @{$by_cat->{quality}}, 1, 'Exactly one result in quality bucket');
};

# ===========================================================================
# 9. Runner: hostile Distribution arguments
# ===========================================================================
subtest 'Runner: hostile Distribution arguments croak' => sub {

	my $runner = Test::CPAN::Health::Runner->new(checks => []);

	throws_ok(sub { $runner->run(undef)    }, qr/dist must be/i, 'run(undef) croaks');
	throws_ok(sub { $runner->run('string') }, qr/dist must be/i, 'run(string) croaks');
	throws_ok(sub { $runner->run({})       }, qr/dist must be/i, 'run(hashref) croaks');
};

# ===========================================================================
# 10. Runner: check returning undef contributes no result
# ===========================================================================
subtest 'Runner: check returning undef produces no result in Report' => sub {

	my $dist   = _bare_dist();
	my $runner = Test::CPAN::Health::Runner->new(checks => [EC::NullCheck->new]);
	my $report = $runner->run($dist);

	is(scalar @{$report->results}, 0,
		'Check returning undef produces no result (silently skipped)');
};

# ===========================================================================
# 11. Runner: exploding check produces error Result (does not abort run)
# ===========================================================================
subtest 'Runner: exception in check produces error Result, run continues' => sub {

	my $dist   = _bare_dist();
	my $runner = Test::CPAN::Health::Runner->new(
		checks => [EC::NullCheck->new, EC::ExplodingCheck->new, EC::NullCheck->new],
	);
	my $report = $runner->run($dist);

	my @results = @{$report->results};
	is(scalar @results, 1,          'Exactly one result (the error from ExplodingCheck)');
	is($results[0]->status, 'error', 'Exploding check status is error');
	like($results[0]->summary, qr/simulated check kaboom/,
		'Error summary carries the exception message');
};

# ===========================================================================
# 12. Runner: check returning non-Result gets converted to error Result
#
#     BUG (fixed in this session): before the fix, the Runner crashed with
#     "Can't call method 'data' on non-reference" when it tried to stamp
#     $result->data->{category} onto the non-object return value.
# ===========================================================================
subtest 'Runner: non-Result check return converted to error Result (regression)' => sub {

	my $dist   = _bare_dist();
	my $runner = Test::CPAN::Health::Runner->new(checks => [EC::BadReturnCheck->new]);

	my $report;
	lives_ok(
		sub { $report = $runner->run($dist) },
		'Runner does not crash when a check returns a non-Result',
	);

	SKIP: {
		skip 'run() did not return a report', 2 unless defined $report;
		my @results = @{$report->results};
		is(scalar @results, 1,           'One error Result produced for non-Result return');
		is($results[0]->status, 'error', 'Non-Result return converted to error status');
		diag 'Non-Result error summary: ' . $results[0]->summary if $ENV{TEST_VERBOSE};
	}
};

# ===========================================================================
# 13. Runner: skip results bypass the cache (never stored)
# ===========================================================================
subtest 'Runner: skip results are never written to the cache' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));

	# Spy on Cache::store to verify it is never called for skip results.
	my $store_calls = spy('Test::CPAN::Health::Cache', 'store');

	my $runner = Test::CPAN::Health::Runner->new(
		checks => [EC::SkipCheck->new],
		cache  => $cache,
	);
	$runner->run(_bare_dist());

	my @calls = $store_calls->();
	is(scalar @calls, 0, 'Cache::store never called for a skip result');

	restore_all();
};

# ===========================================================================
# 14. Runner: error results bypass the cache (never stored)
# ===========================================================================
subtest 'Runner: error results are never written to the cache' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));
	my $store_calls = spy('Test::CPAN::Health::Cache', 'store');

	my $runner = Test::CPAN::Health::Runner->new(
		checks => [EC::ExplodingCheck->new],
		cache  => $cache,
	);
	$runner->run(_bare_dist());

	my @calls = $store_calls->();
	is(scalar @calls, 0, 'Cache::store never called for an error result');

	restore_all();
};

# ===========================================================================
# 15. Distribution: hostile path inputs
# ===========================================================================
subtest 'Distribution: hostile path inputs' => sub {

	# Non-existent path.
	throws_ok(
		sub { Test::CPAN::Health::Distribution->new(path => '/path/that/does/not/exist/xyz') },
		qr/does not exist/i,
		'Non-existent path croaks',
	);

	# Empty string path (PVS min=1).
	throws_ok(
		sub { Test::CPAN::Health::Distribution->new(path => '') },
		qr/path/i,
		'Empty string path croaks',
	);

	# Path to a plain file (not a directory).
	my $tmp_file = File::Spec->catfile(
		File::Spec->tmpdir, "edge_test_file_$$.txt",
	);
	{   open my $fh, '>', $tmp_file or die "Cannot create temp file: $!";
		print {$fh} 'content';
	}
	throws_ok(
		sub { Test::CPAN::Health::Distribution->new(path => $tmp_file) },
		qr/does not exist/i,
		'Path pointing to a file (not dir) croaks',
	);
	unlink $tmp_file if -f $tmp_file;
};

# ===========================================================================
# 16. Distribution: file_path path traversal behaviour (known limitation)
# ===========================================================================
subtest 'Distribution: file_path path traversal is a known limitation' => sub {

	my $tmp  = tempdir(CLEANUP => 1);
	my $dist = Test::CPAN::Health::Distribution->new(path => $tmp);

	# file_path does not guard against "../" traversal; it uses catfile then -e.
	# This test documents that the method CAN return paths outside the dist root.
	my $traversal_result = $dist->file_path('..', 'etc', 'passwd');

	if (defined $traversal_result) {
		unlike(
			$traversal_result,
			qr{^\Q$tmp\E},
			'file_path traversal escapes the dist root (known limitation -- no guard)',
		);
		diag "Traversal path returned: $traversal_result" if $ENV{TEST_VERBOSE};
	} else {
		pass('file_path traversal returned undef (path outside dist not found)');
	}
};

# ===========================================================================
# 17. Distribution: meta returns undef for bare dist
# ===========================================================================
subtest 'Distribution: meta() returns undef when no META files present' => sub {

	my $dist = _bare_dist();
	ok(!defined $dist->meta, 'meta() returns undef for dist with no META.json/yml');
};

# ===========================================================================
# 18. Distribution: corrupt META.json emits carp and returns undef
# ===========================================================================
subtest 'Distribution: corrupt META.json triggers carp and returns undef' => sub {

	my $dir = tempdir(CLEANUP => 1);
	{   open my $fh, '>', File::Spec->catfile($dir, 'META.json') or die $!;
		print {$fh} 'this is { not valid } json at all';
	}

	my $dist    = Test::CPAN::Health::Distribution->new(path => $dir);
	my $warned  = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $meta    = $dist->meta;

	ok(!defined $meta, 'Corrupt META.json returns undef');
	ok($warned > 0,    'Corrupt META.json triggers a carp/warning');
};

# ===========================================================================
# 19. Distribution: name() strips version suffix from dirname when no META
# ===========================================================================
subtest 'Distribution: name() strips version from directory basename' => sub {

	my $parent = tempdir(CLEANUP => 1);

	for my $case (
		['Foo-Bar-1.23',  'Foo-Bar'],
		['Foo-Bar-0.001', 'Foo-Bar'],
		['FooBar',        'FooBar' ],
		['Foo-1',         'Foo'    ],
	) {
		my ($dirname, $expected) = @{$case};
		my $dir  = File::Spec->catdir($parent, $dirname);
		make_path($dir) unless -d $dir;
		my $dist = Test::CPAN::Health::Distribution->new(path => $dir);
		is($dist->name, $expected,
			"name() for dirname '$dirname' returns '$expected'");
	}
};

# ===========================================================================
# 20. Cache: hostile key inputs for get and store
# ===========================================================================
subtest 'Cache: empty/undef keys croak on get and store' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));

	throws_ok(sub { $cache->get('')    }, qr/key is required/i, 'get("") croaks');
	throws_ok(sub { $cache->get(undef) }, qr/key is required/i, 'get(undef) croaks');

	throws_ok(
		sub { $cache->store('', { status => 'pass' }) },
		qr/key is required/i,
		'store("", ...) croaks',
	);
	throws_ok(
		sub { $cache->store(undef, { status => 'pass' }) },
		qr/key is required/i,
		'store(undef, ...) croaks',
	);
};

# ===========================================================================
# 21. Cache: hostile value inputs for store
# ===========================================================================
subtest 'Cache: non-hashref values croak on store' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));
	my $key   = 'check:Dist:1.0';

	throws_ok(
		sub { $cache->store($key, undef)      },
		qr/value is required/i,
		'store(key, undef) croaks',
	);
	throws_ok(
		sub { $cache->store($key, [1, 2, 3])  },
		qr/value is required/i,
		'store(key, arrayref) croaks (must be hashref)',
	);
	throws_ok(
		sub { $cache->store($key, 'a string') },
		qr/value is required/i,
		'store(key, scalar) croaks (must be hashref)',
	);
};

# ===========================================================================
# 22. Cache: TTL=0 causes immediate expiry
#
# When TTL is 0, expires = time_of_write.  The SELECT condition is
# "expires > now" (strict greater-than), so reading at the same second
# (now >= time_of_write) returns undef.
# ===========================================================================
subtest 'Cache: TTL=0 entry is immediately expired on get' => sub {

	my $cache = Test::CPAN::Health::Cache->new(
		cache_dir => tempdir(CLEANUP => 1),
		ttls      => { zero_ttl => 0 },
	);
	my $key = 'zero_ttl:Dist:1.0';

	$cache->store($key, { status => 'pass', score => 100 });

	# Read in the same second: expires = time_of_write <= now, so get returns undef.
	my $val = $cache->get($key);
	ok(!defined $val, 'Entry with TTL=0 is expired immediately on get');
};

# ===========================================================================
# 23. Cache: SQL injection attempt in key is safely handled
# ===========================================================================
subtest 'Cache: SQL injection attempt in key is parameterized safely' => sub {

	my $cache = Test::CPAN::Health::Cache->new(cache_dir => tempdir(CLEANUP => 1));

	# DBI parameterization must prevent the injection from executing as SQL.
	lives_ok(
		sub { $cache->store($SQL_INJECT, { status => 'pass' }) },
		'store() with SQL injection key does not crash or execute SQL',
	);

	# The DB must still be functional after the injection attempt.
	lives_ok(
		sub { $cache->store('safe:Foo:1.0', { status => 'ok' }) },
		'DB is still usable after SQL injection attempt',
	);
};

# ===========================================================================
# 24. Cache: purge removes expired entries and returns count
# ===========================================================================
subtest 'Cache: purge removes expired entries and returns integer count' => sub {

	my $cache = Test::CPAN::Health::Cache->new(
		cache_dir => tempdir(CLEANUP => 1),
		ttls      => { purge_test => 0 },    # immediately expired
	);

	$cache->store('purge_test:A:1.0', { v => 1 });
	$cache->store('purge_test:B:2.0', { v => 2 });

	my $deleted = $cache->purge;
	cmp_ok($deleted, '>=', 2, 'purge removed at least the 2 immediately-expired entries');
	returns_ok($deleted, { type => 'integer' }, 'purge returns an integer');
};

# ===========================================================================
# 25. Cache: tampered (corrupt) JSON value carps and returns undef
# ===========================================================================
subtest 'Cache: corrupt JSON in DB triggers carp and returns undef' => sub {

	my $tmp   = tempdir(CLEANUP => 1);
	my $cache = Test::CPAN::Health::Cache->new(
		cache_dir => $tmp,
		ttls      => { corrupt => 3_600 },
	);
	my $key = 'corrupt:Foo:1.0';

	$cache->store($key, { status => 'pass' });

	# Directly write invalid JSON into the DB row.
	my $db_file = File::Spec->catfile($tmp, 'cpan-health.db');
	{   my $dbh = DBI->connect(
			"dbi:SQLite:dbname=$db_file", q{}, q{}, { RaiseError => 1 },
		);
		$dbh->do(
			q(UPDATE cache SET value = '{bad json{{' WHERE key = ?),
			undef,
			$key,
		);
		$dbh->disconnect;
	}

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $val = $cache->get($key);

	ok(!defined $val, 'Tampered JSON returns undef from get()');
	ok($warned > 0,   'Tampered JSON triggers a warning/carp');
};

# ===========================================================================
# 26. HTML Reporter: XSS vectors are HTML-entity-escaped
# ===========================================================================
subtest 'HTML Reporter: XSS vectors escaped in name, summary, details, title' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'xss',
			status   => 'fail',
			score    => 0,
			summary  => "Summary: $XSS_SCRIPT",
			details  => [
				"Detail: $XSS_SCRIPT",
				"AttrXSS: $XSS_ATTR",
				"Squote: $XSS_SQUOTE",
			],
			data     => { name => "Name: $XSS_SCRIPT", category => 'quality' },
		),
	);

	my $html = Test::CPAN::Health::Reporter::HTML->new(
		title => "Title: $XSS_SCRIPT",
	)->render($report);

	# Raw angle-bracket tags must not appear in the output.
	unlike($html, qr/<script>/,          'Raw <script> absent from HTML');
	like($html,   qr/&lt;script&gt;/,   '<script> is entity-escaped in HTML');

	# Double-quote is escaped: an injected `"` cannot break out of an HTML attribute.
	# Note: the TEXT "onmouseover=" is still present in element CONTENT (safe), but the
	# surrounding double-quotes are &quot; so no attribute injection can occur.
	like($html,   qr/&quot;\s*onmouseover=/, 'Double-quote before onmouseover is &quot;');
	unlike($html, qr/(?<!&quot;)" onmouseover=/, 'No raw double-quote before onmouseover');

	# Single-quote injection: `'` becomes `&#39;`.
	like($html,   qr/&#39;\s*onerror=/, "Single-quote before onerror is &#39;");

	diag 'First 500 chars of HTML: ' . substr($html, 0, 500) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 26b. HTML Reporter: pre-existing &amp; is re-escaped (no double-decode)
# ===========================================================================
subtest 'HTML Reporter: ampersand entity is re-escaped (no XSS via double-decode)' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);
	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'amp',
			status   => 'pass',
			score    => 100,
			summary  => $AMP_ENTITY,    # '&amp;<b>injected</b>'
		),
	);

	my $html = Test::CPAN::Health::Reporter::HTML->new->render($report);

	# The & in &amp; must itself become &amp;, yielding &amp;amp;.
	like($html, qr/&amp;amp;/, 'Pre-encoded & is re-encoded to &amp;amp; (double-encoding)');

	# The raw <b> from the injected portion must be escaped.
	unlike($html, qr/<b>/,    'Raw <b> tag absent from HTML output');
};

# ===========================================================================
# 27. HTML Reporter: non-Report argument croaks
# ===========================================================================
subtest 'HTML Reporter: non-Report argument to render() croaks' => sub {

	my $r = Test::CPAN::Health::Reporter::HTML->new;

	throws_ok(sub { $r->render(undef)   }, qr/report must be/i, 'render(undef) croaks');
	throws_ok(sub { $r->render('text')  }, qr/report must be/i, 'render(string) croaks');
	throws_ok(sub { $r->render({})      }, qr/report must be/i, 'render(hashref) croaks');
};

# ===========================================================================
# 28. TAP Reporter: # in labels replaced with [#]
# ===========================================================================
subtest 'TAP Reporter: # in name and summary replaced with [#]' => sub {

	my $report = Test::CPAN::Health::Report->new(checks => []);

	$report->add_result(
		Test::CPAN::Health::Result->new(
			check_id => 'hash_test',
			status   => 'pass',
			score    => 80,
			summary  => 'Test #1 and #2 passed',
			data     => { name => 'Check #Alpha' },
		),
	);

	my $tap = Test::CPAN::Health::Reporter::TAP->new->render($report);

	# Neither the name nor the summary should contain a bare # on a test line.
	my ($test_line) = grep { /^(ok|not ok)/ } split /\n/, $tap;
	unlike($test_line // '', qr/Check #Alpha/,   'Raw # in name absent from TAP line');
	unlike($test_line // '', qr/Test #1/,         'Raw # in summary absent from TAP line');
	like($test_line   // '', qr/\[#\]/,            '[#] substitution present in TAP line');

	diag "TAP output:\n$tap" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 29. TAP Reporter: empty Report produces 1..0 plan line
# ===========================================================================
subtest 'TAP Reporter: empty Report produces 1..0 plan' => sub {

	my $tap = Test::CPAN::Health::Reporter::TAP->new->render(
		Test::CPAN::Health::Report->new(checks => []),
	);

	like($tap, qr/^1\.\.0$/m, 'Empty Report produces 1..0 plan');
};

# ===========================================================================
# 30. TAP Reporter: non-Report argument croaks
# ===========================================================================
subtest 'TAP Reporter: non-Report argument to render() croaks' => sub {

	my $r = Test::CPAN::Health::Reporter::TAP->new;

	throws_ok(sub { $r->render(undef)  }, qr/report must be/i, 'render(undef) croaks');
	throws_ok(sub { $r->render('text') }, qr/report must be/i, 'render(string) croaks');
};

# ===========================================================================
# 31. Check base class: abstract methods croak when not overridden
# ===========================================================================
subtest 'Check base class: unimplemented abstract methods croak' => sub {

	# Manufacture a bare Check object without going through a subclass.
	my $base = bless { _severity => 3, _no_network => 0, _no_cover => 0 },
		'Test::CPAN::Health::Check';

	throws_ok(sub { $base->id   }, qr/must implement id/i,   'id() in base class croaks');
	throws_ok(sub { $base->name }, qr/must implement name/i,  'name() in base class croaks');
	throws_ok(sub { $base->run  }, qr/must implement run/i,   'run() in base class croaks');
};

# ===========================================================================
# 32. Check base class: severity bounds enforced by PVS
# ===========================================================================
subtest 'Check base class: severity 1-5 valid, 0 and 6 croak' => sub {

	for my $s (1 .. 5) {
		my $c = EC::NullCheck->new(severity => $s);
		is($c->severity, $s, "severity $s is valid");
	}

	throws_ok(
		sub { EC::NullCheck->new(severity => 0) },
		qr/severity.*(?:positive|at least 1)/i,
		'severity 0 croaks (below minimum)',
	);
	throws_ok(
		sub { EC::NullCheck->new(severity => 6) },
		qr/severity.*(?:no more than 5|too (?:large|big)|maximum)/i,
		'severity 6 croaks (above maximum)',
	);
};

# ===========================================================================
# 33. Check: unknown constructor key croaks (PVS strict)
# ===========================================================================
subtest 'Check: unknown constructor key croaks' => sub {

	throws_ok(
		sub { EC::NullCheck->new(bogus_key => 42) },
		qr/Unknown parameter/i,
		'Unknown constructor argument croaks (PVS strict mode)',
	);
};

# ===========================================================================
# 34. Check: _skip and _error use default messages for undef arguments
# ===========================================================================
subtest 'Check: _skip/_error default messages when arg is undef' => sub {

	my $check = EC::NullCheck->new;

	# _skip(undef) must use the default message 'Not applicable'.
	my $skip_default = $check->_skip(undef);
	is($skip_default->status,  'skip',           '_skip(undef) produces skip status');
	is($skip_default->summary, 'Not applicable', '_skip(undef) uses default summary');

	# _skip with an explicit reason uses that reason.
	my $skip_custom = $check->_skip('No network available');
	is($skip_custom->summary, 'No network available', '_skip with reason uses that reason');

	# _error(undef) must use the default message 'Unknown error'.
	my $err_default = $check->_error(undef);
	is($err_default->status,  'error',         '_error(undef) produces error status');
	is($err_default->summary, 'Unknown error', '_error(undef) uses default summary');

	# _error with an explicit message uses that message.
	my $err_custom = $check->_error('Simulated failure');
	is($err_custom->summary, 'Simulated failure', '_error with message uses that message');
};

done_testing();
