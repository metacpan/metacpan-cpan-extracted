use strict;
use warnings;
use Test::More tests => 5;
use Net::Proxy;

my $sock = []; # dummy socket object
my $peer = []; # dummy socket object
my $connector = bless {}, 'Net::Proxy::Connector';
my $state = {};

Net::Proxy->set_peer( $sock, $peer );
is( Net::Proxy->get_peer( $sock ), $peer, 'Got back the peer' );

Net::Proxy->set_connector( $sock, $connector );
is( Net::Proxy->get_connector( $sock ), $connector, 'Got back the connector' );

Net::Proxy->set_state( $sock, $state );
is( Net::Proxy->get_state( $sock ), $state, 'Got back the state' );

# data is not clobbered
is( Net::Proxy->get_connector( $sock ), $connector, 'Got back the connector' );
is( Net::Proxy->get_peer( $sock ), $peer, 'Got back the peer' );
