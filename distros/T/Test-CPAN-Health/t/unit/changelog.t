use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Changelog;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Changelog->new;
isa_ok($check, 'Test::CPAN::Health::Check::Changelog');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'changelog', 'id');
is($check->name,     'Changelog', 'name');
is($check->weight,   3,           'weight');
is($check->category, 'packaging', 'category');

# ---------------------------------------------------------------------------
# Helper: create a minimal Distribution from a temp dir
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

sub write_file {
	my ($dir, $name, $content) = @_;
	open my $fh, '>', File::Spec->catfile($dir, $name) or die $!;
	print {$fh} $content;
	close $fh;
	return;
}

sub write_meta {
	my ($dir, $version) = @_;
	$version //= '1.00';
	write_file($dir, 'META.json', <<"JSON");
{
   "abstract"    : "Test dist",
   "author"      : ["A. Uthor <a\@example.com>"],
   "license"     : ["perl_5"],
   "meta-spec"   : { "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec", "version" : 2 },
   "name"        : "Test-Dist",
   "version"     : "$version",
   "prereqs"     : {},
   "dynamic_config" : 0
}
JSON
	return;
}

# ---------------------------------------------------------------------------
# No changelog file -> fail, score 0
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'fail', 'no changelog -> fail');
	is($result->score,  0,      'no changelog -> score 0');
	like($result->summary, qr/No changelog/, 'summary mentions missing file');
	ok(scalar @{ $result->details } > 0, 'details suggest creating Changes');
}

# ---------------------------------------------------------------------------
# Empty changelog -> fail, score 10
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file($dist->path, 'Changes', '');

	my $result = $check->run($dist);
	is($result->status, 'fail',  'empty changelog -> fail');
	is($result->score,  10,      'empty changelog -> score 10');
	like($result->summary, qr/empty/, 'summary mentions empty');
}

# Whitespace-only file is also "empty"
{
	my $dist = make_dist();
	write_file($dist->path, 'Changes', "   \n\t\n");

	my $result = $check->run($dist);
	is($result->status, 'fail', 'whitespace-only changelog -> fail');
}

# ---------------------------------------------------------------------------
# Changelog with content but no META version -> pass (version not determinable)
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file($dist->path, 'Changes', "0.01  2026-07-03\n  - Initial release\n");
	# No META file so version() returns undef

	my $result = $check->run($dist);
	is($result->status, 'pass', 'changelog with content, no version -> pass');
	is($result->score,  100,    'changelog with content, no version -> score 100');
	like($result->summary, qr/not determinable/, 'summary notes version unknown');
}

# ---------------------------------------------------------------------------
# Changelog found but no entry for current version -> warn, score 50
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_meta($dist->path, '1.00');
	write_file($dist->path, 'Changes',
		"0.09  2026-01-01\n  - Previous release\n\n" .
		"0.08  2025-06-01\n  - Even older\n");

	my $result = $check->run($dist);
	is($result->status, 'warn', 'changelog missing version entry -> warn');
	is($result->score,  50,     'changelog missing version entry -> score 50');
	like($result->summary, qr/1\.00/, 'summary includes version');
}

# ---------------------------------------------------------------------------
# Changelog with CPAN-standard entry for current version -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_meta($dist->path, '1.00');
	write_file($dist->path, 'Changes',
		"1.00  2026-07-03\n  - Release\n\n0.09  2026-01-01\n  - Old\n");

	my $result = $check->run($dist);
	is($result->status, 'pass', 'changelog with version entry -> pass');
	is($result->score,  100,    'changelog with version entry -> score 100');
	like($result->summary, qr/1\.00/, 'summary includes version');
}

# Keep a Changelog style: ## [1.00] - 2026-07-03
{
	my $dist = make_dist();
	write_meta($dist->path, '1.00');
	write_file($dist->path, 'CHANGELOG.md',
		"## [1.00] - 2026-07-03\n### Added\n- Release\n");

	my $result = $check->run($dist);
	is($result->status, 'pass', 'keepachangelog format -> pass');
}

# "version 1.00" prose style
{
	my $dist = make_dist();
	write_meta($dist->path, '1.00');
	write_file($dist->path, 'Changes',
		"version 1.00 released 2026-07-03\n  - Release\n");

	my $result = $check->run($dist);
	is($result->status, 'pass', 'prose version style -> pass');
}

# ---------------------------------------------------------------------------
# Changelog is CHANGELOG.md and NEWS -- alternative names recognised
# ---------------------------------------------------------------------------

for my $name (qw(Changelog CHANGES ChangeLog NEWS)) {
	my $dist = make_dist();
	write_file($dist->path, $name, "1.00  2026-07-03\n  - Test\n");
	write_meta($dist->path, '1.00');

	my $result = $check->run($dist);
	is($result->status, 'pass', "changelog name '$name' is recognised");
}

# ---------------------------------------------------------------------------
# run() croaks on wrong argument type
# ---------------------------------------------------------------------------

throws_ok(
	sub { $check->run('not a dist') },
	qr/must be a Test::CPAN::Health::Distribution/,
	'run() croaks on non-Distribution argument',
);

# ---------------------------------------------------------------------------
# Result is a proper Result object
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'changelog', 'result carries correct check_id');
}

done_testing;
