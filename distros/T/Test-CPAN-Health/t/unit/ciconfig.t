use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::CIConfig;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::CIConfig->new;
isa_ok($check, 'Test::CPAN::Health::Check::CIConfig');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'ci_config',        'id');
is($check->name,     'CI Configuration', 'name');
is($check->weight,   4,                  'weight');
is($check->category, 'ci',               'category');

# ---------------------------------------------------------------------------
# Helper: build a real Distribution from a temp dir
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

sub write_file {
	my ($path, $content) = @_;
	make_path(dirname($path));
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
	return;
}

# ---------------------------------------------------------------------------
# No CI config at all -> fail, score 0
# ---------------------------------------------------------------------------

{
	my $dist   = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'fail', 'no CI config -> fail');
	is($result->score,  0,      'no CI config -> score 0');
	like($result->summary, qr/No CI configuration/, 'summary mentions absence');
}

# ---------------------------------------------------------------------------
# .travis.yml present -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, '.travis.yml'),
		"language: perl\nperl:\n  - '5.32'\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass',  '.travis.yml -> pass');
	is($result->score,  100,     '.travis.yml -> score 100');
	like($result->summary, qr/\.travis\.yml/, 'summary names the file');
}

# ---------------------------------------------------------------------------
# .appveyor.yml present -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, '.appveyor.yml'),
		"build: off\ntest_script:\n  - prove -l t\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass', '.appveyor.yml -> pass');
	is($result->score,  100,    '.appveyor.yml -> score 100');
}

# ---------------------------------------------------------------------------
# azure-pipelines.yml present -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, 'azure-pipelines.yml'),
		"trigger:\n  - master\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'azure-pipelines.yml -> pass');
	is($result->score,  100,    'azure-pipelines.yml -> score 100');
}

# ---------------------------------------------------------------------------
# .github/workflows/ci.yml -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, '.github', 'workflows', 'ci.yml'),
		"name: CI\non: [push]\njobs:\n  test:\n    runs-on: ubuntu-latest\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'GitHub Actions workflow -> pass');
	is($result->score,  100,    'GitHub Actions workflow -> score 100');
	like($result->summary, qr/ci\.yml/, 'summary names the workflow file');
}

# ---------------------------------------------------------------------------
# .circleci/config.yml -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, '.circleci', 'config.yml'),
		"version: 2\njobs:\n  build:\n    docker:\n      - image: perl\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'CircleCI config -> pass');
	is($result->score,  100,    'CircleCI config -> score 100');
}

# ---------------------------------------------------------------------------
# Jenkinsfile -> pass, score 100 (non-YAML; no parse check needed)
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	write_file(
		File::Spec->catfile($dist->path, 'Jenkinsfile'),
		"pipeline { agent any; stages { stage('test') { steps { sh 'prove' } } } }\n",
	);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'Jenkinsfile -> pass');
	is($result->score,  100,    'Jenkinsfile -> score 100');
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
	is($result->check_id, 'ci_config', 'result carries correct check_id');
}

done_testing;
