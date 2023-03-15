use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use File::Temp ();

use Errno;
use Cwd qw(getcwd);
use File::Basename;

use SPVM 'Sys';

use SPVM 'TestCase::Sys';

my $symlink_supported;
eval { SPVM::Sys->symlink('', '') };
if ($@ && $@ !~ /not permitted/) {
  $symlink_supported = 1;
}
plan skip_all => "no symlink available on this system"
    if !$symlink_supported;

# readlink
{
  my $tmp_dir = File::Temp->newdir;
  ok(SPVM::TestCase::Sys->readlink("$tmp_dir"));
}

# File Tests
{
  my $file_not_exists = "t/ftest/not_exists.txt";
  my $file_empty = "t/ftest/file_empty.txt";
  my $file_bytes8 = "t/ftest/file_bytes8.txt";
  my $file_myexe_exe = "t/ftest/myexe.exe";
  my $file_myexe_bat = "t/ftest/myexe.bat";
  my $file_myexe_cmd = "t/ftest/myexe.cmd";

  # File tests
  {
    ok(SPVM::TestCase::Sys->l);
    is(!!SPVM::Sys->l($file_not_exists), !!-l $file_not_exists);
    is(!!SPVM::Sys->l($file_empty), !!-l $file_empty);
    is(!!SPVM::Sys->l($file_bytes8), !!-l $file_bytes8);
  }
}

done_testing();
