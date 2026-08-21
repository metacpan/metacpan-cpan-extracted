#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /item/42

# A cache HIT on the hot path, through the memory store.
#
# Every request calls compute on a key that is already there, so what is
# measured is the tier and the lookup and nothing else: the key check, the
# undef marker, the LRU probe, the recency touch. The callback runs once, on
# the first request, and its cost does not enter the numbers - which is the
# point, because in a real application that callback is the database query
# this whole component exists to skip.
#
# Read it against three others:
#
#   punk-dyn          the same dispatch with no cache at all - the floor
#   punk-cache-file   the same route on the file store, which is one copy
#                     for the whole pool instead of one per worker
#   punk-db           what a request costs when it does the work instead
#
# Run it with more than one worker. This store lives in ONE process, so a
# prefork pool holds N copies of everything in it, and `workers => 8` with a
# 64M cap is half a gigabyte. The file store is the default for that reason,
# not for speed.

package BenchCacheMemory;
use Punk;

cache 'memory', max_bytes => '64M';

our $COMPUTED = 0;

get '/item/:id' => sub {
    my ($c) = @_;
    my $id = $c->param('id');
    $c->text($c->cache->compute("item:$id", 300, sub {
        $COMPUTED++;
        # roughly a kilobyte, the size of a small rendered fragment or a
        # serialised row: big enough that copying it is not free, small
        # enough that this is not a memcpy benchmark
        return join '', map { "row $_: " . ('x' x 40) . "\n" } 1 .. 20;
    }));
};

package main;
BenchCacheMemory->to_app;
