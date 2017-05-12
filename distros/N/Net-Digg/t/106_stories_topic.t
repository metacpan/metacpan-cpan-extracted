# -*- perl -*-

# t/106_stories_topic.t - check stories/topic/<topic> endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_stories_by_topic('apple');

ok( $result->{ 'count' } == 10 );
