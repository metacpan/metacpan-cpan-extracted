#!/usr/bin/env perl

use v5.36;
use PAGI::FastAPI;
use Future::AsyncAwait;

my $app = PAGI::FastAPI->new(
    title   => "Order Microservice",
    version => "1.0.0"
);

$app->get('/orders/user/{id}', handler => async sub ($c) {
    my $user_id = $c->param('id') // 1;
    return {
        user_id => 0 + $user_id,
        orders  => [
            { id => 101, item => "Mechanical Keyboard", price => 120 },
            { id => 102, item => "4K Monitor",          price => 350 }
        ]
    };
});

$app->to_app;
