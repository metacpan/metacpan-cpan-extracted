use strict;
use warnings;
use RestAPI;
use Test::More;

ok(my $c = RestAPI->new(
        scheme      => 'http',
        server      => 'localhost',
        port        => 80,
        query       => 'sqlrest',
        q_params    => {},
        path        => 'CUSTOMER',
        http_verb   => 'GET',
        encoding    => 'application/xml',
    ), 'new' );

is( $c->req_params, undef, 'query_string should be undefined...');

ok($c = RestAPI->new(
        scheme      => 'http',
        server      => 'localhost',
        port        => 80,
        query       => 'sqlrest',
        q_params    => { k1 => 'v1' },
        path        => 'CUSTOMER',
        http_verb   => 'GET',
        encoding    => 'application/xml',
    ), 'new' );

is( $c->req_params, 'k1=v1', 'query string valid...' );

done_testing;



