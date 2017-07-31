package Proc::tored::Manager;
# ABSTRACT: OO interface to creating a proctored service
$Proc::tored::Manager::VERSION = '0.18';

use strict;
use warnings;
use Moo;
use Carp;
use Fcntl qw(:flock :seek :DEFAULT);
use Path::Tiny qw(path);
use Time::HiRes qw(sleep);
use Try::Tiny;
use Types::Standard -all;
use Proc::tored::Flag;
use Proc::tored::Machine;
use Proc::tored::PidFile;
use Proc::tored::Types -types;


has name         => (is => 'ro', isa => NonEmptyStr, required => 1);
has dir          => (is => 'ro', isa => Dir, required => 1);
has pid_file     => (is => 'lazy', isa => NonEmptyStr);
has stop_file    => (is => 'lazy', isa => NonEmptyStr);
has pause_file   => (is => 'lazy', isa => NonEmptyStr);
has trap_signals => (is => 'ro', isa => SignalList, default => sub {[]});

sub _build_pid_file {
  my $self = shift;
  my $file = path($self->dir)->child($self->name . '.pid');
  return "$file";
}

sub _build_stop_file {
  my $self = shift;
  my $file = path($self->dir)->child($self->name . '.stopped');
  return "$file";
}

sub _build_pause_file {
  my $self = shift;
  my $file = path($self->dir)->child($self->name . '.paused');
  return "$file";
}

has machine => (
  is  => 'lazy',
  isa => InstanceOf['Proc::tored::Machine'],
  handles => [qw(
    clear_flags
    stop start is_stopped
    pause resume is_paused
    read_pid running_pid is_running
  )],
);

sub _build_machine {
  my $self = shift;
  Proc::tored::Machine->new(
    pidfile_path => $self->pid_file,
    stop_path    => $self->stop_file,
    pause_path   => $self->pause_file,
    traps        => $self->trap_signals,
  );
}


sub stop_wait {
  my ($self, $timeout, $sleep) = @_;
  $sleep ||= 0.2;

  $self->stop;
  return if $self->is_running;

  my $pid = $self->running_pid || return 0;

  while (kill(0, $pid) && $timeout > 0) {
    sleep $sleep;
    $timeout -= $sleep;
  }

  !kill(0, $pid);
}


sub service {
  my ($self, $code) = @_;
  $self->machine->run($code);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Manager - OO interface to creating a proctored service

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  my $proctor = Proc::tored::Manager->new(dir => '/tmp', name => 'my-service');

  # Call do_stuff while the service is running or until do_stuff returns false
  $proctor->service(\&do_stuff)
    or die sprintf('process %d is already running this service!', $proctor->running_pid);

  # Signal another process running this service to quit gracefully, throwing an
  # error if it does not self-terminate after 15 seconds.
  if (my $pid = $proctor->stop_wait(15)) {
    die "process $pid is being stubborn!";
  }

=head1 DESCRIPTION

Objective interface for creating and managing a proctored service.

=head1 METHODS

=head2 new

Creates a new service object, which can be used to run the service and/or
signal another process to quit. The pid file is not created or accessed by this
method.

=over

=item name

The name of the service. Services created with an identical L</name> and
L</dir> will use the same pid file and share flags.

=item dir

A valid run directory (C</var/run> is a common choice). The path must be
writable.

=item pid_file

Unless manually specified, the pid file's path is L</dir>/L</name>.pid.

=item stop_file

Unless manually specified, the stop file's path is L</dir>/L</name>.stopped.

=item pause_file

Unless manually specified, the pause file's path is L</dir>/L</name>.paused.

=item trap_signals

An optional array of signals (suitable for use in C<%SIG>) allowed to end the
L</service> loop. Unless specified, no signal handlers are installed.

=back

=head1 METHODS

=head2 read_pid

Returns the pid identified in the pid file. Returns 0 if the pid file does
not exist or is empty.

=head2 running_pid

Returns the pid of an already-running process or 0 if the pid file does not
exist, is empty, or the process identified by the pid does not exist or is not
visible.

=head2 stop

=head2 start

=head2 is_stopped

Controls and inspects the "stopped" flag. While stopped, the L</service> loop
will refuse to run.

=head2 pause

=head2 resume

=head2 is_paused

Controls and inspects the "paused" flag. While paused, the L</service> loop
will continue to run but will not execute the code block passed in.

=head2 clear_flags

Clears both the "stopped" and "paused" flags.

=head2 is_running

Returns true if the current process is the active, running process.

=head2 stop_wait

Sets the "stopped" flag and blocks until the L<running_pid> exits or the
C<$timeout> is reached.

  $service->stop_wait(30); # stop and block for up to 30 seconds

=head2 service

Accepts a code ref which will be called repeatedly until it returns false or
the "stopped" flag is set. If the "paused" flag is set, will continue to rune
but will not execute the code block until the "paused" flag has been cleared.

Example using a pool of forked workers, an imaginary task queue, and a
secondary condition that decides whether to stop running.

  $proctor->service(sub {
    # Wait for an available worker, but with a timeout
    my $worker = $worker_pool->next_available(0.1);

    if ($worker) {
      # Pull next task from the queue with a 0.1s timeout
      my $task = poll_queue_with_timeout(0.1);

      if ($task) {
        $worker->assign($task);
      }
    }

    return if service_should_stop();
    return 1;
  });

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
