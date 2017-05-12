#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Sub::Alias;

sub foo {
    die "wrong, should not call foo when defining alias.\n";
    "foooooo"
}

alias 'fuu' => \&foo;

# is *fuu, *foo;
is \&fuu, \&foo;

