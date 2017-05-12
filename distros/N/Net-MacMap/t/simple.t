# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::MacMap;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $vendor = Net::MacMap::vendor('00:D0:BA:01:49:B6');
if ($vendor eq 'CISCO SYSTEMS, INC.') { print "ok 2\n" }
else                                  { print "not ok 2\n" }

