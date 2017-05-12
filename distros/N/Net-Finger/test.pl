# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::Finger;

$loaded = 1;
print "ok 1\n";

# I'm not going to define tests here, since they would rely on
# having a working network and working finger server on a
# hard-wired other end. Shudder. Too many external variables.

