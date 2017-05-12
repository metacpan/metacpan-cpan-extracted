# -*- perl -*-

# t/403_comments_user.t - check user/comments endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_comments_by_user('kevinrose');

ok( $result->{ 'count' } == 10 );
