#!perl

use Test::More tests => 11;

use SNA::Network;

my $net = SNA::Network->new_from_pajek_net('t/community-test-network-1.net');

my $num_communities = $net->identify_communities_with_louvain;

# check expected results

is($net->{total_weight}, 1448, "cached total weight is correct");

is($num_communities, 4, '4 communities expected');

foreach my $community ($net->communities) {
	ok( int $community->members > 30, "community has more than 30 members" );
	ok( $community->module_value > 0.08, "community has positive module value" );
}

ok( $net->modularity > 0.38, "clustering has positive modularity" );

