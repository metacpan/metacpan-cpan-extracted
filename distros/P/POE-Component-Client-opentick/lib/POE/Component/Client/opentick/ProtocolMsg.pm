package POE::Component::Client::opentick::ProtocolMsg;
#
#   opentick.com POE client
#
#   Protocol Message abstract base class
#
#   infi/2008
#
#   $Id: ProtocolMsg.pm 56 2009-01-08 16:51:14Z infidel $
#
#   See docs/implementation-notes.txt for a detailed explanation of how
#     this module works.
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( croak );
$Carp::CarpLevel = 2;
use POE;
use Data::Dumper;

# Ours.
use POE::Component::Client::opentick::Constants;
use POE::Component::Client::opentick::Util;
use POE::Component::Client::opentick::Error;
use POE::Component::Client::opentick::Record;
use POE::Component::Client::opentick::Output;

###
### Variables
###

use vars qw( $VERSION $TRUE $FALSE $KEEP $DELETE );

($VERSION) = q$Revision: 56 $ =~ /(\d+)/;
*TRUE      = \1;
*FALSE     = \0;
*KEEP      = \0;
*DELETE    = \1;

my $packet_handler_states = {
    cmds    => {
        OTConstant( 'OT_LOGIN' )                    => '_ot_msg_login_o',
        OTConstant( 'OT_LOGOUT' )                   => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_TICK_STREAM' )      => '_ot_msg_generic_o',
        OTConstant( 'OT_CANCEL_TICK_STREAM' )       => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_HIST_DATA' )        => '_ot_msg_generic_o',
        OTConstant( 'OT_CANCEL_HIST_DATA' )         => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_LIST_EXCHANGES' )   => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_LIST_SYMBOLS' )     => '_ot_msg_generic_o',
        OTConstant( 'OT_HEARTBEAT' )                => '_ot_msg_nobody_o',
        OTConstant( 'OT_REQUEST_EQUITY_INIT' )      => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN' )     => '_ot_msg_generic_o',
        OTConstant( 'OT_CANCEL_OPTION_CHAIN' )      => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_BOOK_STREAM' )      => '_ot_msg_generic_o',
        OTConstant( 'OT_CANCEL_BOOK_STREAM' )       => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_TICK_STREAM_EX' )   => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_EX' )  => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_HIST_TICKS' )       => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_SPLITS' )           => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_DIVIDENDS' )        => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_HIST_BOOKS' )       => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_BOOK_STREAM_EX' )   => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_U' )   => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_OPTION_INIT' )      => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_LIST_SYMBOLS_EX' )  => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_TICK_SNAPSHOT' )    => '_ot_msg_generic_o',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_SNAPSHOT' ) => '_ot_msg_generic_o',
    },
    resp    => {
        OTConstant( 'OT_LOGIN' )                    => '_ot_msg_login_i',
        OTConstant( 'OT_LOGOUT' )                   => '_ot_msg_logout_i',
        OTConstant( 'OT_REQUEST_TICK_STREAM' )      => '_ot_msg_singledt_i',
        OTConstant( 'OT_CANCEL_TICK_STREAM' )       => '_ot_msg_cancel_i',
        OTConstant( 'OT_REQUEST_HIST_DATA' )        => '_ot_msg_multidt_i',
        OTConstant( 'OT_CANCEL_HIST_DATA' )         => '_ot_msg_nobody_i',
        OTConstant( 'OT_REQUEST_LIST_EXCHANGES' )   => '_ot_msg_listex_i',
        OTConstant( 'OT_REQUEST_LIST_SYMBOLS' )     => '_ot_msg_multi_i',
        OTConstant( 'OT_HEARTBEAT' )                => '_ot_msg_cancel_i',
        OTConstant( 'OT_REQUEST_EQUITY_INIT' )      => '_ot_msg_single_i',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN' )     => '_ot_msg_singledt_i',
        OTConstant( 'OT_CANCEL_OPTION_CHAIN' )      => '_ot_msg_cancel_i',
        OTConstant( 'OT_REQUEST_BOOK_STREAM' )      => '_ot_msg_singledt_i',
        OTConstant( 'OT_CANCEL_BOOK_STREAM' )       => '_ot_msg_cancel_i',
        OTConstant( 'OT_REQUEST_TICK_STREAM_EX' )   => '_ot_msg_singledt_i',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_EX' )  => '_ot_msg_singledt_i',
        OTConstant( 'OT_REQUEST_HIST_TICKS' )       => '_ot_msg_multidt_i',
        OTConstant( 'OT_REQUEST_SPLITS' )           => '_ot_msg_single_i',
        OTConstant( 'OT_REQUEST_DIVIDENDS' )        => '_ot_msg_single_i',
        OTConstant( 'OT_REQUEST_HIST_BOOKS' )       => '_ot_msg_multidt_i',
        OTConstant( 'OT_REQUEST_BOOK_STREAM_EX' )   => '_ot_msg_singledt_i',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_U' )   => '_ot_msg_singledt_i',
        OTConstant( 'OT_REQUEST_OPTION_INIT' )      => '_ot_msg_single_i',
        OTConstant( 'OT_REQUEST_LIST_SYMBOLS_EX' )  => '_ot_msg_multi_i',
        OTConstant( 'OT_REQUEST_TICK_SNAPSHOT' )    => '_ot_msg_singledt_i',
        OTConstant( 'OT_REQUEST_OPTION_CHAIN_SNAPSHOT' )
                                                    => '_ot_msg_singledt_i',
    },
};

# These arguments are for this object; pass the rest on.
my %valid_args = (
    alias           => $KEEP,
    debug           => $KEEP,
    protocolver     => $DELETE,
    platform        => $DELETE,
    platformpass    => $DELETE,
    macaddr         => $DELETE,
    os              => $DELETE,
    username        => $DELETE,
    password        => $DELETE,
);


###
### Public methods
###

sub new
{
    my( $class, @args ) = @_;
    croak( "$class requires an even number of parameters" ) if( @args & 1 );

    my $self = {
            alias           => OTDefault( 'alias' ),
            debug           => $FALSE,      # Debug mode
            protocolver     => OTDefault( 'protocolver' ),
            platform        => OTDefault( 'platform' ),
            platformpass    => OTDefault( 'platformpass' ),
            macaddr         => OTDefault( 'macaddr' ),
            os              => OTDefault( 'os' ),
            username        => undef,       # OT username
            password        => undef,       # OT password
            session_id      => undef,       # SessID for this OT session
    };

    # Prepack the supplied MAC address for FASTAR
    $self->{macaddr} = pack_macaddr( $self->{macaddr} );

    bless( $self, $class );

    $self->initialize( @args );

    # Make sure we have enough info to login.
    $self->_get_auth_data();

    return( $self );
}

# Initialize the object instance.
sub initialize
{
    my( $self, %args ) = @_;

    # Store things.  Things that make us go.
    for( keys( %args ) )
    {
        $self->{lc $_} = delete( $args{$_} )
                            if( exists( $valid_args{lc $_} ) );
    }

    return;
}

# Generic body creation dispatcher
sub create_body
{
    my( $self, $req_id, $cmd_id, @fields ) = @_;

    my $state = $packet_handler_states->{cmds}->{ $cmd_id };

    throw( "No state for outgoing command id: $cmd_id" ) unless( $state );

    my $body = $poe_kernel->call( $self->{alias},
                                  $state,
                                  $req_id,
                                  $cmd_id,
                                  @fields );

    return( $body );
}

# Default handler to process generic packet bodies
sub process_body
{
    my( $self, $body, $req_id, $cmd_id ) = @_;
    my( $leftover, $objects );

    my $state = $packet_handler_states->{resp}->{ $cmd_id };

    throw( "No state for incoming command: $cmd_id" ) unless( $state );

    ( $leftover, $objects ) = $poe_kernel->call( $self->{alias},
                                                 $state,
                                                 $body,
                                                 $req_id,
                                                 $cmd_id );

    return( $leftover, $objects );
}

###
### POE event handlers
###

### OUTGOING packet body construction

# The default case
sub _ot_msg_generic_o
{
    my( $self, $req_id, $cmd_id, @fields ) = @_[OBJECT,ARG0..$#_];
    my $body;

    my $template = OTTemplate( 'cmds/' . OTCommand( $cmd_id ) );
    if( defined( $template ) )
    {
        # We can handle this packet body.  Go.
        $body = pack_binary( $template, $self->_get_session_id(), @fields );
    }
    else
    {
        # No template found, THROW
        $self->_create_error( "Unhandled command type specified: $cmd_id",
                              $req_id, $cmd_id )->throw();
    }

    return( $body );
}

# No body.  This is easy!
sub _ot_msg_nobody_o
{
    return( '' );
}

# LOGIN handling; need to do a few things here.
sub _ot_msg_login_o
{
    my( $self ) = $_[OBJECT];

    my $template = OTTemplate( 'cmds/OT_LOGIN' );

    my $body = pack_binary(
                    $template,
                    $self->_get_protocol_ver(),
                    $self->_get_os(),
                    $self->_get_platform(),
                    $self->_get_platform_pass(),
                    $self->_get_mac_addr(),
                    $self->_get_username(),
                    $self->_get_password(),
    );

    return( $body );
}

### INCOMING packet body parsing

# Handle a login response.
sub _ot_msg_login_i
{
    my( $self, $kernel, $body, $req_id, $cmd_id ) = @_[OBJECT,KERNEL,ARG0..$#_];

    # Unpack body
    my $template = $self->_get_resp_template( $req_id, $cmd_id, $body );
    my @fields = unpack_binary( $template, $body );
    my( $session_id, $redirected, $redir_host, $redir_port ) = @fields;

    # Stash our OT session ID for later
    $self->_set_session_id( $session_id );

    # Check if we have been redirected, and send a synchronous event.
    my $object;
    if( $redirected )
    {
        $poe_kernel->call( $poe_kernel->get_active_session(),
                       '_server_redirect', $redir_host, $redir_port );
    }
    else # tell ourselves we logged in
    {
        $kernel->yield( OTEvent( 'OT_ON_LOGIN' ) );
        $object = $self->_create_record( $req_id, $cmd_id, undef, \@fields );
    }

    # Return the resulting object, or nothing.
    return( '', $object ? [ $object ] : [] );
}

# Handle a logout response.
sub _ot_msg_logout_i
{
    my( $self, $kernel ) = @_[OBJECT,KERNEL];

    $self->_set_session_id( undef );

    $kernel->yield( '_logged_out' );

    return( '', [] );
}

# Handle a single record/message packet body
sub _ot_msg_single_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    # Unpack body
    my $template = $self->_get_resp_template( $req_id, $cmd_id, $body );

    my( $leftover, @fields ) = $self->_parse_row( $template, $body );

    # Check for and signal end of data
    my $dt = $fields[0];
    if( OTeod( $dt ) )
    {
        $poe_kernel->yield( _ot_proto_end_of_data => $req_id, $cmd_id );
        return ( $leftover, [] );
    }

    my $record = $self->_create_record( $req_id, $cmd_id, $dt, \@fields );

    return( $leftover, [ $record ] );
}

# Handle a single record/message packet body, with datatype
sub _ot_msg_singledt_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    # Check for and signal end of data
    my $dt = unpack_binary( 'C', $body );
    if( OTeod( $dt ) )
    {
        $poe_kernel->yield( _ot_proto_end_of_data => $req_id, $cmd_id );
        return ( '', [] );
    }

    # Unpack body
    my $template = OTTemplate( 'datatype/' . OTDatatype( $dt ) );
    throw( "Unknown Datatype: '$dt'\n" . dump_hex($body) ) unless( $template );

    my @fields;
    @fields = unpack_binary( $template, $body );

    my $record = $self->_create_record( $req_id, $cmd_id, $dt, \@fields );

    return( '', [ $record ] );
}

# Handle a multiple record/message packet body, with datatype
sub _ot_msg_multidt_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    # Snarf row count and chop from beginning of data.
    my( $leftover, $rowcount ) = $self->_parse_row( 'V', $body );

    # Go through each row, setting template to datatype and parsing
    my @records = ();
    for( 1..$rowcount )
    {
        # Peek ahead to get datatype, but leave it attached
        my $dt       = unpack( 'C', $leftover );
        my $template = OTTemplate( 'datatype/' . OTDatatype( $dt ) );
        throw( "Unknown Datatype: '$dt'\n".dump_hex($body)) unless( $template );

        # break loop if we don't have enough data left to fill template
        last unless( length( $leftover ) >= pack_bytes( $template ) );

        # Parse and retrieve return values, trimming $leftover
        my @fields;
        ( $leftover, @fields) = $self->_parse_row( $template, $leftover );

        # Store in object
        my $record = $self->_create_record( $req_id, $cmd_id, $dt, \@fields );
        push( @records, $record );
    }

    return( $leftover, \@records );
}

# Handle a multiple record/message packet body, no datatype
sub _ot_msg_multi_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    # Get template
    my $template = $self->_get_resp_template( $req_id, $cmd_id, $body );

    # Snarf row count and chop from beginning of data.
    my( $leftover, $rowcount ) = $self->_parse_row( 'v', $body );

    # Go through each row, setting template to datatype and parsing
    my @records = ();
    for( 1..$rowcount )
    {
        # Parse and retrieve return values, trimming $leftover
        ( $leftover, my @fields ) = $self->_parse_row( $template, $leftover );

        # Store in object
        my $record = $self->_create_record( $req_id, $cmd_id, undef, \@fields );
        push( @records, $record );
    }

    return( $leftover, \@records );
}

# Handle ListExchanges response.  Yes, only for this.  Grr.
sub _ot_msg_listex_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    # Get template
    my $template = $self->_get_resp_template( $req_id, $cmd_id, $body );

    # Get urllen, url
    my( $leftover, $url ) = $self->_parse_row( $template, $body );
    # Get rowcount
    ( $leftover, my $rowcount ) = $self->_parse_row( 'v', $leftover );

    $template = 'a15 C v/a v/a';

    # Go through each row, setting template to datatype and parsing
    my @records = ();
    for( 1..$rowcount )
    {
        # Parse and retrieve return values, trimming $leftover
        ( $leftover, my @fields) = $self->_parse_row( $template, $leftover );

        # Store in object
        my $record = $self->_create_record( $req_id, $cmd_id, undef, \@fields );
        push( @records, $record );
    }

    return( $leftover, \@records );
}

# Build cancellation record.
sub _ot_msg_cancel_i
{
    my( $self, $body, $req_id, $cmd_id ) = @_[OBJECT,ARG0..$#_];

    my $cancel = $self->_create_record( $req_id, $cmd_id, undef, [] );

    return( '', [ $cancel ] );
}

# Handle no packet body.  bvernt.
sub _ot_msg_nobody_i
{
    return( '', [] );
}


###
### Private methods
###

# Grab the named template, or throw an exception.
sub _get_resp_template
{
    my( $self, $req_id, $cmd_id, $body ) = @_;

    # Get template
    my $template = OTTemplate( 'resp/' . OTCommand( $cmd_id ) );
    unless( $template )
    {
        my $hex = dump_hex( $body );
        $hex =~ s/\n/ /gms;

        $Carp::CarpLevel = 0;
        print Carp::longmess();

        my $error = $self->_create_error( "Unhandled packet received: ($hex)",
                                          $req_id, $cmd_id )->throw();
    }

    return( $template );
}

# Pull out a single row, returning leftover data and @fields
sub _parse_row
{
    my( $self, $template, $input ) = @_;

    $template   .= ' a*';
    my @fields   = unpack_binary( $template, $input );
    my $leftover = pop( @fields );

    return( $leftover, @fields );
}

# Create and populate a ::Record object
sub _create_record
{
    my( $self, $req_id, $cmd_id, $datatype, $data ) = @_;

    my $record = POE::Component::Client::opentick::Record->new(
        RequestID   => $req_id,
        CommandID   => $cmd_id,
        DataType    => $datatype,
        Data        => $data,
    );

    return( $record );
}

# Create and populate an ::Error object
sub _create_error
{
    my( $self, $message, $req_id, $cmd_id ) = @_;

    my $error = POE::Component::Client::opentick::Error->new(
        RequestID   => $req_id,
        CommandID   => $cmd_id,
        Message     => $message,
        DumpStack   => 1,
    );

    return( $error );
}

# Retrieve auth data from relevant sources
sub _get_auth_data
{
    my( $self ) = @_;

    $self->{username} = $ENV{OPENTICK_USER}
        or croak( "FATAL: Cannot get opentick username!" )
            unless( $self->{username} );
    $self->{password} = $ENV{OPENTICK_PASS}
        or croak( "FATAL: Cannot get opentick password!" )
            unless( $self->{password} );

    return;
}

###
### Accessor methods
###

sub _set_session_id
{
    my( $self, $sess_id ) = @_;

    return( $self->{session_id} = $sess_id );
}

sub _set_platform_id
{
    my( $self, $id ) = @_;

    return( $self->{platform} = $id );
}

sub _set_platform_pass
{
    my( $self, $pass ) = @_;

    return( $self->{platformpass} = $pass );
}

sub _get_session_id
{
    my( $self ) = @_;

    return( $self->{session_id} );
}

sub _get_protocol_ver
{
    my( $self ) = @_;

    return( $self->{protocolver} );
}

sub _get_os
{
    my( $self ) = @_;

    return( $self->{os} );
}

sub _get_platform
{
    my( $self ) = @_;

    return( $self->{platform} );
}

sub _get_platform_pass
{
    my( $self ) = @_;

    return( $self->{platformpass} );
}

sub _get_mac_addr
{
    my( $self ) = @_;

    return( $self->{macaddr} );
}

sub _get_username
{
    my( $self ) = @_;

    return( $self->{username} );
}

sub _get_password
{
    my( $self ) = @_;

    return( $self->{password} );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::ProtocolMsg -- Individual protocol message handling.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::ProtocolMsg;

 my $ps = POE::Component::Client::opentick::ProtocolMsg->new( );

=head1 DESCRIPTION

Provides handling for all of the deep hackery and magic within
POE::Component::Client::opentick::Protocol, and thus should not be gazed
upon by mortal men.

See the documentation for the main ::opentick module for complete
information.

=head1 METHODS

=over 4

=item B<new()>          -- create a new object instance

=item B<create_body()>  -- initialize the object instance

=item B<process_body()> -- high level body handling routine

=item B<create_body()>  -- high level body creation routine

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

