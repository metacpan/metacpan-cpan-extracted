#############################################
# Tests for Sysadm::Install/s fs_read/write_open
#############################################

use Test::More tests => 2;

use Sysadm::Install qw(:all);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use File::Spec;
use File::Path;

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

ok(1, "loading ok");

SKIP: {

    rmf "$TEST_DIR/tmp";
    if(!bin_find("cpio")) {
        skip "No cpio on this system", 1;
    }

    my $read = fs_read_open("$TEST_DIR");
    my $cpio = join '', <$read>;
    close $read;

    my $write = fs_write_open("$TEST_DIR/tmp");
    print $write $cpio;
    close $write;

    ok(-f "$TEST_DIR/007fs.t", "cpio worked");

    rmf "$TEST_DIR/tmp";
}
