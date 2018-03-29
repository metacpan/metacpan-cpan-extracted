package Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

# Refer to https://www.kernel.org/doc/Documentation/cgroup-v2.txt for details

use Mojo::Base 'Mojo::IOLoop::ReadWriteProcess::CGroup';
use Mojo::File 'path';
use Mojo::Collection 'c';

our @EXPORT_OK = qw(cgroup);
use Exporter 'import';

use constant {
  PROCS_INTERFACE           => 'cgroup.procs',
  TYPE_INTERFACE            => 'cgroup.type',
  THREADS_INTERFACE         => 'cgroup.threads',
  EVENTS_INTERFACE          => 'cgroup.events',
  CONTROLLERS_INTERFACE     => 'cgroup.controllers',
  SUBTREE_CONTROL_INTERFACE => 'cgroup.subtree_control',
  MAX_DESCENDANT_INTERFACE  => 'cgroup.max.descendants',
  MAX_DEPTH_INTERFACE       => 'cgroup.max.depth',
  STAT_INTERFACE            => 'cgroup.stat',
};

use Scalar::Util ();
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO;
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2::CPU;
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory;
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2::PID;
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA;

has io => sub {
  my $io = Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO->new(cgroup => shift);
  Scalar::Util::weaken $io->{cgroup};
  return $io;
};

has cpu => sub {
  my $cpu
    = Mojo::IOLoop::ReadWriteProcess::CGroup::v2::CPU->new(cgroup => shift);
  Scalar::Util::weaken $cpu->{cgroup};
  return $cpu;
};

has memory => sub {
  my $memory
    = Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory->new(cgroup => shift);
  Scalar::Util::weaken $memory->{cgroup};
  return $memory;
};

has pid => sub {
  my $pid
    = Mojo::IOLoop::ReadWriteProcess::CGroup::v2::PID->new(cgroup => shift);
  Scalar::Util::weaken $pid->{cgroup};
  return $pid;
};

has rdma => sub {
  my $rdma
    = Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA->new(cgroup => shift);
  Scalar::Util::weaken $rdma->{cgroup};
  return $rdma;
};

# CGroups process interface
sub add_process { shift->_appendln(+PROCS_INTERFACE() => pop) }

sub process_list { shift->_list(PROCS_INTERFACE) }
sub processes    { c(shift->_listarray(PROCS_INTERFACE)) }

sub contains_process { shift->_contains(+PROCS_INTERFACE() => pop) }

# CGroups thread interface
sub add_thread { shift->_appendln(+THREADS_INTERFACE() => pop) }

sub thread_list { shift->_list(THREADS_INTERFACE) }

sub contains_thread { shift->_contains(+THREADS_INTERFACE() => pop) }

# CGroups event interface
sub populated { shift->_list(EVENTS_INTERFACE) }

# CGroups type interface
sub type { shift->_setget(+TYPE_INTERFACE() => pop) }

# CGroups controllers Interface
sub controllers { shift->_setget(+CONTROLLERS_INTERFACE() => pop) }

# CGroups subtree_control Interface
sub subtree_control { shift->_setget(+SUBTREE_CONTROL_INTERFACE() => pop) }

# CGroups max.descendants Interface
sub max_descendants { shift->_setget(+MAX_DESCENDANT_INTERFACE() => pop) }

# CGroups max.depth Interface
sub max_depths { shift->_setget(+MAX_DEPTH_INTERFACE() => pop) }

# CGroups stat Interface
sub stat { shift->_list(+STAT_INTERFACE()) }

*IO     = \&io;
*CPU    = \&cpu;
*MEMORY = \&memory;
*PID    = \&pid;
*RDMA   = \&rdma;

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v2 - CGroups v2 implementation.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new( name => "test" );

    $cgroup->create;
    $cgroup->exists;
    my $child = $cgroup->child('bar');

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v2> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
