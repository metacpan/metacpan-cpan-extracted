#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 3;
use Property::Lookup::Hash;

my %hash = (
    foo => 'bar',
    baz => [ 42 ],
);

my $o = Property::Lookup::Hash->new(hash => \%hash);
is($o->foo, 'bar', 'key [foo]');
is_deeply($o->baz, [ 42 ], 'key [baz]');
is($o->wiz, undef, 'key [wiz] is undef');
