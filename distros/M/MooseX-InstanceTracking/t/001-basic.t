#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

my $collected = 0;
do {
    package Tracked;
    use Moose;
    use MooseX::InstanceTracking;

    sub DEMOLISH { ++$collected }
};

do {
    my $foo = Tracked->new;
    is_deeply([Tracked->meta->instances], [$foo]);
};

is_deeply([Tracked->meta->instances], []);
is($collected, 1, "collected the instance");

my ($bar, $baz) = (Tracked->new, Tracked->new);
is_deeply([sort Tracked->meta->instances], [sort $bar, $baz]);

