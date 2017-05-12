package POE::Component::Daemon;

use 5.00405;
use strict;

use vars qw($VERSION @ISA);

use POSIX qw(EAGAIN ECHILD SIGINT SIGKILL SIGTERM);
use POE;
use Carp;
use Data::Dumper;
use Scalar::Util qw( blessed );

use POE::Component::Daemon::Scoreboard;

$VERSION = '0.1400';

sub DEBUG () { 0 }
sub DEBUG_SC () { DEBUG or 0 }

our $NO_PEEK;
BEGIN {
    eval 'use POE::API::Peek;';
    $NO_PEEK = $@ if $@;
    # warn $NO_PEEK;
}


########################################################
sub new
{
    my($package)=shift;
    my $param;
    if(1==@_) {
        $param=shift;
    }
    else {
        $param={@_};
    }

    my $self=bless $param, $package;

    $self->{package}=$package;
    unless( $self->{alias} ) {
        $self->{alias} = $package;
        $self->{alias} =~ s/\W+/-/g;
    }

    return $self;
}

########################################################
sub spawn
{
    my($self)=shift;
    my $param={@_};

    unless(ref $self) {
        $self = $self->new($param);
    }
    else {
        while(my($k, $v)=each %$param) {
            $self->{$k}=$v if defined $v;
        }
    }

    $self->open_logfile;
    $self->drop_privs;
    $self->detach;

    return $self->create_session;
}

########################################################
sub drop_privs
{
    my($self)=@_;
    return if $self->{"drop_privs done"}++;
    return unless $self->{UID} or $self->{GID};
    warn ref($self), "->drop_prives TODO";
}


########################################################
sub open_logfile
{
    my($self)=@_;
    my $logfile = $self->{logfile};
    return unless $logfile;
    return if $self->{"logfile done"}++;
    open STDOUT, ">>$logfile" or die "Unable to write to $logfile: $!\n";
    open STDERR, ">&STDOUT"   or die "Unable to reopen STDERR: $!\n";
    STDERR->autoflush(1);
    STDOUT->autoflush(1);
    return 1;
}

########################################################
sub detach
{
    my($self)=@_;
    return if $self->{"detach done"}++;
    return unless $self->{detach};

    my $gen="grand-parent";

    DEBUG and warn "$$: Detaching from $gen";
    my $pid=fork;
    die "Unable to fork: $!\n" unless defined $pid;
    if(0==$pid) {                       # child
        $gen="parent";
        DEBUG and warn "$$: Detaching from $gen";
        $pid=fork;
        die "Unable to fork: $!\n" unless defined $pid;
        if(0==$pid) {                   # grand-child
            $gen="child";
            DEBUG and warn "$$: We are the $gen";
            POSIX::setsid() or
                warn "$$: Unable to setsid(): $! (continuing anyway)";
            if( $poe_kernel->can( 'has_forked' ) ) {
                $poe_kernel->has_forked;
            }
            return 1;
         }
    }
    DEBUG and warn "$$: I am the $gen, and now I exit.";
    ## we are parent or child.  Exit
    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
                                POE::Kernel::KR_RUN_CALLED;

    # This code is lifted from POE::Wheel::Run::_exit_child_any_way_we_can
    my $exitval = 0;

    # First make sure stdio are flushed.
    close STDIN  if defined fileno(STDIN); # Voodoo?
    close STDOUT if defined fileno(STDOUT);
    close STDERR if defined fileno(STDERR);

    # On Windows, subprocesses run in separate threads.  All the "fancy"
    # methods act on entire processes, so they also exit the parent.

    unless (POE::Kernel::RUNNING_IN_HELL) {
      # Try to avoid triggering END blocks and object destructors.
      eval { POSIX::_exit( $exitval ); };

      # TODO those methods will not exit with $exitval... what to do?
      eval { CORE::kill KILL => $$; };
      eval { exec("$^X -e 0"); };
    } else {
      eval { CORE::kill( KILL => $$ ); };

      # TODO Interestingly enough, the KILL is not enough to terminate this process.
      # However, it *is* enough to stop execution of END blocks/etc
      # So we will end up falling through to the exit( $exitval ) below
    }

    # Do what we must.
    exit( $exitval );
}

########################################################
sub create_session
{
    my($self)=@_;

    POE::Session->create(
            object_states => [
                $self=>[qw(
                        _start _stop status update_status
                        check_scoreboard
                        fork retry waste_time
                        babysit rogues shutdown
                        foreign_child
                        sig_CHLD sig_INT sig_TERM sig_HUP
                      )]
            ])->ID;
}

########################################################
sub is_prefork
{
    my($self)=@_;
    return 0 != ($self->{start_children}||0);
}

########################################################
sub is_fork
{
    my($self)=@_;
    return( 0 != ($self->{max_children}||0) and not $self->is_prefork);
}


########################################################
# Set default min and max spare processes for pre-forking
sub default_min_max
{
    my($self)=@_;
    if($self->{max_children}) {
        if($self->{max_spare}) {
            $self->{min_spare} = int($self->{max_spare} / 2) unless (defined $self->{min_spare});
        }
        else {
            $self->{min_spare} = int($self->{max_children} * 0.2) unless (defined $self->{min_spare});
            $self->{max_spare} = int($self->{max_children} * 0.8) unless (defined $self->{max_spare});
        }
        $self->{min_spare} = 1 unless (defined $self->{min_spare});
        $self->{max_spare} = 2 unless (defined $self->{max_spare});
        if( $self->{max_spare} <  $self->{min_spare} ) {
            confess "Max_spare can't be smaller then $self->{min_spare}; madness follows.";
        }
    }
    else {
        # We couldn't be here unless start_children is set
        $self->{min_spare} = $self->{start_children} unless (defined $self->{min_spare});
        $self->{max_spare} = 2 * $self->{min_spare} unless (defined $self->{max_spare});
        $self->{max_children} = $self->{start_children} + $self->{max_spare};
    }
    DEBUG and warn "$$: min_spare=$self->{min_spare} max_spare=$self->{max_spare} max_children=$self->{max_children}";
}

########################################################
sub _start
{
    my($self, $kernel)=@_[OBJECT, KERNEL];

    DEBUG and warn "$$: Alias for ".ref($self)." is $self->{alias}";
    $kernel->alias_set($self->{alias});
    $Daemon::alias=$self->{alias};

    $kernel->sig(shutdown => 'shutdown');
    $kernel->sig(TERM => 'sig_TERM');
    $kernel->sig(HUP  => 'sig_HUP');
    $kernel->sig(INT  => 'sig_INT');

    $self->inform_others( 'daemon_start' );

    ####
    if($self->is_prefork) {                 # pre-forking
        $self->default_min_max;
    }
    elsif($self->is_fork) {                 # forking
        $kernel->yield( 'check_scoreboard' );   # start this loop
    }
    else {
        $kernel->yield('waste_time');       # keep the daemon alive
        return;                             # and do nothing else
    }

    ####                                    # keep track of children
    $self->{children} = {};
    $self->{'failed forks'} = [];
    $self->{verbose}||=DEBUG;
    $self->{"max requests"}=$self->{requests}||1;
    $self->{'is a child'} = 0;              # change behavior in child
    $self->{scoreboard}=
            POE::Component::Daemon::Scoreboard->new($self->{max_children}+5);
    $self->{'pending forks'} = 0;

    ####
    if($self->is_prefork) {
        DEBUG and warn "$$: Pre-forking children";
        $self->{startup}=1;
        # fork the initial set of children
        $self->fork_off( $self->{start_children} );
    }
    ####
    if($self->{babysit}) {
        $self->{"proctable"}=eval {
            require Proc::ProcessTable;
            return new Proc::ProcessTable;
        };
        DEBUG and do {
            warn "$$: Unable to load Proc::ProcessTable: $@" if $@;
        };
        $kernel->yield('babysit');
    }
    ####
    $kernel->yield('waste_time');       # keep the daemon alive
    return;
}

########################################################
# This event keeps this POE kernel alive
sub waste_time
{
    my($self, $kernel)=@_[OBJECT, KERNEL];
    return if $self->{'is a child'};

    DEBUG and
        warn "$$: Still alive!";

    unless($self->{'been told we are parent'}) {
        $self->{'been told we are parent'}=1;
        $self->inform_others( 'daemon_parent' );
    }
    if($self->{'die'}) {
        DEBUG and warn "$$: Orderly shutdown";
    } else {
        $kernel->delay('waste_time', 600);  # TODO : configable
    }
    return;
}

########################################################
# Babysit the child processes
sub babysit
{
    my($self, $kernel)=@_[OBJECT, KERNEL];

    return if $self->{'die'} or             # don't scan if we are dieing
              $self->{'is a child'};        # or if we are a child

    my @children=keys %{$self->{children}};
    ($self->{verbose} or DEBUG) and
            warn "$$: Babysiting ", scalar(@children),
                            " children ", join(", ", sort @children);
    my %table;

    if($self->{proctable}) {
        my $table=$self->{proctable}->table;
        %table=map {($_->pid, $_)} @$table
    }

    my(%missing, $state, $time, %rogues, %ok);
    foreach my $pid (@children) {
        if($table{$pid}) {
            $state=$table{$pid}->state;

            if($state eq 'zombie') {
                my $t=waitpid($pid, POSIX::WNOHANG());
                if($t==$pid) {
                    # process was reaped, now fake a SIGCHLD
                    # DEBUG and
                        warn "$$: Faking a CHLD for $pid";
                    $kernel->yield('sig_CHLD', 'CHLD', $pid, $?, 1);
                    $ok{$pid}=1;
                } else {
                    $self->{verbose} and warn "$$: $pid is a $state and couldn't be reaped.";
                    $missing{$pid}=1;
                }
            }
            elsif($state eq 'run') {
                $time=eval{$table{$pid}->utime + $table{$pid}->stime};
                warn $@ if $@;
                # utime and stime are Linux-only :(

                if($time and $time > 600000) { # arbitrary limit of 10 minutes
                    $rogues{$pid}=$table{$pid};
                    # DEBUG and
                        warn "$$: $pid has gone rogue, time=$time ms";
                } else {
                    warn "$$: $pid time=$time ms";
                    $ok{$pid}=1;
                }

            } elsif($state eq 'sleep' or $state eq 'defunct') {
                $ok{$pid}=1;
                # do nothing
            } else {
                $self->{verbose} and warn "$$: $pid has unknown state '$state'";
                $ok{$pid}=1;
            }
        }
        elsif($self->{proctable}) {
            $self->{verbose} and warn "$$: $pid isn't in proctable!";
            $missing{$pid}=1;
        }
        else {                        # try another means.... :/
            if(-d "/proc" and not -d "/proc/$pid") {
                DEBUG and warn "$$: Unable to stat /proc/$pid!  Is the child missing";
                $missing{$pid}=1;
            }
            elsif(not $missing{$pid}) {
                $ok{$pid}=1;
            }
        }
    }

    # if a process is MIA, we fake a death, and spawn a new child (if needs be)
    foreach my $pid (keys %missing) {
        #$self->{verbose} and
            warn "$$: Faking a CHLD for $pid MIA";
        $kernel->yield('sig_CHLD', 'CHLD', $pid, 0, 1);
    }

    # we could do the same thing for rogue processes, but instead we
    # give them time to calm down

    if($self->{rogues}) {           # processes that are %ok are now removed
                                    # from the list of rogues
        delete @{$self->{rogues}}{keys %ok} if %ok;
    }

    if(%rogues) {
        # Start the rogues delay loop when going from no rogues to have
        # rogues
        # NB: yield causes the event to fire after this function exits
        $kernel->yield('rogues') if not $self->{rogues};

        $self->{rogues}||={};
        foreach my $pid (keys %rogues) {
            if($self->{rogues}{$pid}) {
                $self->{rogues}{$pid}{proc}=$rogues{$pid};
            } else {
                $self->{rogues}{$pid}={proc=>$rogues{$pid}, tries=>0};
            }
        }
    }

    $kernel->delay('babysit', $self->{babysit});
    return;
}

########################################################
# Deal with rogue child processes
sub rogues
{
    my($self, $kernel)=@_[OBJECT, KERNEL];

    return if $self->{'die'} or             # don't scan if we are dieing
              $self->{'is a child'};        # or if we are a child

    return unless $self->{rogues};          # make sure we have some real work
    eval {
        if(ref($self->{rogues}) ne 'HASH' or not keys %{$self->{rogues}}) {
            delete $self->{rogues};
            return;
        }

        my $signal;
        while(my($pid, $rogue)=each %{$self->{rogues}}) {
            $signal=0;
            if($rogue->{tries} < 1)    { $signal=SIGINT;  }
            elsif($rogue->{tries} < 2) { $signal=SIGTERM; }
            elsif($rogue->{tries} < 3) { $signal=SIGKILL; }

            if($signal) {
                DEBUG and warn "$$: Sending signal $signal to rogue $pid";
                unless($rogue->{proc}->kill($signal)) {
                    warn "$$: Error sending signal $signal to $pid: $!";
                    delete $self->{rogues}{$pid};
                }
            }
            else {
                # if SIGKILL didn't work, it's beyond hope!
                $kernel->yield('sig_CHLD', 'CHLD', $pid, 0, 1);
                delete $self->{rogues}{$pid};
                # $self->{verbose} and
                    warn "$$: Faking a CHLD for rogue $pid";
            }
            $rogue->{tries}++;
        }
        $kernel->delay('rogues', 2*$self->{babysit});
    };
    warn "$$: $@" if $@;
    return;
}

########################################################
# Accept POE's standard _stop event, and stop all the children, too.
# The 'children' hash is maintained in the 'fork' and 'sig_CHLD'
# handlers.  It's empty for children.
sub _stop
{
    my($self, $kernel)=@_[OBJECT, KERNEL];
    $Daemon::alias='';

    DEBUG and warn "$$: Server is stoping";
    # DEBUG_USR2 and check_kernel($kernel, $self->{'is a child'}, 1);
}

########################################################
# Someone wants us to exit... oblige
sub do_shutdown
{
    # print STDERR "$$: do_shutdown\n";
    $poe_kernel->call( $poe_kernel->get_active_session, 'shutdown' );
}
sub shutdown
{
    my($self, $kernel)=@_[OBJECT, KERNEL];

    $self->{verbose} and
        warn "$$: shutdown";
    if($self->{rogues}) {
        $kernel->delay('rogues');   # we no longer care about rogues
    }

    if($self->{children}) {         # tell children to go away
        foreach my $pid (keys %{$self->{children}}) {
            $self->{verbose} and warn "$$: TERM $pid";
            kill SIGTERM, $pid
                    or warn "$$: Unable to kill $pid: $!";
        }
    }
    if($self->{foreign_children}) { # tell foreign children to go away
        foreach my $pid (keys %{$self->{foreign_children}}) {
            kill SIGTERM, $pid
                    or warn "$$: Unable to kill $pid: $!";
        }
    }

    if(defined $self->{'my slot'}) {        # notice in the scoreboard
        # this means we are a child
        $self->{scoreboard}->write($self->{'my slot'}, 'e');
        delete $self->{'my slot'};
    }

    $kernel->alias_remove(delete $self->{alias}) if $self->{alias};
    $kernel->delay('waste_time');           # get it OVER with
    $kernel->delay('check_scoreboard');     # get it OVER with
    $self->{'die'}=1;                       # prevent race conditions
    $self->inform_others( 'daemon_shutdown' );

    # Remove signal handlers so that some versions of POE can shut down
    $kernel->sig( 'CHLD' );
    $kernel->sig( 'HUP'  );
    $kernel->sig( 'INT'  );
    $kernel->sig( 'TERM' );
    return;
}

########################################################
# The server has been requested to fork, so fork already.
sub fork
{
    my ($kernel, $self, $req) = @_[KERNEL, OBJECT, ARG0];

    # children should not honor this event
    # Note that the forked POE kernel might have these events in it already
    # This is unavoidable :-(
    if( $self->{'is a child'} ) {
        return;
    }
    return if not $self->{children} or $self->{'die'};

    ####
    DEBUG and warn "$$: pending forks=$self->{'pending forks'}";
    if( $self->{"pending forks"} ) {
        $self->{"pending forks"}--;
    }

    ####
    if( $self->{max_children} <= keys %{$self->{children}} ) {
        warn "$$: Maximum number of children reached!";
        warn "$$: max_children=$self->{max_children} currently=".(0+keys %{$self->{children}});

        # 2006/02 This is the most lamentable bit of my algorythm. By
        # throwing fork events around, I could end up with too many
        # children.  Either I drop requests on the floor (bad), or I save
        # them via fork_failed, which means the events could end up in other
        # children (less bad) or I just let them succeed and hope that
        # > {max_children} isn't all that horrendeous (least bad so far)
    }

    my $slot=$self->{scoreboard}->add('FORK');  # grap a slot in scoreboard

    # Failure!  We have too many children!  AAAGH!
    unless( defined $slot ) {
        warn "NO FREE SLOT!  You should increase max_children to avoid this.";
        return;
    }

    DEBUG and
        warn "$$: Forking a child";
    my $pid = fork();                   # try to fork
    unless (defined($pid)) {            # did the fork fail?
        $self->{scoreboard}->drop($slot);   # give slot back
        $self->fork_failed($!, "$!", $req);
        return;
    }

    if ($pid) {                         # successful fork; parent keeps track
        #print STDERR "$$: parent pid=$pid\n";
        $self->{children}->{$pid} = $slot;
        DEBUG and
            warn "$$: Parent server forked a new child.  children: (",
                    join(' ', sort keys %{$self->{children}}), ")";

        $kernel->sig_child( $pid => 'sig_CHLD');

        if( not $self->{"pending forks"} and $self->{startup} ) {
            # End if pre-forking startup time.
            $self->{startup}=0;
            $kernel->yield('check_scoreboard');
        }
    }
    else {                              # child becomes a child process
        $self->has_forked;
        $self->{scoreboard}->write( $slot, 'fork' );
        $self->become_child( $slot, $req );
    }
    return;
}

########################################################
# We failed to fork!
sub fork_failed
{
    my($self, $errnum, $errstr, $req)=@_;
    if (($errnum == EAGAIN) || ($errnum == ECHILD)) {
                                    # try again later, if a temporary error
        DEBUG and warn "$$: Recoverable forking problem";
        push @{$self->{'failed forks'}}, $req;
        $poe_kernel->delay('retry', 1);
    }
    else {                          # fail permanently, if fatal
        warn "$$: Can't fork: $errstr";
        $poe_kernel->yield('_stop');
    }
    return;
}

sub has_forked
{
    # This resets some kernel data that was preventing the child
    # process's kernel from becoming IDLE
    $poe_kernel->has_forked;
}

########################################################
# Turn ourselves into a child process
sub become_child
{
    my($self, $slot, $req)=@_;

    ( $self->{verbose} or DEBUG )
        and warn "$$: Created ", scalar localtime;

    ## Clean out stuff that the parent needs but not the children

    $self->{'is a child'}   = 1;        # don't allow fork
    $self->{'my slot'}      = $slot;
    delete $self->{'pending forks'};
    delete $self->{'failed forks'};

    $poe_kernel->sig('CHLD');
    $poe_kernel->sig('INT');
    # remove the wait for babysit
    $poe_kernel->delay('babysit') if $self->{'babysit'};
    # remove the wait for checking the scorebard
    $poe_kernel->delay('check_scoreboard') if $self->is_prefork or
                                              $self->is_fork;
    # remove these fields
    delete @{$self}{ qw(rogues proctable children) };

    # Tell everyone we are now a child
    $self->inform_others( 'daemon_child', $req );

    if($self->is_prefork) {
        ## AAAUGH!  Don't send daemon_accept here.
        ## wait for someone to update the status to 'wait' first!!!1eleven
        # warn "$$: Sending 1 daemon_accept\n";
        # $self->inform_others( 'daemon_accept' );
        $self->{requestN}=0;
    }
    elsif($self->is_fork) {
        $self->{scoreboard}->write( $slot, 'req' );
    }

    DEBUG and warn "$$: Child server has been forked";
    return;
}

########################################################
# Retry failed forks.  This is invoked (after a brief delay) if the
# 'fork' state encountered a temporary error.
sub retry
{
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    if($self->{'is a child'} or not $self->{children}) {
        warn "$$: We are a child, why are we forking?";
        return;
    }

    # Multiplex the delayed 'retry' event into enough 'fork' events to
    # make up for the temporary fork errors.
    DEBUG and warn "$$: We have $self->{'failed forks'} failed forks";
    $self->fork_off( $self->{'failed forks'} );
                                        # reset the failed forks counter
    $self->{'failed forks'} = [];
    return;
}



########################################################
# $poe_kernel->signal() simply places an event on the queue. This means that
# they get handled during the select loop, which is a bad thing for
# 'daemon_child' in a forking server.
# Note that it requires POE::API::Peek, which is currently broken for 1.300+
sub expedite_signal
{
    my( $self, $signal, @etc ) = @_;

    DEBUG and
        warn "$$: Expedite signal $signal";

    my $api = POE::API::Peek->new();
    my %watchers = $api->signal_watchers( $signal );

    while( my( $session, $event ) = each %watchers ) {
        DEBUG and
            warn "$$: Signal $signal is $session/$event";
        $poe_kernel->call( $session, $event, $poe_kernel, @etc );
    }
    return;
}

sub inform_others
{
    my( $self, $signal, @etc ) = @_;

    $self->{verbose} and
        warn "$$: Inform others about $signal";

    if( !$NO_PEEK and ($signal eq 'daemon_shutdown' or
            ($signal eq 'daemon_child') and $self->is_fork) ) {
        $self->expedite_signal( $signal, @etc );
    }
    else {
        $poe_kernel->signal($poe_kernel, $signal, @etc );
    }
}

########################################################
sub foreign_child
{
    my( $self, $pid ) = @_[ OBJECT, ARG0 ];

    $self->{foreign_children}{ $pid } = 1;
}


########################################################
# SIGCHLD causes this session to fork off a replacement for the lost child.
sub sig_CHLD
{
    my ($kernel, $self, $signal, $pid, $status, $fake) =
                @_[KERNEL, OBJECT, ARG0, ARG1, ARG2, ARG3];

    ( DEBUG or $self->{verbose} ) and
        warn "$$: SIGCHLD pid=$pid";

    ##########
    if($self->{foreign_children} and $self->{foreign_children}{$pid}) {
        DEBUG and warn "$$: Foreign child $pid exited.";
        delete $self->{foreign_children}{ $pid };
        return;
    }

    return if $self->{"is a child"};

#    ( DEBUG or $self->{verbose} ) and
        warn "$$: SIGCHLD pid=$pid";

    ##########
    if($self->{children}) {
                                # if it was one of ours
        my $slot=delete $self->{children}->{$pid};
        if (defined $slot) {
            DEBUG and warn "$$: Parent caught SIGCHLD for $pid.  children: (",
                                join(' ', sort keys %{$self->{children}}),
                                ")";
            $self->{verbose} and warn "$$: Child $pid ",
                        ($fake?'is gone':'exited normaly');
            $self->{scoreboard}->drop($slot);

            # Don't do anything else; wait for regular check_scoreboard to
            # do it's thing.  Otherwise we have to check min_spare/max_spare
            # and stuff like that.
        }
        elsif($fake) {
            warn "$$: Needless fake CHLD for $pid.";
        }
        else {
            warn "$$: CHLD for $pid child of someone else.";
            warn Dumper $self;
        }
    }

                                        # don't handle terminal signals
    return;
}

########################################################
# Terminal signals aren't handled, so the session will stop on SIGINT.
# The shutdown event handler takes care of cleanup.
sub sig_INT
{
    my ($kernel, $self, $signal, $pid, $status) =
                @_[KERNEL, OBJECT, ARG0, ARG1, ARG2];

    ( DEBUG or $self->{verbose} ) and
        warn "$$: SIGINT";
    $self->do_shutdown;
    $kernel->sig_handled();         # INT is a terminal
    return;
}

########################################################
# daemontool's svc -d sends a TERM to the parent.
# Propagate it down to the children
# The shutdown event handler takes care of cleanup.
#
# Terminal signals aren't handled, so the session will stop on SIGINT.
sub sig_TERM
{
    my ($kernel, $self, $signal, $pid, $status) =
                @_[KERNEL, OBJECT, ARG0, ARG1, ARG2];

    ( DEBUG or $self->{verbose} ) and
        warn "$$: SIGTERM";
    $self->do_shutdown;
    $kernel->sig_handled();     # TERM is a terminal
    return;
}

########################################################
# Close the log file and reopen
sub sig_HUP
{
    my ($kernel, $self, $signal, $pid, $status) =
                @_[KERNEL, OBJECT, ARG0, ARG1, ARG2];

    ( DEBUG or $self->{verbose} ) and
        warn "$$: SIGHUP (logfile=$self->{logfile})";
    $kernel->sig_handled();

    $self->inform_others( 'daemon_HUP' );

    return unless $self->{logfile};

    DEBUG and warn "Reopening $self->{logfile}";

    $self->{"logfile done"}--;
    $self->open_logfile;
    return;
}




########################################################
# Start the process of creating a number of children
sub fork_off
{
    my($self, $n)=@_;
    if(ref $n) {
        DEBUG and
            warn "$$: Fork off ", (0+@$n), " children";
        if( 1==@$n and $self->is_fork) {

            # This fork_off was probably caused by client code doing
            # update_status( 'req' ) for a new request.  That being the case,
            # we want to prevent the select loop from running.

            $poe_kernel->call( $poe_kernel->get_active_session,
                                'fork', @$n );
        } else {
            foreach my $req (@$n) {
                $self->{"pending forks"}++;
                $poe_kernel->yield('fork', $req);
            }
        }
         return;
    }

    DEBUG and
        warn "$$: Fork off $n children";
    for(my $q1=0; $q1 < $n; $q1++) {
        $self->{"pending forks"}++;
        $poe_kernel->yield('fork');
    }
    return;
}

########################################################
# Make sure we have min_spare waiting processes
# But no more than max_spare
sub check_scoreboard
{
    my($self)=@_;
    DEBUG and warn "$$: check_scoreboard";

    if($self->{'is a child'}) {
        DEBUG and warn "$$: I am a child!  I refuse to check the scoreboard!";
        return;
    }
    # DEBUG_SC and warn "$$: Checking scoreboard";

    my $slots=$self->{scoreboard}->read_all;
    my @waiting;                # PIDs of waiting children

    while(my($pid, $slot)=each %{$self->{children}}) {
        DEBUG and warn "$$: child at slot $slot ($pid: $slots->[$slot])";
        if($slots->[$slot] eq 'w' or
            $slots->[$slot] eq 'f') {      # waiting for req
            warn "$pid is still forking" if $slots->[$slot] eq 'f';
            push @waiting, $pid;
        }
        else {
        }

    }


    if( $self->is_prefork ) {
        my $waiting=@waiting;
        DEBUG and warn "$$: waiting=$waiting";
        if($waiting < $self->{min_spare}) {
            my $n=$self->{min_spare} - $waiting;
            DEBUG_SC and
                warn "$$: Spawning $n spares";
            $self->fork_off($n);
        }
        if($waiting > $self->{max_spare}) {
            my $n=$waiting - $self->{max_spare};
            DEBUG_SC and warn "$$: Killing $n spares";
            foreach my $pid ( @waiting[0..($n-1)] ) {
                kill SIGINT, $pid or warn "$$: killing $pid: $!";
            }
        }
    }
    elsif( $self->is_fork and
                    $self->{max_children} <= keys %{$self->{children}} ) {
        unless( $self->{paused} ) {
            $self->inform_others( 'daemon_pause' );
            $self->{paused} = 1;
        }
    }
    elsif( $self->{paused} ) {
        $self->inform_others( 'daemon_accept' );
        delete $self->{paused};
    }

    # This also clears any pending delay to us
    $poe_kernel->delay('check_scoreboard', 1);
}

########################################################
# User code wants to update the status
sub update_status
{
    my($self, $status, $parm)=@_[OBJECT, ARG0, ARG1];
    DEBUG and warn "$$: Update status status=$status parm=(",($parm||''),")";

    if($self->is_prefork) {
        return $self->update_status_prefork($status, $parm, @_[CALLER_FILE, CALLER_LINE]);
    }

    elsif($self->is_fork) {
        if($self->{'is a child'}) {
            return $self->update_status_fork_child($status, $parm);
        }
        else {
            return $self->update_status_fork_parent($status, $parm);
        }
    }
    warn "$$: Non-forking server doesn't need to update status";
    return;
}

########################################################
# User code in a preforked child wants to update the status
sub update_status_prefork
{
    my($self, $status, $parm, $file, $line)=@_;
    return if $self->{'die'};

    unless($self->{'is a child'}) {
        warn "$$: Only child processes should update their status ($status)";
        return;
    }

    my $slot=$self->{'my slot'};
    unless( defined $slot ) {
        die "$$: Missing slot.  Update sent from $file line $line.\n"
    }
    my $current_status=$self->{scoreboard}->read($slot)||'unknown';
    DEBUG and
        warn "$$: current_status=$current_status -> status=$status";

    if($status eq 'wait' or $status eq 'done') {
        DEBUG and warn "$$: Moving to status=wait";
        $self->{scoreboard}->write($slot, 'wait');
        if($self->{requestN} >= $self->{'max requests'}) {
            DEBUG and
                warn "$$: Handled $self->{requestN} requests, shutting down status=$status";
            $self->do_shutdown;
        }
        elsif($current_status ne 'w') {
            # use Carp qw( cluck );
            # cluck "$$: daemon_accept";
            $self->inform_others( 'daemon_accept' );
        }
        else {
            warn "Why are we moving from $current_status to $status.".
                 "  Update sent from $file line $line.\n";
        }
        return;
    }

    if($status eq 'long') {
        DEBUG and warn "$$: Long request $self->{requestN}";
        if($current_status eq 'r') {
            $self->{scoreboard}->write($slot, 'long');
            return;
        }
        # allow to fall through if we didn't get a 'req' previous
        # for now this isn't important, but it might be later
    }

    if($status eq 'req' or $status eq 'long') {
        if( $current_status ne 'r' and $current_status ne 'l' ) {
            $self->{requestN}++;
            DEBUG and warn "$$: Handling request $self->{requestN}";
        }
        $self->{scoreboard}->write($slot, $status);
        return;
    }
    warn "$$: Don't know what do for '$status'! Maybe you meant 'long', 'wait' or 'done' or 'req'?";
}


########################################################
# User code in a forked child wants to update the status
sub update_status_fork_child
{
    my($self, $status, $parm)=@_;
    return if $self->{'die'};

    my $slot=$self->{'my slot'};
    unless( defined $slot ) {
        warn "$$: NO SLOT for status=$status";
        return;
    }

    my $current_status=$self->{scoreboard}->read($slot);

    if($status eq 'wait' or $status eq 'done') {
        $self->{scoreboard}->write($slot, 'wait');
        $self->do_shutdown;
        return;
    }

    if($status eq 'long') {
        $self->{scoreboard}->write($slot, $status);
        return;
    }

    warn "$$: Don't know what to do for '$status'! Maybe you meant 'long', 'wait' or 'done'?";
}

########################################################
# User code in the parent wants to update the status
sub update_status_fork_parent
{
    my($self, $status, $parm)=@_;

    if($status eq 'req') {
        DEBUG and warn "$$: update_status_fork_parent status = $status $parm";
        $self->fork_off( [$parm] );
        return;
    }

    warn "$$: Don't know what to do for '$status'! Maybe you meant 'req'?";
}



########################################################
sub status
{
    my($self)=@_;
    my @ret=ref($self);

    my $q1='the parent';
    $q1='a child' if $self->{'is a child'};
    if($self->is_prefork) {
        push @ret, "Pre-forking server, we are $q1";
    }
    elsif($self->is_fork) {
        push @ret, "Forking server, we are $q1";
    }
    else {
        push @ret, "Daemon server";
    }

    if($self->{children}) {
        my $kids=$self->{children};
        push @ret, (0+keys %$kids), " children: ", sort join ' ', keys %$kids;

        my $doing=$self->{scoreboard}->read_all;
        foreach my $pid (sort keys %$kids) {
            push @ret, "        $pid: $doing->[$kids->{$pid}]";
        }
    }
    return join("\n    ", @ret)."\n".$self->{scoreboard}->status;
}

##########################################################################
package Daemon;

use strict;
use POE;

use Scalar::Util qw( blessed );

use vars qw($alias);

sub update_status
{
    my($package, $status, $parm)=@_;

    # Must be a call() to prevent the select-loop running
    $poe_kernel->call( $alias => 'update_status', $status, $parm );
}

sub foreign_child
{
    my($package, $pid)=@_;
    $poe_kernel->call( $alias => 'foreign_child', $pid );
}

sub shutdown
{
    $poe_kernel->call( $alias => 'shutdown' );
}

sub status
{
    return $poe_kernel->call( $alias => 'status' );
}

############################################################
sub peek
{
    my($package, $verbose)=@_;

    return $POE::Component::Daemon::NO_PEEK if $POE::Component::Daemon::NO_PEEK;
    my $self;
    my $api=POE::API::Peek->new();
    my @queue = $api->event_queue_dump();

    my $ret = "Event Queue ($POE::Component::Daemon::VERSION):\n";

    my $events = {};

    foreach my $item (@queue) {
        $ret .= "\t* ID: ". $item->{ID}." - Index: ".$item->{index}."\n";
        $ret .= "\t\tPriority: ".$item->{priority}."\n";
        $ret .= "\t\tEvent: ".$item->{event}."\n";

        if($verbose) {
            $events->{ $item->{source}->ID }{source} ++;
            $ret .= "\t\tSource: ".
                    $api->session_id_loggable($item->{source}).
                    "\n";
            $events->{ $item->{destination}->ID }{destination} ++;
            $ret .= "\t\tDestination: ".
                    $api->session_id_loggable($item->{destination}).
                    "\n";
            $ret .= "\t\tType: ".$item->{type}."\n";
            $ret .= "\n";
        }
    }
    $ret .="\tEMPTY\n" unless @queue;

    if($verbose) {
        $ret.="Sessions: \n" if $api->session_count;
        foreach my $session ( sort { $a->ID cmp $b->ID } $api->session_list) {
            my $ref=0;
            $ret.="\tSession ".$api->session_id_loggable($session)." ($session)";

            my $refcount=$api->get_session_refcount($session);
            $ret.="\n\t\tref count: $refcount\n";

            my $q1=$api->get_session_extref_count($session);
            $ref += $q1;
            $ret.="\t\textref count: $q1 (Stay alive)\n" if $q1;

            $q1=$api->session_handle_count($session);
            $ref += $q1;
            $ret.="\t\thandle count: $q1 (Stay alive)\n" if $q1;

            my @aliases = $api->session_alias_list($session);
            $ref += @aliases;
            $q1=join ',', @aliases;
            $ret.="\t\tAliases: $q1\n" if $q1;

            my @children = $api->get_session_children($session);
            if(@children) {
                $ref += @children;
                $q1 = join ',', map {$api->session_id_loggable($_)} @children;
                $ret.="\t\tChildren: $q1\n";
            }

            $q1 = $events->{ $session->ID }{source};
            if( $q1 ) {
                $ret.="\t\tEvent source count: $q1 (Stay alive)\n";
                $ref += $q1;
            }

            $q1 = $events->{ $session->ID }{destination};
            if( $q1 ) {
                $ret.="\t\tEvent destination count: $q1 (Stay alive)\n";
                $ref += $q1;
            }

            if($refcount != $ref) {
                $ret.="\t\tStay alive: refcount=$refcount counted=$ref\n";
            }
            if( $alias and grep $alias, @aliases ) {
                my $state = $session->[ POE::Session::SE_STATES ]{_start};
                if( $state and 'ARRAY' eq ref $state and blessed $state->[0] ) {
                    $self = $state->[0];
                }
            }
        }
    }

    $ret.="\n";

    if( blessed $self ) {
        if( $self->{'my slot'} ) {
            my $status = $self->{scoreboard}->read($self->{'my slot'});
            $ret .= "Scoreboard slot: $self->{'my slot'}\n";
            $ret .= "Scoreboard: $status\n";
        }
        $ret .= $self->{scoreboard}->status;
        $ret.="\n\n";
    }

    $poe_kernel->sig_handled;

    unless( defined wantarray ) {
        warn "$$: $ret";
        return;
    }
    return $ret;
}

*__peek = \&peek;




1;
__END__

=head1 NAME

POE::Component::Daemon - Handles all the housework for a daemon.

=head1 SYNOPSIS

    use POE::Component::Daemon;

    POE::Component::Daemon->spawn(detach=>1, max_children=>3);


    # Create a session that uses SocketFactory
    POE::Session->create(
    inline_states=>{

        _start=>sub {
            # catch this message from Daemon session
            $kernel->sig('daemon_child'=>'request');

            # create a POE::Wheel::SocketFactory or whatever
            # .....
        },

        # socketfactory got a connection handle it here
        accept=>sub {
            # tell Daemon session about this
            Daemon->update_status('req', $info);
        },

        ###############
        # we are now the child process (via the sig() in _start
        request=>sub {
            my($heap, $info)=@_[HEAP, ARG1];
            # $info was passed here from accept accept

            # create POE::Wheel::ReadWrite
            ....
            # tell Daemon session that this request will take a long time
            Daemon->update_status('long');
        },

        ###############
        # The request is finished
        finished=>sub {
            return unless $heap->{done};
            # tell Deamon session that this request is done
            $poe_kernel->post(Daemon=>'update_status', 'done');
        },
    });

=head1 DESCRIPTION

Dealing with all the little details of a forking daemon can be annoying and
hard.  POE::Component::Daemon encapsulates all the details into one place
and (hopefully) gets them right.

POE::Component::Daemon will deal with all the annoying details of creating
and maintaining daemon processes.  It can detach from the console, handle
pre-forking pools or post-forking (ie, fork on each request). It will also
redirect STDERR to a log file if asked.

POE::Component::Daemon also babysits child processes, handling their
C<CHLD>.  POE::Component::Daemon can also makes sure requests don't take
to long.  If they do, it will try to get rid of them.  See L</BABYSITING>
below.

POE::Component::Daemon does not handle listening on sockets.  That is up to
your code.

Like all of POE, POE::Component::Daemon works cooperatively.  It is up your
code to tell POE::Component::Daemon when it is time to fork, block incoming
requests when approriate and so on.

Sub-processes are maintained with the help of a scoreboard.  In some
situations, your code will have to update it's status in scoreboard with the
L</update_status> method.



=head2 POST-FORKING

Post-forking is the model that most examples and tutorials use.  The daemon
listens on a socket (or other mechanism) for new requests.  When a new
request comes in, a child process is forked off to handle that request and
the parent process continues to listen for new requests.

If you are using a post-forking model, your code must inform
POE::Component::Daemon about a new request.  POE::Component::Daemon will
then handle all the details of forking, and then broadcast a daemon_child
signal, which is your cue that you can now handle the request.

This means the following steps are done.

    Create SocketFactory wheel
    Create POE::Component::Daemon
    Receive SocketFactory's SuccessEvent
    Tell POE::Component::Daemon we are in a request (L</update_status>)
    POE::Component::Daemon forks
    POE::Component::Daemon sends daemon_child signal
    Receive daemon_child signal, create ReadWrite wheel
    Close SocketFactory wheel
    Talk with remote process
    When done, close ReadWrite wheel
    Tell POE::Component::Daemon we are no longer in a request
    POE::Component::Daemon will then shutdown this child process (signal
    daemon_shutdown).

Additionnaly, when POE::Component::Daemon detects that there are nearly too
many child processes, it will send a L</daemon_pause> signal.  You should
call L<POE::Wheel::SocketFactory/accept_pause>.  When the number of
child processes drops back down, POE::Component::Daemon will then send a
C<daemon_accept> signal.  You should then call
L<POE::Wheel::SocketFactory/accept_resume>.

The graph in F<forking-flow.png> might (or might not) help you understand
the above.



=head2 PRE-FORKING

The pre-forking model creates a pool of child processes before accepting
requests.  This is done so that each request doesn't incure the overhead of
forking before it can be processed.  It also allows a child process to
handle more then one request.  This is the model used by Apache.

When pre-forking, you create your SocketFactory and immediately pause it
with L<POE::Wheel::SocketFactory/accept_pause>.  Then spawn a
L<POE::Component::Daemon>. and allow the kernel to run.
L<POE::Component::Daemon> will fork off the desired initial number of
sub-processes (C<start_children>).  The child processes will be told they
are children with a L</daemon_child> signal.  Your code then does what it
needs and updates the status to 'wait' (L</update_status>).  When
POE::Component::Daemon sees this, it fires off a L</daemon_accept> signal.
Your code would then unpause the socket, with L<POE::Wheel::SocketFactory/accept_resume>.

When you receive a new connection, the status to 'req' or 'long' (if it's a
long running request) and handle the request.  When done, update the status
to 'done' (or 'wait').  POE::Component::Daemon sees this, and will either send another
L</daemon_accept> signal to say it's time to start again or shutdown the
daemon if this child has handled enough requests.

Note that when you receive a new request, you should pause your
SocketFactory or you could receive more than one request at the same time
AND ALL SORTS OF HIGGLY-PIGGLE WILL BE UNLEASHED on your code.


In list form, that gives us:

    Spawn POE::Component::Daemon
    Spawn your session
    Create SocketFactory wheel, and pause it
    Getting a daemon_child signal means we are now a child process.
    Update status to 'wait'
    Get a daemon_accept signal
    Resume the SocketFactory wheel
    Receive SocketFactory's SuccessEvent
    Close the SocketFactory
    Update status to 'req'
    Create a ReadWrite wheel
    Talk with remote process
    When done, close the ReadWrite wheel
    Update status to 'done'
    Wait for daemon_accept or daemon_shutdown signal

The graph in F<preforking-flow.png> might (or might not) help you understand
the above.


=head1 NON-FORKING

It is of course possible to use this code in a non-forking server.  While
most functionnality of L<POE::Component::Daemon> will be useless, methods
like L</drop_privs>, L</detach> and L</peek> are useful.


=head1 BABYSITING

Babysiting is the action of periodically monitoring all child processes to
make sure none of them do anything bad.  For values of 'bad' limited to
going rogue (using too much CPU) or disapearing without a trace.  Rogue
processes are killed after 10 minutes.

Babysiting is activated with the C<babysit> parameter to L</spawn>.

Babysiting doesn't have a test case and is probably badly implemented.
Patches welcome.

=head1 METHODS

=head2 spawn

    POE::Component::Daemon->spawn( %params );

Where C<%params> may contain:

=over 4

=item alias

POE session alias for POE::Component::Daemon.  Defaults to 'Daemon'.  If you change
it, other code that depends on it might be confused.

=item detach

If true, POE::Component::Daemon will detach from the current process tree.  It does
this by forking twice and the grand-child then calls L<POSIX/setsid>.
Parent and grand-parent summarily exit.

Default is to not detach.

=item logfile

Name of the log file.  STDERR and STDOUT are redirected to this file.  You
need to set logfile if you want detach from the current terminal.

The logfile will be closed and reopened on a C<HUP> signal.

=item verbose

Turn on verbose messages.  If set, babysiting and process creation will
output some details to STDERR.


=item max_children

Maximum number of child processes that POE::Component::Daemon may create.

If set, but not C<start_children>, then POE::Component::Daemon acts as a post-forking
daemon.  Note that it is unfortunately possible for POE::Component::Daemon to create
more then C<max_children> post-forking processes but instances of this
should be rare.

In pre-forking mode, defaults to start_children + max_spare.

=item start_children

If set, then POE::Component::Daemon acts as a pre-forking daemon.  At startup,
POE::Component::Daemon will fork off C<start_children> child processes.

=item max_spare
=item min_spare

Used by pre-forking server to decide when to create more child processes.
If there are fewer than min_spare, it creates a new spare.  If there are
more than max_spare, some of the spares killed off with TERM.

C<max_spare> defaults to 80% of max_children.
C<min_spare> defaults to 20% of max_children.


=item requests

The number of requests each child process is allowed to handle before it is
killed off.  Limiting the number of requests prevents child processes from
consuming too much memory or other resource.

=item babysit

Time, in seconds, between checks for rogue processes.  See L</BABYSITING>
above.


=back

=head2 shutdown

    Daemon->shutdown;
    $poe_kernel->post( Daemon=>'shutdown' );
    $poe_kernel->signal( $poe_kernel=>'shutdown' );

Tell POE::Component::Daemon to shutdown.  POE::Component::Daemon responds by
cleaning up all traces in the kernel and broadcasting the
L</daemon_shutdown> signal.  In the parent process, it sends a C<TERM>
signal to all child processes.



=head2 update_status

    Daemon->update_status( $new_status, $data )
    $poe_kernel->post( Daemon=>'update_status', $new_status, $data );

Tell POE::Component::Daemon your new status.  C<$new_status> is one of the scoreboards
states, as discussed below.  C<$data> is useful information for a
post-forking server moving into the 'req' state.  See below.


=head2 status

    Daemon->status()

Returns a string containing human readable information about the status of
the daemon, including the current state of the scoreboard.


=head2 foreign_child

    Daemon->foreign_child( $pid );

Allows you to report a child process that you might have spawned with
POE::Component::Daemon.  This obviates the need for you to have a CHLD
handler.  They will receive a TERM when current process exists.



=head2 peek

    Daemon->peek( $verbose );

Outputs the internal status of the POE::Kernel, with special attention paid
to the reasons why a kernel won't exit.

If C<$verbose> is false, only returns the event queue.  If C<$verbose> is
set, details of each session are also output.

In void context, outputs the status to STDERR.  Otherwise outputs a big,
human-readable string.

One helluva useful feature is to tie USR2 to the verbose output.

    $poe_kernel->state( USR2 => sub { Daemon->peek( 1 ) } );
    $poe_kernel->sig( USR2 => 'USR2' );

Now, instead of cursing the $GODS because your kernel doesn't exit when you
think it should, you simply type the following in another window.

    kill -USR2 I<pid>




=head1 SCOREBOARD

POE::Component::Daemon uses a scoreboard to keep track of child processes.  In a few
situations, you must update the scoreboard to tell POE::Component::Daemon when certain
events occur.  You do this with L</update_status>

    Daemon->update_status( 'req', { handle=>$handle } );
    $poe_kernel->call( Daemon=>'update_status', 'long' );

To find out when and why you should set your status, please read
the L</PRE-FORKING> and L</POST-FORKING> sections above.


=over 4

=item r (req)

Process is handling a request.  In a post-forking server, any extra data is
sent back via daemon_child.

=item l (long)

Process is handling a long request.  Differentiating between normal and long
requests can help the babysitter detect rogue processes.

In a post-forking server, any extra data is sent back via daemon_child

=item w (wait)

Process is waiting for next request.



=item ' '

Slot is empty.

=item e (exit)

Process is exiting.

=item F (FORK)

Process is forking, but we are still in the parent

=item f (fork)

Process is forking, we are in the child.

=item .

Process is waiting for first request.

=back




=head1 SIGNALS

POE::Component::Daemon uses signals to communicate with other sessions.  If you are
interested in a given signal, simply register a handler with the kernel.

    $poe_kernel->sig( $some_signal => $event );

The following signals are defined:

=head2 daemon_start

Posted from POE::Component::Daemon's _start event.


=head2 daemon_parent

The current process is the parent.  This is sent by a pre-forking daemon
when all the initial children have been forked.

=head2 daemon_child

The current process is a child.

This is sent by a pre-forking daemon just after forking a new process.  You
must then update the status to 'wait'.

In post-forking daemon, this signal means that you may now handle the new
request.  ARG1 is the data you passed to update_status( 'req' ).

=head2 daemon_accept

The current process is ready to accept new requests.

This is sent by a pre-forking daemon when the status is updated to 'wait'.

In post-forking daemon, this signal means that the number of child processes
has fallen below the maximum and you may resume accepting new requests.
Generally you do this by calling L<POE::Wheel::SocketFactory/accept_resume>.


=head2 daemon_pause

There are too many child processes.  Do not accept any more requests.
Generally you do this by calling L<POE::Wheel::SocketFactory/accept_pause>.


=head2 daemon_shutdown

Time to go to bed!  Sent by POE::Component::Daemon when it thinks it's time to
shutdown.  This might be because of code called Daemon->shutdown or because
of TERM or INT signals.  Additionnaly, in a pre-forking server a shutdown is
called when a child process has handled a certain number of requests.


=head2 daemon_HUP

We received a HUP signal.  Any log files should be closed then reopenned.

=head1 BUGS

Tested on Linux and FreeBSD.

Reports for Mac OS, and other BSDs would be appreciated.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Daemon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Daemon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Daemon>

=item *  METACPAN

L<https://metacpan.org/module/POE::Component::Daemon/>

=item * GITHUB

L<https://github.com/hashbangperl/PoCoDaemon>

=back

Doesn't support Windows.

=head1 SEE ALSO

L<POE>

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -AT- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2011 by Philip Gwyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
