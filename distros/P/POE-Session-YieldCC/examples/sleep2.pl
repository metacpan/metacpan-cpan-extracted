#!/usr/bin/env perl
# Demonstration of the built in sleep method (see the line marked YYY)

use strict;
use warnings;
use POE;
use POE::Session::YieldCC;

POE::Session::YieldCC->create(
  inline_states => {
    _start => \&_start,
    very_slow => \&very_slow,
    progress => \&progress,
  },
);

sub _start {
  $_[KERNEL]->yield('progress');
}

my $n = 0;
sub very_slow {
  my $m = $n;
  print "$m: This is before I sleep\n";
  $_[SESSION]->sleep(5); # YYY
  print "$m: This is after I sleep\n";
}

sub progress {
  print "progress\n";
  $_[KERNEL]->yield('very_slow');
  $_[KERNEL]->delay('progress', 0.5)
    if ++$n < 10;
}

$poe_kernel->run;
exit;
