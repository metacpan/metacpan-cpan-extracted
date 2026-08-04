#!/usr/bin/env perl

use v5.36;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(decode_json);
use Types::Standard qw(Int);

use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(
    title   => 'My API Service',
    version => '2.5.0',
);

$app->get('/items/{id}',
    query   => { page => Int },
    handler => async sub ($c) { return {} }
);

my $pagi_app = $app->to_app;

# Helper to invoke PAGI application asynchronously
async sub request ($path) {
    my @sent;
    my $scope   = { type => 'http', method => 'GET', path => $path, headers => [] };
    my $receive = async sub { return { type => 'http.disconnect' }; };
    my $send    = async sub ($event) { push @sent, $event; };

    await $pagi_app->($scope, $receive, $send);
    return \@sent;
}

subtest 'GET /openapi.json' => sub {
    my $events = request('/openapi.json')->get;

    is $events->[0]{status}, 200, 'Status is 200';

    my $openapi = decode_json($events->[1]{body});
    is $openapi->{openapi}, '3.1.0', 'OpenAPI version is 3.1.0';
    is $openapi->{info}{title}, 'My API Service', 'API Title populated';
    is $openapi->{info}{version}, '2.5.0', 'API Version populated';
    ok exists $openapi->{paths}{'/items/{id}'}{get}, 'Registered path route generated in OpenAPI spec';
};

subtest 'GET /docs (Swagger UI)' => sub {
    my $events = request('/docs')->get;

    is $events->[0]{status}, 200, 'Status is 200';
    like $events->[1]{body}, qr/SwaggerUIBundle/, 'Swagger UI HTML bundle rendered';
};

done_testing;
