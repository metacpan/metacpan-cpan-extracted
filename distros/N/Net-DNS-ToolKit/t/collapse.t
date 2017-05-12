# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(
	collapse
);

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

my $zone = 'BaR.CoM';
my $host = 'foo.bar.com';
my $exp = 'foo';

my $rv = collapse($zone,$host);
print "got: $rv, exp: $exp\nnot "
	unless $rv eq $exp;
&ok;

## test 3	no match
my $notzone = 'foo.xyz.com';
$rv = collapse($zone,$notzone);
print "got: $rv, exp: $notzone\nnot "
	unless $rv eq $notzone;
&ok;
