#!/usr/bin/env perl

use v5.36;
use PAGI::FastAPI;
use Future::AsyncAwait;

my $app = PAGI::FastAPI->new(
    title   => "User Microservice",
    version => "1.0.0"
);

$app->get('/users/{id}',
    handler => async sub ($c) {
        my $user_id = $c->param('id') // 1;
        return {
            data => {
                id    => 0 + $user_id,
                name  => "Alice Developer",
                role  => "Software Engineer",
                email => 'alice@example.com'
            }
        };
    });

$app->to_app;
