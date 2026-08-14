#!/usr/bin/env perl
use strict;
use warnings;

# The ceiling: a hand-rolled PSGI app doing the absolute minimum.
my $body    = 'hello';
my @headers = ('Content-Type' => 'text/plain', 'Content-Length' => 5);

sub { [ 200, \@headers, [$body] ] };
