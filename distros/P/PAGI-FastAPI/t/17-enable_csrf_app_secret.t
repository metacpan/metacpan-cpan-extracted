#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use Future::AsyncAwait;

use PAGI::FastAPI;
use PAGI::Test::Client;

my $SECRET = 'app-level-secret-12345';

subtest 'enable_csrf() falls back to the secret passed to new()' => sub {
    my $app = PAGI::FastAPI->new(secret => $SECRET);
    $app->add_middleware('PAGI::Middleware::Session', secret => $SECRET);

    is(exception { $app->enable_csrf() }, undef,
        'enable_csrf() does not die when new() was given a secret');

    $app->get('/form', handler => async sub ($c) {
        my $token = $c->csrf_token() // '';
        return $c->html(qq{<input type="hidden" name="csrf" value="$token">});
    });

    $app->post('/submit', handler => async sub ($c) {
        return { status => 'ok' };
    });

    my $client = PAGI::Test::Client->new(app => $app->to_pagi);
    $client->get('/form');
    my $csrf_token = $client->cookies->{csrf_token};

    ok($csrf_token, 'csrf_token cookie present using the app-level secret');

    my $res = $client->post('/submit', headers => { 'x-csrf-token' => $csrf_token });
    is($res->status, 200, 'request validated correctly against the app-level secret');
};

subtest 'enable_csrf(secret => ...) still overrides the app-level secret' => sub {
    my $app = PAGI::FastAPI->new(secret => $SECRET);
    $app->add_middleware('PAGI::Middleware::Session', secret => 'other-session-secret');
    $app->enable_csrf(secret => 'call-level-secret');

    $app->get('/form', handler => async sub ($c) {
        return $c->html($c->csrf_token() // '');
    });
    $app->post('/submit', handler => async sub ($c) { return { status => 'ok' } });

    my $client = PAGI::Test::Client->new(app => $app->to_pagi);
    $client->get('/form');
    my $csrf_token = $client->cookies->{csrf_token};

    my $res = $client->post('/submit', headers => { 'x-csrf-token' => $csrf_token });
    is($res->status, 200, 'call-level secret takes precedence over the app-level one');
};

subtest 'enable_csrf() dies with no secret anywhere' => sub {
    my $app = PAGI::FastAPI->new();

    like(
        exception { $app->enable_csrf() },
        qr/requires 'secret'/,
        'dies with a clear message when no secret is available at all',
    );
};

done_testing;
