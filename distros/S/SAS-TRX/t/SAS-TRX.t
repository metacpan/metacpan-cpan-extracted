# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SAS-TRX.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('SAS::TRX') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( !defined SAS::TRX::ibm_float(pack('H*', '4100000000000000')));
ok( SAS::TRX::ibm_float(pack('H*', '437d80')) == 2008 );
ok( SAS::TRX::ibm_float(pack('H*', '4080000000000000')) == 0.5);
ok( SAS::TRX::ibm_float(pack('H*', '4110000000000000')) == 1);
ok( SAS::TRX::ibm_float(pack('H*', 'c110000000000000')) == -1);
ok( SAS::TRX::ibm_float(pack('H*', '000000')) == 0);
ok( SAS::TRX::ibm_float(pack('H*', '4120000000000000')) == 2);
ok( SAS::TRX::ibm_float(pack('H*', '44FE880000000000')) == 65160);
