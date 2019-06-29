package Proc::Daemon::Prefork;

our $DATE = '2019-06-27'; # DATE
our $VERSION = '0.710'; # VERSION

use 5.010001;
use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);
use File::Which;
use FindBin;
use IO::Select;
use POSIX;
use Symbol;

# --- globals

my @daemons; # list of all daemons

sub new {
    my ($class, %args) = @_;

    # defaults
    if (!$args{name}) {
        $args{name} = $0;
        $args{name} =~ s!.+/!!;
    }
    $args{require_root}           //= 0;
    $args{daemonize}              //= 1;
    $args{prefork}                //= 3;
    $args{max_children}           //= 150;

    die "BUG: Please specify main_loop routine"
        unless $args{main_loop};

    if ($args{on_client_disconnect}) {
        die "netstat is not available in PATH"
            unless -x which("netstat");
        require Parse::Netstat;
    }

    $args{parent_pid} = $$;
    $args{children} = {}; # key = pid
    my $self = bless \%args, $class;
    push @daemons, $self;
    $self;
}

sub check_pidfile {
    my ($self) = @_;
    return unless -f $self->{pid_path};
    open my($pid_fh), $self->{pid_path};
    my $pid = <$pid_fh>;
    $pid = $1 if $pid =~ /(\d+)/; # untaint
    # XXX check timestamp to make sure process is the one meant by pidfile
    return unless $pid > 0 && kill(0, $pid);
    $pid;
}

sub write_pidfile {
    my ($self) = @_;
    die "BUG: Overwriting PID without checking it" if $self->check_pidfile;
    open my($pid_fh), ">$self->{pid_path}";
    print $pid_fh $$;
    close $pid_fh or die "Can't write PID file: $!\n";
}

sub unlink_pidfile {
    my ($self) = @_;
    my $old_pid = $self->check_pidfile;
    die "BUG: Deleting active PID which isn't ours"
        if $old_pid && $old_pid != $$;
    unlink $self->{pid_path};
}

sub kill_running {
    my ($self) = @_;
    die "You did not daemonize, so you cannot kill_running()"
        unless $self->{daemonized};
    for ({sig=>"TERM", delay=>1},
         {sig=>"TERM", delay=>3},
         {sig=>"KILL"},
     ) {
        my $pid = $self->check_pidfile;
        return unless $pid;
        kill $_->{sig} => $pid;
        sleep $_->{delay} // 0;
        my $pid2 = $self->check_pidfile;
        return unless $pid2 && $pid2 == $pid;
    }
}

sub open_logs {
    my ($self) = @_;

    if ($self->{error_log_path}) {
        open my($fhe), ">>", $self->{error_log_path}
            or die "Cannot open error log file $self->{error_log_path}: $!\n";
        $self->{_error_log} = $fhe;
    } elsif ($self->{error_log_handle}) {
        $self->{_error_log} = $self->{error_log_handle};
    }

    if ($self->{access_log_path}) {
        open my($fha), ">>", $self->{access_log_path}
            or die "Cannot open access log file $self->{access_log_path}: $!\n";
        $self->{_access_log} = $fha;
    } elsif ($self->{access_log_handle}) {
        $self->{_access_log} = $self->{access_log_handle};
    }
}

sub close_logs {
    my ($self) = @_;
    if ($self->{_access_log}) {
        $self->{_access_log}->close;
    }
    if ($self->{_error_log}) {
        $self->{_error_log}->close;
    }
}

sub daemonize {
    my ($self) = @_;

    local *ERROR_LOG;
    $self->open_logs;
    *ERROR_LOG = $self->{_error_log};

    chdir '/'                  or die "Can't chdir to /: $!\n";
    open STDIN, '/dev/null'    or die "Can't read /dev/null: $!\n";
    open STDOUT, '>&ERROR_LOG' or do {
        # ERROR_LOG is not a file descriptor but e.g. a tied filehandle. we want
        # to allow this so we provide an alternative.
        *STDOUT = \*ERROR_LOG;
        #die "Can't dup ERROR_LOG: $!\n";
    };
    defined(my $pid = fork)    or die "Can't fork: $!\n";
    exit if $pid;

    unless (0) { #$self->{force}) {
        my $old_pid = $self->check_pidfile;
        die "Another daemon already running (PID $old_pid)\n" if $old_pid;
    }

    setsid                     or die "Can't start a new session: $!\n";
    open STDERR, '>&STDOUT'    or do {
        # not a file descriptor but e.g. a tied filehandle. we want to allow
        # this so we provide an alternative.
        *STDERR = \*STDOUT;
        # die "Can't dup stdout: $!\n";
    };
    $self->{daemonized}++;
    $self->write_pidfile;
    $self->{parent_pid} = $$;
}

sub parent_sig_handlers {
    my ($self) = @_;
    die "BUG: Setting parent_sig_handlers must be done in parent"
        if $self->{parent_pid} ne $$;

    $SIG{INT}  = \&INT_HANDLER;
    $SIG{TERM} = \&TERM_HANDLER;
    #$SIG{HUP} = \&RELOAD_HANDLER;

    $SIG{CHLD} = \&REAPER;
}

# for children
sub child_sig_handlers {
    my ($self) = @_;
    die "BUG: Setting child_sig_handlers must be done in children"
        if $self->{parent_pid} eq $$;

    $SIG{INT}  = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';
    $SIG{HUP}  = 'DEFAULT';
    $SIG{CHLD} = 'DEFAULT';
}

sub init {
    my ($self) = @_;

    #$self->{scoreboard_path} or die "BUG: Please specify scoreboard_path";
    if ($self->{require_root}) {
        $> and die "Permission denied, daemon must be run as root\n";
    }

    $self->daemonize if $self->{daemonize};
    warn "Daemon (PID $$) started at ", scalar(localtime), "\n";
}

# XXX use shared memory scoreboard for better performance
my $SC_RECSIZE = 20;

# the scoreboard file contains fixed-size records, $SC_RECSIZE bytes each. each
# record is used by a child process to store its data, and when the child
# process is dead, its record will be reused by another child process.
#
# each record contains the following data:
#
# - pid of child process (4 bytes), 0 means the record is empty and can be used
#   for a new child process
#
# - child start time (4 bytes)
#
# - number of requests that the child has processed (2 bytes)
#
# - current request's start time (4 bytes)
#
# - last update time (4 byte)
#
# - current state of child process (1 byte, ASCII character): "_" means idle,
#   "R" is reading request, "W" is writing reply
#
# - reserved (1 byte)
#
# total 20 bytes per record.
#
# when a new daemon is started, the parent process truncates the scoreboard to 0
# bytes. the scoreboard then will grow as new child processes are started. each
# child process will find an empty record on the scoreboard and then only write
# to that record for the rest of its lifetime. the parent usually only reads the
# scoreboard file, but when a child process is dead/reaped it will clean the
# scoreboard record of dead processes. the only time a scoreboard file needs to
# be locked is when the new child process tries to occupy a new record (so that
# two child processes do not get into race condition). at other times, a lock is
# not needed.

sub init_scoreboard {
    my ($self) = @_;
    return unless $self->{scoreboard_path};

    sysopen($self->{_scoreboard_fh}, $self->{scoreboard_path},
            O_RDWR | O_CREAT | O_TRUNC)
        or die "Can't initialize scoreboard path: $!";
    # for safety against full disk, pre-allocate some empty records
    syswrite $self->{_scoreboard_fh},
        "\x00" x ($SC_RECSIZE*($self->{max_children}+1));
}

# used by child process to update its state in the scoreboard file.
sub update_scoreboard {
    my ($self, $data) = @_;
    return unless $self->{_scoreboard_fh};

    # XXX schema
    die "BUG: data must be hashref" unless ref($data) eq 'HASH';
    for (keys %$data) {
        die "BUG: Unknown key in data: $_" unless
            /\A(?:child_start_time|num_reqs|req_start_time|
                 state)\z/x;
    }

    # if we haven't picked an empty record yet, pick now
    if (!defined($self->{_scoreboard_recno})) {
        flock $self->{_scoreboard_fh}, 2;
        sysseek $self->{_scoreboard_fh}, 0, 0;
        my $rec;
        $self->{_scoreboard_recno} = 0;
        my $pid;
        while (sysread($self->{_scoreboard_fh}, $rec, $SC_RECSIZE)) {
            die "Abnormal scoreboard file size (not multiples of $SC_RECSIZE)"
                if length($rec) && length($rec) < $SC_RECSIZE; # safety
            $pid = unpack("N", $rec);
            last if !$pid; # empty record
            $self->{_scoreboard_recno}++;
        }
        # we need to make a new record
        $self->{_scoreboard_recno}++ if !defined($pid) || $pid;
        sysseek $self->{_scoreboard_fh},
            $self->{_scoreboard_recno}*$SC_RECSIZE, 0;
        syswrite $self->{_scoreboard_fh},
            pack("NNSNNCC", $$, 0,0,0,0,ord("_"),0);
        flock $self->{_scoreboard_fh}, 8;
    }
    sysseek $self->{_scoreboard_fh},
        $self->{_scoreboard_recno}*$SC_RECSIZE, 0; # needn't write pid again
    my $rec;
    sysread $self->{_scoreboard_fh}, $rec, $SC_RECSIZE;
    my ($pid, $child_start_time, $num_reqs, $req_start_time,
        $mtime, $state) = unpack("NNSNNC", $rec);
    $state = chr($state);
    sysseek $self->{_scoreboard_fh},
        $self->{_scoreboard_recno}*$SC_RECSIZE, 0;
    syswrite $self->{_scoreboard_fh},
        pack("NNSNNCC",
             $pid,
             $data->{child_start_time} // $child_start_time // 0,
             $data->{num_reqs} // $num_reqs // 0,
             $data->{req_start_time} // $req_start_time // 0,
             time(),
             ord($data->{state} // $state // "_"),
             0);
}

# clean records from process(es) that no longer exist. called by parent after
# being notified that a child is dead. once in a while, clean not only $pid but
# also check all records of dead processes.
sub clean_scoreboard {
    my ($self, $child_pid) = @_;
    return unless $self->{_scoreboard_fh};

    #warn "Cleaning scoreboard (pid $child_pid)\n";
    my $check_all = rand()*50 >= 49;

    my $rec;
    flock $self->{_scoreboard_fh}, 2;
    sysseek $self->{_scoreboard_fh}, 0, 0;
    my $i = -1;
    while (sysread($self->{_scoreboard_fh}, $rec, $SC_RECSIZE)) {
        $i++;
        die "Abnormal scoreboard file size (not multiples of $SC_RECSIZE)"
            if length($rec) && length($rec) < $SC_RECSIZE; # safety
        my ($pid) = unpack("N", $rec);
        next if !$check_all && $pid != $child_pid;
        next if $check_all && kill(0, $pid);
        sysseek $self->{_scoreboard_fh}, $i*$SC_RECSIZE, 0;
        syswrite $self->{_scoreboard_fh},
            pack("NNSNNCC", 0, 0,0,0,0,ord("_"),0);
        last unless $check_all;
    }
    flock $self->{_scoreboard_fh}, 8;
}

sub read_scoreboard {
    my ($self) = @_;
    return unless $self->{_scoreboard_fh};

    my $rec;
    my $res = {children=>{}, num_children=>0, num_busy=>0, num_idle=>0};
    sysseek $self->{_scoreboard_fh}, 0, 0;
    while (sysread($self->{_scoreboard_fh}, $rec, $SC_RECSIZE)) {
        die "Abnormal scoreboard file size (not multiples of $SC_RECSIZE)"
            if length($rec) && length($rec) < $SC_RECSIZE; # safety
        my ($pid, $child_start_time, $num_reqs, $req_start_time,
            $mtime, $state) = unpack("NNSNNC", $rec);
        $state = chr($state);
        next unless $pid;
        $res->{num_children}++;
        if ($state =~ /^[_.]$/) {
            $res->{num_idle}++;
        } else {
            $res->{num_busy}++;
        }
        $res->{children}{$pid} = {
            pid=>$pid,
            child_start_time=>$child_start_time,
            num_reqs=>$num_reqs,
            req_start_time=>$req_start_time,
            mtime=>$mtime,
            state=>$state,
        };
    }
    $res;
}

sub run {
    my ($self) = @_;

    $self->init;
    $self->set_label('parent');
    $self->{after_init}->() if $self->{after_init};
    $self->init_scoreboard;

    if ($self->{prefork}) {
        # prefork children
        for (1 .. $self->{prefork}) {
            $self->make_new_child();
        }
        $self->parent_sig_handlers;

        # maintain children population and do cleaning tasks
        my $i = 0;
        my $j = 0; # number of increments of child when busy
        my $k = 0; # number of decrements of child when idle
        my $max_children_warned;
        while (1) {
            sleep 1;
            if ($self->{auto_reload_check_every} &&
                    $i++ >= $self->{auto_reload_check_every}) {
                $self->check_reload_self;
                $i = 0;
            }

            # top up child pool until at least 'prefork'
            if (keys(%{$self->{children}}) < $self->{prefork}) {
                #warn "Topping up child pool to $self->{prefork}\n";
                for (my $i = keys(%{$self->{children}});
                     $i < $self->{prefork}; $i++) {
                    $self->make_new_child(); # top up the child pool
                }
            }

            my $scoreboard;

            if (rand()*5 >= 4 && $self->{on_client_disconnect}) {
                {
                    my $output;
                    {
                        local $SIG{CHLD} = 'DEFAULT';
                        $output = `netstat -anp 2>/dev/null`;
                    }
                    my $res    = Parse::Netstat::parse_netstat(
                        output => $output, udp=>0, unix=>0);
                    # currently unix stats is useless, everything is
                    # CONNECTED/CONNECTING and no pid
                    die "Bug: Netstat output can't be parsed: ".
                        "$res->[0] - $res->[1]" unless $res->[0] == 200;
                    my $conns = $res->[2]{active_conns};
                    my %called_children;
                    for my $conn (@$conns) {
                        my $pid = $conn->{pid};
                        next unless $pid;
                        next unless $conn->{state} =~ /(?:FIN_WAIT|CLOSE_WAIT)/;
                        next unless $self->{children}{ $pid };
                        next if $called_children{$pid}++;
                        $self->{on_client_disconnect}->(
                            pid => $pid,
                            local_host => $conn->{local_host},
                            local_port => $conn->{local_port},
                            foreign_host => $conn->{foreign_host},
                            foreign_port => $conn->{foreign_port},
                        );
                    }
                }
            }

            # if busy, autoadjust child pool until at least 'max_children', and
            # decrease it again when idle
            if (rand()*4 >= 3) {
                $scoreboard = $self->read_scoreboard;
                if ($scoreboard) {
                    if ($scoreboard->{num_busy} &&
                            $scoreboard->{num_idle} <= 1) {
                        warn "max_children ($self->{max_children} reached, ".
                            "consider increasing it)\n" if
                                $scoreboard->{num_children} >=
                                    $self->{max_children}
                                        && !$max_children_warned++;
                        $j++;
                        #warn "Autoadjust: increase number of children ".
                        #    "($j*2, $scoreboard->{num_children} -> .)\n";
                        for (1..$j*2) {
                            last if $scoreboard->{num_children} >=
                                $self->{max_children};
                            $self->make_new_child();
                            $scoreboard->{num_chilren}++;
                        }
                    } else {
                        $j = 0;
                    }

                    # disable temporarily, not yet working properly
                    if (0 && $scoreboard->{num_idle} >= 3 &&
                            $scoreboard->{num_children} > $self->{prefork}) {
                        $k++;
                        #warn "Autoadjust: decrease number of children ".
                        #    "($k*2, $scoreboard->{num_children} -> .)\n";

                        # sort by oldest idle
                        my @pids = sort {
                            $scoreboard->{children}{$a}{mtime} <=>
                                $scoreboard->{children}{$b}{mtime} }
                            grep {$scoreboard->{children}{$_}{state} eq '_'}
                                keys %{$scoreboard->{children}};
                        for (1..$k*2) {
                            last if
                                $scoreboard->{num_children} <= $self->{prefork};
                            if (@pids) {
                                # pick oldest idle child and kill it
                                my $pid = shift @pids;
                                if ($pid) {
                                    kill TERM => $pid;
                                    $scoreboard->{num_chilren}--;
                                    delete $scoreboard->{children}{$pid};
                                    delete $scoreboard->{children}{$pid};
                                    #warn "Killed process $pid (num_children=".
                                    #    "$scoreboard->{num_children})\n";
                                }
                            }
                        }
                    } else {
                        $k = 0;
                    }
                }
            }

        }
    } else {
        $self->{main_loop}->();
    }
}

sub make_new_child {
    my ($self) = @_;

    # from perl cookbook: block signal for fork
    my $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask(SIG_BLOCK, $sigset)
        or die "Can't block SIGINT for fork: $!\n";

    my $pid;
    unless (defined ($pid = fork)) {
        warn "Can't fork: $!";
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die "Can't unblock SIGINT for fork: $!\n";
        return;
    }

    if ($pid) {
        # from perl cookbook: Parent records the child's birth and returns.
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die "Can't unblock SIGINT for fork: $!\n";

        $self->{children}{$pid} = 1;
        return;
    } else {
        # from perl cookbook: Child can *not* return from this subroutine.
        $SIG{INT} = 'DEFAULT';      # make SIGINT kill us as it did before
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die "Can't unblock SIGINT for fork: $!\n";

        $self->child_sig_handlers;
        $self->set_label('child');
        $self->{main_loop}->();
        exit;
    }
}

sub set_label {
    my ($self, $label) = @_;
    $0 = $self->{name} . " [$label]";
}

sub kill_children {
    my ($self) = @_;
    warn "Killing children processes ...\n" if keys %{$self->{children}};
    for my $pid (keys %{$self->{children}}) {
        kill TERM => $pid;
    }
}

sub is_parent {
    my ($self) = @_;
    $$ == $self->{parent_pid};
}

sub shutdown {
    my ($self, $reason) = @_;

    warn "Shutting down daemon".($reason ? " (reason=$reason)" : "")."\n";
    $self->{before_shutdown}->() if $self->{before_shutdown};
    $self->kill_children if $self->is_parent;

    if ($self->{daemonized}) {
        $self->unlink_pidfile;
        $self->close_logs;
    }
}

sub REAPER {
    $SIG{CHLD} = \&REAPER;
    my $pid = wait;
    for (@daemons) {
        delete $_->{children}{$pid};
        $_->clean_scoreboard($pid);
    }
}

sub INT_HANDLER {
    local($SIG{CHLD}) = 'IGNORE'; # from perl cookbook
    for (@daemons) {
        $_->shutdown("INT");
    }
    exit 1;
}

sub TERM_HANDLER {
    local($SIG{CHLD}) = 'IGNORE'; # from perl cookbook
    for (@daemons) {
        $_->shutdown("TERM");
    }
    exit 1;
}

sub check_reload_self {
    my ($self) = @_;

    # XXX use Filesystem watcher instead of manually checking -M
    state $self_mtime;
    state $modules_mtime = {};

    my $should_reload;
    {
        my $new_self_mtime = (-M "$FindBin::Bin/$FindBin::Script");
        if (defined($self_mtime)) {
            do { $should_reload++; last } if $self_mtime != $new_self_mtime;
        } else {
            $self_mtime = $new_self_mtime;
        }

        for (keys %INC) {
            # undef entry in %INC can mean require() has failed loading it, skip
            # this for now
            next unless defined($INC{$_});
            my $new_module_mtime = (-M $INC{$_});
            if (defined($modules_mtime->{$_})) {
                #warn "$$: Comparing file $_ on disk\n";
                if ($modules_mtime->{$_} != $new_module_mtime) {
                    #warn "$$: File $_ changes on disk\n";
                    $should_reload++;
                    last;
                }
            } else {
                $modules_mtime->{$_} = $new_module_mtime;
            }
        }
    }

    if ($should_reload) {
        warn "$$: Reloading self because script/one of the modules ".
            "changed on disk ...\n";
        # XXX not yet working, needs --force somewhere
        $self->{auto_reload_handler}->($self);
    }
}

1;
# ABSTRACT: Create preforking, autoreloading daemon

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::Daemon::Prefork - Create preforking, autoreloading daemon

=head1 VERSION

This document describes version 0.710 of Proc::Daemon::Prefork (from Perl distribution Proc-Daemon-Prefork), released on 2019-06-27.

=for Pod::Coverage .*

=head1 METHODS

=head2 new(%args)

Arguments:

=over 4

=item * require_root => BOOL (default 0)

If true, bails out if not running as root.

=item * error_log_path => STR (required if daemonize=1)

Or, alternatively, specify C<error_log_handle> instead.

=item * error_log_handle => OBJ

An alternative to specifying C<error_log_path>, to allow logging to a
filehandle-like object, e.g. tied filehandle, instead of to a regular file.

=item * access_log_path => STR (required if daemonize=1)

Or, alternatively, specify C<access_log_handle> instead.

=item * access_log_handle => OBJ

An alternative to specifying C<access_log_path>, to allow logging to a
filehandle-like object, e.g. tied filehandle, instead of to a regular file.

=item * pid_path => STR (required if daemonize=1)

=item * scoreboard_path => STR (default none)

If not set, no scoreboard file will be created/updated. Scoreboard file is used
to communicate between parent and child processes. Autoadjustment of number of
processes, for example, requires this (see max_children for more details).

=item * daemonize => BOOL (default 1)

=item * prefork => INT (default 3, 0 means a nonforking/single-threaded daemon)

This is like the StartServers setting in Apache webserver (the prefork MPM), the
number of children processes to prefork.

=item * max_children => INT (default 150)

This is like the MaxClients setting in Apache webserver. Initially the number of
children spawned will follow the 'prefork' setting. If while serving requests,
all children are busy, parent will automatically increase the number of children
gradually until 'max_children'. If afterwards these children are idle, they will
be gradually killed off until there are 'prefork' number of children again.

Note that for this to function, scoreboard_path must be defined since the parent
needs to communicate with children.

=item * auto_reload_check_every => INT (default undef, meaning never)

In seconds.

=item * auto_reload_handler => CODEREF (required if auto_reload_check_every is set)

=item * after_init => CODEREF (default none)

Run after the daemon initializes itself (daemonizes, writes PID file, etc),
before spawning children. You usually bind to sockets here (if your daemon is a
network server).

=item * on_client_disconnect => CODEREF

Do something after socket connection between client and child process is closed.
This requires scoreboard (see C<scoreboard_path> argument) to record all the
children's PIDs, and also the "netstat" command and L<Parse::Netstat> module to
check for connections.

This can be used, for example, to kill child process (cancel job) on disconnect.

Will be called for each child server being disconnected. Code will receive a
hash containing: C<pid>, C<proto>, C<local_host>, C<local_port>,
C<foreign_host>, C<foreign_port>.

Note that monitoring connections is done every few seconds by the parent
process, so this code will not be run immediately after closing of connection.

Currently only works for TCP connections and not Unix connections, due to lack
of information provided by "netstat" for Unix connections.

=item * main_loop* => CODEREF

Run at the beginning of each child process. This is the main loop for your
daemon. You usually do this in your main loop routine:

 for(my $i=1; $i<=$MAX_REQUESTS_PER_CHILD; $i++) {
     # accept loop, or process job loop
 }

=item * before_shutdown => CODEREF (optional)

Run before killing children and shutting down.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Proc-Daemon-Prefork>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Proc-Daemon-Prefork>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Proc-Daemon-Prefork>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
