# -*- perl -*-

# t/110_stories_container_upcoming.t - check stories/container/<conatiner>/upcoming endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_upcoming_stories_by_container('science');

ok( $result->{ 'count' } == 10 );
