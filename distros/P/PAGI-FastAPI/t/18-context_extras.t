#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use PAGI::FastAPI::Context;

subtest 'param() falls back path -> query -> body, in that order' => sub {
    my $ctx = PAGI::FastAPI::Context->new(
        path_params  => { id => 'path-value' },
        query_params => { id => 'query-value', other => 'query-other' },
        body         => { id => 'body-value', body_only => 'body-thing' },
    );

    is $ctx->param('id'), 'path-value',
        'path_param wins over query_param and body when all three are present';
    is $ctx->param('other'), 'query-other',
        'falls back to query_param when no path_param matches';
    is $ctx->param('body_only'), 'body-thing',
        'falls back to body() when neither path nor query match';
    is $ctx->param('missing'), undef,
        'returns undef when the key is absent everywhere';
};

subtest 'csrf_token() resolution order: scope -> pagi_context env -> session' => sub {
    my $ctx_scope = PAGI::FastAPI::Context->new(
        scope => { 'pagi.csrf_token' => 'from-scope' },
    );
    is $ctx_scope->csrf_token, 'from-scope', 'reads token directly from scope';

    my $fake_pagi_context = bless {
        env => { 'pagi.csrf_token' => 'from-env' },
    }, 'PAGI::FastAPI::Test::FakeContext';
    my $ctx_env = PAGI::FastAPI::Context->new(pagi_context => $fake_pagi_context);
    is $ctx_env->csrf_token, 'from-env',
        'falls back to pagi_context->env when scope has no token';

    my $ctx_session = PAGI::FastAPI::Context->new(
        scope => { 'pagi.session' => { csrf_token => 'from-session' } },
    );
    is $ctx_session->csrf_token, 'from-session',
        'falls back to scope session hash as a last resort';

    my $ctx_none = PAGI::FastAPI::Context->new();
    is $ctx_none->csrf_token, undef, 'returns undef when no source has a token';
};

subtest 'csrf_verify() delegates to pagi_context, and requires one' => sub {
    my $ctx_none = PAGI::FastAPI::Context->new();
    like(
        exception { $ctx_none->csrf_verify('any-token') },
        qr/PAGI context is not set/,
        'dies with a clear message when pagi_context is unset',
    );

    my $fake_pagi_context = bless {}, 'PAGI::FastAPI::Test::FakeContext';
    my $ctx = PAGI::FastAPI::Context->new(pagi_context => $fake_pagi_context);
    is $ctx->csrf_verify('the-token'), 'verified:the-token',
        'delegates the token straight through to pagi_context->csrf_verify';
};

subtest 'html() builds a PAGI::FastAPI::Response::HTML with the right shape' => sub {
    my $ctx = PAGI::FastAPI::Context->new();
    my $resp = $ctx->html('<p>hi</p>', status => 202, headers => [['x-a', '1']]);

    isa_ok $resp, 'PAGI::FastAPI::Response::HTML';
    is "$resp", '<p>hi</p>', 'stringifies to the body content';
    is $resp->status, 202, 'status option honored';
    is_deeply $resp->headers, [['x-a', '1']], 'headers option honored';

    my $default_resp = $ctx->html('<p>defaults</p>');
    is $default_resp->status, 200, 'status defaults to 200';
    is_deeply $default_resp->headers, [], 'headers defaults to empty arrayref';
};

subtest 'sse() wraps the generator in a PAGI::FastAPI::Response::SSE' => sub {
    my $ctx = PAGI::FastAPI::Context->new();
    my $generator = sub { };
    my $resp = $ctx->sse($generator);

    isa_ok $resp, 'PAGI::FastAPI::Response::SSE';
};

subtest 'sleep() returns a pending Future::IO future' => sub {
    my $ctx = PAGI::FastAPI::Context->new();
    my $f = $ctx->sleep(0);
    isa_ok $f, 'Future', 'sleep() returns a Future-compatible object';
};

# Minimal stand-in for PAGI's request-scope context object, just enough to
# exercise Context->csrf_token()'s "env" fallback and csrf_verify()'s
# delegation without depending on the full PAGI distribution.
package PAGI::FastAPI::Test::FakeContext;
sub env { return $_[0]->{env} }
sub csrf_verify { my ($self, $token) = @_; return "verified:$token" }

package main;
done_testing;
