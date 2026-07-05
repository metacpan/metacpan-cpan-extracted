use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Benchmarks;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Benchmarks->new;
isa_ok($check, 'Test::CPAN::Health::Check::Benchmarks');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'benchmarks', 'id');
is($check->name,     'Benchmarks', 'name');
is($check->weight,   1,            'weight');
is($check->category, 'quality',    'category');

# ---------------------------------------------------------------------------
# Helper: build a real Distribution from a temp dir
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

# ---------------------------------------------------------------------------
# No benchmarks directory -> fail, score 0
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'fail', 'no bench dir -> fail');
	is($result->score,  0,      'no bench dir -> score 0');
	like($result->summary, qr/No benchmarks directory/, 'summary mentions missing dir');
}

# ---------------------------------------------------------------------------
# benchmarks/ directory exists but is empty -> warn, score 50
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	make_path(File::Spec->catdir($dist->path, 'benchmarks'));

	my $result = $check->run($dist);
	is($result->status, 'warn', 'empty benchmarks/ -> warn');
	is($result->score,  50,     'empty benchmarks/ -> score 50');
	like($result->summary, qr/empty/, 'summary mentions empty');
}

# ---------------------------------------------------------------------------
# benchmarks/ with a file -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist      = make_dist();
	my $bench_dir = File::Spec->catdir($dist->path, 'benchmarks');
	make_path($bench_dir);
	open my $fh, '>', File::Spec->catfile($bench_dir, 'bench_foo.pl') or die $!;
	print {$fh} "use Benchmark;\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'benchmarks/ with file -> pass');
	is($result->score,  100,    'benchmarks/ with file -> score 100');
	is($result->data->{count}, 1, 'data count = 1');
}

# ---------------------------------------------------------------------------
# bench/ (short form) is recognised
# ---------------------------------------------------------------------------

{
	my $dist  = make_dist();
	my $dir   = File::Spec->catdir($dist->path, 'bench');
	make_path($dir);
	open my $fh, '>', File::Spec->catfile($dir, 'bench.pl') or die $!;
	print {$fh} "1;\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'bench/ recognised -> pass');
	like($result->summary, qr/bench/, 'summary names bench/');
}

# ---------------------------------------------------------------------------
# benchmark/ (singular) is recognised
# ---------------------------------------------------------------------------

{
	my $dist  = make_dist();
	my $dir   = File::Spec->catdir($dist->path, 'benchmark');
	make_path($dir);
	open my $fh, '>', File::Spec->catfile($dir, 'b.pl') or die $!;
	print {$fh} "1;\n";
	close $fh;

	my $result = $check->run($dist);
	is($result->status, 'pass', 'benchmark/ recognised -> pass');
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
	is($result->check_id, 'benchmarks', 'result carries correct check_id');
}

done_testing;
