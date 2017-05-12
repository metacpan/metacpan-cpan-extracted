# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
	ipv6_aton
	ipv6_n2x
	pack_sockaddr_in6
	unpack_sockaddr_in6
	havesock6
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

## test 2	check inet_aton, inet_ntoa
my $exp = 'dead:beef:0:0:0:0:1234:5678';
my $ndb = ipv6_aton($exp);
my $adb = ipv6_n2x($ndb);

print "got: $adb, exp: $exp\nnot "
	unless $adb eq $exp;
&ok;

## test 3 - 4	check sockaddr_in
my $port = 12345;
my $sin = pack_sockaddr_in6($port,$ndb);
my($rp,$rn) = unpack_sockaddr_in6($sin);
if (havesock6()) {
  my $ra = ipv6_n2x($rn);
  print "got: $ra, exp: $exp\nnot "
	unless $ra eq $exp;
  &ok;

  print "got: $rp, exp: $port\nnot "
	unless $rp == $port;
} else {
  print "Socket6 is not installed,\n\$sin should be 'undef'\nnot "
	if defined $sin;
  &ok;

  print "Socket6 is not installed,\n\$port and \$netaddr should be 'undef'\nnot "
	if defined $rp || defined $rn;
}

&ok;
