# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
use strict;
no warnings;
BEGIN { use_ok('Palm::Ztxt') };

#########################

exit();
for (1..10_000) {
   my $foo = new Plam::Ztxt;
}
