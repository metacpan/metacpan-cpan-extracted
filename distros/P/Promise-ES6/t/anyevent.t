#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

my $TEST_COUNT = 5;

plan tests => $TEST_COUNT;

SKIP: {
    eval { require AnyEvent; 1 } or skip "AnyEvent isn’t available: $@", $TEST_COUNT;

    require Promise::ES6::AnyEvent;

    _test_normal();
    _test_die_in_constructor();
    _test_resolve();
    _test_reject();
    _test_die_in_then();
}

sub _test_normal {
    my @things;

    my $promise = Promise::ES6::AnyEvent->new( sub {
        push @things, 'a';
        shift()->(123);
        push @things, 'b';
    } );

    push @things, 'c';

    $promise->then( sub { push @things, shift() } );

    push @things, 'e';

    _resolve($promise);

    push @things, 'f';

    is(
        "@things",
        'a b c e 123 f',
        'then() callback invoked asynchronously',
    );
}

sub _test_resolve {
    my @things;

    my $promise = Promise::ES6::AnyEvent->resolve(123);

    push @things, 'c';

    $promise->then( sub { push @things, 'd' } );

    push @things, 'e';

    _resolve($promise);

    push @things, 'f';

    is(
        "@things",
        'c e d f',
        'then() callback invoked asynchronously',
    );
}

sub _test_reject {
    my @things;

    my $promise = Promise::ES6::AnyEvent->reject(123);

    push @things, 'c';

    $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    _resolve($promise);

    push @things, 'f';

    is(
        "@things",
        'c e 123 f',
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_constructor {
    my @things;

    my $promise = Promise::ES6::AnyEvent->new( sub {
        push @things, 'a';
        die "123\n";
        push @things, 'b';
    } );

    push @things, 'c';

    $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    _resolve($promise);

    push @things, 'f';

    is(
        "@things",
        "a c e 123\n f",
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_then {
    my @things;

    my $promise = Promise::ES6::AnyEvent->resolve(123)->then( sub {
        die "123\n";
    } );

    push @things, 'c';

    $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    _resolve($promise);

    push @things, 'f';

    is(
        "@things",
        "c e 123\n f",
        'catch() callback invoked asynchronously',
    );
}

sub _resolve {
    my $promise = shift;

    my $cv = AnyEvent->condvar();
    $promise->finally($cv);
    $cv->recv();
}
