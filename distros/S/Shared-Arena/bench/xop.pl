#!/usr/bin/perl
# What the op layer is worth, and what it costs everybody else.
#
# Run it twice against the same binary:
#
#     perl -Mblib bench/xop.pl
#     SHARED_ARENA_NO_XOP=1 perl -Mblib bench/xop.pl
#
# The second is the ordinary XSUB path, which is what these doors did before
# the op layer existed. Same code, same machine, same moment: the only thing
# that differs is whether the call sites were rewritten.

use strict;
use warnings;
use blib;
use Shared::Arena;
use Time::HiRes qw(time);

my $N = shift || 2_000_000;

my $arena = Shared::Arena->create(size => 8 << 20);
my $cache = $arena->cache('c', capacity => 4096, entry_size => 256);
my $map   = $arena->map('m', slots => 4096, slot_size => 256);
my $bloom = $arena->bloom('b', capacity => 100_000);
my $hist  = $arena->histogram('h', max => 10_000_000, sigbits => 4);

$cache->set('key', 'value');
$map->store('key', 'value');
$bloom->add('key');

my ($hooked) = Shared::Arena::_xop_stats();
printf "%s  (%d call sites rewritten)\n\n",
    $hooked ? "op path" : "XSUB path (SHARED_ARENA_NO_XOP)", $hooked;

# $code runs the whole loop once, so it is called once to warm the caches and
# the branch predictor and once to be timed. Calling it in a loop would run N
# iterations per warm-up round, which is a benchmark that never finishes.
sub bench {
    my ($name, $code) = @_;
    $code->();
    my $t0 = time;
    $code->();
    my $el = time() - $t0;
    printf "  %-22s %7.1f ns/op   %10.2f M/s\n",
        $name, $el / $N * 1e9, $N / $el / 1e6;
}

bench('cache->get (hit)',  sub { my $v; $v = $cache->get('key')  for 1 .. $N });
bench('cache->get (miss)', sub { my $v; $v = $cache->get('nope') for 1 .. $N });
bench('cache->set',        sub { $cache->set('key', 'value')     for 1 .. $N });
bench('map->fetch',        sub { my $v; $v = $map->fetch('key')  for 1 .. $N });
bench('map->exists',       sub { my $v; $v = $map->exists('key') for 1 .. $N });
bench('map->incr',         sub { my $v; $v = $map->incr('n')     for 1 .. $N });
bench('bloom->check',      sub { my $v; $v = $bloom->check('key')for 1 .. $N });
bench('hist->record',      sub { $hist->record(1234)             for 1 .. $N });

# ---- the tax ---------------------------------------------------------------
#
# Every call site in the program with one of these names runs the guard and is
# declined. This is what that costs the rest of the program, and it is the
# number that decides whether the off switch is worth reaching for.
{
    package Innocent::Bystander;
    sub new { bless {}, shift }
    sub get { 1 }
}

my $other = Innocent::Bystander->new;
print "\n";
bench('unrelated ->get', sub { my $v; $v = $other->get('key') for 1 .. $N });

my (undef, $hits, $miss) = Shared::Arena::_xop_stats();
printf "\n  %d through the door, %d declined\n", $hits, $miss;
