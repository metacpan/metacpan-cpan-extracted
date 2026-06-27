use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(refaddr);
use PAGI::Context;

sub ctx_of {
    my $type = shift;
    return PAGI::Context->new({ type => $type, headers => [], path => '/' },
                              sub { }, sub { });
}

subtest 'assert_http passes on http, croaks on the others' => sub {
    my $c = ctx_of('http');
    is(refaddr($c->assert_http), refaddr($c), 'assert_http returns the same context (chainable)');
    like(dies { $c->assert_websocket }, qr/expected a 'websocket' context, got a 'http' context/,
        'assert_websocket croaks on an http context');
    like(dies { $c->assert_sse }, qr/expected a 'sse' context/, 'assert_sse croaks on http');
};

subtest 'assert_websocket' => sub {
    my $c = ctx_of('websocket');
    isa_ok($c, ['PAGI::Context::WebSocket'], 'polymorphic new gave a WS context');
    is(refaddr($c->assert_websocket), refaddr($c), 'assert_websocket passes on ws');
    like(dies { $c->assert_http }, qr/expected a 'http' context, got a 'websocket' context/,
        'assert_http croaks on ws');
};

subtest 'assert_sse' => sub {
    my $c = ctx_of('sse');
    isa_ok($c, ['PAGI::Context::SSE'], 'polymorphic new gave an SSE context');
    is(refaddr($c->assert_sse), refaddr($c), 'assert_sse passes on sse');
};

subtest 'reads as a one-line gate chained off new' => sub {
    my $c = PAGI::Context->new({ type => 'http', headers => [], path => '/' }, sub { }, sub { })
        ->assert_http;
    isa_ok($c, ['PAGI::Context::HTTP'], 'gate returns the typed http context');
};

done_testing;
