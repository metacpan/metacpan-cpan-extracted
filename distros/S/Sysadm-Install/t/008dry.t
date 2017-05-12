#############################################
# Tests for Sysadm::Install/s fs_read/write_open
#############################################

use Test::More tests => 3;

use Sysadm::Install qw(:all);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use File::Spec;
use File::Path;

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

ok(1, "loading ok");

rmf "$TEST_DIR/tmp";
mkd "$TEST_DIR/tmp";

Sysadm::Install::dry_run(1);
blurt "abc", "$TEST_DIR/tmp/abc";

ok(!-f "$TEST_DIR/tmp/abc", "dry run");

Sysadm::Install::dry_run(0);
blurt "abc", "$TEST_DIR/tmp/abc";

ok(-f "$TEST_DIR/tmp/abc", "dry run");

rmf "$TEST_DIR/tmp";
