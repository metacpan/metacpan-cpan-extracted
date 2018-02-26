#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(process);
use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);

subtest SIG_CHLD => sub {
  my $test_script = "$FindBin::Bin/data/process_check.sh";
  plan skip_all =>
    "You do not seem to have bash, which is required (as for now) for this test"
    unless -e '/bin/bash';
  plan skip_all =>
"You do not seem to have $test_script. The script is required to run the test"
    unless -e $test_script;
  my $reached;
  my $collect = 0;

  my $p = process(sub { print "Hello\n" });
  $p->session->collect_status(0);
  $p->on(collect_status => sub { $collect++ });
  $p->session->on(
    SIG_CHLD => sub {
      my $self = shift;
      $reached++;
      waitpid $p->pid, 0;
    });

  $p->start;
  attempt {
    attempts  => 20,
    condition => sub { defined $reached && $reached == 1 },
    cb        => sub { $p->signal(POSIX::SIGTERM); sleep 1; }
  };

  is $reached, 1, 'SIG_CHLD fired';
  is $collect, 0, 'collect_status not fired';

  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all_orphans->size, 0);
  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all->size,         1);

  session->reset;
  my $p2 = process(execute => $test_script);
  $p2->session->collect_status(1);

  $reached = 0;

  $p2->on(
    SIG_CHLD => sub {
      my $self = shift;
      $reached++;
    });

  $p2->start;

  attempt {
    attempts  => 20,
    condition => sub { defined $reached && $reached == 1 },
    cb        => sub { $p2->signal(POSIX::SIGTERM); sleep 1; }
  };

  is $reached, 1, 'SIG_CHLD fired';
  ok defined($p2->exit_status), 'SIG_CHLD fired';

  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all_orphans->size, 0);
  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all->size,         1);
};

subtest collect_status => sub {
  session->reset;

  my $sigcld;
  my $p = process(sub { print "Hello\n" });
  $p->session->collect_status(0);
  $p->session->on(
    SIG_CHLD => sub {
      $sigcld++;
      waitpid $p->pid, 0;
    });
  $p->start;

  attempt {
    attempts  => 10,
    condition => sub { defined $sigcld && $sigcld == 1 },
    cb        => sub { $p->signal(POSIX::SIGTERM); sleep 1 }
  };

  is $sigcld, 1, 'SIG_CHLD fired';

  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all_orphans->size, 0);
  is(Mojo::IOLoop::ReadWriteProcess::Session->singleton->all->size,         1);
};


done_testing();
