#!/usr/bin/env perl -w
use strict;
use Test::More tests => 4;

use Sub::Alias;

sub foo {
    die "wrong, should not call foo when defining alias.\n";
    "foooooo"
}

alias fuu1 => \&foo;
alias 'fuu2' => \&foo;
alias 'fuu3', \&foo;
alias 'fuu4', \&foo;

is \&fuu1, \&foo;
is \&fuu2, \&foo;
is \&fuu3, \&foo;
is \&fuu4, \&foo;
