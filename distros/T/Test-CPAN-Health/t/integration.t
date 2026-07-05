#!/usr/bin/env perl
#
# Black-box integration tests: validate cross-module workflows and stateful
# interactions across the full Test::CPAN::Health stack.
#
# Strategy: real temp-dir distributions exercise the pipeline end-to-end
# (Distribution -> Runner -> Checks -> Report -> Reporter).  Optional deps
# are tested by temporarily blocking them via an @INC hook so graceful-
# degradation paths are always exercised, regardless of local installation.

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json);
use Readonly;
use Scalar::Util qw(blessed);

use Test::Most;
use Test::Returns qw(returns_ok);

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Constants: no magic literals in test code
# ---------------------------------------------------------------------------

Readonly::Hash my %STATUS => (
	PASS  => 'pass',
	WARN  => 'warn',
	FAIL  => 'fail',
	SKIP  => 'skip',
	ERROR => 'error',
);

Readonly::Scalar my $SCORE_MAX             => 100;
Readonly::Scalar my $SCORE_MIN             =>   0;
Readonly::Scalar my $CAP_SECURITY          =>  60;
Readonly::Scalar my $CAP_CI_TESTERS        =>  75;
Readonly::Scalar my $MINPERL_UNVERIFIED    =>  80;
Readonly::Scalar my $SCORE_META_YML        =>  70;
Readonly::Scalar my $SCORE_MYMETA          =>  50;

# Fast, offline checks that run without network or Devel::Cover.
Readonly::Array my @LOCAL_CHECKS => qw(
	sem_ver
	meta_json
	license
	examples
	benchmarks
	ci_config
	deprecations
	duplicate_code
	pod_coverage
	doc_quality
);

# ---------------------------------------------------------------------------
# Inline packages: context-propagation test helpers.
# Both inherit from Check via -norequire; the parent is loaded by use_ok()
# before any subtest calls new() or run().
# ---------------------------------------------------------------------------

{
	package Int::CtxWriter;
	use parent -norequire, 'Test::CPAN::Health::Check';
	sub id       { return 'ctx_writer'     }
	sub name     { return 'Context Writer' }
	sub category { return 'quality'        }
	sub weight   { return 1                }
	sub run {
		my ($self, $dist, $context) = @_;
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => 'wrote sentinel to context',
			data    => { count => 42, name => 'Context Writer' },
		);
	}
}

{
	package Int::CtxReader;
	use parent -norequire, 'Test::CPAN::Health::Check';
	our $OBSERVED;    # inspected by the test after run() completes
	sub id       { return 'ctx_reader'     }
	sub name     { return 'Context Reader' }
	sub category { return 'quality'        }
	sub weight   { return 1                }
	sub run {
		my ($self, $dist, $context) = @_;
		my $prev = $context->{ctx_writer};
		$Int::CtxReader::OBSERVED = defined $prev ? $prev->data->{count} : undef;
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => 'read context',
			data    => { name => 'Context Reader', saw => $Int::CtxReader::OBSERVED // 0 },
		);
	}
}

# ---------------------------------------------------------------------------
# MockWeight: provides ->id and ->weight for Report->new(checks => ...).
# Report only needs these two methods to build its weight map.
# ---------------------------------------------------------------------------

{
	package MockWeight;
	sub new    { my ($class, $id, $w) = @_; return bless { id => $id, w => $w }, $class }
	sub id     { return $_[0]->{id} }
	sub weight { return $_[0]->{w}  }
}

# ---------------------------------------------------------------------------
# Fixture builders
# ---------------------------------------------------------------------------

# "Golden" distribution: every local check should pass or at worst warn.
sub _make_good_dist {
	my $dir = tempdir(CLEANUP => 1);

	_write($dir, 'META.json', <<'END_META');
{
   "abstract"       : "A well-formed integration-test distribution",
   "author"         : [ "Test Author <test@example.com>" ],
   "dynamic_config" : 0,
   "generated_by"   : "hand",
   "license"        : [ "perl_5" ],
   "meta-spec"      : { "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec", "version" : "2" },
   "name"           : "Test-Good",
   "prereqs"        : { "runtime" : { "requires" : { "perl" : "5.020", "strict" : "0", "warnings" : "0" } } },
   "version"        : "1.2.3"
}
END_META

	_write($dir, 'LICENSE', "This software is available under the Perl 5 licence.\n");

	make_path(File::Spec->catdir($dir, 'lib'));
	_write($dir, 'lib', 'Good.pm', <<'END_PM');
package Good;
use strict;
use warnings;
our $VERSION = '1.2.3';

=head1 NAME

Good - Integration-test module

=head1 SYNOPSIS

    use Good;
    Good->greet;

=head1 DESCRIPTION

A well-formed module used by integration tests.

=head1 METHODS

=head2 greet

Returns a greeting string.

=head3 USAGE EXAMPLE

    my $msg = Good->greet;

=cut

sub greet { return 'hello' }

1;
END_PM

	make_path(File::Spec->catdir($dir, 't'));
	_write($dir, 't', 'good.t', "use Test::More; ok(1); done_testing;\n");

	# examples/ satisfies the Examples check
	make_path(File::Spec->catdir($dir, 'examples'));
	_write($dir, 'examples', 'demo.pl', "#!/usr/bin/perl\nprint 'demo';\n");

	# benchmarks/ satisfies the Benchmarks check
	make_path(File::Spec->catdir($dir, 'benchmarks'));
	_write($dir, 'benchmarks', 'bench.pl', "#!/usr/bin/perl\nprint 'bench';\n");

	# CIConfig looks for .github/workflows/*.yml
	make_path(File::Spec->catdir($dir, '.github', 'workflows'));
	_write($dir, '.github', 'workflows', 'ci.yml',
		"on: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps: []\n");

	return $dir;
}

# Bare directory: no META, no source files.
sub _make_bare_dist { return tempdir(CLEANUP => 1) }

# Only META.yml (no META.json): MetaJSON warns at score 70.
sub _make_yml_only_dist {
	my $dir = tempdir(CLEANUP => 1);
	# Use META.yml v1.4 format so CPAN::Meta can parse it without confusion.
	_write($dir, 'META.yml', <<'END_YML');
--- #YAML:1.0
name: Test-YmlOnly
version: 2.0.0
abstract: A YAML-only test distribution
author:
  - YAML Author <yaml@example.com>
license: perl_5
generated_by: hand
meta-spec:
  version: 1.4
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
END_YML
	return $dir;
}

# Only MYMETA.json (local checkout after perl Makefile.PL): MetaJSON warns at 50.
sub _make_mymeta_dist {
	my $dir = tempdir(CLEANUP => 1);
	_write($dir, 'MYMETA.json', <<'END_META');
{
   "abstract"       : "A MYMETA-only distribution",
   "author"         : [ "MYMETA Author <mymeta@example.com>" ],
   "dynamic_config" : 0,
   "generated_by"   : "Makefile.PL",
   "license"        : [ "perl_5" ],
   "meta-spec"      : { "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec", "version" : "2" },
   "name"           : "Test-MyMeta",
   "version"        : "3.0.0"
}
END_META
	return $dir;
}

# Both META.json and META.yml: Distribution->meta must prefer JSON.
sub _make_both_meta_dist {
	my $dir = _make_yml_only_dist();    # contributes META.yml
	_write($dir, 'META.json', <<'END_META');
{
   "abstract"       : "Distribution with both META files",
   "author"         : [ "Both Author <both@example.com>" ],
   "dynamic_config" : 0,
   "generated_by"   : "hand",
   "license"        : [ "perl_5" ],
   "meta-spec"      : { "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec", "version" : "2" },
   "name"           : "Test-Both",
   "version"        : "4.0.0"
}
END_META
	return $dir;
}

# Build a Report from a list of result specs (check_id, status, score, weight).
# Uses MockWeight so Report can compute a weighted score without real Check objects.
sub _build_report {
	my (@specs) = @_;

	require Test::CPAN::Health::Report;
	require Test::CPAN::Health::Result;

	my @weights = map { MockWeight->new($_->{check_id}, $_->{weight} // 1) } @specs;
	my $report  = Test::CPAN::Health::Report->new(checks => \@weights);

	for my $spec (@specs) {
		$report->add_result(
			Test::CPAN::Health::Result->new(
				check_id => $spec->{check_id},
				status   => $spec->{status},
				score    => $spec->{score},
				summary  => $spec->{summary} // 'test summary',
				data     => $spec->{data}    // {},
				details  => $spec->{details} // [],
			)
		);
	}

	return $report;
}

# Return the first Result whose check_id matches, or undef.
sub _result_for {
	my ($report, $check_id) = @_;
	my ($r) = grep { $_->check_id eq $check_id } @{$report->results};
	return $r;
}

# Write $content to $base/@parts, creating parent directories as needed.
sub _write {
	my ($base, @parts) = @_;
	my $content  = pop @parts;
	my $file     = File::Spec->catfile($base, @parts);
	my $dir_part = (File::Spec->splitpath($file))[1];
	make_path($dir_part) if $dir_part && !-d $dir_part;
	open my $fh, '>', $file or die "Cannot write '$file': $!";
	print {$fh} $content;
	close $fh;
	return $file;
}

# Temporarily block a module from being require'd.
# Returns a restore sub; call it when the block should be lifted.
# Also deletes the module from %INC so an existing load doesn't bypass the hook.
sub _block_module {
	my (@modules) = @_;

	my @blocked_paths = map { (my $p = "$_.pm") =~ s{::}{/}g; $p } @modules;
	my %saved         = map { $_ => delete $INC{$_} } @blocked_paths;

	my $hook = sub {
		my (undef, $module) = @_;
		for my $blocked (@blocked_paths) {
			if ($module eq $blocked) {
				die "Blocked for testing: $module\n";
			}
		}
		return;
	};

	unshift @INC, $hook;

	return sub {
		@INC = grep { $_ ne $hook } @INC;
		while (my ($k, $v) = each %saved) {
			$INC{$k} = $v if defined $v;
		}
	};
}

# ===========================================================================
# Module loading -- tests that every public class is importable
# ===========================================================================

use_ok('Test::CPAN::Health');
use_ok('Test::CPAN::Health::Check');        # parent of inline packages; must load first
use_ok('Test::CPAN::Health::Distribution');
use_ok('Test::CPAN::Health::Result');
use_ok('Test::CPAN::Health::Report');
use_ok('Test::CPAN::Health::Runner');
use_ok('Test::CPAN::Health::Cache');
use_ok('Test::CPAN::Health::Reporter::JSON');
use_ok('Test::CPAN::Health::Reporter::TAP');
use_ok('Test::CPAN::Health::Reporter::HTML');
use_ok('Test::CPAN::Health::Reporter::Terminal');

# ===========================================================================
# 1. Health::new -- constructor validation, format routing, lazy init
# ===========================================================================

subtest 'Health::new: constructor validation, format routing, lazy-init accessors' => sub {
	my $good = _make_good_dist();

	# No source argument must croak with the documented message.
	throws_ok { Test::CPAN::Health->new }
		qr/One of path, module, dist, or distribution is required/,
		'new() without source arg croaks';

	# Unknown format must croak.
	throws_ok { Test::CPAN::Health->new(path => $good, format => 'yaml') }
		qr/Unknown format 'yaml'/,
		'new() with unknown format croaks';

	# All four valid formats are accepted; output_format accessor reflects each.
	for my $fmt (qw(terminal json html tap)) {
		my $h;
		lives_ok { $h = Test::CPAN::Health->new(path => $good, format => $fmt) }
			"format '$fmt' accepted without croaking";
		is($h->output_format, $fmt, "output_format() returns '$fmt'");
	}

	# Components are undef at construction; they are initialised by analyse().
	my $h = Test::CPAN::Health->new(path => $good, min_score => 75);
	is($h->min_score, 75, 'min_score accessor returns constructor arg');
	ok(!defined $h->distribution, 'distribution is undef before analyse()');
	ok(!defined $h->runner,       'runner is undef before analyse()');
	ok(!defined $h->reporter,     'reporter is undef before analyse()');

	diag 'Health::new assertions passed' if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 2. Full pipeline -- good distribution passes local checks
# ===========================================================================

subtest 'Full pipeline: good distribution -> analyse() -> valid Report' => sub {
	my $good = _make_good_dist();

	my $health = Test::CPAN::Health->new(
		path       => $good,
		format     => 'json',
		no_network => 1,
		no_cover   => 1,
		checks     => \@LOCAL_CHECKS,
	);

	my $report;
	lives_ok { $report = $health->analyse } 'analyse() completes without error';

	returns_ok(
		$report,
		{ type => 'object', isa => 'Test::CPAN::Health::Report' },
		'analyse() return type is Test::CPAN::Health::Report',
	);

	my $score = $report->overall_score;
	ok($score >= $SCORE_MIN && $score <= $SCORE_MAX,
		"overall_score $score is in range [$SCORE_MIN, $SCORE_MAX]");

	ok(scalar @{$report->results} > 0, 'report contains at least one result');

	# Lazy components must be populated after the first analyse() call.
	ok(defined $health->distribution, 'distribution initialised after analyse()');
	ok(defined $health->runner,       'runner initialised after analyse()');
	ok(defined $health->reporter,     'reporter initialised after analyse()');

	ok(ref $report->by_category eq 'HASH', 'by_category returns a hashref');
	ok(exists $report->by_category->{packaging},
		'packaging category present (sem_ver / meta_json / license all contribute)');

	# SemVer: "1.2.3" is strict semver -- must pass with score 100.
	my $sv = _result_for($report, 'sem_ver');
	ok(defined $sv, 'sem_ver result is present');
	is($sv->status, $STATUS{PASS}, 'sem_ver passes for version 1.2.3');
	is($sv->score,  100,           'sem_ver scores 100 for strict semver');
	like($sv->summary, qr/1\.2\.3/, 'sem_ver summary contains the version string');

	# MetaJSON: complete META.json must score 100.
	my $mj = _result_for($report, 'meta_json');
	ok(defined $mj, 'meta_json result is present');
	is($mj->score, 100, 'meta_json scores 100 for complete META.json');

	diag sprintf('Good dist overall score: %d/100', $score) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 3. Full pipeline -- bare distribution (no META, no source)
# ===========================================================================

subtest 'Full pipeline: bare distribution -> most checks skip or fail' => sub {
	my $bare = _make_bare_dist();

	my $health = Test::CPAN::Health->new(
		path       => $bare,
		no_network => 1,
		no_cover   => 1,
		checks     => \@LOCAL_CHECKS,
	);

	my $report;
	lives_ok { $report = $health->analyse }
		'analyse() on a bare directory does not die';

	ok(blessed($report) && $report->isa('Test::CPAN::Health::Report'),
		'returns a Report object');

	# Without META.json, MetaJSON must fail with score 0.
	my $mj = _result_for($report, 'meta_json');
	ok(defined $mj,                   'meta_json result present for bare dist');
	is($mj->status, $STATUS{FAIL},    'meta_json fails when no META file exists');
	is($mj->score,  0,                'meta_json scores 0 with no META');

	my $score = $report->overall_score;
	ok($score >= $SCORE_MIN && $score <= $SCORE_MAX, "score $score is in range");

	diag sprintf('Bare dist score: %d/100', $score) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 4. Reporter format routing -- all four reporters produce distinct valid output
# ===========================================================================

subtest 'report_to(): all four formats produce non-empty, pattern-matching output' => sub {
	# Use a hand-built Report so this subtest does not depend on filesystem checks.
	my $report = _build_report(
		{ check_id => 'sem_ver',   status => 'pass', score => 100, summary => 'OK',        weight => 3 },
		{ check_id => 'meta_json', status => 'warn', score =>  70, summary => 'YAML only', weight => 5 },
		{ check_id => 'license',   status => 'fail', score =>   0, summary => 'No file',   weight => 4 },
	);

	my $good = _make_good_dist();

	# Map: format name -> regex that must match the rendered output.
	my %expected_pattern = (
		terminal => qr/Overall score/,
		json     => qr/\A\s*\{/,
		html     => qr/<!DOCTYPE html/i,
		tap      => qr/\A1\.\.\d+/,
	);

	for my $fmt (sort keys %expected_pattern) {
		my $health  = Test::CPAN::Health->new(path => $good, format => $fmt);
		my $output;

		lives_ok { $output = $health->report_to($report) }
			"report_to() with format '$fmt' does not die";

		ok(defined $output && length $output > 0,
			"format '$fmt' produces non-empty string");

		like($output, $expected_pattern{$fmt},
			"format '$fmt' output matches expected pattern");

		diag "  $fmt output (first 80 chars): " . substr($output, 0, 80)
			if $ENV{TEST_VERBOSE};
	}

	# report_to() must croak when given a non-Report.
	my $h = Test::CPAN::Health->new(path => $good, format => 'tap');
	throws_ok { $h->report_to({ fake => 1 }) }
		qr/report must be a Test::CPAN::Health::Report/,
		'report_to() croaks on non-Report argument';
};

# ===========================================================================
# 5. Skip filtering -- excluded check ids are absent from the Report
# ===========================================================================

subtest 'Skip filtering: excluded checks do not appear in results' => sub {
	my $good = _make_good_dist();

	my $health = Test::CPAN::Health->new(
		path       => $good,
		no_network => 1,
		no_cover   => 1,
		checks     => \@LOCAL_CHECKS,
		skip       => ['sem_ver', 'meta_json'],
	);

	my $report = $health->analyse;
	my @ids    = map { $_->check_id } @{$report->results};

	ok(!scalar(grep { $_ eq 'sem_ver'   } @ids), 'sem_ver absent when skipped');
	ok(!scalar(grep { $_ eq 'meta_json' } @ids), 'meta_json absent when skipped');

	# Other checks in the whitelist are not affected by the skip list.
	my $lic = _result_for($report, 'license');
	ok(defined $lic, 'license check still ran (not in skip list)');

	ok(!defined _result_for($report, 'sem_ver'),   'sem_ver result is undef');
	ok(!defined _result_for($report, 'meta_json'), 'meta_json result is undef');

	diag 'Skip filtering result ids: ' . join(', ', @ids) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 6. Check whitelist -- only the nominated checks produce results
# ===========================================================================

subtest 'Check whitelist: only specified checks appear in results' => sub {
	my $good = _make_good_dist();

	my $health = Test::CPAN::Health->new(
		path       => $good,
		no_network => 1,
		no_cover   => 1,
		checks     => ['sem_ver', 'meta_json'],
	);

	my $report = $health->analyse;
	my @ids    = map { $_->check_id } @{$report->results};

	is(scalar @ids, 2,
		'exactly 2 results when only 2 checks are whitelisted');
	ok(scalar(grep { $_ eq 'sem_ver'   } @ids), 'sem_ver present');
	ok(scalar(grep { $_ eq 'meta_json' } @ids), 'meta_json present');
	ok(!scalar(grep { $_ eq 'license'  } @ids), 'license absent (not whitelisted)');

	diag "Check whitelist ids: @ids" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 7. Cache integration -- a pre-populated entry overrides the live check
# ===========================================================================

subtest 'Cache: pre-populated entry bypasses the live check in Runner' => sub {
	require Test::CPAN::Health::Cache;

	my $good      = _make_good_dist();
	my $cache_dir = tempdir(CLEANUP => 1);

	# Store a deliberately wrong sem_ver result.  If the cache is consulted,
	# the live check (which would pass for 1.2.3) is never called.
	my $cache = Test::CPAN::Health::Cache->new(cache_dir => $cache_dir);

	my $store_result = $cache->store(
		'sem_ver:Test-Good:1.2.3',
		{
			check_id => 'sem_ver',
			status   => 'fail',
			score    => 0,
			summary  => 'SENTINEL: from cache, not live check',
			details  => [],
			data     => {},
		},
	);
	returns_ok(
		$store_result,
		{ type => 'object', isa => 'Test::CPAN::Health::Cache' },
		'Cache::store returns $self for chaining',
	);

	my $health = Test::CPAN::Health->new(
		path       => $good,
		no_network => 1,
		no_cover   => 1,
		checks     => ['sem_ver'],
		cache_dir  => $cache_dir,
	);

	my $report = $health->analyse;
	my $result = _result_for($report, 'sem_ver');

	ok(defined $result, 'sem_ver result present in report');
	is($result->status, $STATUS{FAIL},
		'cached status (fail) returned instead of live pass');
	like($result->summary, qr/SENTINEL/,
		'cached summary returned verbatim -- proves cache was consulted');

	# When cache_dir is explicit the DB is placed directly inside it (the
	# cpan-health/ subdirectory is only appended by _default_cache_dir()).
	my $db_file = File::Spec->catfile($cache_dir, 'cpan-health.db');
	ok(-f $db_file, 'SQLite cache DB file was written to disk');

	diag "Cache DB path: $db_file" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 8. Hard cap: security_advisories fail caps overall score at 60
# ===========================================================================

subtest 'Hard cap: security_advisories fail -> overall score <= 60' => sub {
	# Weight the clean checks heavily so the uncapped mean would exceed 60.
	my $report = _build_report(
		{ check_id => 'sem_ver',             status => 'pass', score => 100, weight => 20 },
		{ check_id => 'meta_json',           status => 'pass', score => 100, weight => 20 },
		{ check_id => 'security_advisories', status => 'fail', score =>   0, weight =>  1 },
	);

	# Uncapped mean ~ (100*20 + 100*20) / 41 ~ 98.  Cap must bring it to 60.
	my $score = $report->overall_score;
	ok($score <= $CAP_SECURITY,
		"score $score is capped at $CAP_SECURITY when security_advisories fails");
	ok($score >= $SCORE_MIN, 'capped score is non-negative');

	diag "Security cap score: $score" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 9. Hard cap: cpan_testers fail caps overall score at 75
# ===========================================================================

subtest 'Hard cap: cpan_testers fail -> overall score <= 75' => sub {
	my $report = _build_report(
		{ check_id => 'sem_ver',      status => 'pass', score => 100, weight => 20 },
		{ check_id => 'meta_json',    status => 'pass', score => 100, weight => 20 },
		{ check_id => 'cpan_testers', status => 'fail', score =>   0, weight =>  1 },
	);

	my $score = $report->overall_score;
	ok($score <= $CAP_CI_TESTERS,
		"score $score is capped at $CAP_CI_TESTERS when cpan_testers fails");
	ok($score >= $SCORE_MIN, 'capped score is non-negative');

	diag "CI testers cap score: $score" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 10. Both hard caps simultaneously -- the lower cap (security = 60) wins
# ===========================================================================

subtest 'Both caps active: lower security cap (60) wins over CI cap (75)' => sub {
	my $report = _build_report(
		{ check_id => 'sem_ver',             status => 'pass', score => 100, weight => 30 },
		{ check_id => 'security_advisories', status => 'fail', score =>   0, weight =>  1 },
		{ check_id => 'cpan_testers',        status => 'fail', score =>   0, weight =>  1 },
	);

	# Raw mean ~ 94; security cap = 60, CI cap = 75; effective cap = min(60,75).
	my $score = $report->overall_score;
	ok($score <= $CAP_SECURITY,
		"score $score obeys the tighter security cap ($CAP_SECURITY) when both caps fire");

	diag "Both-caps score: $score" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 11. Context propagation: Runner passes each result to subsequent checks
# ===========================================================================

subtest 'Runner context propagation: later check sees earlier check result' => sub {
	require Test::CPAN::Health::Runner;
	require Test::CPAN::Health::Distribution;

	my $bare = _make_bare_dist();
	my $dist = Test::CPAN::Health::Distribution->new(path => $bare);

	# Int::CtxWriter writes to context; Int::CtxReader reads it and stores the
	# observed value in a package variable for inspection.
	local $Int::CtxReader::OBSERVED = undef;

	my $runner = Test::CPAN::Health::Runner->new(
		checks => [ Int::CtxWriter->new, Int::CtxReader->new ],
	);

	my $report = $runner->run($dist);

	is(scalar @{$report->results}, 2,
		'both checks produced results');

	is($Int::CtxReader::OBSERVED, 42,
		'second check saw the first check\'s context value (42)');

	my $reader_result = _result_for($report, 'ctx_reader');
	ok(defined $reader_result, 'ctx_reader result present');
	is($reader_result->data->{saw}, 42,
		'observed context value is embedded in ctx_reader result data');

	diag "Propagated context value: ${\($Int::CtxReader::OBSERVED // 'undef')}"
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 12. Multi-instance isolation: two Health objects on different dists
# ===========================================================================

subtest 'Multi-instance isolation: two Health objects do not share state' => sub {
	my $good = _make_good_dist();
	my $bare = _make_bare_dist();

	my $h_good = Test::CPAN::Health->new(
		path       => $good,
		format     => 'json',
		no_network => 1,
		no_cover   => 1,
		checks     => ['sem_ver', 'meta_json'],
	);

	my $h_bare = Test::CPAN::Health->new(
		path       => $bare,
		format     => 'html',
		no_network => 1,
		no_cover   => 1,
		checks     => ['sem_ver', 'meta_json'],
	);

	# Each instance tracks its own format independently.
	is($h_good->output_format, 'json', 'good instance has json format');
	is($h_bare->output_format, 'html', 'bare instance has html format');

	my $report_good = $h_good->analyse;
	my $report_bare = $h_bare->analyse;

	# The returned objects must be distinct.
	isnt("$report_good", "$report_bare", 'two reports are distinct objects');

	# sem_ver: passes on good dist (META.json, 1.2.3); skips on bare dist (no META).
	my $sv_good = _result_for($report_good, 'sem_ver');
	my $sv_bare = _result_for($report_bare, 'sem_ver');
	ok(defined $sv_good && $sv_good->is_pass, 'good dist: sem_ver passes');
	ok(defined $sv_bare && $sv_bare->is_skip, 'bare dist: sem_ver skips (no META)');

	# Scores must differ because the two dists are structurally different.
	isnt($report_good->overall_score, $report_bare->overall_score,
		'the two instances produced different overall scores');

	# Each reporter is the type that matches its instance's format.
	ok(blessed($h_good->reporter)->isa('Test::CPAN::Health::Reporter::JSON'),
		'good instance uses JSON reporter');
	ok(blessed($h_bare->reporter)->isa('Test::CPAN::Health::Reporter::HTML'),
		'bare instance uses HTML reporter');

	diag sprintf('Good: %d  Bare: %d', $report_good->overall_score, $report_bare->overall_score)
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 13. Optional dep -- MinPerl degrades gracefully without Perl::MinimumVersion
# ===========================================================================

subtest 'MinPerl: score 80 (unverified) when Perl::MinimumVersion absent' => sub {
	require Test::CPAN::Health::Check::MinPerl;
	require Test::CPAN::Health::Distribution;

	my $good   = _make_good_dist();
	my $dist   = Test::CPAN::Health::Distribution->new(path => $good);

	# Block Perl::MinimumVersion so MinPerl falls back to the unverified path.
	my $restore = _block_module('Perl::MinimumVersion');

	my $check  = Test::CPAN::Health::Check::MinPerl->new;
	my $result = $check->run($dist);

	is($result->status, $STATUS{PASS},
		'MinPerl: status is pass when Perl::MinimumVersion unavailable');
	is($result->score, $MINPERL_UNVERIFIED,
		'MinPerl: score is 80 (unverified) without Perl::MinimumVersion');
	like($result->summary, qr/Perl::MinimumVersion/,
		'MinPerl: summary advises installing Perl::MinimumVersion');

	$restore->();

	diag sprintf('MinPerl (no PMV): %s / %d', $result->status, $result->score)
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 14. Optional dep -- SecurityAdvisories skips without CPAN::Audit
# ===========================================================================

subtest 'SecurityAdvisories: skip when CPAN::Audit is absent' => sub {
	require Test::CPAN::Health::Check::SecurityAdvisories;
	require Test::CPAN::Health::Distribution;

	my $good    = _make_good_dist();
	my $dist    = Test::CPAN::Health::Distribution->new(path => $good);

	my $restore = _block_module('CPAN::Audit', 'CPAN::Audit::Query');

	my $check  = Test::CPAN::Health::Check::SecurityAdvisories->new;
	my $result = $check->run($dist, {});

	is($result->status, $STATUS{SKIP},
		'SecurityAdvisories: status is skip when CPAN::Audit absent');
	like($result->summary, qr/CPAN::Audit/,
		'SecurityAdvisories: skip summary mentions CPAN::Audit');

	$restore->();

	diag "SA skip summary: ${\$result->summary}" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 15. Optional dep -- Kwalitee skips without Module::CPANTS::Analyse
# ===========================================================================

subtest 'Kwalitee: skip when Module::CPANTS::Analyse is absent' => sub {
	require Test::CPAN::Health::Check::Kwalitee;
	require Test::CPAN::Health::Distribution;

	my $good    = _make_good_dist();
	my $dist    = Test::CPAN::Health::Distribution->new(path => $good);

	my $restore = _block_module('Module::CPANTS::Analyse');

	my $check  = Test::CPAN::Health::Check::Kwalitee->new;
	my $result = $check->run($dist);

	is($result->status, $STATUS{SKIP},
		'Kwalitee: status is skip when Module::CPANTS::Analyse absent');
	like($result->summary, qr/Module::CPANTS::Analyse/,
		'Kwalitee: skip summary mentions Module::CPANTS::Analyse');

	$restore->();

	diag "Kwalitee skip summary: ${\$result->summary}" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 16. Distribution META file preference: META.json > META.yml > MYMETA.json
# ===========================================================================

subtest 'Distribution META preference: JSON > YML > MYMETA' => sub {
	require Test::CPAN::Health::Distribution;
	require Test::CPAN::Health::Check::MetaJSON;

	# --- META.yml only: MetaJSON warns at score 70 ---
	my $yml_dist = Test::CPAN::Health::Distribution->new(path => _make_yml_only_dist());

	is($yml_dist->name,    'Test-YmlOnly', 'name read from META.yml');
	is($yml_dist->version, '2.0.0',        'version read from META.yml');
	ok(!defined $yml_dist->file_path('META.json'), 'META.json absent in yml-only dist');

	my $yml_r = Test::CPAN::Health::Check::MetaJSON->new->run($yml_dist);
	is($yml_r->status, $STATUS{WARN}, 'MetaJSON warns for yml-only dist');
	is($yml_r->score,  $SCORE_META_YML, "MetaJSON scores $SCORE_META_YML for META.yml");

	# --- MYMETA.json only: MetaJSON warns at score 50 ---
	my $my_dist = Test::CPAN::Health::Distribution->new(path => _make_mymeta_dist());
	is($my_dist->name, 'Test-MyMeta', 'name read from MYMETA.json');

	my $my_r = Test::CPAN::Health::Check::MetaJSON->new->run($my_dist);
	is($my_r->status, $STATUS{WARN},    'MetaJSON warns for mymeta-only dist');
	is($my_r->score,  $SCORE_MYMETA,   "MetaJSON scores $SCORE_MYMETA for MYMETA.json");

	# --- Both META.json and META.yml: JSON wins ---
	my $both_dist = Test::CPAN::Health::Distribution->new(path => _make_both_meta_dist());

	# Distribution->meta resolves META.json first; name must come from that file.
	is($both_dist->name,    'Test-Both', 'name from META.json (not META.yml Test-YmlOnly)');
	is($both_dist->version, '4.0.0',     'version from META.json (not META.yml 2.0.0)');

	my $both_r = Test::CPAN::Health::Check::MetaJSON->new->run($both_dist);
	is($both_r->status, $STATUS{PASS}, 'MetaJSON passes when META.json present');
	is($both_r->score,  100,           'MetaJSON scores 100 for complete META.json');

	diag sprintf('META preference: yml=%d mymeta=%d both=%d',
		$yml_r->score, $my_r->score, $both_r->score) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 17. JSON reporter round-trip: decoded output matches report.as_hash
# ===========================================================================

subtest 'JSON reporter round-trip: decoded JSON matches report.as_hash' => sub {
	require Test::CPAN::Health::Reporter::JSON;

	my $report = _build_report(
		{ check_id => 'sem_ver',   status => 'pass', score => 100, summary => 'v1.2.3 OK',  weight => 3 },
		{ check_id => 'meta_json', status => 'warn', score =>  70, summary => 'YAML only',  weight => 5 },
		{ check_id => 'license',   status => 'fail', score =>   0, summary => 'No LICENSE', weight => 4 },
	);

	# --- Compact (non-pretty) output ---
	my $reporter = Test::CPAN::Health::Reporter::JSON->new;
	my $json_str;
	lives_ok { $json_str = $reporter->render($report) } 'JSON reporter renders without error';

	ok(defined $json_str && length $json_str > 0, 'JSON output is non-empty');

	my $decoded;
	lives_ok { $decoded = decode_json($json_str) } 'output is valid JSON';

	my $expected = $report->as_hash;
	is($decoded->{overall_score}, $expected->{overall_score}, 'overall_score matches');
	is($decoded->{pass},  $expected->{pass},  'pass count matches');
	is($decoded->{warn},  $expected->{warn},  'warn count matches');
	is($decoded->{fail},  $expected->{fail},  'fail count matches');
	is(scalar @{$decoded->{results}}, scalar @{$expected->{results}}, 'result count matches');

	# --- Pretty output: same data, different whitespace ---
	my $pretty_str    = Test::CPAN::Health::Reporter::JSON->new(pretty => 1)->render($report);
	my $pretty_data   = decode_json($pretty_str);
	is($pretty_data->{overall_score}, $decoded->{overall_score},
		'pretty JSON has same overall_score as compact JSON');

	diag "Compact JSON (first 120 chars): " . substr($json_str, 0, 120)
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 18. Reporter concurrency: two instances of same type produce identical output
# ===========================================================================

subtest 'Reporter concurrency: two reporters of same type produce identical output' => sub {
	# This verifies that reporters are stateless: parallel instances must not
	# accumulate or share state between render() calls.
	my $report = _build_report(
		{ check_id => 'sem_ver',   status => 'pass', score => 100, summary => 'OK',      weight => 3 },
		{ check_id => 'meta_json', status => 'fail', score =>   0, summary => 'No META', weight => 5 },
	);

	# TAP reporters
	require Test::CPAN::Health::Reporter::TAP;
	my $tap1 = Test::CPAN::Health::Reporter::TAP->new;
	my $tap2 = Test::CPAN::Health::Reporter::TAP->new;
	my ($t1, $t2);
	lives_ok { $t1 = $tap1->render($report) } 'TAP reporter 1 renders OK';
	lives_ok { $t2 = $tap2->render($report) } 'TAP reporter 2 renders OK';
	is($t1, $t2, 'both TAP reporters produce identical output');

	# JSON reporters
	require Test::CPAN::Health::Reporter::JSON;
	my $j1 = Test::CPAN::Health::Reporter::JSON->new(canonical => 1);
	my $j2 = Test::CPAN::Health::Reporter::JSON->new(canonical => 1);
	is($j1->render($report), $j2->render($report),
		'both JSON reporters produce identical output');

	diag "TAP output:\n$t1" if $ENV{TEST_VERBOSE};
};

done_testing;
