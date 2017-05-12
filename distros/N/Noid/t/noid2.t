# ------------------------------------
#
# Project:	Noid
#
# Name:		noid2.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create a minter.
#		Queue something.
#		Check that it was logged properly.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/19/2004 - MAR - Initial writing
#
# ------------------------------------

use Test::More tests => 11;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst2.rde long 13030 cdlib.org noidTest >/dev/null");

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

# Try to queue one.
system("$noid_cmd queue now 13030/tst27h >/dev/null");

# Examine the contents of the log.
unless (open(NOIDLOG, "$this_dir/NOID/log")) {
	ok(0, "successfully opened \"$this_dir/NOID/log\", $!");
	die "failed to open log file, stopped";
}

# Read in the log.
@log_lines = <NOIDLOG>;
close(NOIDLOG);

is(scalar(@log_lines), 4, "number of lines in \"$this_dir/NOID/log\"");

# If we don't have exactly 4 lines, something is probably very wrong.
unless (scalar(@log_lines) == 4) {
	print "log_lines: ", join(", ", @log_lines), "\n";
	die "something wrong with log format, stopped";
}

# Remove trailing newlines.
foreach (@log_lines) {
	chomp;
}

# Check the contents of the lines.
is($log_lines[0], "Creating database for template \"tst2.rde\".",
	"line 1 of \"$this_dir/NOID/log\" correct");
is($log_lines[1],
	"note: id 13030/tst27h being queued before first " .
		"minting (to be pre-cycled)",
	"line 2 of \"$this_dir/NOID/log\" correct");
like($log_lines[2],
	qr@m: q|\d\d\d\d\d\d\d\d\d\d\d\d\d\d|jak/users|0@,
	"line 4 of \"$this_dir/NOID/log\" correct");
ok($log_lines[3] =~ /^id: 13030\/tst27h added to queue under :\/q\//,
	"line 4 of \"$this_dir/NOID/log\" correct");
