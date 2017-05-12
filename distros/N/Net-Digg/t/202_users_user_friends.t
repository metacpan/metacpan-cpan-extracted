# -*- perl -*-

# t/202_users_user_friends.t - check user/<username>/friends endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_users_friends('kwilms');

ok( $result->{ 'count' } == 10 );
