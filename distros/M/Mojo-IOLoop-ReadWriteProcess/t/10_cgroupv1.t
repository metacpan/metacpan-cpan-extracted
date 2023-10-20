#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile tempdir path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

BEGIN { $ENV{MOJO_CGROUP_FS} = tempdir() }

use Mojo::IOLoop::ReadWriteProcess              qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop;
use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);

subtest mock => sub {
  my $cgroup = cgroupv1(name => "foo");

  isa_ok $cgroup, 'Mojo::IOLoop::ReadWriteProcess::CGroup::v1';

  my $child_cgroup = $cgroup->child('bar');
  $child_cgroup->create();
  ok $child_cgroup->exists,     'Child cgroup exists';
  ok -d $child_cgroup->_cgroup, 'Folder is created';
  $child_cgroup->remove;
  is $child_cgroup->exists, undef, 'Child group does not exist anymore';

  ok $cgroup->exists,     'Parent CGroup exists';
  ok -d $cgroup->_cgroup, 'Parent CGroup folder exists';
  ok $cgroup->_cgroup ne $child_cgroup->_cgroup,
    'Child and parent has different CGroup path'
    or diag explain [$cgroup, $child_cgroup];
  $cgroup->remove;
  is $cgroup->exists, undef, 'Parent group does not exist anymore';

  $child_cgroup->create();
  $child_cgroup->add_process("3");
  $child_cgroup->add_process("5");
  is $child_cgroup->process_list, "3\n5\n",
    "procs interface contains the added pids"
    or die diag explain $child_cgroup->process_list;

  ok $child_cgroup->contains_process("3"),   "Child contains pid 3";
  ok $child_cgroup->contains_process("5"),   "Child contains pid 5";
  ok !$child_cgroup->contains_process("10"), "Child does not contain pid 10";
  ok !$child_cgroup->contains_process("20"), "Child does not contain pid 20";

  $cgroup->create();
  $cgroup->add_process("30");
  $cgroup->add_process("50");
  is $cgroup->process_list, "30\n50\n",
    "procs interface contains the added pids"
    or die diag explain $cgroup->process_list;

  ok $cgroup->contains_process("30"), "Parent contains pid 30";
  ok $cgroup->contains_process("50"), "Parent contains pid 50";
  ok !$cgroup->contains_process("3"), "Parent does not contain pid 3";
  ok !$cgroup->contains_process("5"), "Parent does not contain pid 5";

  $cgroup->create();
  $cgroup->add_thread("20");
  $cgroup->add_thread("40");
  is $cgroup->thread_list, "20\n40\n",
    "thread interface contains the added threads ID"
    or die diag explain $cgroup->thread_list;

  ok $cgroup->contains_thread("20"),  "Parent contains thread ID 20";
  ok $cgroup->contains_thread("40"),  "Parent contains thread ID 40";
  ok !$cgroup->contains_thread("30"), "Parent does not contain thread ID 30";
  ok !$cgroup->contains_thread("50"), "Parent does not contain thread ID 50";

  $cgroup->pid->max('6');
  is $cgroup->pid->max, '6', 'Correct pid.max set';

  my $cgroup2
    = cgroupv1->from(path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3'));

  is $cgroup2->name,       'test2', "Cgroup name matches";
  is $cgroup2->controller, 'test',  "Cgroup controller matches";
  is $cgroup2->parent,     'test3', "Cgroup controller matches";

  is $cgroup2->_cgroup,
    path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3')->to_string;
};

sub mockwrite {
  my $c = shift;
  $c->cgroup->_cgroup->child(shift)->spew(shift);
}

subtest dev_freez_pid_rdma_controller => sub {

  my $devices = cgroupv1(name => "foo", controller => 'devices');
  my $freezer = cgroupv1(name => "foo", controller => 'freezer');
  my $pid     = cgroupv1(name => "foo", controller => 'pids');
  my $rdma    = cgroupv1(name => "foo", controller => 'rdma');

  my $devices_controller = $devices->devices;
  my $freezer_controller = $freezer->freezer;
  my $pid_controller     = $pid->pid;
  my $rdma_controller    = $rdma->rdma;

  $devices_controller->allow('foo');
  $devices_controller->deny('bar');
  is $devices_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Devices::DEVICES_ALLOW_INTERFACE(
    ))->slurp, 'foo';

  is $devices_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Devices::DEVICES_DENY_INTERFACE(
    ))->slurp, 'bar';

  $freezer_controller->state('THAW');
  is $freezer_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer::STATE_INTERFACE())
    ->slurp, 'THAW';
  is $freezer_controller->state, 'THAW';

  mockwrite(
    $freezer_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer::SELF_FREEZING_INTERFACE(
      ) => 'foo'
  );
  is $freezer_controller->self_freezing, 'foo';

  mockwrite(
    $freezer_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer::PARENT_FREEZING_INTERFACE(
      ) => 'bar'
  );
  is $freezer_controller->parent_freezing, 'bar';

  mockwrite($pid_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID::CURRENT_INTERFACE() =>
      '42');
  is $pid_controller->current, '42';

  $pid_controller->max('BAR');
  is $pid_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID::MAX_INTERFACE())->slurp,
    'BAR';
  is $pid_controller->max, 'BAR';

  mockwrite($rdma_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA::CURRENT_INTERFACE() =>
      '42');
  is $rdma_controller->current, '42';

  $rdma_controller->max('BAR');
  is $rdma_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA::MAX_INTERFACE())->slurp,
    'BAR';
  is $rdma_controller->max, 'BAR';
};

subtest memory_net_controller => sub {

  my $memory  = cgroupv1(name => "foo", controller => 'memory');
  my $netcls  = cgroupv1(name => "foo", controller => 'netcls');
  my $netprio = cgroupv1(name => "foo", controller => 'netprio');

  my $memory_controller  = $memory->memory;
  my $netcls_controller  = $netcls->netcls;
  my $netprio_controller = $netprio->netprio;


  mockwrite($memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::CURRENT_INTERFACE(
      ) => 'boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::CURRENT_INTERFACE())
    ->slurp, 'boo';
  is $memory_controller->current, 'boo';

  mockwrite($memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::STAT_INTERFACE() =>
      'foo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::STAT_INTERFACE())
    ->slurp, 'foo';
  is $memory_controller->stat, 'foo';


  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::CURRENT_AND_SWAP_INTERFACE(
      ) => 'bar'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::CURRENT_AND_SWAP_INTERFACE(
    ))->slurp, 'bar';
  is $memory_controller->swap_current, 'bar';

  mockwrite($memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::FAILCNT_INTERFACE(
      ) => '42');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::FAILCNT_INTERFACE())
    ->slurp, '42';
  is $memory_controller->failcnt, '42';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::MAX_RECORDED_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::MAX_RECORDED_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->observed_max_usage, 'baz';


  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::MAX_RECORDED_AND_SWAP_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::MAX_RECORDED_AND_SWAP_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->observed_swap_max_usage, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_USAGE_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_USAGE_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->kmem_tcp_usage, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_FAILCNT_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_FAILCNT_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->kmem_tcp_failcnt, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_MAX_USAGE_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_MAX_USAGE_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->kmem_tcp_max_usage, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_USAGE_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_USAGE_INTERFACE())
    ->slurp, 'baz';
  is $memory_controller->kmem_usage, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_FAILCNT_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_FAILCNT_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->kmem_failcnt, 'baz';

  mockwrite(
    $memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_MAX_RECORDED_INTERFACE(
      ) => 'baz'
  );
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_MAX_RECORDED_INTERFACE(
    ))->slurp, 'baz';
  is $memory_controller->kmem_max_usage, 'baz';

  mockwrite($memory_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::NUMA_STAT_INTERFACE(
      ) => 'baz');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::NUMA_STAT_INTERFACE())
    ->slurp, 'baz';
  is $memory_controller->numa_stat, 'baz';

  $memory_controller->limit('boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::LIMIT_INTERFACE())
    ->slurp, 'boo';
  is $memory_controller->limit, 'boo';

  $memory_controller->use_hierarchy('boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::USE_HIERARCHY_INTERFACE(
    ))->slurp, 'boo';
  is $memory_controller->use_hierarchy, 'boo';

  $memory_controller->soft_limit('boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::SOFT_LIMIT_INTERFACE())
    ->slurp, 'boo';
  is $memory_controller->soft_limit, 'boo';


  $memory_controller->force_empty('boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::FORCE_EMPTY_INTERFACE())
    ->slurp, 'boo';
  is $memory_controller->force_empty, 'boo';

  $memory_controller->pressure_level('boo');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::PRESSURE_LEVEL_INTERFACE(
    ))->slurp, 'boo';
  is $memory_controller->pressure_level, 'boo';


  $memory_controller->swappiness('22233');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::SWAPPINESS_INTERFACE())
    ->slurp, '22233';
  is $memory_controller->swappiness, '22233';


  $memory_controller->move_charge('433');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::MOVE_CHARGE_AT_IMMIGRATE_INTERFACE(
    ))->slurp, '433';
  is $memory_controller->move_charge, '433';

  $memory_controller->oom_control('433');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::OOM_CONTROL_INTERFACE())
    ->slurp, '433';
  is $memory_controller->oom_control, '433';

  $memory_controller->kmem_limit('433');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_LIMIT_INTERFACE())
    ->slurp, '433';
  is $memory_controller->kmem_limit, '433';

  $memory_controller->kmem_tcp_limit('433');
  is $memory_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Memory::KMEM_TCP_LIMIT_INTERFACE(
    ))->slurp, '433';
  is $memory_controller->kmem_tcp_limit, '433';

  $netcls_controller->classid('boo');
  is $netcls_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netcls::CLASSID_INTERFACE())
    ->slurp, 'boo';
  is $netcls_controller->classid, 'boo';

  $netprio_controller->ifpriomap('boo');
  is $netprio_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netprio::IFPRIOMAP_INTERFACE())
    ->slurp, 'boo';
  is $netprio_controller->ifpriomap, 'boo';

  mockwrite($netprio_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netprio::PRIOIDX_INTERFACE(
      ) => 'foo');
  is $netprio_controller->prioidx, 'foo';
};

subtest cpu_controller => sub {

  # Initialize controllers
  my $cpuset  = cgroupv1(name => "foo", controller => 'cpuset');
  my $cpuacct = cgroupv1(name => "foo", controller => 'cpuacct');

  my $cpuacct_controller = $cpuacct->cpuacct;
  my $cpuset_controller  = $cpuset->cpuset;

  mockwrite($cpuacct_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuacct::USAGE_INTERFACE() =>
      'foo');
  is $cpuacct_controller->usage, 'foo';

  # cpuset
  mockwrite(
    $cpuset_controller =>
      Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_PRESSURE_INTERFACE(
      ) => 'foobar'
  );
  is $cpuset_controller->get_memory_pressure, 'foobar';

  $cpuset_controller->cpus('3');
  $cpuset_controller->mems('30');

  $cpuset_controller->memory_migrate(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEMORY_MIGRATE_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->memory_migrate(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEMORY_MIGRATE_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->cpu_exclusive(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::CPU_EXCLUSIVE_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->cpu_exclusive(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::CPU_EXCLUSIVE_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->mem_exclusive(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_EXCLUSIVE_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->mem_exclusive(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_EXCLUSIVE_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->mem_hardwall(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_HARDWALL_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->mem_hardwall(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_HARDWALL_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->memory_spread_page(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_SPREAD_PAGE_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->memory_spread_page(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_SPREAD_PAGE_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->memory_pressure(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEMORY_PRESSURE_ENABLED_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->memory_pressure(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEMORY_PRESSURE_ENABLED_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->sched_relax_domain_level(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::SCHED_RELAX_DOMAIN_LEVEL_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->sched_relax_domain_level(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::SCHED_RELAX_DOMAIN_LEVEL_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->sched_load_balance(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::SCHED_LOAD_BALANCE_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->sched_load_balance(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::SCHED_LOAD_BALANCE_INTERFACE(
    ))->slurp, '0';

  $cpuset_controller->memory_spread_slab(1);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_SPREAD_SLAB_INTERFACE(
    ))->slurp, '1';
  $cpuset_controller->memory_spread_slab(0);
  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEM_SPREAD_SLAB_INTERFACE(
    ))->slurp, '0';

  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::CPUS_INTERFACE())
    ->slurp, '3';

  is $cpuset_controller->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuset::MEMS_INTERFACE())
    ->slurp, '30';
};

done_testing;
