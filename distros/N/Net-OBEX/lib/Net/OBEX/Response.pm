package Net::OBEX::Response;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Net::OBEX::Response::Generic;
use Net::OBEX::Response::Connect;
use Net::OBEX::Packet::Headers;

use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors( qw(obj_connect  obj_generic  obj_head  error ) );

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->obj_connect( Net::OBEX::Response::Connect->new );
    $self->obj_generic( Net::OBEX::Response::Generic->new );
    $self->obj_head( Net::OBEX::Packet::Headers->new );

    return $self;
}

sub parse {
    my ( $self, $packet, $is_connect ) = @_;

    if ( $is_connect ) {
        return $self->obj_connect->parse_info( $packet );
    }
    else {
        return $self->obj_generic->parse_info( $packet );
    }
}

sub parse_sock {
    my ( $self, $sock, $is_connect ) = @_;

    my $read_buffer;
    unless ( $sock->read( $read_buffer, ( $is_connect ? 7 : 3 ) )  ) {
        $self->error( 'Socket error: ' . $sock->error );
        return;
    }

    my %response = (
        raw_packet => $read_buffer,
        info       => $self->parse( $read_buffer, $is_connect ),
    );

    if ( my $length = $response{info}{headers_length} ) {
        unless ( $sock->read( $read_buffer, $length ) ) {
            $self->error( 'Socket error: ' . $sock->error );
            return;
        }
        $response{raw_packet} .= $read_buffer;
        $response{headers} = $self->obj_head->parse( $read_buffer );
    }

    return \%response;
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN IrLMP LSAP MTU RT SEL mtu parseable

=head1 NAME

Net::OBEX::Response - interpret OBEX protocol response packets

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::OBEX::Response;

    my $res = Net::OBEX::Response->new;

    # read 7 bytes of the Connect packet from the socket there somewhere
    # now parse it:
    my $response_ref = $res->parse( $data_from_the_socket, 1 );

    if ( $response_ref->{headers_length} ) {
        # ok, looks like we got some headers in this packet
        # read $response_ref->{headers_length} bytes from the socket
        # here and parse the headers.
    }

    # OMG SO COMPLICATED!!
    # now, let's try the EZ way, let's assume that $sock
    # is a Socket::Class object already connected to our "device"...

    # this is NOT a Connect packet, so we will omit the second argument
    # to the ->parse_sock() method.
    my $response_ref = $res->parse_sock( $sock );

    # boomm, now $response_ref is fully loaded and no mess with socket reads.

=head1 DESCRIPTION

B<WARNING!!! this module is still in early alpha stage. It is recommended
that you use it only for testing.>
The module provides means to interpret raw OBEX protocol responses.

=head1 CONSTRUCTOR

=head2 new

    my $res = Net::OBEX::Response->new;

Takes no arguments, returns a freshly baked, right out of the oven, juicy
with a cherry on top Net::OBEX::Response object ready to be used and abused.

=head1 METHODS

=head2 parse

    # parse a generic response
    my $generic_response = $res->parse( $data_from_wire );

    # parse response from Connect
    my $connect_response = $res->parse( $data_from_wire, 1 );

Takes one mandatory and one optional arguments. The first argument
is the raw data from the wire representing the packet. The second one
is either a true or false value indicating if the packet is a response
to a Connect request or not, it defaults to C<0>.
Returns a hashref with the following keys/values:

Sample returns (descriptions are below):

    # generic response
    $VAR1 = {
        'packet_length' => 3,
        'response_code' => 200,
        'headers_length' => 0,
        'response_code_meaning' => 'OK, Success'
    };

    # Connect response
    $VAR1 = {
        'mtu' => 5126,
        'flags' => '00000000',
        'packet_length' => 31,
        'obex_version' => '00010000',
        'response_code' => 200,
        'headers_length' => 24,
        'response_code_meaning' => 'OK, Success'
    };

=head3 packet_length

    { 'packet_length' => 3 }

The C<packet_length> key will contain the length of the packet in bytes.

=head3 headers_length

    { 'headers_length' => 24 }

The C<headers_length> key will contain the length of packet's headers in
bytes. You would use this value to finish reading the entire packet from
the socket, however, see the C<parse_sock()> method described below.

=head3 response_code

    { 'response_code' => 200 }

The C<response_code> key will contain a response code, this will pretty
much be HTTP response codes since that what OBEX prefers to use.

=head3 response_code_meaning

    { 'response_code_meaning' => 'OK, Success' }

The C<response_code_meaning> key will contain a human parseable explanation
of C<response_code>.


Additionally, if the "is connect response" argument to C<parse()> is to
a true value (and, of course, providing the packet is a proper Connect
response) the hashref will have the following keys/values:

=head3 mtu

    { 'mtu' => 5126 }

The C<mtu> key will contain the MTU of the responding device, i.e. the
maximum length of a packet (in bytes) the device can accept.

=head3 flags

    { 'flags' => '00000000' }

The C<flags> key will contain an unpacked "flags" byte, all but the first
of those 8 bits are reserved. If the first bit is set it
I<indicates support for multiple IrLMP connections to the same LSAP-SEL>

=head3 obex_version

    { 'obex_version' => '00010000' }

The C<obex_version> key will contain an unpacked "version" byte.             Which is the version of the OBEX protocol encoded with the major number
in the high order 4 bits, and the minor version in the low order 4 bits.

=head2 parse_sock

    my $sock = Socket::Class->new(
        domain        => 'bluetooth',
        type          => 'stream',
        proto         => 'rfcomm',
        remote_addr   => '00:17:E3:37:76:BB',
        remote_port   => 9,
    );

    # then later....

    my $response = $res->parse_sock( $sock, $is_this_a_connect_response )
        or die $res->error;

To cut down on the code for additional reads from the socket to collect
all the packet headers you may want to use the C<parse_sock()> method.
B<Note:> this was tested only with L<Socket::Class> socket object, but
in theory should work with all objects which provide C<read()>
(implemented in a L<Socket::Class> fashion) and C<error()> methods.

Takes one mandatory and one optional arguments. The first argument is
the socket object which we will read from (it must be connected and
ready to be read from). The second optional argument is either true
or false value; if true, the data from the socket will be treated as a
response to C<Connect>, if false the data will be treated as a generic
OBEX packet, it defaults to C<0>.

On failure will return either C<undef> or an empty list depending on the
context and the reason for failure will be available via C<error()> method.

On success returns a hashref with the following keys/values:

Sample dump (description is below):

  $VAR1 = {
    'info' => {
        'flags' => '00000000',
        'packet_length' => 31,
        'obex_version' => '00010000',
        'response_code' => 200,
        'headers_length' => 24,
        'response_code_meaning' => 'OK, Success',
        'mtu' => 5126
    },
    'headers' => {
        'connection_id' => '',
        'who' => '��{ĕ<ҘNRTܞ  '
    },
    'raw_packet' => '�J��{ĕ<ҘNRTܞ   �'
  };

=head3 info

The C<info> key will contain the hashref which is the return value
of C<parse()> method (see above).

=head3 headers

The C<headers> key will contain a hashref which is the return value of
the C<parse()> method of the L<Net::OBEX::Packet::Headers> object, see
L<Net::OBEX::Packet::Headers> documentation for details.

=head3 raw_packet

The C<raw_packet> key will contain the raw data representing the packet
as it was read from the socket.

=head2 error

    my $response = $res->parse_sock( $sock, $is_this_a_connect_response )
        or die $res->error;

If an error occurred during the call to C<parse_sock()> method it will
return either C<undef> or an empty list depending on the context and the
reason for the error will be available via C<error()> method. Takes no
arguments, returns a human readable error message.

=head2 obj_connect

    my $obj = $res->obj_connect;

Takes no arguments, returns the L<Net::OBEX::Response::Connect> object
used in parsing.

=head2 obj_generic

    my $obj = $res->obj_generic;

Takes no arguments, returns the L<Net::OBEX::Response::Generic> object
used in parsing.

=head2 obj_head

    my $obj = $res->obj_generic;

Takes no arguments, returns the L<Net::OBEX::Packet::Headers> object
used in parsing.

=head1 SEE ALSO

L<Net::OBEX::Packet::Headers>, L<Net::OBEX::Response::Connect>,
L<Net::OBEX::Response::Generic>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut