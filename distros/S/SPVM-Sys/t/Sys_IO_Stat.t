use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use File::Temp;

use SPVM 'TestCase::Sys::IO::Stat';

use IO::Poll;

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

my $test_dir = "$FindBin::Bin";

{
  ok(SPVM::TestCase::Sys::IO::Stat->stat("$test_dir"));
  
  my $stat_info = SPVM::TestCase::Sys::IO::Stat->stat_info("$test_dir");
  my $stat_info_expected = [stat "$test_dir/ftest/readline_long_lines.txt"];
  use Data::Dumper;
  warn Dumper $stat_info->to_elems;
  warn Dumper $stat_info_expected;

=pod

  0 dev      device number of filesystem
  1 ino      inode number
  2 mode     file mode  (type and permissions)
  3 nlink    number of (hard) links to the file
  4 uid      numeric user ID of file's owner
  5 gid      numeric group ID of file's owner
  6 rdev     the device identifier (special files only)
  7 size     total size of file, in bytes
  8 atime    last access time in seconds since the epoch
  9 mtime    last modify time in seconds since the epoch
 10 ctime    inode change time in seconds since the epoch (*)
 11 blksize  preferred I/O size in bytes for interacting with the
             file (may vary from file to file)
 12 blocks   actual number of system-specific blocks allocated
             on disk (often, but not always, 512 bytes each)

=cut
  
  my $stat_info_array = $stat_info->to_elems;
  is($stat_info_array->[0], $stat_info_expected->[0], "stat[0]");
  is($stat_info_array->[1], $stat_info_expected->[1], "stat[1]");
  is($stat_info_array->[2], $stat_info_expected->[2], "stat[2]");
  if ($^O eq 'MSWin32') {
    warn("[Test Output]Output:$stat_info_array->[3], Expected(Perl Output):$stat_info_expected->[3] on Windows");
  }
  else {
    is($stat_info_array->[3], $stat_info_expected->[3], "stat[3");
  }
  is($stat_info_array->[4], $stat_info_expected->[4], "stat[4]");
  is($stat_info_array->[5], $stat_info_expected->[5], "stat[5]");
  is($stat_info_array->[6], $stat_info_expected->[6], "stat[6]");
  is($stat_info_array->[7], $stat_info_expected->[7], "stat[7]");
  is($stat_info_array->[8], $stat_info_expected->[8], "stat[8]");
  is($stat_info_array->[9], $stat_info_expected->[9], "stat[9]");
  is($stat_info_array->[10], $stat_info_expected->[10], "stat[10]");
  
  unless ($^O eq 'MSWin32') {
    is($stat_info_array->[11], $stat_info_expected->[11], "stat[11]");
    is($stat_info_array->[12], $stat_info_expected->[12], "stat[12]");
  }
}

unless ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::IO::Stat->lstat("$test_dir"));
  
  my $stat_info = SPVM::TestCase::Sys::IO::Stat->lstat_info("$test_dir");
  my $stat_info_expected = [lstat "$test_dir/ftest/readline_long_lines.txt"];
  warn Dumper $stat_info->to_elems;
  warn Dumper $stat_info_expected;
  is_deeply($stat_info->to_elems, $stat_info_expected);
}

{
  ok(SPVM::TestCase::Sys::IO::Stat->fstat("$test_dir"));
  
  my $stat_info = SPVM::TestCase::Sys::IO::Stat->fstat_info("$test_dir");
  my $stat_info_expected = [stat "$test_dir/ftest/readline_long_lines.txt"];
  warn Dumper $stat_info->to_elems;
  warn Dumper $stat_info_expected;
  
  my $stat_info_array = $stat_info->to_elems;
  if ($^O eq 'MSWin32') {
    warn("[Test Output]Output:$stat_info_array->[0], Expected(Perl Output):$stat_info_expected->[0] on Windows");
  }
  else {
    is($stat_info_array->[0], $stat_info_expected->[0], "stat[0]");
  }
  is($stat_info_array->[1], $stat_info_expected->[1], "stat[1]");
  is($stat_info_array->[2], $stat_info_expected->[2], "stat[2]");
  if ($^O eq 'MSWin32') {
    warn("[Test Output]Output:$stat_info_array->[3], Expected(Perl Output):$stat_info_expected->[3] on Windows");
  }
  else {
    is($stat_info_array->[3], $stat_info_expected->[3], "stat[3]");
  }
  is($stat_info_array->[4], $stat_info_expected->[4], "stat[4]");
  is($stat_info_array->[5], $stat_info_expected->[5], "stat[5]");
  if ($^O eq 'MSWin32') {
    warn("[Test Output]Output:$stat_info_array->[6], Expected(Perl Output):$stat_info_expected->[6] on Windows");
  }
  else {
    is($stat_info_array->[6], $stat_info_expected->[6], "stat[6]");
  }
  is($stat_info_array->[7], $stat_info_expected->[7], "stat[7]");
  is($stat_info_array->[8], $stat_info_expected->[8], "stat[8]");
  is($stat_info_array->[9], $stat_info_expected->[9], "stat[9]");
  is($stat_info_array->[10], $stat_info_expected->[10], "stat[10]");
  
  unless ($^O eq 'MSWin32') {
    is($stat_info_array->[11], $stat_info_expected->[11], "stat[11]");
    is($stat_info_array->[12], $stat_info_expected->[12], "stat[12]");
  }
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
