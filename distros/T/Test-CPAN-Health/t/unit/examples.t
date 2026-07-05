use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Examples;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Examples->new;
isa_ok($check, 'Test::CPAN::Health::Check::Examples');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'examples', 'id');
is($check->name,     'Examples', 'name');
is($check->weight,   2,          'weight');
is($check->category, 'quality',  'category');

# ---------------------------------------------------------------------------
# Helper: build a real Distribution from a temp dir
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

# ---------------------------------------------------------------------------
# No examples directory -> fail, score 0
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'fail', 'no examples dir -> fail');
	is($result->score,  0,      'no examples dir -> score 0');
	like($result->summary, qr/No examples directory/, 'summary mentions missing dir');
}

# ---------------------------------------------------------------------------
# examples/ directory exists but is empty -> warn, score 50
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	make_path(File::Spec->catdir($dist->path, 'examples'));

	my $result = $check->run($dist);
	is($result->status, 'warn', 'empty examples/ -> warn');
	is($result->score,  50,     'empty examples/ -> score 50');
	like($result->summary, qr/empty/, 'summary mentions empty');
}

# ---------------------------------------------------------------------------
# examples/ with a file -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist     = make_dist();
	my $eg_dir   = File::Spec->catdir($dist->path, 'examples');
	make_path($eg_dir);
	open my $fh, '>', File::Spec->catfile($eg_dir, 'demo.pl') or die $!;
	print {$fh} "#!/usr/bin/env perl\nprint 'hello'\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'examples/ with file -> pass');
	is($result->score,  100,    'examples/ with file -> score 100');
	like($result->summary, qr/examples/, 'summary names the directory');
	is($result->data->{count}, 1, 'data count = 1');
}

# ---------------------------------------------------------------------------
# eg/ is also recognised
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $eg_dir = File::Spec->catdir($dist->path, 'eg');
	make_path($eg_dir);
	open my $fh, '>', File::Spec->catfile($eg_dir, 'sample.pl') or die $!;
	print {$fh} "1;\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'eg/ recognised -> pass');
	like($result->summary, qr/eg/, 'summary names eg/');
}

# ---------------------------------------------------------------------------
# example/ (singular) is also recognised
# ---------------------------------------------------------------------------

{
	my $dist     = make_dist();
	my $ex_dir   = File::Spec->catdir($dist->path, 'example');
	make_path($ex_dir);
	open my $fh, '>', File::Spec->catfile($ex_dir, 'foo.pl') or die $!;
	print {$fh} "1;\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'example/ recognised -> pass');
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
	is($result->check_id, 'examples', 'result carries correct check_id');
}

done_testing;
