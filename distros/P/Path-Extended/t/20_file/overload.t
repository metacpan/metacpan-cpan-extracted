use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'compare' => sub {
  my $file1 = file("$tmpdir/file1");
  my $file2 = file("$tmpdir/file2");

  ok $file1 ne $file2,    'ne works';
  ok !($file1 eq $file2), 'eq works';
};

subtest 'handle' => sub {
  my $file = file("$tmpdir/overload.txt");
     $file->touch;
     $file->openw;
  print $file 'content';
  $file->close;

  ok $file->slurp eq 'content', 'as a file handle';

  $file->unlink;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
