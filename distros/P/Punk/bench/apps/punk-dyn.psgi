#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /books/42

# The same hello through a dynamic route: bucket scan + capture.
package BenchDyn;
use Punk;

get '/books/:id' => sub { $_[0]->text('hello') };

package main;
BenchDyn->to_app;
