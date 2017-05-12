# -*- perl -*-

# t/102_stories_upcoming.t - check stories/upcoming endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_upcoming_stories();

ok( $result->{ 'count' } == 10 );
