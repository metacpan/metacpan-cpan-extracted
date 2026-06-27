use strict;
use warnings;
use Test2::V0;
use PAGI::Context;

# raw_send returns the underlying $send coderef on every context type — including
# the SSE context, whose ->send is overridden with the sse.send convenience.

my $send = sub { };

subtest 'SSE context: raw_send bypasses the ->send override' => sub {
    my $ctx = PAGI::Context->new({ type => 'sse' }, sub { }, $send);
    isa_ok $ctx, ['PAGI::Context::SSE'];
    ok $ctx->raw_send == $send, 'raw_send is the underlying send coderef';
    # ->send is the SSE convenience (an override), not the raw coderef — assert the
    # override is actually in place by comparing the resolved method to the base's.
    # (Don't *call* $ctx->send: on SSE it would send an sse.send event.)
    ok $ctx->can('send') != PAGI::Context->can('send'),
        'SSE overrides send, so raw_send reaches past the override';
};

subtest 'HTTP context: raw_send equals the raw send' => sub {
    my $ctx = PAGI::Context->new({ type => 'http', method => 'GET' }, sub { }, $send);
    isa_ok $ctx, ['PAGI::Context::HTTP'];
    ok $ctx->raw_send == $send, 'raw_send is the send coderef';
    ok $ctx->send    == $send, 'HTTP send is already the raw coderef';
};

subtest 'WebSocket context: raw_send equals the raw send' => sub {
    my $ctx = PAGI::Context->new({ type => 'websocket' }, sub { }, $send);
    isa_ok $ctx, ['PAGI::Context::WebSocket'];
    ok $ctx->raw_send == $send, 'raw_send is the send coderef';
};

done_testing;
