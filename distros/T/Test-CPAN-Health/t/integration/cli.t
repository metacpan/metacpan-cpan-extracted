use strict;
use warnings;

use File::Spec;
use JSON::MaybeXS qw(decode_json);
use Test::More;

# ---------------------------------------------------------------------------
# Locate the project root and CLI script
# ---------------------------------------------------------------------------

# When run under 'make test' cwd is the project root.
# When run as 'prove t/integration/cli.t' cwd is also the project root.
my $root = File::Spec->rel2abs('.');
my $script = File::Spec->catfile($root, 'scripts', 'cpan-health');

plan skip_all => "scripts/cpan-health not found at $script"
	unless -f $script;

# Use the lib/ directory so the tests work without a prior 'make'.
my $lib = File::Spec->catdir($root, 'lib');

# ---------------------------------------------------------------------------
# Helper: run the CLI, return (stdout, raw_wait_status)
# ---------------------------------------------------------------------------

sub run_cli {
	my @args = @_;
	my $out = '';
	if (open my $fh, '-|', $^X, "-I$lib", $script, @args) {
		local $/;
		$out = <$fh>;
		close $fh;
	}
	return ($out, $?);
}

# A fast baseline: run against the project itself with all slow checks off.
my @fast = ('--no-network', '--no-cover', $root);

# ---------------------------------------------------------------------------
# 1. Terminal format (default)
# ---------------------------------------------------------------------------

my ($term_out, $term_rc) = run_cli(@fast);
is($term_rc, 0, 'terminal: exits 0');
like($term_out, qr/Overall score: \d+\/100/, 'terminal: overall score line present');
like($term_out, qr/Passed: \d+  Warned: \d+  Failed: \d+  Skipped: \d+/,
	'terminal: status summary present');

# ---------------------------------------------------------------------------
# 2. JSON format
# ---------------------------------------------------------------------------

my ($json_out, $json_rc) = run_cli('--format=json', @fast);
is($json_rc, 0, 'json: exits 0');

my $data = eval { decode_json($json_out) };
is($@, '', 'json: output is valid JSON');
SKIP: {
	skip 'JSON parse failed', 5 if $@;
	ok(exists $data->{overall_score}, 'json: overall_score key present');
	ok(exists $data->{results},       'json: results key present');
	ok(ref($data->{results}) eq 'ARRAY', 'json: results is an array');
	ok($data->{overall_score} >= 0,   'json: score >= 0');
	ok($data->{overall_score} <= 100, 'json: score <= 100');
}

# ---------------------------------------------------------------------------
# 3. TAP format
# ---------------------------------------------------------------------------

my ($tap_out, $tap_rc) = run_cli('--format=tap', @fast);
is($tap_rc, 0, 'tap: exits 0');
like($tap_out, qr/\A1\.\.\d+\n/,            'tap: starts with plan line');
like($tap_out, qr/^(?:ok|not ok) \d+/m,     'tap: contains ok/not ok lines');
like($tap_out, qr/^# Overall score: \d+\/100/m, 'tap: score in diagnostics');

# ---------------------------------------------------------------------------
# 4. HTML format
# ---------------------------------------------------------------------------

my ($html_out, $html_rc) = run_cli('--format=html', @fast);
is($html_rc, 0, 'html: exits 0');
like($html_out, qr/<!DOCTYPE html>/i,  'html: starts with DOCTYPE');
like($html_out, qr/\d+\/100/,          'html: score present');
like($html_out, qr/<\/html>/i,         'html: ends with </html>');

# ---------------------------------------------------------------------------
# 5. --min-score exit code
# ---------------------------------------------------------------------------

my (undef, $low_rc)  = run_cli('--min-score=0',   @fast);
my (undef, $high_rc) = run_cli('--min-score=100',  @fast);
is($low_rc  >> 8, 0, '--min-score=0 exits 0 (always passes)');
is($high_rc >> 8, 1, '--min-score=100 exits 1 when score < 100');

# ---------------------------------------------------------------------------
# 6. --skip: named check is absent from results
# ---------------------------------------------------------------------------

my ($skip_out, $skip_rc) = run_cli('--skip=sem_ver', @fast);
is($skip_rc, 0, '--skip: exits 0');
unlike($skip_out, qr/Semantic Version/i,
	'--skip=sem_ver: SemVer check absent from output');

# Total checks run should be one fewer than with all checks
my ($full_out) = run_cli(@fast);
my ($full_count)  = ($full_out  =~ /Passed: (\d+)  Warned: (\d+)  Failed: (\d+)  Skipped: (\d+)/);
my $full_total = 0;
if ($full_out =~ /Passed: (\d+)  Warned: (\d+)  Failed: (\d+)  Skipped: (\d+)/) {
	$full_total = $1 + $2 + $3 + $4;
}
my $skip_total = 0;
if ($skip_out =~ /Passed: (\d+)  Warned: (\d+)  Failed: (\d+)  Skipped: (\d+)/) {
	$skip_total = $1 + $2 + $3 + $4;
}
is($skip_total, $full_total - 1,
	'--skip=sem_ver: one fewer check result than the full run');

# ---------------------------------------------------------------------------
# 7. --check: only the named check runs
# ---------------------------------------------------------------------------

my ($check_out, $check_rc) = run_cli('--check=perlcritic', @fast);
is($check_rc, 0, '--check: exits 0');
like($check_out, qr/Perl::Critic/i, '--check=perlcritic: Perlcritic result present');
my $check_total = 0;
if ($check_out =~ /Passed: (\d+)  Warned: (\d+)  Failed: (\d+)  Skipped: (\d+)/) {
	$check_total = $1 + $2 + $3 + $4;
}
is($check_total, 1, '--check=perlcritic: exactly one check result');

# ---------------------------------------------------------------------------
# 8. --output: writes to a file
# ---------------------------------------------------------------------------

SKIP: {
	require File::Temp;
	my $tmp = File::Temp->new(SUFFIX => '.json', UNLINK => 1);
	my $path = $tmp->filename;

	my (undef, $out_rc) = run_cli('--format=json', '--output', $path, @fast);
	is($out_rc, 0, '--output: exits 0');
	ok(-f $path && -s $path, '--output: file exists and is non-empty');
	my $content = do { local $/; open my $fh, '<', $path; <$fh> };
	my $parsed = eval { decode_json($content) };
	is($@, '', '--output: written file is valid JSON');
}

# ---------------------------------------------------------------------------
# 9. Invalid --format croaks (non-zero exit)
# ---------------------------------------------------------------------------

my (undef, $bad_fmt_rc) = run_cli('--format=badformat', $root);
isnt($bad_fmt_rc >> 8, 0, 'invalid --format causes non-zero exit');

# ---------------------------------------------------------------------------
# 10. Live network tests -- skipped only when NO_NETWORK_TESTING is set
# ---------------------------------------------------------------------------

SKIP: {
	skip q{Live network tests skipped (unset NO_NETWORK_TESTING to run)}, 5
		if $ENV{NO_NETWORK_TESTING};

	my ($net_out, $net_rc) = run_cli('--no-cover', $root);
	is($net_rc, 0, 'live: network run exits 0');
	like($net_out, qr/Overall score: \d+\/100/, 'live: overall score present');
	like($net_out, qr/CPAN Testers/i,           'live: CPAN Testers check present');
	like($net_out, qr/Reverse Dep/i,            'live: ReverseDeps check present');
	like($net_out, qr/Stale Dep/i,              'live: StaleDeps check present');
}

done_testing;
