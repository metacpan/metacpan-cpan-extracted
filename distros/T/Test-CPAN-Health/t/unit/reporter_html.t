use strict;
use warnings;

use Test::Exception;
use Test::More;

use Test::CPAN::Health::Reporter::HTML;
use Test::CPAN::Health::Report;
use Test::CPAN::Health::Result;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

my $reporter = Test::CPAN::Health::Reporter::HTML->new;
isa_ok($reporter, 'Test::CPAN::Health::Reporter::HTML');

my $titled = Test::CPAN::Health::Reporter::HTML->new(title => 'My Dist Health');
isa_ok($titled, 'Test::CPAN::Health::Reporter::HTML');

# ---------------------------------------------------------------------------
# Build a report with pass / fail results and details
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
	details  => ['Add META.json to distribution root'],
));

# ---------------------------------------------------------------------------
# Basic HTML structure
# ---------------------------------------------------------------------------

my $html = $reporter->render($report);

like($html, qr/<!DOCTYPE html>/i,          'output begins with DOCTYPE');
like($html, qr/<html\b/i,                  'contains <html> tag');
like($html, qr/<\/html>/i,                 'ends with </html>');
like($html, qr/charset=.UTF-8/i,           'declares UTF-8 charset');
like($html, qr/<title>.*CPAN Health/i,     'default title contains CPAN Health');
like($html, qr/<\/body>/i,                 'contains closing </body>');

# ---------------------------------------------------------------------------
# Custom title
# ---------------------------------------------------------------------------

my $html_titled = $titled->render($report);
like($html_titled, qr/<title>My Dist Health<\/title>/, 'custom title rendered');

# ---------------------------------------------------------------------------
# Score and summary
# ---------------------------------------------------------------------------

like($html, qr/\d+\/100/, 'overall score present');
like($html, qr/Passed.*Warned.*Failed.*Skipped/s, 'status summary present');

# ---------------------------------------------------------------------------
# Check names and summaries present
# ---------------------------------------------------------------------------

like($html, qr/Semantic Version/, 'pass check name present');
like($html, qr/1\.2\.3 is a valid semver/, 'pass check summary present');
like($html, qr/META\.json/, 'fail check name present');
like($html, qr/No META\.json found/, 'fail check summary present');

# ---------------------------------------------------------------------------
# Detail lines present
# ---------------------------------------------------------------------------

like($html, qr/Add META\.json to distribution root/, 'detail line rendered');

# ---------------------------------------------------------------------------
# HTML escaping (XSS prevention)
# ---------------------------------------------------------------------------

my $xss_report = Test::CPAN::Health::Report->new;
$xss_report->add_result(make_result(
	check_id => 'sem_ver',
	status   => 'fail',
	score    => 0,
	summary  => '<script>alert(1)</script>',
	name     => '<b>Inject</b>',
	details  => ['<img src=x onerror=alert(1)>'],
));

my $xss_html = $reporter->render($xss_report);
unlike($xss_html, qr/<script>alert/,    'raw <script> tag not present (escaped)');
unlike($xss_html, qr/<b>Inject<\/b>/,  'raw <b> tag not present (escaped)');
unlike($xss_html, qr/<img src=x/,      'raw <img> in detail not present (escaped)');
like($xss_html,   qr/&lt;script&gt;/,  'script tag HTML-escaped');
like($xss_html,   qr/&lt;b&gt;/,       'name HTML-escaped');

# ---------------------------------------------------------------------------
# render() croaks on non-Report argument
# ---------------------------------------------------------------------------

throws_ok(
	sub { $reporter->render('not a report') },
	qr/report must be/,
	'render() croaks on non-Report argument',
);

done_testing;
