package POE::Component::Client::opentick;
#
#   opentick.com POE client
#
#   infi/2008
#
#   $Id: opentick.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Socket;
use Carp qw( croak );
use Data::Dumper;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite
            Driver::SysRW        Filter::Stream   );

# Ours
use POE::Component::Client::opentick::Constants;
use POE::Component::Client::opentick::Util;
use POE::Component::Client::opentick::Output;
use POE::Component::Client::opentick::Error;
use POE::Component::Client::opentick::Protocol;
use POE::Component::Client::opentick::Socket;

###
### Variables
###

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE $poe_kernel );

$VERSION = '0.21';
*TRUE    = \1;
*FALSE   = \0;
*KEEP    = \0;
*DELETE  = \1;

# These arguments are for this object; pass the rest on.
my %our_args = (
    autologin       => $KEEP,
    alias           => $KEEP,
    events          => $DELETE,
    notifyee        => $DELETE,
    realtime        => $KEEP,
    debug           => $KEEP,
    quiet           => $KEEP,
);

########################################################################
###   Public methods                                                 ###
########################################################################

# Create the object and POE session instance
sub spawn
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of parameters" ) if( @args & 1 );

    # Set our default variables
    my $self = {
            READY       => OTConstant( 'OT_STATUS_INACTIVE' ),
                                        # ready to accept requests?
            debug       => $FALSE,                      # in debug mode
            quiet       => $FALSE,                      # in silent mode
            alias       => OTDefault( 'alias' ),        # our POE alias
            realtime    => OTDefault( 'realtime' ),     # RealTime quote mode
            autologin   => OTDefault( 'autologin' ),    # Auto login?
            # event callbacks
            # events => { event_id => { $sess_id => 1, ... }, ... }
            events      => {},          # event notification map
            notifyee    => undef,
            # object containers
            sock        => undef,       # Socket object
            protocol    => undef,       # Protocol object
            # Statistical information
            start_time  => time,
    };

    # Set up event hashref with all event names
    $self->{events}->{$_} = {} for( OTEventList() );

    # Create and init the object
    bless( $self, $class );
    my @leftovers = $self->initialize( @args );

    # Create the protocol handling object
    $self->{protocol} =
        POE::Component::Client::opentick::Protocol->new( @leftovers );

    # Create the socket handling object
    $self->{sock} =
        POE::Component::Client::opentick::Socket->new( @leftovers );

    # GO!
    $self->_POE_startup();

    return( $self );
}

# Initialize this object instance
sub initialize
{
    my( $self, %args ) = @_;

    # Make sure we have mandatory arguments.  I don't really like this.
    my ($key) = grep { /^notifyee$/i } keys( %args )
        or croak( 'Notifyee is a mandatory argument' );
    my $notifyee = delete( $args{$key} );
    grep { /^events$/i } keys( %args )
        or croak( 'Events is a mandatory argument' );

    # Stash our args...
    for( keys( %args ) )
    {
        if( $_ =~ /^events$/i )
        {
            croak( "Events must be an arrayref" )
                unless( ref( $args{$_} ) eq 'ARRAY' );
            $self->_reg_event( $notifyee, $args{$_} );
            delete( $args{ $_ } );
        }
        else
        {
            # grab our args
            if( exists( $our_args{lc $_} ) )
            {
                $self->{lc $_} = $args{$_};
                # delete them if appropriate
                delete( $args{ $_ } ) if( $our_args{lc $_} == $DELETE );
            }
        }
    }

    # Set the debug output flag.
    POE::Component::Client::opentick::Output->set_debug( $TRUE )
        if( $self->{debug} );
    POE::Component::Client::opentick::Output->set_quiet( $TRUE )
        if( $self->{quiet} );

    # ... and return the rest.
    return( %args );
}

sub new
{
    croak( 'Please use spawn() to create a session.' );
}

# Shut down the OT connection and POE session
sub shutdown
{
    my( $self ) = @_;

    $poe_kernel->post( $self->{alias}, 'shutdown' );

    return;
}

sub login
{
    my( $self ) = @_;

    $poe_kernel->call( $self->{alias}, '_ot_proto_issue_command',
                       OTConstant( 'OT_LOGIN' ) );

    return;
}

sub logout
{
    my( $self ) = @_;

    $poe_kernel->call( $self->{alias}, '_ot_proto_issue_command',
                       OTConstant( 'OT_LOGOUT' ) );

    return;
}

# Send an event to OT via object method
sub yield
{
    my $self = shift;

    $poe_kernel->post( $self->{alias} => @_ );

    return;
}

# Call a synchronous event in OT via object method
sub call
{
    my $self = shift;

    return( $poe_kernel->call( $self->{alias} => @_ ) );
}

# Are we ready for action?
sub ready
{
    my $self = shift;

    return( $self->{READY} == OTConstant( 'OT_STATUS_LOGGED_IN' )
            ? $TRUE
            : $FALSE );
}

# The next 3 functions are lame, added to be compatible with the otFeed API
sub set_hosts
{
    my( $self, @hosts ) = @_;
    @hosts = @{ $hosts[0] } if( ref( $hosts[0] ) eq 'ARRAY' );

    $self->{'socket'}->_set_servers( \@hosts );

    return;
}

sub set_port
{
    my( $self, $port ) = @_;

    $self->{'socket'}->_set_port( $port );

    return;
}

sub set_platform_id
{
    my( $self, $platform_id, $platform_pass ) = @_;

    $self->{protocol}->{state_obj}->_set_platform_id( $platform_id );
    $self->{protocol}->{state_obj}->_set_platform_pass( $platform_pass );

    return;
}

# return our actual state
sub get_status
{
    my( $self ) = @_;

    return( $self->{READY} );
}

# Return some statistics
# HYBRID METHOD/POE EVENT HANDLER
sub statistics
{
    my( $self ) = shift;

    my @fields = (
        $self->{sock}->get_packets_sent(),
        $self->{sock}->get_packets_recv(),
        $self->{sock}->get_bytes_sent(),
        $self->{sock}->get_bytes_recv(),
        $self->{protocol}->get_messages_sent(),
        $self->{protocol}->get_messages_recv(),
        $self->{protocol}->get_records_recv(),
        $self->{protocol}->get_errors_recv(),
        $self->get_uptime(),
        $self->{sock}->get_connect_time(),
    );

    return( @fields );
}

# Admit our age
sub get_uptime
{
    my( $self ) = shift;

    return( time - $self->{start_time} );
}

########################################################################
###   POE State handlers                                             ###
########################################################################

# Called at session start
# First callback upon POE start of this session.
sub _ot_start
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    O_DEBUG( sprintf 'Starting POE session (ID=%s)',
             $kernel->get_active_session()->ID() );

    $kernel->alias_set( $self->{alias} );
    $kernel->yield( 'connect' ) if( $self->_auto_login() );

    return;
}

# Called at session shutdown
# Final callback before shutdown
sub _ot_stop
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    O_DEBUG( "Final shutdown called.  Bye!" );

    return;
}

# Called on receipt of 'register' event
# Register a client for particular events
sub _register
{
    my( $self, $kernel, $sender, $events ) = @_[OBJECT, KERNEL, SENDER, ARG0];

    return( $self->_reg_event( $sender->ID(), $events ) );
}

# Called on receipt of 'unregister' event
# Unregister a client for particular events
sub _unregister
{
    my( $self, $kernel, $sender, $events ) = @_[OBJECT, KERNEL, SENDER, ARG0];

    return( $self->_unreg_event( $sender->ID(), $events ) );
}

# Maximum Reconnect Attempts reached.  Complain to someone.
sub _reconn_giveup
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    O_WARN( "Connection retry limit reached." );
    $kernel->yield( '_notify_of_event', OTEvent( 'OT_CONNECT_FAILED' ) );

    return;
}

# Server sent us a redirect request in OT_LOGIN response packet
sub _server_redirect
{
    my( $self, $host, $port ) = @_[OBJECT, ARG0, ARG1];

    O_NOTICE( "Server redirected us to $host:$port." );
    $self->{sock}->redirect( $host, $port );

    return;
}

# Logged in; set up heartbeat and say we're ready to go!
sub _ot_on_login
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    # Remove the connection timeout alarm.
    $kernel->alarm_remove( delete( $self->{sock}->{timeout_id} ) )
        if( $self->{sock}->{timeout_id} );

    $self->{READY} = OTConstant( 'OT_STATUS_LOGGED_IN' );
    $self->{sock}->_set_state( OTConstant( 'OT_STATUS_LOGGED_IN' ) );
    $kernel->yield( '_ot_proto_heartbeat_send' );

    return;
}

# Logged out; stop heartbeat and disable ready flag
sub _ot_on_logout
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    O_DEBUG( "We are logged out" );

    $kernel->yield( '_ot_proto_heartbeat_stop' );
    $self->{READY} = OTConstant( 'OT_STATUS_INACTIVE' );
    $self->{sock}->_set_state( OTConstant( 'OT_STATUS_INACTIVE' ) );

    return;
}

sub _status_changed
{
    my( $self, $status ) = @_[OBJECT, ARG0];

    return( $self->{READY} = $status );
}

# Pass on event notifications to their recipients
sub _notify_of_event
{
    my( $self, $kernel, $event_type, $extra_recips, @args )
                                            = @_[OBJECT,KERNEL,ARG0..$#_];
    # Resolve event properly.
    my $event = ( $event_type =~ /^\d+$/ )
                ? OTEvent( $event_type )
                : $event_type;
    my( $notify_count, %seen );

    # Prepend our extra recipients to the list, but don't send two events.
    no warnings 'uninitialized';
    my @recipients = grep { not $seen{$_}++ }
        ( @$extra_recips, keys( %{$self->{events}->{$event}} ) );

    # Send!
    for my $recipient ( @recipients )
    {
        $poe_kernel->post( $recipient, $event, @args );
        $notify_count++;
    }

    return( $notify_count );
}

### API event receiver/dispatcher
sub _api_dispatch
{
    my( $self, $kernel, $event, $sender, @args )
                        = @_[OBJECT, KERNEL, STATE, SENDER, ARG0..$#_];

    O_DEBUG( "_api_dispatch( $event ) from sender: " . $sender->ID() );

    # Find the command number, and report on irregularities.
    my ($cmd_number, $deprecated) = OTAPItoCommand( $event );
    O_WARN( "$event is deprecated by opentick; please use " . 
                        OTCommandtoAPI( $deprecated ) . " instead." )
        if( $deprecated );
    O_ERROR( "No known command mapping for $event." )
        unless( $cmd_number );
    
    # Dispatch the command
    my $retval = $kernel->call( $self->{alias}, '_ot_proto_issue_command',
                                $cmd_number,    @args )
        if( $cmd_number );

    return( $retval );
}

# Logout event trap.
sub _logged_out
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    $self->{sock}->_reset_object() if( $self and $self->{sock} );

    $self->yield( _notify_of_event => OTEvent( 'OT_ON_LOGOUT' ) );

    $self->_final_cleanup() if( $self->_is_disconnecting() );

    return;
}

# We got some unknown event.
# XXX: Perhaps we should send this back as an ot_on_error event.
sub _unknown_event
{
    my( $self, $event ) = @_[OBJECT, ARG0];

    O_DEBUG( "Unhandled event '$event'" );

    return;
}

# Do nothing, for useless events
sub _do_nothing {}

########################################################################
###   Private methods                                                ###
########################################################################

# Start me up.
sub _POE_startup
{
    my( $self ) = @_;

    POE::Session->create(
            object_states => [
                # General events for the entire interface
                $self => {
                    _start                  => '_ot_start',
                    _stop                   => '_ot_stop',
                    _default                => '_unknown_event',
                    _server_redirect        => '_server_redirect',
                    _reconn_giveup          => '_reconn_giveup',
                    _notify_of_event        => '_notify_of_event',
                    _logged_out             => '_logged_out',
                    # public sendable events
                    shutdown                => '_POE_shutdown',
                    register                => '_register',
                    unregister              => '_unregister',
                    statistics              => 'statistics',
                    # public receivable events that we need to handle, too
                    OTEvent('OT_ON_LOGIN')  => '_ot_on_login',
                    OTEvent('OT_ON_DATA')   => '_do_nothing',
                    OTEvent('OT_ON_LOGOUT') => '_do_nothing',
                    OTEvent('OT_ON_ERROR')  => '_do_nothing',
                    OTEvent('OT_REQUEST_COMPLETE')  => '_do_nothing',
                    OTEvent('OT_REQUEST_CANCELLED') => '_do_nothing',
                    OTEvent('OT_STATUS_CHANGED') => '_status_changed',
                    # API commands
                    requestSplits               => '_api_dispatch',
                    requestDividends            => '_api_dispatch',
                    requestOptionInit           => '_api_dispatch',
                    requestHistData             => '_api_dispatch',
                    requestHistTicks            => '_api_dispatch',
                    requestTickStream           => '_api_dispatch',
                    requestTickStreamEx         => '_api_dispatch',
                    requestTickSnapshot         => '_api_dispatch',
                    requestOptionChain          => '_api_dispatch',
                    requestOptionChainEx        => '_api_dispatch',
                    requestOptionChainU         => '_api_dispatch',
                    requestOptionChainSnapshot  => '_api_dispatch',
                    requestEqInit               => '_api_dispatch',
                    requestEquityInit           => '_api_dispatch', # alias
                    requestBookStream           => '_api_dispatch',
                    requestBookStreamEx         => '_api_dispatch',
                    requestHistBooks            => '_api_dispatch',
                    requestListSymbols          => '_api_dispatch',
                    requestListSymbolsEx        => '_api_dispatch',
                    requestListExchanges        => '_api_dispatch',
                    cancelTickStream            => '_api_dispatch',
                    cancelBookStream            => '_api_dispatch',
                    cancelHistData              => '_api_dispatch',
                    cancelOptionChain           => '_api_dispatch',
                },
                $self->{sock} => [
                    # Socket events
                    qw(
                        connect
                        disconnect
                        reconnect
                        _redirect
                        _ot_sock_connected
                        _ot_sock_connfail
                        _ot_sock_conntimeout
                        _ot_sock_error
                        _ot_sock_receive_packet
                        _ot_sock_send_packet
                    ),
                ],
                $self->{protocol} => [
                    # Protocol events
                    qw(
                        logout
                        login
                        _ot_proto_issue_command
                        _ot_proto_process_response
                        _ot_proto_end_of_data
                        _ot_proto_heartbeat_send
                        _ot_proto_heartbeat_stop
                    ),
                ],
                $self->{protocol}->{state_obj} => [
                    # Individual protocol message type events
                    qw(
                        _ot_msg_login_o
                        _ot_msg_generic_o
                        _ot_msg_nobody_o
                        _ot_msg_login_i
                        _ot_msg_logout_i
                        _ot_msg_single_i
                        _ot_msg_singledt_i
                        _ot_msg_multi_i
                        _ot_msg_multidt_i
                        _ot_msg_listex_i
                        _ot_msg_cancel_i
                        _ot_msg_nobody_i
                    ),
                ],
            ],
            heap => $self,
    );

    return;
}

# Shut the client down gracefully.
sub _POE_shutdown
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    $self->_is_disconnecting( $TRUE );
    $self->{sock}->disconnect();

    return;
}

# Clean up everything and die already, already.
sub _final_cleanup
{
    my( $self ) = @_;

    delete( $self->{sock} );
    delete( $self->{protocol} );
    $poe_kernel->alarm_remove_all();
    $poe_kernel->alias_remove( $self->{alias} );
    undef( $self );

    return;
}

# Register an event handler message to be sent to a session from opentick
# $events = \@aryref
sub _reg_event
{
    my( $self, $sender_id, $events ) = @_;

    my $regged = 0;
    if( $sender_id && ref( $events ) eq 'ARRAY' )
    {
        $events = [ OTEventList() ] if( grep { /^all$/i } @$events );
        for( @$events )
        {
            if( OTEventByEvent( $_ ) )
            {
                $self->{events}->{$_}->{$sender_id} = $TRUE;
                $regged++;
            }
        }
    }

    return( $regged );
}

# Register an event handler message to be sent to a session from opentick
# $events = \@aryref
sub _unreg_event
{
    my( $self, $sender_id, $events ) = @_;

    my $unregged = 0;
    if( $sender_id && ref( $events ) eq 'ARRAY' )
    {
        $events = [ OTEventList() ] if( grep { /^all$/i } @$events );
        for( @$events )
        {
            next unless( OTEventByEvent( $_ ) );
            $unregged += delete( $self->{events}->{$_}->{$sender_id} );
        }
    }

    return( $unregged );
}

#######################################################################
###  Accessor methods                                               ###
#######################################################################

sub _auto_login
{
    my( $self ) = @_;

    return( $self->{autologin} ? $TRUE : $FALSE );
}

sub _is_disconnecting
{
    my( $self, $value ) = @_;

    $self->{is_disconnecting} = $value ? $TRUE : $FALSE
        if( defined( $value ) );

    return( $self->{is_disconnecting} );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick - A POE component for working with opentick.com's market data feeds.

=head1 SYNOPSIS

 use POE qw( Component::Client::opentick );

 my $alias = 'otdemo';
 my $opentick = POE::Component::Client::opentick->spawn(
                    Username => 'MYUSER',       # REPLACE THIS
                    Password => 'MYPASS',       # REPLACE THIS
                    Events   => [ qw( all ) ],
                    Notifyee => $alias,
 );

 my $session = POE::Session->create(
     inline_states => {
         _start => sub {
             print "OT demo script starting up.\n";
             $poe_kernel->alias_set( $alias );
         },
         ot_on_login => sub {
             print "Logged in!\n";
             my $rid = $opentick->call( requestSplits =>
                                        'Q', 'MSFT',
                                        999999999, 1111111111 );
             print "ReqID $rid: requestSplits()\n";
         },
         ot_on_data  => sub {
             my ( $rid, $cmd, $record ) = @_[ARG0..$#_];
             print "ReqID $rid: Data: ", $record->as_string(), "\n";
         },
         ot_on_error => sub {
             my ( $rid, $cmd, $error ) = @_[ARG0..ARG2];
             print "ReqID $rid: Error: $error\n";
         },
     },
 );

 $poe_kernel->run();
 exit(0);

=head1 DESCRIPTION

B<POE::Component::Client::opentick> allows you to easily interface with
opentick.com's market data feed service using the power of POE to handle
the asynchronous, simultaneous requests allowed with their protocol.
This service provides both real-time and historical market data, much of
it free of charge, other data based on subscriptions.

It is primarily designed as an interface library, for example, to log to a
database, rather than a standalone client application to query market data,
although it will work fine in both regards.

B<NOTE>: This is primarily the documentation for the lower-level POE
component itself.  You may be looking for 
L<POE::Component::Client::opentick::OTClient>, which is part of this
distribution, and provides an opentick.com B<otFeed> Standard API-compatible
front-end interface for this component.

PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE PLEASE

Please read the L<FAQ|POE::Component::Client::opentick::FAQ>.  It should
answer 99% of your questions.  Then come back here for comprehensive
documentation on how to use the interface.

=head1 CONSTRUCTOR

=head2 spawn()

    my $opentick = POE::Component::Client::opentick->spawn(
            Username => 'Steve',        # Your opentick.com username
            Password => 'Zissou',       # Your opentick.com password
            Notifyee => 'myclient',     # POE alias of client session
            Events   => [ 'all' ],      # Arrayref of events to trap
    );

Spawn a new POE component, connect to the opentick server, log in, and
get ready for action.

B<ARGUMENTS:>

All arguments are of the hash form  Var =E<gt> Value.  L</spawn()> will
complain and exit if they do not follow this form.

=over 4

=item B<Username>           [ I<required> ] (but see NOTE)

=item B<Password>           [ I<required> ] (but see NOTE)

These are your login credentials for opentick.com.  If you do not have an
opentick.com account, please visit their website (L</SEE ALSO>) to create
one.  Note, that it is not necessarily a free service, but it is very
inexpensive.  (I don't work for them.)

B<NOTE:> A username and password I<MUST> be specified either as arguments
to B<spawn()> or via the L</OPENTICK_USER> and/or L</OPENTICK_PASS>
environment variables (detailed in L</ENVIRONMENT> below), or the component
complain and throw an exception.

=item B<Events>             [ I<required> ]

=item B<Notifyee>           [ I<required> ]

B<Events> is an arrayref of event notifications to send to the POE
session alias specified by B<Notifyee>.  At the occurrence of various
important events, this component will notify your session of its occurrence,
with relevant data passed as arguments.

I<Both of these are mandatory.>

For a list of events for which you can register, see the L</EVENTS> section.
The string I<'all'> works as a shortcut to just register for all events.

=item B<AutoLogin>          [ default: I<TRUE> ]

Set to automatically log into the opentick server upon POE kernel startup.

B<NOTE:> This does not affect automatic reconnection, which is set with the
B<AutoReconnect> option, and is disabled if you explicitly log out.

=item B<Realtime>           [ default: I<FALSE> ]

Request real-time quote information.  Pass in a TRUE value to enable it.
It is implemented on their service by connecting you to a different port.

=item B<RawData>            [ default: I<FALSE> ]

The default response to your queries from the opentick server comes to you
as a L<POE::Component::Client::opentick::Record> object, which has
accessor methods and additional features you can use to examine the data,
but if you prefer to receive simple @arrays, set this option to a TRUE
value.

=item B<Alias>              [ default: I<opentick> ]

The alias under which the opentick component will be registered within POE.
See the POE documentation for further details.

=item B<Servers>    [ default: I<[ feed1.opentick.com, feed2.opentick.com ]> ]

An arrayref of server hostnames with which to connect to the opentick
service.  

=item B<Port>               [ default: I<10015> ]

The port number to which to connect.  Two are default for the protocol:
10010 (realtime) and 10015 (delayed).

B<NOTE:> If you specify a Port setting, it will be used regardless;
otherwise the port is selected based on the B<Realtime> setting
(detailed next).

=item B<ConnTimeout>        [ default: I<30> ]

Timeout in seconds before declaring this connection attempt to have failed.

B<NOTE:> This also covers OT_LOGIN, so the actual timeout is from
initiating the socket connection until reaching OT_STATUS_LOGGED_IN.

=item B<AutoReconnect>      [ default: I<TRUE> ]

Boolean.  Set I<TRUE> to automatically reconnect to the server when
disconnected, I<FALSE> otherwise.

=item B<ReconnInterval>     [ default: I<60> ]

Set to the delay you wish between attempts to automatically reconnect to the
server.

Please be polite with this setting.

=item B<ReconnRetries>      [ default: I<5> ]

Set to the number of times you wish to attempt to retry before giving up.
(Set to I<0> (zero) to try to reconnect forever, waiting B<ReconnInterval>
seconds between attempts.)

=item B<BindAddress>        [ default: I<undef> ]

=item B<BindPort>           [ default: I<undef> ]

Set these if you wish to bind to a specific local address and local port
for outgoing connections, for instance, if you are running this on a
multi-homed host.  Leaving them blank will choose an arbitrary interface
and port.

Don't bother using these unless you need them.  You'll know if you do.

=item B<ProtocolVer>        [ default: I<4> ]

=item B<MacAddr>            [ default: some 3Com address ]

=item B<Platform>           [ default: I<1> (opentick) ]

=item B<PlatformPass>       [ default: I<''> ]

=item B<OS>                 [ default: I<20> (Linux) ]

Internal variables used for the opentick protocol itself.  I have set sane
defaults.  Unless you I<REALLY> know what you are doing and have read their
protocol guide thoroughly, understand it, and know the constant values for
these, just leave them alone.

If you tweak these and your account becomes disabled, don't blame me or ask
me for support with the modified settings.  Retest with the defaults.

=item B<Debug>              [ default: I<FALSE> ]

Set to enable (lots of) debugging output from this component.

=item B<Quiet>              [ default: I<FALSE> ]

Set to have the suite not print ANYTHING AT ALL (it doesn't much anyway,
but you may get the occasional warning).  The only way you will be able
to receive status from the suite is via sending and receiving POE events.

=back

B<RETURNS:> blessed I<$object>, or undef on failure.

=head2 initialize()

    $self->initialize();

Initialize the object.  If you are subclassing, overload this, not
L</spawn()>.

=head2 call()

=head2 post()

=head2 yield()

    $opentick->call( someevent => @args );
    $opentick->post( someevent => @args );
    $opentick->yield( someevent => @args );

These correspond to their POE counterparts, but automatically direct
the events to the OpenTick session instead of requiring the extra argument
of the target session (in the case of call() and post()).

They are useful as time-savers so you don't have to mess around with
locating the POE session ID, passing in the POE alias, etc.

=head2 shutdown()

Logs out and disconnects from the opentick server, closes down the OT
component, and eventually exits.  You need to remove all references to
the object in order to have it truly destroyed, of course.

After this, you must call L</spawn()> again to create a new object/session.

=head2 ready()

    my $isready = $opentick->ready();

Returns BOOLEAN depending upon whether the OT component is ready to accept
API requests (i.e., POE is running, the Session exists, is connected to
the opentick.com server, and has successfully logged in).

Polling this would be silly.  It would be better to just register to
receive the L</ot_on_login> or L</ot_status_changed> events.

=head2 statistics()

    my @stats = $opentick->statistics();

Returns some statistics about the B<$opentick> object and connection.  More
fields will be added over time, but right now it returns a list with the
following fields:

=over 4

=item 0     packets sent

=item 1     packets received

=item 2     bytes sent

=item 3     bytes received

=item 4     messages sent

=item 5     messages received

=item 6     records received

=item 7     errors received

=item 8     object lifetime (in seconds)

=item 9     opentick.com server connection time (in seconds)

=back

=head2 new()

Nothing.  Don't use this.  Use L</spawn()> instead.

=head2 get_status()

    my $status = $opentick->get_status();

Returns the current state of the object, as specified by the opentick
protocol specification.

Possible states are:

=over 4

=item 1     - OT_STATUS_INACTIVE

=item 2     - OT_STATUS_CONNECTING

=item 3     - OT_STATUS_CONNECTED

=item 4     - OT_STATUS_LOGGED_IN

=back

See L<POE::Component::Client::opentick::Constants> for more information.

=head2 get_uptime()

    my $uptime = $opentick->get_uptime();

Returns object lifetime in seconds.

=head2 login()

    $opentick->login();

Begin the login process.

=head2 logout()

    $opentick->logout();

Log out from the opentick server, and disconnect the socket.

=head2 set_hosts()

=head2 set_port()

=head2 set_platform_id()

These exist solely for higher-level compatibility with the B<otFeed> Standard
API.  Don't use them.  Pass arguments to the object constructor L</spawn()>
instead.

=head1 EVENTS

To do anything useful with this module, you must register to receive events
upon important occurrences.  You do this either by using the Events =E<gt> []
argument to L</spawn()> (preferred), or by sending a 'register' event to the
object using POE, with an \@arrayref argument containing the list of events
for which you wish to register.

All events sent to your session will receive I<at least> the following two
arguments:

 ( $request_id, $command_id ) = @_[ARG0,ARG1];

Specific events will also have more arguments.  If an event receives
different or additional arguments, they will be listed and described.

Below is a list of events for which you may register:

=head3 all

A time saver.  Registers to receive all events.  You don't even have to
set up handlers for all of them, just the ones you want.

=head3 ot_on_login

Sent upon successful login to the opentick.com server.

=head3 ot_on_logout

Sent upon logout from the opentick.com server.

=head3 ot_on_data

Sent upon the receipt of data from a request you have placed.

Extra arguments: ( @data ) = @_[ARG2..$#_]

I<@data> corresponds to the individual fields of the particular API call for
which this is a response to.  For more information on the API calls, see the
L</OPENTICK API> section below, as well as the L<http://www.opentick.com/>
home page and documentation wiki.

=head3 ot_on_error

Sent upon any type of error.

Extra arguments: ( $Error ) = @_[ARG2]

I<$Error> is an object of type L<POE::Component::Client::opentick::Error>,
and contains detailed information about the error, at what point it occurred,
etc.

However, the object's I<stringify()> method is overloaded, so it prints a
meaningful and complete error message if you simply call something similar
to C<print "$Error">.

For more detailed documentation, see
L<POE::Component::Client::opentick::Error>.

=head3 ot_request_complete

Sent upon the completion of a request.

=head3 ot_request_cancelled

Sent upon the successful cancellation of a request.

=head3 ot_connect_failed

Sent upon failed connection and exhaustion of all retry attempts.

=head3 ot_status_changed

Sent upon any status change; will be sent as a duplicate request, alongside
(but slightly later than) L</ot_on_login>.

Primarily exists for compatibility with OTClient.pm, but traps I<all> status
changes; not just login and logout.

=head1 OPENTICK API

The opentick.com API provides several commands that you may send.  All of the
API requests return a unique numeric I<$request_id> for the particular command
you issue.  You properly send these commands by using the L</call()>
method (or the I<$poe_kernel-E<gt>call()> method with the session ID of the
component), so that you receive a numeric I<$request_id> as a return value.
L</yield()> and L</post()> are asynchronous, and do not return a
I<$request_id>.

Because opentick is an asychronous protocol and allows multiple requests at
once, B<getting this $request_id into your client is essential, to keep
track of and match particular requests with their corresponding responses.>

It is left as an exercise to the implementor (YOU!) as to how best keep
track of these, although a I<%hash> would work quite well.  See the
B<examples/> directory of this distribution for some examples of how to do
this, if you are not sure.

I don't explain their protocol completely in this document.  A link to their
documentation is found under L</SEE ALSO>.

=head2 Arguments

Most commands take at least the following two arguments:

=over 4

=item I<$exchange>     = STRING

The corresponding exchange code in the opentick.com format.

See L<http://www.opentick.com/dokuwiki/doku.php?id=general:exchange_codes>
for details.

=item I<$symbol>       = STRING

The corresponding symbol in the opentick.com format.

Use L</requestListSymbols> if you actually want a list, otherwise these just
generally correspond to the equity/security symbol from the exchange.

See L<http://www.opentick.com/dokuwiki/doku.php?id=general:symbol_formats>
for details.

=back

=head2 Other Common Arguments

=over 4

=item I<$startDate>    = EPOCH DATE

=item I<$endDate>      = EPOCH DATE

The time, in seconds, since Jan 1, 1970 00:00:00 UTC.  This is the standard
UNIX time format, as returned by the Perl function B<time()>.

Including Date/Time conversion routines in this component is out of scope.
Please read L<POE::Component::Client::opentick::FAQ/Why do you only accept UNIX epoch dates?>.

=item I<$expMonth>     = INTEGER (1-12)

=item I<$expYear>      = INTEGER (4-DIGIT YEAR)

Expiration month and year, as appropriate to the particular request.

=item I<$request_id>   = INTEGER

A numeric request, as previously returned from an API call.  Usually used
for stream cancellation.

=item I<$minStrike>    = REAL

=item I<$maxStrike>    = REAL

The minimum and maximum strike prices for which you wish to filter.

=back

Most other arguments take a range of constants.  See the L<opentick API documentation|http://www.opentick.com/dokuwiki/doku.php?id=general:standard> for further details.

=head2 Issuable Events

Here are the API-related events that you can issue to the POE component,
which correspond to the opentick.com API:

=head3 requestSplits

ARGUMENTS: ( $exchange, $symbol, $startDate, $endDate );

=head3 requestDividends

ARGUMENTS: ( $exchange, $symbol, $startDate, $endDate );

=head3 requestOptionInit

ARGUMENTS: ( $exchange, $symbol, $expMonth, $expYear, $minStrike,
$maxStrike, $paramsType );

=head3 requestHistData

ARGUMENTS: ( $exchange, $symbol, $startDate, $endDate, $datatype, $interval );

=head3 requestHistTicks

ARGUMENTS: ( $exchange, $symbol, $startDate, $endDate, $mask );

=head3 requestTickSnapshot

ARGUMENTS: ( $exchange, $symbol, $mask );

=head3 requestOptionChainU

ARGUMENTS: ( $exchange, $symbol, $expMonth, $expYear, $mask, $minStrike,
$maxStrike, $paramsType );

=head3 requestOptionChainSnapshot

ARGUMENTS: ( $exchange, $symbol, $expMonth, $expYear, $mask, $minStrike,
$maxStrike, $paramsType );

=head3 requestEquityInit

ARGUMENTS: ( $exchange, $symbol );

=head3 requestBookStream

ARGUMENTS: ( $exchange, $symbol );

=head3 requestBookStreamEx

ARGUMENTS: ( $exchange, $symbol, $mask );

=head3 requestHistBooks

ARGUMENTS: ( $exchange, $symbol, $startDate, $endDate, $mask );

=head3 requestTickStream

ARGUMENTS: ( $exchange, $symbol );

B<NOTE:> Deprecated by opentick.com; use L</requestTickStreamEx> instead.

=head3 requestTickStreamEx

ARGUMENTS: ( $exchange, $symbol, $mask );

=head3 requestOptionChain

ARGUMENTS: ( $exchange, $symbol, $expMonth, $expYear );

B<NOTE:> Deprecated by opentick.com; use L</requestOptionChainEx> instead.

=head3 requestOptionChainEx

ARGUMENTS: ( $exchange, $symbol, $expMonth, $expYear, $mask );

=head3 requestListExchanges

ARGUMENTS: ( NONE! )

NOTE: You will I<NOT> receive an L</ot_request_complete> event upon
completion of this command.

=head3 requestListSymbols

ARGUMENTS: ( $exchange );

NOTE: You will I<NOT> receive an L</ot_request_complete> event upon
completion of this command.

=head3 requestListSymbolsEx

ARGUMENTS: ( $exchange, $symbol, $mask );

I<$symbol> in this instance acts as a filter, matching specified symbols as
either a whole or a substring (depending on the value of $mask).

NOTE: You will I<NOT> receive an L</ot_request_complete> event upon
completion of this command.

=head3 cancelTickStream

ARGUMENTS: ( $request_id )

=head3 cancelBookStream

ARGUMENTS: ( $request_id )

=head3 cancelOptionChain

ARGUMENTS: ( $request_id )

=head3 cancelHistData

ARGUMENTS: ( $request_id )

More information regarding the opentick API, exchange codes, field
definitions, etc., can be found at L<http://www.opentick.com>.

B<NOTE:> Several of the opentick API commands return different than expected
values for I<CommandType>.  Generally, these are commands that were implemented
later, that extend functionality of earlier commands, and they return
their base types.  For example, L</requestTickStreamEx> (cid=16) returns a
I<CommandType> of 3 (L</requestTickStream>).  You should keep this in mind
when writing your result handlers.  I could program around it, and I may in
a later version, but as long as you keep track of requests by I<$requestID>
instead of I<CommandType> (which you should anyway), it should not pose a
problem.

=head1 ENVIRONMENT

This module suite uses the following environment variables:

=head3 OPENTICK_USER

=head3 OPENTICK_PASS

These are used as a fallback mechanism, in case Username or Password are
not passed as arguments to L</spawn()>.  If after exhausting these two
possibilities, the username and password are not set, the suite will throw
an exception and exit.

They are also provided as a security option, since many people do not desire
to store passwords directly in their software.

=head3 OPENTICK_LIB

This is used in the official opentick B<otFeed> Standard API software.
This module suite will also use this environment variable when attempting
to locate the original opentick library, to preload constant values used
in the protocol.

L<POE::Component::Client::opentick::Constants> attempts to load the
original libraries from I<@INC>, and will prepend the directory specified in
B<OPENTICK_LIB> to the I<@INC> search path, if it is set.

If the original libraries are not found, this is not a problem; we use our
own values.  This is only an attempt to maintain derived compatibility with
the mainline software itself should they suddenly change features between
versions of this software.

=head1 LOGGING OUT AND SIGNALS

It would be polite to opentick.com, and follow their protocol, if you ensured
that you always logged out before actually exiting your client application.
I have included several methods of doing so, but I am hesitant to include a
signal handler in this module, as that is really the responsibility of your
client application.

An easy way to do this would be to use a signal handler similar to the
following, to trap SIGINT, and repeat for whichever other signals you wish
to trap:

    $poe_kernel->sig( INT  => 'event_quit' );
    $poe_kernel->sig( TERM => 'event_quit' );

    sub event_quit {
        $opentick->call( 'shutdown' );
        $poe_kernel->alias_remove( 'your_alias' );
        exit(1);
    }

More information about POE's signal handling can be found at
L<POE::Kernel/"Signal Watcher Methods">.

While testing, they did not seem to mind me disconnecting improperly several
times until I had finished the logout code, but I have no control over their
decision-making process, and this could change at any time.

If your account gets banned, don't cry to me.

=head1 SEE ALSO

L<POE::Component::Client::opentick::FAQ>

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - All about the Perl Object Environment (POE)

L<http://www.opentick.com/> - The official opentick site

L<http://www.opentick.com/dokuwiki/doku.php> - opentick.com's documentation

The examples/ directory of this module's distribution.

=head1 ACKNOWLEDGEMENTS

Thank you, Rocco Caputo (dngor) for inventing and unleashing POE upon the
world!

=head1 AUTHOR

Please kindly read the L<FAQ|POE::Component::Client::opentick::FAQ> before
emailing me with questions.  Your answer is probably in there.

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

The data from opentick.com are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the opentick.com and exchange license agreements with the data.

Further details are available on L<http://www.opentick.com/>.

=cut

