package P9Y::ProcessTable::Role::Table::OS::VMS;

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

requires 'process';

use VMS::Process;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Methods

sub table {
   my $self = shift;
   return map {
      my $hash = $self->_convert_hash($_);
      $hash->{_pt_obj} = $self;
      P9Y::ProcessTable::Process->new($hash);
   } (process_list);
}

sub list {
   my $self = shift;
   return sort { $a <=> $b } map { $_->{PID} } (process_list);
}

sub fields {
   return ( qw/
      pid uid gid ppid pgrp
      exe
      ttlflt start time
      priority fname state ttydev flags size rss cpuid
   / );
}

sub _process_hash {
   my ($self, $pid) = @_;
   my $info = process_list({
      NAME  => 'MASTER_PID',
      VALUE => $pid,
   });
   return unless $info;
   return $self->_convert_hash;
}

sub _convert_hash {
   my ($self, $info) = @_;
   return unless $info;

   my $hash = {};
   my $stat_loc = { qw/
      pid         PID
      uid         OWNER
      gid         GRP
      ppid        MASTER_PID
      pgrp        MASTER_PID
      cpuid       CPUID
      priority    PRI
      flags       PHDFLAGS
      ttlflt      PAGEFLTS
      time        CPUTIM
      size        VIRTPEAK
      rss         WSSIZE
      ttydev      TT_PHYDEVNAM
      fname       PRCNAM
      start       LOGINTIM
      state       STATE

      exe         IMAGNAME
   / };

   foreach my $key (keys %$stat_loc) {
      my $item = $info->{ $stat_loc->{$key} };
      $hash->{$key} = $item if defined $item;
   }

   return $hash;
}

42;
