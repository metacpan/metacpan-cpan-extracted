# -*- perl -*-

# t/105_stories_container.t - check stories/container/<container> endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_stories_by_container('science');

ok( $result->{ 'count' } == 10 );
