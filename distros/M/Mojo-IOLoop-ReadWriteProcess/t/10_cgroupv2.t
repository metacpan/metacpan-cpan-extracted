#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile tempdir path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

BEGIN { $ENV{MOJO_CGROUP_FS} = tempdir() }

use Mojo::IOLoop::ReadWriteProcess qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop;
use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv2);

subtest mock => sub {
  my $cgroup = cgroupv2(name => "foo");

  isa_ok $cgroup, 'Mojo::IOLoop::ReadWriteProcess::CGroup::v2';

  my $child_cgroup = $cgroup->child('bar');
  $child_cgroup->create();
  ok $child_cgroup->exists, 'Child cgroup exists';
  ok -d $child_cgroup->_cgroup, 'Folder is created';
  $child_cgroup->remove;
  is $child_cgroup->exists, undef, 'Child group does not exist anymore';

  ok $cgroup->exists, 'Parent CGroup exists';
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

  ok $child_cgroup->contains_process("3"), "Child contains pid 3";
  ok $child_cgroup->contains_process("5"), "Child contains pid 5";
  ok !$child_cgroup->contains_process("10"), "Child does not contain pid 10";
  ok !$child_cgroup->contains_process("20"), "Child does not contain pid 20";

  $cgroup->create();
  $cgroup->add_process("30");
  $cgroup->add_process("50");
  is $cgroup->process_list, "30\n50\n",
    "procs interface contains the added pids"
    or die diag explain $cgroup->process_list;

  is $cgroup->processes->first, 30, 'first process has pid 30';
  is $cgroup->processes->last,  50, 'last process has pid 50';

  ok $cgroup->contains_process("30"), "Parent contains pid 30";
  ok $cgroup->contains_process("50"), "Parent contains pid 50";
  ok !$cgroup->contains_process("3"), "Parent does not contain pid 3";
  ok !$cgroup->contains_process("5"), "Parent does not contain pid 5";

  $cgroup->type('test');
  is $cgroup->type, 'test', 'Correct CGroup type set';

  ok -e $cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::TYPE_INTERFACE()),
    'CGroup type interface exists';
  is $cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::TYPE_INTERFACE())->slurp,
    'test', 'CGroup type interface is correct';

  $cgroup->create();
  $cgroup->add_thread("20");
  $cgroup->add_thread("40");
  is $cgroup->thread_list, "20\n40\n",
    "thread interface contains the added threads ID"
    or die diag explain $cgroup->thread_list;

  ok $cgroup->contains_thread("20"), "Parent contains thread ID 20";
  ok $cgroup->contains_thread("40"), "Parent contains thread ID 40";
  ok !$cgroup->contains_thread("30"), "Parent does not contain thread ID 30";
  ok !$cgroup->contains_thread("50"), "Parent does not contain thread ID 50";

  is $cgroup->populated, undef, 'Not populated - mocked test';  # We are mocking

  $cgroup->subtree_control('+cpu +memory -io');
  is $cgroup->subtree_control, '+cpu +memory -io', 'Correct CGroup type set';

  ok -e $cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::SUBTREE_CONTROL_INTERFACE()),
    'CGroup controllers interface exists';
  is $cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::SUBTREE_CONTROL_INTERFACE())
    ->slurp, '+cpu +memory -io', 'CGroup controllers interface is correct';

  $cgroup->io->max('20');
  is $cgroup->io->max, '20', 'Correct io.max set';

  $cgroup->io->weight('30');
  is $cgroup->io->weight, '30', 'Correct io.weight set';

  $cgroup->io->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO::STAT_INTERFACE())
    ->spurt('20');
  is $cgroup->io->stat, '20', 'Correct io.max set';

  $cgroup->cpu->max('30');
  is $cgroup->cpu->max, '30', 'Correct cpu.max set';
  $cgroup->cpu->weight('40');
  is $cgroup->cpu->weight, '40', 'Correct cpu.weight set';
  $cgroup->cpu->weight_nice('42');
  is $cgroup->cpu->weight_nice, '42', 'Correct cpu.weight_nice set';
  $cgroup->cpu->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::CPU::STAT_INTERFACE())
    ->spurt('20');
  is $cgroup->cpu->stat, '20', 'Correct cpu.stat set';

  $cgroup->memory->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory::EVENTS_INTERFACE())
    ->spurt('230');
  is $cgroup->memory->events, '230', 'Correct memory.events set';

  $cgroup->memory->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory::STAT_INTERFACE())
    ->spurt('333');
  is $cgroup->memory->stat, '333', 'Correct memory.stat set';

  $cgroup->memory->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory::CURRENT_INTERFACE())
    ->spurt('foo');
  is $cgroup->memory->current, 'foo', 'Correct memory.stat set';

  $cgroup->memory->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory::SWAP_CURRENT_INTERFACE(
    ))->spurt('bar');
  is $cgroup->memory->swap_current, 'bar', 'Correct memory.stat set';

  $cgroup->memory->max('4');
  is $cgroup->memory->max, '4', 'Correct memory.max set';

  $cgroup->memory->low('42');
  is $cgroup->memory->low, '42', 'Correct memory.low set';

  $cgroup->memory->swap_max('111');
  is $cgroup->memory->swap_max, '111', 'Correct memory.swap_max set';

  $cgroup->memory->high('420');
  is $cgroup->memory->high, '420', 'Correct memory.high set';

  $cgroup->rdma->max('5');
  is $cgroup->rdma->max, '5', 'Correct rdma.max set';

  $cgroup->pid->max('6');
  is $cgroup->pid->max, '6', 'Correct pid.max set';

  $cgroup->pid->cgroup->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::PID::CURRENT_INTERFACE())
    ->spurt('test');
  is $cgroup->pid->current, 'test', 'Can get cgroup max';

  my $cgroup2
    = cgroupv2->from(path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3'))
    ->create;
  is $cgroup2->name,   'test',        "Cgroup name matches";
  is $cgroup2->parent, 'test2/test3', "Cgroup parent matches";
  is $cgroup2->_cgroup,
    path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3')->to_string,
    'Cgroup path matches';

  my $cgroup3 = cgroupv2->from(path('/test', 'test2', 'test3'))->create;
  is $cgroup3->name,   'test',        "Cgroup name matches";
  is $cgroup3->parent, 'test2/test3', "Cgroup parent matches";
  is $cgroup3->_cgroup,
    path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3')->to_string,
    'Cgroup path matches';

  my $cgroup4 = cgroupv2->from(path('test', 'test2', 'test3'))->create;
  is $cgroup4->name,   'test',        "Cgroup name matches";
  is $cgroup4->parent, 'test2/test3', "Cgroup parent matches";
  is $cgroup4->_cgroup,
    path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3')->to_string,
    'Cgroup path matches';

  $cgroup2->controllers('+io +cpu');
  is $cgroup2->controllers, '+io +cpu', 'Controllers set correctly';

  $cgroup2->max_descendants('20');
  is $cgroup2->max_descendants, '20', 'max_descendants set correctly';

  $cgroup2->max_depths('30');
  is $cgroup2->max_depths, '30', 'max_depths set correctly';


  $cgroup2->_cgroup->child(
    Mojo::IOLoop::ReadWriteProcess::CGroup::v2::STAT_INTERFACE())
    ->spurt('test');
  is $cgroup2->stat, 'test', 'Can get cgroup stats';


  $cgroup2
    = cgroupv2->from(path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3'));

  is $cgroup2->name,   'test',        "Cgroup name matches";
  is $cgroup2->parent, 'test2/test3', "Cgroup controller matches";

  is $cgroup2->_cgroup,
    path($ENV{MOJO_CGROUP_FS}, 'test', 'test2', 'test3')->to_string;
};

done_testing;
