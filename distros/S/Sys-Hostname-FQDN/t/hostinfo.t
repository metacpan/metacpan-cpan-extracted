# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Sys::Hostname::FQDN qw(
	asciihostinfo
	gethostinfo
	fqdn
	short
);
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "short name:\t",short(),"\n";
print "long  name:\t",fqdn(),"\n";

my ($name,$aliases,$addrtype,$length,@addrs) = asciihostinfo();

print qq|
host info
  name		:\t|, $name, qq|
  aliases	:\t|, $aliases, qq|
  address type	:\t|, $addrtype, qq|
  address length:\t|, $length, qq|
  IP address(es):
|;
foreach(@addrs) {
  print "\t$_\n";
}

