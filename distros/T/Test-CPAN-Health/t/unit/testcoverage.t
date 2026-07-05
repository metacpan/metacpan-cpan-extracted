use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::TestCoverage;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::TestCoverage->new;
isa_ok($check, 'Test::CPAN::Health::Check::TestCoverage');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'test_coverage', 'id');
is($check->name,     'Test Coverage', 'name');
is($check->weight,   7,               'weight');
is($check->category, 'ci',            'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_file {
	my ($path, $content) = @_;
	make_path(dirname($path));
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# ---------------------------------------------------------------------------
# Skip when no_cover flag is set (no Devel::Cover needed for this test)
# ---------------------------------------------------------------------------

{
	my $no_cover_check = Test::CPAN::Health::Check::TestCoverage->new(no_cover => 1);
	my (undef, $dist) = make_dist();
	my $result = $no_cover_check->run($dist);
	is($result->status, 'skip', 'no_cover => 1 -> skip');
	like($result->summary, qr/no.cover/i, 'summary mentions no-cover');
}

# ---------------------------------------------------------------------------
# Everything below requires Devel::Cover to get past the first guard.
# ---------------------------------------------------------------------------

my $have_devel_cover = eval { require Devel::Cover; 1 };

SKIP: {
	skip 'Devel::Cover not installed', 6 unless $have_devel_cover;

	# Skip when no t/ files
	{
		my ($tmp, $dist) = make_dist();
		write_file(File::Spec->catfile($tmp, 'Makefile.PL'), "use ExtUtils::MakeMaker;\n");

		my $result = $check->run($dist);
		is($result->status, 'skip', 'no t/ files -> skip');
		like($result->summary, qr/no test files/i, 'summary mentions missing tests');
	}

	# Skip when no Makefile.PL or Build.PL
	{
		my ($tmp, $dist) = make_dist();
		write_file(
			File::Spec->catfile($tmp, 't', 'basic.t'),
			"use Test::More; pass('ok'); done_testing;\n",
		);

		my $result = $check->run($dist);
		is($result->status, 'skip', 'no build file -> skip');
		like($result->summary, qr/Makefile\.PL|Build\.PL/i, 'summary mentions missing build file');
	}

	# Skip when cover binary not found (simulate by temporarily patching PATH)
	{
		my ($tmp, $dist) = make_dist();
		write_file(File::Spec->catfile($tmp, 't', 'basic.t'), "use Test::More; done_testing;\n");
		write_file(File::Spec->catfile($tmp, 'Makefile.PL'), "use ExtUtils::MakeMaker;\n");

		local $ENV{PATH} = '';    # hide all binaries including cover
		# Also zero out the Config dirs by testing _find_cover_bin directly
		my $bin = Test::CPAN::Health::Check::TestCoverage::_find_cover_bin();

		SKIP: {
			skip 'cover still found despite empty PATH', 2 if defined $bin;
			my $result = $check->run($dist);
			is($result->status, 'skip', 'cover not in PATH -> skip');
			like($result->summary, qr/cover binary not found/i, 'summary mentions missing binary');
		}
	}
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
# Result object via the no_cover fast path
# ---------------------------------------------------------------------------

{
	my $c = Test::CPAN::Health::Check::TestCoverage->new(no_cover => 1);
	my (undef, $dist) = make_dist();
	my $result = $c->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'test_coverage', 'result carries correct check_id');
}

done_testing;
