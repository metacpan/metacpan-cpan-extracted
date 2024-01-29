package POE::Wheel::Run::DaemonHelper;

use 5.006;
use strict;
use warnings;
use POE qw( Wheel::Run );
use base 'Error::Helper';
use Algorithm::Backoff::Exponential;
use Sys::Syslog;
use File::Slurp qw(append_file read_file);

=head1 NAME

POE::Wheel::Run::DaemonHelper - Helper for the POE::Wheel::Run for easy controlling logging of stdout/err as well as restarting with backoff.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use strict;
    use warnings;
    use POE::Wheel::Run::DaemonHelper;
    use POE;

    my $program = 'sleep 1; echo test; derp derp derp';

    my $dh = POE::Wheel::Run::DaemonHelper->new(
	    program           => $program,
	    status_syslog     => 1,
        restart_ctl       => 1,
	    status_print      => 1,
        status_print_warn => 1,
        # this one will be ignored as it will already be warning for print
        status_syslog_warn => 1,
    );

    $dh->create_session;

    POE::Kernel->run();

=head1 METHODS

=head2 new

Required args as below.

    - program :: The program to execute. Either a string or array.
        Default :: undef

    - restart_ctl :: Control if it will be restarted if it dies.
        Default :: 1

Optional args are as below.

    - syslog_name :: The name to use when sending stuff to syslog.
        Default :: DaemonHelper

    - pid_file :: The file to check for additional PIDs. Used for for
             with the $dh->pids and $dh->pid_from_pid_file.
        Default :: undef

    - default_kill_signal :: The default signal to use for kill.
        Default :: TERM

The following optional args control the backoff. Backoff is handled by
L<Algorithm::Backoff::Exponential> with consider_actual_delay and delay_on_success
set to true. The following are passed to it.

    - max_delay :: Max backoff delay in seconds when a program exits quickly.
        Default :: 90

    - initial_delay :: Initial backoff amount.
        Default :: 2

The following optional args control the how the log_message method behaves.

    - syslog_facility :: The syslog facility to log to.
        Default :: daemon

    - stdout_prepend :: What to prepend to STDOUT lines sent for status logging.
        Default :: Out:

    - stderr_prepend :: What to prepend to STDERR lines sent to status logging.
        Default :: Err:

    - status_print :: Print statuses messages to stdout.
        Default :: 0

    - status_print_warn :: For when error is true, use warn.
        Default :: 0

    - status_syslog :: Send status messages to syslog
        Default :: 1

    - status_syslog_warn :: Warn for error messages going to syslog. Warn will only be used once.
        Default :: 0

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			flags            => {
				1 => 'invalidProgram',
				2 => 'optsBadRef',
				3 => 'optsNotInt',
				4 => 'readPidFileFailed',
				5 => 'killFailed',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		args => {
			ints => {
				'max_delay'     => 1,
				'initial_delay' => 1,
			},
			args => [
				'syslog_name',       'syslog_facility',    'stdout_prepend', 'stderr_prepend',
				'max_delay',         'initial_delay',      'status_syslog',  'status_print',
				'status_print_warn', 'status_syslog_warn', 'restart_ctl',    'pid_file',
				'default_kill_signal',
			],
		},
		program             => undef,
		syslog_name         => 'DaemonHelper',
		syslog_facility     => 'daemon',
		stdout_prepend      => 'Out: ',
		stderr_prepend      => 'Err: ',
		max_delay           => 90,
		initial_delay       => 2,
		session_created     => 0,
		started             => undef,
		started_at          => undef,
		restart_ctl         => 1,
		backoff             => undef,
		pid                 => undef,
		status_syslog       => 1,
		status_syslog_warn  => 0,
		status_print        => 0,
		status_print_warn   => 0,
		append_pid          => 0,
		pid_prepend         => 1,
		pid_file            => undef,
		default_kill_signal => 'TERM',
	};
	bless $self;

	if ( !defined( $opts{program} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = 'program is defined';
		$self->warn;
		return;
	} elsif ( ref( $opts{program} ) ne '' && ref( $opts{program} ) ne 'ARRAY' ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = 'ref for program is ' . ref( $opts{program} ) . ', but should be either "" or ARRAY';
		$self->warn;
		return;
	}
	$self->{program} = $opts{program};

	foreach my $arg ( @{ $self->{args}{args} } ) {
		if ( defined( $opts{$arg} ) ) {
			if ( ref( $opts{$arg} ) ne '' ) {
				$self->{perror}      = 1;
				$self->{error}       = 2;
				$self->{errorString} = 'ref for ' . $arg . ' is ' . ref( $opts{$arg} ) . ', but should be ""';
				$self->warn;
				return;
			}

			if ( $self->{args}{ints}{$arg} && $opts{$arg} !~ /^[0-9]+$/ ) {
				$self->{perror}      = 1;
				$self->{error}       = 3;
				$self->{errorString} = $arg . ' is "' . $opts{$arg} . '" and does not match /^[0-9]+$/';
				$self->warn;
				return;
			}

			$self->{$arg} = $opts{$arg};
		} ## end if ( defined( $opts{$arg} ) )
	} ## end foreach my $arg ( @{ $self->{args}{args} } )

	eval {
		$self->{backoff} = Algorithm::Backoff::Exponential->new(
			initial_delay         => $self->{initial_delay},
			max_delay             => $self->{max_delay},
			consider_actual_delay => 1,
			delay_on_success      => 1,
		);
	};
	if ($@) {
		die($@);
	}

	return $self;
} ## end sub new

=head2 create_session

This creates the new POE session that will handle this.

    $dh->create_session;

=cut

sub create_session {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	POE::Session->create(
		inline_states => {
			_start           => \&on_start,
			got_child_stdout => \&on_child_stdout,
			got_child_stderr => \&on_child_stderr,
			got_child_close  => \&on_child_close,
			got_child_signal => \&on_child_signal,
		},
		heap => { self => $self },
	);

	return;
} ## end sub create_session

=head2 log_message

Logs a message. Printing to stdout or sending to syslog is controlled via
the status_syslog and status_print values passed to new.



    - status :: What to log.
      Default :: undef

    - error :: If true, this will set the log level from info to err.
      Default :: 0

=cut

sub log_message {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	my $level = 'info';
	if ( $opts{error} ) {
		$level = 'err';
	}

	# used for making sure we only use warn once.
	my $warned = 0;

	if ( $self->{status_print} ) {
		if ( $self->{status_print_warn} && $opts{error} ) {
			warn( $self->{syslog_name} . '[' . $$ . '] ' . $opts{status} );
			$warned = 1;
		} else {
			print $self->{syslog_name} . '[' . $$ . '] ' . $opts{status} . "\n";
		}
	}

	if ( $self->{status_syslog} ) {
		if ( $self->{status_syslog_warn} && $opts{error} && !$warned ) {
			warn( $self->{syslog_name} . '[' . $$ . '] ' . $opts{status} );
		}
		eval {
			openlog( $self->{syslog_name}, '', $self->{syslog_facility} );
			syslog( $level, $opts{status} );
			closelog();
		};
		if ($@) {
			warn( 'Errored logging message... ' . $@ );
		}
	} ## end if ( $self->{status_syslog} )
} ## end sub log_message

=head2 kill

Sends the specified signal to the PIDs.

Returns undef if there are no PIDs, meaning it is not running.

If the signal is not supported, the error 5, killFailed, is set.

For understanding the return value, see the docs for the Perl
function kill.

If you want to see the available signals,
check L<Config> and $Config{sig_name}.

    - signal :: The signal to send. The default is conntrolled
        by the setting of the default_kill_signal setting.

    # send the default signal
    my $count=$dh->kill;

    # send the KILL signal
    my $count;
    eval{ $count=$dh->kill(signal=>'KILL'); };
    if ($@ && $Error::Helper::errorFlag eq 'killFailed') {
        die('Unkown kill signal used');
    } elsif ($@) {
        die($@);
    } elsif ( $count < 1 ) {
        die('Failed to kill any of the procs');
    }
    print $count . " procs signaled\n";

=cut

sub kill {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !defined( $opts{signal} ) ) {
		$opts{signal} = $self->{default_kill_signal};
	}

	my @pids = $self->pids;

	if ( !defined( $pids[0] ) ) {
		return undef;
	}

	my $count;
	eval { $count = kill $opts{signal}, @pids; };
	if ($@) {
		$self->{error} = 5;
		$self->{errorString}
			= 'Died trying to send kill signal "' . $opts{signal} . '" to pids ' . join( ',', @pids ) . ' ... ' . $@;
		$self->warn;
		return undef;
	}

	return $count;
} ## end sub kill

=head2 pid

Returns the PID of the process or undef if it
has not been started.

This just return the child PID. Will not return
the PID from the PID file if one is set.

    my $pid = $dh->pid;
    if ($pid){
        print 'PID is '.$started_at."\n";
    }

=cut

sub pid {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return $self->{pid};
}

=head2 pids

Returns the child PID and PID from the PID file if one is specified.

This calls pid_from_pid_file via eval and ignores if it fails. If you
want to check to see if that errored or not, check to see if error 4,
readPidFileFailed, was set or use both pid and pid_from_pid_file.

    my @pids = $dh->pids;
    print 'PIDs are ' . join(', ', @pids) . "\n";

=cut

sub pids {
	my ($self) = @_;

	$self->errorblank;

	my @pids;

	if ( defined( $self->{pid} ) ) {
		push( @pids, $self->{pid} );
	}

	my $pid_from_pid_file;
	eval { $pid_from_pid_file = $self->pid_from_pid_file; };
	if ( defined($pid_from_pid_file) ) {
		push( @pids, $pid_from_pid_file );
	}

	return @pids;
} ## end sub pids

=head2 pid_from_pid_file

Reads the PID from the PID file.

If one was not specified or the file does not exist, it returns undef.

Will throw error 4, readPidFileFailed, if it could not read it.

After reading it, it will return the first integer.

    my $pid;
    eval{ $pid = $dh->pid_from_pid_file; };
    if ($@) {
        print "Could not read PID file\n";
    } elsif (defined ($pid)) {
        print 'PID: ' . $pid . "\n";
    }

=cut

sub pid_from_pid_file {
	my ($self) = @_;

	$self->errorblank;

	if ( !defined( $self->{pid_file} ) ) {
		return undef;
	} elsif ( !-f $self->{pid_file} ) {
		return undef;
	}

	my $raw_pid_file;
	eval { $raw_pid_file = read_file( $self->{pid_file} ); };
	if ($@) {
		$self->{error}       = 4;
		$self->{errorString} = 'Failed to read PID file, "' . $self->{pid_file} . '" ... ' . $@;
		$self->warn;
		return;
	}

	my @raw_pid_file_split = split( /\n/, $raw_pid_file );
	foreach my $line (@raw_pid_file_split) {
		if ( $line =~ /^[0-9]+$/ ) {
			return $line;
		}
	}

	return undef;
} ## end sub pid_from_pid_file

=head2 restart_ctl

Controls if the process will be restarted when it exits or not.

    - restart_ctl :: A Perl boolean that if true the process will
            be restarted when it exits.
        Default :: undef

    # next time it exits, it won't be restarted
    $dh->restart_ctl(restart_ctl=>0);

If restart_ctl is undef, the current value is returned.

    my $restart_ctl = $dh->restart_ctl;
    if ($restart_ctl) {
        print "Will be restarted when it dies.\n";
    } else {
        print "Will NOT be restarted when it dies.\n";
    }

=cut

sub restart_ctl {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	if ( !defined( $opts{restart_ctl} ) ) {
		return $self->{restart_ctl};
	}

	$self->{restart_ctl} = $opts{restart_ctl};
} ## end sub restart_ctl

=head2 started

Returns a Perl boolean for if it has been started or not.

    my $started=$dh->started;
    if ($started){
        print 'started as '.$dh->pid."\n";
    }

=cut

sub started {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return $self->{started};
}

=head2 started_at

Returns the unix time it was (re)started at or undef if it has not
been started.

    my $started_at = $dh->started;
    if ($started_at){
        print 'started at '.$started_at."\n";
    }

=cut

sub started_at {
	my ( $self, %opts ) = @_;

	$self->errorblank;

	return $self->{started_at};
}

sub on_start {

	my $child = POE::Wheel::Run->new(
		StdioFilter  => POE::Filter::Line->new(),
		StderrFilter => POE::Filter::Line->new(),
		Program      => $_[HEAP]{self}->{program},
		StdoutEvent  => "got_child_stdout",
		StderrEvent  => "got_child_stderr",
		CloseEvent   => "got_child_close",
	);

	$_[KERNEL]->sig_child( $child->PID, "got_child_signal" );

	# Wheel events include the wheel's ID.
	$_[HEAP]{children_by_wid}{ $child->ID } = $child;

	# Signal events include the process ID.
	$_[HEAP]{children_by_pid}{ $child->PID } = $child;

	$_[HEAP]{self}->log_message( status => 'Starting... ' . $_[HEAP]{self}->{program} );

	$_[HEAP]{self}->log_message( status => 'Child pid ' . $child->PID . ' started' );

	$_[HEAP]{self}{started}    = 1;
	$_[HEAP]{self}{pid}        = $child->PID;
	$_[HEAP]{self}{started_at} = time;
} ## end sub on_start

sub on_child_stdout {
	my ( $stdout_line, $wheel_id ) = @_[ ARG0, ARG1 ];
	my $child = $_[HEAP]{children_by_wid}{$wheel_id};

	my $prepend = $_[HEAP]{self}->{stdout_prepend};
	if ( $_[HEAP]{self}->{pid_prepend} ) {
		$prepend = $_[HEAP]{self}->{pid} . ' ' . $prepend;
	}

	$_[HEAP]{self}->log_message( status => $prepend . $stdout_line );
} ## end sub on_child_stdout

sub on_child_stderr {
	my ( $stderr_line, $wheel_id ) = @_[ ARG0, ARG1 ];
	my $child = $_[HEAP]{children_by_wid}{$wheel_id};

	my $prepend = $_[HEAP]{self}->{stderr_prepend};
	if ( $_[HEAP]{self}->{pid_prepend} ) {
		$prepend = $_[HEAP]{self}->{pid} . ' ' . $prepend;
	}

	$_[HEAP]{self}->log_message( error => 1, status => $prepend . $stderr_line );
} ## end sub on_child_stderr

sub on_child_close {
	my $wheel_id = $_[ARG0];
	my $child    = delete $_[HEAP]{children_by_wid}{$wheel_id};

	# May have been reaped by on_child_signal().
	unless ( defined $child ) {
		return;
	}
	$_[HEAP]{self}->log_message( status => $child->PID . ' closed all pipes.' );
	delete $_[HEAP]{children_by_pid}{ $child->PID };
} ## end sub on_child_close

sub on_child_signal {
	my $error = 0;
	if ( $_[ARG2] ne '0' ) {
		$error = 1,;
	}

	my $child = delete $_[HEAP]{children_by_pid}{ $_[ARG1] };

	$_[HEAP]{self}->log_message( error => $error, status => $_[ARG1] . ' exited with ' . $_[ARG2] );

	if ( defined($child) ) {
		delete $_[HEAP]{children_by_wid}{ $child->ID };
	}

	my $secs;
	if ( !$error ) {
		$secs = $_[HEAP]{self}{backoff}->success;
	} else {
		$secs = $_[HEAP]{self}{backoff}->failure;
	}

	if ( $_[HEAP]{self}->{restart_ctl} ) {
		$_[HEAP]{self}->log_message( status => 'restarting in ' . $secs . ' seconds' );

		$_[KERNEL]->delay( _start => 3 );
	} else {
		$_[HEAP]{self}->log_message( status => 'restart_ctl false... not restarting' );
	}
} ## end sub on_child_signal

=head1 ERROR CODES / FLAGS

=head2 1, invalidProgram

No program is specified.

=head2 2, optsBadRef

The opts has a invlaid ref.

=head2 3, optsNotInt

The opts in question should be a int.

=head2 4, readPidFileFailed

Failed to read the PID file.

=head2 5, killFailed

Failed to run kill. This in general means a improper signal was specified.

If you want to see the available signals, check L<Config> and $Config{sig_name}.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-wheel-run-daemonhelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Wheel-Run-DaemonHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Wheel::Run::DaemonHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Wheel-Run-DaemonHelper>

=item * Search CPAN

L<https://metacpan.org/release/POE-Wheel-Run-DaemonHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of POE::Wheel::Run::DaemonHelper
