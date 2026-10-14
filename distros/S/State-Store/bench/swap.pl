#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use State::Store;
use HAMT::Map;

# One change to a map held in a store, against making the same change by
# hand into a variable: what the store costs on top of HAMT. Then the same
# with watchers and with a validator.
#
# Every store here keeps its last 1,000 steps: a timed loop makes millions
# of changes, and a store that kept them all would be measuring its own
# growth.
#
# Usage: perl bench/swap.pl [SIZE]

my $T = -($ENV{STORE_BENCH_SECONDS} || 1);
my $n = shift // 10_000;
print "one change to a map of $n keys; perl $], $^O\n\n";

my $m0 = HAMT::Map->new(map { ("key$_" => $_) } 1 .. $n);
my $by_hand = $m0;
my %store = map { ($_ => State::Store->new($m0, history => 1000)) }
    'swap', 'set', 'swap, 1 watcher', 'swap, 10 watchers', 'swap, validator';
$store{'swap, 1 watcher'}->watch(sub { });
$store{'swap, 10 watchers'}->watch(sub { }) for 1 .. 10;
$store{'swap, validator'}->validator(sub { 1 });

my $i = 0;
cmpthese($T, {
    'by hand'           => sub { $by_hand = $by_hand->set(key1 => ++$i) },
    'swap'              => sub { $store{'swap'}->swap(sub { $_[0]->set(key1 => ++$i) }) },
    'set'               => sub { my $s = $store{'set'}; $s->set($s->current->set(key1 => ++$i)) },
    'swap, 1 watcher'   => sub { $store{'swap, 1 watcher'}->swap(sub { $_[0]->set(key1 => ++$i) }) },
    'swap, 10 watchers' => sub { $store{'swap, 10 watchers'}->swap(sub { $_[0]->set(key1 => ++$i) }) },
    'swap, validator'   => sub { $store{'swap, validator'}->swap(sub { $_[0]->set(key1 => ++$i) }) },
});
