#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

my $TEST_COUNT = 4;

plan tests => $TEST_COUNT;

SKIP: {
    eval { require IO::Async::Loop; 1 } or skip "IO::Async::Loop isn’t available: $@", $TEST_COUNT;

    require Promise::ES6::IOAsync;

    _test_normal();
    _test_die_in_constructor();
    _test_resolve();
    _test_reject();
}

sub _test_normal {
    my @things;

    my $loop = IO::Async::Loop->new();
    my $lguard = Promise::ES6::IOAsync::SET_LOOP($loop);

    my $promise = Promise::ES6::IOAsync->new( sub {
        push @things, 'a';
        shift()->(123);
        push @things, 'b';
    } );

    push @things, 'c';

    $promise->then( sub { push @things, 'd' } );

    push @things, 'e';

    _resolve($loop, $promise);

    push @things, 'f';

    is(
        "@things",
        'a b c e d f',
        'then() callback invoked asynchronously',
    );
}

sub _test_resolve {
    my @things;

    my $loop = IO::Async::Loop->new();
    my $lguard = Promise::ES6::IOAsync::SET_LOOP($loop);

    my $promise = Promise::ES6::IOAsync->resolve(123);

    push @things, 'c';

    $promise->then( sub { push @things, 'd' } );

    push @things, 'e';

    _resolve($loop, $promise);

    push @things, 'f';

    is(
        "@things",
        'c e d f',
        'then() callback invoked asynchronously',
    );
}

sub _test_reject {
    my @things;

    my $loop = IO::Async::Loop->new();
    my $lguard = Promise::ES6::IOAsync::SET_LOOP($loop);

    my $promise = Promise::ES6::IOAsync->reject(123);

    push @things, 'c';

    $promise->catch( sub { push @things, 'd' } );

    push @things, 'e';

    _resolve($loop, $promise);

    push @things, 'f';

    is(
        "@things",
        'c e d f',
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_constructor {
    my @things;

    my $loop = IO::Async::Loop->new();
    my $lguard = Promise::ES6::IOAsync::SET_LOOP($loop);

    my $promise = Promise::ES6::IOAsync->new( sub {
        push @things, 'a';
        die 123;
        push @things, 'b';
    } );

    push @things, 'c';

    $promise->catch( sub { push @things, 'd' } );

    push @things, 'e';

    _resolve($loop, $promise);

    push @things, 'f';

    is(
        "@things",
        'a c e d f',
        'catch() callback invoked asynchronously',
    );
}

sub _resolve {
    my ($loop, $promise) = @_;

    $promise->finally( sub { $loop->stop() } );
    $loop->run();
}
