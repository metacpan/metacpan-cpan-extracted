#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(parallel batch process pool);

subtest parallel => sub {
  my $n_proc = 4;
  my $fired;

  my $c = parallel(
    code                  => sub { sleep 2; print "Hello world\n"; },
    kill_sleeptime        => 1,
    sleeptime_during_kill => 1,
    separate_err          => 1,
    set_pipes             => 1,
    $n_proc
  );

  isa_ok($c, "Mojo::IOLoop::ReadWriteProcess::Pool");
  is $c->size(), $n_proc;

  $c->once(stop => sub { $fired++; });
  $c->start();
  $c->each(sub { my $p = shift; $p->wait; is $p->getline(), "Hello world\n"; });
  $c->wait_stop;
  is $fired, $n_proc;

  $c->once(stop => sub { $fired++ });
  my $b = $c->restart();
  is $b, $c;
  sleep 3;
  $c->wait_stop;
  is $fired, $n_proc * 2;
};

subtest batch => sub {
  my @stack;
  my $n_proc = 2;
  my $fired;

  push(
    @stack,
    process(
      code         => sub { sleep 2; print "Hello world\n" },
      separate_err => 0,
      set_pipes    => 1
    )) for (1 .. $n_proc);

  my $c = batch @stack;

  isa_ok($c, "Mojo::IOLoop::ReadWriteProcess::Pool");
  is $c->size(), $n_proc;

  $c->once(stop => sub { $fired++; });
  my @procs = $c->start();
  $c->each(sub { my $p = shift; $p->wait; is $p->getline(), "Hello world\n"; });
  $c->wait_stop;

  is $fired, $n_proc;
  is scalar(@procs), $n_proc;

  $c->add(
    code         => sub { print "Hello world 3\n" },
    separate_err => 0,
    set_pipes    => 1
  );
  $c->start();
  is $c->last->getline, "Hello world 3\n";
  $c->wait_stop();

  my $result;
  $c->add(code => sub { return 40 + 2 }, separate_err => 0, set_pipes => 0);
  $c->last->on(
    stop => sub {
      $result = shift->return_status;
    });
  $c->last->start()->wait_stop();
  is $result, 42;
};

subtest "Working with pools" => sub {
  my $n_proc = 5;
  my $number = 1;
  my $pool   = batch;
  for (1 .. $n_proc) {
    $pool->add(
      code => sub {
        my $self   = shift;
        my $number = shift;
        sleep 2;
        return 40 + $number;
      },
      args                  => $number,
      set_pipes             => 0,
      separate_err          => 0,
      kill_sleeptime        => 1,
      sleeptime_during_kill => 1,
    );
    $number++;
  }
  my $results;
  $pool->once(stop => sub { $results->{+shift()->return_status}++; });
  $pool->start->wait_stop;
  my $i = 1;
  for (1 .. $n_proc) {
    is $results->{40 + $i}, 1;
    $i++;
  }
  ok $pool->get(0) != $pool->get(1);
  ok $pool->get(3);
  $pool->remove(3);
  is $pool->get(3), undef;
};

subtest maximum_processes => sub {
  my $p = pool();
  $p->maximum_processes(1);
  $p->add(sub { print "Hello\n" });
  $p->add(sub { print "Wof\n" });
  $p->add(sub { print "Wof2\n" });
  is $p->get(1), undef;
  is $p->size,              1;
  is $p->maximum_processes, 1;
};

subtest stress_test => sub {
  plan skip_all => "set STRESS_TEST=1 (be careful)" unless $ENV{STRESS_TEST};

  # Push the maximum_processes boundaries and let's see events are fired.
  my $n_proc = 2000;
  my $fired;
  my $p = pool;
  $p->maximum_processes($n_proc);
  $p->add(
    code           => sub { sleep 3; exit(20) },
    internal_pipes => 0,
    set_pipes      => 0
  ) for 1 .. $n_proc;
  $p->once(stop => sub { $fired++ });
  $p->start->wait;
  is $fired, $n_proc;
  $p->each(sub { is $_->exit_status, "20" });
};

done_testing;
