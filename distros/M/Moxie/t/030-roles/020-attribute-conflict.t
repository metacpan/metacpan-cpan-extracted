#!perl

use strict;
use warnings;

use Test::More;

our (
    $FOO_EXCEPTION,
    $FOO_BAR_EXCEPTION,
    $FOO_BAZ_EXCEPTION,
);

BEGIN {
    package Foo {
        use Moxie;

        has 'foo';
    }
    package Bar {
        use Moxie;

        has 'foo';
    }

    eval q[
        package Foo2 {
            use Moxie;
            with 'Foo';
            has 'foo';
        }
    ];
    $FOO_EXCEPTION = $@;

    eval q[
        package FooBar {
            use Moxie;
            with 'Foo', 'Bar';
        }
    ];
    $FOO_BAR_EXCEPTION = $@;

    eval q[
        package FooBaz {
            use Moxie;

            extends 'Moxie::Object';
               with 'Foo';

            has 'foo';
        }
    ];
    $FOO_BAZ_EXCEPTION = $@;
}

like($FOO_EXCEPTION, qr/^\[CONFLICT\] Role Conflict, cannot compose slot \(foo\) into \(Foo2\) because \(foo\) already exists/, '... got the expected error message (role on role)');
like($FOO_BAR_EXCEPTION, qr/^\[CONFLICT\] There should be no conflicting slots when composing \(Foo, Bar\) into \(FooBar\)/, '... got the expected error message (composite role)');
like($FOO_BAZ_EXCEPTION, qr/^\[CONFLICT\] Role Conflict, cannot compose slot \(foo\) into \(FooBaz\) because \(foo\) already exists/, '... got the expected error message (role on class)');

done_testing;
