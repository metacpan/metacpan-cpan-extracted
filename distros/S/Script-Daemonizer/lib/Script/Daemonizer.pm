package Script::Daemonizer;

use 5.006;
use strict;
use warnings;
use Carp qw/carp croak/;
use POSIX qw(:signal_h);
use Fcntl qw/:DEFAULT :flock/;
use FindBin ();
use File::Spec;
use File::Basename ();

$Script::Daemonizer::VERSION = '1.01.01';

# ------------------------------------------------------------------------------
# 'Private' vars
# ------------------------------------------------------------------------------
my @argv_copy;
my $devnull = File::Spec->devnull;
my @daemon_options = ( qw{
    chdir
    do_not_tie_stdhandles
    drop_privileges
    output_file
    pidfile
    restart_on
    setsid
    sigunmask
    stdout_file
    stderr_file

    _DEBUG
} );
my %id_map = (
    user   => 'uid',
    group  => 'gid',
    euser  => 'euid',
    egroup => 'egid',
);
my $global_pidfh;
my %defaults = (
    working_dir => File::Spec->rootdir(),
    umask       => 0,
);



################################################################################
# SAVING @ARGV for restart()
################################################################################
#
# restart() needs the exact list of arguments in order to relaunch the script,
# if requested.
# User is free to shift(@ARGV) and/or modify it in any way, we ensure we always
# get the "real" args (unless someone takes some extra effort to modify them
# before we get here).
# restart() gets an array of args, thoug, so there is no need to tamper with
# this:

BEGIN {
    @argv_copy = @ARGV;
}

################################################################################
# HANDLING SIGHUP
################################################################################
#
# When the script restarts itself upon receiving SIGHUP, that signal is masked.
# When starting, we unmask the signals so that they do not stop working for us.
# We do this regardless of how we were launched.
#
{
    my $sigset = POSIX::SigSet->new( SIGHUP );  # Just handle HUP
    sigprocmask(SIG_UNBLOCK, $sigset);
}



################################################################################
# HANDLING IMPORT TAGS
################################################################################

sub import {
    my $class = shift;
    for my $opt (@_) {
        if ($opt eq ':NOCHDIR') {
            delete $defaults{working_dir};
        } elsif ($opt eq ':NOUMASK') {
            delete $defaults{umask};
        } else {
            croak "Unknown tag: $opt";
        }
    }
}



# ------------------------------------------------------------------------------
# 'Private' functions
# ------------------------------------------------------------------------------

################
# sub _debug() #
################

sub _debug {
    my $self = shift;
    print @_, "\n"
        if $self->{_DEBUG};
}


##################
# sub _set_umask #
##################

sub _set_umask {
    my $self = shift;
    defined(umask($self->{umask})) or
        croak qq(Cannot set umask to "), $self->{umask}, qq(": $!);
}

###############
# sub _fork   #
###############
# fork() a child
sub _fork {
    my $self = shift;

    return unless $self->{fork};    # Just in case, but already checked when
                                    # _fork() is called

    # See http://code.activestate.com/recipes/278731/ or the source of
    # Proc::Daemon for a discussion on ignoring SIGHUP.
    # Since ignoring it across the fork() should not be harmful, I prefer to set
    # this to IGNORE anyway.
    local $SIG{'HUP'} = 'IGNORE';

    defined(my $pid = fork())
        or croak "Cannot fork: $!";

    exit 0 if $pid;     # parent exits here

    $self->{fork}--;

    $self->_debug("Forked, remaining forks: ", $self->{fork});

}

###############
# sub _setsid #
###############

sub _setsid {
    my $self = shift;
    return if
        ( exists $self->{ setsid } && $self->{ setsid } eq 'SKIP' );
    POSIX::setsid() or
        croak "Unable to set session id: $!";
}

#########################
# sub _write_pidfile    #
#########################
# Open the pidfile (creating it if necessary), then lock it, then truncate it,
# then write pid into it. Then retun filehandle.
# If environment variable $_pidfile_fileno is set, then we assume we're product
# of an exec() and take that file descriptor as the (already opened) pidfile.
sub _write_pidfile {
    my $self = shift;
    my $pidfile = $self->{pidfile};
    my $fh;

    # First we must see if there is a _pidfile_fileno variable in environment;
    # that means that we were started by an exec() and we must keep the same
    # pidfile as before
    my $pidfd = delete $ENV{_pidfile_fileno};
    if (defined $pidfd && $pidfd =~ /^\d+$/) {
        $self->_debug("Reopening pidfile from file descriptor");
        open($fh, ">&=$pidfd")
            or croak "can't open fd $pidfd: $!";
        # Re-set close-on-exec bit for pidfile filehandle
        fcntl($fh, F_SETFD, 1)
            or die "Can't set close-on-exec flag on pidfile filehandle: $!\n";
    } else {
        $self->_debug("Opening a new pid file");
        # Open configured pidfile
        sysopen($fh, $pidfile, O_RDWR | O_CREAT)
            or croak "can't open $pidfile: $!";
    }
    flock($fh, LOCK_EX|LOCK_NB)
        or croak "can't lock $pidfile: $! - is another instance running?";
    truncate($fh, 0)
        or croak "can't truncate $pidfile: $!";

    select((select( $fh ), ++$|)[0]);

    print $fh $$;

    # Save it as a global so that in short init syntax
    #   Script::Daemonizer->new( pidfile => $pfile )->daemonize;
    # it stays in scope
    return $global_pidfh = $self->{pidfh} = $fh;
}


##############
# sub _chdir #
##############

sub _chdir {
    my $self = shift;
    chdir($self->{'working_dir'}) or
        croak "Cannot change directory to ", $self->{'working_dir'}, ": $!";
}


#################
# sub _close    #
#################
# Handle closing of STDOUT/STDERR
sub _close {
    my $self = shift;
    my $fh = shift;
    # Have to lookup handles by name
    $self->_debug("Closing $fh");
    no strict "refs";
    open *$fh, '>', $devnull
        or croak "Unable to open $fh on $devnull: $!";

}

#################
# sub _redirect #
#################

sub _redirect {
    my ( $self, $fh, $destination ) = @_;

    $destination = $devnull
        if $destination eq '/dev/null';

    $self->_debug("Redirecting $fh on: $destination ", $destination);
    no strict "refs";
    open *$fh, '>>', $destination
        or croak "Unable to open $fh on $destination: $!";

}

##########################
# sub _manage_stdhandles #
##########################
sub _manage_stdhandles {
    my $self = shift;

    open STDIN, '<', $devnull
        or croak "Cannot reopen STDIN on $devnull: $!";

    # If we were requested to redirect output on a file, do it now and return
    if ($self->{output_file}) {
        $self->_debug("Using output file");
        $self->_redirect( $_, $self->{output_file}) for (qw{STDOUT STDERR});
        return 1;
    }

    # Use Tie::Syslog unless both stdout/stderr redirected to file
    unless ($self->{stdout_file} && $self->{stderr_file}) {
        $self->_debug("Using Tie::Syslog");
        eval {
            require Tie::Syslog;
        };

        if ($@) {
            carp "Unable to load Tie::Syslog module. Error is:\n----\n$@----\nI will continue without output"
                if $self->{_DEBUG};
            $self->_close( $_ ) for (qw{STDOUT STDERR});
            return 0;
        }

        $Tie::Syslog::ident  = $self->{name};
        $Tie::Syslog::logopt = 'ndelay,pid';
    }

    # STDOUT
    if ($self->{stdout_file}) {
        $self->_redirect( 'STDOUT', $self->{stdout_file} );
    } else {
        $self->_close( 'STDOUT' );
        $self->_debug("Tying STDOUT to Tie::Syslog");
        tie *STDOUT, 'Tie::Syslog', {
            facility => 'LOG_DAEMON',
            priority => 'LOG_INFO',
        };
    }

    # STDERR
    if ($self->{stderr_file}) {
        $self->_redirect( 'STDERR', $self->{stderr_file} );
    } else {
        $self->_close( 'STDERR' );
        $self->_debug("Tying STDERR to Tie::Syslog");
        tie *STDERR, 'Tie::Syslog', {
            facility => 'LOG_DAEMON',
            priority => 'LOG_ERR',
        };
    }

}

########################
# sub _get_signal_list #
########################
sub _get_signal_list {
    my $self = shift;

}

# ------------------------------------------------------------------------------
# 'Public' functions
# ------------------------------------------------------------------------------

sub drop_privileges {

    my $self = shift;

    # Check parameters:
    croak "Odd number of arguments in drop_privileges() call!"
        if @_ % 2;

    # Get parameters
    my %ids = @_ ? @_ : %{ $self->{drop_privileges} };

    # Resolve user name to user id if given
    for (qw{ user euser }) {
        defined( my $us = delete $ids{ $_ } )
            or next;
        defined ( $ids{ $id_map{ $_ } } = getpwnam( $us ) )
            or croak "No such user: $us";
    }

    # Resolve group name to group id if given
    for (qw{ group egroup }) {
        defined( my $gr = delete $ids{ $_ } )
            or next;
        defined ( $ids{ $id_map{ $_ } } = getgrnam( $gr ) )
            or croak "No such group: $gr";
    }

    # Get ids
    my ($euid, $egid, $uid, $gid) = @ids{qw(euid egid uid gid)};

    # Drop GROUP ID
    if (defined $gid) {
        POSIX::setgid((split " ", $gid)[0])
            or croak "POSIX::setgid() failed: $!";
    } elsif (defined $egid) {
        # $egid might be a list
        $) = $egid;
        croak "Cannot drop effective group id to $egid: $!"
            if $!;
    }

    # Drop USER ID
    if (defined $uid) {
        POSIX::setuid($uid)
            or croak "POSIX::setuid() failed: $!";
    } elsif (defined $euid) {
        # Drop EUID too, unless explicitly forced to something else
        $> = $euid;
        croak "Cannot drop effective user id to $uid: $!"
            if $!;
    }

    return 1;

}

sub new {

    my $pkg = shift;

    croak ("This is a class method!")
        if ref($pkg);

    croak "Odd number of arguments in configuration!"
        if @_ %2;

    my $self = {
        %defaults,
    };

    # Get the configuration
    my %params = @_;

    # Set useful defaults
    $self->{name}        = delete $params{name}        || (File::Spec->splitpath($0))[-1];
    $self->{fork}        = (exists $params{fork} && $params{fork} =~ /^[012]$/)
                            ? delete $params{fork}
                            : 2;

    $self->{working_dir} = delete $params{working_dir} if $params{working_dir};

    if (exists $params{umask}) {
        croak "Invalid umask specified: ", $params{umask}
            unless $params{umask} =~ /^[0-7]{1,3}$/;
        $self->{umask} = delete $params{umask};
    }

    # Get other options as they are:
    for (@daemon_options) {
        $self->{ $_ } = delete $params{ $_ }
            if exists $params{ $_ };
    }

    my @extra_args = keys %params;
    {
        local $" = ", ";
        croak sprintf "Invalid argument(s) passed: @extra_args"
            if @extra_args;
    }

    bless $self, $pkg;

    # Set up signal handlers
    if ($self->{restart_on} && ref $self->{restart_on} eq 'ARRAY') {
        my @sigs = @{ $self->{restart_on} };
        for (@sigs) {
            $SIG{ $_ } = sub {
                $self->restart();
            };
        }
        $self->sigunmask( @sigs );
    }

    # Unmask signals if requested
    if ($self->{sigunmask} && ref $self->{sigunmask} eq 'ARRAY') {
        $self->sigunmask(@{ $self->{sigunmask} });
    }

    return $self;

}

sub daemonize {
    my $self = shift;

    # Step 0.0 - OPTIONAL: drop privileges
    $self->drop_privileges
        if $self->{drop_privileges};

    # Step 1.
    $self->_set_umask
        if exists $self->{umask};

    # Step 2.
    $self->_fork()
        if $self->{fork};

    # Step 3.
    $self->_setsid();

    # Step 4.
    $self->_fork()
        if $self->{fork};

    # Step 4.5 - OPTIONAL: take a lock on pidfile
    # (and write pid into it)
    $self->_write_pidfile()
        if $self->{pidfile};

    # Step 5.
    $self->_chdir()
        if $self->{working_dir};


    # Step 6.
    #   REMOVED!


    # Step 7.
    $self->_manage_stdhandles();

    return 1;

}

sub restart {

    my $self = shift;

    my @args = @_ ? @_ : @argv_copy;

    # See perlipc
    # make the daemon cross-platform, so exec always calls the script
    # itself with the right path, no matter how the script was invoked.
    my $script = File::Basename::basename($0);
    my $SELF = File::Spec->catfile($FindBin::Bin, $script);

    # $pidf must be kept open across exec() if we don't want race conditions:
    if (my $pidfh = $self->{pidfh}) {
        $self->_debug("Keeping current pidfile open");
        # Clear close-on-exec bit for pidfile filehandle
        fcntl($pidfh, F_SETFD, 0)
            or die "Can't clear close-on-exec flag on pidfile filehandle: $!\n";
        # Now we must notify ourseves that pidfile is already open
        $ENV{_pidfile_fileno} = fileno( $pidfh );
    }

    exec($SELF, @args)
        or croak "$0: couldn't restart: $!";

}

# Bye default, we unmask SIGHUP but, if other signals must be unmasked too,
# then use this and pass in a list of signals to be unmasked.
sub sigunmask {
    my $self = shift;
    croak "sigunmask called without arguments"
        unless @_;
    no strict "refs";
    # Have to convert manually signal names into numbers. I remove the prefix
    # POSIX::[SIG] from signal name and add it back again, this allows user to
    # refer to signals in any way, for example:
    # QUIT
    # SIGQUIT
    # POSIX::QUIT
    # POSIX::SIGQUIT
    my @sigs =  map {
        ( my $signal = $_ ) =~ s/^POSIX:://;
        $signal =~ s/^SIG//;
        $signal = "POSIX::SIG".$signal;
        &$signal
    } @_;
    my $sigset = POSIX::SigSet->new( @sigs );  # Handle all given signals
    sigprocmask(SIG_UNBLOCK, $sigset);
}


'End of Script::Daemonizer'

__END__

