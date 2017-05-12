use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'stat_for_file' => sub {
  my $file = file("$tmpdir/stat.txt");
     $file->touch;

  ok ref $file->stat eq 'File::stat', 'got a stat object';

  $file->unlink;
};

subtest 'stat_for_handle' => sub {
  my $file = file("$tmpdir/stat.txt");
     $file->openw;

  ok ref $file->stat eq 'File::stat', 'got a stat object';

  $file->unlink;
};

subtest 'mtime' => sub {
  my $file = file("$tmpdir/stat.txt");

  ok !$file->mtime, 'no mtime as file does not exist';

  $file->touch;

  ok $file->mtime, 'valid mtime';

  ok $file->mtime(time), 'set mtime';

  $file->unlink;
};

subtest 'size' => sub {
  my $file = file("$tmpdir/stat.txt");

  ok !$file->size, 'zero size as file does not exist';

  $file->touch;

  ok !$file->size, 'zero size';

  $file->save('content');

  ok $file->size, 'non zero size';

  $file->openr;

  ok $file->size, 'non zero size';

  $file->unlink;
};

subtest 'exists' => sub {
  my $file = file("$tmpdir/stat.txt");

  $file->unlink;

  ok !$file->exists, 'file does not exist';

  $file->touch;

  ok $file->exists, 'file exists';

  $file->unlink;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
