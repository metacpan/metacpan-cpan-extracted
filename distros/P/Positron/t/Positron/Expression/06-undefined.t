#!/usr/bin/perl

# Test semantic hardening
# If the environment does not fit what is asked by the expression,
# we should degenerate gracefully

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dump qw( pp );

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

my $func = sub {
    return scalar(@_);
};

my $obj = bless({ attr => 'myval', delim => '--' }, 'Obj');

# helper function, mostly to avoid repeating the class names
# and environment constructor.
sub t {
    my ($string, $env) = @_;
    my $environment = Positron::Environment->new($env);
    return Positron::Expression::evaluate($string, $environment);
}

lives_and { ok(!defined(t('key', {})));} "Undefined lookup";

lives_and { ok(!defined(t('key.value', {})));} "Undefined dotted lookup";
lives_and { ok(!defined(t('key.value', { key => {} })));} "Undefined dotted lookup, 2nd level";
lives_and { is(t('key.value', { key => [3] }), 3);} "Textual lookup in array";
lives_and { ok(!defined(t('key.value', { key => 'one' })));} "Undefined dotted lookup into scalar";

lives_and { ok(!defined(t('func()', { })));} "Undefined function call";
lives_and { ok(!defined(t('func()', { func => 3 })));} "Function call on scalar";
lives_and { ok(!defined(t('func()', { func => { a => 1}})));} "Function call on hash ref";
lives_and { ok(!defined(t('func()', { func => [2, 3] })));} "Function call on array";
lives_and { is(t('func(not)', { func => $func }), 1);} "Function call with undefined argument";

lives_and { ok(!defined(t('o.func()', { })));} "Method call on undef";
lives_and { ok(!defined(t('o.func()', { o => 'this'} )));} "Method call on scalar";
lives_and { ok(!defined(t('o.func()', { o => {} })));} "Method call on empty hash";
lives_and { ok(!defined(t('o.func()', { o => [] })));} "Method call on empty array";
lives_and { is(t('o.func(not)', { o => { func => $func }}), 1);} "Function call within hash";

lives_and { ok(!defined(t('o.func()', { o => $obj })));} "Call of missing method";
lives_and { ok(!defined(t('o.x', { o => $obj })));} "Call of missing attribute";

done_testing();
