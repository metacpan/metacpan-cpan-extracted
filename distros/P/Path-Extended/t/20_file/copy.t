use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'copy' => sub {
  for my $flag (0, 1) {
    my $file = file("$tmpdir/copy.txt");
    $file->save('content');
    my $size = $file->size;

    ok $file->exists, 'original file created';
    ok $size,         'and not zero sized';

    $file->openr if $flag;

    $file->copy_to("$tmpdir/copied.txt");

    my $original = file("$tmpdir/copy.txt");
    my $copied   = file("$tmpdir/copied.txt");

    ok $original->exists, 'original file still exists';
    ok $original->size == $size, 'and the same size';
    ok $copied->exists, 'copied file exists';
    ok $copied->size == $size, 'and the same size';

    ok $file->absolute eq $original->absolute, 'file is not moved';

    $file->close;

    ok $original->unlink;
    $copied->unlink;
  }
};

subtest 'move' => sub {
  for my $flag (0, 1) {
    my $file = file("$tmpdir/move.txt");
    $file->save('content');
    my $size = $file->size;

    ok $file->exists, 'original file created';
    ok $size,         'and not zero sized';

    $file->openr if $flag;

    $file->move_to("$tmpdir/moved.txt");

    my $original = file("$tmpdir/move.txt");
    my $moved    = file("$tmpdir/moved.txt");

    ok !$original->exists, 'original file does not exist';
    ok $moved->exists, 'moved file exists';
    ok $moved->size == $size, 'and the same size';

    ok $file->absolute eq $moved->absolute, 'file is moved';

    $file->close;

    $original->unlink;
    $moved->unlink;
  }
};

subtest 'rename' => sub {
  for my $flag (0, 1) {
    my $file = file("$tmpdir/rename.txt");
    $file->save('content');
    my $size = $file->size;

    ok $file->exists, 'original file created';
    ok $size,         'and not zero sized';

    $file->openr if $flag;

    $file->rename_to("$tmpdir/renamed.txt");

    my $original = file("$tmpdir/rename.txt");
    my $renamed  = file("$tmpdir/renamed.txt");

    ok !$original->exists, 'original file does not exist';
    ok $renamed->exists, 'renamed file exists';
    ok $renamed->size == $size, 'and the same size';

    ok $file->absolute eq $renamed->absolute, 'file is renamed';

    $file->close;

    $original->unlink;
    $renamed->unlink;
  }
};

subtest 'errors' => sub {
  my $file = file("$tmpdir/errors.txt");
     $file->logger(0);

  ok !$file->copy_to, 'requires destination';
  ok !$file->move_to, 'requires destination';
  ok !$file->rename_to, 'requires destination';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
