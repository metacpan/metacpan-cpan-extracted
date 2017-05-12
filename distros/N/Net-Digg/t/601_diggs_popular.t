# -*- perl -*-

# t/601_diggs_popular.t - check diggs popular endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_popular_diggs();

ok( $result->{ 'count' } == 10 );
