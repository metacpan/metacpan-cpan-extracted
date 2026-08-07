#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /api/zz/42

# 50 dynamic routes sharing one first segment - a single bucket the
# Perl router scans with 50 regexes; the benched route sits last.
package BenchDyn50;
use Punk;

for my $i (1 .. 49) {
    get "/api/r$i/:id" => sub { $_[0]->text('x') };
}
get '/api/zz/:id' => sub { $_[0]->text('hello') };

package main;
BenchDyn50->to_app;
