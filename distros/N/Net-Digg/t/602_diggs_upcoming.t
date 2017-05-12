# -*- perl -*-

# t/602_diggs_upcoming.t - check diggs upcoming endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_upcoming_diggs();

ok( $result->{ 'count' } == 10 );
