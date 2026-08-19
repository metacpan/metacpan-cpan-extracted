#!/usr/bin/env perl

use v5.38;
use Test::More;
use PAGI::FastAPI::Context;

subtest 'Context Instantiation & Basic Attributes' => sub {
    my $scope = {
        type         => 'http',
        method       => 'GET',
        path         => '/users/42',
        query_string => 'verbose=1&sort=asc',
        headers      => [
            ['content-type', 'application/json'],
            ['authorization', 'Bearer secret123'],
            ['user-agent', 'PAGI-Test/1.0'],
        ],
    };

    my $ctx = PAGI::FastAPI::Context->new(
        scope        => $scope,
        query_params => { verbose => 1, sort => 'asc' },
        path_params  => { id => '42' },
        body         => { name => 'Alice', role => 'admin' },
    );

    isa_ok $ctx, 'PAGI::FastAPI::Context';
    is_deeply $ctx->scope, $scope, 'Scope reference preserved';
    is $ctx->status, 200, 'Default response status is 200';
};

subtest 'Path and Query Parameter Access' => sub {
    my $ctx = PAGI::FastAPI::Context->new(
        query_params => { page => 2, filter => 'active' },
        path_params  => { user_id => '101' },
    );

    is $ctx->path_param('user_id'), '101', 'Single path param lookup';
    is $ctx->path_param('non_existent'), undef, 'Missing path param returns undef';
    is_deeply $ctx->path_params, { user_id => '101' }, 'All path params hash returned';

    is $ctx->query_param('page'), 2, 'Single query param lookup';
    is $ctx->query_param('filter'), 'active', 'String query param lookup';
    is $ctx->query_param('missing'), undef, 'Missing query param returns undef';
    is_deeply $ctx->query_params, { page => 2, filter => 'active' }, 'All query params returned';
};

subtest 'Request Body Payload Access' => sub {
    my $body_hash = { item_name => 'Laptop', quantity => 3 };
    my $ctx = PAGI::FastAPI::Context->new(body => $body_hash);

    is_deeply $ctx->body, $body_hash, 'Full body payload returned';
    is $ctx->body('item_name'), 'Laptop', 'Specific key extracted from body hash';
    is $ctx->body('quantity'), 3, 'Numeric field extracted from body hash';
    is $ctx->body('missing_field'), undef, 'Missing body field returns undef';

    my $scalar_ctx = PAGI::FastAPI::Context->new(body => 'raw text payload');
    is $scalar_ctx->body, 'raw text payload', 'Raw non-hash body scalar returned cleanly';
};

subtest 'Request Header Lookup (Case-Insensitive)' => sub {
    my $scope = {
        headers => [
            ['content-type', 'application/json'],
            ['authorization', 'Bearer tok_abc123'],
            ['X-Custom-Header', 'custom_val'],
        ],
    };

    my $ctx = PAGI::FastAPI::Context->new(scope => $scope);

    is $ctx->header('content-type'), 'application/json', 'Lowercase header lookup';
    is $ctx->header('Content-Type'), 'application/json', 'Titlecase header lookup';
    is $ctx->header('AUTHORIZATION'), 'Bearer tok_abc123', 'Uppercase header lookup';
    is $ctx->header('x-custom-header'), 'custom_val', 'Mixed-case header normalized lookup';
    is $ctx->header('x-missing'), undef, 'Missing header returns undef';
};

subtest 'Response Status & Response Headers Modification' => sub {
    my $ctx = PAGI::FastAPI::Context->new();

    # Status mutation
    is $ctx->status(201), 201, 'Setting status code returns set value';
    is $ctx->status, 201, 'Status accessor returns updated status code';

    # Response header management
    $ctx->set_header('X-Frame-Options', 'DENY');
    $ctx->set_header('Content-Type', 'application/json');

    my $res_headers = $ctx->res_headers;
    is ref $res_headers, 'ARRAY', 'res_headers returns arrayref';
    is scalar @$res_headers, 2, 'Two response headers set';
    is_deeply $res_headers->[0], ['X-Frame-Options', 'DENY'], 'First response header pair correct';
    is_deeply $res_headers->[1], ['Content-Type', 'application/json'], 'Second response header pair correct';
};

subtest 'set_header() replaces an existing header of the same name' => sub {
    my $ctx = PAGI::FastAPI::Context->new();

    $ctx->set_header('Content-Type' => 'text/html; charset=utf-8');
    $ctx->set_header('content-type' => 'text/plain; charset=utf-8');

    my $res_headers = $ctx->res_headers;
    is scalar @$res_headers, 1,
        'Second set_header() call replaces rather than duplicates (case-insensitive)';
    is_deeply $res_headers->[0], ['content-type', 'text/plain; charset=utf-8'],
        'Replacement value and casing are the ones from the second call';

    $ctx->set_header('X-A' => '1');
    $ctx->set_header('X-B' => '2');
    $ctx->set_header('X-A' => '3');
    is_deeply $ctx->res_headers,
        [ ['content-type', 'text/plain; charset=utf-8'], ['X-A', '3'], ['X-B', '2'] ],
        'Replacing a header updates it in place without disturbing header order';
};

subtest 'add_header() appends without touching existing headers of the same name' => sub {
    my $ctx = PAGI::FastAPI::Context->new();

    $ctx->add_header('Set-Cookie' => 'session=abc123; Path=/');
    $ctx->add_header('Set-Cookie' => 'theme=dark; Path=/');

    is_deeply $ctx->res_headers,
        [ ['Set-Cookie', 'session=abc123; Path=/'], ['Set-Cookie', 'theme=dark; Path=/'] ],
        'add_header() intentionally allows duplicate header names to accumulate';
};

subtest 'Stash Object Storage (Context Lifecycle Stash)' => sub {
    my $ctx = PAGI::FastAPI::Context->new();

    is ref $ctx->stash, 'HASH', 'Stash defaults to an empty hash reference';
    $ctx->stash->{authenticated_user} = { id => 42, role => 'admin' };
    $ctx->stash->{db_transaction}    = 'active';

    is $ctx->stash->{authenticated_user}{role}, 'admin', 'Stash persists nested data structure';
    is $ctx->stash->{db_transaction}, 'active', 'Stash scalar field retrieved';
};

done_testing;
