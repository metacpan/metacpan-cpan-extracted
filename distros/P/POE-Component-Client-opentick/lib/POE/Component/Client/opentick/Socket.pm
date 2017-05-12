package POE::Component::Client::opentick::Socket;
#
#   opentick.com POE client
#
#   Socket handling
#
#   infi/2008
#
#   $Id: Socket.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( croak );
use Data::Dumper;
use Socket;
use POE qw( Wheel::SocketFactory    Wheel::ReadWrite
            Driver::SysRW           Filter::Stream   );

# Ours
use POE::Component::Client::opentick::Constants;
use POE::Component::Client::opentick::Util;
use POE::Component::Client::opentick::Output;
use POE::Component::Client::opentick::Error;

###
### Variables
###

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE $poe_kernel );

($VERSION) = q$Revision: 56 $ =~ /(\d+)/;
*TRUE      = \1;
*FALSE     = \0;
*KEEP      = \0;
*DELETE    = \1;

# Arguments are for this object.
my %valid_args = (
    alias           => $KEEP,
    debug           => $KEEP,
    servers         => $DELETE,
    port            => $DELETE,
    realtime        => $DELETE,
    conntimeout     => $DELETE,
    autoreconnect   => $DELETE,
    reconninterval  => $DELETE,
    reconnretries   => $DELETE,
    bindaddress     => $DELETE,
    bindport        => $DELETE,
);

########################################################################
###   Public methods                                                 ###
########################################################################

sub new
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of parameters" ) if( @args & 1 );

    my $self = {
        alias           => OTDefault( 'alias' ),
        debug           => $FALSE,
        servers         => undef,
        myserver        => undef,
        port            => undef,
        state           => OTConstant( 'OT_STATUS_INACTIVE' ),
        realtime        => OTDefault( 'realtime' ),
        redirected      => $FALSE,      # were we redirected?
        # For reconnection logic
        conntimeout     => OTDefault( 'conntimeout' ),
        autoreconnect   => OTDefault( 'autoreconnect' ),
        reconninterval  => OTDefault( 'reconninterval' ),
        reconnretries   => OTDefault( 'reconnretries' ),
        reconncount     => 0,
        bindaddress     => undef,
        bindport        => undef,
#        'socket'        => undef,
        socket_buffer   => [],      # outgoing socket FIFO
        # Statistical parameters
        packets_sent    => 0,
        packets_recv    => 0,
        bytes_sent      => 0,
        bytes_recv      => 0,
        connect_time    => 0,
    };

    bless( $self, $class );

    $self->initialize( @args );

    return( $self );
}

# Initialize this object instance
sub initialize
{
    my( $self, %args ) = @_;

    # Store things.  Things that make us go. 
    # We're a leaf node; go ahead and delete.
    for( keys( %args ) )
    {
        $self->{lc $_} = delete( $args{ $_ } )
                            if( exists( $valid_args{lc $_} ) );
    }

    $self->{servers} = $self->_get_server_list( $self->{servers} );
    $self->{port}    = $self->_get_port( $self->{port} );

    return;
}

# High level manual disconnect method
#   NOTE: HYBRID POE EVENT HANDLER/METHOD
sub disconnect
{
    my( $self ) = @_;

    $self->_pause_autoreconnect();
    $self->_reset_reconn_count();

    # Step through and back out for each step.
    my $state = $self->_get_state();
    if( $state >= OTConstant( 'OT_STATUS_LOGGED_IN' ) )
    {
        $poe_kernel->call( $self->{alias}, 'logout' );
    }
    else
    {
        if( $state >= OTConstant( 'OT_STATUS_CONNECTED' ) )
        {
            # Disconnect.  This should do it.
            delete( $self->{socket} );
        }
        if( $state >= OTConstant( 'OT_STATUS_CONNECTING' ) )
        {
            # Cancel connection and clean up
            delete( $self->{SocketFactory} );
            $self->{myserver} = undef;
        }
        $self->_set_state( OTConstant( 'OT_STATUS_INACTIVE' ) );
#        $self->_set_redirected_flag( $FALSE );
    }


    return;
}

# High level reconnect method
sub reconnect
{
    my( $self ) = @_;

    $poe_kernel->yield( 'disconnect' );
    $poe_kernel->yield( 'connect' );

    return;
}

# High level redirect METHOD (only)
#   Server can send host redirect response; we must comply.
#   High priority, so we call it synchronously.
sub redirect
{
    my( $self, $host, $port ) = @_;

    $self->_set_redirected_flag( $TRUE );
    $poe_kernel->call( $poe_kernel->get_active_session(), 'disconnect' );
    $poe_kernel->call( $poe_kernel->get_active_session(),
                       'connect', $host, $port );

    return;
}

### Statistical accessors

sub get_packets_recv
{
    my( $self ) = @_;

    return( $self->{packets_recv} );
}

sub get_packets_sent
{
    my( $self ) = @_;

    return( $self->{packets_sent} );
}

sub get_bytes_recv
{
    my( $self ) = @_;

    return( $self->{bytes_recv} );
}

sub get_bytes_sent
{
    my( $self ) = @_;

    return( $self->{bytes_sent} );
}

sub get_connect_time
{
    my( $self ) = @_;

    return( $self->{connect_time} ? time - $self->{connect_time} : 0 );
}

########################################################################
###   POE event handlers                                             ###
########################################################################

# Public event handlers

# quick event handler to marshal args over to redirect method
sub _redirect
{
    my( $self, $host, $port ) = @_[OBJECT,ARG0,ARG1];

    $self->redirect( $host, $port );

    return;
}

# Connect to the OT server
sub connect
{
    my( $self, $kernel, $host, $port ) = @_[OBJECT,KERNEL,ARG0,ARG1];

    if( $self->_get_state() == OTConstant( 'OT_STATUS_INACTIVE' ) )
    {
        $self->_reset_autoreconnect();

        $self->{myserver} = $host || $self->_get_server();
        O_NOTICE( "Connecting to " . $self->{myserver} . "..." );

        my $wheel = POE::Wheel::SocketFactory->new(
            SocketDomain        => AF_INET,
            SocketType          => SOCK_STREAM,
            SocketProtocol      => 'tcp',
            BindAddress         => $self->{bindaddress},
            BindPort            => $self->{bindport},
            Reuse               => $TRUE,
            RemoteAddress       => $self->{myserver},
            RemotePort          => $port || $self->_get_port(),
            SuccessEvent        => '_ot_sock_connected',
            FailureEvent        => '_ot_sock_connfail',
        );
        $self->{SocketFactory} = $wheel;

        $self->_set_state( OTConstant( 'OT_STATUS_CONNECTING' ) );

        if( $self->_get_conn_timeout() )
        {
            $kernel->alarm_remove( delete( $self->{timeout_id} ) )
                if( $self->{timeout_id} );
            $self->{timeout_id}
                = $kernel->alarm_set( '_ot_sock_conntimeout',
                                      time + $self->_get_conn_timeout() );
        }
    }

    return;
}

### Connection initiation handling

# Successfully connected!
sub _ot_sock_connected
{
    my( $self, $kernel, $socket ) = @_[OBJECT, KERNEL, ARG0];

    my ($port, $addr) = sockaddr_in( getpeername( $socket ) );

    O_NOTICE( sprintf( "Connected to %s [%s]:%s.",
                       scalar( gethostbyaddr( $addr, AF_INET ) ),
                       inet_ntoa( $addr ), $port ) );

    # We don't need no steenkeen factory anymore.
    delete( $self->{SocketFactory} );

    # Leave the alarm removal until opentick.pm:_logged_in().
#    $kernel->alarm_remove( delete( $self->{timeout_id} ) )
#        if( $self->{timeout_id} );

    # Create the socket handler.
    $self->{'socket'} = POE::Wheel::ReadWrite->new(
        Handle          => $socket,
        Driver          => POE::Driver::SysRW->new(),
        Filter          => POE::Filter::Stream->new(),
        InputEvent      => '_ot_sock_receive_packet',
        ErrorEvent      => '_ot_sock_error',
    );

    # Set the state variables
    $self->_reset_object();
    $self->_set_connect_time( time );

    # Send login command
    $self->_set_state( OTConstant( 'OT_STATUS_CONNECTED' ) );
    $kernel->call( $kernel->get_active_session(),
                   '_ot_proto_issue_command',
                   OTConstant( 'OT_LOGIN' ) );

    # Flush queue, if we have queued up commands
    $self->_flush_queue();

    return;
}

# Connection failed for whatever reason.
sub _ot_sock_connfail
{
    my( $self, $kernel, $op, $err_code, $err_str, $wheel )
                                        = @_[OBJECT, KERNEL, ARG0..ARG3];

    O_DEBUG( "Connection failed.  $op() returned $err_code: $err_str" );
    delete( $self->{'socket'} );

    retry_connect( @_ );
}

# Connection timed out.
sub _ot_sock_conntimeout
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    O_DEBUG( "Connection timed out." );
    delete( $self->{'socket'} );

    retry_connect( @_ );
}

# Retry a connection ReconnRetries times, or give up.
sub retry_connect
{
    my( $self, $kernel ) = @_[OBJECT, KERNEL];

    # Fix our states
    $self->_set_state( OTConstant( 'OT_STATUS_INACTIVE' ) );
    $kernel->alarm_remove( delete( $self->{timeout_id} ) )
        if( exists( $self->{timeout_id} ) );

    # Retry
    if( $self->_get_autoreconnect() )
    {
        if( $self->_inc_reconn_count() < $self->_get_reconn_retries() or
            $self->_get_reconn_retries() == 0 )
        {
            my $timeout = $self->_get_reconn_interval();
            O_DEBUG( "Retrying connection in $timeout seconds..." );
            $kernel->delay( 'connect', $timeout );
        }
        else
        {
            delete( $self->{SocketFactory} );
            $kernel->yield( '_reconn_giveup', @_[ARG0..$#_] );
        }
    }

    return;
}

# A socket error has occurred.
sub _ot_sock_error
{
    my( $self, $kernel, $op, $err_code, $err_str, $wheel )
                                        = @_[OBJECT,KERNEL,ARG0..ARG3];

    O_DEBUG( "Socket disconnected: $op() returned $err_code: $err_str" );

    # Socket disconnected
    if( $op eq 'read' && $err_code == 0 )
    {
        # Stop heartbeats immediately and synchronously.
        $kernel->yield( '_ot_proto_heartbeat_stop' );

        $self->_reset_object();
        delete( $self->{'socket'} );

        retry_connect( @_ );
    }

    return;
}

### Live connection handling

# Got a packet!
sub _ot_sock_receive_packet
{
    my( $self, $kernel, $packet ) = @_[OBJECT, KERNEL, ARG0];

    O_DEBUG( "_ot_sock_receive_packet( " . length( $packet ) . " )" );

    # Tell the protocol handler we got a packet
    $kernel->yield( '_ot_proto_process_response', $packet );

    $self->_update_stats_recv( length( $packet ) );

    return;
}

# Send a packet!
sub _ot_sock_send_packet
{
    my( $self, $packet ) = @_[OBJECT, ARG0];

    # Put the packet on the wire, or enqueue
    my $buffered = $self->_put_or_enqueue( $packet );

    # Update the stats if appropriate
    $self->_update_stats_sent( length( $packet ) ) unless( $buffered );

    O_DEBUG( sprintf "_ot_sock_send_packet( %d ): %s",
                     length( $packet ),
                     $buffered ? "buffered" : "sent" );

    return( $buffered ? $TRUE : $FALSE );
}

########################################################################
###   Private methods                                                ###
########################################################################

# Return the correct port for initialization based on user preferences
sub _get_port
{
    my( $self, $user_port ) = @_;

    my $port = ( defined( $user_port ) && $user_port =~ /^\d+/ )
               ? $user_port
               : $self->{port}
                 ? $self->{port}
                 : $self->{realtime}
                   ? OTDefault( 'port_realtime' )
                   : OTDefault( 'port_delayed' );

    return( $port );
}

# Return the server list for initialization based on user preferences
sub _get_server_list
{
    my( $self, $user_list ) = @_;

    my $servers = ( defined( $user_list ) && ref( $user_list ) eq 'ARRAY' )
                  ? $user_list
                  : $self->{servers}
                    ? $self->{servers}
                    : $self->{realtime}
                      ? OTDefault( 'servers_realtime' )
                      : OTDefault( 'servers_delayed' );

    return( $servers );
}

sub _set_servers
{
    my( $self, $user_list ) = @_;

    $self->{servers} = $user_list;

    return;
}

sub _set_port
{
    my( $self, $port ) = @_;

    return( $self->{port} = $port );
}

# Get one of the servers from our server list round-robin
{ # CLOSURE
my $server_num = 0;
sub _get_server
{
    my( $self ) = @_;

    my $server  = $self->{servers}->[ $server_num++ ];
    $server_num = 0 if $server_num > $#{ $self->{servers} };

    return( $server );
}
} # /CLOSURE

### Accessor methods

# The USER variable setting the number of retries to attempt
sub _get_reconn_retries
{
    my( $self ) = @_;

    return( $self->{reconnretries} );
}

sub _get_state
{
    my( $self ) = @_;

    return( $self->{state} );
}

sub _set_state
{
    my( $self, $state ) = @_;

    throw( O_ERROR( 'Tried to set invalid state: ' . $state ) )
        if( $state < OTConstant( 'OT_STATUS_INACTIVE') ||
            $state > OTConstant( 'OT_STATUS_LOGGED_IN' ) );

    $poe_kernel->yield( '_notify_of_event',
                        OTEvent( 'OT_STATUS_CHANGED' ),
                        [ $self->{alias} ],
                        $state );

    return( $self->{state} = $state );
}

sub _set_redirected_flag
{
    my( $self, $value ) = @_;

    $self->{redirected} = defined( $value )
                          ? $value ? $TRUE : $FALSE
                          : $TRUE;
}

sub _is_redirected
{
    my( $self ) = @_;

    return( $self->{redirected} );
}

# The ACTUAL count of retry attempts
sub _reset_reconn_count
{
    my( $self ) = @_;

    return( $self->{reconncount} = 0 );
}

# The ACTUAL count of retry attempts
sub _inc_reconn_count
{
    my( $self ) = @_;

    return( ++$self->{reconncount} );
}

# The ACTUAL count of retry attempts
sub _get_reconn_count
{
    my( $self ) = @_;

    return( $self->{reconncount} );
}

sub _get_autoreconnect
{
    my( $self ) = @_;

    return( $self->{autoreconnect} );
}

sub _set_autoreconnect
{
    my( $self, $value ) = @_;

    $self->{autoreconnect} = $value ? $TRUE : $FALSE;

    return;
}

sub _get_conn_timeout
{
    my( $self ) = @_;

    return( $self->{conntimeout} );
}

sub _get_reconn_interval
{
    my( $self ) = @_;

    return( $self->{reconninterval} );
}

# Put or enqueue user-requested sent packets to FIFO
sub _put_or_enqueue
{
    my( $self, $packet ) = @_;

    my $buffered;
    if( $self->{'socket'} )
    {
        $buffered = $self->{'socket'}->put( $packet );
    }
    else
    {
        push( @{ $self->{socket_buffer} }, $packet );
        $buffered = $TRUE;
    }

    return( $buffered );
}

# Flush queue of user-requested sent packets, when connected.
sub _flush_queue
{
    my( $self ) = @_;

    return undef unless( $self->{'socket'} );

    my $count;
    if( $count = @{ $self->{socket_buffer} } )
    {
        $self->{'socket'}->put( @{ $self->{socket_buffer} } );
        $self->_update_stats_sent(
                  length( join( '', @{ $self->{socket_buffer} } ) )
        );
        $self->{socket_buffer} = [];        # clear buffer
        O_DEBUG( $count . " buffered packets sent." );
    }

    return( $count );
}

# Pause the autoreconnect state; save the current value
sub _pause_autoreconnect
{
    my( $self ) = @_;

    # make idempotent
    return if( $self->{autoreconnbak} );

    $self->{autoreconnbak} = $self->_get_autoreconnect();
    $self->_set_autoreconnect( $FALSE );

    return;
}

# Restore the autoreconnect state
sub _reset_autoreconnect
{
    my( $self ) = @_;

    if( exists( $self->{autoreconnbak} ) )
    {
        $self->_set_autoreconnect( $self->{autoreconnbak} );
        delete( $self->{autoreconnbak} );
    }

    return;
}

### Statistics logging

sub _update_stats_recv
{
    my( $self, $bytes ) = @_;

    $self->_inc_bytes_recv( $bytes );
    $self->_inc_packets_recv();

    return;
}

sub _update_stats_sent
{
    my( $self, $bytes ) = @_;

    $self->_inc_bytes_sent( $bytes );
    $self->_inc_packets_sent();

    return;
}

sub _reset_stats_recv
{
    my( $self ) = @_;

    $self->{packets_recv} = 0;
    $self->{bytes_recv}   = 0;

    return;
}

sub _reset_stats_sent
{
    my( $self ) = @_;

    $self->{packets_sent} = 0;
    $self->{bytes_sent}   = 0;

    return;
}

sub _inc_bytes_recv
{
    my( $self, $num ) = @_;

    return( $self->{bytes_recv} += $num || 1 );
}

sub _inc_bytes_sent
{
    my( $self, $num ) = @_;

    return( $self->{bytes_sent} += $num || 1 );
}

sub _inc_packets_recv
{
    my( $self, $num ) = @_;

    return( $self->{packets_recv} += $num || 1 );
}

sub _inc_packets_sent
{
    my( $self, $num ) = @_;

    return( $self->{packets_sent} += $num || 1 );
}

sub _set_connect_time
{
    my( $self, $value ) = @_;

    return( $self->{connect_time} = $value || time );
}

sub _reset_object
{
    my( $self ) = $_[OBJECT];
    return if( $self->_get_state() == OTConstant( 'OT_STATUS_INACTIVE' ) );
    
#    $self->_set_state( OTConstant( 'OT_STATUS_INACTIVE' ) );
    $self->_set_connect_time( 0 );
    $self->{myserver} = undef;
#    $self->_set_redirected_flag( $FALSE );
    $self->_reset_reconn_count();
#    $self->_reset_stats_sent();
#    $self->_reset_stats_recv();

    return;
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Socket - Socket handling routines for the opentick POE component.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Socket;

=head1 DESCRIPTION

See L<POE::Component::Client::opentick> for the main documentation.

=head1 METHODS

=over 4

=item B<new( )>

=item B<initialize( %args )>

=item B<connect( )>

Connect.

=item B<disconnect( )>

Disconnect.

=item B<reconnect( )>

Yep.

=item B<redirect( )>

Called when redirected by server.

=item B<retry_connect( )>

=item B<get_bytes_recv( )>

=item B<get_bytes_sent( )>

=item B<get_packets_recv( )>

=item B<get_packets_sent( )>

=item B<get_connect_time( )>

Statistical information.  Just read the main docs, already.

=back

=head1 AUTHOR

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

