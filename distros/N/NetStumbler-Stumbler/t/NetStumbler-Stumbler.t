# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NetStumbler-Stumbler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('NetStumbler::Stumbler') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$lib = NetStumbler::Stumbler->new;
ok($lib->isNS1("test.ns1") == 1,"Testing NS1");
ok($lib->isSummary("test.summary") == 1,"Testing Summary");