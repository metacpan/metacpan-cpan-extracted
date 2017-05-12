use strict;
use warnings;

use Test::More;

use Module::Faker::Dist;
use File::Temp ();
use Path::Class;

my @matches = (

  [ qr/^ \s* NAME \s* => \s* "Provides::Inner::Sorted", \s* $/mx,
    'Makefile.PL gets NAME that looks like a package' ],

);

plan tests => 2 + @matches;

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file('./eg/Provides-Inner-Sorted.yml');

isa_ok($dist, $MFD);

my $dir = $dist->make_dist_dir({ dir => $tmpdir });

my $path = file($dir, 'Makefile.PL');
ok -e $path;

my $content = $path->slurp;

foreach my $match ( @matches ){
  like $content, $match->[0], $match->[1];
}
