# ------------------------------------
#
# Project:	Noid
#
# Name:		noid4.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter with template de, for 290 identifiers.
#		Mint 10.
#		Queue 3, hold 2, that would have been minted in the
#			next 20.
#		Mint 20 and check that they come out in the correct order.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/19/2004 - MAR - Initial writing
#
# ------------------------------------

use Test::More tests => 27;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst4.rde long 13030 cdlib.org noidTest >/dev/null");

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

# Mint 10.
system("$noid_cmd mint 10 > /dev/null");

# Queue 3.
system("$noid_cmd queue now 13030/tst43m 13030/tst47h 13030/tst44k >/dev/null");

# Hold 2.
system("$noid_cmd hold set 13030/tst412 13030/tst421 >/dev/null");

# Mint 20, and check that they have come out in the correct order.
@noid_output = `$noid_cmd mint 20`;

# Remove trailing newlines, and delete the last line if it's empty.
foreach (@noid_output) {
	#print $_;
	chomp;
	}
# If the last one is the null string, delete it.
if ((scalar(@noid_output) > 0) && (length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}

is(scalar(@noid_output), 20, "number of minted noids");

# If we don't have exactly 20, something is probably very wrong.
unless (scalar(@noid_output) == 20) {
	die "wrong number of ids minted, stopped";
}

is($noid_output[0], "id: 13030/tst43m", "1st minted noid");
is($noid_output[1], "id: 13030/tst47h", "2nd minted noid");
is($noid_output[2], "id: 13030/tst44k", "3rd minted noid");
is($noid_output[3], "id: 13030/tst48t", "4th minted noid");
is($noid_output[4], "id: 13030/tst466", "5th minted noid");
is($noid_output[5], "id: 13030/tst44x", "6th minted noid");
is($noid_output[6], "id: 13030/tst42c", "7th minted noid");
is($noid_output[7], "id: 13030/tst49s", "8th minted noid");
is($noid_output[8], "id: 13030/tst48f", "9th minted noid");
is($noid_output[9], "id: 13030/tst475", "10th minted noid");
is($noid_output[10], "id: 13030/tst45v", "11th minted noid");
is($noid_output[11], "id: 13030/tst439", "12th minted noid");
is($noid_output[12], "id: 13030/tst40q", "13th minted noid");
is($noid_output[13], "id: 13030/tst49f", "14th minted noid");
is($noid_output[14], "id: 13030/tst484", "15th minted noid");
is($noid_output[15], "id: 13030/tst46t", "16th minted noid");
is($noid_output[16], "id: 13030/tst45h", "17th minted noid");
is($noid_output[17], "id: 13030/tst447", "18th minted noid");
is($noid_output[18], "id: 13030/tst42z", "19th minted noid");
is($noid_output[19], "id: 13030/tst41n", "20th minted noid");
