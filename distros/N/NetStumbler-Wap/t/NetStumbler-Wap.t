# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NetStumbler-Wap.t'

#########################

# change 'tests => 4' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('NetStumbler::Wap') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $lib = NetStumbler::Wap->new();
$lib->initialize();
is($lib->getVendorForBBSID("000000000000"),"Xerox","MAC format 1");
is($lib->getVendorForBBSID("00:00:00:00:00:00"),"Xerox","MAC format 2");
isnt($lib->getVendorForBBSID("crap-test"),"Xerox","MAC format 3");