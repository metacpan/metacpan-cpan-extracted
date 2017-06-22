#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use MOP;

our $EXCEPTION;

BEGIN {

package Foo {
    use Moxie;

    sub bar;
}

eval q[
    package Bar::Incorrect {
        use Moxie;

        extends 'Moxie::Object';
           with 'Foo';

        has 'bar';
    }
];
$EXCEPTION = $@;

}

like(
    $EXCEPTION,
    qr/^\[CONFLICT\] There should be no required methods when composing \(Foo\) into \(Bar\:\:Incorrect\) but instead we found \(bar\)/,
    '... this code failed to compile correctly'
);

done_testing;
