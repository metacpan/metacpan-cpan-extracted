use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'rmdir' => sub {
  my $root_dir =  dir("$tmpdir/dir")->mkdir;

  ok $root_dir->exists,  'root dir exists';

  my $subdir = dir("$tmpdir/dir/level1")->mkdir;

  ok $subdir->exists, 'subdirectory exists';

  $root_dir->rmdir({keep_root => 1});

  ok $root_dir->exists,  'root dir exists after rmdir with keep_root';

  ok !$subdir->exists, 'subdirectory does not exist after rmdir with keep_root';

  $root_dir->rmdir;
  ok !$root_dir->exists,  'root dir does not exist';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
