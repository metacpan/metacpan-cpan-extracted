#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();
# BENCH-PATH: /item/42

# The same cache hit as punk-cache-memory, on the file store.
#
# This is the pair that decides the default, so the two apps are deliberately
# identical apart from the backend: same route, same key, same value, same
# ttl. A hit here is two syscalls - one read for the header and key, one
# pread for the value straight into the buffer - against a hash probe for
# memory, so it costs roughly six microseconds against five nanoseconds.
#
# Measured, 2 workers, a 1KB value: memory lands within a point of punk-dyn
# and this lands at about 46% of it. That number wants reading carefully.
# The route it is measured against does nothing, so six microseconds is
# most of the request; against a route that renders a template or queries a
# database it is a rounding error, and against the query it REPLACES it is
# an enormous win. What the file store buys for the six microseconds is ONE
# copy for the whole pool rather than one per worker, and survival across a
# restart. Choose on that, not on this ratio.
#
# The cache directory is fresh per run, so the first request to each key
# computes and the rest hit. Run with more than one worker: the second
# worker to ask for the key finds what the first one wrote, which is the
# whole property, and the one the memory store cannot have.

my $dir = File::Temp->newdir;

package BenchCacheFile;
use Punk;

cache 'file', dir => "$dir/cache", max_bytes => '64M';

our $COMPUTED = 0;

get '/item/:id' => sub {
    my ($c) = @_;
    my $id = $c->param('id');
    $c->text($c->cache->compute("item:$id", 300, sub {
        $COMPUTED++;
        return join '', map { "row $_: " . ('x' x 40) . "\n" } 1 .. 20;
    }));
};

package main;
# keep the tempdir alive for the server's lifetime
our $KEEP_TEMPDIR = $dir;
BenchCacheFile->to_app;
