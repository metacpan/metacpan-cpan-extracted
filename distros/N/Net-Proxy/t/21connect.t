use strict;
use warnings;
use Test::More;
use Net::Proxy::Connector;

BEGIN {
    eval { require LWP::UserAgent; };
    plan skip_all => 'LWP::UserAgent not available' if $@;
}

use Net::Proxy::Connector::connect;

plan tests => 13;

# delete all proxy keys from the environment
delete $ENV{$_} for grep { /_proxy$/i } keys %ENV;

my $c;
my $args = {};

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
like( $@, qr/^host parameter is required /, 'No host');
$args->{host} = 'example.com';

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
like( $@, qr/^port parameter is required /, 'No port');
$args->{port} = 9999;

$ENV{HTTP_PROXY} = 'http://powie:zgruppp@urkk.crunch.com:8888/';
eval { $c = Net::Proxy::Connector::connect->new( $args ); };
is( $@, '', 'env_proxy');
isa_ok( $c, 'Net::Proxy::Connector::connect' );
delete $ENV{HTTP_PROXY};

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
like( $@, qr/^proxy_host parameter is required /, 'No proxy_host');
$args->{proxy_host} = 'urkk.crunch.com';

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
is( $@, '', 'proxy_host');
isa_ok( $c, 'Net::Proxy::Connector::connect' );
$args->{proxy_port} = 8888;

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
is( $@, '', 'proxy_port');
isa_ok( $c, 'Net::Proxy::Connector::connect' );
$args->{proxy_user} = 'barkhausen';

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
is( $@, '', 'proxy_user');
isa_ok( $c, 'Net::Proxy::Connector::connect' );
$args->{proxy_pass} = 'gerfaut';

eval { $c = Net::Proxy::Connector::connect->new( $args ); };
is( $@, '', 'proxy_pass');
isa_ok( $c, 'Net::Proxy::Connector::connect' );

