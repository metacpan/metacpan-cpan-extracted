package POE::Component::Client::opentick::Protocol;
#
#   opentick.com POE client
#
#   Protocol handling (only operates on data, no socket handling)
#
#   infi/2008
#
#   $Id: Protocol.pm 56 2009-01-08 16:51:14Z infidel $
#
#   See docs/implementation-notes.txt for a detailed explanation of how
#     this module works.
#
#   Full user POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( croak );
use Data::Dumper;
use POE;

# Ours.
use POE::Component::Client::opentick::Constants;
use POE::Component::Client::opentick::Util;
use POE::Component::Client::opentick::Output;
use POE::Component::Client::opentick::Error;
use POE::Component::Client::opentick::ProtocolMsg;

###
### Variables
###

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE $poe_kernel );

($VERSION) = q$Revision: 56 $ =~ /(\d+)/;
*TRUE      = \1;
*FALSE     = \0;
*KEEP      = \0;
*DELETE    = \1;

# These arguments are for this object; pass the rest on.
my %valid_args = (
    alias           => $KEEP,
    debug           => $KEEP,
    rawdata         => $KEEP,
);

my $state_base = 'POE::Component::Client::opentick::ProtocolMsg';

########################################################################
###   Public methods                                                 ###
########################################################################

sub new
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of parameters" ) if( @args & 1 );

    my $self = {
        # User prefs
        alias           => OTDefault( 'alias' ),
        rawdata         => $FALSE,      # user prefers to receive raw response
                                        # data instead of ::Record objects
        debug           => $FALSE,
        # Protocol settings
        heartbeat       => OTDefault( 'heartbeat' ),    # beat delay in secs
        request_timeout => OTDefault( 'request_timeout' ), # request timeout
        # Protocol state
        requests        => {},          # outstanding requests keyed on ID
                                        #   stamp       = timestamp
                                        #   cmd_id      = command ID
                                        #   respcount   = response count
                                        #   cancel_rqid = cancel request ID
                                        #   sender      = sender POE ID
        partial_data    => '',          # stash incomplete <Message>s
        # Object containers
        state_obj       => undef,       # object reference for ProtocolMsg
#        handlers        => {},          # loaded ProtocolMsg subclasses
        # Statistical information
        messages_sent   => 0,
        messages_recv   => 0,
        records_recv    => 0,
        errors_recv     => 0,
    };

    bless( $self, $class );

    my @leftovers = $self->initialize( @args );

    # Create a protocol state handler object with the leftover args
    $self->{state_obj} =
        POE::Component::Client::opentick::ProtocolMsg->new( @leftovers );

#    $self->_load_handler_subclasses();

    return( $self );
}

# Initialize this object instance
sub initialize
{
    my( $self, %args ) = @_;

    # Keep our things...
    for( keys( %args ) )
    {
        # grab them regardless
        $self->{lc $_} = $args{$_} if( exists( $valid_args{lc $_} ) );
        # delete them if true
        delete( $args{ $_ } )      if( $valid_args{lc $_} );
    }

    # ... return the rest.
    return( %args );
}

# Construct a packet, register the request, and put the data on the wire
# XXX: Should we throttle outstanding requests here?
sub prepare_packet
{
    my( $self, $sender_id, $cmd_id, @fields ) = @_;

    # Abort packet sending if non-existent request cancelled
    if( OTCancel( $cmd_id ) && !$self->_request_exists( $fields[0] ) )
    {
        $self->_send_notification(
            POE::Component::Client::opentick::Error->new(
                            CommandID   => $cmd_id,
                            Message     => 'No such request: ' . $fields[0],
            )
        );
        return;
    }

    my $req_id = $self->_add_request( $sender_id, $cmd_id );
    my $packet = $self->_create_packet( $req_id, $cmd_id, @fields );

    $self->_inc_messages_sent();

    # Stash cancellation request ID for return packet
    $self->_set_request_cancel_id( $req_id, $fields[0] )
        if( OTCancel( $cmd_id ) );

    return( $packet, $req_id );
}

# Handle and examine received packets
#
#   This is complex, so here's the explanation:
#   1. If there is partial data stored from a previous run, prepend it.
#   2. Check the message length field.
#   3. If the data is still shorter than the message length, store as
#         partial data for next loop and exit.
#   4. If it is long enough or longer, break off MsgLen bytes and process
#         them, returning the remainder of the data to the caller.
#   5. Rinse and repeat (called in loop from caller).
#
#   This is because the server can send packets that are smaller than a
#   <Message>, the exact size of one <Message>, or containing multiple
#   records per <Message> or multiple <Message>s per packet.
#
sub process_packet
{
    my( $self, $data ) = @_;

    O_DEBUG( "process_packet( " . length( $data ) . " )" );

    # prepend the last packet received to the partial data, if apropo
    $data = $self->_get_partial_data() . $data;
    $self->_set_partial_data( undef );

    # check our length
    my $msg_len = _get_message_length( $data );

    my( $leftover, $objects );
    # Check if this packet contains a complete response
    if( length( $data ) < ( $msg_len + 4 ) )
    {
        O_DEBUG( "  packet not large enough; stashing." );
        # Not large enough, stash it for next time.
        $self->_set_partial_data( $data );
        return ();
    }
    else    # OK DESU.
    {
        my( $cmd_sts, $cmd_id, $req_id );

        O_DEBUG( "  packet large enough; processing." );
        # don't drop anything, store it for the next
        $leftover = substr( $data, $msg_len + 4 );

        $self->_inc_messages_recv();

        # only work with one message, minus MessageLength
        $data = substr( $data, 4, $msg_len );

        my( $msg_type );
        ( $msg_type, $cmd_sts, $cmd_id, $req_id )   
                                            = _process_header( $data );

        # Drop message if invalid header or request_id not found
        return( $leftover )
            unless $self->_validate_header( $msg_type, $cmd_sts,
                                            $cmd_id,   $req_id );

        # chomp the header off, left only with the body.
        $data = substr( $data, 12, $msg_len - 12 );

        # Everything is ready, process the body or notify of error
        if( $cmd_sts == OTConstant( 'OT_STATUS_ERROR' ) )
        {
            push( @$objects, POE::Component::Client::opentick::Error->new(
                                 RequestID => $req_id,
                                 CommandID => $cmd_id,
                                 Data      => $data
            ) );
        }
        else
        {
            # If this was a cancel response pkt, prune the original request.
            $self->_cancel_commands( $req_id, $cmd_id );

            # FINALLY, process the body itself.
            my $extradata;
            ( $extradata, $objects ) =
                $self->_process_body( $data, $req_id, $cmd_id );
            $leftover .= $extradata;
        }
    }

    return( $leftover, $objects );
}


########################################################################
###   Public Accessor methods                                        ###
########################################################################

sub get_heartbeat_delay
{
    my( $self ) = @_;

    return( $self->{heartbeat} );
}

sub get_messages_sent
{
    my( $self ) = @_;

    return( $self->{messages_sent} );
}

sub get_messages_recv
{
    my( $self ) = @_;

    return( $self->{messages_recv} );
}

sub get_records_recv
{
    my( $self ) = @_;

    return( $self->{records_recv} );
}

sub get_errors_recv
{
    my( $self ) = @_;

    return( $self->{errors_recv} );
}


########################################################################
###   POE event handlers                                             ###
########################################################################

# Generate a request packet to send to the server
# NOTE: This should be called with ->call() if you need the return value!
sub _ot_proto_issue_command
{
    my( $self, $kernel, $sender, $cmd_id, @args )
                                    = @_[OBJECT,KERNEL,SENDER,ARG0..$#_];

    my $sender_id = $sender->ID();

    O_DEBUG( sprintf( "_ot_proto_issue_command( %s ), from sender %s",
                      join( ', ', OTCommand( $cmd_id ), @args ),
                      $sender_id ) );

    my( $packet, $req_id )
                = $self->prepare_packet( $sender_id, $cmd_id, @args );

    $kernel->call( $self->{alias}, '_ot_sock_send_packet', $packet )
        if( $packet );

    return( $req_id );
}

# Handle response packets from the server
sub _ot_proto_process_response
{
    my( $self, $kernel, $data ) = @_[OBJECT,KERNEL,ARG0];
    my( $cmd_sts, $cmd_id, $req_id, $objects );

    O_DEBUG( "_ot_proto_process_response( " . length( $data ) . " )" );

    # Loop to catch multiple messages sent per packet
    while( $data )
    {
        ( $data, $objects ) = $self->process_packet( $data );

        # If we got something worthwhile...
        for my $object ( @$objects )
        {
            # Notify the requestor of data or errors
            $self->_send_notification( $object );
        }

        # OPTIMIZATION: All messages in a single response will be from the
        # same request, so SEPARATELY, for ONE OBJECT,
        # Update the outstanding request list
        if( @$objects and my $object = $objects->[0] )
        {
            $self->_update_requests( $object );
        }
    }

    return;
}

# Handle End Of Data state from ProtocolMsg handlers
sub _ot_proto_end_of_data
{
    my( $self, $kernel, $req_id, $cmd_id ) = @_[OBJECT, KERNEL, ARG0, ARG1];

    # Stab the request
    my $sender = $self->_get_request_sender( $req_id );
    $self->_prune_request( $req_id );

    # Notify the original requestor
    $poe_kernel->yield( _notify_of_event =>
                        OTEvent( 'OT_REQUEST_COMPLETE' ),
                        [ $sender ],     # extra sender list
                        $req_id,
                        $cmd_id );

    return;
}

# Send a heartbeat and restart the timer
sub _ot_proto_heartbeat_send
{
    my( $self, $kernel ) = @_[OBJECT,KERNEL];

    $kernel->call( $self->{alias},
                   '_ot_proto_issue_command',
                   OTConstant( 'OT_HEARTBEAT' ) );
    $kernel->delay( '_ot_proto_heartbeat_send', $self->get_heartbeat_delay );

    return;
}

# Stop the heartbeat timer
sub _ot_proto_heartbeat_stop
{
    my( $self, $kernel ) = @_[OBJECT,KERNEL];

    $kernel->delay( '_ot_proto_heartbeat_send' );

    return;
}

# Just a friendly wrapper to trap the event.  Synchronously.
sub logout
{
    my( $self, $kernel ) = @_[OBJECT,KERNEL];

    $kernel->call( $self->{alias},
                   '_ot_proto_issue_command',
                   OTConstant( 'OT_LOGOUT' )
                 );

    return;
}

# Just a friendly wrapper to trap the event.  Synchronously.
sub login
{
    my( $self, $kernel ) = @_[OBJECT,KERNEL];

    $kernel->call( $self->{alias},
                   '_ot_proto_issue_command',
                   OTConstant( 'OT_LOGIN' )
                 );

    return;
}

########################################################################
###   Private methods                                                ###
########################################################################

### Requestor notification

# Send notification to requestor
sub _send_notification
{
    my( $self, $object ) = @_;

    my $cmd_id    = $object->get_command_id();
    return unless( $cmd_id );

    my $req_id    = $object->get_request_id();
    my $sender_id = $self->_get_request_sender( $req_id );
    my $event;

    if( is_error( $object ) )
    {
        $event = OTEvent( 'OT_ON_ERROR' );
        $self->_inc_errors_recv();
    }
    elsif( $object->is_eod )
    {
        $event = OTEvent( 'OT_REQUEST_COMPLETE' );
    }
    else
    {
        $event = OTEventByCommand( $cmd_id );
        $self->_inc_records_recv()
            if( $event eq OTEvent( 'OT_ON_DATA' ) );
    }
    
    # SPECIAL CASE: We already sent the notification.  Skip this.
    # Have to send it high-priority.
    undef( $sender_id ) if( $event eq OTEvent( 'OT_ON_LOGIN' ) );

    # G'wan and send it already already, already!
    $poe_kernel->yield( _notify_of_event =>
                        $event,
                        [ $sender_id ],
                        $req_id,
                        $cmd_id,
                        # give them raw data if they really want it.
                        $self->{rawdata}
                          ? @{ $object->get_raw_data() }
                          : $object );

    return;
}

### Outgoing packet processing

# Generate OT request packet
sub _create_packet
{
    my( $self, $req_id, $cmd_id, @fields ) = @_;

    my $header = $self->_create_header( $req_id, $cmd_id );
    my $body   = $self->_create_body( $req_id, $cmd_id, @fields );
    my $length =
        $self->_create_msg_length( length( $header ) + length( $body ) );
    my $packet = $length . $header . $body;

    return( $packet );
}

# Generate MessageLength field.
sub _create_msg_length
{
    my( $self, $msg_len ) = @_;

    my $junk = pack_binary( OTTemplate( 'MSG_LENGTH' ), $msg_len );

    return( $junk );
}

# Generate OT packet header
sub _create_header
{
    my( $self, $req_id, $cmd_id ) = @_;

    my $header = pack_binary(
                     OTTemplate( 'HEADER' ),
                     OTConstant( 'OT_MES_REQUEST' ),
                     OTConstant( 'OT_STATUS_OK' ),
                     $cmd_id,
                     $req_id,
    );

    return( $header );
}

# Generate OT packet message body
sub _create_body
{
    my( $self, $req_id, $cmd_id, @fields ) = @_;

#    my $handler = $self->_get_state_handler( $cmd_id );
    my $body = $self->{state_obj}->create_body( $req_id, $cmd_id, @fields );

    return( $body );
}

### Incoming packet processing

# Return the MessageLength field
sub _get_message_length
{
    my( $data ) = @_;

    my( $length ) = unpack_binary( OTTemplate( 'MSG_LENGTH' ), $data );

    return( $length );
}

# Unpack a packet header
sub _process_header
{
    my( $data ) = @_;

    my @fields = unpack_binary( OTTemplate( 'HEADER' ), $data );

    return( @fields );
}

# Ensure the header fields are valid
# NOTE: I have generally tried to maintain the arg order of
#   $sender_id, $request_id, $command_id, @etc
# throughout; but in functions that deal with packet contents themselves,
# the signature goes in packet contents order.
sub _validate_header
{
    my( $self, $msg_type, $cmd_sts, $cmd_id, $req_id ) = @_;

    return( $FALSE ) unless( OTCmdStatus( $cmd_sts ) );
    return( $FALSE ) unless( OTMsgType( $msg_type ) );
    return( $FALSE ) unless( OTCommand( $cmd_id ) );
    return( $FALSE ) unless( $self->_get_request_command( $req_id ) );

    return( $TRUE );
}

# Handle the body of a response message through subclassed handlers
# XXX: This may have concurrency issues...
sub _process_body
{
    my( $self, $body, $req_id, $cmd_id ) = @_;

#    my $handler = $self->_get_state_handler( $cmd_id );
    my( $leftover, $results )
                = $self->{state_obj}->process_body( $body, $req_id, $cmd_id );

    return( $leftover, $results );
}

# Stash some data in the object for next loop
sub _set_partial_data
{
    my( $self, $data ) = @_;

    $self->{partial_data} = defined( $data ) ? $data : '';

    return( defined( $data ) ? length( $data ) : 0 );
}

# Retrieve (but keep) partial data from the object
sub _get_partial_data
{
    my( $self, $data ) = @_;

    return( $self->{partial_data} );
}

# Cancel entries from our request list if appropriate
sub _cancel_commands
{
    my( $self, $req_id, $cmd_id ) = @_;

    # Bail out if this isn't a cancel command.
    return unless( OTCancel( $cmd_id ) );

    my $cancel_id = $self->_get_request_cancel_id( $req_id );
    my $cancelled = $self->_prune_request( $cancel_id );
    $cancelled = $self->_prune_request( $req_id );

    O_DEBUG( "_cancel_commands( $req_id, $cmd_id ), cid=$cancel_id = $cancelled" );

    return( $cancelled );
}

### Outstanding request list processing

# Generate an ID and add a request to the outstanding request list
sub _add_request
{
    my( $self, $sender_id, $cmd_id ) = @_;

    my $id = $self->_get_next_request_id();

    # Don't save heartbeat requests in outstanding request queue.
    unless( $cmd_id == OTConstant( 'OT_HEARTBEAT' ) )
    {
        $self->_update_request_time( $id );
        $self->_update_request_sender( $id, $sender_id );
        $self->_update_request_command( $id, $cmd_id );
        $self->_update_request_respcount( $id, 0 );
    }

    return( $id );
}

# Remove request from catalog if appropriate
sub _update_requests
{
    my( $self, $object ) = @_;

    my $packets_expected = OTResponses( $object->get_command_id() );
    my $req_id = $object->get_request_id();

    if( $packets_expected <= OTConstant( 'OT_RESPONSES_ONE' ) ||
        is_error( $object ) )
    {
        $self->_prune_request( $req_id );
    }
    else
    {
        $self->_update_request_time( $req_id );
        $self->_update_request_respcount( $req_id );
    }

    # Clean up ListSymbols and ListExchange requests while we're at it.
    $self->_prune_old_requests();

    return;
}

# Set the request_id that this command will cancel upon server confirmation
sub _set_request_cancel_id
{
    my( $self, $req_id, $cancel_id ) = @_;

    O_DEBUG( "_set_request_cancel_id( $req_id, $cancel_id )" );

    return( $self->{requests}->{$cancel_id}->{cancel_rqid} = $req_id );
}

# Update a request timestamp
sub _update_request_time
{
    my( $self, $req_id ) = @_;

    $self->{requests}->{$req_id}->{stamp} = time;

    return;
}

# Update or increment a request response count
sub _update_request_respcount
{
    my( $self, $req_id, $new_count ) = @_;

    if( defined( $new_count ) )
    {
        $self->{requests}->{$req_id}->{respcount} = $new_count;
    }
    else
    {
        $self->{requests}->{$req_id}->{respcount}++;
    }

    return;
}

# Update a request POE session sender ID
sub _update_request_sender
{
    my( $self, $req_id, $sender_id ) = @_;

    $self->{requests}->{$req_id}->{sender} = $sender_id;

    return;
}

# Update a request command
sub _update_request_command
{
    my( $self, $req_id, $cmd_id ) = @_;

    $self->{requests}->{$req_id}->{command} = $cmd_id;

    return;
}

# Prune specified request, returning true if pruned.
sub _prune_request
{
    my( $self, $req_id ) = @_;

    return unless( $req_id );

    my $pruned = delete( $self->{requests}->{$req_id} );

    return( $pruned ? $TRUE : $FALSE );
}

# Remove outdated requests
sub _prune_old_requests
{
    my( $self ) = @_;
    my $timeout = $self->{request_timeout};

    for my $req_id ( $self->_get_requests() )
    {
        my $cmd_id    = $self->_get_request_command( $req_id );

        if( ( time >
              $self->_get_request_time( $req_id ) + $timeout ) and
            ( $cmd_id == OTConstant( 'OT_REQUEST_LIST_EXCHANGES' ) or
              $cmd_id == OTConstant( 'OT_REQUEST_LIST_SYMBOLS' ) or
              $cmd_id == OTConstant( 'OT_REQUEST_LIST_SYMBOLS_EX' ) ) )
        {
            O_DEBUG( "pruning $req_id!" );
            $self->_prune_request( $req_id );
        }
    }

    return;
}

# Return list of all outstanding requests
sub _get_requests
{
    my( $self ) = @_;

    return( keys( %{ $self->{requests} } ) );
}

# Return boolean if request exists
sub _request_exists
{
    my( $self, $req_id ) = @_;

    return( exists( $self->{requests}->{$req_id} ) ? $TRUE : $FALSE );
}

# Return target ID for cancellation, if present
sub _get_request_cancel_id
{
    my( $self, $req_id ) = @_;

    return( $self->{requests}->{$req_id}->{cancel_rqid} );
}

# Get the sender of a request
sub _get_request_sender
{
    my( $self, $req_id ) = @_;

    return( $self->{requests}->{$req_id}->{sender} );
}

# Get the number of responses for this request
sub _get_request_respcount
{
    my( $self, $req_id ) = @_;

    return( $self->{requests}->{$req_id}->{respcount} || 0 );
}

# Return command of particular request
sub _get_request_command
{
    my( $self, $req_id ) = @_;

    return( exists( $self->{requests}->{$req_id} )
            ? $self->{requests}->{$req_id}->{command}
            : undef
    );
}

# Return timestamp of particular request
sub _get_request_time
{
    my( $self, $req_id ) = @_;

    return( exists( $self->{requests}->{$req_id} )
            ? $self->{requests}->{$req_id}->{stamp} 
            : undef );
}

# Generate and return a new, unique request ID number
{   # CLOSURE
my $id;
sub _get_next_request_id
{
    my( $self, $newid ) = @_;
    $id = $newid || $id || 0;

    do {
        $id = 1 if (++$id > 0xFFFFFFFF);
        $id++ unless $id;
    } while( exists( $self->{requests}->{ $id } ) );

    return $id;
}
}   # /CLOSURE

### Statistical junk

sub _inc_messages_sent
{
    my( $self, $value ) = @_;

    return( $self->{messages_sent} += $value || 1 );
}

sub _inc_messages_recv
{
    my( $self, $value ) = @_;

    return( $self->{messages_recv} += $value || 1 );
}

sub _inc_records_recv
{
    my( $self, $value ) = @_;

    return( $self->{records_recv} += $value || 1 );
}

sub _inc_errors_recv
{
    my( $self, $value ) = @_;

    return( $self->{errors_recv} += $value || 1 );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Protocol - Protocol handling routines for opentick client.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Protocol;

=head1 DESCRIPTION

This provides the high level routines for handling the opentick Protocol.
It is heavily tailored to this application, and thus probably serves little
purpose for anything else.

See L<POE::Component::Client::opentick> for the main documentation.

If Happy Fun Ball begins to smoke, get away immediately. Seek shelter and
cover head.

=head1 METHODS

=over 4

=item B<new( )>

Create a new object.

=item B<initialize( )>

Initialize the object.

=item B<login( )>

Send login information to opentick.

=item B<logout( )>

Logout from opentick.

=item B<prepare_packet( )>

Prepare a packet to send to opentick.

=item B<process_packet( )>

Process a packet received from opentick.

=back

=head1 ACCESSORS

=over 4

=item B<get_errors_recv( )>

=item B<get_messages_recv( )>

=item B<get_messages_sent( )>

=item B<get_records_recv( )>

=item B<get_heartbeat_delay( )>

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
