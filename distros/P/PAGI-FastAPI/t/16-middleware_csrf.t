#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;

use PAGI::FastAPI;
use PAGI::Test::Client;

my $app    = PAGI::FastAPI->new();
my $SECRET = 'test-csrf-secret-12345';

$app->add_middleware('PAGI::Middleware::Session', secret => $SECRET);
$app->enable_csrf(secret => $SECRET);

$app->get('/form', handler => async sub ($c) {
    my $token = $c->csrf_token() // '';
    return $c->html(qq{<input type="hidden" name="csrf" value="$token">});
});

$app->post('/submit', handler => async sub ($c) {
    return { status => 'ok', message => 'Data saved' };
});

my $client = PAGI::Test::Client->new(app => $app->to_pagi);

subtest 'GET /form sets CSRF Cookie' => sub {
    my $res = $client->get('/form');

    is($res->status, 200, 'Returns 200 OK');
    like($res->text, qr/input type="hidden"/, 'Form content rendered');
    ok($client->cookies->{csrf_token}, 'csrf_token cookie is present in client jar');
};

subtest 'POST /submit without CSRF token fails' => sub {
    my $anon_client = PAGI::Test::Client->new( app => $app->to_pagi );

    my $res = $anon_client->post('/submit');
    is($res->status, 403, 'Fails with 403 Forbidden');
};

subtest 'POST /submit with valid CSRF Cookie and Header succeeds' => sub {
    $client->get('/form');

    my $csrf_token = $client->cookies->{csrf_token};

    my $post_res = $client->post('/submit',
        headers => { 'x-csrf-token' => $csrf_token }
    );

    is($post_res->status, 200, 'Succeeds with 200 OK');
    is($post_res->json->{status}, 'ok', 'Response body matches JSON');
};

done_testing;
