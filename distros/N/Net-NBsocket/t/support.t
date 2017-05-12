# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Config;
use Net::NBsocket qw(
	havesock6
	isupport6
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

################################################################
################################################################

## test 2	check for Socket6 and host socket6 support

if (havesock6) {
  print STDERR "\thave Socket6 support\n";
} else {
  print STDERR "\tno Socket6 support available\n";
}
&ok;

my $os = $Config{'osname'};

if (isupport6) {
  print STDERR "\t$os system has IPv6 sockets\n";
} else {
  print STDERR "\t$os perl does not support IPv6 sockets\n";
}
&ok;
