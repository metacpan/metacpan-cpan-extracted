#!/usr/bin/env perl -w
use strict;
use Test::More tests => 7;

use Perl6ish::Syntax::constant;

my $foo = 42;
{
    constant $foo = "foo";
    is($foo, "foo", 'constant $foo initialized');

    eval ' $foo = "bar"; ';
    ok($@, 'died when modifying constant.');
}
is $foo, 42, 'constant $foo is lexically scoped';

{
    constant @foo = 1,2,3;

    is_deeply(\@foo, [1,2,3], 'constant @foo initialized');

    eval '@foo = 4,5,6';
    ok($@, 'died when modifying constant @foo');
}


{
    constant %foo = ( a => 1, b => 2);

    is_deeply(\%foo, { a => 1, b => 2}, 'constant %foo initialized');

    eval '%foo = (c=>3)';
    ok($@, 'died when modifying constant %foo');
}

