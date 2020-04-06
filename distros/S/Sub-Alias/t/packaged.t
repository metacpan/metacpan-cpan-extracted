#!/usr/bin/env perl -w
use strict;


package TraditionalAlias;

sub foo {
    "the return value of traditional foo";
}

*bar = \&foo;

package FancyAlias;

use Sub::Alias;

sub foo {
    "the return value of fancy foo";
}

alias bar => "foo";

package AwesomeAlias;

use Sub::Alias;

sub foo {
    "the return value of awesome foo";
}

my $v = "bar";
alias $v => "foo";

package main;

sub foo {
    "the return value of main foo";
}

use Test::More tests => 6;

is \&TraditionalAlias::bar, \&TraditionalAlias::foo;
is TraditionalAlias::bar(), TraditionalAlias::foo();

is \&FancyAlias::bar, \&FancyAlias::foo;
is FancyAlias::bar(), FancyAlias::foo();

is \&AwesomeAlias::bar, \&AwesomeAlias::foo;
is AwesomeAlias::bar(), AwesomeAlias::foo();
