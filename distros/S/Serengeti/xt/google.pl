#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib/';
use Serengeti;
use Data::Dumper;

my $b = Serengeti->new();
$b->load('examples/google/google.js');

my $r = $b->perform("search");

print $@, "\n" if $@;
