# ------------------------------------
#
# Project:	Noid
#
# Name:		noid5.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter with template de, for 290 identifiers.
#		Try to bind to the 3rd identifier that would be minted,
#			and check that it failed.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/19/2004 - MAR - Initial writing
#
# ------------------------------------

use Test::More tests => 8;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst5.rde long 13030 cdlib.org noidTest >/dev/null");

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

# Try binding the 3rd identifier to be minted.
@noid_output = `$noid_cmd bind set 13030/tst594 element value 2>&1`;
ok(scalar(@noid_output) >= 1,
	"at least one line of output from attempt to bind to an unminted id");
chomp($noid_output[0]);

is($noid_output[0], "error: 13030/tst594: \"long\" term disallows binding " .
	"an unissued identifier unless a hold is first placed on it.",
	"disallowed binding to unminted id");
