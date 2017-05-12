package System::Daemon;

use strict;
use warnings;

use POSIX;
use Carp;
use Fcntl ':flock';
use System::Daemon::Utils;

use constant NEW_SUFFIX => ".new";

our $VERSION = 0.15;
our $AUTHOR = 'justnoxx';
our $ABSTRACT = "Swiss-knife for daemonization";

our $DEBUG = 0;

sub new {
    my ($class, %params) = @_;
    my $self = {};
    $self->{daemon_data}->{daemonize} = 1;

    if ($params{user}) {
        $self->{daemon_data}->{user} = $params{user};
    }

    if ($params{group}) {
        $self->{daemon_data}->{group} = $params{group};
    }
    
    if ($params{pidfile}) {
        $self->{pidfile} = $params{pidfile};
    }

    if ($params{new}) {
        $self->{new} = 1;
    }

    if ($params{mkdir}) {
        $self->{daemon_data}->{mkdir} = 1;
    }

    if ($params{procname}) {
        $self->{daemon_data}->{procname} = $params{procname};
    }
    
    if (exists $params{daemonize}) {
        $self->{daemon_data}->{daemonize} = $params{daemonize};
    }
    
    if ($params{cleanup_on_destroy}) {
        $self->{daemon_data}->{cleanup_on_destroy} = 1;
    }

    bless $self, $class;
    return $self;
}

sub pidfile {
    my $self = shift;

    return unless $self->{pidfile};

    $self->{new} ? $self->{pidfile}.NEW_SUFFIX : $self->{pidfile};
}

sub daemonize {
    my $self = shift;

    unless ($self->{daemon_data}->{daemonize}) {
        carp "Daemonization disabled";
        return 1;
    }

    my $dd = $self->{daemon_data};

    my $process_object = System::Daemon::Utils::process_object();

    # wrapper context
    System::Daemon::Utils::daemon();
    
    # let's validate user and group
    if ($dd->{user} || $dd->{group}) {
        System::Daemon::Utils::validate_user_and_group(
            user    =>  $dd->{user},
            group   =>  $dd->{group},
        ) or do {
            croak "Bad user or group";
        };
    }

    if ($self->pidfile) {
        System::Daemon::Utils::validate_pid_path($self->pidfile, $dd->{mkdir});
    }
    System::Daemon::Utils::make_sandbox($self->pidfile, $dd) if $dd->{mkdir};
    # daemon context
    if ($self->pidfile) {
        croak "Can't overwrite pid file of my alive instance" unless $self->ok_pid();
        if ($self->pidfile) {
            open my $LOCK, $self->pidfile;
            my $got_lock = flock($LOCK, LOCK_EX | LOCK_NB);
            $self->{_lock} = $LOCK;
            unless ($got_lock) {
                warn "Can't get lock ".$self->pidfile."\n";
                exit 1;
            }
        }
        $self->{original_pid} = $$;
        System::Daemon::Utils::write_pid($self->pidfile, undef,
            user    =>  $dd->{user},
            group   =>  $dd->{group}
        );
    }
    
    if ($dd->{user} || $dd->{group}) {
        System::Daemon::Utils::apply_rights(
            user    =>  $dd->{user},
            group   =>  $dd->{group}
        );
    }

    if ($dd->{procname}) {
        $0 = $dd->{procname};
    }

    if ($dd->{cleanup_on_destroy}) {
        *{System::Daemon::DESTROY} = sub {
            my $obj = shift;
            $obj->cleanup();
        };
    }

    System::Daemon::Utils::suppress();
    return 1;
}


sub exit {
    my ($self, $code) = @_;

    $self->finish();

    $code ||= 0;
    exit $code;
}


sub ok_pid {
    my ($self, $pidfile) = @_;

    $pidfile ||= $self->pidfile;

    return 1 unless $pidfile;

    unless (System::Daemon::Utils::pid_init($self->pidfile)) {
        croak "Can't init pidfile";
    }

    my $pid;
    unless ($pid = System::Daemon::Utils::read_pid($pidfile)) {
        return 1;
    }

    return 1;
}


sub cleanup {
    my ($self) = @_;

    return $self->finish();
}


sub finish {
    my ($self) = @_;

    if ($self->pidfile) {
        my $pid = System::Daemon::Utils::read_pid($self->pidfile); # pid missing OR changed
        if ($pid ne $self->{original_pid}) {
            undef $self->{new};
        }

        if (-e $self->pidfile.NEW_SUFFIX) {
            rename $self->pidfile.NEW_SUFFIX, $self->pidfile or confess "rename ".$self->pidfile.NEW_SUFFIX.", ".$self->pidfile;
        }
        else {
            System::Daemon::Utils::delete_pidfile($self->pidfile);
        }
    }
}


sub process_object {
    my ($self) = @_;

    return System::Daemon::Utils::process_object();
}

1;

__END__

=head1 NAME

System::Daemon

=head1 DESCRIPTION

Swiss-knife for daemonization

=head1 SYNOPSIS

See little example:

    use System::Daemon;
    
    $0 = 'my_daemon_process_name';

    my $daemon = System::Daemon->new(
        user            =>  'username',
        group           =>  'groupname',
        pidfile         =>  'path/to/pidfile',
        daemonize       =>  0,
    );
    $daemon->daemonize();

    your_cool_code();

    $daemon->exit(0);

=head1 METHODS

=over

=item new(%params)

Constructor, returns System::Daemon object. Available parameters:

    user            =>  desired_username,
    group           =>  desired_groupname,
    pidfile         =>  '/path/to/pidfile',
    procname        =>  process name for ps output,
    mkdir           =>  tries to create directory for pid files,
    daemonize       =>  if not true, will not daemonize, for debug reasons,
    procname        =>  after daemonize $0 will be updated to desired name,
    new             =>  Write pid to newpidfile=pidfile.".new", if newpidfile
                        dissapears or changed during daemon life, switch back to pidfile
                        Note that even without this option, if pidfile.".new" found during destruction
                        pidfile.".new" moved to pidfile location. These tools are for grace restart.

=item daemonize

Call it to become a daemon.

=item exit($exit_code)

An exit wrapper, also, it performing cleanup before exit.

=item finish

Performing cleanup. At now cleanup is just pid file removing.

=item cleanup

Same as finish.


=item process_object

Returns System::Process object of daemon instance.

=back

=cut

