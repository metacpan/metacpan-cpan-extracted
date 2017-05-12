# -*- perl -*-

# t/107_stories_container_popular.t - check stories/container/<container>/popular endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_popular_stories_by_container('science');

ok( $result->{ 'count' } == 10 );
