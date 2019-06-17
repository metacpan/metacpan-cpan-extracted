#!/usr/bin/env perl
# created on 2018-02-12

use warnings;
use strict;
use v5.11;
use Proc::ProcessTable;
use Time::HiRes;

my @time_spans;
my %cpu_times;

my $ppt        = Proc::ProcessTable->new;
my $start_time = [ Time::HiRes::gettimeofday() ];

my $poll_intervall = int( 2 * 1000 * 1000 );    # 2 sec
my $num_steps      = 2;

local $| = 1;

my $cur_step = 0;
while (1) {


  # current and old index of array.
  # because of modulo, the idcs are rotated.
  # the old index is always the oldest recorded entry
  # this means the entry *after* the current index
  #[ c o . . . ]
  #[ . c o . . ]
  #[ . . c o . ]
  #[ . . . c o ]
  #[ o . . . c ]
  my $cur_idx = $cur_step % $num_steps;
  my $old_idx = ( $cur_step + 1 ) % $num_steps;

  # calc pct cpu per interval:
  # we need seconds since
  # https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat

  my $t = Time::HiRes::tv_interval($start_time);
  my $pt           = $ppt->table;

  my %active_procs = ();
  for my $p (@$pt) {
    # init process info if non-existent
    my $pid = $p->pid;
    $active_procs{$pid} = 1;
    $cpu_times{$pid} //= [];

    $cpu_times{$pid}[$cur_idx] = $p->time;
  }
  $time_spans[$cur_idx] = $t;

  # clean the cputimes hash
  my @killed_procs = grep { !$active_procs{$_} } keys %cpu_times ;
  delete @cpu_times{@killed_procs};

  my $ratio = 0;
  # make sure the array is filled with cpu times
  if ( $cur_step >= $num_steps ) {

    # move cursor to top left of screen
    print "\033[2J";

    printf( "%-5s %s\n", "cpu", "pid");
    # show cpu usage per process
    for my $pid (keys %cpu_times) {
      my $cpu_time   = $cpu_times{$pid};
      my $diff_cpu   = ( $cpu_time->[$cur_idx] - ( $cpu_time->[$old_idx] // 0 ) ) / 1e6;
      my $diff_start = ( $time_spans[$cur_idx] - $time_spans[$old_idx] );
      $ratio = $diff_cpu / $diff_start if ( $diff_start > 0 );
      # show only processes that have a usage > 1%
      printf( "%5.1f %s\n", $ratio * 100, $pid ) if ( $ratio > 0.01 );
    }
  }

  $cur_step++;
  Time::HiRes::usleep($poll_intervall);
}
