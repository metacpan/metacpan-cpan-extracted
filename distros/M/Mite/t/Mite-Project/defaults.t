#!/usr/bin/perl

use lib 't/lib';
use Test::Mite with_recommends => 1;

tests "undef default" => sub {
    mite_load <<'CODE';
package Foo;
use Mite::Shim;

has foo =>
    is      => 'rw',
    default => undef;

1;
CODE

    my $obj = new_ok "Foo";
    is $obj->foo, undef;
};

done_testing;
