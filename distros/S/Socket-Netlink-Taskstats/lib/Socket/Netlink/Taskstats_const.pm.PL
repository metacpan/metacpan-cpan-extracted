#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::H2PM 0.06;

module "Socket::Netlink::Taskstats";

include "sys/socket.h";
include "linux/netlink.h";
include "linux/taskstats.h";

use_export;

constant "TASKSTATS_CMD_$_", name => "CMD_$_" 
   for qw( UNSPEC GET NEW );

constant "TASKSTATS_TYPE_$_", name => "TYPE_$_"
   for qw( PID TGID STATS AGGR_PID AGGR_TGID );

constant "TASKSTATS_CMD_ATTR_$_", name => "CMD_ATTR_$_"
   for qw( PID TGID REGISTER_CPUMASK DEREGISTER_CPUMASK );

structure "struct taskstats",
   arg_style => "hashref",
   no_length_check => 1,
   members => [
      # Version 1
      ( map { $_ => member_numeric } qw( version
         ac_exitcode ac_flag ac_nice
         cpu_count cpu_delay_total
         blkio_count blkio_delay_total
         swapin_count swapin_delay_total
         cpu_run_real_total cpu_run_virtual_total
         ) ),

      # Basic Accounting Fields
      ac_comm => member_strarray,
      ( map { $_ => member_numeric } qw(
         ac_sched ac_uid ac_gid ac_pid ac_ppid
         ac_btime ac_etime ac_utime ac_stime
         ac_minflt ac_majflt ) ),

      # Extended Accounting
      ( map { $_ => member_numeric } qw(
         coremem virtmem hiwater_rss hiwater_vm
         read_char write_char read_syscalls write_syscalls ) ),

      # IO accounting
      ( map { $_ => member_numeric } qw(
         read_bytes write_bytes cancelled_write_bytes
         nvcsw nivcsw
         ac_utimescaled ac_stimescaled cpu_scaled_run_real_total
         freepages_count freepages_delay_total ) ),
   ];

write_output $ARGV[0];
