use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'copy' => sub {
  my $file = file("$tmpdir/copy/copy.txt");
  $file->save('content', mkdir => 1 );
  my $size = $file->size;

  ok $file->exists, 'original file created';
  ok $size,         'and not zero sized';

  my $dir = dir("$tmpdir/copy");
     $dir->copy_to("$tmpdir/copied");

  my $original = dir("$tmpdir/copy");
  my $copied   = dir("$tmpdir/copied");

  ok $original->exists, 'original dir still exists';
  ok $copied->exists, 'copied dir exists';

  ok $dir->absolute eq $original->absolute,
    'dir is not moved';

  my $copied_file = file("$tmpdir/copied/copy.txt");
  ok $copied_file->exists, 'copied file exists';
  ok $copied_file->size == $size, 'and the same size';

  $original->rmdir;
  $copied->rmdir;
};

subtest 'move' => sub {
  my $file = file("$tmpdir/move/move.txt");
  $file->save('content', mkdir => 1 );
  my $size = $file->size;

  ok $file->exists, 'original file created';
  ok $size,         'and not zero sized';

  my $dir = dir("$tmpdir/move");
     $dir->move_to("$tmpdir/moved");

  my $original = dir("$tmpdir/move");
  my $moved    = dir("$tmpdir/moved");

  ok !$original->exists, 'original dir does not exist';
  ok $moved->exists, 'moved dir exists';

  ok $dir->absolute eq $moved->absolute,
    'dir is moved';

  my $moved_file = file("$tmpdir/moved/move.txt");
  ok $moved_file->exists, 'moved file exists';
  ok $moved_file->size == $size, 'and the same size';
  $moved->rmdir;
};

subtest 'rename' => sub {
  my $file = file("$tmpdir/rename/rename.txt");
  $file->save('content', mkdir => 1 );
  my $size = $file->size;

  ok $file->exists, 'original file created';
  ok $size,         'and not zero sized';

  my $dir = dir("$tmpdir/rename");
     $dir->rename_to("$tmpdir/renamed");

  my $original = dir("$tmpdir/rename");
  my $renamed  = dir("$tmpdir/renamed");

  ok !$original->exists, 'original dir does not exist';
  ok $renamed->exists, 'renamed dir exists';

  ok $dir->absolute eq $renamed->absolute,
    'dir is renamed';

  my $renamed_file = file("$tmpdir/renamed/rename.txt");
  ok $renamed_file->exists, 'renamed file exists';
  ok $renamed_file->size == $size, 'and the same size';
  $renamed->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
