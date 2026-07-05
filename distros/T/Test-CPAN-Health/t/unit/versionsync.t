use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use_ok('Test::CPAN::Health::Check::VersionSync');

use Test::CPAN::Health::Distribution ();

my $check = Test::CPAN::Health::Check::VersionSync->new;
isa_ok($check, 'Test::CPAN::Health::Check::VersionSync');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'version_sync', 'id');
is($check->name,     'Version Sync', 'name');
is($check->weight,   3,              'weight');
is($check->category, 'packaging',    'category');

# ---------------------------------------------------------------------------
# Helper: create a temp dist with META.json and lib/*.pm files
# ---------------------------------------------------------------------------

sub make_dist {
	my (%args) = @_;
	my $tmp   = tempdir(CLEANUP => 1);
	my $lib   = File::Spec->catdir($tmp, 'lib');
	make_path($lib);

	if (defined $args{meta_version}) {
		my $meta = File::Spec->catfile($tmp, 'META.json');
		open my $fh, '>', $meta;
		print {$fh} <<"META";
{
   "name"     : "Test-Dist",
   "version"  : "$args{meta_version}",
   "abstract" : "test",
   "author"   : ["Test"],
   "license"  : ["perl_5"],
   "meta-spec": { "version": 2 }
}
META
		close $fh;
	}

	for my $pm_name (keys %{ $args{pm_files} // {} }) {
		my $pm_path = File::Spec->catfile($lib, $pm_name);
		my ($vol, $dir) = File::Spec->splitpath($pm_path);
		make_path(File::Spec->catpath($vol, $dir, ''));
		open my $fh, '>', $pm_path;
		print {$fh} $args{pm_files}{$pm_name};
		close $fh;
	}

	return Test::CPAN::Health::Distribution->new(path => $tmp);
}

# ---------------------------------------------------------------------------
# No META -> skip
# ---------------------------------------------------------------------------

{
	my $tmp = tempdir(CLEANUP => 1);
	make_path(File::Spec->catdir($tmp, 'lib'));
	my $pm = File::Spec->catfile($tmp, 'lib', 'Foo.pm');
	open my $fh, '>', $pm; print {$fh} "package Foo;\nour \$VERSION = '1.0.0';\n1;\n"; close $fh;
	my $dist = Test::CPAN::Health::Distribution->new(path => $tmp);
	my $r = $check->run($dist);
	is($r->status, 'skip', 'no META -> skip');
}

# ---------------------------------------------------------------------------
# No .pm files -> skip
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(meta_version => '1.0.0', pm_files => {});
	my $r = $check->run($dist);
	is($r->status, 'skip', 'no .pm files -> skip');
}

# ---------------------------------------------------------------------------
# All in sync -> pass, score 100
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		meta_version => '1.2.3',
		pm_files     => {
			'Foo.pm' => "package Foo;\nour \$VERSION = '1.2.3';\n1;\n",
			'Bar.pm' => "package Bar;\nour \$VERSION = '1.2.3';\n1;\n",
		},
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'all in sync -> pass');
	is($r->score,  100,    'all in sync -> score 100');
}

# ---------------------------------------------------------------------------
# No $VERSION in any file -> pass (no versions to mismatch)
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		meta_version => '1.2.3',
		pm_files     => {
			'Foo.pm' => "package Foo;\n1;\n",
		},
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'no $VERSION declarations -> pass');
}

# ---------------------------------------------------------------------------
# One file out of sync -> warn or fail depending on ratio
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		meta_version => '1.2.3',
		pm_files     => {
			'Foo.pm' => "package Foo;\nour \$VERSION = '1.2.3';\n1;\n",
			'Bar.pm' => "package Bar;\nour \$VERSION = '0.9.0';\n1;\n",
		},
	);
	my $r = $check->run($dist);
	isnt($r->status, 'pass',    'mismatched file -> not pass');
	cmp_ok($r->score, '<', 100, 'mismatched file -> score < 100');
	ok(scalar @{ $r->details }, 'detail lines present for mismatched file');
}

# ---------------------------------------------------------------------------
# All files out of sync -> fail
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		meta_version => '2.0.0',
		pm_files     => {
			'Foo.pm' => "package Foo;\nour \$VERSION = '0.1.0';\n1;\n",
			'Bar.pm' => "package Bar;\nour \$VERSION = '0.1.0';\n1;\n",
		},
	);
	my $r = $check->run($dist);
	is($r->status, 'fail', 'all mismatched -> fail');
	is($r->score,  0,      'all mismatched -> score 0');
}

# ---------------------------------------------------------------------------
# META version with v-prefix is treated the same as without (CPAN::Meta
# normalises '0.1.0' to 'v0.1.0' internally).
# ---------------------------------------------------------------------------

{
	my $dist = make_dist(
		meta_version => '0.1.0',
		pm_files     => {
			'Foo.pm' => "package Foo;\nour \$VERSION = '0.1.0';\n1;\n",
		},
	);
	my $r = $check->run($dist);
	is($r->status, 'pass', 'v-prefix normalised: 0.1.0 == v0.1.0 -> pass');
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
	my $dist = make_dist(
		meta_version => '1.0.0',
		pm_files     => { 'Foo.pm' => "package Foo;\nour \$VERSION = '1.0.0';\n1;\n" },
	);
	my $r = $check->run($dist);
	isa_ok($r, 'Test::CPAN::Health::Result');
	is($r->check_id, 'version_sync', 'result carries correct check_id');
}

done_testing;
