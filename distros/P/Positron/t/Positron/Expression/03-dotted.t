#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;
use Positron::Environment;

BEGIN {
    require_ok('Positron::Expression');
}

package
Obj;

sub attr {
    my ($self) = @_;
    return $self->{'attr'};
}

sub dash {
    my ($self, $arg) = @_;
    my $delim = $self->{'delim'};
    return $delim . $arg . $delim;
}

package main;

my $environment = Positron::Environment->new({
    one => 'eins',
    two => [4,5,6],
    i   => 1,
    j   => 'i',
    three => { a => 'z', b => { inner => 'outer', d => 'a'}, },
    c   => 'b',

    add => sub {
        my ($op1, $op2) = @_; 
        return $op1 + $op2;
    },

    mult => sub {
        my ($op1, $op2) = @_; 
        return $op1 * $op2;
    },

    obj => bless({ attr => 'myval', delim => '--' }, 'Obj'),
    long => [4,5,6,7,8,9,10],
});

is(Positron::Expression::evaluate('two.0', $environment), 4, 'Array index 0');
is(Positron::Expression::evaluate('two.1', $environment), 5, 'Array index 1');
is(Positron::Expression::evaluate('two.-1', $environment), 6, 'Array index -1');

is(Positron::Expression::evaluate('three.a', $environment), 'z', 'Hash access');
is(Positron::Expression::evaluate('three.b.inner', $environment), 'outer', 'Double hash access');
is_deeply(Positron::Expression::evaluate('three.b', $environment), { inner => 'outer', d => 'a' }, 'Unfinished hash access');

is(Positron::Expression::evaluate('((7))', $environment), 7, 'Multiple expression evaluation');
is(Positron::Expression::evaluate('two.(i)', $environment), 5, 'Subexpression access');
is(Positron::Expression::evaluate('three.(three.(c).d)', $environment), 'z', 'Subexpression access 2');

is(Positron::Expression::evaluate('long.$i', $environment), 5, 'Key from environment');
is(Positron::Expression::evaluate('long.$$j', $environment), 5, 'Key twice from environment');

is(Positron::Expression::evaluate('add(mult(1.5, 3), -1)', $environment), 3.5, 'Functions');

is(Positron::Expression::evaluate('obj.attr', $environment), 'myval', 'Object attribute');
is(Positron::Expression::evaluate('obj.dash("thing")', $environment), '--thing--', 'Object method');

done_testing();
