package Supervisor::ProcessFactory;

our $VERSION = '0.02';

use 5.008;

use Config::IniFiles;
use Supervisor::Process;

use Supervisor::Class
  version   => $VERSION,
  base      => 'Supervisor::Base Badger::Prototype',
  utils     => 'params env_dump',
  constants => ':all',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load {
    my $self = shift;

    $self = $self->prototype() unless ref $self;
    my $params = params(@_);

    my $cfg;
    my @sections;
    my @processes;
    my $env = env_dump();
    my $logfile = $params->{'Logfile'} || '/dev/stdout';
    my $ex = 'supervisor.processfactory.load';

    if ($cfg = Config::IniFiles->new(-file => $params->{'Config'})) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /program:.*/);

            my $process = Supervisor::Process->new(
                Command       => $cfg->val($section, 'command', ''),
                Name          => $cfg->val($section, 'name', ''),
                User          => $cfg->val($section, 'user', ''),
                Group         => $cfg->val($section, 'group', ''),
                Directory     => $cfg->val($section, 'directory', "/"),
                Environment   => $cfg->val($section, 'environment', $env),
                Umask         => $cfg->val($section, 'umask', '0022'),
                ExitCodes     => $cfg->val($section, 'exit-codes', '0,1'),
                Priority      => $cfg->val($section, 'priority', '0'),
                AutoStart     => $cfg->val($section, 'auto-start', TRUE),
                AutoRestart   => $cfg->val($section, 'auto-restart', TRUE),
                StopSignal    => $cfg->val($section, 'stop-signal', 'TERM'),
                StopRetries   => $cfg->val($section, 'stop-retries', '5'),
                StopWaitSecs  => $cfg->val($section, 'stop-wait-secs', '10'),
                StartRetries  => $cfg->val($section, 'start-retries', '5'),
                StartWaitSecs => $cfg->val($section, 'start-wait-secs', '10'),
                ReloadSignal  => $cfg->val($section, 'reload-signal', 'HUP'),
                Logfile       => $cfg->val($section, 'logfile', $logfile),
                Supervisor    => $params->{'Supervisor'},
                Debug         => $params->{'Debug'},
            );

            push(@processes, $process);

        }

    } else {

        $ex .= '.badini';
        $self->throw_msg($ex, 'badini', $params->{'Config'});

    }

    return \@processes;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    return $self;

}

1;

__END__

=head1 NAME

Supervisor::ProcessFactory - factory method to load processes

=head1 SYNOPSIS

This module is used to create multiple processes from a configuration file.

 my @processes = Supervisor::ProcessFactory->load(
    Config => 'supervisor.ini'
 );

 foreach my $process (@processes) {

     $process->start();

 }

=head1 DESCRIPTION

This module will take a configuration file and initilize all the managed 
processes defined within. The configuration follows the familiar Win32 .ini 
format. It is based, partially, on the configuration file used by the
Supervisord project. Here is an example:

 ; My configuration file
 ;
 [program:test]
 command = /home/kesteb/outside/Supervisor/trunk/bin/test.sh
 name = test
 user = kesteb

This is the minimum of items needed to define a managed process. There are many
more available. So what does this minimum show: 

=over 4

o Item names are case sensitve.

o A ";" indicates the start of a comment.

o The section header must be unique and start with "program:".

o It defines the command to be ran.

o It defines a name that will be used to control the process.

o It defines the user context that the command will be ran under.

=back

These configuration items have corresponding parameters in Supervisor::Process.

=head1 ITEMS

=over 4

=item command

This specifies the command to be ran. This must be supplied. It is directly
related to the Command parameter.

=item name

This specifies the name of the process. This must be supplied. It is directly
related to the Name parameter.

=item user

This specifies the user context this command will run under. This must be
supplied. It is directly related to the User parameter.

=item directory

The directory to set as the default before running the command. Defaults to
"/". It is directly related to the Directory parameter.

=item environment

The environment variables that are set before running the command. Defaults to
the environment varaibles within the main supervisor's processes context. It 
is directly related to the Environment parameter.

=item umask

The unask of the command that is being ran. It defaults to "0022". It is
directly related to the Umask parameter.

=item exit-codes

The expected exit codes from the process. It defaults to "0,1" and is an array.
If the processes exit code doesn't match these values. The process will not be
re-started. It is directly related to the ExitCode parameter.

=item priority

The priority that the process will be ran under. It defaults to "0". It is
directly related to the Priotity parameter.

=item auto-start

Indicates wither the process should be started when the supervisor starts up. 
Defaults to "1" for true, and where "0" is false. It is directly related to the 
AutoStart parameter.

=item auto-restart

Indicates wither to automatically restart the process when it exits. Defaults
to "1" for true and where "0" is false. It is directly related to the AutoRestart 
parameter.

=item stop-signal

Indicates which signal to use to stop the process. Defaults to "TERM". It
is directly related to the StopSignal parameter.

=item stop-retries

Indicates how many times the supervisor should try to stop the process before
sending it a KILL signal. Defaults to "5". I tis directly related to the 
StopRetries parameter.

=item stop-wait-secs

Indicates how many seconds to wait between attempts to stop the process. 
Defaults to "10". It is directly related to the StopWaitSecs parameter.

=item start-retries

Indicates how many start attempts should be done on process. Defaults to "5".
It is directly realted to the StartRetries parameter.

=item start-wait-secs

Indicates how many seconds to wait between attempts to start the process.
Defaults to "10". If is directly related to the StartWaitSecs parameter.

=item reload-signal

Indicates the signal to use to send a "reload" signal to the process. Defaults
to "HUP". It is directly related to the ReloadSignal parameter.

=item logfile

Indicates the logfile name to use for captured stderr and stdout text that the
process may generate. Defaults to "/dev/stdout". It is directly related to the
Logfile parameter.

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
