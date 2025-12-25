#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use PAGI::Test::Response;

subtest 'basic response accessors' => sub {
    my $res = PAGI::Test::Response->new(
        status  => 200,
        headers => [
            ['content-type', 'text/plain'],
            ['x-custom', 'value'],
        ],
        body => 'Hello World',
    );

    is $res->status, 200, 'status';
    is $res->content, 'Hello World', 'content';
    is $res->text, 'Hello World', 'text';
    is $res->header('content-type'), 'text/plain', 'header lookup';
    is $res->header('X-Custom'), 'value', 'header case-insensitive';
    ok $res->is_success, 'is_success for 2xx';
};

subtest 'status helpers' => sub {
    ok( PAGI::Test::Response->new(status => 200)->is_success, '200 is success' );
    ok( PAGI::Test::Response->new(status => 201)->is_success, '201 is success' );
    ok( PAGI::Test::Response->new(status => 301)->is_redirect, '301 is redirect' );
    ok( PAGI::Test::Response->new(status => 404)->is_error, '404 is error' );
    ok( PAGI::Test::Response->new(status => 500)->is_error, '500 is error' );
};

subtest 'json parsing' => sub {
    my $res = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'application/json']],
        body    => '{"name":"John","age":30}',
    );

    my $data = $res->json;
    is $data->{name}, 'John', 'json name';
    is $data->{age}, 30, 'json age';
};

subtest 'json error handling' => sub {
    my $res = PAGI::Test::Response->new(
        status => 200,
        body   => 'not json',
    );

    like dies { $res->json }, qr/malformed|error|invalid|expected/i, 'dies on invalid json';
};

subtest 'convenience methods' => sub {
    my $res = PAGI::Test::Response->new(
        status  => 302,
        headers => [
            ['content-type', 'text/html'],
            ['content-length', '42'],
            ['location', '/redirect-target'],
        ],
        body => 'x' x 42,
    );

    is $res->content_type, 'text/html', 'content_type';
    is $res->content_length, '42', 'content_length';
    is $res->location, '/redirect-target', 'location';
};

done_testing;
