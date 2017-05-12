package P9Y::ProcessTable::Role::Table::OS::MSWin32;

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

use Win32::Process;
use Win32::Process::Info;
use Path::Class;

use namespace::clean;
no warnings 'uninitialized';

my $pi = Win32::Process::Info->new();

my $IS_CYGWIN = ($^O =~ /cygwin/i) ? 1 : 0;

#############################################################################
# Methods

sub list {
   my ($self) = @_;
   my %winpids = map { $_ => 1 } $self->_win32_list;
   my %cygpids = map { $_ => 1 } ($IS_CYGWIN ? $self->_cyg_list : ());
   my %pids = (%winpids, %cygpids);
   return sort { $a <=> $b } keys %pids;
}

sub fields {
   my ($self) = @_;
   my %winflds = map { $_ => 1 } $self->_win32_fields;
   my %cygflds = map { $_ => 1 } ($IS_CYGWIN ? $self->_cyg_fields : ());
   my %fields = (%winflds, %cygflds);

   # (keeps the order straight)
   return grep { $fields{$_} } ( qw/
      pid uid gid euid egid suid sgid ppid pgrp sess
      cwd exe root cmdline environ
      minflt cminflt majflt cmajflt ttlflt cttlflt utime stime cutime cstime start time ctime
      priority fname state ttynum ttydev flags threads size rss wchan cpuid pctcpu pctmem
      winpid winexe
   / );
}

sub process {
   my ($self, $pid) = @_;
   $pid = $$ unless defined $pid;
   my $hash = $self->_process_hash($pid);
   return unless $hash && $hash->{pid} && $hash->{ppid};

   $hash->{_pt_obj} = $self;
   return P9Y::ProcessTable::Process->new($hash);
}

sub _process_hash {
   my ($self, $pid) = @_;
   return ($IS_CYGWIN and Cygwin::pid_to_winpid($pid)) ?
      $self->  _cyg_process_hash($pid) :
      $self->_win32_process_hash($pid)
   ;
}

############################
## Win32 only methods

sub _win32_list {
   return sort { $a <=> $b } ($pi->ListPids);
}

sub _win32_fields {
   return qw(
      pid uid ppid sess
      exe root
      ttlflt utime stime start state time
      threads priority fname state size rss
   );
}

sub _win32_process_hash {
   my ($self, $pid) = @_;
   my $info = $pi->GetProcInfo($pid);
   return unless $info;
   $info = $info->[0];

   my $hash = {};
   my $stat_loc = { qw/
      pid        ProcessId
      uid        Owner
      ppid       ParentProcessId
      sess       SessionId
      exe        ExecutablePath
      threads    ThreadCount
      priority   Priority
      ttlflt     PageFaults
      utime      UserModeTime
      stime      KernelModeTime
      size       VirtualSize
      rss        WorkingSetSize
      fname      Caption
      start      CreationDate
      state      Status
      cmdline    CommandLine
   / };

   foreach my $key (keys %$stat_loc) {
      my $item = $info->{ $stat_loc->{$key} };
      $hash->{$key} = $item if defined $item;
   }

   $hash->{exe} =~ /^(\w\:\\)/;
   $hash->{root} = $1;
   $hash->{time} = $hash->{utime} + $hash->{stime};

   return $hash;
}

############################
## Cygwin only methods

### TODO: Leverage ProcFS, instead of copying the same code ###

sub _cyg_list {
   my @list;

   my $dir = dir('', 'proc');
   while (my $pdir = $dir->next) {
      next unless ($pdir->is_dir);
      next unless (-e $pdir->file('status'));
      next unless ($pdir->basename =~ /^\d+$/);

      push @list, $pdir->basename;
   }

   return @list;
}

sub _cyg_fields {
   return qw(
      pid uid gid ppid pgrp sess
      cwd exe root cmdline
      minflt cminflt majflt cmajflt ttlflt cttlflt
      utime stime cutime cstime start time ctime
      priority fname state ttynum flags size rss
      winpid winexe
   );
}

sub _cyg_process_hash {
   my ($self, $pid) = @_;

   my $pdir = dir('', 'proc', $pid);
   return unless (-d $pdir);
   my $hash = {
      pid   => $pid,
      uid   => $pdir->stat->uid,
      gid   => $pdir->stat->gid,
      start => $pdir->stat->mtime,
   };

   # process links
   foreach my $ln (qw{cwd exe root}) {
      my $link = $pdir->file($ln);
      $hash->{$ln} = readlink $link if (-l $link);
   }

   # process simple cats
   foreach my $fn (qw{cmdline winpid winexename}) {
      my $file = $pdir->file($fn);
      next unless (-f $file);
      $hash->{$fn} = $file->slurp;
      $hash->{$fn} =~ s/\0/ /g;
      $hash->{$fn} =~ s/^\s+|\s+$//g;
      $hash->{winexe} = delete $hash->{$fn} if ($fn eq 'winexename');
   }

   # process main PID stats
   if (-f $pdir->file('stat')) {

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

      # See cygwin/fhandler_process.cc for the order
      my $stat_loc = [ qw(
         pid fname state ppid pgrp sess ttynum . flags minflt cminflt majflt cmajflt
         utime stime cutime cstime priority . . . . size rss .
      ) ];

      foreach my $i (0 .. @data - 1) {
         next if $stat_loc->[$i] eq '.';
         last if ($i >= @$stat_loc);
         $hash->{ $stat_loc->[$i] } = $data[$i];
      }

      $hash->{fname} =~ s/^\((.+)\)$/$1/;
      $hash->{state} = $states->{ $hash->{state} };
      $hash->{ time} = $hash->{ utime} + $hash->{ stime};
      $hash->{ctime} = $hash->{cutime} + $hash->{cstime};

      $hash->{ ttlflt} = $hash->{ minflt} + $hash->{ majflt};
      $hash->{cttlflt} = $hash->{cminflt} + $hash->{cmajflt};
   }

   return $hash;
}

42;
