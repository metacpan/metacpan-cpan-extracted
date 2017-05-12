# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::Interface qw(mac_bin2hex);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $binmac = pack("H*",'a1b2c3d4e5f6');
my $exp = 'A1:B2:C3:D4:E5:F6';
print "got: $_\nexp: $exp\nnot "
	unless ($_ = mac_bin2hex($binmac)) eq $exp;
print "ok 2\n";

my $bo = _bo Net::Interface();
print "got: $_\nexp: $exp\nnot "
	unless ($_ = $bo->mac_bin2hex($binmac)) eq $exp;
print "ok 3\n";
