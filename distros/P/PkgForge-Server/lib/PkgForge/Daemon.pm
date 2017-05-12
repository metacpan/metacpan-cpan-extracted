package PkgForge::Daemon; # -*- perl -*-
use strict;
use warnings;

# $Id: Daemon.pm.in 16191 2011-02-28 19:51:24Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16191 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Daemon.pm.in $
# $Date: 2011-02-28 19:51:24 +0000 (Mon, 28 Feb 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Spec ();
use IO::File ();
use POSIX qw(SIGINT SIGTERM SIGKILL);

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);

use PkgForge::PidFile;
use PkgForge::Types qw(UID Octal);

with 'MooseX::Getopt';

has 'pidfile' => (
    is      => 'ro',
    isa     => 'PkgForge::PidFile',
    coerce  => 1,
    builder => 'init_pidfile',
    documentation => 'The PID file',
);

sub init_pidfile {
    my ($self) = @_;
    return PkgForge::PidFile->new( basedir  => $self->pidfile_dir,
                                   progname => $self->progname );
}

has 'pidfile_dir' => (
    is      => 'ro',
    isa     => Str,
    default => '/var/run/pkgforge',
    documentation => 'The directory in which PID files should be stored',
);

has 'workdir' => (
    is       => 'ro',
    isa      => Str,
    default  => q{/},
    documentation => 'The directory within which to run',
);

has 'umask' => (
    is       => 'ro',
    isa      => Octal,
    default  => 0,
    documentation => 'The umask to set before starting',
);

has 'chroot' => (
    is       => 'ro',
    isa      => Str,
    documentation => 'chroot during startup',
);

has 'progname' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub { return (File::Spec->splitpath( $PROGRAM_NAME ) )[-1] },
    documentation => 'The name of the daemon',
);

has 'stop_timeout' => (
    is        => 'rw',
    isa       => Int,
    default   =>  120,
    documentation => 'The time to wait (in secs) for stop to finish',
);

has 'background' => (
    is        => 'ro',
    isa       => Bool,
    default   => 1,
    documentation => 'Background the process',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub run {
    my ($self) = @_;

    my ($command) = @{$self->extra_argv};
    defined $command or die "No command specified\n";

    if ( $command =~ m{^
                       (start
                       |stop
                       |restart
                       |status)
                       $}x ) {
        $self->$command();
    } else {
        die "Unsupported command: $command\n";
    }

    return;
}

sub shutdown {
    my ($self) = @_;

    exit 0;
}

sub setup_signals {
    my ($self) = @_;

    $SIG{INT} = $SIG{TERM} = sub { $self->shutdown };

    return;
}

sub start {
    my ($self) = @_;

    if ( $self->pidfile->does_file_exist ) {
        if ( $self->pidfile->is_running ) {
            my $pid = $self->pidfile->pid;
            die "daemon process ($pid) already running\n";
        } else {
            $self->pidfile->remove;
        }
    }

    $self->setup_signals;

    my $workdir = $self->workdir;
    chdir $workdir or die "Could not chdir to '$workdir': [$OS_ERROR]\n";

    my $umask = $self->umask;
    umask $umask or die "Could not set umask to '$umask: [$OS_ERROR]\n";

    if ( $self->background ) {
        my $process = eval { $self->daemonize() };
        if ( !$process || $EVAL_ERROR ) {
            # errors...
            $self->pidfile->remove;
            die "Failed to daemonize: $@\n";
        }
        elsif ( $process eq 'parent' ) {
            exit 0;
        }
    }

    $self->pidfile->pid($PROCESS_ID);
    $self->pidfile->store();

    return $self->pidfile->pid;
}

sub stop {
    my ($self) = @_;

    if ( $self->pidfile->does_file_exist && $self->pidfile->is_running ) {
        my $pid = $self->pidfile->pid;

        if ( $pid eq $PROCESS_ID ) {
            die "$pid is us! Cannot commit suicide.\n";
        }

        my $killed;
        for my $signal ( SIGINT, SIGTERM, SIGKILL ) {
            my $timeout = $self->stop_timeout;
            kill $signal, $pid;

            while ( $timeout > 0 ) {
                if ( ! kill 0, $pid ) {
                    $killed = $signal;
                    last;
                }
                $timeout--;
                sleep 1;
            }

            last if $killed;
        }

        # Ensure we are tidy

        if ( $killed && $self->pidfile->does_file_exist ) {
            $self->pidfile->clear_pid; # force retrieval from file
            my $pid2 = $self->pidfile->pid;
            if ( $pid == $pid2 ) { # check it is not a new process
                $self->pidfile->remove;
            }
        }

        if ( !$killed ) {
            my $progname = $self->progname;
            die "Failed to kill $progname PID $pid\n";
        }
    }
    else {
        print "Nothing to kill\n";
    }

    return;
}

sub restart {
    my ($self) = @_;

    $self->stop();

    $self->start();

    return;
}

sub status_message {
    my ( $self, $pid ) = @_;

    my $progname = $self->progname;
    if ($pid) {
      print "$progname is running with PID $pid\n";
    } else {
      print "$progname is not running\n";
    }

    return;
}

sub status {
    my ($self) = @_;

    my $pid;
    if ( $self->pidfile->does_file_exist && $self->pidfile->is_running ) {
      $pid = $self->pidfile->pid;
    }

    return $self->status_message($pid);
}

sub daemonize {
    my ($self) = @_;

    my $pid_c = fork();     # Parent spawns Child
    die "Cannot fork: $!\n" if !defined $pid_c;
    if ($pid_c)
    {
        # ==== Parent ====
        waitpid($pid_c, 0); # Zombies not allowed
        return 'parent';    # No attachment to grand-child
    }

    # ==== Child ====
    my $pid_gc = fork();     # Child spawns Grand-Child
    die "Cannot fork: $!\n" if !defined $pid_gc;
    exit (0) if $pid_gc;     # Child exits immediately

    # ==== Grand-Child ====
    # Grand-Child continues, now parented by init.

    # setpgrp MUST be BEFORE setsid

    setpgrp(0,0) or die "Cannot set process group: $!\n";

    POSIX::setsid() or die "Cannot start a new session: $!\n";

    my $chroot = $self->chroot;
    if ( $EUID == 0 && $chroot ) {
        chroot $chroot or die "Could not chroot to '$chroot': [$OS_ERROR]\n";
    }

    open( STDIN, '+>', '/dev/null' )
        or die "Could not redirect STDIN to /dev/null: [$OS_ERROR]\n";

    open( STDOUT, '+>', '/dev/null' )
        or die "Could not redirect STDOUT to /dev/null: [$OS_ERROR]\n";

    open( STDERR, '+>', '/dev/null' )
        or die "Could not redirect STDERR to /dev/null: [$OS_ERROR]\n";

    return 'child';
}

1;
__END__

