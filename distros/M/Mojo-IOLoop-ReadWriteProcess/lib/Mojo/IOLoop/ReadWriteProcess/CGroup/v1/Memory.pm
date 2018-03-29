package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory;

use Mojo::Base -base;

use constant {

  # show various statistics
  STAT_INTERFACE => 'memory.stat',

  # show current usage for memory
  CURRENT_INTERFACE => 'memory.usage_in_bytes',

  # show current usage for memory+Swap
  CURRENT_AND_SWAP_INTERFACE => 'memory.memsw.usage_in_bytes',

  # set/show limit of memory usage
  LIMIT_INTERFACE => 'memory.limit_in_bytes',

  # show current usage for memory
  LIMIT_AND_SWAP_INTERFACE => 'memory.memsw.limit_in_bytes',

  # show the number of memory usage hits limits
  FAILCNT_INTERFACE => 'memory.failcnt',

  # show max memory usage recorded
  MAX_RECORDED_INTERFACE => 'memory.max_usage_in_bytes',

  # show max memory+Swap usage recorded
  MAX_RECORDED_AND_SWAP_INTERFACE => 'memory.memsw.max_usage_in_bytes',

  # set/show soft limit of memory usage
  SOFT_LIMIT_INTERFACE => 'memory.soft_limit_in_bytes',

  # set/show hierarchical account enabled
  USE_HIERARCHY_INTERFACE => 'memory.use_hierarchy',

  # trigger forced move charge to parent
  FORCE_EMPTY_INTERFACE => 'memory.force_empty',

  # set memory pressure notifications
  PRESSURE_LEVEL_INTERFACE => 'memory.pressure_level',

  # set/show swappiness parameter of vmscan (See sysctl's vm.swappiness)
  SWAPPINESS_INTERFACE => 'memory.swappiness',

  # set/show controls of moving charges
  MOVE_CHARGE_AT_IMMIGRATE_INTERFACE => 'memory.move_charge_at_immigrate',

  # set/show oom controls.
  OOM_CONTROL_INTERFACE => 'memory.oom_control',

  # show the number of memory usage per numa node
  NUMA_STAT_INTERFACE => 'memory.numa_stat',

  # set/show hard limit for kernel memory
  KMEM_LIMIT_INTERFACE => 'memory.kmem.limit_in_bytes',

  # show current kernel memory allocation
  KMEM_USAGE_INTERFACE => 'memory.kmem.usage_in_bytes',

  # show the number of kernel memory usage hits limits
  KMEM_FAILCNT_INTERFACE => 'memory.kmem.failcnt',

  # show max kernel memory usage recorded
  KMEM_MAX_RECORDED_INTERFACE => 'memory.kmem.max_usage_in_bytes',

  # set/show hard limit for tcp buf memory
  KMEM_TCP_LIMIT_INTERFACE => 'memory.kmem.tcp.limit_in_bytes',

  # show current tcp buf memory allocation
  KMEM_TCP_USAGE_INTERFACE => 'memory.kmem.tcp.usage_in_bytes',

  # show the number of tcp buf memory usage hits limits
  KMEM_TCP_FAILCNT_INTERFACE => 'memory.kmem.tcp.failcnt',

  # show max tcp buf memory usage recorded
  KMEM_TCP_MAX_USAGE_INTERFACE => 'memory.kmem.tcp.max_usage_in_bytes',

};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub current            { shift->cgroup->_list(CURRENT_INTERFACE) }
sub stat               { shift->cgroup->_list(STAT_INTERFACE) }
sub swap_current       { shift->cgroup->_list(CURRENT_AND_SWAP_INTERFACE) }
sub limit              { shift->cgroup->_setget(LIMIT_INTERFACE, @_) }
sub failcnt            { shift->cgroup->_list(FAILCNT_INTERFACE) }
sub observed_max_usage { shift->cgroup->_list(MAX_RECORDED_INTERFACE) }

sub observed_swap_max_usage {
  shift->cgroup->_list(MAX_RECORDED_AND_SWAP_INTERFACE);
}
sub use_hierarchy  { shift->cgroup->_setget(USE_HIERARCHY_INTERFACE,  @_) }
sub soft_limit     { shift->cgroup->_setget(SOFT_LIMIT_INTERFACE,     @_) }
sub force_empty    { shift->cgroup->_setget(FORCE_EMPTY_INTERFACE,    @_) }
sub pressure_level { shift->cgroup->_setget(PRESSURE_LEVEL_INTERFACE, @_) }
sub swappiness     { shift->cgroup->_setget(SWAPPINESS_INTERFACE,     @_) }

sub move_charge {
  shift->cgroup->_setget(MOVE_CHARGE_AT_IMMIGRATE_INTERFACE, @_);
}
sub oom_control { shift->cgroup->_setget(OOM_CONTROL_INTERFACE, @_) }
sub numa_stat   { shift->cgroup->_list(NUMA_STAT_INTERFACE) }
sub kmem_limit  { shift->cgroup->_setget(KMEM_LIMIT_INTERFACE,  @_) }
sub kmem_usage  { shift->cgroup->_list(KMEM_USAGE_INTERFACE) }
sub kmem_failcnt       { shift->cgroup->_list(KMEM_FAILCNT_INTERFACE) }
sub kmem_max_usage     { shift->cgroup->_list(KMEM_MAX_RECORDED_INTERFACE) }
sub kmem_tcp_limit     { shift->cgroup->_setget(KMEM_TCP_LIMIT_INTERFACE, @_) }
sub kmem_tcp_usage     { shift->cgroup->_list(KMEM_TCP_USAGE_INTERFACE) }
sub kmem_tcp_failcnt   { shift->cgroup->_list(KMEM_TCP_FAILCNT_INTERFACE) }
sub kmem_tcp_max_usage { shift->cgroup->_list(KMEM_TCP_MAX_USAGE_INTERFACE) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory - CGroups v1 Memory Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->memory->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
