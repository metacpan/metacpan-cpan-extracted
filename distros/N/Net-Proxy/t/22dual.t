use strict;
use warnings;
use Test::More tests => 10;
use Net::Proxy::Connector;
use Net::Proxy::Connector::dual;

my $c;
my $args = {};

eval { $c = Net::Proxy::Connector::dual->new($args); };
like( $@, qr/^'client_first' connector required /, 'No client_first' );
$args->{client_first} = 1;

eval { $c = Net::Proxy::Connector::dual->new($args); };
like(
    $@,
    qr/^'client_first' connector must be a HASHREF /,
    'client_first not HASHREF'
);
$args->{client_first} = {};

eval { $c = Net::Proxy::Connector::dual->new($args); };
like(
    $@,
    qr/^'type' key required for 'client_first' connector /,
    'No type for client_first'
);
$args->{client_first} = { type => 'zlonk' };

eval { $c = Net::Proxy::Connector::dual->new($args); };
like(
    $@,
    qr/^Couldn't load Net::Proxy::Connector::zlonk for 'client_first' connector: /,
    'Bad connector type for client_first'
);
$args->{client_first} = { type => 'tcp' };
$args->{_proxy_} = bless {}, 'Net::Proxy';

eval { $c = Net::Proxy::Connector::dual->new( $args ); };
like( $@, qr/^'server_first' connector required /, 'No server_first' );
$args->{server_first} = 1;

eval { $c = Net::Proxy::Connector::dual->new($args); };
like(
    $@,
    qr/^'server_first' connector must be a HASHREF /,
    'server_first not HASHREF'
);
$args->{server_first} = { type => 'zowie' };

eval { $c = Net::Proxy::Connector::dual->new($args); };
like(
    $@,
    qr/^Couldn't load Net::Proxy::Connector::zowie for 'server_first' connector: /,
    'Bad connector type for server_first'
);
$args->{server_first} = { type => 'tcp' };

eval { $c = Net::Proxy::Connector::dual->new( $args ); };
like( $@, qr/^Parameter 'port' is required /, 'No port' );
$args->{port} = 444;

eval { $c = Net::Proxy::Connector::dual->new( $args ); };
is( $@, '', 'dual object created');
isa_ok( $c, 'Net::Proxy::Connector::dual' );

