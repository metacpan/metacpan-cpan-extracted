#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use State::Store;
use HAMT::Map;

# 100 changes in one transaction, against the same 100 made one by one: with
# no watcher, and with one, where a transaction tells it once and not 100
# times. Every store keeps its last 1,000 steps.
#
# Usage: perl bench/txn.pl

my $T = -($ENV{STORE_BENCH_SECONDS} || 1);
print "100 changes to a map of 10,000 keys; perl $], $^O\n";
my $m = HAMT::Map->new(map { ("key$_" => $_) } 1 .. 10_000);

for my $watchers (0, 1) {
    my $one = State::Store->new($m, history => 1000);
    my $all = State::Store->new($m, history => 1000);
    for my $s ($one, $all) { $s->watch(sub { }) for 1 .. $watchers }
    my $i = 0;
    print "\nwith $watchers watcher" . ($watchers == 1 ? '' : 's') . "\n";
    cmpthese($T, {
        'one by one'         => sub { $all->swap(sub { $_[0]->set(key1 => ++$i) }) for 1 .. 100 },
        'in a transaction'   => sub { $one->txn(sub { $one->swap(sub { $_[0]->set(key1 => ++$i) }) for 1 .. 100 }) },
    });
}
