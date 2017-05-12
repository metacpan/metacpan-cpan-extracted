package P9Y::ProcessTable::Role::Table::ProcFS;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.08'; # VERSION

#############################################################################
# Modules

# use sanity;
use strict qw(subs vars);
no strict 'refs';
use warnings FATAL => 'all';
no warnings qw(uninitialized);

use Moo::Role;

requires 'table';
requires 'process';

use Path::Class;
use Config;
use POSIX;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Methods

sub list {
   my $self = shift;

   my @list;
   my $dir = dir('', 'proc');
   while (my $pdir = $dir->next) {
      next unless ($pdir->is_dir);
      next unless (-e $pdir->file('status'));
      next unless ($pdir->basename =~ /^\d+$/);

      push @list, $pdir->basename;
   }

   return sort { $a <=> $b } @list;
}

sub fields {
   return $^O eq /solaris|sunos/i ?
   ( qw/
      pid uid gid euid egid ppid pgrp sess
      cwd exe root cmdline
      utime stime cutime cstime start time ctime
      fname ttynum flags threads size rss pctcpu pctmem
   / ) :
   ( qw/
      pid uid gid ppid pgrp sess
      cwd exe root cmdline environ
      minflt cminflt majflt cmajflt ttlflt cttlflt utime stime cutime cstime start time ctime
      priority fname state ttynum flags threads size rss wchan cpuid
   / );
}

sub _process_hash {
   my ($self, $pid) = @_;

   my $pdir = dir('', 'proc', $pid);
   return unless -d $pdir;

   my $stat = $pdir->stat;
   return unless $stat;

   my $hash = {
      pid   => $pid,
      uid   => $stat->uid,
      gid   => $stat->gid,
      start => $stat->mtime,  # not reliable
   };

   # process links
   foreach my $ln (qw{cwd exe root}) {
      my $link = $pdir->file($ln);
      $hash->{$ln} = readlink $link if (-l $link);
   }

   # process simple cats
   foreach my $fn (qw{cmdline}) {
      my $file = $pdir->file($fn);
      next unless (-f $file);
      $hash->{$fn} = $file->slurp;
      $hash->{$fn} =~ s/\0/ /g;
      $hash->{$fn} =~ s/^\s+//;
      $hash->{$fn} =~ s/\s+$//;
   }

   # process environment
   my $env_file = $pdir->file('environ');
   if (-f $env_file) {
      my $data;
      eval { $data = $env_file->slurp; };  # skip permission failures
      unless ($@) {
         $data =~ s/^\0+//;
         $data =~ s/\0+$//;
         $hash->{environ} = { map { split /\=/, $_, 2 } grep { /\=/ } split /\0/, $data };
      }
   }

   my $clock_ticks = POSIX::sysconf( &POSIX::_SC_CLK_TCK );

   # start time is measured in the number of clock ticks since boot, so we need the boot time
   my $boot_time;
   my $uptime_file = file('', 'proc', 'uptime');
   if ( -f $uptime_file ) {
      my $time = time;
      my $uptime = $uptime_file->slurp;
      $boot_time = $time - $1 if $uptime =~ /^([\d\.]+)/;
   }

   # process main PID stats
   if ( -f $pdir->file('status') and -f $pdir->file('statm') and -f $pdir->file('stat') ) {
      ### Linux ###
      # stat has more needed information than the friendier status, so we'll use that file instead

      # stat
      my $data = $pdir->file('stat')->slurp;
      my @data = split /\s+/, $data;

      my $states = {
         R => 'run',
         S => 'sleep',
         D => 'disk sleep',
         Z => 'defunct',
         T => 'stop',
         W => 'paging',
      };

      my $stat_loc = [ qw(
         pid fname state ppid pgrp sess ttynum . flags minflt cminflt majflt cmajflt utime stime cutime cstime priority . threads .
         starttime size rss . . . . . . . . . . wchan . . . cpuid . . . . .
      ) ];

      foreach my $i (0 .. @data - 1) {
         next if $stat_loc->[$i] eq '.';
         last if ($i >= @$stat_loc);
         $hash->{ $stat_loc->[$i] } = $data[$i];
      }

      # normalize clock ticks into seconds
      if ($clock_ticks) {
         $hash->{$_} /= $clock_ticks for (qw[ utime stime cutime cstime starttime ]);
         $hash->{start} = $boot_time + $hash->{starttime} if $boot_time;
      }
      delete $hash->{starttime};

      $hash->{fname} =~ s/^\((.+)\)$/$1/;
      $hash->{state} = $states->{ $hash->{state} };
      $hash->{ time} = $hash->{ utime} + $hash->{ stime};
      $hash->{ctime} = $hash->{cutime} + $hash->{cstime};

      $hash->{ ttlflt} = $hash->{ minflt} + $hash->{ majflt};
      $hash->{cttlflt} = $hash->{cminflt} + $hash->{cmajflt};

      $hash->{rss} *= POSIX::sysconf( &POSIX::_SC_PAGESIZE );
   }
   elsif ($^O =~ /solaris|sunos/i) {
      ### Solaris ###
      my $ptr = $Config{longsize} >= 8 ? 'Q' : 'I';

      my $data = '';
      eval { $data = $pdir->file('status')->slurp; };  # skip permission failures
      if (length $data) {
         my @data = unpack 'I[10]'.$ptr.'[4]I[12]CI[4]', $data;

         #  1 int pr_flags;            /* flags (see below) */
         #  2 int pr_nlwp;             /* number of active lwps in the process */
         #  3 int pr_nzomb;            /* number of zombie lwps in the process */
         #  4 pid_tpr_pid;             /* process id */
         #  5 pid_tpr_ppid;            /* parent process id */
         #  6 pid_tpr_pgid;            /* process group id */
         #  7 pid_tpr_sid;             /* session id */
         #  8 id_t pr_aslwpid;         /* obsolete */
         #  9 id_t pr_agentid;         /* lwp-id of the agent lwp, if any */
         # 10 sigset_t pr_sigpend;     /* set of process pending signals */
         # 11 uintptr_t pr_brkbase;    /* virtual address of the process heap */
         # 12 size_t pr_brksize;       /* size of the process heap, in bytes */
         # 13 uintptr_t pr_stkbase;    /* virtual address of the process stack */
         # 14 size_tpr_stksize;        /* size of the process stack, in bytes */
         #
         # 15 timestruc_t pr_utime;    /* process user cpu time */
         # 17 timestruc_t pr_stime;    /* process system cpu time */
         # 19 timestruc_t pr_cutime;   /* sum of children's user times */
         # 21 timestruc_t pr_cstime;   /* sum of children's system times */

         # some Solaris versions don't have pr_nzomb
         if ($data[2] == $pid) {
            @data = unpack 'I[9]'.$ptr.'[4]I[12]CI[4]', $data;
            splice @data, 2, 0, (0);
         }

         my $stat_loc = [ qw(
            flags threads . pid ppid pgrp sess . . . . . . . utime . stime . cutime . cstime .
         ) ];

         foreach my $i (0 .. @data - 1) {
            next if $stat_loc->[$i] eq '.';
            last if ($i >= @$stat_loc);
            $hash->{ $stat_loc->[$i] } = $data[$i];
         }

         $hash->{time}  = $hash->{utime}  + $hash->{stime};
         $hash->{ctime} = $hash->{cutime} + $hash->{stime};
      }

      $data = '';
      eval { $data = $pdir->file('psinfo')->slurp; };  # skip permission failures
      if (length $data) {
         my @data = unpack 'I[11]'.$ptr.'[3]IS[2]I[6]A[16]A[80]I', $data;

         #define  PRFNSZ      16  /* Maximum size of execed filename */
         #define  PRARGSZ     80  /* number of chars of arguments */

         #  1 int pr_flag;             /* process flags (DEPRECATED: see below) */
         #  2 int pr_nlwp;             /* number of active lwps in the process */
         #  3 int pr_nzomb;            /* number of zombie lwps in the process */
         #  4 pid_t pr_pid;            /* process id */
         #  5 pid_t pr_ppid;           /* process id of parent */
         #  6 pid_t pr_pgid;           /* process id of process group leader */
         #  7 pid_t pr_sid;            /* session id */
         #  8 uid_t pr_uid;            /* real user id */
         #  9 uid_t pr_euid;           /* effective user id */
         # 10 gid_t pr_gid;            /* real group id */
         # 11 gid_t pr_egid;           /* effective group id */
         # 12 uintptr_t pr_addr;       /* address of process */
         # 13 size_t pr_size;          /* size of process image in Kbytes */
         # 14 size_t pr_rssize;        /* resident set size in Kbytes */
         # 15 dev_t pr_ttydev;         /* controlling tty device (or PRNODEV) */
         # 16 ushort_t pr_pctcpu;      /* % of recent cpu time used by all lwps */
         # 17 ushort_t pr_pctmem;      /* % of system memory used by process */
         # 18 timestruc_t pr_start;    /* process start time, from the epoch */
         # 20 timestruc_t pr_time;     /* cpu time for this process */
         # 22 timestruc_t pr_ctime;    /* cpu time for reaped children */
         # 23 char pr_fname[PRFNSZ];   /* name of exec'ed file */
         # 24 char pr_psargs[PRARGSZ]; /* initial characters of arg list */
         # 25 int pr_wstat;            /* if zombie, the wait() status */

         # some Solaris versions don't have pr_nzomb
         if ($data[2] == $pid) {
            @data = unpack 'I[10]'.$ptr.'[3]IS[2]I[6]A[16]A[80]I', $data;
            splice @data, 2, 0, (0);
         }

         my $psinfo_loc = [ qw(
            . threads . pid ppid pgrp sess uid euid gid egid . size rss ttynum pctcpu pctmem start time ctime fname cmdline .
         ) ];

         foreach my $i (0 .. @data - 1) {
            next if $psinfo_loc->[$i] eq '.';
            last if ($i >= @$psinfo_loc);
            $hash->{ $psinfo_loc->[$i] } = $data[$i];
         }

         $hash->{size} *= 1024;
         $hash->{rss}  *= 1024;
      }
   }
   elsif ($^O =~ /dragonfly|bsd/i) {
      ### Dragonfly ###

      # stat
      my $data = $pdir->file('status')->slurp;
      my @data = split /\s+/, $data;

      my $stat_loc = [ qw(
         fname pid ppid pgrp sess ttynum flags start utime stime state euid
      ) ];

      foreach my $i (0 .. @data - 1) {
         next if $stat_loc->[$i] eq '.';
         last if ($i >= @$stat_loc);
         $hash->{ $stat_loc->[$i] } = $data[$i];
      }

      $hash->{fname} =~ s/^\((.+)\)$/$1/;
      ($hash->{euid}, $hash->{egid}) = split(/,/, $hash->{euid}, 3);
      $hash->{$_} =~ s!\,!.! for qw[start utime stime];

      ### TODO: State normalization, like $states in the Linux block ###
      #$hash->{state} = $states->{ $hash->{state} };

      $hash->{ time} = $hash->{ utime} + $hash->{ stime};
   }

   return $hash;
}

42;
