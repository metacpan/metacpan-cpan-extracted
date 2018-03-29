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
use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv2 cgroupv1);
use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
use Mojo::Util 'monkey_patch';
use Mojo::IOLoop::ReadWriteProcess::Namespace;

sub mock_test {
  my $c = shift;
  my @pids;
  my $fired;
  $c->session->on(register => sub { push(@pids, shift) });
  $c->once(stop => sub { $fired++ });
  $c->start();

  my $cgroups = $c->cgroups;

  attempt {
    attempts  => 20,
    condition => sub { defined $cgroups->first->process_list },
    cb        => sub { sleep 1; }
  };

  my $p = $c->process();
  is $cgroups->first->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroups->first->process_list;

  ok $cgroups->first->contains_process($p->pid),
    "Parent contains pid " . $p->pid;

  attempt {
    attempts  => 20,
    condition => sub { !$c->is_running },
    cb        => sub { sleep 1; }
  };

  $c->wait_stop();
  is $cgroups->first->process_list, $p->pid . "\n"
    or die diag explain $cgroups->first->process_list;

  unlink $cgroups->first->_cgroup
    ->child(Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PROCS_INTERFACE);
  $cgroups->first->remove();
  ok !$cgroups->first->exists();
  is $fired, 1;
}

subtest container => sub {

  eval { container(process => 2)->start(); };
  ok defined $@, 'Croaks if no sub or Mojo::IOLoop::ReadWriteProcess given';
  like $@,
qr/You need either to pass a Mojo::IOLoop::ReadWriteProcess object or a callback/;

  my $c = container(
    subreaper => 1,
    group     => "group",
    name      => "test",
    process =>
      sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); },
  );

  my @pids;
  my $fired;
  $c->session->on(register => sub { push(@pids, shift) });
  $c->once(stop => sub { $fired++ });
  $c->start();

  my $p       = $c->process();
  my $cgroups = $c->cgroups;
  is $cgroups->first->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroups->first->process_list;

  ok $cgroups->first->contains_process($p->pid),
    "Parent contains pid " . $p->pid;

  attempt {
    attempts  => 20,
    condition => sub { $cgroups->first->processes->size == 1 },
    cb        => sub { sleep 1; }
  };

  $c->wait();
  is $cgroups->first->process_list, $p->pid . "\n"
    or die diag explain $cgroups->first->process_list;

  unlink $cgroups->first->_cgroup
    ->child(Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PROCS_INTERFACE);
  $cgroups->first->remove();
  ok !$cgroups->first->exists();
  is $fired, 1;
};

subtest container_2 => sub {
  my $c = container(
    subreaper => 1,
    group     => "group",
    name      => "test",
    process   => process(
      sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
    ),
  );

  my @pids;
  my $fired;
  $c->session->on(register => sub { push(@pids, shift) });
  $c->once(stop => sub { $fired++ });
  $c->start();

  my $p       = $c->process();
  my $cgroups = $c->cgroups;
  is $cgroups->first->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroups->first->process_list;

  ok $cgroups->first->contains_process($p->pid),
    "Parent contains pid " . $p->pid;

  attempt {
    attempts  => 20,
    condition => sub { !$c->is_running },
    cb        => sub { sleep 1; }
  };

  $c->wait_stop();
  is $cgroups->first->process_list, $p->pid . "\n"
    or die diag explain $cgroups->first->process_list;

  unlink $cgroups->first->_cgroup
    ->child(Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PROCS_INTERFACE);
  $cgroups->first->remove();
  ok !$cgroups->first->exists();
  is $fired, 1;
  $c->stop;

  is $c->is_running, 0;
};

subtest container_3 => sub {
  use Mojo::Collection 'c';
  mock_test(
    container(
      subreaper => 1,
      cgroups => cgroupv1(controller => 'pids', name => 'group')->child('test'),
      group   => "group",
      name    => "test",
      process => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));
  my $t_cgroup = cgroupv1(controller => 'pids', name => 'group')->child('test');
  mock_test(
    container(
      subreaper    => 1,
      pre_migrate  => 1,
      clean_cgroup => 1,
      cgroups      => c($t_cgroup),
      group        => "group",
      name         => "test",
      process      => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));

  ok !$t_cgroup->exists();

  mock_test(
    container(
      unshare      => 0,
      pre_migrate  => 1,
      clean_cgroup => 1,
      group        => "group",
      name         => "test",
      process      => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));

  mock_test(
    container(
      pre_migrate  => 1,
      clean_cgroup => 1,
      group        => "group",
      name         => "test",
      process      => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));


  my $c = container(
    pid_isolation => 1,
    pre_migrate   => 1,
    clean_cgroup  => 1,
    group         => "group",
    name          => "test",
    process       => process(
      sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
    ),
  );

  mock_test($c);

  ok $c->process->errored;

  monkey_patch "Mojo::IOLoop::ReadWriteProcess::Namespace",
    unshare => sub { 0 };

  is Mojo::IOLoop::ReadWriteProcess::Namespace::unshare(1), 0;
  mock_test(
    container(
      unshare      => Mojo::IOLoop::ReadWriteProcess::Namespace::CLONE_NEWIPC,
      clean_cgroup => 1,
      group        => "group",
      name         => "test",
      process      => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));

  mock_test(
    container(
      unshare      => 0,
      pre_migrate  => 1,
      clean_cgroup => 1,
      group        => "group",
      name         => "test",
      process      => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));

  mock_test(
    container(
      pre_migrate   => 1,
      pid_isolation => 1,
      clean_cgroup  => 1,
      group         => "group",
      name          => "test",
      process       => process(
        sub { sleep 5; Devel::Cover::report() if Devel::Cover->can('report'); }
      ),
    ));
};



done_testing;
