# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "could not load Net::Connection::Sniffer::Util\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer::Util;
use NetAddr::IP::Util qw(
	inet_any2n
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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

## test 2	check not equal
my $ip1 = newcidr24 Net::Connection::Sniffer::Util(inet_any2n('1.2.3.4'));
my $ip2 = newcidr24 Net::Connection::Sniffer::Util(inet_any2n('3.4.5.6'));
print "ip1 should not equal ip2\nnot "
	if $ip1->equal($ip2);
&ok;

## test 2	check equal
$ip2 = newcidr24 Net::Connection::Sniffer::Util(inet_any2n('1.2.3.4'));
print "ip1 should equal ip2\nnot "
	unless $ip1->equal($ip2);
&ok;
