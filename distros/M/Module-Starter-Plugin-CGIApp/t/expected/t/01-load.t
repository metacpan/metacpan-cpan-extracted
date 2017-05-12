#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 2;

BEGIN {

    use_ok('Foo::Bar');

    use_ok('Foo::Baz');

}

diag(

    "Testing Foo::Bar $Foo::Bar::VERSION, Perl $], $^X\n",

    "Testing Foo::Baz $Foo::Baz::VERSION, Perl $], $^X\n",

);
