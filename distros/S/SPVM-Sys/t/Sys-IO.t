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
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

my $test_dir = "$FindBin::Bin";

SPVM::TestCase::Sys::IO->SET_TEST_DIR($test_dir);

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->open("$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->read);
ok(SPVM::TestCase::Sys::IO->lseek);
ok(SPVM::TestCase::Sys::IO->close);
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->write("$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->fopen);
ok(SPVM::TestCase::Sys::IO->fdopen);
ok(SPVM::TestCase::Sys::IO->fread);
ok(SPVM::TestCase::Sys::IO->feof);
ok(SPVM::TestCase::Sys::IO->ferror);
ok(SPVM::TestCase::Sys::IO->clearerr);
ok(SPVM::TestCase::Sys::IO->getc);
ok(SPVM::TestCase::Sys::IO->fgets);
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->fwrite("$tmp_dir"));
}
ok(SPVM::TestCase::Sys::IO->fseek);
ok(SPVM::TestCase::Sys::IO->ftell);
ok(SPVM::TestCase::Sys::IO->fflush);
ok(SPVM::TestCase::Sys::IO->fclose);

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->flock(0, 0) };
  like($@, qr|not supported|);
}
else {
  ok(SPVM::TestCase::Sys::IO->flock);
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
  ok(SPVM::TestCase::Sys::IO->getcwd);
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::IO->realpath(undef, undef) };
  like($@, qr|not supported|);
}
else {
  ok(SPVM::TestCase::Sys::IO->realpath);
}

if ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::IO->_fullpath);
}
else {
  eval { SPVM::Sys::IO->_fullpath(undef, undef, 0) };
  like($@, qr|not supported|);
}

ok(SPVM::TestCase::Sys::IO->chdir);

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

ok(SPVM::TestCase::Sys::IO->readline);

ok(SPVM::TestCase::Sys::IO->ungetc);

unless ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::IO->fsync);
}

ok(SPVM::TestCase::Sys::IO->setvbuf);

ok(SPVM::TestCase::Sys::IO->setbuf);

ok(SPVM::TestCase::Sys::IO->setbuffer);

ok(SPVM::TestCase::Sys::IO->setlinebuf);

ok(SPVM::TestCase::Sys::IO->freopen);

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->truncate("$tmp_dir"));
}

{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys::IO->ftruncate("$tmp_dir"));
}

# Directory stream system calls
{
  # opendir
  {
    ok(SPVM::TestCase::Sys::IO->opendir);
  }
  
  # readdir
  {
    ok(SPVM::TestCase::Sys::IO->readdir);
  }
  
  # seekdir
  {
    ok(SPVM::TestCase::Sys::IO->seekdir);
  }
  
  # telldir
  {
    ok(SPVM::TestCase::Sys::IO->telldir);
  }
  
  # rewinddir
  {
    ok(SPVM::TestCase::Sys::IO->rewinddir);
  }
  
  # closedir
  {
    ok(SPVM::TestCase::Sys::IO->closedir);
  }
}

# fcntl
{
  ok(SPVM::TestCase::Sys::IO->fcntl);
}

# stdin
{
  ok(SPVM::TestCase::Sys::IO->stdin);
}

# stdout
{
  ok(SPVM::TestCase::Sys::IO->stdout);
}

# stderr
{
  ok(SPVM::TestCase::Sys::IO->stderr);
}

# spvm_stdin
{
  ok(SPVM::TestCase::Sys::IO->spvm_stdin);
}

# spvm_stdout
{
  ok(SPVM::TestCase::Sys::IO->spvm_stdout);
}

# spvm_stderr
{
  ok(SPVM::TestCase::Sys::IO->spvm_stderr);
}

SPVM::api->set_exception(undef);

SPVM::TestCase::Sys::IO->SET_TEST_DIR(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
