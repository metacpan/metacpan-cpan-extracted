use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'exists' => sub {
  my $dir = dir("$tmpdir/tmpdir");

  $dir->rmdir;

  ok !$dir->exists, 'dir does not exist';

  $dir->mkdir;

  ok $dir->exists, 'dir exists';

  $dir->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
