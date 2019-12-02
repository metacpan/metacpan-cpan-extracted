#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::ES6 ();
use Promise::ES6::Future ();

my $promise = Promise::ES6->resolve(2);

is(
    Promise::ES6::Future::from_future($promise),
    $promise,
    'input is returned if it’s a promise',
);

SKIP: {
    eval { require Future; die 123; 1 } or skip "Future isn’t available: $@";

    my $goodf = Future->done(123);

    my $promise = Promise::ES6::Future::from_future($goodf);
    isa_ok( $promise, 'Promise::ES6', 'from_future() conversion - done()' );

    my $value;
    $promise->then( sub { $value = shift } );

    is( $value, 123, 'done() future -> resolved promise' );

    #----------------------------------------------------------------------

    my $badf = Future->fail(123);

    $promise = Promise::ES6::Future::from_future($badf);
    isa_ok( $promise, 'Promise::ES6', 'from_future() conversion - fail()' );

    $promise->catch( sub { $value = shift } );

    is( $value, 123, 'fail() future -> rejected promise' );

    #----------------------------------------------------------------------

    is(
        Promise::ES6::Future::to_future($badf),
        $badf,
        'to_future() returns input if given a Future',
    );

    #----------------------------------------------------------------------

    my $goodp = Promise::ES6->resolve(123);

    my $future = Promise::ES6::Future::to_future($goodp);

    $value = $future->get();
    is( $value, 123, 'resolved promise -> done() future' );

    #----------------------------------------------------------------------

    my $badp = Promise::ES6->reject(123);

    $future = Promise::ES6::Future::to_future($badp);

    $value = $future->failure();
    is( $value, 123, 'rejected promise -> fail()ed future' );
}

done_testing();
