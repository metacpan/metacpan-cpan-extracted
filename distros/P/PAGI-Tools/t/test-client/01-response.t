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

subtest 'text decoding with charset' => sub {
    use Encode;

    # UTF-8 with explicit charset
    my $utf8_body = Encode::encode('UTF-8', "Héllo Wörld");
    my $res1 = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'text/plain; charset=utf-8']],
        body    => $utf8_body,
    );
    is $res1->text, "Héllo Wörld", 'text decodes UTF-8 charset';
    is $res1->content, $utf8_body, 'content returns raw bytes';

    # ISO-8859-1 (Latin-1) charset
    my $latin1_body = Encode::encode('ISO-8859-1', "café");
    my $res2 = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'text/html; charset=ISO-8859-1']],
        body    => $latin1_body,
    );
    is $res2->text, "café", 'text decodes ISO-8859-1 charset';

    # Quoted charset value
    my $res3 = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'text/plain; charset="utf-8"']],
        body    => $utf8_body,
    );
    is $res3->text, "Héllo Wörld", 'text handles quoted charset';

    # No charset defaults to UTF-8
    my $res4 = PAGI::Test::Response->new(
        status  => 200,
        headers => [['content-type', 'text/plain']],
        body    => $utf8_body,
    );
    is $res4->text, "Héllo Wörld", 'text defaults to UTF-8 when no charset';

    # No Content-Type header defaults to UTF-8
    my $res5 = PAGI::Test::Response->new(
        status => 200,
        body   => $utf8_body,
    );
    is $res5->text, "Héllo Wörld", 'text defaults to UTF-8 when no Content-Type';

    # Empty body
    my $res6 = PAGI::Test::Response->new(
        status => 200,
        body   => '',
    );
    is $res6->text, '', 'empty body returns empty string';
};

done_testing;
