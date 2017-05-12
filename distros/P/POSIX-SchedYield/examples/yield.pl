#!/usr/bin/perl -w

use POSIX::SchedYield qw(sched_yield);

sched_yield();
