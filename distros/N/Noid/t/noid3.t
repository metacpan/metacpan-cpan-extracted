# ------------------------------------
#
# Project:	Noid
#
# Name:		noid3.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter.
#		Hold identifiers that would normally be first and second.
#		Mint 1 and check that it is what would normally be third.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/19/2004 - MAR - Initial writing
#
# ------------------------------------

use Test::More tests => 7;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst3.rde long 13030 cdlib.org noidTest >/dev/null");

# Check that the "NOID" subdirectory was created.
$this_test = -e "$this_dir/NOID";
$next_test = -d _;
ok($this_test, "NOID was created");

unless ($this_test) {
	die "no minter directory created, stopped";
}

# That "NOID" is a directory.
ok($next_test, "NOID is a directory");

unless ($next_test) {
	die "NOID is not a directory, stopped";
}

# Check for the presence of the "README" file, then "log" file, then the
# "logbdb" file within "NOID".
ok(-e "$this_dir/NOID/README", "NOID/README was created");
ok(-e "$this_dir/NOID/log", "NOID/log was created");
ok(-e "$this_dir/NOID/logbdb", "NOID/logbdb was created");

# Check for the presence of the BerkeleyDB file within "NOID".
$this_test = -e "$this_dir/NOID/noid.bdb";
ok($this_test, "NOID/noid.bdb was created");

unless ($this_test) {
	die "minter initialization failed, stopped";
}

# Hold first and second identifiers.
system("$noid_cmd hold set 13030/tst31q 13030/tst30f > /dev/null");

# Mint 1.
@noid_output = `$noid_cmd mint 288`;

# Verify that it's the third one.
chomp($noid_output[0]);
is($noid_output[0], "id: 13030/tst394",
	"held two, minted one, got the third one");
