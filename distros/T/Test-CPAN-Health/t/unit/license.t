use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::License;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::License->new;
isa_ok($check, 'Test::CPAN::Health::Check::License');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'license',    'id');
is($check->name,     'License',    'name');
is($check->weight,   4,            'weight');
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

# META.json with a specific (non-vague) licence.
my $GOOD_META_JSON = <<'END';
{"abstract":"test","author":["Test Author"],"license":["perl_5"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0"}
END
chomp $GOOD_META_JSON;

# META.json with the 'unknown' placeholder licence.
my $UNKNOWN_LICENSE_META_JSON = <<'END';
{"abstract":"test","author":["Test Author"],"license":["unknown"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0"}
END
chomp $UNKNOWN_LICENSE_META_JSON;

my $LICENSE_TEXT = "This software is free.\n";

# ---------------------------------------------------------------------------
# No META file -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'skip', 'no META -> skip');
	like($result->summary, qr/No META/i, 'summary explains skip reason');
}

# ---------------------------------------------------------------------------
# META with vague licence ("unknown") -> fail, score 0
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $UNKNOWN_LICENSE_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'fail', '"unknown" licence -> fail');
	is($result->score,  0,      '"unknown" licence -> score 0');
	like($result->summary, qr/unknown/i, 'summary names the vague identifier');
}

# ---------------------------------------------------------------------------
# Specific licence declared but no licence file -> warn, score 50
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $GOOD_META_JSON);

	my $result = $check->run($dist);
	is($result->status, 'warn', 'licence declared, no file -> warn');
	is($result->score,  50,     'licence declared, no file -> score 50');
	like($result->summary, qr/no licence file/i, 'summary mentions missing file');
}

# ---------------------------------------------------------------------------
# Specific licence declared + LICENSE file present -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $GOOD_META_JSON);
	write_file(File::Spec->catfile($tmp, 'LICENSE'), $LICENSE_TEXT);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'perl_5 + LICENSE -> pass');
	is($result->score,  100,    'perl_5 + LICENSE -> score 100');
	like($result->summary, qr/perl_5/, 'summary names the licence');
	is($result->data->{file}, 'LICENSE', 'data records file name');
}

# ---------------------------------------------------------------------------
# LICENCE file (British spelling) is also recognised -> pass
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $GOOD_META_JSON);
	write_file(File::Spec->catfile($tmp, 'LICENCE'), $LICENSE_TEXT);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'LICENCE (British) -> pass');
	is($result->score,  100,    'LICENCE (British) -> score 100');
	is($result->data->{file}, 'LICENCE', 'data records LICENCE file name');
}

# ---------------------------------------------------------------------------
# COPYING file is also recognised -> pass
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $GOOD_META_JSON);
	write_file(File::Spec->catfile($tmp, 'COPYING'), $LICENSE_TEXT);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'COPYING -> pass');
	is($result->data->{file}, 'COPYING', 'data records COPYING file name');
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
	is($result->check_id, 'license', 'result carries correct check_id');
}

done_testing;
