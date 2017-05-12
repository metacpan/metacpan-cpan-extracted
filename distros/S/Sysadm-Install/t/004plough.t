#############################################
# Tests for Sysadm::Install/s plough
#############################################

use Test::More tests => 2;

use Sysadm::Install qw(:all);

use File::Spec;
use File::Path;

my $TEST_DIR = ".";
$TEST_DIR = "t" if -d 't';

#####################################################################
# Create a temp file
#####################################################################
my $TMP_FILE = File::Spec->catfile($TEST_DIR, "test.dat");
END { unlink $TMP_FILE }

#####################################################################
# Blurt
#####################################################################
blurt("one\ntwo\nthree", $TMP_FILE);
ok(-f $TMP_FILE, "$TMP_FILE exists");

#####################################################################
# Count all lines containing 'o'
#####################################################################
my $count = 0;
plough(sub { $count++ if /o/ }, $TMP_FILE);
is($count, 2, "Counting all lines containing pattern");
