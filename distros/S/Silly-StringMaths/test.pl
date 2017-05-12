# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Silly::StringMaths qw(add subtract multiply divide exponentiate);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# These tests taken straight from the synopsis

# Add two positive numbers - returns ABFOOR
compare(2, add("FOO", "BAR"), "ABFOOR");

# Add a generally positive number and a negative number
# - returns ot
compare(3, add("FNoRD", "yncft"), "ot");

# Subtract several numbers from a rather large one
# - returns accdeiiiiloopssu
compare(4, subtract("Supercalifragilisticepsialidocious",
						  "stupid", "made", "up", "word"), "accdeiiiiloopssu");

# Multiply two negative numbers - returns AAACCCCCCEEELLLNNN
compare(5, multiply("cancel", "out"), "AAACCCCCCEEELLLNNN");

# Divide two numbers - returns AAA
compare(6, divide("EuropeanCommission", "France"), "AAA");

# Confirm Pythagorus' theorum - returns nothing
compare(7, subtract(exponentiate("FETLA", "PI"),
						  exponentiate("TLA", "PI"),
						  exponentiate("ETLA", "PI")), "");

sub compare {
	my ($test, $result, $expected)=@_;
	print ($result eq $expected ? "ok" : "not ok");
	print " $test\n";
}
