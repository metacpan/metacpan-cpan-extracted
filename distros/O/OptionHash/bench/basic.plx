#!/usr/bin/perl

use strict;
use warnings;
use OptionHash;
use Benchmark qw< timethis >;

my %h = (a => 1, b => 2, c => 3);
my $def = ohash_define(keys => [qw< a b c d e f g>]);
timethis( 900000, sub{ ohash_check( $def, \%h)});
