#!perl

use Test::More tests => 4;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-1.net');

$net->calculate_pageranks();

# check pagerank ranking

my @top_prs = map {
	$_->{name}
} sort {
	$b->{pagerank} <=> $a->{pagerank}
} $net->nodes();

is($top_prs[0], 'B', 'B has highest pagerank');
is($top_prs[1], 'C', 'C has 2nd-highest pagerank');
is($top_prs[2], 'D', 'C has 3rd-highest pagerank');
is($top_prs[3], 'A', 'A has lowest pagerank');

