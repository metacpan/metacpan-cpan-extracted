# Before `make install' is performed this script should be runnable 
# with # `make test'. 
# After `make install' it should work as `perl test.pl'

use Test::Harness;
# Test::Harness::verbose=1;
runtests(qw(t/Trigger.t));

