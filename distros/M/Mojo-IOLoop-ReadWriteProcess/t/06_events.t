#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess              qw(process);
use Mojo::IOLoop::ReadWriteProcess::Session     qw(session);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt check_bin);

subtest SIG_CHLD => sub {
  my $test_script = check_bin("$FindBin::Bin/data/process_check.sh");
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

subtest collect_from_signal_handler => sub {
  check_bin('/bin/true');
  my $p         = process(execute => '/bin/true');
  my $collected = 0;
  my $orphan    = 0;
  my $sig_chld  = 0;
  $p->session->reset();
  $p->session->collect_status(1);    # needed, because previous test set it to 0
  $p->session->on(SIG_CHLD         => sub { $sig_chld++ });
  $p->session->on(collected        => sub { $collected++ });
  $p->session->on(collected_orphan => sub { $orphan++ });
  $p->start();

  attempt {
    attempts  => 10,
    condition => sub { $sig_chld > 0 && $collected > 0 },
  };

  is($sig_chld,  1, "Event for SIG_CHILD was emitted");
  is($collected, 1, "Event collected apear without doing active wait()");
  is($orphan,    0, "No orphans where collected");

  $p->wait_stop();
  is($collected,      1, "No more collect events emitted");
  is($orphan,         0, "No more orphans events emitted");
  is($p->exit_status, 0, '/bin/true exited with 0');

  exec('/bin/true') if (fork() == 0);

  attempt {attempts => 10, condition => sub { $sig_chld > 1 && $orphan > 0 },};

  is($sig_chld,  2, "Event for SIG_CHILD was emitted");
  is($collected, 1, "No more collect events emitted (2)");
  is($orphan,    1, "Collect one orphan");
};

subtest emit_from_sigchld_off => sub {
  check_bin('/bin/true');
  my $p         = process(execute => '/bin/true');
  my $collected = 0;
  my $orphan    = 0;
  my $sig_chld  = 0;
  $p->session->reset();
  $p->session->collect_status(1);
  $p->session->emit_from_sigchld(0);
  $p->session->on(SIG_CHLD         => sub { $sig_chld++ });
  $p->session->on(collected        => sub { $collected++ });
  $p->session->on(collected_orphan => sub { $orphan++ });
  $p->start();

  attempt {attempts => 10, condition => sub { $sig_chld > 0 },};
  is($sig_chld,  1, "Event for SIG_CHILD was emitted");
  is($collected, 0, "Event collected didn't appear from sighandler");
  is($orphan,    0, "No orphans where collected");

  $p->wait_stop();
  is($collected,      1, "No more collect events emitted");
  is($orphan,         0, "No more orphans events emitted");
  is($p->exit_status, 0, '/bin/true exited with 0');

  exec('/bin/true') if (fork() == 0);
  attempt {attempts => 10, condition => sub { $sig_chld > 1 },};
  is($collected, 1, "No more collect events emitted (2)");
  is($orphan,    0, "collect_orphan didn't appear from sighandler");

  $p->session->consume_collected_info();
  is($sig_chld,  2, "Event for SIG_CHILD was emitted");
  is($collected, 1, "No more collect events emitted (3)");
  is($orphan,    1, "Collect one orphan");
};

done_testing();
