#!/usr/bin/perl

use strict;
use HTTP::Tiny;
use Storable qw(freeze);

my $ua = HTTP::Tiny->new();
my $response = $ua->get($ARGV[0]);

print STDOUT freeze($response);
