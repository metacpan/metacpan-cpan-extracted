# -*- perl -*-

# t/101_stories_popular.t - check stories/popular endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_popular_stories();

ok( $result->{ 'count' } == 10 );
