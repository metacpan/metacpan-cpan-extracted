use strict;
use warnings;

use Test::More tests => 3;

use Module::Faker::Dist;
use File::Temp ();

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file('./eg/Lacks-META.json');

isa_ok($dist, $MFD);

my $dir = $dist->make_dist_dir({ dir => $tmpdir });

ok(
  -e "$dir/Makefile.PL",
  "there's a Makefile.PL",
);

ok(
  ! -e "$dir/META.yml",
  "but there is no META.yml",
);

