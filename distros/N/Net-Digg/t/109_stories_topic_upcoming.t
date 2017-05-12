# -*- perl -*-

# t/109_stories_topic_upcoming.t - check check stories/topic/<topic>/upcoming endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_upcoming_stories_by_topic('apple');

ok( $result->{ 'count' } == 10 );
