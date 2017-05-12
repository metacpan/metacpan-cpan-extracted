# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Lite-XMPP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::Lite::XMPP') };

my $obj = Net::Lite::XMPP->new;
isa_ok( $obj, 'Net::Lite::XMPP',"Clasa obiektu" );
is  ( $obj->trivialm(), 1, "Trivial method");



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

