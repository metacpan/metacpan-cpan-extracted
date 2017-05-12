package POE::Component::Client::opentick::Error;
#
#   opentick.com POE client
#
#   Error handling functionality
#
#   infi/2008
#
#   $Id: Error.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( carp croak confess );
#$Carp::CarpLevel = 10;
use Data::Dumper;

# Ours.
use POE::Component::Client::opentick::Constants;

use overload '""' => \&stringify;

###
### Variables
###

use vars qw( $VERSION $TRUE $FALSE );

BEGIN {
    require Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( throw );
    ($VERSION)  = q$Revision: 56 $ =~ /(\d+)/;
}

*TRUE    = \1;
*FALSE   = \0;

my $valid_args = {
    requestid   => $TRUE,
    commandid   => $TRUE,
    dumpstack   => $TRUE,
    message     => $TRUE,
    data        => $TRUE,
};

###
### Public methods
###

sub new
{
    my( $class, @data ) = @_;
    croak( "$class requires an even number of parameters" ) if( @data & 1 );
    
    my $self = {
            stack   => _process_longmess(),
    };

    bless( $self, $class );

    $self->initialize( @data );

    return( $self );
}

sub initialize
{
    my( $self, %args ) = @_;

    for( keys( %args ) )
    {
        $self->{lc $_} = $args{$_} if( $valid_args->{lc $_} );
    }

    croak( "At least one of Message or Data must be specified!" )
        unless( exists( $self->{message} ) or exists( $self->{data} ) );

    return;
}

# Dump the object contents appropriately
sub stringify
{
    my( $self ) = @_;

    my $message = $self->get_message();
    unless( $message )
    {
        my( $errcode, $errmsg ) = $self->get_data();
        $message = 'Protocol error ' . $errcode . ': ' . $errmsg;
    }

    # Add additional fields
    if( my( $cmd_name, $cmd_id )= $self->get_command() )
    {
        $message .= sprintf( "\nOTCommand: %d (%s)", $cmd_id, $cmd_name );
    }
    $message .= "\nRequest ID: " . $self->get_request_id()
                                          if( $self->get_request_id() );
    $message .= "\n" . $self->get_stack() if( $self->dump_stack() );

    return( $message );
}

# Just give up already, already.
sub throw
{
    my( $item ) = @_;

    my $message = "$item";      # OMG HAX

    confess( $message );
}

###
### Accessors
###

sub set_dump_stack
{
    my( $self ) = @_;

    $self->{dumpstack} = $TRUE;

    return( $self );
}

sub get_command
{
    my( $self ) = @_;

    return unless $self->{commandid};

    return( OTCommand( $self->{commandid} ), $self->{commandid} );
}

sub get_command_id
{
    my( $self ) = @_;

    return( $self->{commandid} );
}

sub dump_stack
{
    return( shift->{dumpstack} ? $TRUE : $FALSE );
}

sub get_stack
{
    return( shift->{stack} );
}

sub get_data
{
    my( $self ) = @_;

    my( $errcode, undef, $errmsg )
                        = unpack( OTTemplate( 'ERROR' ), $self->{data} );

    return( wantarray
            ? ( $errcode, $errmsg )
            : $self->{data} );
}

sub get_message
{
    return( shift->{message} );
}

sub get_request_id
{
    return( shift->{requestid} );
}

###
### Private methods
###

sub _process_longmess
{
    my @good = grep { ! /(?:Kernel|Session)/ } Carp::longmess();

    return( join( "\n", @good ) );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Error - Error handling routines for opentick client.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Error;

 my $error = POE::Component::Client::opentick::Error->new(
        Message     => 'Something kasplodinated!',
 );

-or-

 my $error = POE::Component::Client::opentick::Error->new(
        Data        => $packet_error_data,   # Error body, off the wire
        Command     => $OT_LOGIN,            # an integer
        DumpStack   => 1,                    # a true value
        RequestID   => 42,                   # Protocol ReqID, integer
 );

 # Easy.
 print "$error\n";

 # Other available methods.
 print $error->get_message(), "\n";
 print $error->get_stack(), "\n";
 my $cmd_id = $error->get_command();

 # Expand the raw protocol error message
 my( $errcode, $errdesc ) = $error->get_data();    # list context
 # Just get the raw data itself
 my $data                 = $error->get_data();    # scalar context

=head1 DESCRIPTION

This module contains all of the error-handling routines used by the rest of
POE::Component::Client::opentick.

It overloads stringification to print a formatted message when used within
"" (quotes) for ease of use, but you are free to call its methods to reach
all of the contents yourself.

It can also be subclassed to encapsulate and perform your own error
handling, if so desired.

=head1 METHODS

=over 4

=item B<new( [ @args ] )>           -- create and bless a new object

Checks that arguments are passed in in even numbers, croaks if not.

RETURNS:    $object

ARGUMENTS:

 Message     => $error_msg      stringified error message
 Data        => $data           packed binary data from OT's protocol
 DumpStack   => $boolean        [opt] dump the call stack (defaults to false)
 RequestID   => $integer        [opt] Request ID from which this packet came
 CommandID   => $integer        [opt] opentick <CommandType>

I<*** (at least ONE of Message or Data are REQUIRED)>

=item B<initialize( [ @args ] )>    -- configure a new object

RETURNS:    undef

ARGUMENTS:

Actually, all of the above arguments are passed onto initialize() and stored
at that point.

=item B<stringify( )>               -- stringify the object

RETURNS:    $stringified_error_message

ARGUMENTS:  none

=item B<throw( $item )>             -- explode with an error message

RETURNS:    Sure doesn't.

ARGUMENTS:  a message or an Error (or subclassed Error) object.

=back

=head1 ACCESSORS

Obviously, to use the object effectively, you should be able to reach its
contents.  Here are accessor methods for grabbing the various fields that
may be available within the object.

These will return appropriate contents, or undef if nothing was supplied.

=over 4

=item B<get_message( )>

Returns the message supplied in the constructor.

=item B<get_stack( )>

Returns the call stack at the time of object construction.

=item B<dump_stack( )>

Returns BOOLEAN as to whether DumpStack was specified in the constructor.

=item B<set_dump_stack( $bool )>

Use to set dump_stack later if you should change your mind.

=item B<get_request_id( )>

Returns the Request ID passed in the constructor.

=item B<get_command_id( )>

Returns the integral command id supplied

=item B<get_command( )>

Returns ( $cmd_name, $cmd_id ) in list context.

=item B<get_data( )>

Returns the raw packet data in scalar context, expanded packet data into
two fields in list context: ( $error_code, $error_description ).

=back

=head1 SUBCLASSING

To subclass Error.pm, overload the B<initialize()>, B<stringify()> and
B<throw> methods with functions of your own choosing, to dump the
appropriate data.  new() should not be overloaded.

=head1 NOTES

This module uses the Perl 'overload' pragma to overload the stringification
operator '""', and point it to the stringify() method.  This makes error
dumpage easier.  This is also why you should overload stringify() with a
method of your own design, if you should subclass the module.

=head1 SEE ALSO

POE, POE::Component::Client::opentick

L<http://poe.perl.org>

L<http://www.opentick.com/>

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

