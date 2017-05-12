package Supervisor::Controller;

our $VERSION = '0.02';

use 5.008;
use POE;

use Supervisor::Class
  version   => $VERSION,
  base      => 'Supervisor::Session',
  utils     => 'params',
  constants => ':all',
  accessors => 'processes rpc',
  messages => {
    starting  => "starting processes",
    started   => "%s has started",
    stopped   => "%s has stopped",
    reloaded  => "%s has reloaded",
    exited    => "%s has exited",
    alive     => "%s is running",
    dead      => "%s is not running",
    status    => "%s is %s",
    restart   => "attempting to restart %s",
    checking  => "checking for running sessions",
    killing   => "killing %s",
    stopping  => "stopping %s session",
    shutdown  => "shutting down with the %s signal",
    exit_code => "exit code: %s, was not recognized for %s. restarting not attempted",
  }
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $data;
    my $processes = $self->processes;

    $self->log->info($self->message('starting'));

    foreach my $process (@$processes) {

        $process->start($data);

    }

}

sub handle_signals {
    my ($kernel, $self, $signal) = @_[KERNEL,OBJECT,ARG0];

    my $processes = $self->processes;

    $kernel->sig_handled();
    $self->status(SHUTDOWN);

    $self->log->warn($self->message('shutdown', $signal));

    foreach my $process (@$processes) {

        $self->log->info($self->message('killing', $process->name));
        $process->killme();

    }

}

sub check_sessions {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $running = TRUE;
    my $processes = $self->processes;

    $self->log->info($self->message('checking'));

    foreach my $process (@$processes) {

        if ($process->status eq START) {

            $running = FALSE;
            $process->killme();

        }

    }

    if ($running) {

        $kernel->yield('shutdown');

    } else {

        $kernel->delay_add('check_session', 5);

    }

}

# ----------------------------------------------------------------------
# Process Events
# ----------------------------------------------------------------------

sub child_started {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $self->log->info($self->message('started', $data->{name}));

    if (defined($data->{rpc})) {

        $data->{result} = STARTED;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub child_stopped {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $self->log->info($self->message('stopped', $data->{name}));

    if (defined($data->{rpc})) {

        $data->{result} = STOPPED;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub child_reloaded {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $self->log->info($self->message('reloaded', $data->{name}));

    if (defined($data->{rpc})) {

        $data->{result} = RELOADED;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub child_status {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $self->log->info($self->message('status', $data->{name}, $data->{status}));

    if (defined($data->{rpc})) {

        $data->{result} = $data->{status};
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub child_exited {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $processes = $self->processes;

    $self->log->warn($self->message('exited', $data->{name}));

    if ($self->status eq SHUTDOWN)  {

        foreach my $process (@$processes) {

            if ($data->{name} eq $process->name) {

                $self->log->info($self->message('stopping', $data->{name}));
                $kernel->post($process->session->ID, 'shutdown');
                last;

            }

        }

        $kernel->delay_add('check_sessions', 5);

    } else {

        foreach my $process (@$processes) {

            if ($data->{name} eq $process->name) {

                if ($process->action ne STOP) {

                    if ($process->exit_codes->has($process->exit_code)) {

                        if ($process->autorestart) {

                            $self->log->info($self->message('restart', $data->{name}));
                            $process->start($data);

                        }

                    } else {

                        my $code = $process->exit_code || "";
                        my $msg = $self->message('exit_code', $code, $data->{name});
                        $self->log->error($msg);
                        $kernel->post($process->session->ID, 'shutdown');

                    }
                    last;

                } else {
                    
                    $process->action("");
                    last;

                }

            }

        }

    }

}

sub child_error {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $processes = $self->processes;

    if (defined($data->{error})) {

        if (defined($data->{rpc})) {

            $data->{result} = $data->{error};
            $kernel->post($data->{rpc}, 'response', $data);

        }

    } elsif ($data->{status} eq START) {

        foreach my $process (@$processes) {

            if ($data->{name} eq $process->name) {

                if ($process->autorestart) {

                    $self->log->info($self->message('restart', $data->{name}));
                    $process->start($data);

                }

            }

        }

    } elsif ($data->{status} eq STOP) {

        if (defined($data->{rpc})) {

            $data->{result} = $data->{status};
            $kernel->post($data->{rpc}, 'response', $data);

        }

    }

}

# ----------------------------------------------------------------------
# RPC Events
# ----------------------------------------------------------------------

sub stop_process {
    my ($kernel, $self, $sender, $data) = @_[KERNEL,OBJECT,SENDER,ARG0];

    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->name eq $data->{name}) {

            $process->stop($data);
            return;

        }

    }

    if (defined($data->{rpc})) {

        $data->{result} = UNKNOWN;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub stat_process {
    my ($kernel, $self, $sender, $data) = @_[KERNEL,OBJECT,SENDER,ARG0];

    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->name eq $data->{name}) {

            $process->stat($data);
            return;

        }

    }

    if (defined($data->{rpc})) {

        $data->{result} = UNKNOWN;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub start_process {
    my ($kernel, $self, $sender, $data) = @_[KERNEL,OBJECT,SENDER,ARG0];

    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->name eq $data->{name}) {

            $process->start($data);
            return;

        }

    }

    if (defined($data->{rpc})) {

        $data->{result} = UNKNOWN;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub reload_process {
    my ($kernel, $self, $sender, $data) = @_[KERNEL,OBJECT,SENDER,ARG0];

    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->name eq $data->{name}) {

            $process->reload($data);
            return;

        }

    }

    if (defined($data->{rpc})) {

        $data->{result} = UNKNOWN;
        $kernel->post($data->{rpc}, 'response', $data);

    }

}

sub stop_supervisor {
    my ($kernel, $self, $sender, $data) = @_[KERNEL,OBJECT,SENDER,ARG0];
    
}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub run {
    my ($self) = @_;

    $poe_kernel->run;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _initialize {
    my ($self, $kernel, $session) = @_;

    # communications from the Processes

    $kernel->state('child_error', $self);
    $kernel->state('child_status', $self);
    $kernel->state('child_exited', $self);
    $kernel->state('child_started', $self);
    $kernel->state('child_stopped', $self);
    $kernel->state('child_reloaded', $self);

    # communications from the RPC Server.

    $kernel->state('stop_process', $self);
    $kernel->state('stat_process', $self);
    $kernel->state('start_process', $self);
    $kernel->state('reload_process', $self);
    $kernel->state('stop_supervisor', $self);

    # supervisor internal functions

    $kernel->state('handle_signals', $self);
    $kernel->state('check_sessions', $self);

    $kernel->sig(INT => 'handle_signals');
    $kernel->sig(HUP => 'handle_signals');
    $kernel->sig(TERM => 'handle_signals');
    $kernel->sig(QUIT => 'handle_signals');
    $kernel->sig(ABRT => 'handle_signals');

    $self->{rpc}       = $self->config('RPC');
    $self->{processes} = $self->config('Processes');

}

sub _cleanup {
    my ($self, $kernel, $session) = @_;

    $poe_kernel->post($self->rpc->session->ID, 'shutdown');
    $self->log->warn("shutting down");

}

1;

__END__

=head1 NAME

Supervisor::Controller - Controls the Superviors environment

=head1 SYNOPSIS

 my $supervisor = Supervisor::Controller->new(
     Name => 'supervisor',
     Logfile => 'supervisor.log',
     Processes => Supervisor::ProcessFactory->load(
         Config => 'supervisor.ini',
         Supervisor => 'supervisor'
    )
 );

 $supervisor->run;

 or with the RPC interaction

 my $supervisor = Supervisor::Controller->new(
     Name => 'supervisor',
     Logfile => 'supervisor.log',
     Processes => Supervisor::ProcessFactory->load(
         Config => 'supervisor.ini',
         Supervisor => 'suprvisor',
     ),
     RPC => Supervisor::RPC::Server->new(
         Name => 'rpc',
         Port => 9505,
         Address => 127.0.0.1,
         Logfile => 'supervisor.log'
         Supervisor => 'supervisor',
     )
 );

 $supervisor->run;

=head1 DESCRIPTION

This module is designed to control multiple managed processes. It will attempt
to keep them running. Additionally it will shut them down when the supervisor 
is signalled to stop. The following signals will start the shutdown actions:

=over 4

 INT
 TERM
 HUP
 QUIT
 ABRT

=back

Optionally it can allow external agents access, so that they can interact with 
the managed processes thru a RPC mechaniasm.

=head2 PARAMETERS

=over 4

=item Name

The name for the supervisors session.

=item Logfile

The name of the logfile for the supervisor

=item Processes

The managed processes that the supervisor will manage.

=item RPC

The rpc server to interact with and on behalf of the processes.

=back

=head1 METHODS

=over 4

=item run

This method starts the endless loop.

=back

=head1 SEE ALSO

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
