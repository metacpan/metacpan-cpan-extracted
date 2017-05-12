#!/usr/bin/env perl -w
use strict;
use Test::More tests => 8;

use Sub::Alias;

sub foo {
    die "wrong, should not call foo when defining alias.\n";
    "the return value of foo"
}

alias
    'bar2', 'foo';

alias
    'bar3'
    => 'foo';

alias bar4
    => 'foo';

alias
    'bar5',
    'foo';

# is *bar1, *foo;
is *bar2, *foo;
is *bar3, *foo;
is *bar4, *foo;
is *bar5, *foo;

is \&bar2, \&foo;
is \&bar3, \&foo;
is \&bar4, \&foo;
is \&bar5, \&foo;



