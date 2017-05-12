# -*- perl -*-

# t/300_galleryphotos.t - check galleryphotos endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_galleryphotos();

ok( $result->{ 'count' } == 10 );
