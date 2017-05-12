use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'seek' => sub {
  my $dir = dir("$tmpdir/seek")->mkdir;

  ok $dir->exists, 'made directory';

  my $file1 = file("$tmpdir/seek/file1.txt")->save('content1');
  my $file2 = file("$tmpdir/seek/file2.txt")->save('content2');

  ok $dir->open, 'opened directory';

  ok defined $dir->tell, 'current position is '. $dir->tell;

  ok $dir->read, 'read directory';

  my $pos = $dir->tell;
  ok $pos, 'got a current position';

  my $read = $dir->read;
  ok $read, 'read more';;

  ok $dir->seek($pos), 'rewinded a bit';

  ok $dir->read eq $read, 'the same thing is read';

  ok $dir->rewind, 'rewinded';

  ok defined $dir->tell, 'current position is '. $dir->tell;

  ok $dir->close, 'closed directory';

  $dir->rmdir;
};

subtest 'seek_before_open' => sub {
  my $dir = dir("$tmpdir/unseekable");

  ok !defined $dir->tell, 'cannot tell';
  ok !defined $dir->read, 'cannot read';
  ok !defined $dir->seek, 'cannot seek';
  ok !defined $dir->rewind, 'cannot rewind';
  ok !defined $dir->close, 'cannot close';
};

subtest 'cannot_open' => sub {
  my $dir = dir("$tmpdir/unseekable");
     $dir->logger(0);

  ok !defined $dir->open, 'cannot open';
};

subtest 'open_opened_directory' => sub {
  my $dir = dir("$tmpdir/seek")->mkdir;

  ok $dir->open, 'opened directory';
  ok $dir->open, 'and opened it again';

  $dir->close;

  $dir->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
