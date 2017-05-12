use strict;
use warnings;

use Test::More;
use Net::Fluidinfo;

use_ok('Net::Fluidinfo::User');

my $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;
foreach my $username ('test', 'fxn') {
    my $user = Net::Fluidinfo::User->get($fin, $username);
    ok $user->username eq $username;
    ok $user->name eq $username;
}

done_testing;