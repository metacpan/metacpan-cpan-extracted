# ------------------------------------
#
# Project:	Noid
#
# Name:		noid6.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter with template de, for 290 identifiers.
#		Mint 1 noid.
#		Bind to it a bunch of element/value pairs.
#		Fetch the bindings to see if everything is there.
#
# Command line parameters:  none.
#
# Author:	Michael A. Russell
#
# Revision History:
#		7/20/2004 - MAR - Initial writing
#
# ------------------------------------

# Declare a subroutine we'll define later.
sub random_string;

# Seed the random number generator.
srand(time( ));

use Test::More tests => 112;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst6.rde long 13030 cdlib.org noidTest >/dev/null");

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

# Mint one.
@noid_output = `$noid_cmd mint 1`;
chomp($noid_output[0]);
ok($noid_output[0] =~ s/^id:\s+//, "\"id: \" preceded minted noid");
$bound_noid = $noid_output[0];
undef @noid_output;

# Set up the elements and values that we'll bind to this noid.
%bind_stuff = ( );
while (scalar(keys(%bind_stuff)) < 100) {
	# If we create a duplicate element name (not likely), it will
	# be overwritten in the hash.  No big deal.
	$bind_stuff{random_string( )} = random_string( );
	}

# Start the "bind set" command, so that we'll be able to "print" the
# elements and values.
unless(open(BINDCMD,
	"| $noid_cmd bind set $bound_noid : >/dev/null")) {
	die "open of \"| $noid_cmd bind set $bound_noid :\" failed, ",
		"$!, stopped";
	}
foreach (keys %bind_stuff) {
	print BINDCMD "$_: $bind_stuff{$_}\n";
	}
print BINDCMD "\n";
close(BINDCMD);

# Now, run the "fetch" command to get it all back.
@noid_output = `$noid_cmd fetch $bound_noid`;

ok(scalar(@noid_output) > 0, "\"fetch\" command generated some output");
unless (scalar(@noid_output) > 0) {
	die "something wrong with fetch, stopped";
}

# Remove all newlines.
foreach (@noid_output) {
	chomp;
	}

# If the last line is empty, delete it.
if ((scalar(@noid_output) > 0) && (length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}

is(scalar(@noid_output), 102,
	"there are 102 lines of output from the \"fetch\" command");

# If there aren't 102 lines of output, somethings is wrong.
unless (scalar(@noid_output) == 102) {
	die "something wrong with fetch output, stopped";
}

# Check first line.
ok($noid_output[0] =~ /^id:\s+$bound_noid\s+hold\s*$/,
	"line 1 of \"fetch\" output");

# Check seocnd line.
ok($noid_output[1] =~ /^Circ:\s+/, "line 2 of \"fetch\" output");

# Remove the first two lines from the array.
shift(@noid_output);
shift(@noid_output);

# Run through the rest, looking to see if they're correct.
for ($i = 0; $i < 100; $i++) {
	if ($noid_output[$i] =~ /^\s*(\S+)\s*:\s*(\S+)\s*$/) {
		$element = $1;
		$value = $2;
		if (exists($bind_stuff{$element})) {
			if ($bind_stuff{$element} eq $value) {
				ok(1, "line " . ($i + 3) . " of \"fetch\" " .
					"output");
				delete($bind_stuff{$element});
				}
			else {
				ok(0, "line " . ($i + 3) . " of \"fetch\" " .
					"output:  element \"$element\" was " .
					"bound to value " .
					"\"$bind_stuff{$element}\", but " .
					"\"fetch\" returned that it was " .
					"bound to value \"$value\"");
				}
			}
		else {
			ok(0, "line " . ($i + 3) . " of \"fetch\" output " .
				"(\"$noid_output[$i]\") contained an element " .
				"that was not in the group of elements " .
				"bound to this noid");
			}
		}
	else {
		ok(0, "line " . ($i + 3) .  " of \"fetch\" output " .
			"(\"$noid_output[$i]\") is in an unexpected format");
		}
	}

# Everything that was bound and has been verified has been deleted from
# the hash.  So the hash should now be empty.
is(scalar(keys(%bind_stuff)), 0,
	"everything that was bound was returned by the \"fetch\" command");

# -----
# Subroutine to generate a random string of (sort of) random length.
sub random_string {
	my $to_choose_from =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ" .
		"abcdefghijklmnopqrstuvwxyz" .
		"0123456789";
	my $to_choose_index;
	my $string_length;
	my $i;
	my $building_string = "";

	# Calculate the string length.  First, get a fractional number that's
	# between 0 and 1 but never 1.
	$string_length = rand;
	# Multiply it by 48, so that it's between 0 and 48, but never 48.
	$string_length *= 48;
	# Throw away the fractional part, leaving an integer between 0 and 47.
	$string_length = int($string_length);
	# Add 3 to give us a number between 3 and 50.
	$string_length += 3;

	for ($i = 0; $i < $string_length; $i++) {
		# Calculate an integer between 0 and ((length of
		# $to_choose_from) - 1).
		# First, get a fractional number that's between 0 and 1,
		# but never 1.
		$to_choose_index = rand;
		# Multiply it by the length of $to_choose_from, to get
		# a number that's between 0 and (length of $to_choose_from),
		# but never (length of $choose_from);
		$to_choose_index *= length($to_choose_from);
		# Throw away the fractional part to get an integer that's
		# between 0 and ((length of $to_choose_from) - 1).
		$to_choose_index = int($to_choose_index);

		# Fetch the character at that index into $to_choose_from,
		# and append it to the end of the string we're building.
		$building_string .= substr($to_choose_from, $to_choose_index,
			1);
		}

	# Return our construction.
	return($building_string);
	}
