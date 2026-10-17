#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /api/zz/42

# 50 dynamic routes sharing one first segment, so the C router's linear scan
# over typed records does 50 segment comparisons before the benched route,
# which sits last: the worst case the scan has (about 0.3 us over punk-dyn).
package BenchDyn50;
use Punk;

for my $i (1 .. 49) {
    get "/api/r$i/:id" => sub { $_[0]->text('x') };
}
get '/api/zz/:id' => sub { $_[0]->text('hello') };

package main;
BenchDyn50->to_app;
