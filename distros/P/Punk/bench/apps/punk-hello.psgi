#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# The same response through the full Punk dispatch: static route table,
# context construction, coercion, finalize.
package BenchHello;
use Punk;

get '/' => sub { $_[0]->text('hello') };

package main;
BenchHello->to_app;
