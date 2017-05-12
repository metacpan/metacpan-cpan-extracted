# -*- perl -*-

# t/203_users_user_fans.t - check user/<username>/fans endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_users_fans('kwilms');

ok( $result->{ 'count' } == 10 );
