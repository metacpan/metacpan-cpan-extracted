#!/usr/bin/env perl

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHarness qw(run_request);

use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Security::OAuth2::PasswordBearer;

subtest 'constructor validation' => sub {
    eval { PAGI::FastAPI::Security::OAuth2::PasswordBearer->new };
    like $@, qr/requires a 'token_url' option/, 'missing token_url dies';
};

subtest 'metadata accessors' => sub {
    my $oauth2 = PAGI::FastAPI::Security::OAuth2::PasswordBearer->new(
        token_url => '/token',
        scopes    => { 'items:read' => 'Read items' },
    );
    is $oauth2->token_url, '/token', 'token_url() returns the configured value';
    is_deeply $oauth2->scopes, { 'items:read' => 'Read items' }, 'scopes() returns the configured value';

    my $oauth2_no_scopes = PAGI::FastAPI::Security::OAuth2::PasswordBearer->new(token_url => '/token');
    is_deeply $oauth2_no_scopes->scopes, {}, 'scopes defaults to an empty HashRef';
};

subtest 'token extraction (same wire format as HTTPBearer)' => sub {
    my $oauth2 = PAGI::FastAPI::Security::OAuth2::PasswordBearer->new(
        token_url => '/token',
        realm     => 'TestRealm',
    );
    my $app = PAGI::FastAPI->new(title => 'OAuth2 Test');
    $app->get('/items',
        dependencies => [ $oauth2->depends(key => 'token') ],
        handler      => async sub ($c) { return { token => $c->stash->{token} } },
    );
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app,
        method  => 'GET',
        path    => '/items',
        headers => [['Authorization', 'Bearer real-token-123']],
    );
    is $status, 200, 'valid Bearer header succeeds';
    is $data->{token}, 'real-token-123', 'token extracted correctly';

    my ($status2, $data2, undef, $headers2) = run_request($pagi_app, method => 'GET', path => '/items');
    is $status2, 401, 'missing token is rejected with 401';
    my ($challenge) = map { $_->[1] } grep { lc($_->[0]) eq 'www-authenticate' } @$headers2;
    is $challenge, 'Bearer realm="TestRealm"', 'a WWW-Authenticate: Bearer challenge with realm is sent';
};

done_testing;
