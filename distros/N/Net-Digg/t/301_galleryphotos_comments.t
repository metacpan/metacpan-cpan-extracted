# -*- perl -*-

# t/301_galleryphotos_comments.t - check galleryphotos/comments endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_galleryphotos_comments();

ok( $result->{ 'count' } == 10 );
