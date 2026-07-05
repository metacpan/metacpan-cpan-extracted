use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::MetaJSON;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::MetaJSON->new;
isa_ok($check, 'Test::CPAN::Health::Check::MetaJSON');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'meta_json',  'id');
is($check->name,     'META.json',  'name');
is($check->weight,   5,            'weight');
is($check->category, 'packaging',  'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_file {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# Minimal valid META.json content (all required fields present).
my $FULL_META_JSON = <<'END';
{"abstract":"A test distribution","author":["Test Author"],"license":["perl_5"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0"}
END
chomp $FULL_META_JSON;

# META.json with abstract set to the CPAN placeholder value.
my $UNKNOWN_ABSTRACT_META_JSON = <<'END';
{"abstract":"unknown","author":["Test Author"],"license":["perl_5"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0"}
END
chomp $UNKNOWN_ABSTRACT_META_JSON;

# Minimal META.yml (v1.4 -- CPAN::Meta::YAML format).
my $FULL_META_YML = <<'END';
---
name: Test-Dist
version: '1.0.0'
abstract: A test distribution
author:
  - Test Author
license: perl_5
meta-spec:
  version: '1.4'
  url: 'http://module-build.sourceforge.net/META-spec-v1.4.html'
END

# ---------------------------------------------------------------------------
# No META file at all -> fail, score 0
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'fail', 'no META -> fail');
	is($result->score,  0,      'no META -> score 0');
	like($result->summary, qr/META/, 'summary mentions META');
}

# ---------------------------------------------------------------------------
# META.json with all required fields -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $FULL_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'full META.json -> pass');
	is($result->score,  100,    'full META.json -> score 100');
	like($result->summary, qr/META\.json/i, 'summary mentions META.json');
	is($result->data->{has_json}, 1, 'data reports has_json = 1');
}

# ---------------------------------------------------------------------------
# META.json with abstract = 'unknown' -> warn, score 40 (json incomplete)
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $UNKNOWN_ABSTRACT_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'warn',   'abstract=unknown -> warn');
	is($result->score,  40,       'abstract=unknown -> score 40');
	like($result->summary, qr/abstract/i, 'summary names missing field');
}

# ---------------------------------------------------------------------------
# META.yml only (no META.json) -> warn, score 70
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.yml'), $FULL_META_YML);

	my $result = $check->run($dist);
	is($result->status, 'warn', 'META.yml only -> warn');
	is($result->score,  70,     'META.yml only -> score 70');
	like($result->summary, qr/META\.yml/i, 'summary mentions META.yml');
	is($result->data->{has_json}, 0, 'data reports has_json = 0');
}

# ---------------------------------------------------------------------------
# MYMETA.json only (no canonical META) -> warn, score 50
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'MYMETA.json'), $FULL_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'warn',   'MYMETA.json only -> warn');
	is($result->score,  50,       'MYMETA.json only -> score 50');
	like($result->summary, qr/MYMETA/i, 'summary mentions MYMETA');
}

# ---------------------------------------------------------------------------
# MYMETA.json wins over MYMETA.yml when both present
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'MYMETA.json'), $FULL_META_JSON);
	write_file(File::Spec->catfile($tmp, 'MYMETA.yml'),  $FULL_META_YML);

	my $result = $check->run($dist);
	is($result->status, 'warn', 'MYMETA.json+MYMETA.yml -> warn (no canonical)');
	like($result->summary, qr/MYMETA\.json/i, 'MYMETA.json preferred over MYMETA.yml');
}

# ---------------------------------------------------------------------------
# MYMETA.json with missing fields -> warn, score 15
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'MYMETA.json'), $UNKNOWN_ABSTRACT_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'warn', 'MYMETA incomplete -> warn');
	is($result->score,  15,     'MYMETA incomplete -> score 15');
}

# ---------------------------------------------------------------------------
# Canonical META.json beats MYMETA when both present
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'),   $FULL_META_JSON);
	write_file(File::Spec->catfile($tmp, 'MYMETA.json'), $UNKNOWN_ABSTRACT_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'META.json beats MYMETA.json');
	is($result->score,  100,    'META.json gives full score even with MYMETA present');
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
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'meta_json', 'result carries correct check_id');
}

done_testing;
