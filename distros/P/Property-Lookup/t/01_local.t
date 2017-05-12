#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 3;
use Property::Lookup::Local;

my %hash = (
    foo => 'bar',
    baz => [ 42 ],
);

local %Property::Lookup::Local::opt = %hash;
my $o = Property::Lookup::Local->new;
is($o->foo, 'bar', 'key [foo]');
is_deeply($o->baz, [ 42 ], 'key [baz]');
is($o->wiz, undef, 'key [wiz] is undef');
