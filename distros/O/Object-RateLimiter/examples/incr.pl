#!/usr/bin/env perl
use strict; use warnings FATAL => 'all';

use Object::RateLimiter;

# Count to 100, slowly.
my $ctrl = Object::RateLimiter->new( events => 3, seconds => 5 );
my $x = 0;
while ($x < 100) {
  if (my $delay = $ctrl->delay) {
    print "  ... delayed for $delay seconds ...\n";
    sleep 1
  } else {
    print ++$x, "\n"
  }
}
