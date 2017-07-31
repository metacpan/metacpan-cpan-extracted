package Proc::tored;
# ABSTRACT: Service management using a pid file and touch files
$Proc::tored::VERSION = '0.18';
use strict;
use warnings;
require Exporter;
require Proc::tored::Manager;


use parent 'Exporter';

our @EXPORT = qw(
  service
  in
  trap

  pid
  running
  zap
  run

  stop
  start
  stopped

  pause
  resume
  paused
);

sub service ($%)  { Proc::tored::Manager->new(name => shift, @_) }
sub in      ($;@) { dir => shift, @_ }
sub trap    ($)   { trap_signals => shift, @_ }

sub pid     ($)   { $_[0]->read_pid }
sub running ($)   { $_[0]->running_pid }
sub zap     ($;@) { shift->stop_wait(@_) }
sub run     (&$)  { $_[1]->service($_[0]) }

sub stop    ($)   { $_[0]->stop }
sub start   ($)   { $_[0]->start }
sub stopped ($)   { $_[0]->is_stopped }

sub pause   ($)   { $_[0]->pause }
sub resume  ($)   { $_[0]->resume }
sub paused  ($)   { $_[0]->is_paused }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored - Service management using a pid file and touch files

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Proc::tored;
  use Getopt::Long;

  my %opt = (
    pause  => 0,
    resume => 0,
    stop   => 0,
    zap    => 0,
    start  => 0,
    run    => 0,
  );

  GetOptions(
    'pause'  => \$opt{pause},
    'resume' => \$opt{resume},
    'stop'   => \$opt{stop},
    'zap'    => \$opt{zap},
    'start'  => \$opt{start},
    'run'    => \$opt{run},
  );

  my $service = service 'stuff-doer', in '/var/run';
  my $pid = running $service;

  print "Running service found with pid $pid\n"
    if $pid;

  if ($opt{pause}) {
    # Set the paused flag, causing a running service to block until unset
    pause $service;
  }
  elsif ($opt{resume}) {
    # Unset the paused flag, unblocking any running service
    resume $service;
  }
  elsif ($opt{stop}) {
    # Set the stopped state, preventing new processes from starting the service
    # and causing running processes to self-terminate
    stop $service;
  }
  elsif ($opt{zap}) {
    # Terminate a running process, timing out after 15s
    zap $service, 15
      or die "stuff_doer $pid is being stubborn";
  }
  elsif ($opt{start}) {
    # Allow the service to start running again
    start $service;
  }

  if ($opt{run}) {
    # Run service (if not stopped)
    run { do_stuff() } $service;
  }

=head1 DESCRIPTION

A C<Proc::tored> service is voluntarily managed by a pid file and touch files.

C<Proc::tored> services are specified with a name and a path. Any services
created using the same name and path are considered the same service and will
be aware of other processes via their L</PID FILE> and respect service control
L</FLAGS>.

=head1 EXPORTED SUBROUTINES

All routines are exported by default.

=head2 service

=head2 in

=head2 trap

A proctored service is defined using the C<service> function. The name given to
the service is used in the naming of various files used to control the service
(e.g., pid file and touch files). The C<in> function is used to specify the
local directory where these files will be created and looked for. Signals may
be trapped using C<trap> on non-C<MSWin32> systems.

  my $service = service 'name-of-service', in '/var/run', trap ['TERM', 'INT'];

=head2 pid

Reads and returns the contents of the pid file. Does not check to determine
whether the pid is valid. Returns 0 if the pid file is not found or is empty.

  printf "service may be running under pid %d", pid $service;

=head2 running

Reads and returns the contents of the pid file after checking that the process
identified still exists. Essentially the same as C<kill(0, pid $service)>.
Returns 0 if the pid is not found or cannot be signalled.

  if (my $pid = running $service) {
    warn "service is already running under pid $pid";
  }

=head2 run

Begins the service in the current process. The service, specified as a code
block, will be called until it returns false or the L</stopped> flag is set.

If the L</paused> flag is set, the loop will continue to run without executing
the code block until it has been L</resume>d. If the L</paused> flag is set at
the time C<run> is called, the loop will start but will not begin executing the
code block until the flag is cleared.

If the L</stopped> flag is set, the loop will terminate at the completion of
the current iteration. If the L</stopped> flag is set at the time C<run> is
called, C<run> will return false immediately. The behavior under L</stopped>
takes priority over that of L</paused>.

  my $started = time;
  my $max_run_time = 300;

  run {
    if (time - $started > $max_run_time) {
      warn "Max run time ($max_run_time seconds) exceeded\n";
      warn "  -shutting down\n";
      return 0;
    }
    else {
      do_some_work();
    }

    return 1;
  } $service;

=head2 zap

Sets the "stopped" flag (see L</stop>), then blocks until a running service
exits. Returns immediately (after setting the "stopped" flag) if the
L</running> service is the current process.

  sub stop_service {
    if (my $pid = running $service) {
      print "Attempting to stop running service running under process $pid\n";

      if (zap $pid, 30) {
        print "  -Service shut down\n";
        return 1;
      }
      else {
        print "  -Timed out before service shut down\n";
        return 0;
      }
    }
  }

=head2 stop

=head2 start

=head2 stopped

Controls and inspects the "stopped" flag for the service.

  # Stop a running service
  if (!stopped $service && running $service) {
    stop $service;
  }

  do_work_while_stopped();

  # Allow service to start
  # Note that this does not launch the service process. It simply clears the
  # "stopped" flag that would have prevented it from running again.
  start $service;

=head2 pause

=head2 resume

=head2 paused

Controls and inspects the "paused" flag for the service. In general, this
should never be done inside the L</run> loop (see the warning in L</Pause and
resume>).

  # Pause a running service
  # Note that the running service will not exit. Instead, it will stop
  # executing its main loop until the "paused" flag is cleared.
  if (!paused $service && running $service) {
    pause $service;
  }

  do_work_while_paused();

  # Allow service to resume execution
  resume $service;

=head1 PID FILE

A pid file is used to identify a running service. While the service is running,
barring any outside interference, the pid will contain the pid of the running
process and a newline. After the service process stops, the pid file will be
truncated. The file will be located in the directory specified by L</in>. Its
name is the concatenation of the service name and ".pid".

=head1 FLAGS

Service control flags are persistent until unset. Their status is determined by
the existence of a touch file.

=head2 stopped

A touch file indicating that a running service should self-terminate and that
new processes should not start is created with L</stop> and removed with
L</start>. It is located in the directory specified by L</in>. Its name is the
concatenation of the service name and ".stopped".

=head2 paused

A touch file indicating that a running service should temporarily stop
executing and that new processes should start but not yet execute any service
code is created with L</pause> and removed with L</resume>. It is located in
the directory specified by L</in>. Its name is the concatenation of the service
name and ".paused".

=head1 BUGS AND LIMITATIONS

=head2 Pause and resume

When a service is L</paused>, the code block passed to L</run> is no longer
executed until I<something> calls L</resume>. This can lead to deadlock if
there is no external actor willing to L</resume> the service.

For example, this service will never resume:

  run {
    my $empty = out_of_tasks();

    if ($empty) {
      pause $service;
    }
    elsif (paused $service && !$empty) {
      # This line is never reached because this code block is no longer
      # executed after being paused above.
      resume $service;
    }

    do_next_task();
    return 1;
  } $service;

In most cases, pausing and resuming a service should be handled from outside of
L</run>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
