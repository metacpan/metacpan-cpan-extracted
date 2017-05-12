use strict;
use warnings;

use Test::More tests => 4;

use Module::Faker::Dist;
use File::Temp ();

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file('./eg/Provides-Inner-Sorted.yml');

isa_ok($dist, $MFD);

my $dir = $dist->make_dist_dir({ dir => $tmpdir });

my $file = File::Spec->catfile($dir, qw(lib Provides Inner), 'Sorted.pm');

ok(-e $file, "there's a package file");

my @pkg_lines = do {
  open my $fh, '<', $file or die "couldn't open file $file: $!";
  grep { /^package/ } <$fh>;
};

chomp @pkg_lines;
s/^package (.+);/$1/ for @pkg_lines;

is(@pkg_lines, 4, 'there! are! four! lines!');

is_deeply(
  \@pkg_lines,
  [ map { "Provides::Inner::Sorted::$_" } qw(Alfa Charlie Delta Bravo) ],
  "the packages are in the right order",
);

