#!/usr/bin/perl

use strict;
use warnings;

sub foo {
    eval {
        die "bar";
    };
}

foo();

1;