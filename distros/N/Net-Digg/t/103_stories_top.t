# -*- perl -*-

# t/103_stories_top.t - check stories/top endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_top_stories();

ok( $result->{ 'count' } == 10 );
