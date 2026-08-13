#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use Types::Standard qw(Int Str);
use JSON::PP qw(decode_json);
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(title => 'Test App');

$app->get('/users/{id}',
    query   => { verbose => Int },
    handler => async sub ($c) {
        return {
            id      => $c->param('id'),
            verbose => $c->param('verbose'),
            status  => 'active',
        };
    }
);

my $pagi_app = $app->to_app;

subtest 'Valid Async GET Route with Path & Query Params' => sub {
    my $scope = {
        type         => 'http',
        method       => 'GET',
        path         => '/users/42',
        query_string => 'verbose=1',
        headers      => [],
    };

    my $sent_start;
    my $sent_body;

    my $receive = async sub { return { type => 'http.request' } };
    my $send    = async sub ($event) {
        if ($event->{type} eq 'http.response.start') {
            $sent_start = $event;
        }
        elsif ($event->{type} eq 'http.response.body') {
            $sent_body = $event;
        }
    };

    # Resolve async execution with ->get
    $pagi_app->($scope, $receive, $send)->get;

    is $sent_start->{status}, 200, 'HTTP Status 200 OK';

    my $data = decode_json($sent_body->{body});
    is $data->{id}, '42', 'Path parameter parsed via param()';
    is $data->{verbose}, 1, 'Query parameter coerced and parsed via param()';
    is $data->{status}, 'active', 'Handler response payload correct';
};

subtest 'Query Parameter Type Validation Failure' => sub {
    my $scope = {
        type         => 'http',
        method       => 'GET',
        path         => '/users/42',
        query_string => 'verbose=not_an_int',
        headers      => [],
    };

    my $sent_start;
    my $sent_body;

    my $receive = async sub { return { type => 'http.request' } };
    my $send    = async sub ($event) {
        if ($event->{type} eq 'http.response.start') {
            $sent_start = $event;
        }
        elsif ($event->{type} eq 'http.response.body') {
            $sent_body = $event;
        }
    };

    $pagi_app->($scope, $receive, $send)->get;

    is $sent_start->{status}, 422, 'HTTP Status 422 Unprocessable Entity';
    like $sent_body->{body}, qr/Query param 'verbose' invalid/, 'Validation error message returned';
};

subtest '404 Not Found Route' => sub {
    my $scope = {
        type         => 'http',
        method       => 'GET',
        path         => '/nonexistent/route',
        query_string => '',
        headers      => [],
    };

    my $sent_start;

    my $receive = async sub { return { type => 'http.request' } };
    my $send    = async sub ($event) {
        if ($event->{type} eq 'http.response.start') {
            $sent_start = $event;
        }
    };

    $pagi_app->($scope, $receive, $send)->get;

    is $sent_start->{status}, 404, 'HTTP Status 404 Not Found';
};

done_testing;
