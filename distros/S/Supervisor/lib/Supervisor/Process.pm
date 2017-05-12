package Supervisor::Process;

our $VERSION = '0.03';

use 5.008;

use POE;
use DateTime;
use Set::Light;
use POE::Wheel::Run;
use Supervisor::Log;
use POSIX qw(WIFSIGNALED WIFEXITED WEXITSTATUS WTERMSIG);

use Supervisor::Class
  version    => $VERSION,
  base       => 'Supervisor::Session',
  filesystem => 'FS',
  constants  => ':all',
  utils      => 'env_parse env_store env_create env_restore',
  accessors  => 'name command priority start_wait_secs start_retries
                 stop_signal stop_wait_secs stop_retries reload_signal 
                 mask user group directory environment wheel autostart 
                 autorestart exit_codes supervisor proc',
  mutators   => 'action exit_code exit_signal',
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub start_process {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my %oldenv;
    my $gid = getgrnam($self->group);
    my $uid = getpwnam($self->user);
    my $supervisor = $self->supervisor;

    $data->{name} = $self->name;

    if ($data->{retries} < $self->start_retries) {

        # save old stuff

        my $oldenv = env_store();
        my $oldmask = umask;
        my $olddir  = FS->cwd();

        # create new stuff

        umask $self->mask;
        chdir $self->directory;
        env_create($self->environment);

        # spawn the process

        $self->{wheel} = POE::Wheel::Run->new(
            StderrEvent => '_get_stderr',
            StdoutEvent => '_get_stdout',
            Group       => $gid,
            User        => $uid,
            Priority    => $self->priority,
            Program     => $self->command
        );

        # restore old stuff

        env_restore($oldenv);
        umask $oldmask;
        chdir $olddir;

        # see if it worked...

        $data->{retries}++;
        $self->log->info("pid = " . $self->wheel->PID);
        $kernel->delay_add('_start_process_timeout', $self->start_wait_secs, $data);

    } else {

        $self->status(STOP);
        delete $self->{wheel};
        $data->{status} = STOP;
        $kernel->post($supervisor, 'child_error', $data);

    }

}

sub stop_process {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $rc;
    my $supervisor = $self->supervisor;

    $data->{name} = $self->name;

    if ($data->{retries} < $self->stop_retries) {

        $data->{retries}++;
        kill($self->stop_signal, $self->wheel->PID);
        $kernel->delay_add('_stop_process_timeout', $self->stop_wait_secs, $data);

    } else {

        $self->status(STOP);
        delete $self->{wheel};
        $data->{status} = STOP;
        $kernel->post($supervisor, 'child_error', $data);

    }

}

sub kill_process {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $rc;
    my $supervisor = $self->supervisor;

    $data->{name} = $self->name;

    if ($data->{retries} < $self->stop_retries) {

        $data->{retries}++;
        kill(9, $self->wheel->PID);
        $kernel->delay_add('_stop_process_timeout', $self->stop_wait_secs, $data);

    } else {

        $self->status(STOP);
        delete $self->{wheel};
        $data->{status} = STOP;
        $kernel->post($supervisor, 'child_error', $data);

    }

}

sub reload_process {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $data->{name} = $self->name;

    my $supervisor = $self->supervisor;

    if (kill($self->reload_signal, $self->wheel->PID)) {

        $kernel->post($supervisor, 'child_reloaded', $data);

    }

}

sub stat_process {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $supervisor = $self->supervisor;

    $data->{name} = $self->name;

    if ($self->proc->exists) {

        $data->{status} = ALIVE;
        $kernel->post($supervisor, 'child_status', $data);

    } else {

        $data->{status} = DEAD;
        $kernel->post($supervisor, 'child_status', $data);

    }

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub start {
    my ($self, $data) = @_;

    my $supervisor = $self->supervisor;
    my $session_id = $self->session->ID;

    $data->{retries} = 1;

    if (($self->status eq STOP) or ($self->status eq EXIT)) {

        $self->action(START);
        $self->log->info("starting process");
        $poe_kernel->post($session_id, 'start_process', $data);

    } else {

        $data->{error} = STARTED;
        $self->log->warn("process is already started");
        $poe_kernel->post($supervisor, 'child_error', $data);

    }

}

sub stop {
    my ($self, $data) = @_;

    my $supervisor = $self->supervisor;
    my $session_id = $self->session->ID;

    $data->{retries} = 1;

    if ($self->status eq START) {

        $self->action(STOP);
        $self->log->info("stopping the process");
        $poe_kernel->post($session_id, 'stop_process', $data);

    } else {

        $data->{error} = STOPPED;
        $self->log->warn("process is already stopped");
        $poe_kernel->post($supervisor, 'child_error', $data);

    }

}

sub reload {
    my ($self, $data) = @_;

    my $rc = 0;
    my $supervisor = $self->supervisor;
    my $session_id = $self->session->ID;

    if ($self->status eq START) {

        $self->action(RELOAD);
        $self->log->info("sending a \"reload\" signal");
        $poe_kernel->post($session_id, 'reload_process', $data);

    } else {

        $data->{error} = STOPPED;
        $self->log->warn("process is stopped");
        $poe_kernel->post($supervisor, 'child_error', $data);

    }

}

sub stat {
    my ($self, $data) = @_;

    my $supervisor = $self->supervisor;
    my $session_id = $self->session->ID;

    $self->log->info("performing a query status");

    $self->action(STAT);
    $poe_kernel->post($session_id, 'stat_process', $data);

}

sub killme {
    my ($self) = @_;

    my $supervisor = $self->supervisor;
    my $session_id = $self->session->ID;
    my $data = {
        retries => 1,
    };

    if ($self->status eq START) {

        $self->action(KILLME);
        $self->log->info("killing the process");
        $poe_kernel->post($session_id, 'kill_process', $data);

    } else {

        $data->{error} = STOPPED;
        $self->log->warn("process is already stopped");
        $poe_kernel->post($supervisor, 'child_error', $data);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _initialize {
    my ($self, $kernel, $session) = @_;

    my @exit_codes;

    $kernel->state('_response', $self);
    $kernel->state('_get_stdout', $self);
    $kernel->state('_get_stderr', $self);
    $kernel->state('_child_exit', $self);
    $kernel->state('kill_process', $self);
    $kernel->state('stop_process', $self);
    $kernel->state('stat_process', $self);
    $kernel->state('start_process', $self);
    $kernel->state('reload_process', $self);
    $kernel->state('_stop_process_timeout', $self);
    $kernel->state('_start_process_timeout', $self);

    $self->{name}            = $self->config('Name');
    $self->{command}         = $self->config('Command');
    $self->{mask}            = oct($self->config('Umask'));
    $self->{user}            = $self->config('User');
    $self->{group}           = $self->config('Group');
    $self->{directory}       = $self->config('Directory');
    $self->{priority}        = $self->config('Priority');
    $self->{start_wait_secs} = $self->config('StartWaitSecs');
    $self->{start_retries}   = $self->config('StartRetries');
    $self->{stop_signal}     = $self->config('StopSignal');
    $self->{stop_wait_secs}  = $self->config('StopWaitSecs');
    $self->{stop_retries}    = $self->config('StopRetries');
    $self->{reload_signal}   = $self->config('ReloadSignal');
    $self->{autostart}       = $self->config('AutoStart');
    $self->{autorestart}     = $self->config('AutoRestart');
    $self->{supervisor}      = $self->config('Supervisor');

    @exit_codes = split(',', $self->config('ExitCodes'));

    $self->{action}      = "";
    $self->{exit_codes}  = Set::Light->new(@exit_codes);
    $self->{environment} = env_parse($self->config('Environment'));

}

sub _cleanup {
    my ($self, $kernel, $session) = @_;

    $self->log->warn("stopping session");

    if (my $wheel = $self->wheel) {

        delete $self->{wheel};

    }

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _get_stdout {
    my ($kernel, $self, $output, $wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $self->log->info($output);

}

sub _get_stderr {
    my ($kernel, $self, $output, $wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $self->log->error($output);

}

sub _child_exit {
    my ($kernel, $self, $exit) = @_[KERNEL,OBJECT,ARG2];

    my $supervisor  = $self->supervisor;
    my $exit_code   = WIFEXITED($exit)   ? WEXITSTATUS($exit) : undef;
    my $exit_signal = WIFSIGNALED($exit) ? WTERMSIG($exit)    : undef;
    my $data = {
        name => $self->name
    };

    $self->exit_code($exit_code)     if defined($exit_code);
    $self->exit_signal($exit_signal) if defined($exit_signal);
    $self->log->warn("process exited");
    $self->status(EXIT);

    $kernel->post($supervisor, 'child_exited', $data);

}

sub _start_process_timeout {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $wheel;
    my $supervisor = $self->supervisor;

    $data->{name} = $self->name;
    $self->log->debug("entering _start_process_timeout()");

    if ($wheel = $self->wheel) {

        $self->{proc} = FS->dir(PROC_ROOT, $wheel->PID);

        if ($self->proc->exists) {

            $self->log->debug("process is alive, telling the supervisor");

            $self->status(START);
            $kernel->sig_child($self->wheel->PID, '_child_exit');
            $kernel->post($supervisor, 'child_started', $data);

        } else {

            $self->log->debug("process is still not alive, retrying the start");
            $kernel->delay_add('start_process', $self->start_wait_secs, $data);

        }

    } else {

        $self->log->debug("process didn't initialize, retrying the start");
        $kernel->delay_add('start_process', $self->start_wait_secs, $data);

    }

    $self->log->debug("leaving _start_process_timeout()");

}

sub _stop_process_timeout {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    my $rc;
    my $wheel;
    my $supervisor = $self->supervisor;

    $self->log->debug("entering _stop_process_timeout()");

    if ($wheel = $self->wheel) {

        if (! $self->proc->exists) {

            $self->log->debug('process is dead, telling the supervisor');

            $self->status(STOP);
            $kernel->post($supervisor, 'child_stopped', $data);

        } else {

            $self->log->debug('process is still alive, retrying the stop');
            $kernel->delay_add('stop_process', $self->stop_wait_secs, $data);

        }

    } else {

        $self->log->debug('process is gone, telling the supervisor');

        $self->status(STOP);
        $kernel->post($supervisor, 'child_stopped', $data);

    }

    $self->log->debug("leaving _stop_process_timeout()");

}

sub _response {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];
    
    $self->log->info($data->{result});

}

1;

__END__

=head1 NAME

Supervisor::Process - Defines a managed process for the Supervisor environment

=head1 SYNOPSIS

A managed process is defined and started as follows:

 my $process = Supervisor::Process->new(
    Name          => 'sleeper',
    Command       => 'sleeper.sh',
    Umask         => '0022',
    User          => 'kesteb',
    Group         => 'users',
    Directory     => '/',
    Priority      => 0,
    StartWaitSecs => 10,
    StartRetries  => 5,
    StopSignal    => 'TERM',
    StopWaitSecs  => 10,
    StopRetries   => 5,
    ReloadSignal  => 'HUP',
    Autostart     => TRUE,
    AutoRestart   => TRUE,
    Supervisor    => 'Controller',
    Logfile       => '/dev/stdout',
    ExitCodes     =>  '0,1',
    Environment   => 'item=value;;item2=value2'
 );

 $process->start();

=head1 DESCRIPTION

A managed process is an object that knows how to start/stop/reload and 
return the status of that process. How the object knows what to do, is
defined by the parameters that are set when the object is created. Those
parameters are as follows.

=head2 PARAMETERS

=over 4

=item Name

The name the process is know by. A string value.

 Example:
  Name => 'test'

=item Command

The command to run within the process. A string value.

 Example:
  Command => '/home/kesteb/test.sh it works'

=item User

The user context the run the process under. No effort is made to check if the 
user actually exists. A string value.

 Example:
  User => 'kesteb'

=item Group

The group context to run the process under. No effort is made to check if the 
group actually exists. A string value.

 Example:
  Group => 'users'

=item Umask

The umask for this process. A string value.

 Example:
  Umask => "0022"

=item Directory

The directory to set default too when running the process. No effort is made
to make sure the directory is valid. A string value.

 Example:
  Directory => "/"

=item Priority

The priority to run the process at. An integer value.

 Example:
  Priority => 0

=item StartRetries

The number of retires when trying to start the process. An integer value.

 Example:
  StartRetries => 5

=item StartWaitSecs

The number of seconds to wait between attempts to start the process. An integer
value.

 Example:
  StartWaitSecs => 5

=item StopSignal

The signal to send when trying to stop the process. A string value. It should
be in a format that Perl understands.

 Example:
  StopSignal => 'TERM'

=item StopRetries

How many times to try and stop the process before issuing a KILL signal. An 
integer value.

 Example:
  StopRetries => 5

=item StopWaitSecs

The number of seconds to wait between attempts to stop the process. A intger value.

 Example:
  StopWaitSecs => 10

=item ReloadSignal

The signal to use to attempt a "reload" on the process. A string value. It 
should in a format that Perl understands.

 Example:
  ReloadSignal => 'HUP'

=item AutoStart

Wither the process should be auto started by a supervisor. A boolean value.

 Example:
  AutoStart => 1 (true)
  AutoStart => 0 (false)

=item AutoRestart

Wither to attempt to restart the process should it unexpectedly exit. A 
boolean value.

 Example:
  AutoRestart => 1 (true)
  AutoRestart => 0 (false)
 
=item Supervisor

The session name of a controlling supervisor. A string value.

 Example:
  Supervisor => 'Controller'

=item Logfile

The name of the log file to send output from stdout and stderr. A string value.

 Example: 
  Logfile => '/var/log/mylog.log'
  Logfile => '/dev/stdout'

=item ExitCodes

The expected exit codes from the process. If a returned exit code does not
match this list, the process will not be restarted. This should be a comma 
delimited list of integers. 

 Example:
  ExitCodes => 0,1

=item Environment

The environment variables for the process. This needs to be a formated string.

 Example: 
   Environment => 'item=value;;item2=value2'

=back

=head1 METHODS

=over 4

=item start

This method will start the process running. Will return "start" if successful.

=item stop

This method will stop the process. Will return "stop" if successful.

=item stat

This method will perform a "stat" on the process. It will return either 
"alive" or "dead".

=item reload

This method will send a signal to the process to "reload".

=item killme

This method will send a KILL signal to the process.

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
