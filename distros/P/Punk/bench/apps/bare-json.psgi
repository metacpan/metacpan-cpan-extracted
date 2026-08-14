#!/usr/bin/env perl
use strict;
use warnings;

# The ceiling for the JSON row: the identical bytes, encoded once.
my $body    = '{"hello":"world"}';
my @headers = ('Content-Type' => 'application/json',
               'Content-Length' => length $body);

sub { [ 200, \@headers, [$body] ] };
