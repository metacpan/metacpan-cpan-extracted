#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use PAGI::Request;

subtest 'cookies parsing' => sub {
    my $scope = {
        type    => 'http',
        method  => 'GET',
        headers => [
            ['cookie', 'session=abc123; user=john; theme=dark'],
        ],
    };

    my $req = PAGI::Request->new($scope);
    my $cookies = $req->cookies;

    is(ref($cookies), 'HASH', 'cookies returns hashref');
    is($cookies->{session}, 'abc123', 'session cookie');
    is($cookies->{user}, 'john', 'user cookie');
    is($cookies->{theme}, 'dark', 'theme cookie');
};

subtest 'cookie() shortcut' => sub {
    my $scope = {
        type    => 'http',
        method  => 'GET',
        headers => [
            ['cookie', 'token=xyz789'],
        ],
    };

    my $req = PAGI::Request->new($scope);

    is($req->cookie('token'), 'xyz789', 'cookie() returns value');
    is($req->cookie('missing'), undef, 'missing cookie returns undef');
};

subtest 'no cookies' => sub {
    my $scope = { type => 'http', method => 'GET', headers => [] };
    my $req = PAGI::Request->new($scope);

    is($req->cookies, {}, 'empty cookies returns empty hash');
    is($req->cookie('anything'), undef, 'missing returns undef');
};

subtest 'cookies with special characters' => sub {
    my $scope = {
        type    => 'http',
        method  => 'GET',
        headers => [
            ['cookie', 'data=hello%20world; encoded=%3D%26'],
        ],
    };

    my $req = PAGI::Request->new($scope);

    # Cookie::Baker handles URL decoding
    is($req->cookie('data'), 'hello world', 'decodes URL encoding');
    is($req->cookie('encoded'), '=&', 'decodes special characters');
};

done_testing;
