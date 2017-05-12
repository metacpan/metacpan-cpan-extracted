#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

do {
    package Tracked;
    use Moose;
    use MooseX::InstanceTracking;
};

my $foo = Tracked->new;
my $bar = Tracked->meta->clone_object($foo);

is_deeply([sort Tracked->meta->instances], [sort $foo, $bar]);

