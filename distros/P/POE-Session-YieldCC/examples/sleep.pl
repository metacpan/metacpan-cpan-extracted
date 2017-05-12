#!/usr/bin/env perl
# This example shows how to implement sleeping yourself
# Please see sleep2.pl to see how to use the built in version

use strict;
use warnings;
use POE;
use POE::Session::YieldCC 0.012;

sub before_sleep {
  my ($cont, $args) = @_[ARG0, ARG1];
  $_[KERNEL]->delay("$_[STATE]_after", $args->[0], $cont, $_[STATE]);
}

sub after_sleep {
  $_[ARG0]->();
  $_[KERNEL]->state($_[ARG1]);
  $_[KERNEL]->state($_[ARG1] . "_after");
}

my $_uniq = 0;
sub mysleep {
  my $time = shift;
  my $session = $poe_kernel->get_active_session;
  die "oops, no session" unless $session;

  $_uniq++;
  $poe_kernel->state("mysleep_${_uniq}" => \&before_sleep);
  $poe_kernel->state("mysleep_${_uniq}_after" => \&after_sleep);
  $session->yieldCC("mysleep_${_uniq}", $time);
}

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
  mysleep(5);
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
