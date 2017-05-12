use Test::More tests => 3;
use strict;
use warnings;

use Net::Proxy;
use Net::Proxy::Connector;

my $c = Net::Proxy::Connector->new( );
isa_ok( $c, 'Net::Proxy::Connector' );

# proxy-related methods
eval { $c->set_proxy( [] ); };
like( $@, qr/is not a Net::Proxy object/, 'set_proxy() wants a Net::Proxy' );

my $p = bless {}, 'Net::Proxy';
$c->set_proxy( $p );
is( $c->get_proxy, $p, 'Got the Net::Proxy back' );

