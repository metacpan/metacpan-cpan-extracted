#############################################
# Tests for Sysadm::Install/s plough
#############################################

use Test::More tests => 2;

use Sysadm::Install qw(:all);

use File::Spec;
use File::Path;

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

ok(1, "loading ok");

my $testfile = "";

SKIP: {
  skip "Executable file perms not supported on Win32", 1 if $^O eq "MSWin32";
  $testfile = File::Spec->catfile($TEST_DIR, "test_file");
  blurt("waaaah!", $testfile);
  END { unlink $testfile, "${testfile}_2" }; 

  chmod(0755, $testfile) or die "Cannot chmod";
  cp($testfile, "${testfile}_2");
  Sysadm::Install::perm_cp($testfile, "${testfile}_2");
  
  ok(-x "${testfile}_2", "copied file has same permissions");
}
