# ------------------------------------
#
# Project:	Noid
#
# Name:		noid7.t
#
# Function:	To test the noid command.
#
# What Is Tested:
#		Create minter with template de, for 290 identifiers.
#		Mint 2 noids.
#		Bind an element/value to the first one using the ":"
#			option.
#		Bind an element/value, with the element length greater
#			than 1,500 characters, and the value being
#			10 lines, to the second one using the ":-" option.
#		Fetch the bindings and check that they are correct.
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

use Test::More tests => 27;

my $this_dir = ".";
my $rm_cmd = "/bin/rm -rf $this_dir/NOID > /dev/null 2>&1 ";
my $noid_bin = "blib/script/noid";
my $noid_cmd = (-x $noid_bin ? $noid_bin : "../$noid_bin") . " -f $this_dir ";

# Start off by doing a dbcreate.
# First, though, make sure that the BerkeleyDB files do not exist.
system("$rm_cmd ; " .
	"$noid_cmd dbcreate tst7.rde long 13030 cdlib.org noidTest >/dev/null");

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

# Mint two.
@noid_output = `$noid_cmd mint 2`;

# Remove all newlines.
foreach (@noid_output) {
	chomp;
	}

# If the last line is empty, delete it.
if ((scalar(@noid_output) > 0) && (length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}

ok($noid_output[0] =~ s/^id:\s+//,
	"first line:  \"id: \" preceded minted noid");
ok($noid_output[1] =~ s/^id:\s+//,
	"second line:  \"id: \" preceded minted noid");
$bound_noid1 = $noid_output[0];
$bound_noid2 = $noid_output[1];
undef @noid_output;

# Generate what we'll bind to noid number 1.
$element1 = random_string( );
$value1 = random_string( );

# Start the "bind set" command for noid number 1, so that we'll be
# able to "print" the element/value.
unless(open(BINDCMD,
	"| $noid_cmd bind set $bound_noid1 :- >/dev/null")) {
	die "open of \"| $noid_cmd bind set $bound_noid1 $_\" failed, ",
		"$!, stopped";
}

# Write the element/value pair.
print BINDCMD "$element1: $value1\n";
close(BINDCMD);

# Generate the stuff for noid number 2.
$element2 = "";
while (length($element2) < 1500) {
	$element2 .= random_string( );
}

# Generate 10 lines for the value for noid number 2.
@value2 = ( );
for ($i = 0; $i < 10; $i++) {
	push @value2, random_string( );
	}

# Start the "bind set" command for noid number 2, so that we'll be
# able to "print" the element/value.
unless(open(BINDCMD,
	"| $noid_cmd bind set $bound_noid2 :- >/dev/null")) {
	die "open of \"| $noid_cmd bind set $bound_noid2 :-\" failed, ",
		"$!, stopped";
}

# Write the element/value pair.
print BINDCMD "$element2 : $value2[0]\n";
for ($i = 1; $i < 10; $i++) {
	print BINDCMD "$value2[$i]\n";
	}
close(BINDCMD);

# Now, run the "fetch" command on the noid number 1.
@noid_output = `$noid_cmd fetch $bound_noid1`;

ok(scalar(@noid_output) > 0, "\"fetch\" command on noid 1 generated some " .
	"output");
unless (scalar(@noid_output) > 0) {
	die "something wrong with fetch, stopped";
}

# Remove all newlines.
foreach (@noid_output) {
	chomp;
	}

# Delete any trailing lines that are empty.
while ((scalar(@noid_output) > 0) &&
	(length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}

is(scalar(@noid_output), 3,
	"there are 3 lines of output from the \"fetch\" command on noid 1");

# If there aren't 3 lines of output, somethings is wrong.
unless (scalar(@noid_output) == 3) {
	die "something wrong with fetch output, stopped";
}

# Check first line.
ok($noid_output[0] =~ /^id:\s+$bound_noid1\s+hold\s*$/,
	"line 1 of \"fetch\" output for noid 1");

# Check second line.
ok($noid_output[1] =~ /^Circ:\s+/, "line 2 of \"fetch\" output for noid 1");

# Check third line.
unless ($noid_output[2] =~ /^\s*(\S+)\s*:\s*(\S+)\s*$/) {
	ok(0, "line 3 of \"fetch\" output for noid 1");
	die "something wrong with bound value, stopped";
}

ok(($1 eq $element1) && ($2 eq $value1),
	"line 3 of \"fetch\" output for noid 1");

# Run the "fetch" on noid 2.
@noid_output = `$noid_cmd fetch $bound_noid2`;

ok(scalar(@noid_output) > 0, "\"fetch\" command on noid 2 generated some " .
	"output");
unless (scalar(@noid_output) > 0) {
	die "something wrong with fetched value, stopped";
}

# Remove all newlines.
foreach (@noid_output) {
	chomp;
	}

# Delete any trailing lines that are empty.
while ((scalar(@noid_output) > 0) &&
	(length($noid_output[$#noid_output])) == 0) {
	$#noid_output--;
	}

is(scalar(@noid_output), 12,
	"there are 12 lines of output from the \"fetch\" command on noid 2");

# If there aren't 12 lines of output, something is wrong.
unless (scalar(@noid_output) == 12) {
	die "not enough lines of output, stopped";
}

# Check first line.
ok($noid_output[0] =~ /^id:\s+$bound_noid2\s+hold\s*$/,
	"line 1 of \"fetch\" output for noid 2");

# Check second line.
ok($noid_output[1] =~ /^Circ:\s+/, "line 2 of \"fetch\" output for noid 2");

# Check third line.
unless ($noid_output[2] =~ /^\s*(\S+)\s*:\s*(\S+)\s*$/) {
	ok(0, "line 3 of \"fetch\" output for noid 2");
	die "something wrong with fetch output, stopped";
}

ok(($1 eq $element2) && ($2 eq $value2[0]),
	"line 3 of \"fetch\" output for noid 2");

for ($i = 1; $i <= 9; $i++) {
	is($noid_output[$i + 2], $value2[$i], "line " . ($i + 3) . " of " .
		"\"fetch\" output for noid 2");
	}

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
