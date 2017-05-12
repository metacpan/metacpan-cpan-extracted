#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok 'Statistics::RankCorrelation' }
diag("Testing Statistics::RankCorrelation $Statistics::RankCorrelation::VERSION, Perl $], $^X");
