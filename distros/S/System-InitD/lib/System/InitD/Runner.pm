package System::InitD::Runner;

=head NAME

System::InitD::Runner

=head1 DESCRIPTION

Simple module to process common init.d tasks.
init.d bash scripts replacement

=head1 AUTHOR

Dmitriy @justnoxx Shamatrin

=head1 USAGE

=cut

use strict;
use warnings;
no warnings qw/once/;

use Carp;
use System::Process;
use POSIX;
use Time::HiRes;
use Data::Dumper;
use System::InitD::Const;
use System::InitD::Base;
use System::InitD::Const;

=over

=item B<new>

new(%)

Constructor, params:

B<start>

A start command

B<usage>

Usage line, called by script usage

B<daemon_name>

Now unused, reserved for output format

B<restart_timeout>

Timeout between stop and start in restart

B<pid_file>

Path to pid file, which used for monitoring

B<process_name>

B<EXACT> daemon process name. Need for preventing wrong kill.

B<kill_signal>

Signal, which used for daemon killing.

=back

=cut


sub new {
    my ($class, %params) = @_;
    my $self = {};

    if (!$params{start}) {
        croak "Start param is required";
    }

    if (!$params{usage}) {
        croak 'Usage must be specified';
    }

    if ($params{daemon_name}) {
        $self->{daemon_name} = $params{daemon_name};
    }

    else {
        $self->{_text}->{usage} = $params{usage};
    }

    # Command is array from now, for system
    @{$self->{_commands}->{start}} = split /\s+/, $params{start};

    if ($params{restart_timeout}) {
        $self->{_args}->{restart_timeout} = $params{restart_timeout};
    }

    if ($params{pid_file}) {
        $self->{pid_file} = $params{pid_file};
        $self->{pid} = System::Process::pidinfo(
            file    =>  $params{pid_file}
        );
    }

    if ($params{kill_signal}) {
        $self->{_args}->{kill_signal} = $params{kill_signal};
    }

    if ($params{process_name}) {
        $self->{_args}->{process_name} = $params{process_name};
    }

    # user and group params, added for right validation
    if ($params{user}) {
        $self->{_args}->{user} = $params{user};
    }
    if ($params{group}) {
        $self->{_args}->{group} = $params{group};
    }
    if ($params{progress_log}) {
        $self->{_args}->{progress_log} = $params{progress_log};
    }
    if ($params{grace_restart_file}) {
        $self->{_args}->{grace_restart_file} = $params{grace_restart_file};
    }

    bless $self, $class;
    return $self;
}


=over

=item B<run>

Runner itself, service sub
Never returns. Insted exit()s with error or success, or throws exception in some cases.

=back

=cut

sub run {
    my $self = shift;
    unless ($ARGV[0]) {
        $self->usage();
        exit(0);
    }

    my $sub = $ARGV[0];
    $sub =~ s/-/_/g;
    if ($self->can($sub)) {
        $self->$sub() ? exit(0) : exit(1);
    }
    else {
        $self->usage();
        exit(1);
    }
}

sub start {
    my $self = shift;
    print STARTING;
    $self->before_start();
    # TODO: Add command check
    my @command = @{$self->{_commands}->{start}};
    if ($self->is_alive()) {
        print DAEMON_ALREADY_RUNNING;
        return;
    }

    unlink $self->{_args}->{grace_restart_file} if $self->{_args}->{grace_restart_file};

    system(@command);

    my $code = $?;
    $code = $code >> 8;
    $self->after_start();

    if ($code) {
        printf NOT_STARTED, $code;
        return;
    }

    print STARTED;

    return 1;
}


sub _stop {
    my ($self, $mode) = @_;

    if (!$self->{pid}) {
        print DAEMON_IS_NOT_RUNNING;
        return;
    }
    print STOPPING;
    $self->confirm_permissions() or do {
        print NOT_STOPPED;
        croak "Incorrect permissions. Can't kill";
    };

    $self->before_stop();
    if ($self->{pid}) {
        my $signal = $self->{kill_signal} // POSIX::SIGTERM;

        if ($mode eq 'both') {
            my $new_pid = $self->new_pid;
            $new_pid->kill($signal) if ($new_pid && $new_pid->is_alive()); # don't use new_pid_is_alive to avoid race cond
            $self->{pid}->kill($signal);
        }
        else { # kill OLD or NEW only when there are NEW and OLD daemons at same time
            my $new_pid = $self->new_pid;
            if ($new_pid && $new_pid->is_alive()) { # don't use new_pid_is_alive to avoid race cond
                if ($mode eq 'new') {
                    $new_pid->kill($signal)
                }
                elsif ($mode eq 'old') {
                    # we've got OLD daemon pid
                    # next we've got NEW daemon pid
                    # it's fixed pid values not
                    # now if NEW pid is alive, we kill OLD daemon.
                    # if NEW become OLD in-between, there won't be a race condition
                    # because we'll just kill non-existing process
                    $self->{pid}->kill($signal);
                }
            }
        }
    }

    $self->after_stop();

    print STOPPED;
    return 1;
}

sub stop {
    shift->_stop('both')
}

sub stop_new {
    shift->_stop('new')
}

sub stop_old {
    shift->_stop('old')
}

=item restart

stops and start daemon, stop errors (except fatals) are ignored. start return code
returned as restart return code

=cut

sub restart {
    my $self = shift;

    $self->stop();

    while ($self->is_alive()) {
        Time::HiRes::usleep(1000);
    }

    return $self->start();
}

# same as start, but
# starts with --new option
# expects daemon to be running, sends SIGHUP to it
# expects new daemon to use pid with ".new" suffix (fails if already running)
sub _reload {
    my ($self, $verbose) = @_;

    if (!$self->{_args}{grace_restart_file}) {
        print GRACE_RESTART_NOT_ALLOWED;
        return;
    }

    if (!$self->{pid}) {
        print DAEMON_IS_NOT_RUNNING;
        return;
    } elsif ($self->new_pid_is_alive()) {
        print GRACE_RESTART_ALREADY_INPROGRESS;
        return;
    }

    print RELOADING;

    $self->before_start();
    # TODO: Add command check
    my @command = @{$self->{_commands}->{start}};

    if ($self->{_args}->{progress_log}) {
        # truncate progress_log (better than unlink, because unlink will break 'tail -f')
        # don't try create-and truncate file here. it will break permissions
        truncate($self->{_args}->{progress_log}, 0);
    }
    unlink $self->{_args}->{grace_restart_file};

    system(
        @command,
        '--new',
        $self->{_args}->{progress_log} ? ('--progress-log' => $self->{_args}->{progress_log}) : ()
    );

    my $code = $?;
    $code = $code >> 8;
    $self->after_start();

    if ($code) {
        printf NOT_STARTED, $code;
        return;
    }

    # what when new daemon will start for sure
    Time::HiRes::usleep(10_000) while (! $self->new_pid_is_alive());

    # then kill old
    $self->{pid}->kill(POSIX::SIGHUP);

    print RELOADED;

    if ($verbose && $self->{_args}->{progress_log}) {
        print "Printing progress log, Ctrl-C to quit tail\n";
        print "Waiting for log..\n";
        Time::HiRes::usleep(10_000) while (! -f $self->{_args}->{progress_log});
        print "Log below:\n";
        system('tail', '-f', $self->{_args}->{progress_log});
        return; # should unreachable
    }

    return 1;
}

sub reload {
    shift->_reload(0)
}

sub reload_verbose {
    shift->_reload(1)
}

sub status {
    my $self = shift;

    if (!$self->{pid}) {
        print DAEMON_IS_NOT_RUNNING;
        return;
    }
    elsif ($self->is_alive()) {
        if ($self->new_pid_is_alive()) {
            print GRACE_RESTART_ALREADY_INPROGRESS;
        }
        else {
            print DAEMON_ALREADY_RUNNING;
        }
        return 1;
    }
}


sub info {
    my $self = shift;

    $self->status;

    if ($self->is_alive()) {
        my $p = $self->{pid};
        printf "\tPID: %s\n\tCommand: %s\n\tUser: %s\n\tProgress-log: %s\n",
            $p->pid(), $p->command(), $p->user(), $self->{_args}->{progress_log} // 'NONE';
    }

    return 1;

}


sub usage {
    my $self = shift;

    print $self->{_text}->{usage}, "\n";
    return 1;
}


sub is_alive {
    my $self = shift;

    my $pid = $self->{pid};
    return 0 unless $pid;

    return $pid->is_alive();
}

sub new_pid {
    my $self = shift;

    System::Process::pidinfo(file => $self->{pid_file}.NEW_SUFFIX);
}

sub new_pid_is_alive {
    my $self = shift;

    my $new_pid = $self->new_pid;
    $new_pid && $new_pid->is_alive;
}

=over

=item B<load>

load($,\&)

Loads additional actions to init script, for example, add `script hello` possible via:

$runner->load('hello', sub {print 'Hello world'})

=back

=cut

sub load {
    my ($self, $subname, $subref) = @_;

    if (!$subname || !$subref) {
        croak 'Missing params';
    }

    croak 'Subref must be a CODE ref' if (ref $subref ne 'CODE');

    no strict 'refs';
    *{__PACKAGE__ . "\::$subname"} = $subref;
    use strict 'refs';

    return 1;
}


sub confirm_permissions {
    my ($self) = @_;

    if (!exists $self->{pid}) {
        carp 'Usage of System::InitD without pidfile is deprecated ' .
            'and will be forbidden in the future releases';
        return 1;
    }

    unless ($self->{_args}->{user}) {
        carp 'Usage of System::InitD without specified user is extremely insecure ' .
            'and will be forbidden in the future releases';
        return 1;
    }

    # if no System::Process object, next check useless
    unless ($self->{pid}) {
        return 1;
    }

    if ($self->{_args}->{user} ne $self->{pid}->user()) {
        carp "Expected: $self->{_args}->{user}, but got: " . $self->{pid}->user()
            . " looks like very strange. Execution was aborted.";
        return 0;
    }

    return 1;
}

sub before_start {1;}
sub after_start {1;}

sub before_stop {1;}
sub after_stop {1;}


1;

__END__
