#!/usr/bin/env perl

use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHarness qw(run_request);

use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Security::HTTPBearer;

my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;

my $app = PAGI::FastAPI->new(title => 'HTTPBearer Test');
$app->get('/protected',
    dependencies => [ $bearer->depends(key => 'token') ],
    handler      => async sub ($c) { return { token => $c->stash->{token} } },
);

my $pagi_app = $app->to_app;

subtest 'valid bearer token' => sub {
    my ($status, $data) = run_request($pagi_app,
        method => 'GET', path => '/protected',
        headers => [['Authorization', 'Bearer abc123']],
    );
    is $status, 200, 'request succeeds with a valid Bearer header';
    is $data->{token}, 'abc123', 'the extracted token is passed through to the handler';
};

subtest 'missing Authorization header' => sub {
    my ($status, $data, undef, $headers) = run_request($pagi_app,
        method => 'GET', path => '/protected',
    );
    is $status, 401, 'missing header is rejected with 401';
    is $data->{detail}, 'Not authenticated', 'a standard detail message is returned';
    my ($challenge) = map { $_->[1] } grep { lc($_->[0]) eq 'www-authenticate' } @$headers;
    is $challenge, 'Bearer realm="Restricted"', 'a WWW-Authenticate: Bearer challenge header is sent';
};

subtest 'malformed Authorization header' => sub {
    for my $bad ('Basic abc123', 'Bearer', 'Bearertoken', 'Bearer  ') {
        my ($status) = run_request($pagi_app,
            method => 'GET', path => '/protected',
            headers => [['Authorization', $bad]],
        );
        is $status, 401, "malformed header '$bad' is rejected with 401";
    }
};

subtest 'auto_error => 0 lets the request through with an undef token' => sub {
    my $optional = PAGI::FastAPI::Security::HTTPBearer->new(auto_error => 0);
    my $app2 = PAGI::FastAPI->new(title => 'Optional Bearer Test');
    $app2->get('/maybe',
        dependencies => [ $optional->depends(key => 'token') ],
        handler      => async sub ($c) { return { has_token => defined $c->stash->{token} ? 1 : 0 } },
    );
    my $pagi_app2 = $app2->to_app;

    my ($status, $data) = run_request($pagi_app2, method => 'GET', path => '/maybe');
    is $status, 200, 'request succeeds even without a token when auto_error is off';
    is $data->{has_token}, 0, 'the handler can see that no token was present';
};

done_testing;
