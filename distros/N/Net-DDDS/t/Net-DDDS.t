# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DDDS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::DDDS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $enum = Net::DDDS::ENUM->new();
my $result = $enum->lookup("+46 8 162000");
ok($result);
is($result,"sip:+468162000\@pstnproxy.sip.su.se");
