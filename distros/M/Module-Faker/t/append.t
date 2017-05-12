use strict;
use warnings;

use Test::More tests => 4;

use Module::Faker::Dist;
use File::Temp ();
use Path::Class qw(file);

my $MFD = 'Module::Faker::Dist';

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $dist = $MFD->from_file('./eg/Append.yml');

isa_ok($dist, $MFD);

my $dir = $dist->make_dist_dir({ dir => $tmpdir });

ok(
  -e "$dir/t/foo.t",
  "there's my test file",
);

is(
  file("$dir/t/foo.t")->slurp,
  "use Test::More;\n\nok(1);", 'test written'
);

like(
  file("$dir/lib/Provides/Inner.pm")->slurp,
  qr/1\n\n=head1 NAME\n\nAppend - here I am/, 'appended pod'
);