# -*- perl -*-

# t/200_users.t - check users endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_users();

ok( $result->{ 'count' } == 10 );
