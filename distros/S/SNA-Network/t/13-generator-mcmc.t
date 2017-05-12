#!perl

use Test::More tests => 1;

use SNA::Network;

my $net = SNA::Network->new_from_pajek_net('t/community-test-network-1.net');
ok( $net->shuffle, "net shuffled" );

