#!/usr/bin/env perl

use v5.38;
use Test::More;
use Test::Fatal qw(exception);

use PAGI::FastAPI::Depends qw(Depends);

subtest 'Depends() wraps a coderef and exposes it via ->code' => sub {
    my $coderef = sub { 42 };
    my $dep = Depends($coderef);

    isa_ok $dep, 'PAGI::FastAPI::Depends';
    is $dep->code, $coderef, '->code returns the original coderef';
    is $dep->key, undef, '->key defaults to undef';
};

subtest 'Depends() accepts an optional key' => sub {
    my $dep = Depends(sub { 1 }, key => 'db');
    is $dep->key, 'db', '->key returns the option passed to Depends()';
};

subtest 'a non-CODE argument is rejected at construction time' => sub {
    like(
        exception { PAGI::FastAPI::Depends->new(code => 'not a coderef') },
        qr/Depends requires a CODE reference/,
        'dies with a clear message for a string',
    );

    like(
        exception { PAGI::FastAPI::Depends->new(code => { not => 'a coderef' }) },
        qr/Depends requires a CODE reference/,
        'dies with a clear message for a hashref',
    );

    like(
        exception { PAGI::FastAPI::Depends->new() },
        qr/Required parameter 'code' is missing/,
        'dies with a clear message when code is omitted entirely (constructor-level check, not ADJUST)',
    );
};

done_testing;
