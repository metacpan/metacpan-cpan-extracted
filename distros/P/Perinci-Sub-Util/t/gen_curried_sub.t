#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Perinci::Sub::Util qw(gen_curried_sub);

package Foo;

our %SPEC;
$SPEC{bar} = {
    v => 1.1,
    summary => 'Orig summary',
    description => 'Orig description',
    args => {
        a => {},
        b => {},
    },
    result_naked => 1,
};
sub bar {
    my %args = @_;
    $args{a} * $args{b};
}

package main;

gen_curried_sub('Foo::bar', {a=>2}, 'Foo::baz');
is(Foo::baz(b=>3), 6);

DONE_TESTING:
done_testing;
