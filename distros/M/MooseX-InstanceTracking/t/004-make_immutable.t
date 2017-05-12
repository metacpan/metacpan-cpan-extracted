#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

do {
    package Tracked;
    use Moose;
    use MooseX::InstanceTracking;

    __PACKAGE__->meta->make_immutable;
};

my $foo = Tracked->new;
is_deeply([Tracked->meta->instances], [$foo]);

