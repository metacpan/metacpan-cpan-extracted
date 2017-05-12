# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-GrowlClient.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::GrowlClient') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

diag( "Testing Net::GrowlClient $Net::GrowlClient::VERSION" );
my $growl = Net::GrowlClient->init( 'CLIENT_SKIP_REGISTER' => 1 );
ok($growl->{'CLIENT_SOCKET'},"Basic Initialize");
can_ok('Net::GrowlClient', qw(notify) );