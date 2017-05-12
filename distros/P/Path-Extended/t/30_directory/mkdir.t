use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'mkdir' => sub {
  my $dir = dir("$tmpdir/dir");
  ok !$dir->exists, 'directory does not exist';

  $dir->mkdir;

  ok $dir->exists, 'directory does exist';

  $dir->rmdir;

  ok !$dir->exists, 'directory does not exist';
};

subtest 'already_exists' => sub {
  my $dir = dir("$tmpdir/dir")->mkdir;
  ok $dir->exists, 'directory does exist';

  ok $dir->mkdir, 'does not cause error';

  ok $dir->exists, 'and directory still exists';

  $dir->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
