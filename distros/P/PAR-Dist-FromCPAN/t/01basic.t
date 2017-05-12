# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PAR-Dist-FromCPAN.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('PAR::Dist::FromCPAN') };

#########################

# sorry, no more than compilation tests at this time. Promise to do better.
