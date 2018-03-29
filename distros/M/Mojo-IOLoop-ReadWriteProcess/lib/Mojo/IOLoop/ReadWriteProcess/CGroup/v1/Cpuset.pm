package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset;

use Mojo::Base -base;

use constant {

  # list of CPUs in that cpuset
  CPUS_INTERFACE => 'cpuset.cpus',

  # list of Memory Nodes in that cpuset
  MEMS_INTERFACE => 'cpuset.mems',

  # if set, move pages to cpusets nodes
  MEMORY_MIGRATE_INTERFACE => 'cpuset.memory_migrate',

  # is cpu placement exclusive?
  CPU_EXCLUSIVE_INTERFACE => 'cpuset.cpu_exclusive',

  # is memory placement exclusive?
  MEM_EXCLUSIVE_INTERFACE => 'cpuset.mem_exclusive',

  # is memory allocation hardwalled
  MEM_HARDWALL_INTERFACE => 'cpuset.mem_hardwall',

  #  measure of how much paging pressure in cpuset
  MEM_PRESSURE_INTERFACE => 'cpuset.memory_pressure',

  # if set, spread page cache evenly on allowed nodes
  MEM_SPREAD_PAGE_INTERFACE => 'cpuset.memory_spread_page',

  # if set, spread slab cache evenly on allowed nodes
  MEM_SPREAD_SLAB_INTERFACE => 'cpuset.memory_spread_slab',

  # if set, load balance within CPUs on that cpuset
  SCHED_LOAD_BALANCE_INTERFACE => 'cpuset.sched_load_balance',

  # the searching range when migrating tasks
  SCHED_RELAX_DOMAIN_LEVEL_INTERFACE => 'cpuset.sched_relax_domain_level',

# In addition, only the root cpuset has the following - compute memory_pressure?
  MEMORY_PRESSURE_ENABLED_INTERFACE => 'cpuset.memory_pressure_enabled',

};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub cpus { shift->cgroup->_write(CPUS_INTERFACE, @_) }
sub mems { shift->cgroup->_write(MEMS_INTERFACE, @_) }

sub memory_pressure {
  shift->cgroup->_flag(MEMORY_PRESSURE_ENABLED_INTERFACE, @_);
}

sub sched_relax_domain_level {
  shift->cgroup->_flag(SCHED_RELAX_DOMAIN_LEVEL_INTERFACE, @_);
}

sub sched_load_balance {
  shift->cgroup->_flag(SCHED_LOAD_BALANCE_INTERFACE, @_);
}
sub memory_spread_slab { shift->cgroup->_flag(MEM_SPREAD_SLAB_INTERFACE, @_) }
sub memory_spread_page { shift->cgroup->_flag(MEM_SPREAD_PAGE_INTERFACE, @_) }
sub get_memory_pressure { shift->cgroup->_list(MEM_PRESSURE_INTERFACE) }
sub mem_hardwall        { shift->cgroup->_flag(MEM_HARDWALL_INTERFACE, @_) }
sub mem_exclusive       { shift->cgroup->_flag(MEM_EXCLUSIVE_INTERFACE, @_) }
sub cpu_exclusive       { shift->cgroup->_flag(CPU_EXCLUSIVE_INTERFACE, @_) }
sub memory_migrate      { shift->cgroup->_flag(MEMORY_MIGRATE_INTERFACE, @_) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset - CGroups v1 Cpuset Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->cpuset->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
