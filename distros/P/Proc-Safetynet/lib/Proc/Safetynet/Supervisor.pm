package Proc::Safetynet::Supervisor;
use strict;
use warnings;

use Proc::Safetynet::POEWorker;
use base qw/Proc::Safetynet::POEWorker/;

use Carp;
use Data::Dumper;
use POE::Kernel;
use POE::Session;
use IO::Handle;
use Scalar::Util qw/blessed reftype/;

use File::Spec;
use Proc::Safetynet::Event;
use Proc::Safetynet::Program;
use Proc::Safetynet::ProgramStatus;
use POSIX ':sys_wait_h';

sub initialize {
    my $self        = $_[OBJECT];
    # add states
    $_[KERNEL]->state( 'heartbeat'                      => $self );
    $_[KERNEL]->state( 'do_postback'                    => $self );
    $_[KERNEL]->state( 'list_programs'                  => $self );
    $_[KERNEL]->state( 'add_program'                    => $self );
    $_[KERNEL]->state( 'remove_program'                 => $self );
    $_[KERNEL]->state( 'update_program'                 => $self );
    $_[KERNEL]->state( 'info_program'                   => $self );
    $_[KERNEL]->state( 'list_status'                    => $self );
    $_[KERNEL]->state( 'info_status'                    => $self );
    $_[KERNEL]->state( 'start_program'                  => $self );
    $_[KERNEL]->state( 'stop_program'                   => $self );
    $_[KERNEL]->state( 'stop_program_timeout'           => $self );
    $_[KERNEL]->state( 'commit_programs'                => $self );
    $_[KERNEL]->state( 'nop'                            => $self );

    $_[KERNEL]->state( 'sig_ignore'                     => $self );
    $_[KERNEL]->state( 'sig_CHLD'                       => $self );
    $_[KERNEL]->state( 'sig_PIPE'                       => $self );

    $_[KERNEL]->state( 'tell_event'                     => $self );
    $_[KERNEL]->state( 'bcast_system_error'             => $self );
    $_[KERNEL]->state( 'bcast_system_info'              => $self );
    $_[KERNEL]->state( 'bcast_process_started'          => $self );
    $_[KERNEL]->state( 'bcast_process_stopped'          => $self );
    # trap signals
    $_[KERNEL]->sig( PIPE   => 'sig_PIPE' );
    #$_[KERNEL]->sig( INT    => 'sig_ignore' );
    $_[KERNEL]->sig( HUP    => 'sig_ignore' );
    $_[KERNEL]->sig( TERM   => 'sig_ignore' );
    # verify programs
    {
        (defined $self->options->{programs})
            or confess "spawn() requires a defined 'programs' parameter";
        (ref($self->options->{programs}) 
            and $self->options->{programs}->isa( "Proc::Safetynet::Program::Storage" ))
            or confess "spawn() requires a valid 'programs' parameter";
        $self->{programs} = $self->options->{programs};
    }
    # verify binpath
    {
        (defined $self->options->{binpath})
            or confess "spawn() requires a defined 'binpath' parameter";
        my @p = ();
        foreach my $tp (split /:/, $self->options->{binpath}) {
            my ($path) = ($tp =~ /^(.*)$/);
            (-d $path)
                or confess "binpath expects valid directories";
            ($path !~ /\.\.\//)
                or confess "binpath does not allow (..) directories";
            ($path =~ /^\//)
                or confess "binpath only allows absolute directories";
            push @p, $path;
        }
        $ENV{PATH} = join(':', @p);
    }

    # verify logpath
    {
        my $lpath = $self->options->{logpath} || File::Spec->tmpdir();
        my ($logpath) = ($lpath =~ /^(.*)$/);
        (-d $logpath)
            or confess "logpath ($logpath) option does not exist";
        $self->{logpath} = $logpath;
    }

    # verify logext_stderr
    {
        my $x = $self->options->{logext_stderr} || '.stderr';
        # log ext should match the pattern (.\w+)
        my ($logext) = ($x =~ /^(\.\w+)$/);
        ($logext)
            or confess "logext_stderr ($logext) should match pattern ".'"\.\w+"';
        $self->{logext_stderr} = $logext;
    }

    # verify logext_stdout
    {
        my $x = $self->options->{logext_stderr} || '.stdout';
        # log ext should match the pattern (.\w+)
        my ($logext) = ($x =~ /^(\.\w+)$/);
        ($logext)
            or confess "logext_stdout ($logext) should match pattern ".'"\.\w+"';
        $self->{logext_stdout} = $logext;
    }

    # start monitoring
    $self->{monitored} = { };
    $self->{killed} = { };
    foreach my $p (@{ $self->{programs}->retrieve_all() }) {
        $self->monitor_add_program( $p );
    }
    $self->yield( 'start_work' );
}


sub heartbeat {
    my $self        = $_[OBJECT];
    $_[KERNEL]->delay( 'heartbeat' => 1 );
}


sub start_work {
    my $self        = $_[OBJECT];
    # start all autostart processes
    foreach my $p (@{ $self->{programs}->retrieve_all() }) {
        if ($p->autostart) {
            $self->yield( 'start_program', [ $self->alias, 'nop' ], [ $p ], $p->name );
        }
    }
}


sub nop {
    # do nothing
}


sub sig_ignore {
    # ignore signals for now ...
    $_[KERNEL]->yield( 'bcast_system_info', "unexpected signal ignored" );
    $_[KERNEL]->sig_handled();
}


sub sig_PIPE {
    # ignore signals for now ...
    $_[KERNEL]->yield( 'bcast_system_info', "SIGPIPE warning" );
    $_[KERNEL]->sig_handled();
}


# SIGCHLD handler
sub sig_CHLD {
    my $self        = $_[OBJECT];
    my $name        = $_[ARG0];
    my $pid         = $_[ARG1];
    my $exit_val    = $_[ARG2];
    ##print STDERR "SIGCHLD: $name, $pid, $exit_val\n";
    # clear status
    my $program_name = '';
    foreach my $ps_key (keys %{ $self->{monitored} }) {
        my $ps = $self->{monitored}->{$ps_key};
        my $pspid = $ps->pid() || 0;
        if ($pspid == $pid) {
            ##print STDERR "post: pid=$pid, pspid=".$ps->pid(), "\n";
            $ps->pid(0);
            $ps->stopped_since( time() );
            $ps->is_running( 0 );
            delete $ps->{_stdin};
            $program_name = $ps_key;
            last;
        }
    }
    # postback if killed
    if (exists $self->{killed}->{$program_name}) {
        my $pb = delete $self->{killed}->{$program_name};
        $_[KERNEL]->yield( 'do_postback', $pb->[0], $pb->[1], 1 );
        $_[KERNEL]->delay( 'stop_program_timeout' ); # cancel
    }
    # schedule for restart, if applicable
    my $prog = $self->{programs}->retrieve( $program_name );
    if (defined $prog) {
        # an event has happened, a process has been started ...
        $_[KERNEL]->yield( 'bcast_process_stopped', $prog, $exit_val, 1 );
        # autorestart if applicable
        if ($prog->autorestart()) {
            $_[KERNEL]->delay_add( 
                'start_program' => 
                $prog->autorestart_wait(), 
                [ $self->alias, 'nop'], 
                [ $prog, $exit_val ], 
                $program_name,
            );
        }
    }
}


sub do_postback {
    my $postback    = $_[ARG0];
    my $stack       = $_[ARG1];
    my $result      = $_[ARG2];
    my $error       = $_[ARG3];
    # filter the result to output only public information
    if (defined($result) and blessed($result)) {
        # FIXME: maybe we can refactor this later into its own routine
        if (reftype($result) eq 'HASH') {
            my $class = ref($result);
            my $o = { };
            foreach my $k (keys %$result) {
                # we'd like to filter out the private keys 
                # starting with underscores "_"
                if ($k !~ m/^_/) {  
                    $o->{$k} = $result->{$k};
                }
            }
            $result = $class->new($o);
        }
    }
    #print Dumper( [ $_[STATE], $postback, $stack, $result ] );
    my $res = { result => $result };
    if (defined $error) { 
        my $cerr = $error;
        if ($error =~ m/^(.*)\s+at\s.*line\s\d+[\.\s\n]*$/m) {
            ($cerr) = $1;
        }
        $res->{error} = { message => $cerr };
    }
    $_[KERNEL]->post( 
        $postback->[0], 
        $postback->[1], 
        $stack,
        $res,
    ) or warn "unable to postback: $!";
}


# program provisioning
sub list_programs {
    my $result = $_[OBJECT]->{programs}->retrieve_all;
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $result );
} 


sub add_program {
    my $program = $_[ARG2];
    my $o = 0;
    my $e = undef;
    # TODO: sanitize the param
    # TODO: check whitelist
    eval {
        my $p = Proc::Safetynet::Program->new($program);
        $o = $_[OBJECT]->{programs}->add( $p ) ? 1 : 0;
        if ($o) { 
            # track status
            $_[OBJECT]->monitor_add_program( $p );
        }
    };
    if ($@) {
        $e = $@;
    }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub remove_program {
    my $program_name = $_[ARG2];
    my $o = 0;
    my $e = undef;
    eval {
        $_[OBJECT]->monitor_remove_program( $program_name );
        $o = $_[OBJECT]->{programs}->remove( $program_name ) ? 1 : 0;
    };
    if ($@) { $e = $@; }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub info_program {
    my $program_name = $_[ARG2];
    my $o = undef;
    my $e = undef;
    eval {
        $o = $_[OBJECT]->{programs}->retrieve( $program_name );
    };
    if (not defined $o) {
        $e = "object does not exist";
    }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub update_program {
    my $program_name    = $_[ARG2];
    my $fieldval        = $_[ARG3];
    my $o = 0;
    my $e = undef;
    my $allowed_updates = {
        command             => 1,
        autostart           => 1,
        autorestart         => 1,
        autorestart_wait    => 1,
        priority            => 1,
        eventlistener       => 1,
    };
    eval {
        # check field values
        (ref($fieldval) eq 'HASH')
            or die "field expected as HASH";
        my $p = $_[OBJECT]->{programs}->retrieve( $program_name );
        (defined $p)
            or die "object does not exist";
        # check allowed field values
        foreach my $k (keys %$fieldval) {
            if (not exists $allowed_updates->{$k}) {
                die "updating field '$k' not allowed";
            }
        }
        # update
        foreach my $k (keys %$fieldval) {
            $p->{$k} = $fieldval->{$k};
        }
        $o = 1;
    };
    if ($@) { $e = $@; }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub commit_programs {
    my $o = undef;
    my $e = undef;
    eval {
        $o = $_[OBJECT]->{programs}->commit;
    };
    if ($@) {
        $e = $@;
    }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

# process management

sub list_status { 
    my $o = undef;
    $o = $_[OBJECT]->{monitored};
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o );
}

sub info_status { 
    my $program_name = $_[ARG2];
    my $o = undef;
    my $e = undef;
    if (exists $_[OBJECT]->{monitored}->{$program_name}) {
        $o = $_[OBJECT]->{monitored}->{$program_name};
    }
    if (not defined $o) {
        $e = "status for object ($program_name) does not exist";
    }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub start_program { 
    my $program_name = $_[ARG2];
    my $self = $_[OBJECT];
    my $p = undef;
    my $o = 0;
    my $e = undef;
    # TODO: don't start if already started
    SPAWN: {
        if (exists $_[OBJECT]->{monitored}->{$program_name}) {
            my $ps = $_[OBJECT]->{monitored}->{$program_name};
            if ($ps->is_running) {
                # already running
                $e = "already running";
                last SPAWN;
            }
            $p = $_[OBJECT]->{programs}->retrieve($program_name);
            my $command = $p->command;

            # pipe: simulate open(FOO, "|-")
            # -----
            my $parentfh;
            my $childfh;
            if ($p->eventlistener) {
                # pipe only if this is an eventlistener process
                $parentfh = IO::Handle->new;
                eval {
                    pipe $childfh, $parentfh 
                        or die $!;
                };
                if ($@) {
                    $_[KERNEL]->yield( 'bcast_system_error', "unable to create pipe: $@", $p );
                    $e = "unable to create pipe: $@";
                    last SPAWN; 
                }
            }
            # redirect stderr
            eval {
                my ($pname)  = ($program_name =~ /^(.*)$/);
                my $filename = File::Spec->catfile( 
                    $self->{logpath},
                    join('',$pname,$self->{logext_stderr}),
                );
                open STDERR, ">>$filename"
                    or die "($filename): $!";
            };
            if ($@) {
                $_[KERNEL]->yield( 'bcast_system_error', "unable to redirect stderr: $@", $p );
                $e = "unable to redirect stderr: $@";
                last SPAWN; 
            }
            # redirect stdout
            eval {
                my ($pname)  = ($program_name =~ /^(.*)$/);
                my $filename = File::Spec->catfile( 
                    $self->{logpath},
                    join('',$pname,$self->{logext_stdout}),
                );
                open STDOUT, ">>$filename"
                    or die "($filename): $!";
            };
            if ($@) {
                $_[KERNEL]->yield( 'bcast_system_error', "unable to redirect stdout: $@", $p );
                $e = "unable to redirect stdout: $@";
                last SPAWN; 
            }
            # fork
            # ----
            my $pid = fork;
            if (not defined $pid) {
                $_[KERNEL]->yield( 'bcast_system_error', "unable to fork: $@", $p );
                $e = "unable to fork: $!";
                last SPAWN;
            }
            if ($pid) {
                # parent here
                if ($p->eventlistener) {
                    close $childfh;
                }
                $_[KERNEL]->sig_child( $pid, 'sig_CHLD' );
                $ps->is_running( 1 );
                $ps->pid( $pid );
                $ps->started_since( time() );
                # trap autoflush handle errors
                eval {
                    if (defined $parentfh) {
                        $parentfh->autoflush(1);
                    }
                    $ps->{_stdin} = $parentfh;
                    ##print STDERR "$$: started $program_name, pid=$pid\n";
                    $o = 1;
                };
                if ($@) {
                    $e = "$$: setup of child stdin failed: $@";
                    warn $e;
                    last SPAWN;
                }
            }
            else {
                # child here ... a point of no return # TODO: redirect STDERR, STDOUT ...
                # TODO: check whitelist
                # TODO: apply uid/gid changes 
                # TODO: apply chroot
                # assume command was already sanitized
                if ($p->eventlistener) {
                    close $parentfh;
                    open(STDIN, "<&=" . fileno($childfh)) 
                        or die "child unable to open stdin";
                }
                my ($cmd) = ($command =~ /^(.*)$/);
                exec $cmd
                    or exit(100);
            }
        }
        else {
            $e = "object does not exist";
        }
    }
    if ($o) {
        # an event has happened, a process has been started
        $_[KERNEL]->yield( 'bcast_process_started', $p, 1 );
    }
    $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], $o, $e );
}

sub stop_program {
    my $program_name = $_[ARG2];
    my $e = undef;
    if (exists $_[OBJECT]->{monitored}->{$program_name}) {
        my $ps = $_[OBJECT]->{monitored}->{$program_name};
        if ( ($ps->is_running) and (not exists $_[OBJECT]->{killed}->{$program_name}) ) {
            # defer postback until either SIGCHLD or time out waiting
            $_[OBJECT]->{killed}->{$program_name} = [ $_[ARG0], $_[ARG1], ];
            # kill the process
            my $o = kill 'TERM', $ps->pid;
            if ($o > 0) {
                # okay, we've signalled the process, we now have to wait for SIGCHLD to occur
                #   or timeout
                $_[KERNEL]->delay( 'stop_program_timeout' => 10, @_[ARG0, ARG1], $program_name );
            }
            else {
                # signalling did not work this time
                $e = "kill signal failed";
                $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], 0, $e );
            }
        }
        else {
            # not running or already issued a kill
            $e = "not running or already issued kill signal";
            $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], 0, $e );
        }
    }
    else {
        # non-existent
        $e = "object does not exist";
        $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], 0, $e );
    }
}

sub stop_program_timeout {
    my $program_name = $_[ARG2];
    if (exists $_[OBJECT]->{killed}->{$program_name}) {
        delete $_[OBJECT]->{killed}->{$program_name};
        my $e = "timeout";
        $_[KERNEL]->yield( 'do_postback', @_[ARG0, ARG1], 0, $e );
    }
}


sub shutdown {
    my $self        = $_[OBJECT];
    $_[KERNEL]->delay( 'heartbeat' );
    $self->SUPER::shutdown( @_[1..$#_]);
}

# ============== Event Broadcasters

# POE_ARGS( $p, $ps, $event )
# - sends the event to one event listener
sub tell_event {
    my $self    = $_[OBJECT];
    my $p       = $_[ARG0];
    my $ps      = $_[ARG1];
    my $event   = $_[ARG2];
    # write to STDIN of event listener
    my $stdin   = $ps->{_stdin};
    if (defined $stdin) {
        print $stdin $event->as_string."\n";
    }
}


sub _do_event_bcast { # non-POE
    my $self = shift;
    my $event = shift;
    foreach my $p (@{ $self->{programs}->retrieve_all } ) {
        my $pname = $p->name;
        my $ps = $self->{monitored}->{$pname};
        if ($ps->is_running and $p->eventlistener) {
            $self->yield( 'tell_event' => $p, $ps, $event );
        }
    }
}


sub bcast_system_error {
    my $self    = $_[OBJECT];
    my $message = $_[ARG0];
    my $p       = $_[ARG1];
    my $object  = '@SYSTEM'; #default
    if (defined $p) {
        $object = $p->name;
    }
    my $ev = Proc::Safetynet::Event->new(
        event       => 'system_error',
        object      => $object,
        message     => $message,
    );
    $self->_do_event_bcast( $ev );
}


sub bcast_system_info {
    my $self    = $_[OBJECT];
    my $message = $_[ARG0];
    my $p       = $_[ARG1];
    my $object  = '@SYSTEM'; #default
    if (defined $p) {
        $object = $p->name;
    }
    my $ev = Proc::Safetynet::Event->new(
        event       => 'system_info',
        object      => $object,
        message     => $message,
    );
    $self->_do_event_bcast( $ev );
}


sub bcast_process_started {
    my $self    = $_[OBJECT];
    my $p       = $_[ARG0];
    my $started = $_[ARG1];
    if ($started) {
        my $ev = Proc::Safetynet::Event->new(
            event       => 'process_started',
            object      => $p->name,
        );
        $self->_do_event_bcast( $ev );
    }
}


sub bcast_process_stopped {
    my $self    = $_[OBJECT];
    my ($p, $exit_val, $stopped) = @_[ARG0, ARG1, ARG2];
    if ($stopped) {
        my $ev = Proc::Safetynet::Event->new(
            event       => 'process_stopped',
            object      => $p->name,
        );
        $self->_do_event_bcast( $ev );
    }
}

# ==============


sub monitor_add_program { # non-POE
    my $self = shift;
    my $p = shift;
    my $name = $p->name() || '';
    if (not exists $self->{monitored}->{$name}) {
        $self->{monitored}->{$name} 
            = Proc::Safetynet::ProgramStatus->new({ is_running => 0 });
        # TODO: start if autostart
    }
}


sub monitor_remove_program { # non-POE
    my $self = shift;
    my $name = shift;
    my $ret  = 0;
    if (exists $self->{monitored}->{$name}) {
        my $ps = $self->{monitored}->{$name};
        if ($ps->is_running) { 
            croak "cannot remove running program"; 
        }
        delete $self->{monitored}->{$name};
        $ret = 1;
    }
    return $ret;
}



1;

__END__
