#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile tempdir path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

use Mojo::IOLoop::ReadWriteProcess qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv2 cgroupv1);
use Mojo::IOLoop::ReadWriteProcess::Container qw(container);

eval {
  my $try_cgroup
    = cgroupv1(controller => 'pids', name => 'group')->child('test')->create;
  die unless $try_cgroup->exists();
};

plan skip_all => "This test works only if you have cgroups permissions" if $@;

subtest belongs => sub {
  cgroupv1(controller => 'pids', name => 'group')->create;
  my $cgroup = cgroupv1(controller => 'pids', name => 'group')->child('test');
  isa_ok $cgroup, 'Mojo::IOLoop::ReadWriteProcess::CGroup::v1';

  my $p = process(sub { sleep 400 });
  $p->start();

  $cgroup->add_process($p->pid);

  is $cgroup->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroup->process_list;

  ok $cgroup->contains_process($p->pid), "Parent contains pid " . $p->pid;

  $p->stop();

  is $p->is_running, 0;

  attempt {
    attempts  => 20,
    condition => sub { $cgroup->process_list eq '' },
    cb        => sub { sleep 1; }
  };

  is $cgroup->process_list, '';
  $cgroup->remove();

  ok !$cgroup->exists();

};

subtest childs => sub {
  my $cgroup = cgroupv1(controller => 'pids', name => 'group')->child('test');
  isa_ok $cgroup, 'Mojo::IOLoop::ReadWriteProcess::CGroup::v1';
  is $cgroup->exists(), 1, 'Cgroup exists';

  my $p = process(
    sub {
      process(sub { sleep 400 })->start;
      sleep 400;
    });
  $p->start();

  $cgroup->add_process($p->pid);

  is $cgroup->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroup->process_list;

  ok $cgroup->contains_process($p->pid), "Parent contains pid " . $p->pid;

  attempt {
    attempts  => 20,
    condition => sub { $cgroup->processes->size == 2 },
    cb        => sub { sleep 1; }
  };

  $p->stop();

  is $p->is_running, 0;

  is $cgroup->pid->current, "1\n";
  process(process_id => $_, blocking_stop => 1)->stop()
    for $cgroup->processes->each;
  is $cgroup->process_list, '' or diag explain $cgroup->process_list;
  $cgroup->remove();

  ok !$cgroup->exists();

};

subtest container_pid_isolation => sub {
  plan skip_all => "This test works only if you are root" if ($< != "0");

  if ($ENV{MOJO_PROCESS_DEBUG} eq "1") {
    local $ENV{MOJO_PROCESS_DEBUG}
      = 0;    # It will change our container output otherwise :(

    delete $INC{'Mojo/IOLoop/ReadWriteProcess.pm'};
    eval "no warnings; require Mojo::IOLoop::ReadWriteProcess";    ## no critic
  }

  my $c = container(
    pid_isolation => 1,
    subreaper     => 1,
    group         => "group",
    name          => "test",
    process       => process(
      sub {
        print "$$\n";
        process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
        process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
        process(
          sub {
            process(
              sub {
                process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
                warn "Hey";
                sleep 400;
                warn "Hey";
              })->start;
            warn "Hey";
            sleep 400;
            warn "Hey";
          })->start;
        sleep 400;

      }
    )->separate_err(0));
  $c->start();

  my @pids;
  my $fired;
  $c->session->on(register  => sub { push(@pids, shift) });
  $c->process->on(collected => sub { $fired++ });
  $c->once(stop => sub { $fired++ });

  my $p       = $c->process();
  my $cgroups = $c->cgroups;
  is $cgroups->first->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroups->first->process_list;

  ok $cgroups->first->contains_process($p->pid),
    "Parent contains pid " . $p->pid;

  my $virtual_pid;
  while (defined(my $line = $c->process->getline())) {
    $virtual_pid = $line;
  }
  chomp($virtual_pid);

  attempt {
    attempts  => 20,
    condition => sub { $cgroups->first->processes->size == 7 },
    cb        => sub { sleep 1; }
  };

  $c->stop();
  is $cgroups->first->process_list, ''
    or die diag explain $cgroups->first->process_list;
  $cgroups->first->remove();
  is scalar(@pids), 6 or diag explain \@pids;
  is $virtual_pid, '1', "Running process was PID 1 inside container";
  ok !$cgroups->first->exists();
  is $fired, 2;
};

subtest container_no_pid_isolation => sub {
  if ($ENV{MOJO_PROCESS_DEBUG} eq "1") {
    local $ENV{MOJO_PROCESS_DEBUG}
      = 0;    # It will change our container output otherwise :(
    delete $INC{'Mojo/IOLoop/ReadWriteProcess.pm'};
    eval "no warnings; require Mojo::IOLoop::ReadWriteProcess";    ## no critic
  }
  my $c = container(
    pid_isolation => 0,
    subreaper     => 1,
    group         => "group",
    name          => "test",
    process       => process(
      sub {
        print "$$\n";
        process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
        process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
        process(
          sub {
            process(
              sub {
                process(sub { warn "Hey"; sleep 400; warn "Hey"; })->start;
                warn "Hey";
                sleep 400;
                warn "Hey";
              })->start;
            warn "Hey";
            sleep 400;
            warn "Hey";
          })->start;
        sleep 400;

      }
    )->separate_err(0));
  $c->start();

  my @pids;
  $c->session->on(register => sub { push(@pids, shift) });

  my $p      = $c->process();
  my $cgroup = $c->cgroups->first;
  is $cgroup->process_list, $p->pid . "\n",
    "procs interface contains the added pids"
    or diag explain $cgroup->process_list;

  ok $cgroup->contains_process($p->pid), "Parent contains pid " . $p->pid;

  my $virtual_pid;
  while (defined(my $line = $c->process->getline())) {
    $virtual_pid = $line;
  }
  chomp($virtual_pid);

  attempt {
    attempts  => 20,
    condition => sub { $cgroup->processes->size == 6 },
    cb        => sub { sleep 1; }
  };
  is $cgroup->processes->size, 6 or diag explain $cgroup->process_list;

  $c->stop();
  is $cgroup->processes->size, 0;
  is $cgroup->process_list, '' or die diag explain $cgroup->process_list;
  $cgroup->remove();
  is scalar(@pids), 5 or diag explain \@pids;
  isnt $virtual_pid, '1',
    "Running process was not PID 1 inside container, but $virtual_pid";
  ok !$cgroup->exists();
};

done_testing;
