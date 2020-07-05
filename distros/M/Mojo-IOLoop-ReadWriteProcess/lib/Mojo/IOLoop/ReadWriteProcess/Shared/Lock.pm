package Mojo::IOLoop::ReadWriteProcess::Shared::Lock;

use Mojo::Base 'Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore';

our @EXPORT_OK = qw(shared_lock semaphore);
use Exporter 'import';
use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

# Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore has same defaults - but locks have 1 count and 1 as setup value
# Make it explict
has count  => 1;
has _value => 1;
has locked => 0;

sub shared_lock { __PACKAGE__->new(@_) }

sub lock {
  my $self = shift;
  warn "[debug:$$] Attempt to acquire lock " . $self->key if DEBUG;
  my $r = @_ > 0 ? $self->acquire(@_) : $self->acquire(wait => 1, undo => 0);
  warn "[debug:$$] lock Returned : $r" if DEBUG;
  $self->locked(1)                     if defined $r && $r == 1;
  return $r;
}

sub lock_section {
  my ($self, $fn) = @_;
  warn "[debug:$$] Acquiring lock (blocking)" if DEBUG;
  1 while $self->lock != 1;
  warn "[debug:$$] Lock acquired $$" if DEBUG;

  my $r;
  {
    local $@;
    $r = eval { $fn->() };
    $self->unlock();
    warn "[debug:$$] Error inside locked section : $@" if $@ && DEBUG;
  };
  return $r;
}

*section = \&lock_section;

sub try_lock { shift->acquire(undo => 0, wait => 0) }

sub unlock {
  my $self = shift;
  warn "[debug:$$] UNLock " . $self->key if DEBUG;
  my $r;
  eval {
    $r = $self->release(@_);
    $self->locked(0) if defined $r && $r == 1;
  };
  return $r;
}

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Shared::Lock - IPC Lock

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess qw(process queue lock);

    my $q = queue; # Create a Queue
    $q->pool->maximum_processes(10); # 10 Concurrent processes at maximum
    $q->queue->maximum_processes(50); # 50 is maximum total to be allowed in the queue

    $q->add(
      process(
        sub {
          my $l = lock(key => 42); # IPC Lock
          my $e = 1;
          if ($l->lock) { # Blocking lock acquire
            # Critical section
            $e = 0;
            $l->unlock;
          }
          exit($e);
        }
      )->set_pipes(0)->internal_pipes(0)) for 1 .. 20; # Fill with 20 processes

    $q->consume(); # Consume the processes

=head1 DESCRIPTION

L<Mojo::IOLoop::ReadWriteProcess::Shared::Lock> uses L<IPC::Semaphore> internally and creates a Lock from a semaphore that is available across different processes.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Shared::Lock> inherits all events from L<Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore> and implements
the following new ones.

=head2 lock/unlock

    use Mojo::IOLoop::ReadWriteProcess qw(lock);

    my $l = lock(key => "42"); # Create Lock with key 42

    if ($l->lock) { # Blocking call
      # Critical section
      ...

      $l->unlock; # Release the lock
    }

Acquire access to the lock and unlocks it.

C<lock()> has the same arguments as L<Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore> C<acquire()>.

=head2 try_lock

    use Mojo::IOLoop::ReadWriteProcess qw(lock);

    my $l = lock(key => "42"); # Create Lock with key 42

    if ($l->try_lock) { # Non Blocking call
      # Critical section
      ...

      $l->unlock; # Release the lock
    }

Try to acquire lock in a non-blocking way.

=head2 lock_section

    use Mojo::IOLoop::ReadWriteProcess qw(lock);
    my $l = lock(key => 3331);
    my $e = 1;
    $l->lock_section(sub { $e = 0; die; }); # or also $l->section(sub { $e = 0 });

    $l->locked; # is 0

Executes a function inside a locked section. Errors are catched so lock is released in case of failures.

=head1 ATTRIBUTES

L<Mojo::IOLoop::ReadWriteProcess::Shared::Lock> inherits all attributes from L<Mojo::IOLoop::ReadWriteProcess::Shared::Semaphore> and provides
the following new ones.

=head2 flags

    use Mojo::IOLoop::ReadWriteProcess qw(lock);
    use IPC::SysV qw(IPC_CREAT IPC_EXCL S_IRUSR S_IWUSR);

    my $l = lock(flags=> IPC_CREAT | IPC_EXCL | S_IRUSR | S_IWUSR);

Sets flag for the lock. In such way you can limit the access to the lock, e.g. to specific user/group process.

=head2 key

    use Mojo::IOLoop::ReadWriteProcess qw(lock);
    my $l = lock(key => 42);

Sets the lock key that is used to retrieve the lock among different processes, must be an integer.

=head2 locked

    use Mojo::IOLoop::ReadWriteProcess qw(lock);

    my $l = lock(key => 42);

    $l->lock_section(sub {
      $l->locked; # 1
    });

    $l->locked; # 0

Returns the lock status

=head1 DEBUGGING

You can set MOJO_PROCESS_DEBUG environment variable to get diagnostics about the process execution.

    MOJO_PROCESS_DEBUG=1

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

!!42;
