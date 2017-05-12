# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Tor-Servers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 1;

  ok( 1 eq 1, 'foo is bar, and pi is _not_ exactly 3' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

