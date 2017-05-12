package POE::Component::IKC::Server;

############################################################
# $Id: Server.pm 1247 2014-07-07 09:06:34Z fil $
# Based on refserver.perl and preforkedserver.perl
# Contributed by Artur Bergman <artur@vogon-solutions.com>
# Revised for 0.06 by Rocco Caputo <troc@netrus.net>
# Turned into a module by Philp Gwyn <fil@pied.nu>
#
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.

use strict;
use Socket;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
use POE qw(Wheel::ListenAccept Wheel::SocketFactory);
use POE::Component::IKC::Channel;
use POE::Component::IKC::Responder;
use POE::Component::IKC::Util;
use POSIX qw(:errno_h);
use POSIX qw(ECHILD EAGAIN WNOHANG);


require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_server);
$VERSION = '0.2402';

sub DEBUG { 0 }
sub DEBUG_USR2 { 1 }
BEGIN {
    # http://support.microsoft.com/support/kb/articles/Q150/5/37.asp
    eval '*WSAEAFNOSUPPORT = sub { 10047 };';
    if( $^O eq 'MSWin32' and not eval "EADDRINUSE" ) {
        eval '*EADDRINUSE  = sub { 10048 };';
    }
}


###############################################################################
#----------------------------------------------------
# This is just a convenient way to create servers.  To be useful in
# multi-server situations, it probably should accept a bind address
# and port.
sub spawn
{
    my($package, %params)=@_;
    $params{package} ||= $package;

    unless($params{unix}) {
        $params{ip}||='0.0.0.0';            # INET_ANY
        $params{port} = 603                 # POE! (almost :)
                    unless defined $params{port};
    }
    $params{protocol} ||= 'IKC0';

    # Make sure one is available
    POE::Component::IKC::Responder->spawn();
    my $session = POE::Session->create(
                    package_states => [ 
                        $params{package} =>
                        [qw(
                            _start _stop error _child
                            accept fork retry waste_time
                            babysit rogues shutdown
                            sig_CHLD sig_INT sig_USR2 sig_USR1 sig_TERM
                        )],
                    ],
                    args=>[\%params],
                  );
    my $heap = $session->get_heap;
    return $heap->{wheel_port};
}

sub create_ikc_server
{
    my( %params )=@_;
    $params{package} ||= __PACKAGE__;
    carp "create_ikc_server is DEPRECATED.  Please use $params{package}->spawn instead";
    return $params{package}->spawn( %params );
}

#----------------------------------------------------
sub _select_define
{
    my($heap, $on)=@_;
    return unless $heap->{wheel};
    $on||=0;

    DEBUG and 
        warn "_select_define  (on=$on)";

    if($on) {
        $heap->{wheel}->resume_accept
    }
    else {
        $heap->{wheel}->pause_accept
    }
    return;
}

#----------------------------------------------------
# Drop the wheel
sub _delete_wheel
{
    my( $heap ) = @_;
    return unless $heap->{wheel};
    my $w = delete $heap->{wheel};
    $w->DESTROY;
    return;
}

#----------------------------------------------------
#
sub _concurrency_up
{
    my( $heap ) = @_;
    $heap->{concur_connections}++;
    DEBUG and 
        warn "$$: $heap->{concur_connections} concurrent connections (max $heap->{concurrency})";
    return unless $heap->{concurrency} > 0;
    if( $heap->{concur_connections} >= $heap->{concurrency} ) {
        DEBUG and 
            warn "$$: Blocking more concurrency";
        $heap->{blocked} = 1;
        _select_define( $heap, 0 );
    }
}


sub _concurrency_down
{
    my( $heap ) = @_;
    $heap->{concur_connections}--;
    DEBUG and 
        warn "$$: $heap->{concur_connections} concurrent connections";
    return unless $heap->{concurrency} > 0;
    if( $heap->{concur_connections} < $heap->{concurrency} 
        and delete $heap->{blocked} ) {
        DEBUG and 
            warn "$$: Unblocking concurrency";
        _select_define( $heap, 1 );
    }
}

#----------------------------------------------------
# Delete all delays
sub _delete_delays
{
    $poe_kernel->delay('rogues');
    $poe_kernel->delay('waste_time');
    $poe_kernel->delay('babysit');
    $poe_kernel->delay( 'retry' );

    return;
}


#----------------------------------------------------
# Accept POE's standard _start event, and set up the listening socket
# factory.

sub _start
{
    my($heap, $params, $kernel) = @_[HEAP, ARG0, KERNEL];

    my $ret;

    # This shouldn't be necessary
    POE::Component::IKC::Responder->spawn;

    # monitor for shutdown events.
    # this is the best way to get IKC::Responder to tell us about the
    # shutdown
    $kernel->post(IKC=>'monitor', '*', {shutdown=>'shutdown'});

    my $alias='unknown';
    my %wheel_p=(
        Reuse          => 'yes',        # and allow immediate reuse of the port
        SuccessEvent   => 'accept',     # generating this event on connection
        FailureEvent   => 'error'       # generating this event on error
    );
    if($params->{unix}) {
        $alias="unix:$params->{unix}";
        $wheel_p{SocketDomain}=AF_UNIX;
        $wheel_p{BindAddress}=$params->{unix};
        $heap->{unix}=$params->{unix};
        unlink $heap->{unix};           # blindly do this ?
    }
    else {
        $alias="$params->{ip}:$params->{port}";
        $wheel_p{BindPort} = $params->{port};
        $wheel_p{BindAddress}= $params->{ip};
    }
    DEBUG && warn "$$: Server starting $alias.\n";


    $heap->{name}=$params->{name};
    $heap->{kernel_aliases}=$params->{aliases};
    $heap->{concurrency}=$params->{concurrency} || 0;
    $heap->{protocol}=$params->{protocol};
    $heap->{on_error}=$params->{on_error} if $params->{on_error};
                                        # create a socket factory
    $heap->{wheel} = new POE::Wheel::SocketFactory (%wheel_p);
    if( $heap->{wheel} and not $params->{unix} and not $params->{port} ) {
        $heap->{wheel_port} = 
                $ret = ( sockaddr_in( $heap->{wheel}->getsockname() ) )[0];
        $alias="$params->{ip}:$ret";
        DEBUG && 
                warn "$$: Server listening on $alias.\n";
    }
    $heap->{wheel_address}=$alias;

    $heap->{connections} = 0;

    # +GC
    $kernel->alias_set("IKC Server $alias");

    # set up local names for kernel
    my @names=($heap->{name});
    if($heap->{kernel_aliases}) {
        if(ref $heap->{kernel_aliases}) {
            push @names, @{$heap->{kernel_aliases}};
        } else {
            push @names, $heap->{kernel_aliases};
        }
    }

    $kernel->post(IKC=>'register_local', \@names);

    # pre-load the default serialisers
    foreach my $ft ( qw(Storable FreezeThaw POE::Component::IKC::Freezer) ) {
        eval {  local $SIG{__WARN__} = sub {1}; 
                local $SIG{__DIE__} = 'DEFAULT';
                POE::Filter::Reference->new( $ft );
             };
        warn "$ft: $@" if DEBUG and $@;
    }

    return $ret unless $params->{processes};

    # Delete the SocketFactory's read select in the parent
    # We don't ever want the parent to accept a connection
    # Children put the state back in place after the fork
    _select_define($heap, 0);

    $kernel->sig(CHLD => 'sig_CHLD');
    $kernel->sig(TERM => 'sig_TERM');
    $kernel->sig(INT  => 'sig_INT');
    DEBUG_USR2 and $kernel->sig('USR2', 'sig_USR2');
    DEBUG_USR2 and $kernel->sig('USR1', 'sig_USR1');

                                        # keep track of children
    $heap->{children} = {};
    $heap->{'failed forks'} = 0;
    $heap->{verbose}=$params->{verbose}||0;
    $heap->{"max connections"}=$params->{connections}||1;

    $heap->{'is a child'} = 0;          # change behavior for children
    my $children=0;
    foreach (2..$params->{processes}) { # fork the initial set of children
        $kernel->yield('fork', ($_ == $params->{processes}));
        $children++;
    }

    $kernel->yield('waste_time', 60) unless $children;
    if($params->{babysit}) {
        $heap->{babysit}=$params->{babysit};
        delete($heap->{"proctable"});
        eval {
            require Proc::ProcessTable;
            $heap->{"proctable"}=new Proc::ProcessTable;
        };
        DEBUG and do {
            print "Unable to load Proc::ProcessTable: $@\n" if $@;
        };
        $kernel->yield('babysit');
    }
    return $ret;
}

#------------------------------------------------------------------------------
sub _child
{
    my( $heap, $kernel, $op, $child, $ret ) = 
                                @_[ HEAP, KERNEL, ARG0, ARG1, ARG2 ];
    $ret ||= '';
    DEBUG and 
        warn "$$: _child op=$op child=$child ret=$ret";
    unless( $ret eq "channel-$child" ) {
        if( $op eq 'create' ) {
            DEBUG and 
                warn "$$: Detatching child session $child";
            $kernel->detach_child( $child );
        }
        return;
    }
    if( $op eq 'lose' ) {
        DB::disable_profile() if $INC{'Devel/NYTProf.pm'};
        $heap->{child_sessions}--;
        if( $heap->{child_sessions} > 0 ) {
            DEBUG and warn "$$: still have a child session";
        }
        _concurrency_down($heap);
    }
    else {
        $heap->{child_sessions}++;
        return;
    }
    unless( $heap->{wheel} ) {  # no wheel == GAME OVER
        ( DEBUG and not $INC{'Test/More.pm'} ) and
            warn "$$: }}}}}}}}}}}}}}} Game over\n";
        # XXX: Using shutdown is a stop-gap measure.  Maybe the daemon
        # wants to stay alive even if IKC was shutdown...
        # XXX: more to the point, maybe there are still requests that are
        # hanging around !
        $kernel->call( IKC => 'shutdown' );
    }
}

#------------------------------------------------------------------------------
# This event keeps this POE kernel alive
sub waste_time
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    return if $heap->{'is a child'};

    unless($heap->{'been told we are parent'}) {
        $heap->{verbose} and warn "$$: Telling everyone we are the parent\n";
        $heap->{'been told we are parent'}=1;
        $kernel->signal($kernel, '__parent');
    }
    if($heap->{'die'}) {
        DEBUG and warn "$$: Orderly shutdown\n";
    } else {
        $kernel->delay('waste_time', 60);
    }
    return;
}
    
#------------------------------------------------------------------------------
# Babysit the child processes
sub babysit
{
    my($kernel, $heap)=@_[KERNEL, HEAP];

    return if $heap->{'die'} or             # don't scan if we are dieing
              $heap->{'is a child'};        # or if we are a child

    my @children=keys %{$heap->{children}};
    $heap->{verbose} and warn  "$$: Babysiting ", scalar(@children), 
                            " children ", join(", ", sort @children), "\n";
    my %table;

    if($heap->{proctable}) {
        my $table=$heap->{proctable}->table;
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
                    DEBUG and warn "$$: Faking a CHLD for $pid\n";            
                    $kernel->yield('sig_CHLD', 'CHLD', $pid, $?, 1);
                    $ok{$pid}=1;
                } else {
                    $heap->{verbose} and warn "$$: $pid is a $state and couldn't be reaped.\n";
                    $missing{$pid}=1;
                }
            } 
            elsif($state eq 'run') {
                $time=eval{$table{$pid}->utime + $table{$pid}->stime};
                warn $@ if $@;
                # utime and stime are Linux-only :(
                $time /= 1_000_000 if $time;    # micro-seconds -> seconds

                if($time and $time > 1200) {    # arbitrary limit of 20 minutes
                    $rogues{$pid}=$table{$pid};
                        warn "$$: $pid has gone rogue, time=$time s\n";
                } else {
                    DEBUG and 
                        warn "$$: child $pid has utime+stime=$time s\n"
                            if $time > 1;
                    $ok{$pid}=1;
                }

            } elsif($state eq 'sleep' or $state eq 'defunct') {
                $ok{$pid}=1;
                # do nothing
            } else {
                $heap->{verbose} and warn "$$: $pid has unknown state '$state'\n";
                $ok{$pid}=1;
            }
        } elsif($heap->{proctable}) {
            $heap->{verbose} and warn "$$: $pid isn't in proctable!\n";
            $missing{$pid}=1;
        } else {                        # try another means.... :/
            if(-d "/proc" and not -d "/proc/$pid") {
                DEBUG and warn "$$: Unable to stat /proc/$pid!  Is the child missing\n";
                $missing{$pid}=1;
            } elsif(not $missing{$pid}) {
                $ok{$pid}=1;
            }
        }
    }

    # if a process is MIA, we fake a death, and spawn a new child
    foreach my $pid (keys %missing) {
        $kernel->yield('sig_CHLD', 'CHLD', $pid, 0, 1);
        $heap->{verbose} and warn "$$: Faking a CHLD for $pid MIA\n";            
    }

    # we could do the same thing for rogue processes, but instead we
    # give them time to calm down

    if($heap->{rogues}) {           # processes that are %ok are now removed
                                    # from the list of rogues
        delete @{$heap->{rogues}}{keys %ok} if %ok;
    }

    if(%rogues) {
        $kernel->yield('rogues') if not $heap->{rogues};

        $heap->{rogues}||={};
        foreach my $pid (keys %rogues) {
            if($heap->{rogues}{$pid}) {
                $heap->{rogues}{$pid}{proc}=$rogues{$pid};
            } else {
                $heap->{rogues}{$pid}={proc=>$rogues{$pid}, tries=>0};
            }
        }
    }

    $kernel->delay('babysit', $heap->{babysit});
    return;
}

#------------------------------------------------------------------------------
# Deal with rogue child processes
sub rogues
{
    my($kernel, $heap)=@_[KERNEL, HEAP];

    return if $heap->{'die'} or             # don't scan if we are dieing
              $heap->{'is a child'};        # or if we are a child

                                            # make sure we have some real work
    return unless $heap->{rogues};
eval {
    if(ref($heap->{rogues}) ne 'HASH' or not keys %{$heap->{rogues}}) {
        delete $heap->{rogues};
        return;
    }

    my $signal;
    while(my($pid, $rogue)=each %{$heap->{rogues}}) {
        $signal=0;
        if($rogue->{tries} < 1) {
            $signal=2;
        } 
        elsif($rogue->{tries} < 2) {
            $signal=15;
        }
        elsif($rogue->{tries} < 3) {
            $signal=9;
        }
    
        if($signal) {
            DEBUG and warn "$$: Sending signal $signal to rogue $pid\n";
            unless($rogue->{proc}->kill($signal)) {
                warn "$$: Error sending signal $signal to $pid: $!\n";
                delete $heap->{rogues}{$pid};
            }
        } else {
            # if SIGKILL didn't work, it's beyond hope!
            $kernel->yield('sig_CHLD', 'CHLD', $pid, 0, 1);
            delete $heap->{rogues}{$pid};
            $heap->{verbose} and warn "$$: Faking a CHLD for rogue $pid\n";            
        }

        $rogue->{tries}++;
    }
    $kernel->delay('rogues', 2*$heap->{babysit});
};
    warn "$$: $@" if $@;
}

#------------------------------------------------------------------------------
# Accept POE's standard _stop event, and stop all the children, too.
# The 'children' hash is maintained in the 'fork' and 'sig_CHLD'
# handlers.  It's empty for children.

sub _stop 
{
    my($kernel, $heap) = @_[KERNEL, HEAP];

                                        # kill the child servers
    if($heap->{children}) {
        foreach (keys %{$heap->{children}}) {
            DEBUG && print "$$: server is killing child $_ ...\n";
            kill 2, $_ or warn "$$: $_ $!\n";
        }
    }
    if($heap->{unix}) {
        unlink $heap->{unix};
    }
    DEBUG && 
        warn "$$: Server $heap->{name} _stop\n";
    # DEBUG_USR2 and check_kernel($kernel, $heap->{'is a child'}, 1);
    # __peek( 1 );
}

#------------------------------------------------------------------------------
sub shutdown
{
    my($kernel, $heap)=@_[KERNEL, HEAP];

    DEBUG and 
        warn "$$: Server $heap->{name} shutdown\n";

    _delete_wheel( $heap );         # close socket
    _delete_delays();               # get it OVER with

    # -GC
    # $kernel->alias_remove("IKC Server $heap->{wheel_address}");
    $heap->{'die'}=1;               # prevent race conditions
}

#----------------------------------------------------
# Log server errors, but don't stop listening for connections.  If the
# error occurs while initializing the factory's listening socket, it
# will exit anyway.

sub error
{
    my ($heap, $operation, $errnum, $errstr) = @_[HEAP, ARG0, ARG1, ARG2];


    DEBUG and
        warn __PACKAGE__, " $$: encountered $operation error $errnum: $errstr\n";

    my $ignore;
    if($errnum==EADDRINUSE) {       # EADDRINUSE
        $heap->{'die'}=1;
        _delete_wheel( $heap );
        $ignore = 0;
    } elsif($errnum==WSAEAFNOSUPPORT) {
        # Address family not supported by protocol family.
        # we get this error, yet nothing bad happens... oh well
        $ignore=1;
    }
    unless($ignore) {
        POE::Component::IKC::Util::monitor_error( $heap, $operation, $errnum, $errstr );
    }
}

#----------------------------------------------------
# The socket factory invokes this state to take care of accepted
# connections.

sub accept 
{
    my ($heap, $kernel, $handle, $peer_host, $peer_port) = 
            @_[HEAP, KERNEL, ARG0, ARG1, ARG2];

    T->start( 'IKC' );
    if(DEBUG) {
        if($peer_port) {        
            warn "$$: Server connection from ", inet_ntoa($peer_host), 
                            ":$peer_port", 
                            ($heap->{'is a child'}  ? 
                            " (Connection $heap->{connections})\n" : "\n");
        } else {
            warn "$$: Server connection over $heap->{unix}",
                            ($heap->{'is a child'}  ? 
                            " (Connection $heap->{connections})\n" : "\n");
        }
    }
    if($heap->{children} and not $heap->{'is a child'}) {
        warn "$$: Parent process received a connection: THIS SUCKS\n";
        return;
    }

    DB::enable_profile() if $INC{'Devel/NYTProf.pm'};

    DEBUG and warn "$$: Server kernel_aliases=", join ',', @{$heap->{kernel_aliases}||[]};

                                        # give the connection to a channel
    POE::Component::IKC::Channel->spawn(
                handle=>$handle, 
                name=>$heap->{name},
                unix=>$heap->{unix}, 
                aliases=>[@{$heap->{kernel_aliases}||[]}],
                protocol=>$heap->{protocol},
                on_error=>$heap->{on_error}
            );

    _concurrency_up($heap);
        
    return unless $heap->{children};

    if (--$heap->{connections} < 1) {
        DEBUG and 
                warn "$$: {{{{{{{{{{{{{{{ Game over\n";
        $kernel->delay('waste_time');
        _delete_wheel( $heap );
        $::TRACE_REFCNT = 1;

    } else {
        DEBUG and 
                warn "$$: $heap->{connections} connections left\n";
    }
}




#------------------------------------------------------------------------------
# The server has been requested to fork, so fork already.
sub fork 
{
    my ($kernel, $heap, $last) = @_[KERNEL, HEAP, ARG0];
    # children should not honor this event
    # Note that the forked POE kernel might have these events in it already
    # this is unavoidable
    if($heap->{'is a child'} or not $heap->{children} or $heap->{'die'}) {
        DEBUG and warn "$$: We are a child, why are we forking?\n";
        return;
    }
    my $parent=$$;
                 

    DEBUG and warn "$$: Forking a child";
                                   
    my $pid = fork();                   # try to fork
    unless (defined($pid)) {            # did the fork fail?
                                        # try again later, if a temporary error
        if (($! == EAGAIN) || ($! == ECHILD)) {
            DEBUG and warn "$$: Recoverable forking problem";
            $heap->{'failed forks'}++;
            $kernel->delay('retry', 1);
        }
        else {                          # fail permanently, if fatal
            POE::Component::IKC::Util::monitor_error( $heap, 'fork', 0+$1, "$!" );
            $kernel->yield('_stop');
        }
        return;
    }
                                        # successful fork; parent keeps track
    if ($pid) {
        $heap->{children}->{$pid} = 1;
        DEBUG &&
            print( "$$: master server forked a new child.  children: (",
                    join(' ', sort keys %{$heap->{children}}), ")\n"
                 );
        $kernel->yield('waste_time') if $last;
    }
                                        # child becomes a child server
    else {
        $heap->{verbose} and warn "$$: Created ", scalar localtime, "\n";

        # This resets some kernel data that was preventing the child process's
        # kernel from becoming IDLE
        if( $kernel->can( 'has_forked' ) ) {
            $kernel->has_forked;
        }
        else {
            $kernel->_data_sig_initialize;
        }

        # Clean out stuff that the parent needs but not the children
        $heap->{'is a child'}   = 1;        # don't allow fork
        $heap->{'failed forks'} = 0;
        $heap->{children}={};               # don't kill child processes
                                            # limit sessions, then die off
        $heap->{connections}    = $heap->{"max connections"};   

        # These signals are no longer our problem
        $kernel->sig('CHLD');
        $kernel->sig('INT');

        # remove any waits that might be around
        _delete_delays();               # get it OVER with

        delete @{$heap}{qw(rogues proctable)};

        # Tell everyone we are now a child
        $kernel->signal($kernel, '__child');

        # Create a select for the children, so that SocketFactory can
        # do it's thing
        _select_define($heap, 1);

        DEBUG && print "$$: child server has been forked\n";
    }

    # remove the call
    return;
}


#------------------------------------------------------------------------------
# Retry failed forks.  This is invoked (after a brief delay) if the
# 'fork' state encountered a temporary error.

sub retry 
{
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    if($heap->{'is a child'} or not $heap->{children}) {
        warn "$$: We are a child, why are we forking?\n";
        return;
    }

    # Multiplex the delayed 'retry' event into enough 'fork' events to
    # make up for the temporary fork errors.

    for (1 .. $heap->{'failed forks'}) {
        $kernel->yield('fork');
    }
                                        # reset the failed forks counter
    $heap->{'failed forks'} = 0;
    return;
}

#------------------------------------------------------------------------------
# SIGCHLD causes this session to fork off a replacement for the lost child.

sub sig_CHLD
{
    my ($kernel, $heap, $signal, $pid, $status, $fake) =
                @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    return if $heap->{"is a child"};

    if($heap->{children}) {
                                # if it was one of ours; fork another
        if (delete $heap->{children}->{$pid}) {
            DEBUG &&
                    print( "$$: master caught SIGCHLD for $pid.  children: (",
                                join(' ', sort keys %{$heap->{children}}), ")\n"
                        );
            $heap->{verbose} and warn "$$: Child $pid ", 
                        ($fake?'is gone':'exited normaly'), ".\n";
            $kernel->yield('fork') unless $heap->{'die'};
        } elsif($fake) {
            warn "$$: Needless fake CHLD for $pid\n";
        } else {
            warn "$$: CHLD for $pid child of someone else.\n";
        }
    }
                                        # don't handle terminal signals
    return;
}

#------------------------------------------------------------------------------
# Terminal signals aren't handled, so the session will stop on SIGINT.  
# The _stop event handler takes care of cleanup.

sub sig_INT
{
    my ($kernel, $heap, $signal, $pid, $status) =
                @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    return 0 if $heap->{"is a child"};

    if($heap->{children}) {
        $heap->{verbose} and warn "$$ SIGINT\n";
        $heap->{'die'}=1;
        # kill all events
        _delete_delays();               # get it OVER with
    } else {
        _delete_wheel( $heap );
    }    
    $kernel->post( IKC => 'shutdown' );
    $kernel->sig_handled();             # INT is terminal
    return;
}

#------------------------------------------------------------------------------
# daemontool's svc -d sends a TERM
# The _stop event handler takes care of cleanup.

sub sig_TERM
{
    my ($kernel, $heap, $signal, $pid, $status) =
                @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    $heap->{verbose} and warn "$$ SIGTERM\n";
    $heap->{'die'}=1;

    _delete_wheel( $heap );

    _delete_delays();               # get it OVER with

    $kernel->post( IKC => 'shutdown' );

    $kernel->sig_handled();             # TERM is terminal
    return;
}

############################################################
sub check_kernel
{
    my($kernel, $child, $signal)=@_;
    if(ref $kernel) {
        # 2 = KR_HANDLES
        # 7 = KR_EVENTS
        # 8 = KR_ALARMS (NO MORE!)
        # 12 = KR_EXTRA_REFS

        # 0 = HND_HANDLE
        warn( "$$: ,----- Kernel Activity -----\n",  
              "$$: | States : ", scalar(@{$kernel->[7]}), " ",
                            join( ', ', map {$_->[0]->ID."/$_->[2]"} 
                                        @{$kernel->[7]}), "\n",
#              "$$: | Alarms : ", scalar(@{$kernel->[8]}), "\n",
              "$$: | Files  : ", scalar(keys(%{$kernel->[2]})), "\n",
              "$$: |   `--> : ", join( ', ',
                               sort { $a <=> $b }
                               map { fileno($_->[0]) }
                               values(%{$kernel->[2]})
                             ),   "\n",
              "$$: | Extra  : ${$kernel->[12]}\n",
              "$$: `---------------------------\n",
         );
#        if($child) {
#            foreach my $q (@{$kernel->[8]}) {
#                warn "************ Alarm for ", join '/', @{$q->[0][2]{$q->[2]}};
#            }
#        }
    } else {
        warn "$kernel isn't a reference";
    }
}

############################################################
sub __peek
{
    my($verbose)=@_;
    eval {
        require POE::Component::Daemon;
    };
    unless( $@ ) {
        my $ret = Daemon->peek( $verbose );
        $ret =~ s/\n/\n$$: /g;
        warn "$$: $ret";
        return 1;
    }

    eval {
        require POE::API::Peek;
    };
    if($@) {
        DEBUG and warn "Failed to load POE::API::Peek: $@";
        return;
    }
    my $api=POE::API::Peek->new();
    my @queue = $api->event_queue_dump();
    
    my $ret = "Event Queue:\n";
  
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
            $ret .= "\t\tDestination: ".
                    $api->session_id_loggable($item->{destination}).
                    "\n";
            $ret .= "\t\tType: ".$item->{type}."\n";
            $ret .= "\n";
        }
    }
    if($api->session_count) {
        $ret.="Keepalive " unless $verbose;
        $ret.="Sessions: \n";
        my $ses;
        foreach my $session ( sort { $a->ID <=> $b->ID } $api->session_list) {  
            my $ref=0;
            $ses='';

            $ses.="\tSession ".$api->session_id_loggable($session)." ($session)";

            my $refcount=$api->get_session_refcount($session);
            $ses.="\n\t\tref count: $refcount\n";

            my $q1=$api->get_session_extref_count($session);
            $ref += $q1;
            $ses.="\t\textref count: $q1 [keepalive]\n" if $q1;

            my $hc=$api->session_handle_count($session);
            $ref += $hc;
            $ses.="\t\thandle count: $q1 [keepalive]\n" if $hc;

            my @aliases=$api->session_alias_list($session);
            $ref += @aliases;
            $q1=join ',', @aliases;
            $ses.="\t\tAliases: $q1\n" if $q1;

            my @children = $api->get_session_children($session);
            if(@children) {
                $ref += @children;
                $q1 = join ',', map {$api->session_id_loggable($_)} @children;
                $ses.="\t\tChildren: $q1\n";
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
                $ses.="\t\tReference: refcount=$refcount counted=$ref [keepalive]\n";
            }
            if($hc or $verbose or $refcount != $ref) {
                $ret.=$ses;
            }
        }
    }
    $ret.="\n";

    warn "$$: $ret";
    return 1;
}


sub sig_USR2
{
#    return unless DEBUG;
    my ($kernel, $heap, $signal, $pid) = @_[KERNEL, HEAP, ARG0, ARG1];
    $pid||='';
    warn "$$: signal $signal $pid\n";
    unless(__peek(1)) {
        check_kernel($kernel, $heap->{'is a child'}, 1);
    }
    $kernel->sig_handled();
    return;
}

sub sig_USR1
{
#    return unless DEBUG;
    my ($kernel, $heap, $signal, $pid) = @_[KERNEL, HEAP, ARG0, ARG1];
    $pid||='';
    warn "$$: signal $signal $pid\n";
    unless(__peek(0)) {
        check_kernel($kernel, $heap->{'is a child'}, 0);
    }
    $kernel->sig_handled();
    return;
}


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

POE::Component::IKC::Server - POE Inter-kernel Communication server

=head1 SYNOPSIS

    use POE;
    use POE::Component::IKC::Server;
    POE::Component::IKC::Server->spawn(
        ip=>$ip, 
        port=>$port,
        name=>'Server');
    ...
    $poe_kernel->run();

=head1 DESCRIPTION

This module implements a POE IKC server.  A IKC server listens for incoming
connections from IKC clients.  When a client connects, it negociates certain
connection parameters.  After this, the POE server and client are pretty much
identical.

=head1 EXPORTED FUNCTIONS

=head2 C<create_ikc_server>

Deprecated.  Use L<POE::Component::IKC::Server/spawn>.

=head1 CLASS METHODS

=head2 C<spawn>

This methods initiates all the work of building the IKC server. 
Parameters are :

=over 4

=item C<ip>

Address to listen on.  Can be a doted-quad ('127.0.0.1') or a host name
('foo.pied.nu').  Defaults to '0.0.0.0', aka INADDR_ANY.

=item C<port>

Port to listen on.  Can be numeric (80) or a service ('http').  If
undefined, will default to 603.  
If you set the port to 0, a random port will be chosen and C<spawn> will
return the port number.

    my $port = POE::Component::IKC::Server->spawn( port => 0 );
    warn "Listeing on port $port";


=item C<unix>

Path to the unix-socket to listen on.  Note: this path is unlinked before 
socket is attempted!  Buyer beware.

=item C<name>

Local kernel name.  This is how we shall "advertise" ourself to foreign
kernels. It acts as a "kernel alias".  This parameter is temporary, pending
the addition of true kernel names in the POE core.  This name, and all
aliases will be registered with the responder so that you can post to them
as if they were remote.

=item C<aliases>

Arrayref of even more aliases for this kernel.  Fun Fun Fun!


=item C<verbose>

Print extra information to STDERR if true.  This allows you to see what
is going on and potentially trace down problems and stuff.

=item C<processes>

Activates the pre-forking server code.  If set to a positive value, IKC will
fork processes-1 children.  IKC requests are only serviced by the children. 
Default is 1 (ie, no forking).

=item C<babysit>

Time, in seconds, between invocations of the babysitter event.

=item C<connections>

Number of connections a child will accept before exiting.  Currently,
connections are serviced concurrently, because there's no way to know when
we have finished a request.  Defaults to 1 (ie, one connection per
child).

=item C<concurrency>

Number of simultaneous connected clients allowed.
Defaults to 0 (unlimited).  

Note that this is per-IKC::Server instance;  if you have several ways of
connecting to a give IKC server (for example, both an TCP/IP port and unix
pipe), they will not share the conncurrent connection count.

=item C<protocol>

Which IKC negociation protocol to use.  The original protocol (C<IKC>) had a
slow synchronous handshake.  The new protocol (C<IKC0>) sends all the
handshake information at once.  IKC0 will degrade gracefully to IKC, if the
client and server don't match.

Default is IKC0.

=item C<on_error>

Coderef that is called for all errors. You could use this to monitor for
problems when forking children or opening the socket.  Parameters are
C<$operation, $errnum and $errstr>, which correspond to
POE::Wheel::SocketFactory's FailureEvent, which q.v.

However, IKC/monitor provides a more powerful mechanism for detecting
errors.  See L<POE::Component::IKC::Responder>.  

Note, also, that the coderef will be executed from within an IKC session,
NOT within your own session.  This means that things like
$poe_kernel->delay_set() won't do what you think they should.


=back

C<POE::Component::IKC::Server::spawn> returns C<undef()>, unless you specify
a L</port>=0, in which case, C<spawn> returns the port that was chosen.


=head1 EVENTS

=head2 shutdown

This event causes the server to close it's socket, clean up the shop and
head home. Normally it is only posted from IKC::Responder.

=head1 BUGS

Preforking is something of a hack.  In particular, you must make sure that
your sessions will permit children exiting.  This means, if you have a
delay()-loop, or event loop, children will not exit.  Once POE gets
multicast events, I'll change this behaviour. 

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC::Client>

=cut
