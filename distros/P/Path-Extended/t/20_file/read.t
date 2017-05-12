use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;
use Fcntl qw( :DEFAULT :seek );

my $tmpdir = tempdir();

subtest 'basic' => sub {
  my $file = file("$tmpdir/read.txt");

  ok $file->open('w'), 'opened file to write';
     $file->binmode;
     $file->autoflush(1);
  ok $file->lock_ex, 'exclusive lock';
  ok $file->print("first line\n"), 'print works';
  ok $file->printf("%s line\n", "second"), 'printf works';
  ok $file->say("third line"), 'say works';
  ok $file->write("fourth line\n"), 'write works';
  ok $file->syswrite("fifth line\n"), 'syswrite works';

  ok $file->close, 'close works';

  ok $file->open('r'), 'opened file to read';
  ok $file->lock_sh, 'shared lock';
  ok $file->getline eq "first line\n", 'read first line';
  my $pos = $file->tell;
  ok $pos, 'tell works';
  my @lines = $file->getlines;
  ok @lines == 4 && $lines[0] eq "second line\n", 'read remaining lines';
  ok $file->seek(0, SEEK_SET), 'rewinded';
  $file->read(my $read, 5);
  ok $read eq 'first', 'read works';
  ok $file->sysseek($pos, SEEK_SET), 'moved pointer to second line';
  $file->sysread($read, 6);
  ok $read eq 'second', 'sysread works';

  $file->close;

  $file->unlink;
};

subtest 'read_before_open' => sub {
  my $file = file("$tmpdir/not_readable.txt");

  ok !$file->is_open, 'file is not open';
  ok !$file->close, "can't close before open";
  ok !$file->binmode, "ignored binmode before open";
  ok !$file->print("ignored"), "ignored print before open";
  ok !$file->printf("ignored"), "ignored printf before open";
  ok !$file->say("ignored"), "ignored say before open";
  ok !$file->getline, "ignored getline before open";
  ok !$file->getlines, "ignored getlines before open";
  ok !$file->read, "ignored read before open";
  ok !$file->sysread, "ignored sysread before open";
  ok !$file->write("ignored"), "ignored write before open";
  ok !$file->syswrite("ignored"), "ignored syswrite before open";
  ok !$file->autoflush(1), "ignored autoflush before open";
  ok !$file->lock_ex, "ignored lock_ex before open";
  ok !$file->lock_sh, "ignored lock_sh before open";
  ok !$file->seek(0, SEEK_SET), "ignored seek before open";
  ok !$file->sysseek(0, SEEK_SET), "ignored sysseek before open";
  ok !$file->tell, "ignored tell before open";
};

subtest 'reopen' => sub {
  my $file = file("$tmpdir/reopen.txt");

  ok $file->open('w'), "file opened";
     $file->write('test');
  ok $file->open('<:raw'), "reopened";

  $file->close;

  ok $file->sysopen(O_RDONLY), "file opened with sysopen";
  ok $file->sysopen(O_RDONLY), "reopened with sysopen";

  $file->unlink;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
