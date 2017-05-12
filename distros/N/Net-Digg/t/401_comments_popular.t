# -*- perl -*-

# t/401_comments_popular.t - check comments/popular endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_popular_comments();

ok( $result->{ 'count' } == 10 );
