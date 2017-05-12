# -*- perl -*-

# t/108_stories_topic_popular.t - check stories/topic/<topic>/popular endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_popular_stories_by_topic('apple');

ok( $result->{ 'count' } == 10 );
