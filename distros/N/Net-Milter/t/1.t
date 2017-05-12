# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Net::Milter;') };

#########################

ok (my $milter = new Net::Milter, 'created a new milter object');

# not a lot more testing possible in the absence of a real milter filter
# to talk to


