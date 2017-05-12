#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

tests "Many classes, one file" => sub {
    mite_load(<<'CODE');
package Foo;
use Mite::Shim;
has 'things' =>
    is      => 'rw',
    default => 42;

package Bar;
use Mite::Shim;
extends 'Foo';
has 'stuff' =>
    is      => 'rw',
    default => 23;
1;
CODE

    my $foo = new_ok 'Foo';
    my $bar = new_ok 'Bar';

    is $foo->things, 42;
    is $bar->stuff, 23;
    is $bar->things, 42;
};

done_testing();
