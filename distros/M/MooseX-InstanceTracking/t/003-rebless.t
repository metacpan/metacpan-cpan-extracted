#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;

do {
    package Tracked;
    use Moose;
    use MooseX::InstanceTracking;

    package MoreTracked;
    use Moose;
    extends 'Tracked';
};

my $foo = Tracked->new;

is_deeply([Tracked->meta->instances],     [$foo]);
is_deeply([MoreTracked->meta->instances], []);

MoreTracked->meta->rebless_instance($foo);

is_deeply([Tracked->meta->instances],     []);
is_deeply([MoreTracked->meta->instances], [$foo]);

is_deeply([Tracked->meta->get_all_instances],     [$foo]);
is_deeply([MoreTracked->meta->get_all_instances], [$foo]);

