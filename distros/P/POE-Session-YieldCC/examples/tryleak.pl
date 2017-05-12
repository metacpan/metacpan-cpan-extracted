#!/usr/bin/env perl

use strict;
use warnings;
use POE;
use POE::Session::YieldCC 0.011;
#use Devel::Leak;

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
    sync => \&sync,
    sig_int => \&sig_int,
  },
);

sub _start {
  $_[KERNEL]->yield('sync');
  $_[KERNEL]->sig('INT' => 'sig_int');
}

sub sig_int {
  $_[HEAP]{stopped}++;
}

my $n = 0;
sub sync {
  $_[KERNEL]->yield('sync') unless $_[HEAP]{stopped};
  my $m = ++$n;
  print "\rloop: $m";
  mysleep(0.5);
  print " finished: $m";
  #$_[HEAP]{stopped} = 1 if $n > 3000; # XXX
}

my $start = time;
print "...";
$|++;
#Devel::Leak::NoteSV(my $handle);
$poe_kernel->run;
print "\nFinished.\n";
#Devel::Leak::CheckSV($handle);
my $lps = $n / (time - $start - 0.5);
warn "lps = $lps\n";
exit;
