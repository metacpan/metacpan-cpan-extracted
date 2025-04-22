#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  if ($] < 5.010) {
    print "1..0 # Skipped: Perl 5.010 or higher required\n";
    exit 0;
  }
}

use Test::More tests => 1;
use Proc::Forkmap;

my @results = forkmap { $_ * 2 } 1..3;
is_deeply(\@results, [2,4,6], 'basic forking works');