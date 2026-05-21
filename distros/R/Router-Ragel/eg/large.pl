#!/usr/bin/env perl
# Compile N routes and bench match throughput.
# Usage: perl eg/large.pl [N] (default N=1000)
use strict;
use warnings;
use Time::HiRes qw(time);
use Benchmark qw(timethis);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

my $n = $ARGV[0] // 1000;

my $r = Router::Ragel->new;
$r->add("/r$_/:id<int>/:slug", "h$_") for 1..$n;

my $t0 = time;
$r->compile;
printf "compiled %d routes in %.2fs\n", $n, time - $t0;

my $hit = "/r" . int($n / 2) . "/42/widget";
my $miss = "/no/such/path";

print "\nhit ($hit):\n";
my $b = timethis(-2, sub { Router::Ragel::match($r, $hit) }, 'hit', 'noc');
printf "%.0f matches/sec\n", $b->iters / ($b->cpu_a || 1);

print "miss ($miss):\n";
$b = timethis(-2, sub { Router::Ragel::match($r, $miss) }, 'miss', 'noc');
printf "%.0f matches/sec\n", $b->iters / ($b->cpu_a || 1);
