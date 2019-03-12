#!/usr/bin/perl
package Proc::Stat;

use strict;
use diagnostics;

use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub DESTROY {};		# make modperl happy

=head1 NAME

Proc::Stat

=head1 SYNOPSIS

  use Proc::Stat;

  my $ps	= new Proc::Stat;
  my $psj	= $ut->jiffy();
  my $ut	= $ps->uptime();
  my $stat	= $ps->stat($pid0,$pid1,$pid...);
  my $usage	= $ut->usage($pid0,$pid1,$pid...);
  my $prep	= $ps->prepare($pid0,$pid1,...);  
  my $percent	= $prep->loadavg($pid0,$pid1,...);
  my $percent	= $ps->loadkid($pid0,$pid1,...);



=head1 DESCRIPTION

This module reads /proc/uptime and /proc/{pid}/stat to gather statistics
and calculate cpu utilization of designatated PID's with or without children

All the data from /proc/[pid]/stat is returned attached to the method pointer, see list below by index (-1).

Calculates processor JIFFY

Calculate realtime load average of a particular job(pid) or list of job(pid's)

Real load Balancing using $ps->loadavg(pid list) below.

=over 4

=item * $ref = new Proc::Stat;

Return a method pointer

=cut

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  return bless {}, $class;
}

=item * $psj = $ut->jiffy();

Returns a blessed reference with a scalar representing the best guess
of the SC_CLK_TCK or USR_HZ for this system based on proc data

  input:	[optional] method pointer from "uptime"
  returns:

  $psj->{
	jiffy => number
  };

Returns 9999 on error and sets $@

Will call $ps->uptime() if not a $ut->method pointer

NOTE: known to be supported on LINUX, requires the /proc/filesystem

=cut

my @jiftab = (	# bounded table of known common jiffy values
	24,
	48,
	96,
	100,	# linux
	192,
	250,	# linux
	300,	# linux
	384,
	768,
	1000,	# linux
	1536,
	9999	# oops
);

sub jiffy {
  my $ps = shift;
  $ps = $ps->uptime() unless exists $ps->{current};
  my $f;
  open($f,'<','/proc/stat') or return undef;
  my $stat = <$f>;
  close $f;
#				      user    nice     sys    idle
  return undef unless $stat =~ /cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/i;
  my $idleticks = $4;				# total idle ticks
  my $idlesecs  = $ps->{current}->{idle};	# total idle seconds since boot
  my $uhz = $idleticks / $idlesecs;		# should be jiffy withing a nats eyelash
  my $i;
  for ($i = 0;$i < $#jiftab -1;$i++) {		# iterate to tablen -1
    if ($uhz < $jiftab[$i+1]) {
      my $diflo = $uhz - $jiftab[$i];
      my $difhi = $jiftab[$i+1] - $uhz;
      if ($diflo < $difhi) {			# choose closest boundry
	$uhz = $jiftab[$i];
      } else {
	$uhz = $jiftab[$i+1];
      }
      last;
    }
  }
  if ($i == @jiftab) {
	eval {
	  die "jiffie overflow, unknown HIGH clock rate '$uhz'";
	};
	$uhz = $jiftab[$i];;
  }
  $ps->{jiffy} = $uhz;
  $ps;
}



=item * $ut = $ps->uptime();

  input:	none
  returns:	blessed method pointer of the form

  $ut->{	# seconds and fractions
	current	=> {
		uptime	=> uptime of the system,
		idle	=> time spent in idle
	},
	last	=> {
		uptime	=> 0,
		idle	=> 0,
	}

  };

Subsequent calls will return:

  $ut->{	# seconds and fractions
	current	=> {
		uptime	=> uptime of the system,
		idle	=> time spent in idle
	},
	last	=> {
		uptime	=> previous uptime,
		idle	=> previous idle
	}
  };

Returns undef on error

=cut

sub uptime {
  my $ps = shift;
  my $f;
  if (exists $ps->{last}) {
    if (exists $ps->{current}) {
      @{$ps->{last}}{qw(uptime idle)} = @{$ps->{current}}{qw(uptime idle)};
    } else {
      @{$ps->{last}}{qw(uptime idle)} = (0,0);
    }
  } else {
    @{$ps->{last}}{qw(uptime idle)} = (0,0);
  }
  open ($f,'<','/proc/uptime') or return undef;
  @{$ps->{current}}{qw(uptime idle)} = split /\s+/, (<$f>);
  close $f;
  return $ps->{current}->{uptime} ? $ps : undef;
}

=item * = $stat = $ps->stat($pid0,$pid1,...);

Returns pointer to an array of values for each proc/PID/stat as defined in L<man proc(5)>

  input:	an array of PID's or ref to array of PID's
  returns:	blessed method pointer of the form

  $stat->{
	curstat => {
		$pid0 => [stat array],
		$pid1 => [stat array],
		...
	},
	lastat	=> {
		$pid0 => [],
		$pid1 => [],
		...
	}
};

Subsequent calls will return:

  $stat->{
	curstat => {
		$pid0 => [stat array],
		$pid1 => [stat array],
		...
	},
	lastat	=> {
		$pid0 => [],
		$pid1 => [],
		...
	}
};

Returns undef on error. 

Will not populate PID's missing from /proc

May be chained. i.e.

  $stat = $ps->uptime()->stat($pid,...);

=cut

sub stat {
  my $ps = shift;
  my $pids = ref $_[0] ? $_[0] : [@_];
  return undef unless @{$pids};

  foreach my $pid (@{$pids}) {
    my $f;
    next unless open($f,'<',"/proc/$pid/stat");
    if (exists $ps->{lastat}->{$pid}) {
      @{$ps->{lastat}->{$pid}} = @{$ps->{curstat}->{$pid}};
    } else {
      $ps->{lastat}->{$pid} = [];
    }
    @{$ps->{curstat}->{$pid}} = split /\s+/, (<$f>);
    close $f;
  }
  $ps;
}

=item * $usage = $ut->usage();

Calculate the CPU usage from data in a chained uptime, stat call pair

i.e	$usage = $ps->uptime()->jiffy()->stats(pid0,pid1,...)->usage();
		in any order, only "stats" required

	calculates differences for
		utime
		stime
		cutime
		cstime

First call for a particular PID will return the absolute value since job start

Subsequent calls for a particular PID will return the difference from the last call

  input:	an array of PID's or ref to array of PID's
  returns: 	additional fields added to "uptime" and "stats"

  $usage->{
	utime	=> {
		$pid0 => diff,
		$pid1 => diff,
		...	etc...
	},
	stime	=> {
		$pid0 => diff,
		$pid1 => diff,
		...	etc...
	},
	cutime	=> {
		$pid0 => diff,
		$pid1 => diff,
		...	etc...
	},
	cstime	=> {
		$pid0 => diff,
		$pid1 => diff,
		...	etc...
	}
  };

Returns undef on error

=cut

my %times = (
	utime	=> 13,
	stime	=> 14,
	cutime	=> 15,
	cstime	=> 16 
);

sub usage {
  my $ps = shift;
  return undef unless exists $ps->{curstat} && keys %{$ps->{curstat}};
  foreach my $pid (keys %{$ps->{curstat}}) {
    foreach (keys %times) {
      my $idx = $times{$_};
      $ps->{$_}->{$pid} = $ps->{curstat}->{$pid}->[$idx] - ($ps->{lastat}->{$pid}->[$idx] || 0);
    }
  }
  $ps;
}

=item * $prep = $ps->prepare($pid0,$pid1,...);

Collect information about jobs(pids) needed to calculate cpu utilization.
Call repetitively at intervals.

  input:	an array of PID's or ref to array of PID's
  returns:	a blessed hash structure containing data

This is a wrapper around:

	$ps->uptime()->stat($pids);

...and will conditionally call ->jiffy if it is not populated

=cut

sub prepare {
  my $ps = shift;
  my $pids = ref $_[0] ? $_[0] : [@_];
  return undef unless @{$pids};

  $ps->uptime()->stat($pids);
  $ps->jiffy() unless exists $ps->{jiffy};
  $ps;
}

=item * $percent = $prep->loadavg($pid0,$pid1,...);

=item * $percent = $prep->loadkid($pid0,$pid1,...);

Call:

  method: loadavg for job(pid) utilization
  method: loadkid to include utilization of child processes

Calculates the % CPU utilization of each job (pid) over the period between calls

  input:	an array of PID's or ref to array of PID's
  returns:	a blessed hash structure of the form:

  $ps	= {
	utilize	=> {
		$pid0	=> num[float 0..100] representing %,
		$pid1	=> num...,
		...
	},
  };

Method will report ZERO for a job(pid) which does not have a previous call entry.

Return undef on error.

Will call the other package methods as needed to populate the '$ps' hash.

=cut

sub loadavg {
  _util(0,@_);
}

sub loadkid {
  _util(1,@_);
}

sub _util {
  my $kid = shift;
  my $ps = shift;
  my $pids = ref $_[0] ? $_[0] : [@_];
  return undef unless @{$pids};

  $ps->usage();

  my $cputime = ( $ps->{current}->{uptime}
		- $ps->{last}->{uptime}
		+ $ps->{current}->{idle}
		- $ps->{last}->{idle}
		) * $ps->{jiffy};
  foreach my $pid (@{$pids}) {
    my $util;
    if ( exists $ps->{lastat}->{$pid} && $ps->{lastat}->{$pid} ) {
      $util = $ps->{utime}->{$pid} + $ps->{stime}->{$pid};
      if ($kid) {
	$util += $ps->{cutime}->{$pid} + $ps->{cstime}->{$pid};
      }
      $util /= $cputime;
# round to 2 decimal places and render in % 0 -> 100 more or less
      $util *= 10000;
      $util += 0.5;
      $util = int($util) / 100;
    } else {
      $util = 0;
    }
    $ps->{utilize}->{$pid} = $util;
  }
}

=item * $ps = $ps->purgemissing($pid0,$pid1,...);

Removes all PID's from the '$ps' structure not in the PID list

  input:	an array of PID's or ref to array of PID's
  returns:	bless reference stripped of all other PID's

Returns undef on error

=cut

sub purgemissing {
  my $ps = shift;
  my $pids = ref $_[0] ? $_[0] : [@_];
  return undef unless @{$pids};

  my $live = {};
  @{$live}{@{$pids}} = ();	# hash of undefs
	
  foreach (qw(
	utime
	stime
	cutime
	cstime
	lastat
	curstat )) {
    my @allpids = keys %{$ps->{$_}};
    foreach my $pid (@allpids) {
      next if exists $live->{$pid};
      delete $ps->{$_}->{$pid} if exists $ps->{$_}->{$pid};
    }
  }
  $ps;
}

=back

=head1 Contents of /proc/[pid]/stat from proc(5)

pid %d

(1) The process ID.

comm %s

(2) The filename of the executable, in parentheses. This is visible whether or not the executable is swapped out.

state %c

(3) One character from the string "RSDZTW" where R is running, S is sleeping in an interruptible wait, D is waiting in uninterruptible disk sleep, Z is zombie, T is traced or stopped (on a signal), and W is paging.

ppid %d

(4) The PID of the parent.

pgrp %d

(5) The process group ID of the process.

session %d

(6) The session ID of the process.

tty_nr %d

(7) The controlling terminal of the process. (The minor device number is contained in the combination of bits 31 to 20 and 7 to 0; the major device number is in bits 15 to 8.)

tpgid %d

(8) The ID of the foreground process group of the controlling terminal of the process. 

flags %u (%lu before Linux 2.6.22) 

(9) The kernel flags word of the process. For bit meanings, see the PF_* defines in the Linux kernel source file include/linux/sched.h. Details depend on the kernel version.

minflt %lu

(10) The number of minor faults the process has made which have not required loading a memory page from disk.

cminflt %lu

(11) The number of minor faults that the process's waited-for children have made.

majflt %lu

(12) The number of major faults the process has made which have required loading a memory page from disk.

cmajflt %lu

(13) The number of major faults that the process's waited-for children have made.

utime %lu

(14) Amount of time that this process has been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)). This includes guest time, guest_time (time spent running a virtual CPU, see below), so that applications that are not aware of the guest time field do not lose that time from their calculations.

stime %lu

(15) Amount of time that this process has been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)).

cutime %ld

(16) Amount of time that this process's waited-for children have been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)). (See also times(2).) This includes guest time, cguest_time (time spent running a virtual CPU, see below).

cstime %ld

(17) Amount of time that this process's waited-for children have been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)). 

priority %ld 

(18) (Explanation for Linux 2.6) For processes running a real-time scheduling policy (policy below; see sched_setscheduler(2)), this is the negated scheduling priority, minus one; that is, a number in the range -2 to -100, corresponding to real-time priorities 1 to 99. For processes running under a non-real-time scheduling policy, this is the raw nice value (setpriority(2)) as represented in the kernel. The kernel stores nice values as numbers in the range 0 (high) to 39 (low), corresponding to the user-visible nice range of -20 to 19.

Before Linux 2.6, this was a scaled value based on the scheduler weighting given to this process.

nice %ld

(19) The nice value (see setpriority(2)), a value in the range 19 (low priority) to -20 (high priority). 

num_threads %ld 

(20) Number of threads in this process (since Linux 2.6). Before kernel 2.6, this field was hard coded to 0 as a placeholder for an earlier removed field.

itrealvalue %ld 

(21) The time in jiffies before the next SIGALRM is sent to the process due to an interval timer. Since kernel 2.6.17, this field is no longer maintained, and is hard coded as 0.

starttime %llu (was %lu before Linux 2.6) 

(22) The time the process started after system boot. In kernels before Linux 2.6, this value was expressed in jiffies. Since Linux 2.6, the value is expressed in clock ticks (divide by sysconf(_SC_CLK_TCK)).

vsize %lu

(23) Virtual memory size in bytes.

rss %ld

(24) Resident Set Size: number of pages the process has in real memory. This is just the pages which count toward text, data, or stack space. This does not include pages which have not been demand-loaded in, or which are swapped out.

rsslim %lu

(25) Current soft limit in bytes on the rss of the process; see the description of RLIMIT_RSS in getrlimit(2). 

startcode %lu 

(26) The address above which program text can run.

endcode %lu

(27) The address below which program text can run. 

startstack %lu 

(28) The address of the start (i.e., bottom) of the stack.

kstkesp %lu

(29) The current value of ESP (stack pointer), as found in the kernel stack page for the process.

kstkeip %lu

(30) The current EIP (instruction pointer).

signal %lu

(31) The bitmap of pending signals, displayed as a decimal number. Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.

blocked %lu

(32) The bitmap of blocked signals, displayed as a decimal number. Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead. 

sigignore %lu 

(33) The bitmap of ignored signals, displayed as a decimal number. Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.

sigcatch %lu 

(34) The bitmap of caught signals, displayed as a decimal number. Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.

wchan %lu

(35) This is the "channel" in which the process is waiting. It is the address of a system call, and can be looked up in a namelist if you need a textual name. (If you have an up-to-date /etc/psdatabase, then try ps -l to see the WCHAN field in action.)

nswap %lu

(36) Number of pages swapped (not maintained).

cnswap %lu

(37) Cumulative nswap for child processes (not maintained). 

exit_signal %d (since Linux 2.1.22) 

(38) Signal to be sent to parent when we die.

processor %d (since Linux 2.2.8) 

(39) CPU number last executed on.

rt_priority %u (since Linux 2.5.19; was %lu before Linux 2.6.22) 

(40) Real-time scheduling priority, a number in the range 1 to 99 for processes scheduled under a real-time policy, or 0, for non-real-time processes (see sched_setscheduler(2)).

policy %u (since Linux 2.5.19; was %lu before Linux 2.6.22) 

(41) Scheduling policy (see sched_setscheduler(2)). Decode using the SCHED_* constants in linux/sched.h.

delayacct_blkio_ticks %llu (since Linux 2.6.18) 

(42) Aggregated block I/O delays, measured in clock ticks (centiseconds).

guest_time %lu (since Linux 2.6.24) 

(43) Guest time of the process (time spent running a virtual CPU for a guest operating system), measured in clock ticks (divide by sysconf(_SC_CLK_TCK)).

cguest_time %ld (since Linux 2.6.24) 

(44) Guest time of the process's children, measured in clock ticks (divide by sysconf(_SC_CLK_TCK)). 

=head1 BUGS

none so far

=head1 COPYRIGHT 2019

Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.
        51 Franklin Street, Fifth Floor
        Boston, MA 02110-1301 USA.

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
