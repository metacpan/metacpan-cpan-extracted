use strict;
use warnings;

use Test::More tests => 3;
use Net::StackExchange;

my $se = Net::StackExchange->new( {
    'network' => 'stackoverflow.com',
    'version' => '1.0',
} );
isa_ok( $se, 'Net::StackExchange' );

is( $se->network(), 'stackoverflow.com', 'Network: StackOverflow' );
is( $se->version(), '1.0',               'API version: 1.0'       );
