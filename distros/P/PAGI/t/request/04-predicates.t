#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Request;

subtest 'is_json predicate' => sub {
    my $json_scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/json']],
    };
    my $json_charset = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/json; charset=utf-8']],
    };
    my $html_scope = {
        type    => 'http',
        method  => 'GET',
        headers => [['content-type', 'text/html']],
    };

    ok(PAGI::Request->new($json_scope)->is_json, 'application/json is json');
    ok(PAGI::Request->new($json_charset)->is_json, 'with charset is json');
    ok(!PAGI::Request->new($html_scope)->is_json, 'text/html is not json');
};

subtest 'is_form predicate' => sub {
    my $urlencoded = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };
    my $multipart = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'multipart/form-data; boundary=----abc']],
    };
    my $json = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/json']],
    };

    ok(PAGI::Request->new($urlencoded)->is_form, 'urlencoded is form');
    ok(PAGI::Request->new($multipart)->is_form, 'multipart is form');
    ok(!PAGI::Request->new($json)->is_form, 'json is not form');
};

subtest 'is_multipart predicate' => sub {
    my $multipart = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'multipart/form-data; boundary=----abc']],
    };
    my $urlencoded = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };

    ok(PAGI::Request->new($multipart)->is_multipart, 'multipart/form-data');
    ok(!PAGI::Request->new($urlencoded)->is_multipart, 'urlencoded is not multipart');
};

subtest 'accepts predicate' => sub {
    my $scope = {
        type    => 'http',
        method  => 'GET',
        headers => [
            ['accept', 'text/html'],
            ['accept', 'application/json'],
        ],
    };

    my $req = PAGI::Request->new($scope);

    ok($req->accepts('text/html'), 'accepts text/html');
    ok($req->accepts('application/json'), 'accepts application/json');
    ok(!$req->accepts('text/plain'), 'does not accept text/plain');
    ok($req->accepts('text/*'), 'accepts text/* wildcard');
    ok($req->accepts('*/*'), 'accepts */* wildcard');
};

subtest 'is_disconnected' => sub {
    my $scope = { type => 'http', method => 'GET', headers => [] };

    # Test with client still connected
    my $connected_receive = async sub {
        return { type => 'http.request', body => '', more => 1 };
    };
    my $req1 = PAGI::Request->new($scope, $connected_receive);
    my $disconnected1 = (async sub { await $req1->is_disconnected })->()->get;
    ok(!$disconnected1, 'client connected');

    # Test with disconnected client
    my $disconnected_receive = async sub {
        return { type => 'http.disconnect' };
    };
    my $req2 = PAGI::Request->new($scope, $disconnected_receive);
    my $disconnected2 = (async sub { await $req2->is_disconnected })->()->get;
    ok($disconnected2, 'client disconnected');
};

done_testing;
