package P9Y::ProcessTable::Table::Base;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.08'; # VERSION

#############################################################################
# Modules

# use sanity;
use strict qw(subs vars);
no strict 'refs';
use warnings FATAL => 'all';
no warnings qw(uninitialized);

use Moo;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Common Methods (may potentially be overloaded with OS-specific ones)

sub table {
   my $self = shift;
   return map { $self->process($_) } ($self->list);
}

sub process {
   my ($self, $pid) = @_;
   $pid = $$ if (@_ == 1);
   my $hash = $self->_process_hash($pid);
   return unless $hash && $hash->{pid};

   $hash->{_pt_obj} = $self;
   return P9Y::ProcessTable::Process->new($hash);
}

42;
