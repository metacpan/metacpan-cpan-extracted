use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::AbandonedDeps;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::AbandonedDeps->new;
isa_ok($check, 'Test::CPAN::Health::Check::AbandonedDeps');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'abandoned_deps',          'id');
is($check->name,     'Abandoned Dependencies',  'name');
is($check->weight,   5,                         'weight');
is($check->category, 'security',                'category');

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
# run() croaks on wrong argument type
# ---------------------------------------------------------------------------

throws_ok(
	sub { $check->run('not a dist') },
	qr/must be a Test::CPAN::Health::Distribution/,
	'run() croaks on non-Distribution argument',
);

# ---------------------------------------------------------------------------
# Skip when no_network flag is set
# ---------------------------------------------------------------------------

{
	my $nn_check = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 1);
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), <<'JSON');
{
   "name"      : "Test-Dist",
   "version"   : "0.01",
   "abstract"  : "A test distribution",
   "author"    : ["Test Author <test\@example.com>"],
   "license"   : ["perl_5"],
   "meta-spec" : { "version" : "2", "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec" },
   "prereqs"   : { "runtime" : { "requires" : { "HTTP::Tiny" : "0" } } }
}
JSON
	my $result = $nn_check->run($dist);
	is($result->status, 'skip', 'no_network -> skip');
	like($result->summary, qr/network/i, 'summary mentions network');
}

# ---------------------------------------------------------------------------
# Skip when no META file present
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $nn_check = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 1);
	my $result   = $nn_check->run($dist);
	is($result->status, 'skip', 'no META -> skip on no_network');
}

# ---------------------------------------------------------------------------
# Skip when META has no non-core runtime deps
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), <<'JSON');
{
   "name"      : "Test-Dist",
   "version"   : "0.01",
   "abstract"  : "A test distribution",
   "author"    : ["Test Author <test\@example.com>"],
   "license"   : ["perl_5"],
   "meta-spec" : { "version" : "2", "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec" },
   "prereqs"   : { "runtime" : { "requires" : { "perl" : "5.010", "strict" : "0" } } }
}
JSON
	my $nn_check = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 1);
	my $result   = $nn_check->run($dist);
	is($result->status, 'skip', 'core-only deps (or no_network) -> skip');
}

# ---------------------------------------------------------------------------
# Result from the no_network fast path is a valid Result object
# ---------------------------------------------------------------------------

{
	my $nn_check = Test::CPAN::Health::Check::AbandonedDeps->new(no_network => 1);
	my (undef, $dist) = make_dist();
	my $result = $nn_check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'abandoned_deps', 'result carries correct check_id');
}

# ---------------------------------------------------------------------------
# Live MetaCPAN call -- skipped only when NO_NETWORK_TESTING is set
# ---------------------------------------------------------------------------

SKIP: {
	skip q{Live network tests skipped (unset NO_NETWORK_TESTING to run)}, 9
		if $ENV{NO_NETWORK_TESTING};

	my ($tmp, $dist) = make_dist();

	# HTTP::Tiny is actively maintained; it should NOT be flagged as abandoned.
	write_file(File::Spec->catfile($tmp, 'META.json'), <<'JSON');
{
   "name"      : "Test-Dist",
   "version"   : "0.01",
   "abstract"  : "A test distribution",
   "author"    : ["Test Author <test\@example.com>"],
   "license"   : ["perl_5"],
   "meta-spec" : { "version" : "2", "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec" },
   "prereqs"   : {
       "runtime" : {
           "requires" : {
               "HTTP::Tiny"   : "0",
               "JSON::MaybeXS": "0"
           }
       }
   }
}
JSON

	my $live_check = Test::CPAN::Health::Check::AbandonedDeps->new;
	my $result     = $live_check->run($dist);

	isa_ok($result, 'Test::CPAN::Health::Result', 'live: returns a Result');

	SKIP: {
		skip 'live: result was skip/error: ' . $result->summary, 8
			unless grep { $result->status eq $_ } qw(pass warn fail);

		ok(defined $result->score,                        'live: score defined');
		ok($result->score >= 0 && $result->score <= 100, 'live: score in 0..100');
		ok(exists $result->data->{total},                 'live: data.total exists');
		ok(exists $result->data->{abandoned},             'live: data.abandoned exists');
		ok($result->data->{total} > 0,                    'live: total deps checked > 0');
		ok(ref($result->data->{abandoned_mods}) eq 'ARRAY', 'live: abandoned_mods is arrayref');
		ok(ref($result->data->{active_mods})    eq 'ARRAY', 'live: active_mods is arrayref');
		# Verify Both/All-N summary: 2 active deps → "Both", N≠2 → "All N"
		if ($result->data->{abandoned} == 0) {
			my $want = $result->data->{total} == 2 ? 'Both' : "All $result->data->{total}";
			like($result->summary, qr/^\Q$want\E\b/, "live: all-active summary starts '$want'");
		} else {
			pass('live: abandoned deps present, Both/All-N summary test not applicable');
		}
	}
}

# ---------------------------------------------------------------------------
# Live: single dep -- summary must say "All 1", never "Both"
# ---------------------------------------------------------------------------

SKIP: {
	skip q{Live network tests skipped (unset NO_NETWORK_TESTING to run)}, 5
		if $ENV{NO_NETWORK_TESTING};

	my ($tmp2, $dist2) = make_dist();
	write_file(File::Spec->catfile($tmp2, 'META.json'), <<'JSON');
{
   "name"      : "Test-Dist-One",
   "version"   : "0.01",
   "abstract"  : "Single dep test",
   "author"    : ["Test Author <test\@example.com>"],
   "license"   : ["perl_5"],
   "meta-spec" : { "version" : "2", "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec" },
   "prereqs"   : { "runtime" : { "requires" : { "HTTP::Tiny" : "0" } } }
}
JSON

	my $check1  = Test::CPAN::Health::Check::AbandonedDeps->new;
	my $result1 = $check1->run($dist2);

	isa_ok($result1, 'Test::CPAN::Health::Result', 'single-dep: returns a Result');

	SKIP: {
		skip 'single-dep: skip/error - ' . $result1->summary, 4
			unless grep { $result1->status eq $_ } qw(pass warn fail);

		is($result1->data->{total}, 1, 'single-dep: exactly 1 dep checked');
		if ($result1->data->{abandoned} == 0) {
			like($result1->summary, qr/^All 1\b/, 'single-dep: all-active uses "All 1"');
		} else {
			pass('single-dep: dep was abandoned, "All 1" assertion not applicable');
		}
		unlike($result1->summary, qr/^Both\b/, 'single-dep: 1 dep never produces "Both"');
		ok(defined $result1->score, 'single-dep: score is defined');
	}
}

done_testing;
