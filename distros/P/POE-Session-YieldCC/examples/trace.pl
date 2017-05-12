#!/usr/bin/env perl

sub POE::Session::YieldCC::TRACE () { 1 }

use strict;
use warnings;
use POE;
use POE::Session::YieldCC 0.011;

POE::Session::YieldCC->create(
  inline_states => {
    _start => \&_start,
    sync => \&sync,
    paused => \&paused,
    resume => \&resume,
  },
);

sub _start {
  $_[KERNEL]->yield('sync');
}

sub sync {
  print "before\n";
  $_[SESSION]->yieldCC('paused');
  print "after\n";
}

sub paused {
  my $cont = $_[ARG0];
  print "paused\n";
  $_[KERNEL]->yield('resume', $cont);
}

sub resume {
  my $cont = $_[ARG0];
  print "resuming\n";
  $cont->();
  print "done\n";
}

$poe_kernel->run();
