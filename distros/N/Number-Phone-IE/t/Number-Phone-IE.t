# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Number-Phone-IE.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More skip_all => 'No tests yet';
BEGIN { use_ok('Number::Phone::IE') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


