package P9Y::ProcessTable::Role::Table::PPT;

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

use Proc::ProcessTable 0.48;  # ie: the one that ain't broke
use List::AllUtils 'first';

use namespace::clean;
no warnings 'uninitialized';

my $pt = Proc::ProcessTable->new();

#############################################################################
# Methods

# Unfortunately, P:PT has no concept of anything except "grab everything at once". So, we need to run
# through these wasteful cycles just to get one process, one list of PIDs, etc.

sub table {
   my $self = shift;
   return map {
      my $hash = $self->_convert_process($_);
      $hash->{_pt_obj} = $self;
      P9Y::ProcessTable::Process->new($hash);
   } @{ $pt->table };
}

sub list {
   my $self = shift;
   return sort { $a <=> $b } map { $_->pid } @{ $pt->table };
}

sub fields {
   # sometimes an undef pops through
   return grep { $_ } $pt->fields;
}

sub _process_hash {
   my ($self, $pid) = @_;
   my $process = first { $_->pid == $pid } @{ $pt->table };
   return unless $process;
   return $self->_convert_process($process);
}

sub _convert_process {
   my ($self, $process) = @_;
   return unless $process;

   my $hash = {};
   # (only has the ones that are different)
   my $stat_loc = { qw/
      cmdline   cmndline
   / };

   foreach my $key ( $self->fields ) {
      my $old = $stat_loc->{$key} || $key;
      my $item = eval { $process->$old() };

      $hash->{$key} = $item if defined $item;
   }

   return $hash;
}

42;
