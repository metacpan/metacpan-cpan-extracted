package P9Y::ProcessTable::Role::Table::OS::os2;

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

use OS2::Process;

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
   } (process_hentries);
}

sub list {
   my $self = shift;
   return sort { $a <=> $b } map { $_->{owner_pid} } (process_hentries);
}

sub fields {
   return ( qw/
      pid ppid sess cmdline
   / );
}

sub _process_hash {
   my ($self, $pid) = @_;
   my $info = process_hentry($pid);
   return unless $info;
   return $self->_convert_hash;
}

sub _convert_hash {
   my ($self, $info) = @_;
   return unless $info;

   my $hash = {};
   my $stat_loc = { qw/
      pid        owner_pid
      sess       owner_sid
      cmdline    title
   / };

   foreach my $key (keys %$stat_loc) {
      my $item = $info->{ $stat_loc->{$key} };
      $hash->{$key} = $item if defined $item;
   }

   $hash->{ppid} = ppidOf($hash->{pid});

   return $hash;
}

42;
