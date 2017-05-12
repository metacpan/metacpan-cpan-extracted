# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
	inet_aton
	inet_ntoa
	sockaddr_in
	sockaddr_un
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
my $exp = '127.0.0.1';
my $n127 = inet_aton($exp);
my $a127 = inet_ntoa($n127);

print "got: $a127, exp: $exp\nnot "
	unless $a127 eq $exp;
&ok;

## test 3 - 4	check sockaddr_in
my $port = 12345;
my $sin = sockaddr_in($port,$n127);
my($rp,$rn) = sockaddr_in($sin);
my $ra = inet_ntoa($rn);
print "got: $ra, exp: $exp\nnot "
	unless $ra eq $exp;
&ok;

print "got: $rp, exp: $port\nnot "
	unless $rp == $port;
&ok;

