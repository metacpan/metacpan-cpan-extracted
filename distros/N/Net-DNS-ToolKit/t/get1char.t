# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(get1char);

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

my $buffer = 'hello';
## test 2	check for return of first character
my $rv = get1char(\$buffer,0);
$rv = sprintf("%c",$rv);
print "got: '$rv', exp: 'h'\nnot "
	unless $rv eq 'h';
&ok;

## test 3	check for the 'o'
$rv = get1char(\$buffer,4);
$rv = sprintf("%c",$rv);
print "got: '$rv', exp: 'o'\nnot "
	unless $rv eq 'o';
&ok;

## test 4	check for overflow
$rv = get1char(\$buffer,5);
print "got: '", $rv, "', exp: undef\nnot "
	if defined $rv;
&ok;
