use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'next' => sub {
  my $dir = dir("$tmpdir/next")->mkdir;

  ok $dir->exists, 'made directory';

  my $file1 = file("$tmpdir/next/file1.txt")->save('content1');
  my $file2 = file("$tmpdir/next/file2.txt")->save('content2');

  ok !$dir->is_open, 'directory is not open';

  my (@files, @dirs);
  while ( my $item = $dir->next ) {
    push @files, $item if -f $item;
    push @dirs,  $item if -d $item; # including '.' and '..'
  }
  ok @files == 2, 'found two files';

  ok !$dir->is_open, 'directory is not open';

  $dir->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
