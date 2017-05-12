# -*- perl -*-

# t/104_stories_hot.t - check stories/hot endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_hot_stories();

ok( $result->{ 'count' } == 10 );
