#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Storable ();
use State::Store;
use HAMT::Map;

# Undo, against the two ways it is done without a store: a stack of hash
# copies and a stack of Storable::dclone copies.
#
# First a single step back and forward, on a map with a history behind it:
# for the store, an undo and a redo; for a hash, restoring a copy twice.
# Then the whole of it: 100 changes and 100 undos, from nothing kept.
#
# Usage: perl bench/undo.pl [SIZE]

my $T = -($ENV{STORE_BENCH_SECONDS} || 1);
my $n = shift // 10_000;
print "undo on a map of $n keys; perl $], $^O\n";

my %h = map { ("key$_" => $_) } 1 .. $n;
my $m = HAMT::Map->new(%h);

{
    my $s = State::Store->new($m);
    $s->swap(sub { $_[0]->set(key1 => $_) }) for 1 .. 10;
    my @copies = map { +{ %h, key1 => $_ } } 1 .. 2;
    my %live = %h;
    print "\none step back and one forward\n";
    cmpthese($T, {
        'store undo, redo'     => sub { $s->undo; $s->redo },
        'hash restore, twice'  => sub { %live = %{ $copies[0] }; %live = %{ $copies[1] } },
        'dclone restore, twice' => sub { my $a = Storable::dclone($copies[0]); my $b = Storable::dclone($copies[1]) },
    });
}

print "\n100 changes, then 100 undos\n";
cmpthese($T, {
    'store' => sub {
        my $s = State::Store->new($m);
        $s->swap(sub { $_[0]->set(key1 => $_) }) for 1 .. 100;
        $s->undo for 1 .. 100;
    },
    'stack of hash copies' => sub {
        my %live = %h;
        my @stack;
        for (1 .. 100) { push @stack, { %live }; $live{key1} = $_ }
        %live = %{ pop @stack } for 1 .. 100;
    },
    'stack of dclones' => sub {
        my $live = { %h };
        my @stack;
        for (1 .. 100) { push @stack, Storable::dclone($live); $live->{key1} = $_ }
        $live = pop @stack for 1 .. 100;
    },
});
