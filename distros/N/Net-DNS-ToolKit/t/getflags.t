# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	getflags
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2 check the test "getflags" routines
my $buffer = pack("n n n",1234, 18124, 65432);

my $flags = getflags(\$buffer);

print "got: $flags, exp: 18124\nnot "
	unless $flags == 18124;
&ok;
