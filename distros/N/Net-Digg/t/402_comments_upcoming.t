# -*- perl -*-

# t/402_comments_upcoming.t - check comments/upcoming endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_upcoming_comments();

ok( $result->{ 'count' } == 10 );
