# ------------------------------------
#
# Project:	Noid
#
# Name:		noid1.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter with template de, for 290 identifiers.
#		Mint 288.
#		Mint 1 and check that it was what was expected.
#		Queue one of the 288 and check that it failed.
#		Release hold on 3 of the 288.
#		Queue those 3.
#		Mint 3 and check that they are the ones that were queued.
#		Mint 1 and check that it was what was expected.
#		Mint 1 and check that it failed.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/15/2004 - MAR - Initial writing
#
# ------------------------------------

use Test::More tests => 19;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst1.rde long 13030 cdlib.org noidTest >/dev/null");

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

# If it wasn't, then there is something wrong with initialization, so give up.
unless ($this_test) {
	die "minter initialization failed, stopped";
}

# Mint all but the last two of 290.
@noid_output = `$noid_cmd mint 288`;

# Clean up each output line.
foreach (@noid_output) {
	chomp;
	s/^\s*id:\s+//;
	}
# If the last one is the null string, delete it.
if ((scalar(@noid_output) > 0) && (length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}
# We expect to have 288 entries.
is(scalar(@noid_output), 288, "number of minted noids is 288");

# Save number 20, number 55, and number 155.
$save_noid[0] = $noid_output[20];
$save_noid[1] = $noid_output[55];
$save_noid[2] = $noid_output[155];
undef @noid_output;

# Mint the next to last one.
$noid = `$noid_cmd mint 1`;
# Remove leading "id: ".
ok($noid =~ s/^id:\s+//, "\"id: \" precedes output of mint command for next to last noid");
# Remove trailing white space.
ok($noid =~ s/\s+$//, "white space follows output of mint command for next to last noid");
# This was the next to the last one on 7/16/2004.
#is($noid, "13030/tst11q", "next to last noid was \"13030/tst11q\"");
is($noid, "13030/tst190", "next to last noid was \"13030/tst190\"");

# Try to queue one of the 3.  It shouldn't let me, because the hold must
# be released first.
@noid_output = `$noid_cmd queue now $save_noid[0] 2>&1`;

# Verify that it won't let me.
chomp($noid_output[0]);
ok($noid_output[0] =~ /^error: a hold has been set for .* and must be released before the identifier can be queued for minting/,
	"correctly disallowed queue before hold release");

# Release the hold on the 3 minted noids.
system("$noid_cmd hold release $save_noid[0] " .
	"$save_noid[1] $save_noid[2] > /dev/null");

# Queue those 3.
system("$noid_cmd queue now $save_noid[0] $save_noid[1] " .
	"$save_noid[2] > /dev/null");

# Mint them.
@noid_output = `$noid_cmd mint 3`;

# Clean up each line.
foreach (@noid_output) {
	chomp;
	s/^\s*id:\s+//;
	}
# If the last one is the null string, delete it.
if ((scalar(@noid_output) > 0) && (length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}
# We expect to have 3 entries.
is(scalar(@noid_output), 3,
	"(minted 3 queued noids) number of minted noids is 3");

# Check their values.
is($noid_output[0], $save_noid[0], "first of three queued & reminted noids");
is($noid_output[1], $save_noid[1], "second of three queued & reminted noids");
is($noid_output[2], $save_noid[2], "third of three queued & reminted noids");
undef @save_noid;
undef @noid_output;

# Mint the last one.
$noid = `$noid_cmd mint 1`;
# Remove leading "id: ".
ok($noid =~ s/^id:\s+//, "\"id: \" precedes output of mint command for last noid");
# Remove trailing white space.
ok($noid =~ s/\s+$//, "white space follows output of mint command for last noid");
# This was the the last one on 7/16/2004.
#is($noid, "13030/tst10f", "last noid was \"13030/tst10f\"");
is($noid, "13030/tst17p", "last noid was \"13030/tst17p\"");

# Try to mint another, after they are exhausted.
@noid_output = `$noid_cmd mint 1 2>&1`;

# Clean up each line.
foreach (@noid_output) {
	chomp;
}

ok($noid_output[0] =~ /^\s*error: identifiers exhausted/,
	"correctly disallowed minting after identifiers were exhausted");
