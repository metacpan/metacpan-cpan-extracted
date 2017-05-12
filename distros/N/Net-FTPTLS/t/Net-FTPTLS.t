# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-FTPTLS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::FTPTLS') };

my $obj = Net::FTPTLS->new;
isa_ok( $obj, 'Net::FTPTLS',"Clasa obiektu" );
is  ( $obj->trivialm(), 1, "Trivial method");



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

