#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use Pinwheel::Context;


my $ctx;

$ctx = Pinwheel::Context::get();
$ctx->{foo} = 'bar';
$ctx = Pinwheel::Context::get();
is($ctx->{foo}, 'bar', 'context preserved across get calls');
Pinwheel::Context::reset();
$ctx = Pinwheel::Context::get();
ok(!defined($ctx->{foo}), 'context is emptied by reset');

Pinwheel::Context::reset();
$ctx = Pinwheel::Context::get();
$ctx->{foo} = 'bar';
$ctx = Pinwheel::Context::get('*main');
is($ctx->{foo}, 'bar', 'get() uses * plus caller\'s package name');

Pinwheel::Context::reset();
$ctx = Pinwheel::Context::get();
$ctx->{abc} = 123;
Pinwheel::Context::set(abc => 'def');
$ctx = Pinwheel::Context::get();
is($ctx->{abc}, 'def', 'set() overwrote the package context');

Pinwheel::Context::reset();
Pinwheel::Context::set('template', abc => 'xyz');
$ctx = Pinwheel::Context::get('template');
is($ctx->{abc}, 'xyz', 'set() overwrote the named context');

Pinwheel::Context::reset();
$ctx = Pinwheel::Context::get('a');
$ctx->{foo} = '123';
$ctx = Pinwheel::Context::get('b');
$ctx->{foo} = '789';
is(Pinwheel::Context::get('a')->{foo}, '123', 'retrieved value from context a');
is(Pinwheel::Context::get('b')->{foo}, '789', 'retrieved value from context b');

Pinwheel::Context::reset();
Pinwheel::Context::set('template', a => 1, b => 2);
Pinwheel::Context::set('template', c => 3, d => 4);
is_deeply(
    Pinwheel::Context::get('template'),
    { c => 3, d => 4 },
    '"set" removes existing values'
);
