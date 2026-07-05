use strict;
use warnings;

use Test::Exception;
use Test::More;

use Test::CPAN::Health::Reporter::Markdown;
use Test::CPAN::Health::Report;
use Test::CPAN::Health::Result;

# ---------------------------------------------------------------------------
# 1. Constructor and class identity
# ---------------------------------------------------------------------------

my $reporter = Test::CPAN::Health::Reporter::Markdown->new;
isa_ok( $reporter, 'Test::CPAN::Health::Reporter::Markdown', 'new returns correct class' );

# ---------------------------------------------------------------------------
# Helper: build a Result with named parameters
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

# ---------------------------------------------------------------------------
# Build a minimal two-result report (one pass, one fail with details)
# ---------------------------------------------------------------------------

my $report = Test::CPAN::Health::Report->new;
$report->add_result( make_result(
	check_id => 'sem_ver',
	status   => 'pass',
	score    => 100,
	summary  => '1.2.3 is a valid semver',
	name     => 'Semantic Version',
) );
$report->add_result( make_result(
	check_id => 'meta_json',
	status   => 'fail',
	score    => 0,
	summary  => 'No META.json found',
	name     => 'META.json',
	details  => [ 'Add META.json to distribution root' ],
) );

my $md = $reporter->render($report);

# ---------------------------------------------------------------------------
# 2. render() croaks on non-Report argument
# ---------------------------------------------------------------------------

throws_ok(
	sub { $reporter->render('not a report') },
	qr/report must be/,
	'render() croaks on non-Report argument',
);

# ---------------------------------------------------------------------------
# 3. Header present
# ---------------------------------------------------------------------------

like( $md, qr/[#][#] CPAN Health/, 'output contains ## CPAN Health header' );

# ---------------------------------------------------------------------------
# 4. Overall score present
# ---------------------------------------------------------------------------

like( $md, qr/\d+\/100/, 'output contains overall score' );

# ---------------------------------------------------------------------------
# 5. Markdown table header row present
# ---------------------------------------------------------------------------

like( $md, qr/[|] Status [|]/, 'output contains Markdown table header row' );

# ---------------------------------------------------------------------------
# 6. Pass result renders with pass emoji
# ---------------------------------------------------------------------------

my $glyph_pass = "\x{2705}";
like( $md, qr/\Q$glyph_pass\E/, 'pass result renders with pass emoji' );

# ---------------------------------------------------------------------------
# 7. Fail result renders with fail emoji; details appear in collapsible block
# ---------------------------------------------------------------------------

my $glyph_fail = "\x{2717}";
like( $md, qr/\Q$glyph_fail\E/,                    'fail result renders with fail emoji' );
like( $md, qr/<details>/,                          'collapsible block present for fail result' );
like( $md, qr/Add META\.json to distribution root/, 'detail line present in collapsible block' );

# ---------------------------------------------------------------------------
# 8. Summary counts line present
# ---------------------------------------------------------------------------

like( $md, qr/Passed:.*Warned:.*Failed:.*Skipped:/s, 'summary counts line present' );

# ---------------------------------------------------------------------------
# 9. Badge URL comment present
# ---------------------------------------------------------------------------

like( $md, qr/<!-- badge:.*shields\.io/s, 'shields.io badge URL comment present' );

# ---------------------------------------------------------------------------
# Additional: pass result has no collapsible block (no details)
# ---------------------------------------------------------------------------

unlike( $md, qr/<summary>\S+\s+Semantic Version details/, 'no collapsible block for pass result' );

# ---------------------------------------------------------------------------
# Additional: skip result renders with skip glyph and dash score
# ---------------------------------------------------------------------------

my $skip_report = Test::CPAN::Health::Report->new;
$skip_report->add_result( make_result(
	check_id => 'ci_config',
	status   => 'skip',
	name     => 'CI Config',
	summary  => 'No CI config required',
) );

my $skip_md = $reporter->render($skip_report);
my $glyph_skip = "\x{2014}";
like( $skip_md, qr/\Q$glyph_skip\E/, 'skip result renders with em-dash glyph' );

# ---------------------------------------------------------------------------
# Additional: Markdown special characters in summary are escaped
# ---------------------------------------------------------------------------

my $esc_report = Test::CPAN::Health::Report->new;
$esc_report->add_result( make_result(
	check_id => 'sem_ver',
	status   => 'pass',
	score    => 100,
	summary  => 'pipe|and\\backslash',
	name     => 'Escape Test',
) );

my $esc_md = $reporter->render($esc_report);
like( $esc_md, qr/pipe\\[|]and\\\\backslash/, 'pipe and backslash escaped in table cell' );

done_testing;
