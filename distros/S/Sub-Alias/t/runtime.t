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

subtest "Multi-line" => sub {
    my $baz = "BAZ";

    alias $baz,
        'foo';

    is \&BAZ, \&foo;
};
