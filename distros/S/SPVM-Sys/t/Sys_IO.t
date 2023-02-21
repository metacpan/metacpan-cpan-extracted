use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use File::Temp;

use SPVM 'TestCase::Sys::IO';
use SPVM 'Sys::IO';

use IO::Poll;

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

my $test_dir = "$FindBin::Bin";
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->open($test_dir, "$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->read($test_dir));
ok(SPVM::TestCase::Sys::IO->lseek($test_dir));
ok(SPVM::TestCase::Sys::IO->close($test_dir));
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->write("$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->fopen($test_dir));
ok(SPVM::TestCase::Sys::IO->fdopen($test_dir));
ok(SPVM::TestCase::Sys::IO->fread($test_dir));
ok(SPVM::TestCase::Sys::IO->feof($test_dir));
ok(SPVM::TestCase::Sys::IO->ferror($test_dir));
ok(SPVM::TestCase::Sys::IO->clearerr($test_dir));
ok(SPVM::TestCase::Sys::IO->getc($test_dir));
ok(SPVM::TestCase::Sys::IO->fgets($test_dir));
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->fwrite("$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->fseek($test_dir));
ok(SPVM::TestCase::Sys::IO->ftell($test_dir));
ok(SPVM::TestCase::Sys::IO->fflush($test_dir));
ok(SPVM::TestCase::Sys::IO->fclose($test_dir));

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->flock(0, 0) };
  like($@, qr|not supported|);
}
else {
  ok(SPVM::TestCase::Sys::IO->flock($test_dir));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->mkdir("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->umask("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->rmdir("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->unlink("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->rename("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->fileno("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->getcwd("$tmp_dir"));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->realpath(undef, undef) };
  like($@, qr|not supported|);
}
else {
  ok(SPVM::TestCase::Sys::IO->realpath("$test_dir"));
}

if ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::IO->_fullpath("$test_dir"));
}
else {
  eval { SPVM::Sys::IO->_fullpath(undef, undef, 0) };
  like($@, qr|not supported|);
}

ok(SPVM::TestCase::Sys::IO->chdir("$test_dir"));

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->chmod("$tmp_dir"));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->chown(undef, 0, 0) };
  like($@, qr|not supported|);
}
else {
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->chown("$tmp_dir"));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->symlink(undef, undef) };
  like($@, qr|not supported|);
}
else {
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->symlink("$tmp_dir"));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->readlink(undef, undef, 0) };
  like($@, qr|not supported|);
}
else {
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->readlink("$tmp_dir"));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->readlinkp(undef) };
  ok($@);
}
else {
  my $tmp_dir = File::Temp->newdir;
  ok(!SPVM::TestCase::Sys::IO->readlinkp("$tmp_dir"));
}

ok(SPVM::TestCase::Sys::IO->readline("$test_dir"));

ok(SPVM::TestCase::Sys::IO->ungetc("$test_dir"));

unless ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::IO->fsync("$test_dir"));
}

ok(SPVM::TestCase::Sys::IO->setvbuf("$test_dir"));

ok(SPVM::TestCase::Sys::IO->setbuf("$test_dir"));

ok(SPVM::TestCase::Sys::IO->setbuffer("$test_dir"));

ok(SPVM::TestCase::Sys::IO->setlinebuf("$test_dir"));

ok(SPVM::TestCase::Sys::IO->freopen("$test_dir"));

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->truncate("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->ftruncate("$tmp_dir"));
}

ok(SPVM::TestCase::Sys::IO->utime("$test_dir"));

# opendir
{
  ok(SPVM::TestCase::Sys::IO->opendir($test_dir));
}

# readdir
{
  ok(SPVM::TestCase::Sys::IO->readdir($test_dir));
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
