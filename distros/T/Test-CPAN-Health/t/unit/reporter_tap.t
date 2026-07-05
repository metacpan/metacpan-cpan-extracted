use strict;
use warnings;

use Test::Exception;
use Test::More;

use Test::CPAN::Health::Reporter::TAP;
use Test::CPAN::Health::Report;
use Test::CPAN::Health::Result;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

my $reporter = Test::CPAN::Health::Reporter::TAP->new;
isa_ok($reporter, 'Test::CPAN::Health::Reporter::TAP');

# ---------------------------------------------------------------------------
# Build a minimal report with pass / fail / skip / warn results
# ---------------------------------------------------------------------------

sub make_result {
	my (%args) = @_;
	return Test::CPAN::Health::Result->new(
		check_id => $args{check_id} // 'test_check',
		status   => $args{status}   // 'pass',
		score    => $args{score},
		summary  => $args{summary}  // 'ok',
		details  => $args{details}  // [],
		data     => { name => $args{name} // 'Test Check' },
	);
}

my $report = Test::CPAN::Health::Report->new;
$report->add_result(make_result(
	check_id => 'sem_ver',
	status   => 'pass',
	score    => 100,
	summary  => '1.2.3 is a valid semver',
	name     => 'Semantic Version',
));
$report->add_result(make_result(
	check_id => 'meta_json',
	status   => 'fail',
	score    => 0,
	summary  => 'No META.json found',
	name     => 'META.json',
	details  => ['Add META.json to your distribution'],
));
$report->add_result(make_result(
	check_id => 'ci_config',
	status   => 'skip',
	summary  => 'No CI directory found',
	name     => 'CI Config',
));

# ---------------------------------------------------------------------------
# TAP plan and basic structure
# ---------------------------------------------------------------------------

my $tap = $reporter->render($report);

like($tap, qr/\A1\.\.3\n/, 'TAP document starts with plan 1..3');

# Results are sorted by check_id: ci_config, meta_json, sem_ver
like($tap, qr/ok 1 # SKIP CI Config: No CI directory found/, 'skip -> ok # SKIP');
like($tap, qr/not ok 2 - META\.json: No META\.json found/,   'fail -> not ok');
like($tap, qr/ok 3 - Semantic Version: 1\.2\.3/,              'pass -> ok');

# ---------------------------------------------------------------------------
# Detail lines become TAP diagnostics
# ---------------------------------------------------------------------------

like($tap, qr/# Add META\.json/, 'detail line becomes # diagnostic');

# ---------------------------------------------------------------------------
# Trailing diagnostics: score and counts
# ---------------------------------------------------------------------------

like($tap, qr/# Overall score: \d+\/100/, 'overall score in trailing diagnostics');
like($tap, qr/# Passed: 1  Warned: 0  Failed: 1  Skipped: 1/,
	'status counts in trailing diagnostics');

# ---------------------------------------------------------------------------
# warn status maps to ok ... # WARN
# ---------------------------------------------------------------------------

my $warn_report = Test::CPAN::Health::Report->new;
$warn_report->add_result(make_result(
	check_id => 'stale_deps',
	status   => 'warn',
	score    => 70,
	summary  => '1 of 5 deps may be stale',
	name     => 'Stale Dependencies',
));

my $warn_tap = $reporter->render($warn_report);
like($warn_tap, qr/ok 1 - Stale Dependencies.*# WARN/, 'warn -> ok ... # WARN');

# ---------------------------------------------------------------------------
# Hash characters in summaries are replaced (TAP parser safety)
# ---------------------------------------------------------------------------

my $hash_report = Test::CPAN::Health::Report->new;
$hash_report->add_result(make_result(
	check_id => 'check_a',
	status   => 'pass',
	summary  => 'found #3 issue',
	name     => 'Check A',
));

my $hash_tap = $reporter->render($hash_report);
unlike($hash_tap, qr/ok 1 - Check A: found #3/, 'bare # removed from description');
like($hash_tap,   qr/ok 1 - Check A: found \[#\]3/, 'bare # replaced with [#]');

# ---------------------------------------------------------------------------
# render() croaks on non-Report argument
# ---------------------------------------------------------------------------

throws_ok(
	sub { $reporter->render('not a report') },
	qr/report must be/,
	'render() croaks on non-Report argument',
);

# ---------------------------------------------------------------------------
# Output ends with a newline
# ---------------------------------------------------------------------------

my $simple_report = Test::CPAN::Health::Report->new;
$simple_report->add_result(make_result(status => 'pass', score => 100));
my $out = $reporter->render($simple_report);
like($out, qr/\n\z/, 'output ends with a newline');

done_testing;
