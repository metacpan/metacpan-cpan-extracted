# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-CUPS.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Net::CUPS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cups = Net::CUPS->new();

ok( $cups );

my $server_name = $cups->getServer();

ok( $server_name );

$cups->setServer( "test.cups.org" );

ok( $cups->getServer() eq "test.cups.org" );

$cups->setServer( $server_name );

ok( $cups->getServer() eq $server_name );

my $username = $cups->getUsername();

ok( $username );

$cups->setUsername( "cupstestuser" );

ok( $cups->getUsername() eq "cupstestuser" );

$cups->setUsername( $username );

ok( $cups->getUsername() eq $username );
