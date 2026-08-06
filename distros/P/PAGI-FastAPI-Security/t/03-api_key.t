#!/usr/bin/env perl

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHarness qw(run_request);

use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Security::APIKey;

subtest 'constructor validation' => sub {
    eval { PAGI::FastAPI::Security::APIKey->new(name => 'X-API-Key') };
    like $@, qr/requires an 'in' option/, 'missing "in" option dies';

    eval { PAGI::FastAPI::Security::APIKey->new(in => 'header') };
    like $@, qr/requires a 'name' option/, 'missing "name" option dies';

    eval { PAGI::FastAPI::Security::APIKey->new(in => 'nowhere', name => 'x') };
    like $@, qr/requires an 'in' option/, 'invalid "in" value dies';
};

subtest 'header-based API key' => sub {
    my $scheme = PAGI::FastAPI::Security::APIKey->new(in => 'header', name => 'X-API-Key');
    my $app = PAGI::FastAPI->new(title => 'APIKey Header Test');
    $app->get('/data',
        dependencies => [ $scheme->depends(key => 'api_key') ],
        handler      => async sub ($c) { return { key => $c->stash->{api_key} } },
    );
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/data',
        headers => [['X-API-Key', 'sekrit-key']],
    );
    is $status, 200, 'request succeeds with the header present';
    is $data->{key}, 'sekrit-key', 'key extracted from the header';

    my ($status2, $data2) = run_request($pagi_app, method => 'GET', path => '/data');
    is $status2, 403, 'missing header is rejected with 403 (no challenge scheme for API keys)';
    is $data2->{detail}, 'Not authenticated', 'standard detail message';
};

subtest 'query-based API key (works without route-level query declaration)' => sub {
    my $scheme = PAGI::FastAPI::Security::APIKey->new(in => 'query', name => 'api_key');
    my $app = PAGI::FastAPI->new(title => 'APIKey Query Test');
    $app->get('/data',
        dependencies => [ $scheme->depends(key => 'api_key') ],
        handler      => async sub ($c) { return { key => $c->stash->{api_key} } },
    );
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/data', query_string => 'api_key=hello%20world%2Bfoo',
    );
    is $status, 200, 'request succeeds with the query param present';
    is $data->{key}, 'hello world+foo', 'key is extracted AND percent-decoded';

    my ($status2) = run_request($pagi_app, method => 'GET', path => '/data', query_string => 'other=1');
    is $status2, 403, 'missing query param is rejected with 403';
};

subtest 'cookie-based API key' => sub {
    my $scheme = PAGI::FastAPI::Security::APIKey->new(in => 'cookie', name => 'api_key');
    my $app = PAGI::FastAPI->new(title => 'APIKey Cookie Test');
    $app->get('/data',
        dependencies => [ $scheme->depends(key => 'api_key') ],
        handler      => async sub ($c) { return { key => $c->stash->{api_key} } },
    );
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/data',
        headers => [['Cookie', 'session=abc; api_key=cookie-key; other=xyz']],
    );
    is $status, 200, 'request succeeds when the cookie is present among several cookies';
    is $data->{key}, 'cookie-key', 'the correct cookie value is extracted';

    my ($status2) = run_request($pagi_app,
        method => 'GET', path => '/data',
        headers => [['Cookie', 'session=abc; other=xyz']],
    );
    is $status2, 403, 'missing cookie is rejected with 403';
};

subtest 'auto_error => 0' => sub {
    my $scheme = PAGI::FastAPI::Security::APIKey->new(in => 'header', name => 'X-API-Key', auto_error => 0);
    my $app = PAGI::FastAPI->new(title => 'APIKey Optional Test');
    $app->get('/data',
        dependencies => [ $scheme->depends(key => 'api_key') ],
        handler      => async sub ($c) { return { has_key => defined $c->stash->{api_key} ? 1 : 0 } },
    );
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app, method => 'GET', path => '/data');
    is $status, 200, 'request succeeds even without the key when auto_error is off';
    is $data->{has_key}, 0, 'handler can see no key was present';
};

done_testing;
