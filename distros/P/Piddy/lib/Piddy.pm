package Piddy;

=head1 NAME

Piddy - Easy Linux PID Management

=head1 DESCRIPTION

Manage the current process/pid and/or external ones (Not the current process) easily with this module. Use 
it to create helpful sysadmin scripts while it lets you control the flow of a process by suspending and resuming 
it at will. Some options require root access, but Piddy will let you know which ones when you try to run them.
Piddy will even attempt to determine if the pid instance is actually running as a threaded process.
This module probably still needs a lot of work, but it functions fine for the most part.

=head1 SYNOPSIS

    use Piddy;

    my $pid = Piddy->new({
        pid   => 5367,
        path  => '/var/run/pids',
    });

    if ($pid->running($pid->pid)) {
        $pid->suspend($pid->pid); # temporarily stop the process where it is
        print $pid->info('state') . "\n"; # read the current state of the process
        sleep 20;
        $pid->continue($pid->pid); # resume the process from where it was stopped
    }
    else { print "Oh.. " . $pid->pid . " is not actually running..\n"; }

=cut

use strict;
use warnings;
use 5.010;

use FindBin;
use File::Basename 'fileparse';

$Piddy::VERSION = '0.02';

=head2 new

Creates a new PID instance. There are a couple of options you can pass...

pid = Use an external PID (Not the current running process).
path = Location of the pid file

    # Use pid 5367 and save the pid file as /var/run/pids/5367.pid
    my $p = Piddy->new({pid => 5367, path => '/var/run/pids'});

=cut

sub new {
    my ($class, $args) = @_;
 
    my $ext_pid = 0; # are we using a pid other than the current running script?
    my $self = {};
    my ($name, $path, $suffix) = fileparse($0, '\.[^\.]*');
    $self->{path} = "$FindBin::Bin";
    $self->{errors} = [];    
    if ($args) {
        for (keys %$args) {
            given ($_) {
                when ('path') {
                    $self->{path} = $args->{$_};
                }
                when ('pid') {
                    $self->{pid} = $args->{$_};
                    $ext_pid = 1;
                }
                default {
                    warn "Unknown option: $_";
                    __PACKAGE__->last_error("Unknown option: $_");
                }
            }
        }
    }

    bless $self, __PACKAGE__;
    if (! $ext_pid) {
        my $filename = "$self->{path}/$name.pid";
        $self = {
            pid        => $$,
            pid_file   => $filename,
        };

        $self->_read_info;

        if ($self->_pid_exists($filename)) {
            # we may be inside a thread if the pid is still running
            # check to see if it's the ppid, if not, kill it.
            my $rpid = $self->read($filename);
            if (! $rpid eq getppid()) {
                # remove it nicely, but if that fails, then DESTROY IT
                kill 15, $rpid;
                if ($self->running) {
                    kill 9, $rpid;
                    if ($self->running) {
                        warn "Argh. I could not kill $rpid... can you please do it for me? :-(";
                    }
                }
                
                unlink $filename;
            }
            else {
                # need to change filename to reflect the forked process
                my $path = $self->{path}||"$FindBin::Bin";
                $filename = $path . "/" . $name . "." . $self->{pid} . ".pid";
                $self->{pid_file} = $filename;
            }
        } 
        open(my $pid_file, ">$filename") or
            die "Could not open pid file $filename for writing";

        print $pid_file $$ or do {
            $self->last_error("Could not write PID to $filename");
        };
   
        close $pid_file; 
        return $self;
    }
    else {
        $self->{extpid} = 1;
        $self->_read_info;
        return $self;
    }
}

=head2 info

Reads information on the process from /proc

    my $state = $pid->info('state'); # Piddy formats state to make it look nicer, too!

=cut

sub info {
    my ($self, $info) = @_;

    $self->_read_info;
    if (exists $self->{info}->{$info}) { return $self->{info}->{$info}; }
    else { return 0; }
}

=head2 suspend

Temporarily suspend a process (will not kill it, simply stops it exactly where it is so you 
can resume it later. Handy when writing scripts to monitor performance - you can stop the process 
then resume it when things have cooled down.

    $pid->suspend(5367);

=cut

sub suspend {
    my ($self, $pid) = @_;

    if ($self->kill('-STOP', $pid)) { return 1; }
    else { return 0; }
}

=head2 continue

Resumes a stopped process.

    $pid->continue(5367);

=cut

sub continue {
    my ($self, $pid) = @_;

    if ($self->kill('-CONT', $pid)) { return 1; }
    else { return 0; }
}

=head2 kill

Uses the systems kill command instead of Perl's. If you simply want to -9 or -15 
a process then use Perl, but for things like stopping/continuing processes, I could 
not get it to work any other way.

    $pid->kill('-9', 5367);
    $pid->kill('-STOP', 5367); # or just use $pid->suspend(5367);

=cut

sub kill {
    my ($self, $args, $pid) = @_;

    if ($< != 0) {
        warn "This action requires root access";
        return 0;
    }
    
    my $cmd = `kill $args $pid`;
    chomp $cmd;
    if ($cmd eq '') { return 1; }
    else { return 0; }
}

=head2 ppid

Returns the parent process id

=cut

sub ppid {
    my $self = shift;
    
    return getppid();
}

=head2 pid

Returns the pid of the current instance

=cut

sub pid {
    my $self = shift;
    
    return $self->{pid};
}

=head2 running

Determines whether the current pid is running, or if you pass 
another pid as an argument it will check that instead.
By default it will use /proc, otherwise it will revert to ps and grep.

    if ($pid->running(5367)) { print "It's running!\n"; }

=cut

sub running {
    my ($self, $cpid) = @_;

    # if the fs has /proc, then use it
    # otherwise fallback on ps
    my $pid = $cpid||$self->{pid};
    if (-d '/proc') {
        if (-d "/proc/$pid") {
            return 1;
        }
        else { return 0; }
    }
    else {
        my $ps = `ps -A | grep $pid`;
        $ps =~ s/^\s*//;
        if ($ps =~ /^$pid /) { return 1; }
        else { return 0; }
    }
}

=head2 last_error

Returns the last known error

=cut

sub last_error {
    my ($self, $err) = @_;

    if ($err) { push @{$self->{errors}}, $err }
    else { return $self->{errors}->[ scalar(@{$self->{errors}})+1 ]; }
}

sub read {
    my ($self, $fname) = @_;

    if (! $self->_pid_exists($fname)) { return 0; }
    else {
        my $getpid;
        open (my $pid, "<$fname") or return 0;
        while(<$pid>) {
            $getpid = $_;
        }
        close $pid;
        
        return $getpid;
    }
}

sub _pid_exists {
    my ($self, $fname) = @_;

    if (-f $fname) { return 1; }
    else { return 0; }
}

sub _read_info {
    my $self = shift;

    open(my $proc, "/proc/$self->{pid}/status") or return 0;
    while(<$proc>) {
        my ($key, $value) = /(.+):\s*(.+)/;
        $self->{info}->{lc($key)} = $value;
    }
    close $proc;

    # some fixups
    # state
    my $state = $self->{info}->{state};
    if ($state =~ /(.+)\s*\((.+)\)/) {
        $self->{info}->{state} = lc $2;
    }
}

sub DESTROY {
    my $self = shift;
    if (! $self->{extpid}) {
        if (! unlink $self->{pid_file}) {
            warn "There was a problem removing '$self->{pid_file}'";
        }
        else { say "Removed $self->{pid_file}"; }
    }
}

=head1 BUGS

Please e-mail bradh@cpan.org

=head1 AUTHOR

Brad Haywood <bradh@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

1;
