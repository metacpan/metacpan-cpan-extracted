# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib 't/lib';
use Test::More tests=>5;
use TestModule qw(:Q bar other);

ok(foo, "Exported &foo (always)");
ok(bar, "Exported requested &bar");
ok(qux, "Exported grouped &qux");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

