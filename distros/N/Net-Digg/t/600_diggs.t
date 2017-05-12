# -*- perl -*-

# t/600_diggs.t - check diggs endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_diggs();

ok( $result->{ 'count' } == 10 );
