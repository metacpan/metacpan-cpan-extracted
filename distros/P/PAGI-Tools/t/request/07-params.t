#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use lib 'lib';
use PAGI::Request;

subtest 'params from scope' => sub {
    my $scope = {
        type    => 'http',
        method  => 'GET',
        path    => '/users/42/posts/100',
        headers => [],
        # Router sets path_params directly in scope (router-agnostic)
        path_params => { user_id => '42', post_id => '100' },
        'pagi.router' => {
            route  => '/users/:user_id/posts/:post_id',
        },
    };

    my $req = PAGI::Request->new($scope);

    is($req->path_params, { user_id => '42', post_id => '100' }, 'params returns hashref');
    is($req->path_param('user_id'), '42', 'param() gets single value');
    is($req->path_param('post_id'), '100', 'param() another value');

    # path_param is strict by default - dies on missing key
    like(
        dies { $req->path_param('missing') },
        qr/path_param 'missing' not found/,
        'missing param dies (strict by default)'
    );
    is($req->path_param('missing', strict => 0), undef, 'strict => 0 returns undef');
};

subtest 'params set via scope' => sub {
    # Simulating how router sets path_params in scope before handler is called
    my $scope = {
        type => 'http',
        method => 'GET',
        headers => [],
        path_params => { id => '123', slug => 'hello-world' },
    };
    my $req = PAGI::Request->new($scope);

    is($req->path_param('id'), '123', 'param from scope');
    is($req->path_param('slug'), 'hello-world', 'another param');
};

subtest 'no params' => sub {
    my $scope = { type => 'http', method => 'GET', headers => [] };
    my $req = PAGI::Request->new($scope);

    is($req->path_params, {}, 'empty params by default');

    # path_param dies when no path params set (strict by default)
    like(
        dies { $req->path_param('anything') },
        qr/path_param 'anything' not found.*No path params set/,
        'path_param dies when no params set'
    );
    is($req->path_param('anything', strict => 0), undef, 'strict => 0 returns undef');
};

subtest 'path_param does not include query params' => sub {
    my $scope = {
        type => 'http',
        method => 'GET',
        headers => [],
        query_string => 'foo=bar&baz=qux',
        path_params => { id => '42' },
    };
    my $req = PAGI::Request->new($scope);

    # path_param only returns path params, not query params
    is($req->path_param('id'), '42', 'path param exists');

    # path_param dies for missing keys (doesn't fall back to query params)
    like(
        dies { $req->path_param('foo') },
        qr/path_param 'foo' not found/,
        'query param not returned by path_param (dies)'
    );
    like(
        dies { $req->path_param('baz') },
        qr/path_param 'baz' not found/,
        'path_param does not fall back to query params'
    );

    # Query params should be accessed via $req->query_param('foo')
    is($req->query_param('foo'), 'bar', 'query() returns query param');
    is($req->query_param('baz'), 'qux', 'query() returns another query param');
};

subtest 'path_params strict option (per-call)' => sub {
    # path_params(strict => 1) dies when no router populated the scope.
    # The default is non-strict: return an empty hashref. This mirrors the
    # per-call strict option on path_param.

    my $scope_no_params = { type => 'http', method => 'GET', headers => [] };
    my $req = PAGI::Request->new($scope_no_params);

    # Non-strict (default): empty hashref, no death
    is($req->path_params, {}, 'default: path_params returns empty hashref');
    is($req->path_params(strict => 0), {}, 'strict => 0: returns empty hashref');

    # Strict: dies when path_params not in scope
    like(
        dies { $req->path_params(strict => 1) },
        qr/path_params not set in scope/,
        'strict => 1: path_params dies when not set'
    );

    # Unknown option is rejected
    like(
        dies { $req->path_params(bogus => 1) },
        qr/Unknown options to path_params/,
        'path_params rejects unknown options'
    );

    # path_param (singular) still dies for a missing key when no router ran,
    # naming the key it could not find.
    like(
        dies { $req->path_param('id') },
        qr/path_param 'id' not found/,
        'path_param dies for missing key when no router set'
    );
    is($req->path_param('id', strict => 0), undef, 'path_param(strict => 0): returns undef');

    # When the scope HAS path_params, both strict modes return them
    my $scope_with_params = {
        type => 'http', method => 'GET', headers => [],
        path_params => { id => '42' },
    };
    $req = PAGI::Request->new($scope_with_params);

    is($req->path_params, { id => '42' }, 'path_params returns scope params');
    is($req->path_params(strict => 1), { id => '42' }, 'strict => 1: returns scope params when set');
    is($req->path_param('id'), '42', 'path_param returns value when set');
};

done_testing;
