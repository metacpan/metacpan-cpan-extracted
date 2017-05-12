#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;

# This is really ugly. I need to catch the output of ->table().
# Since I couldn't come up with a better idea, I just open a filehandle
# to a file, then run ->table(), then check the output of the file.

my $fh;
if(!open($fh, "+>tmp_output.log")) {
	plan skip_all => "Couldn't open temporary output file for test: $!";
	exit;
}

# Load the module
plan tests => 2;
require_ok("Term::Menu");

# Print the output
my $out = select($fh);
Term::Menu->table(
	['id', 'number'],
	[[1, 5],
	 [2, 10]]);
select $out;

# Read the output
seek($fh, 0, 0);
my $output = join("", <$fh>);

# Check the output
my $expected_output = <<EXPECTED;
+--+------+
|id|number|
+--+------+
|1 |5     |
|2 |10    |
+--+------+
EXPECTED
ok($expected_output eq $output, "Checking if the output is correct.");

# Close the file
close $fh;
if(!unlink("tmp_output.log")) {
	diag("Warning: Couldn't remove the temporary output file 'tmp_output.log'. You might want to do this yourself."
		."\nError was: $!");
}
