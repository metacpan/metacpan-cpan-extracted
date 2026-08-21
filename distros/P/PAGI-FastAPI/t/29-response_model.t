#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);
use Future::AsyncAwait;
use Types::Standard qw(Str Int ArrayRef);

use PAGI::FastAPI::ResponseModel qw(with_response_model);
use PAGI::FastAPI::Response::Redirect qw(redirect_to);

package MockContext {
    sub new    ($class) { return bless { status => 200 }, $class }
    sub status ($self, @args) { $self->{status} = $args[0] if @args; return $self->{status} }
}

subtest 'HashRef schema: valid data passes through with declared fields only' => sub {
    my $handler = with_response_model(
        { id => Int, name => Str },
        async sub ($c) { return { id => 42, name => 'Alice' } },
    );
    my $c   = MockContext->new;
    my $res = $handler->($c)->get;

    is($res->{id}, 42, 'declared field id present');
    is($res->{name}, 'Alice', 'declared field name present');
    is($c->status, 200, 'status untouched on success');
};

subtest 'HashRef schema: undeclared fields are silently filtered out' => sub {
    my $handler = with_response_model(
        { id => Int, name => Str },
        async sub ($c) {
            return {
                id            => 42,
                name          => 'Alice',
                password_hash => 'super-secret',
                internal_note => 'x'
            };
        },
    );
    my $c   = MockContext->new;
    my $res = $handler->($c)->get;

    is_deeply(
        [sort keys %$res],
        ['id', 'name'],
        'only declared fields survive -- password_hash and internal_note are gone',
    );
};

subtest 'HashRef schema: a field failing its type constraint -> 500, not the raw handler data' => sub {
    my $handler = with_response_model(
        { id => Int, name => Str },
        async sub ($c) { return { id => 'not-an-int', name => 'Bob' } },
    );
    my $c = MockContext->new;

    # ResponseModel's warn() here is intentional, expected server-side
    # diagnostic logging (that's the whole point of it not leaking into the
    # client response) silence it locally just so passing test output
    # isn't cluttered with noise the test already asserts on directly below.
    my $res = do { local $SIG{__WARN__} = sub {}; $handler->($c)->get };

    is($c->status, 500, 'treated as a server bug, not a 4xx client error');
    is($res->{detail}, 'Internal Server Error', 'generic detail returned, not the raw validation error');
    is(exists $res->{id}, '', 'the invalid data itself is not echoed back to the client');
};

subtest 'HashRef schema: handler returning a non-HashRef -> 500' => sub {
    my $handler = with_response_model(
        { id => Int },
        async sub ($c) { return [1, 2, 3] },   # wrong shape entirely
    );
    my $c   = MockContext->new;
    my $res = do { local $SIG{__WARN__} = sub {}; $handler->($c)->get };

    is($c->status, 500, 'non-HashRef return value against a HashRef schema is a server bug');
    is($res->{detail}, 'Internal Server Error', 'generic detail, no internal shape leaked');
};

subtest 'Type::Tiny object schema: validates the whole return value, no filtering' => sub {
    my $handler = with_response_model(
        ArrayRef[Str],
        async sub ($c) { return ['a', 'b', 'c'] },
    );
    my $c   = MockContext->new;
    my $res = $handler->($c)->get;

    is_deeply($res, ['a', 'b', 'c'], 'whole array passed through unfiltered when schema is a single Type::Tiny constraint');
};

subtest 'Type::Tiny object schema: mismatch -> 500' => sub {
    my $handler = with_response_model(
        ArrayRef[Int],
        async sub ($c) { return ['not', 'integers'] },
    );
    my $c   = MockContext->new;
    my $res = do { local $SIG{__WARN__} = sub {}; $handler->($c)->get };

    is($c->status, 500, 'whole-value schema mismatch is a server bug');
    is($res->{detail}, 'Internal Server Error', 'generic detail');
};

subtest 'A Response object (e.g. a redirect) passes through untouched, schema not applied' => sub {
    my $handler = with_response_model(
        { id => Int },   # deliberately a schema this Response object would never satisfy
        async sub ($c) { return redirect_to('/elsewhere') },
    );
    my $c   = MockContext->new;
    my $res = $handler->($c)->get;

    isa_ok($res, 'PAGI::FastAPI::Response::Redirect');
    is($c->status, 200, 'status untouched, ResponseModel did not try to validate a Response object as data');
};

subtest 'An unrecognized $schema shape dies with a clear message' => sub {
    my $handler = with_response_model(
        'not a schema at all',
        async sub ($c) { return { id => 1 } },
    );
    my $c = MockContext->new;

    like(
        exception { $handler->($c)->get },
        qr/must be a Type::Tiny object or a HashRef/,
        'clear programmer-error message rather than a confusing failure deeper in the code',
    );
};

done_testing;
