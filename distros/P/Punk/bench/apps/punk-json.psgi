#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# A small JSON body through the full Punk dispatch: a handler returning a
# hashref is coerced by the C finish path (File::Raw::JSON encode).
package BenchJson;
use Punk;

get '/' => sub { { hello => 'world' } };

package main;
BenchJson->to_app;
