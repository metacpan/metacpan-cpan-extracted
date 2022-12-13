#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop::ReadWriteProcess              qw(process);
use Mojo::IOLoop::ReadWriteProcess::Session;
my $session = Mojo::IOLoop::ReadWriteProcess::Session->singleton;


subtest autodetect => sub {
  local $SIG{CHLD};

  my $reached;
  my $collect;
  my $status;
  my $fired;

  my $orphan2
    = process(sub { print "Hello from first process\n"; sleep 1 })->start;
  my $orphan
    = process(sub { print "Hello from second process\n"; sleep 1 })->start;
  my $p = process(
    sub {
      print "Hello from master process\n";
      sleep 2;
      return 2;
    });
  my $orphans = 0;
  $session->on(collected        => sub { $fired++ });
  $session->on(collected_orphan => sub { $orphans++ });

  $p->on(collect_status => sub { $status++ });

  $p->start();

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 10,
    condition => sub { defined $fired && $fired == 3 },
    cb        => sub { sleep 1 }
  };

  $p->stop;
  is $status,                       1, 'Status fired once';
  is $session->all_processes->size, 3, 'detection works' or die diag explain $p;
  ok $session->contains($orphan->pid), 'Orphan collected'
    or die diag explain $p->session->all;
  ok $session->contains($orphan2->pid), 'Orphan collected';
  ok !$session->contains(99999999),     'Session contain works as expected';

  is $fired,   3, 'New subprocess event fired';
  is $orphans, 0, 'New subprocess event fired';

  is $p->return_status, 2, 'Got exit status from master';
  $p->session->reset();
};

subtest autodetect_fork => sub {
  my $fired;
  my $status;
  local $SIG{CHLD};

  $session->reset;
  $session->on(collected        => sub { $fired++ });
  $session->on(collected_orphan => sub { $status++ });
  my $master_p = process(sub { exit 20 });

  $master_p->start();

  # Fork, and die after a bit
  my $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }
  $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }
  $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }
  $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }
  $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }
  $pid = fork;
  die "Cannot fork: $!" unless defined $pid;
  if ($pid == 0) { sleep 2; exit 110 }

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $status && $status == 6 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop;

  is $master_p->exit_status, 20, 'Correct exit status from master process';
  is $status,                6,  'Status fired 6 times';
  is $fired,                 1,  'Status fired 1 times';

  is $session->all->size, 7, 'detection works' or die diag explain $master_p;

  $session->all_orphans->each(
    sub { is $_->exit_status, 110, 'Correct status from process ' . $_->pid });

};


subtest subreaper => sub {
  plan skip_all => "Skipped unless TEST_SUBREAPER is set"
    unless $ENV{TEST_SUBREAPER};

  my $fired;
  my $status;
  my $orphans;
  local $SIG{CHLD};

  my $sys;
  eval {
    $sys = $session->_prctl(
      Mojo::IOLoop::ReadWriteProcess::Session::PR_SET_CHILD_SUBREAPER(), 1);
  };
  plan skip_all => "$@ : You do not seem to have subreaper capabilities"
    if ($@ || $sys != 0);

  $session->reset;

  my $master_p = process(
    sub {
      # Fork, and die after a bit
      my $pid = fork;
      die "Cannot fork: $!" unless defined $pid;
      if ($pid == 0) { sleep 2; exit 120 }
      $pid = fork;
      die "Cannot fork: $!" unless defined $pid;
      if ($pid == 0) {
        $pid = fork;
        die "Cannot fork: $!" unless defined $pid;
        if ($pid == 0) { sleep 2; exit 120 }
        exit 120;
      }
      $pid = fork;
      die "Cannot fork: $!" unless defined $pid;
      if ($pid == 0) {
        $pid = fork;
        die "Cannot fork: $!" unless defined $pid;
        if ($pid == 0) {
          $pid = fork;
          die "Cannot fork: $!" unless defined $pid;
          if ($pid == 0) {
            $pid = fork;
            die "Cannot fork: $!" unless defined $pid;
            if ($pid == 0) { sleep 2; exit 120 }
            sleep 2;
            exit 120;
          }
          exit 120;
        }
        exit 120;
      }
    });

  $master_p->subreaper(1);
  $session->on(collected        => sub { $fired++ });
  $session->on(collected_orphan => sub { $orphans++ });

# On start we setup the current process as subreaper
# So it's up on us to disable it after process is done. We can do that also when master process stops:
# $master_p->on(stop => sub { shift()->disable_subreaper });
  $master_p->start();

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $orphans && $orphans == 7 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop();
  is $fired,   1, 'collect_status fired 8 times';
  is $orphans, 7, 'new_subprocess fired 7 times';

  is $session->all_orphans->size, 7, 'detection works'
    or die diag explain $master_p;
  $session->all_orphans->each(
    sub { is $_->exit_status, 120, 'Correct status from process ' . $_->pid });

  $session->disable_subreaper;
};

subtest subreaper_bash => sub {

  plan skip_all => "Skipped unless TEST_SUBREAPER is set"
    unless $ENV{TEST_SUBREAPER};

  my $fired;
  my $status;
  my $orphans;
  local $SIG{CHLD};
  $session->reset;

  my $sys;
  eval {
    $sys = $session->_prctl(
      Mojo::IOLoop::ReadWriteProcess::Session::PR_SET_CHILD_SUBREAPER(), 1);
  };
  plan skip_all => "You do not seem to have subreaper capabilities"
    if ($@ || $sys != 0);
  my $test_script = "$FindBin::Bin/data/subreaper/master.sh";
  plan skip_all =>
    "You do not seem to have bash, which is required (as for now) for this test"
    unless -e '/bin/bash';
  plan skip_all =>
"You do not seem to have $test_script. The script is required to run the test"
    unless -e $test_script;

  my $master_p = process(
    sub {
      exec($test_script);
    });

  $master_p->subreaper(1);
  $session->on(collected        => sub { $fired++ });
  $session->on(collected_orphan => sub { $orphans++ });
  $master_p->start();
  is $master_p->subreaper, 1,
    'We are subreaper';    # Goes to 0 if attempt was unsuccessful

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $orphans && $orphans == 7 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop();
  is $fired,   1, 'collect_status fired 8 times';
  is $orphans, 7, 'new_subprocess fired 7 times';

  is $session->all_orphans->size, 7, 'detection works'
    or die diag explain $master_p;
  $session->disable_subreaper;

};


subtest subreaper_bash_execute => sub {
  my $fired;
  my $status;
  local $SIG{CHLD};
  $session->reset;

  my $sys;
  eval {
    $sys = $session->_prctl(
      Mojo::IOLoop::ReadWriteProcess::Session::PR_SET_CHILD_SUBREAPER(), 1);
  };
  plan skip_all => "You do not seem to have subreaper capabilities"
    if ($@ || $sys != 0);
  my $test_script = "$FindBin::Bin/data/subreaper/master.sh";
  plan skip_all =>
    "You do not seem to have bash, which is required (as for now) for this test"
    unless -e '/bin/bash';
  plan skip_all =>
"You do not seem to have $test_script. The script is required to run the test"
    unless -e $test_script;


  my $master_p
    = process(execute => $test_script, detect_subprocess => 1, subreaper => 1);
  my $orphans;
  $session->on(collected        => sub { $status++ });
  $session->on(collected_orphan => sub { $orphans++ });
  $master_p->start();
  is $master_p->subreaper, 1, 'We are subreaper';

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $orphans && $orphans == 7 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop();
  is $status,  1, 'collect_status fired 1 times';
  is $orphans, 7, 'new_subprocess fired 7 times';

  is $session->all_orphans->size, 7, 'detection works'
    or die diag explain $master_p;
  $session->disable_subreaper;
};


subtest manager => sub {
  my $fired;
  my $status;
  local $SIG{CHLD};
  $session->reset;

  my $sys;
  eval {
    $sys = $session->_prctl(
      Mojo::IOLoop::ReadWriteProcess::Session::PR_SET_CHILD_SUBREAPER(), 1);
  };
  plan skip_all => "You do not seem to have subreaper capabilities"
    if ($@ || $sys != 0);

  my $master_p = process(
    sub {
      my $p = shift;
      $p->enable_subreaper;

      process(sub { sleep 4; exit 1 })->start();
      process(
        sub {
          sleep 4;
          process(sub { sleep 1; })->start();
        })->start();
      process(sub { sleep 4; exit 0 })->start();
      process(sub { sleep 4; die })->start();
      my $manager = process(sub { sleep 2 })->subreaper(1)->start();
      sleep 1 for (0 .. 10);
      $manager->stop;
      return $manager->session->all->size;
    });

  $master_p->subreaper(1);

  $master_p->on(collected => sub { $status++ });

  # On start we setup the current process as subreaper
  # So it's up on us to disable it after process is done.
  $master_p->on(stop => sub { shift()->disable_subreaper });
  $master_p->start();

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $status && $status == 1 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop();
  is $status, 1, 'collect_status fired 1 times';

  is $session->all_orphans->size, 0, 'isolation works'
    or die diag explain $master_p;

  is $session->all->size, 1, 'isolation works' or die diag explain $master_p;
  is $master_p->return_status, 6,
    'detection works, 6 processes in total finished or died'
    or die diag explain $master_p;
  $session->disable_subreaper;

};


subtest subreaper_bash_roulette => sub {
  my $fired;
  my $status;
  local $SIG{CHLD};
  $session->reset;

  my $sys;
  eval {
    $sys = $session->_prctl(
      Mojo::IOLoop::ReadWriteProcess::Session::PR_SET_CHILD_SUBREAPER(), 1);
  };
  plan skip_all => "You do not seem to have subreaper capabilities"
    if ($@ || $sys != 0);
  my $test_script = "$FindBin::Bin/data/subreaper/roulette.sh";
  plan skip_all =>
    "You do not seem to have bash, which is required (as for now) for this test"
    unless -e '/bin/bash';
  plan skip_all =>
"You do not seem to have $test_script. The script is required to run the test"
    unless -e $test_script;

# In this tests the bash scripts are going to create child processes and then die immediately

  my $master_p = process(execute => $test_script);
  $master_p->subreaper(1);
  my $orphans;
  $session->on(collected        => sub { $fired++ });
  $session->on(collected_orphan => sub { $orphans++ });
  $master_p->start();
  is $master_p->subreaper, 1,
    'We are subreaper';    # Goes to 0 if attempt was unsuccessful

  # If we just sleep and then exit, we won't be able to catch signals
  attempt {
    attempts  => 20,
    condition => sub { defined $orphans && $orphans == 8 },
    cb        => sub { sleep 1 }
  };

  $master_p->stop();
  is $fired,   1, 'collect_status fired 8 times';
  is $orphans, 8, 'new_subprocess fired 7 times';

  is $session->all_orphans->size, 8, 'detection works'
    or die diag explain $master_p;
  is $master_p->exit_status, '1', 'Correct master process exit status';
  $session->disable_subreaper;
};


done_testing();
