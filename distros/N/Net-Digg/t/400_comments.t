# -*- perl -*-

# t/400_comments.t - check comments endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_comments();

ok( $result->{ 'count' } == 10 );
