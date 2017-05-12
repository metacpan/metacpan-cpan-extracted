# -*- perl -*-

# t/100_stories.t - check stories endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
%params = ('count' => 20);
my $result = $digg->get_stories(\%params);

ok( $result->{ 'count' } == 20 );

