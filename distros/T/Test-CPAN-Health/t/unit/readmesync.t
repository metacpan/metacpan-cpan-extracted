use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use_ok('Test::CPAN::Health::Check::ReadmeSync');

use Test::CPAN::Health::Distribution ();

my $check = Test::CPAN::Health::Check::ReadmeSync->new;
isa_ok($check, 'Test::CPAN::Health::Check::ReadmeSync');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'readme_sync', 'id');
is($check->name,     'README Sync', 'name');
is($check->weight,   2,             'weight');
is($check->category, 'packaging',   'category');

# ---------------------------------------------------------------------------
# Helper: create a dist with an optional README
# ---------------------------------------------------------------------------

sub make_dist {
	my (%args) = @_;
	my $tmp = tempdir(CLEANUP => 1);

	if (defined $args{readme_name} && defined $args{readme_content}) {
		my $path = File::Spec->catfile($tmp, $args{readme_name});
		open my $fh, '>', $path;
		print {$fh} $args{readme_content};
		close $fh;
	}

	if ($args{with_meta}) {
		my $meta = File::Spec->catfile($tmp, 'META.json');
		open my $fh, '>', $meta;
		print {$fh} '{"name":"Test-Dist","version":"1.0.0","abstract":"t","author":["T"],"license":["perl_5"],"meta-spec":{"version":2}}';
		close $fh;
	}

	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

# ---------------------------------------------------------------------------
# No README -> fail, score 0
# ---------------------------------------------------------------------------

{
	my $dist = make_dist();
	my $r = $check->run($dist);
	is($r->status, 'fail', 'no README -> fail');
	is($r->score,  0,      'no README -> score 0');
}

# ---------------------------------------------------------------------------
# README.md exists but is trivially short -> warn, score 60
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(readme_name => 'README.md', readme_content => "short\n");
	my $r = $check->run($dist);
	is($r->status, 'warn',         'short README -> warn');
	is($r->score,  60,             'short README -> score 60');
}

# ---------------------------------------------------------------------------
# README.md is long but does not mention the dist name -> warn, score 80
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		readme_name    => 'README.md',
		readme_content => 'x' x 200,
		with_meta      => 1,
	);
	my $r = $check->run($dist);
	is($r->status, 'warn', 'no dist name mention -> warn');
	is($r->score,  80,     'no dist name mention -> score 80');
}

# ---------------------------------------------------------------------------
# README.md present, non-trivial, mentions dist name -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		readme_name    => 'README.md',
		readme_content => "# Test-Dist\n\n" . ('A ' x 60) . "\n",
		with_meta      => 1,
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'good README -> pass');
	is($r->score,  100,    'good README -> score 100');
}

# ---------------------------------------------------------------------------
# README (plain) also recognised
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		readme_name    => 'README',
		readme_content => "Test-Dist\n\n" . ('x' x 200),
		with_meta      => 1,
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'plain README recognised');
}

# ---------------------------------------------------------------------------
# Module form (Test::CPAN::Health) accepted as well as dist form (Test-Dist)
# ---------------------------------------------------------------------------

{
	# META name is 'Test-Dist'; module form is 'Test::Dist'
	my $dist = make_dist(
		readme_name    => 'README.md',
		readme_content => "# Test::Dist\n\n" . ('A ' x 60) . "\n",
		with_meta      => 1,
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'module-name form (::) accepted in README');
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
	my $dist = make_dist();
	my $r = $check->run($dist);
	isa_ok($r, 'Test::CPAN::Health::Result');
	is($r->check_id, 'readme_sync', 'result carries correct check_id');
}

done_testing;
