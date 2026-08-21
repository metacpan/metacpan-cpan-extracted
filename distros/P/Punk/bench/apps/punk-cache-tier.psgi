#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();
# BENCH-PATH: /item/42

# The same cache hit again, on the file store with a memory tier in front.
#
# Read it against its two siblings, which are identical apart from the cache
# declaration: punk-cache-file is this store without the tier, and
# punk-cache-memory is the ceiling a tier can reach. This one should sit
# beside MEMORY, not beside file - if it does not, the tier is not being hit
# and something upstream of this app is wrong.
#
# The tier exists because a file hit is 7.2us and 6.2us of that is the open()
# syscall. Nothing around the syscall was worth tuning, so the only way the
# hit gets faster is not to open the file at all.
#
# WHAT IT COSTS, WHICH THE NUMBER WILL NOT SHOW YOU. The file store on its own
# is instantly consistent across the pool: one copy, and a write is visible
# the moment it lands. A tier is a per-worker copy, so this app is eventually
# consistent instead - bounded by memory_ttl, and by the bus delivering the
# invalidation. It also costs `memory` PER WORKER, which is the arithmetic
# that made the file store the default in the first place.
#
# That is why the tier is opt-in and why this is a third app rather than a
# change to the second one.

my $dir = File::Temp->newdir;

package BenchCacheTier;
use Punk;

cache 'file', dir        => "$dir/cache",
              max_bytes  => '64M',
              memory     => '64M',
              memory_ttl => 30;

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
BenchCacheTier->to_app;
