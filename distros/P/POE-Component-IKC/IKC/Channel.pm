package POE::Component::IKC::Channel;

############################################################
# $Id: Channel.pm 1247 2014-07-07 09:06:34Z fil $
# Based on tests/refserver.perl
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
use POE qw(Wheel::ListenAccept Wheel::ReadWrite Wheel::SocketFactory
           Driver::SysRW Filter::Reference Filter::Line
          );
use POE::Component::IKC::Responder;
use POE::Component::IKC::Protocol;
use POE::Component::IKC::Util;
use Data::Dump qw( pp );
use Devel::Size qw( total_size );

# use Net::Gen ();

use Time::HiRes qw( gettimeofday tv_interval );

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_channel);
$VERSION = "0.2402";

sub DEBUG () { 0 }

BEGIN {
    no strict 'refs';
    unless( defined &TIMING ) {
        if( $ENV{IKC_TIMING} ) { *TIMING = sub () { 1 } } 
        else                   { *TIMING = sub () { 0 } }
    }
    unless( defined &PROTOCOL ) {
        if( $ENV{IKC_PROTOCOL} ) { *PROTOCOL = sub () { 1 } } 
        else                     { *PROTOCOL = sub () { 0 } }
    }
}

###############################################################################
# Channel instances are created by the listening session to handle
# connections.  They receive one or more thawed references, and pass
# them to the running Responder session for processing.

#----------------------------------------------------
# This is just a convenient way to create channels.

sub create_ikc_channel
{
    my %p;
    @p{qw(handle name on_connect subscribe rname unix aliases serializers protocol)}
            = @_;
    return __PACKAGE__->spawn(%p);
}

sub spawn
{
    my $package=shift;
    my %params=@_;

    return POE::Session->create( 
                inline_states => {
                    _start => \&channel_start,
                    _stop  => \&channel_stop,
                    _default => \&channel_default,
                    error  => \&channel_error,
                    shutdown =>\&channel_close,

                    receive => \&channel_receive,
                    'send'  => \&channel_send,
                    'flushed' => \&channel_flushed,
                    'done'  => \&channel_done,
                    'close' => \&channel_close,
                    server_000 => \&server_000,
                    server_001 => \&negociate_001,
                    server_002 => \&server_002,
                    server_003 => \&server_003,
                    server_010 => \&server_010,
                    client_000 => \&client_000,
                    client_001 => \&negociate_001,
                    client_002 => \&client_002,
                    client_003 => \&client_003,
                    client_010 => \&client_010,
                    'sig_INT'  => \&sig_INT
               },
               args => [\%params]
           )->ID;
}

#----------------------------------------------------
# Accept POE's standard _start event, and begin processing data.
sub channel_start 
{
    my ($kernel, $heap, $session, $p) = @_[KERNEL, HEAP, SESSION, ARG0];

    if( TIMING ) {
        $heap->{start_time} = [ gettimeofday ];
        delete $heap->{last_time};
    }

    my @names;
    push @names, $p->{name} if $p->{name};
    push @names, @{$p->{aliases}} if $p->{aliases};
    # $name is blank if create_ikc_{server,client} wasn't called with a name
    # OR if we are a kernel that was connected to (2001/05 huh?)

    # +GC
    my $alias = 0+$session;
    $alias = "Channel $alias";
    $kernel->alias_set($alias);
    $heap->{session_alias} = $alias;

    # all clients have $on_connect defined, even if sub {}
    $heap->{is_server} = not $p->{client};
    DEBUG and 
        warn "$$: We are a ".($heap->{is_server} ? 'server' : 'client')."\n";

    if($p->{unix}) {
        $p->{unix}=~s/[^-:.\w]+/_/g;
        push @names, "unix:$p->{unix}";

        unless($heap->{is_server}) {
            $names[-1].=":$$-".fileno($p->{handle});
        }
    }
    else {
        my @name=unpack_sockaddr_in(getsockname($p->{handle}));
        $name[1]=inet_ntoa($name[1]);
        push @names, join ':', @name[1,0];
    }

    DEBUG and warn "$$: Names: ", join ',', @names;
    $heap->{kernel_name}=shift @names;
    $heap->{kernel_aliases}=\@names;
    

    # remote_kernel is only needed for DEBUG messages only
    # remote_aliases, however, is important
    # remote_ID is set when negociations are finished
    #           it should be cannonical name according to remote side
    # temp_remote_kernel is a local sanity alias. (ie, if we connect to 
    #               something:port, it should have that name as an alias)
    if($p->{rname}) {          # we are a server
        $heap->{remote_kernel}=$p->{rname}; 
        $heap->{temp_remote_kernel}=$p->{rname};
    } 
    elsif($p->{unix}) {        # we are a client
        my $n=$p->{unix};
        $n=~tr(/\\)(--);
        $heap->{remote_kernel}="unix:$n:$$:".
                                    fileno($p->{handle});
        $heap->{temp_remote_kernel}="unix:n" unless $heap->{is_server};


        # we need to have unique aliases for remote kernels
        # so, only the server gets a default name, clients don't
    } 
    else {
        my @name=unpack_sockaddr_in(getpeername($p->{handle}));
        $name[1]=inet_ntoa($name[1]);
        $heap->{temp_remote_kernel}=
                    $heap->{remote_kernel}=join ':', @name[1,0];
    }

    DEBUG && warn "Channel session $heap->{kernel_name}<->$heap->{remote_kernel} created.\n";

                                        # start reading and writing
    $heap->{wheel_client} = new POE::Wheel::ReadWrite
    ( Handle     => $p->{handle},      # on this handle
      Driver     => new POE::Driver::SysRW, # using sysread and syswrite
      InputEvent => 'none',
      Filter     => POE::Filter::Line->new(), # use a line filter for negociations
      ErrorEvent => 'error',                # generate this event on error
    );

    $session->option(default=>1);
    $heap->{on_connect}=$p->{on_connect} if ref($p->{on_connect});
    $heap->{on_error}=$p->{on_error} if ref($p->{on_error});
    $heap->{subscribe}=$p->{subscribe} 
            if ref($p->{subscribe}) and @{$p->{subscribe}};

    unless($heap->{is_server}) {
        if(ref($p->{serializers}) and @{$p->{serializers}}) {
            $heap->{serializers}=$p->{serializers};
        }
        DEBUG and 
            warn __PACKAGE__, " Serializers: ", 
                                        join(', ', @{$heap->{serializers}||[]}), "\n";
    }
    
    # Setup negociation
    $p->{protocol} ||= 'IKC';
    if( $p->{protocol} eq 'IKC0' ) {
        PROTOCOL and warn "$$: Using protocol IKC0\n";
        _set_phase($kernel, $heap, '010');
    }
    else {
        PROTOCOL and warn "$$: Using protocol IKC\n";
        _set_phase($kernel, $heap, '000');
    }

    # This shouldn't be necessary
    POE::Component::IKC::Responder->spawn();

    # Register this channel
    my $ikc = eval { $kernel->alias_resolve( 'IKC' ) };
    if( $ikc ) {
        $kernel->call( $ikc, 'register_channel' );
    }
    else {
        POE::Component::IKC::Util::monitor_error( $heap, 'setup', 2, "No IKC responder" );
        $kernel->yield( 'shutdown' );
    }
    return "channel-$session";
}

#----------------------------------------------------
sub _negociation_done
{
    my($kernel, $heap)=@_;
    DEBUG and
            warn "$$: Negociation done ($heap->{kernel_name}<->$heap->{remote_kernel}).\n";

    $heap->{finishing} = 1;

    _pause_wheel( $heap );
    _register_remote( $kernel, $heap );

    # now that we've registered the remote kernel, we will no longer trigger on_error
    delete $heap->{on_error};

    TIMING and channel_log( $heap, "negociated" );
    
    T->point( 'IKC', 'nego done' );

    # Now that we're set up properly
    if($heap->{subscribe}) {                # subscribe to wanted sessions
        $kernel->call('IKC', 'subscribe', $heap->{subscribe}, 'done');
    } 
    else {
        # "fake" a completed subscription
        $kernel->yield('done');
    }

    delete $heap->{finishing};

    _change_wheel( $heap );
    _resume_wheel( $heap ); 

    _monitor_channel( $heap, 'ready' );

    return;
}

sub _register_remote
{
    my( $kernel, $heap ) = @_;

    # Register the foreign kernel with the responder
    my $aliases=delete $heap->{remote_aliases};
    push @$aliases, $heap->{temp_remote_kernel}
                    if $heap->{temp_remote_kernel} and 
                        not grep {$_ eq $heap->{temp_remote_kernel}} @$aliases;

    DEBUG and 
        warn "$$: Register remote as ", join ', ', @$aliases;
    # we need a globaly unique ID
    $heap->{remote_ID}=shift @$aliases;
#    delete $heap->{remote_kernel};
    $kernel->call('IKC', 'register', $heap->{remote_ID}, $aliases, $heap->{remote_pid});

    DEBUG and 
        warn "$$: Registered remotes";
}


sub _change_wheel
{
    my( $heap ) = @_;

    DEBUG and
        warn "$$: Changing the wheel events\n";
    # generate this event on input
    $heap->{'wheel_client'}->event( InputEvent => 'receive',
                                    FlushedEvent => 'flushed'
                                  );

    unless($heap->{filter}) {
        DEBUG and warn "$$: We didn't negociate a freezer, using defaults\n";
        $heap->{filter}=POE::Filter::Reference->new();
    }

    DEBUG and
        warn "$$: Changing the wheel filter\n";

    # parsing I/O as references
    my $ft = $heap->{filter};
    DEBUG and warn "$$: Filter is now $ft";
    $heap->{wheel_client}->set_filter($ft); 
    delete $heap->{filter};

    DEBUG and
        warn "$$: Changed the wheel filter\n";
}


sub _pause_wheel
{
    my( $heap ) = @_;
    DEBUG and
        warn "$$: Pause wheel\n";
    $heap->{'wheel_client'}->pause_input;
}

sub _resume_wheel
{
    my( $heap ) = @_;
    DEBUG and
        warn "$$: Resume wheel\n";
    $heap->{'wheel_client'}->resume_input;
}

sub _monitor_channel
{
    my( $heap, $op ) = @_;
    $poe_kernel->call( IKC => 'inform_monitors',
                        $heap->{remote_ID},
                        'channel', $op, $poe_kernel->get_active_session->ID 
                     );


}


#----------------------------------------------------
# This is the subscription callback
sub channel_done
{
    my($heap, $subscribed)=@_[HEAP, ARG0];
    if($heap->{subscribe})
    {
        my %count;
        foreach my $spec (@$subscribed, @{$heap->{subscribe}})
        {   $count{$spec}++;    
        }
        my @missing=grep { $count{$_} != 2 } keys %count;

        if(@missing)
        {
            die "Unable to subscribe to ".join(', ', @missing)."\n";
        } 
        delete $heap->{subscribe};
        DEBUG and warn "$$: Subscriptions are completed\n";
    }

    if($heap->{on_connect})            # or call the on_connect
    {
        DEBUG and warn "$$: On connect\n";
        $heap->{on_connect}->();
        delete $heap->{on_connect};    
    }    

    # Detach from parent session
    unless( $heap->{is_server} ) {
        # Only if we are a client.  Server uses 'lose' to detect disconnects
        # for concurrency.
        $_[KERNEL]->detach_myself;
    }

    TIMING and channel_log( $heap, "subscribed" );


    # wait until everything is sane before registering this
#    $kernel->signal(INT=>'sig_INT');       # sig_INT() is in fact empty
}

#----------------------------------------------------
#### DEAL WITH NEGOCIATION PHASE
sub _set_phase
{
    my($kernel, $heap, $phase, $line)=@_;
    if($phase eq 'ZZZ')
    {
        _negociation_done($kernel, $heap);
        return;
    } 

    my $neg = $heap->{is_server} ? 'server_' : 'client_';

        # generate this event on input
    $heap->{'wheel_client'}->event(InputEvent => $neg.$phase);
    DEBUG && warn "Negociation phase $neg$phase.\n";
    $kernel->yield($neg.$phase, $line);     # Start the negociation phase
    return;
}

# First server state is
sub server_000
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    unless(defined $line) {
        # wait for client to send HELLO
    } 
    elsif( $line =~ /^HELLO IKC\d$/ ) {         # compatible with IKC1
        $heap->{'wheel_client'}->put( 'NOT' );
    }
    elsif( $line =~ /^SETUP/ ) {                # compatible with IKC0
        $heap->{'wheel_client'}->put( 'NOT' );
    }
    elsif( $line eq 'HELLO' ) {
        $heap->{'wheel_client'}->put('IAM '.$kernel->ID());

        # put other server aliases here
        $heap->{aliases001}=[$heap->{kernel_name},
                             @{$heap->{kernel_aliases}}];   
        DEBUG and warn "$$: Server we are going to tell remote that aliases001=", join ',', @{$heap->{aliases001}};
        _set_phase($kernel, $heap, '001');

    } 
    else {
        # wait for client to say something coherrent :)
        warn "Client sent '$line' during phase 000\n";
    }
    return;
}

# We tell who we are
sub negociate_001
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];
    
    unless(defined $line) {
        # far side must talk now (we sent "IAM kernel")
    } 
    elsif($line eq 'OK') {
        my $a=pop @{$heap->{aliases001}};
        if($a) {
            $heap->{'wheel_client'}->put("IAM $a");
        } 
        else {
            delete $heap->{aliases001};
            $heap->{'wheel_client'}->put('DONE');   
            _set_phase($kernel, $heap, '002');
        }
    } 
    else {
        warn "Received '$line' during phase 001\n";
        # prod far side into saying something coherrent
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
    return;
}

# We find out who the client is
sub server_002
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    unless(defined $line) {
        # far side must respond to the "DONE"
    } 
    elsif($line eq 'DONE') {
        _set_phase($kernel, $heap, '003');
    } 
    elsif($line =~ /^IAM\s+([-:.\w]+)$/) {   
        # Register this kernel alias with the responder
        push @{$heap->{remote_aliases}}, $1;
        $heap->{'wheel_client'}->put('OK');   

    } 
    else {
        warn "Client sent '$line' during phase 002\n";
        # prod far side into saying something coherrent
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
    return;
}

# We find out what type of serialisation the client wants
sub server_003
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    unless(defined $line) {
        # wait for client to send FREEZER after last IAM
    } 
    elsif($line =~ /^FREEZER\s+([-:\w]+)$/) {   
        my $package=$1;
        eval {
            DEBUG and warn "Going to use $package as serializer\n";
            $heap->{filter}=POE::Filter::Reference->new($package);
        };

        if($heap->{filter}) {
            DEBUG && 
                warn "$$: Using $package\n";
            $heap->{wheel_client}->put('OK');
        } else {
            DEBUG && warn "Client wanted $package, but we can't : $@";
            $heap->{wheel_client}->put('NOT');
        }
    } 
    elsif($line =~ /^FREEZER\s+(.+)$/) {
        warn "Client sent invalid package $1 as a serializer, refused\n";
        $heap->{wheel_client}->put('NOT');
    } 
    elsif($line eq 'WORLD') {
        # last bit of the dialog has to come from us :(
        $heap->{wheel_client}->put('UP');   
        _set_phase($kernel, $heap, 'ZZZ');     
    } 
    else {
        warn "Client sent '$line' during phase 003\n";
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
    return;
}

#----------------------------------------------------
# These states is invoked for each line during the negociation phase on 
# the client's side

## Start negociation and listen to who the server is
sub client_000
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    unless(defined $line) {
        $heap->{wheel_client}->put('HELLO');

    } 
    elsif($line =~ /^IAM\s+([-:.\w]+)$/) {   
        # Register this kernel alias with the responder
        DEBUG and warn "$$: Remote server is called $1\n";
        push @{$heap->{remote_aliases}}, $1;
        $heap->{wheel_client}->put('OK');

    } 
    elsif($line eq 'DONE') {
        $heap->{'wheel_client'}->put('IAM '.$poe_kernel->ID());
        $heap->{aliases001}=[$heap->{kernel_name}, 
                             @{$heap->{kernel_aliases}}];
        _set_phase($kernel, $heap, '001');

    } 
    else {
        warn "$$: Server sent '$line' during negociation phase 000\n";
        # prod far side into saying something coherrent
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
    return;
}

# try to negociate a serialization method
sub client_002
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];
    
    unless(defined $line) {
        $heap->{serial002}=$heap->{serializers};
        $line=$heap->{serial002} ? 'NOT' : 'OK';
        # NOT= pretend that we already sent a FREEZER
        # OK= use default freezers
    }

    if($line eq 'NOT') {
        delete $heap->{filter};
        my $ft;
        while(@{$heap->{serial002}}) {
            $ft=shift @{$heap->{serial002}};
            DEBUG and 
                warn "$$: Trying serializer $ft\n";
            $heap->{filter}=eval {
                POE::Filter::Reference->new($ft);
            };
            last if $heap->{filter};
            DEBUG and warn $@;
        }

        if($ft) {   
            $heap->{'wheel_client'}->put('FREEZER '.$ft);   
        } 
        else {
            DEBUG and 
                warn "Server doesn't like our list of serializers ", 
                                    join ', ', @{$heap->{serializers}};
            delete $heap->{serial002};
            _set_phase($kernel, $heap, '003');
        }
    } 
    elsif($line eq 'OK') {
        delete $heap->{serial002};  
        _set_phase($kernel, $heap, '003');
    } 
    else {
        warn "Server sent '$line' during negociation phase 002\n";
        # prod far side into saying something coherrent
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
}

# Game over
sub client_003
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    unless(defined $line) {
        $heap->{'wheel_client'}->put('WORLD');
    } 
    elsif($line eq 'UP') {
        _set_phase($kernel, $heap, 'ZZZ');
    } 
    else {
        warn "Server sent '$line' during phase 003\n";
        # prod far side into saying something coherrent
        $heap->{wheel_client}->put('NOT') unless $line eq 'NOT';
    }
    return;
}


##############################################################################
sub client_010
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    DEBUG and $line and warn "Client010: $line";

    unless(defined $line) {
        # TODO : make sure all serializers load
        # T->point( 'IKC', 'first line' );
        my $setup = __build_setup( $heap, $heap->{serializers} );
        # T->point( 'IKC', 'build_setup' );
        DEBUG and warn "Client010: sending $setup";
        $heap->{wheel_client}->put( $setup );
    } 
    elsif( $line eq 'NOT' ) {
        PROTOCOL and warn "$$: Using protocol IKC (fallback)\n";
        _set_phase( $kernel, $heap, '000' );
    }
    elsif($line =~ /^SETUP (.+)$/) {
        # T->point( IKC => 'got SETUP' );
        DEBUG and warn "$$: Remote server setup as $1\n";
        my $neg = __neg_setup( $1 );
        unless( 1==@{ $neg->{freezer} } ) {
            warn "Server didn't send one freezer in $line\n";
            $neg->{bad}++;
        }

        if( $neg->{bad} ) {
            $heap->{wheel_client}->put( 'NOT' );
            return;
        }
        # Register these kernel alias with the responder
        $heap->{remote_aliases} = $neg->{kernel};
        $heap->{remote_pid} = $neg->{pid};
        # Build the filter we shall use later
        $heap->{filter} = eval { POE::Filter::Reference->new( $neg->{freezer}[0] ) };
        die "Unable to build filter: $@" if $@;
        die "Unable to build filter $neg->{freezer}[0]" unless $heap->{filter};
        # T->point( IKC => 'got SETUP' );
        _set_phase( $kernel, $heap, 'ZZZ' );
    } 
    else {
        warn "Server sent '$line' during negociation phase 002\n";
        $heap->{wheel_client}->put('NOT');
    }
}

sub server_010
{
    my ($heap, $kernel, $line)=@_[HEAP, KERNEL, ARG0];

    DEBUG and $line and warn "Server010: $line";

    unless(defined $line) {
        # wait for client
    }
    elsif( $line =~ /^HELLO IKC\d$/ ) {         # compatible with IKC1
        $heap->{'wheel_client'}->put( 'NOT' );
    }
    elsif( $line eq 'HELLO' ) {
        PROTOCOL and warn "$$: Using protocol IKC (fallback)\n";
        _set_phase( $kernel, $heap, '000', $line );
        return;
    }
    elsif( $line =~ /^SETUP (.+)$/ ) {
        DEBUG and warn "$$: Remote client setup as $1\n";
        my $neg = __neg_setup( $1 );

        my $filter;
        if( not $neg->{bad} ) {
            # Build the filter we shall use later
            foreach my $ft ( @{ $neg->{freezer} } ) {
                $filter = $ft;
                $heap->{filter} = eval {  POE::Filter::Reference->new( $ft ) };
                last if $heap->{filter};
                DEBUG and warn "Client wanted $ft, but we can't: $@";
            }
        }
        unless( $heap->{filter} ) {
            warn "None of the filters the client wants are OK: ", 
                            join ', ', @{ $neg->{freezer} };
            $neg->{bad}++;
        }

        if( $neg->{bad} ) {
            $heap->{wheel_client}->put( 'NOT' );
            return;
        }
        # Register these kernel alias with the responder
        $heap->{remote_aliases} = $neg->{kernel};
        $heap->{remote_pid} = $neg->{pid};

        # Send our SETUP back
        my @freezers = ( $filter );
        my $setup = __build_setup( $heap, [$filter] );
        DEBUG and warn "Server010: sending $setup";
        $heap->{wheel_client}->put( $setup );  

        # Move to next phase
        _set_phase( $kernel, $heap, 'ZZZ' );
    }
}

sub __build_setup
{
    my( $heap, $freezers ) = @_;
    my $aliases = [ $poe_kernel->ID, 
                    $heap->{kernel_name}, 
                    @{$heap->{kernel_aliases}} 
                  ];
    return POE::Component::IKC::Protocol::__build_setup( $aliases, $freezers );
}        

sub __neg_setup
{
    return POE::Component::IKC::Protocol::__neg_setup( $_[0] );
}



#----------------------------------------------------
# This state is invoked for each error encountered by the session's
# ReadWrite wheel.

sub channel_error 
{
    my ($heap, $kernel, $operation, $errnum, $errstr) =
        @_[HEAP, KERNEL, ARG0, ARG1, ARG2];

    POE::Component::IKC::Util::monitor_error( $heap, 
                            $operation, $errnum, $errstr,
                            ( $operation eq 'read' && $errnum == 0 )
                        );

    if ($errnum) {
        DEBUG && 
           warn "$$: Channel encountered $operation error $errnum: $errstr\n";
    }
    else {
        DEBUG && 
            warn "$$: The channel's client closed its connection ($heap->{kernel_name}<->$heap->{remote_kernel})\n";
    }

    # warn "ERROR $heap->{remote_ID}";
    _close_channel($heap, 1);                # either way, shut down
}


#----------------------------------------------------
sub _channel_unregister
{
    my($heap)=@_;
    if($heap->{remote_ID}) {
        DEBUG and warn <<WARN;
------------------------------------------
              UNREGISTER $$ $heap->{remote_ID}
------------------------------------------
WARN
        # 2005/06 Tell IKC we closed the connection
        $poe_kernel->call( 'IKC', 'unregister', $heap->{remote_ID} );
        delete $heap->{remote_ID};
    }
                                        # either way, shut down
}

#----------------------------------------------------
sub _close_channel
{
    my($heap, $force)=@_;


    # we have to inform monitors before unregistering
    # but we only want to inform once, 
    _monitor_channel( $heap, 'close' ) unless $heap->{inform_once}++;

    # tell responder right away that this channel isn't to be used
    _channel_unregister($heap);

    return unless $heap->{wheel_client};


    if(not $force and $heap->{wheel_client}->get_driver_out_octets) {
        DEBUG and 
            warn "************ Defering wheel close";
        $heap->{go_away}=1;         # wait until next Flushed
        return;
    } 

    DEBUG and 
        warn "Deleting wheel session = ", $poe_kernel->get_active_session->ID;
    my $x=delete $heap->{wheel_client};
    # WORK AROUND
    # $x->DESTROY;

    # sig_INT is empty
    # $kernel->sig( 'INT' );

    if( $heap->{session_alias} ) {
        $poe_kernel->alias_remove( delete $heap->{session_alias} );
    }

    if( TIMING ) {
        channel_log( $heap, "close" );
        delete $heap->{start_time};
        delete $heap->{last_time};
    }
    T->point( 'IKC', 'close' );

    return;   
}




#----------------------------------------------------
#
sub channel_default
{
    my($event)=$_[STATE];
    DEBUG && warn "Unknown event $event posted to IKC::Channel\n"
        if $event !~ /^_/;
    return;
}

#----------------------------------------------------
# Process POE's standard _stop event by shutting down.
sub channel_stop 
{
    my $heap = $_[HEAP];
    DEBUG && 
        warn "$$: *** Channel will shut down.\n";
    _close_channel($heap);
    T->end( 'IKC' );

    return "channel-$_[SESSION]";
}

###########################################################################
## Next two events forward messages between Wheel::ReadWrite and the
## Responder
## Because the Responder know which foreign kernel sent a request,
## these events fill in some of the details.

#----------------------------------------------------
# Foreign kernel sent us a request
sub channel_receive
{
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

    warn "$$: Attempting to receive during finishing" if $heap->{finishing};

    T->point( 'IKC', 'receive' );

    TIMING and 
        channel_log( $heap, "receive" );

    DEBUG && 
        warn "$$: Received data...\n";
    return if $heap->{shutdown};

    # we won't trust the other end to set this properly
    $request->{errors_to}={ kernel=>$heap->{remote_ID},
                            session=>'IKC',
                            state=>'remote_error',
                          };
    # just in case
    $request->{call}->{kernel}||=$heap->{kernel_name};

    # call the Responder channel to process
    # hmmm.... i wonder if this could be stream-lined into a direct call
    $kernel->call('IKC', 'request', $request);
    return;
}

#----------------------------------------------------
# Local kernel is sending a request to a foreign kernel
sub channel_send
{
    my ($heap, $request)=@_[HEAP, ARG0];

    die "Attempting to send during finishing" if $heap->{finishing};

    TIMING and 
        channel_log( $heap, "send" );

    my $size = total_size $request;
    if( $size > 100*1024*1024 ) {
        die "$$ Channel sending WAY too much data ($size bytes)";
    }
    DEBUG && 
        warn "$$: Sending data...\n";
        # add our name so the foreign channel can find us
        # TODO should we do this?  or should the other end do this?
    $request->{rsvp}->{kernel}||=$heap->{kernel_name}
            if ref($request) and $request->{rsvp};

    if($heap->{'wheel_client'}) {
        $heap->{'wheel_client'}->put($request);
    }
    else {
        my $what={event => $request->{event},
                  from  => $request->{from}};
        $what->{action} = $request->{params}[0] 
            if $what->{event}{state} eq 'IKC:proxy' and 
                'ARRAY' eq ref $request->{params};
        my $type = "missing";
        $type = "shutdown" if $heap->{shutdown};
        warn "$$: Attempting to put to a $type channel! ". pp $what;
    }
    T->point( 'IKC', 'send' );

    return 1;
}

#----------------------------------------------------
sub channel_flushed
{
    my($heap, $wheel)=@_[HEAP, ARG0];
    DEBUG && 
        warn "$$: Flushed data...\n";
    if($heap->{go_away}) {
        _close_channel($heap);
    }
    return;
}

#----------------------------------------------------
# Local kernel thinks it's time to close down the channel
sub channel_close
{
    my ($heap, $sender)=@_[HEAP, SENDER];
    unless( $heap->{shutdown} ) {
        DEBUG && 
            warn "$$: channel_close *****************************************\n";
        $heap->{shutdown}=1;
    }
    _close_channel( $heap );
}

#----------------------------------------------------
# User wants to kill process / kernel
sub sig_INT
{
    my ($heap, $kernel)=@_[HEAP, KERNEL];
    DEBUG && warn "$$: Channel::sig_INT\n";
    $kernel->sig_handled();
    return;
}

#----------------------------------------------------
sub channel_log
{
    my( $heap, $when ) = @_;
    return unless $heap->{start_time};
    my $now = [ gettimeofday ];
    my $el = tv_interval( $heap->{start_time}, $now );
    my $time = _delta_time( $el );

    if( $heap->{last_time} ) {
        $el = tv_interval( $heap->{last_time}, $now );
        $time .= " +"._delta_time( $el );
    }
    $heap->{last_time} = $now;
    print STDERR "$$: CHANNEL $time $when\n";
}

sub _delta_time
{
    my( $el ) = @_;

    if( $el > 1 ) {
        return sprintf( "%.3fs", $el);
    } 
    $el *= 1000;            # microseconds -> milliseconds
    if( $el > 10 ) {
        return sprintf( "%ims", int $el);
    } 
    return sprintf( "%.1gms", $el);
}

###########################################################################

1;
__END__


=head1 NAME

POE::Component::IKC::Channel - POE Inter-Kernel Communication I/O session

=head1 SYNOPSIS

    use POE;
    use POE::Component::IKC::Channel;

    POE::Component::IKC::Channel->spawn( %params );

=head1 DESCRIPTION

You will never use an IKC Channel directly.  They are created by
L<POE::Component::IKC::Server> and L<POE::Component::IKC::Client> as needed.


This module implements an POE IKC I/O.  When a new connection is
established, C<IKC::Server> and C<IKC::Client> create an C<IKC::Channel> to
handle the I/O.

IKC communication happens in 2 phases : negociation phase and normal phase.

The negociation phase uses C<Filter::Line> and is used to exchange various
parameters between kernels (example : kernel names, what type of freeze/thaw
to use, etc).  After negociation, C<IKC::Channel> switches to a
C<Filter::Reference> and creates a C<IKC::Responder>, if needed.  After
this, the channel forwards reads and writes between C<Wheel::ReadWrite> and
the Responder.  

C<IKC::Channel> is also in charge of cleaning up kernel names when
the foreign kernel disconnects.

=head1 METHODS

=head2 spawn

    POE::Component::IKC::Channel->spawn(%param);

Creates a new IKC channel to handle the negociations then the actual data.

Parameters are keyed as follows:

=over 4

=item handle

The perl handle we should hand to C<Wheel::ReadWrite::new>.

=item kernel_name

The name of the local kernel.  B<This is a stop-gap until event naming
has been resolved>.

=item on_connect

Code ref that is called when the negociation phase has terminated.  Normaly,
you would use this to start the sessions that post events to foreign
kernels.

=item subscribe

Array ref of specifiers (either foreign sessions, or foreign states) that
you want to subscribe to.  $on_connect will only be called if you can
subscribe to all those specifiers.  If it can't, it will die().

=item unix

A flag indicating that the handle is a Unix domain socket or not.

=item aliases

Arrayref of aliases for the local kernel.

=item serializers

Arrayref or scalar of the packages that you want to use for data
serialization.  A serializer package requires 2 functions : freeze (or
nfreeze) and thaw.  See C<POE::Component::IKC::Client>.

=item C<protocol>

Which IKC negociation protocol to use.  The original protocol (C<IKC>) was
synchronous and slow.  The new protocol (C<IKC0>) sends all information at
once.  IKC0 will degrade gracefully to IKC, if the client and server don't
match.

Default currently IKC but will move to IKC0 when I'm confident in the new
protocol.

=back

=head1 EVENTS

=head2 shutdown

This event causes the server to close it's socket and skiddadle on down the
road.  Normally it is only posted from IKC::Responder.

If you want to post this event yourself, you can get the channel's
session ID from IKC::Client's on_connect:

    POE::Component::IKC::Client->spawn(
        ....
            on_connect=>sub {
                $heap->{channel} = $poe_kernel->get_active_session()->ID;
            },
        ....
        );

Then, when it becomes time to disconnect:

    $poe_kernel->call($heap->{channel} => 'shutdown');

Yes, this is a hack.  A cleaner machanism needs to be provided.

=head1 EXPORTED FUNCTIONS

=head2 create_ikc_channel

Deprecated.


=head1 BUGS

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC::Server>, L<POE::Component::IKC::Client>,
L<POE::Component::IKC::Responder>


=cut


