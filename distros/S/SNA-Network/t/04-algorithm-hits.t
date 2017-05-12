#!perl

use Test::More tests => 6;

use SNA::Network;

my $net = SNA::Network->new();
$net->load_from_pajek_net('t/test-network-1.net');

$net->calculate_authorities_and_hubs();

# check authority ranking

my @authorities = map {
	$_->{name}
} sort {
	$b->{authority} <=> $a->{authority}
} $net->nodes();

is($authorities[0], 'B', 'B has highest authority');
is($authorities[1], 'C', 'C has 2nd-highest authority');
is($authorities[2], 'D', 'C has 3rd-highest authority');
is($authorities[3], 'A', 'A has lowest authority');


# check hub ranking

my @hubs = map {
	$_->{name}
} sort {
	$b->{hub} <=> $a->{hub}
} $net->nodes();

is($hubs[2], 'C', 'C is 3rd-highest hub');
is($hubs[3], 'B', 'B is lowest hub');

