#!/usr/bin/env perl -w
use strict;
use Test::More tests => 4;

use Sub::Alias;

sub foo {
    my $m = shift;

    alias $m => \&foo;
}

foo("bar");
foo("baz");

is \&bar, \&foo;
is \&baz, \&foo;

my $bar = "BAR";
alias $bar => 'foo';
is \&BAR, \&foo;

{
    local $TODO = "multi-line alias statements at runtime.";
    my $baz = "BAZ";

    alias $baz,
        'foo';

    is \&BAZ, \&foo;
}
