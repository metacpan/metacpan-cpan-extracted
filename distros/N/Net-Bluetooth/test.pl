# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "0..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Config qw(%Config);
use Net::Bluetooth;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

#### Left out test calls because we do not know the state
#### of the machine.

print"All tests successful!\n\n";
