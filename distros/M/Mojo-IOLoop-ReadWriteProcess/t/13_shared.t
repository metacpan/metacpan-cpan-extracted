#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile tempdir path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

use Mojo::IOLoop::ReadWriteProcess
  qw(process queue shared_memory lock semaphore);
use Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore;
use Mojo::IOLoop::ReadWriteProcess::Shared::Lock;
use Mojo::IOLoop::ReadWriteProcess::Shared::Memory;
use Data::Dumper;

use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};
plan skip_all => "Skipped unless TEST_SHARED is set" unless $ENV{TEST_SHARED};

subtest 'semaphore' => sub {

  my $sem_key = 33131;

  my $sem = Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore::semaphore(
    key => $sem_key);

  ok(defined $sem->id, ' We have semaphore id ( ' . $sem->id . ' )');
  ok(defined $sem->stat,
    ' We have semaphore stats ( ' . Dumper($sem->stat) . ' )');
  is($sem->stat->[7], 1, 'Default semaphore size is 1');

  $sem->setval(0, 1);
  is $sem->getval(0), 1, 'Semaphore value set to 1';
  $sem->setval(0, 0);
  is $sem->getval(0), 0, 'Semaphore value set 0';
  $sem->setval(0, 1);
  is $sem->getval(0), 1, 'Semaphore value set to 1';
  $sem->setall(0);
  is $sem->getval(0), 0, 'Semaphore value set 0';
  $sem->setval(0, 1);

  is $sem->getall,  1, 'We have one semaphore, which is free to go';
  is $sem->getncnt, 0, '0 Processes waiting for the semaphore';

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(50);

  $q->add(
    process(
      sub {
        my $sem = semaphore(key => $sem_key);
        my $e = 1;
        if ($sem->acquire({wait => 1, undo => 0})) {
          $e = 0;
          $sem->release();
        }
        Devel::Cover::report() if Devel::Cover->can('report');
        exit($e);
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();

  is $q->done->size, 20, '20 Processes consumed';

  $q->done->each(
    sub {
      is $_[0]->exit_status, 0,
          "Process: "
        . shift->pid
        . " exited with 0 (semaphore acquired at least once)";
    });

  $sem->remove;
};

subtest 'lock' => sub {
  my $k = 2342385;
  my $lock
    = Mojo::IOLoop::ReadWriteProcess::Shared::Lock::shared_lock(key => $k);

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(50);

  $q->add(
    process(
      sub {
        my $l = lock(key => $k);
        my $e = 1;
        if ($l->lock) {
          $e = 0;
          $l->unlock;
        }
        Devel::Cover::report() if Devel::Cover->can('report');
        exit($e);
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();

  is $q->done->size, 20, '20 Processes consumed';
  $q->done->each(
    sub {
      is $_[0]->exit_status, 0,
          "Process: "
        . shift->pid
        . " exited with 0 (semaphore acquired at least once)";
    });

  $lock->remove();

};

subtest 'lock section' => sub {

  my $lock
    = Mojo::IOLoop::ReadWriteProcess::Shared::Memory::shared_lock(key => 3331);

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(50);

  $q->add(
    process(
      sub {
        my $l = lock(key => 3331);
        my $e = 1;
        $l->section(sub { $e = 0 });

        Devel::Cover::report() if Devel::Cover->can('report');
        exit($e);
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();
  is $q->done->size, 20, '20 Processes consumed';
  $q->done->each(
    sub {
      is $_[0]->exit_status, 0,
          "Process: "
        . shift->pid
        . " exited with 0 (semaphore acquired at least once)";
    });
  $lock->remove;
};

subtest 'concurrent memory read/write' => sub {
  use IPC::SysV 'ftok';

  my $k = ftok($0, 0);
  my $mem = shared_memory(key => $k);
  $mem->_lock->remove;
  my $default = shared_memory;
  is $default->key, $k, "Default memory key is : $k";

  $mem = shared_memory(key => $k);
  $mem->clean;
  $mem->_lock->remove;

  $mem = shared_memory(key => $k);
  $mem->lock_section(sub { $mem->buffer('start') });

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(50);

  $q->add(
    process(
      sub {

        my $mem = shared_memory(key => $k);
        srand time;
        $mem->lock_section(
          sub {
            # Random sleeps to try to make threads race into lock section
            unless (DEBUG) {
              do {
                warn "$$: Sleeping inside locked section";
                sleep rand(int(2));
                }
                for 1 .. 5;
            }
            my $b = $mem->buffer;
            $mem->buffer($$ . " $b");
            Devel::Cover::report() if Devel::Cover->can('report');
          });
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();

  $mem = shared_memory(key => $k);
  $mem->lock_section(
    sub {
      ok((length $mem->buffer > 0), 'Buffer is there');
    });
  $mem->lock_section(
    sub {
      my @pids = split(/ /, $mem->buffer);
      is scalar @pids, 21, 'There are 20 pids and the start word (21)';
    });

  $mem->_lock->remove;
  $mem->remove;
};

sub free_mem {
  my $mem = shared_memory;
  $mem->_lock->remove;
  $mem->remove;

  $mem = shared_memory;
  $mem->clean;
  $mem->_lock->remove;

  $mem = shared_memory;

  if ($mem->try_lock) {
    $mem->buffer(freeze({}));
    $mem->unlock;
  }
}

sub test_mem {
  my $mem = shared_memory(destroy => 1);
  $mem->lock_section(
    sub {
      ok((length $mem->buffer > 0), 'Buffer is there');
      my $data = thaw($mem->buffer);
      my @pids = keys %{$data};
      is scalar @pids, 20, 'There are 20 pids';
      diag explain $data;
    });

  is $mem->stat->[8], 0, 'No process attached to memory';
}

subtest 'storable' => sub {
  use Storable qw(freeze thaw);
  use Mojo::IOLoop::ReadWriteProcess::Shared::Memory
    qw(shared_lock shared_memory semaphore);

  free_mem;

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(50);

  $q->add(
    process(
      sub {
        my $mem = shared_memory;
        $mem->lock_section(
          sub {
            unless (DEBUG) {
              do {
                warn "$$: Sleeping inside locked section";
                sleep rand(int(2));
                }
                for 1 .. 5;
            }
            my $data = thaw($mem->buffer);
            $data->{$$}++;
            $mem->buffer(freeze($data));
            Devel::Cover::report() if Devel::Cover->can('report');
          });
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();
  is $q->done->size, 20, 'Queue consumed 20 processes';

  test_mem;
};

#
# subtest 'locking with undo' => sub {
#   use Storable qw(freeze thaw);
#
#   free_mem;
#
#   my $q = queue;
#   $q->pool->maximum_processes(10);
#   $q->queue->maximum_processes(50);
#
#   $q->add(
#     process(
#       sub {
#         my $mem = shared_memory;
#
#         if ($mem->lock(undo => 1, wait => 1))
#         {    # Do not unlock/release with undo => 1
#         eval {  my $data = thaw($mem->buffer);
#           $data->{$$}++;
#           $mem->buffer(freeze($data));
#                 $mem->save();
#         };
#         warn "FAILED UNDO $@" if $@;
#
#         #  $mem->unlock();
#         }
#         Devel::Cover::report() if Devel::Cover->can('report');
#         exit(0);
#       }
#     )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;
#
#   $q->consume();
#   is $q->done->size, 20, 'Queue consumed 20 processes';
#
#   test_mem;
# };

subtest 'dying in locked section' => sub {
  use Storable qw(freeze thaw);

  free_mem;

  my $q = queue;
  $q->pool->maximum_processes(10);
  $q->queue->maximum_processes(20);

  $q->add(
    process(
      sub {
        my $mem = shared_memory;
        $mem->lock_section(
          sub {
            unless (DEBUG) {
              do {
                warn "$$: Sleeping inside locked section";
                sleep rand(int(2));
                }
                for 1 .. 5;
            }
            my $data = thaw($mem->buffer);
            $data->{$$}++;
            $mem->buffer(freeze($data));
            Devel::Cover::report() if Devel::Cover->can('report');
            die("Process failed!");
          });
        Devel::Cover::report() if Devel::Cover->can('report');
      }
    )->set_pipes(0)->internal_pipes(0)) for 1 .. 20;

  $q->consume();
  is $q->done->size, 20, 'Queue consumed 20 processes';

  test_mem;
};

done_testing();
