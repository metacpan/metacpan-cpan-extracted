package System::Daemon::Utils;

use strict;
use warnings;

use Carp;
use POSIX;
use Data::Dumper;
use File::Basename;

use System::Process;

our $DEBUG = 0;

sub apply_rights {
    my %params = @_;

    if ($params{group}) {
        my $gid = getgrnam($params{group});
        unless ($gid) {
            croak "Group $params{group} does not exists.";
        }
        unless (setgid($gid)) {
            croak "Can't setgid $gid: $!";
        }
    }

    if ($params{user}) {
        my $uid = getpwnam($params{user});
        unless ($uid) {
            croak "User $params{user} does not exists.";
        }
        unless (setuid($uid)) {
            croak "Can't setuid $uid: $!";
        }
    }
    return 1;
}


sub validate_user_and_group {
    my %params = @_;
    
    my $err = 0;

    if (!$params{user} && !$params{group}) {
        croak "Missing user and group param, can't validate.";
    }
    my ($user, $group) = ($params{user}, $params{group});
    if ($user) {
        my $uid = getpwnam($user);
        unless ($uid) {
            carp "Wrong username";
            $err++;
        }
    }

    if ($group) {
        my $gid = getgrnam($group);
        unless ($gid) {
            carp "Wrong groupname";
            $err++;
        }
    }

    if ($err) {
        return 0;
    }

    return 1;
}


sub daemon {
    fork and exit;
    POSIX::setsid();
    fork and exit;
    umask 0;
    chdir '/';
    return 1;
}


sub pid_init {
    my $pid = shift;

    croak "Can't init nothing" unless $pid;

    if (!-e $pid) {
        # file does not exists, let's try to create
        local *PID;
        open PID, '>', $pid or do {
            carp "Can't create pid $pid: $!";
            return 0;
        };


        return 1;
    }

    # Everything is ok, nothing to check
    return 1;
}


sub write_pid {
    my ($pidfile, $pid, %owner) = @_;

    $pid ||= $$;

    croak "No pidfile" unless $pidfile;
    local *PID;

    open PID, '>', $pidfile;
    print PID $pid;
    close PID;

    if ($owner{user} || $owner{group}) {
        my $uid = getpwnam($owner{user});
        my $gid = getgrnam($owner{group});

        chown $uid, $gid, $pidfile or 
            croak "Can't chown $owner{user}:$owner{group}";
    }

    return 1;
}


sub read_pid {
    my ($pidfile) = @_;

    croak "No pidfile param" unless $pidfile;

    return 0 unless -e $pidfile;

    open PID, $pidfile;
    my $pid = <PID>;

    return 0 unless $pid;

    close PID;

    chomp $pid;

    my $res = validate_pid($pid);
    return 0 unless $res;

    return $pid;
}


sub delete_pidfile {
    my $pidfile = shift;
    
    unlink $pidfile or do {carp "$pidfile $!"} and return 0;

    return 1;
}


sub process_object {
    my ($pid) = @_;

    $pid ||= $$;
    return System::Process::pidinfo pid => $pid;
}


sub validate_pid_path {
    my ($pidfile, $mkdir) = @_;

    croak unless $pidfile;

    my ($filename, $path) = fileparse ($pidfile);

    # path exists
    if (-e $path) {
        # path is not a directory
        if (!-d $path) {
            croak "Path '$path' exists and not a directory.";
        }
        # path exists and a directory
        return 1;
    }

    if ($mkdir) {
        return 1;
    }

    croak "Path '$path' does not exists. Can't write PID.";

}


sub validate_pid {
    my ($pid) = @_;

    return 0 unless $pid;
    if ($pid =~ m/^\d*$/s) {
        return 1;
    }
    return 0;
}


sub make_sandbox {
    my ($pidfile_full, $daemon_data) = @_;

    croak "Can't make sandbox without any data." unless $pidfile_full;

    my ($pidfile, $path) = fileparse($pidfile_full);

    if (-e $path) {
        return 1;
    }

    mkdir $path or croak "Can't 'mkdir $path' Error: $!";
    
    if ($daemon_data->{user} || $daemon_data->{group}) {
        my $uid = getpwnam($daemon_data->{user});
        my $gid = getgrnam($daemon_data->{group});
        chown $uid, $gid, $path;
    }
    return 1;
}


sub suppress {
    open STDIN , '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
}


1;

__END__
