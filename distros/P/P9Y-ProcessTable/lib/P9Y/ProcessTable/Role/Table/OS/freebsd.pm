package P9Y::ProcessTable::Role::Table::OS::freebsd;

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

use BSD::Process;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Methods

sub list {
   my $self = shift;
   return sort { $a <=> $b } (BSD::Process::list);
}

sub fields {
   return ( qw/
      pid uid gid euid suid sgid ppid pgrp sess
      exe
      minflt cminflt majflt cmajflt ttlflt cttlflt utime stime cutime cstime start time ctime
      priority fname state flags size rss wchan cpuid pctcpu
   / );
}

sub _process_hash {
   my ($self, $pid) = @_;
   my $info = BSD::Process::info($pid);
   return unless $info;

   my $hash = {};

   # (only has the ones that are different)
   my $stat_loc = { qw/
      uid         ruid
      gid         rgid
      euid        uid
      suid        svuid
      sgid        svgid
      pgrp        pgid
      sess        sid
      cpuid       oncpu
      priority    nice
      flags       flag
      cminflt     minflt_ch
      cmajflt     majflt_ch
      cutime      utime_ch
      cstime      stime_ch
      ctime       time_ch
      rss         rssize
      wchan       wmesg
      fname       comm
      exe         comm
   / };

   foreach my $key ( $self->fields ) {
      my $item = $info->{ $stat_loc->{$key} || $key };
      $hash->{$key} = $item if defined $item;
   }

   $hash->{ ttlflt} = $hash->{ minflt} + $hash->{ majflt};
   $hash->{cttlflt} = $hash->{cminflt} + $hash->{cmajflt};

   my $states = {
      stat_1 => 'forking',
      stat_2 => 'run',
      stat_3 => 'sleep',
      stat_4 => 'stop',
      stat_5 => 'defunct',
      stat_6 => 'wait',
      stat_7 => 'disk sleep',
   };

   my @state;
   foreach my $key (keys %$states) {
      push @state, $states->{$key} if $info->{$key};
   }
   $hash->{state} = join ' ', @state;

   return $hash;
}

42;
