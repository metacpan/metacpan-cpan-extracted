# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..513\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	get1char
	put1char
);
use Net::DNS::ToolKit::Debug qw(print_buf);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2-257
my $buffer = '';
my @numbers = reverse (0..255);
foreach(0..$#numbers) {
  my $exp = $_ +1;
  my $rv = put1char(\$buffer,$_,$numbers[$_]);
  print "bad offset $rv, exp: $exp\nnot "
	unless $rv == $exp;
  &ok;
}

#print_buf(\$buffer);
sleep 1;
## test 258-513
foreach(0..$#numbers) {
  print "got: $rv, exp: $numbers[$_]\nnot "
	unless ($rv = get1char(\$buffer,$_)) == $numbers[$_];
  &ok;
}
