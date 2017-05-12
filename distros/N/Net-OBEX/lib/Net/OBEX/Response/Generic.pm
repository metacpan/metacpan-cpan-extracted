
package Net::OBEX::Response::Generic;


use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

use Carp;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors( qw( headers_length  packet  info ) );


my %Response_meaning_of_code = _make_response_codes();

sub new {
    my $class = shift;
    my $packet = shift;

    my $self = bless {}, $class;

    if ( defined $packet ) {
        $self->packet( $packet );
        $self->info( $self->parse_info( $packet ) );
    }

    return $self;
}

sub parse_info {
    my ( $self, $packet ) = @_;
    $packet = $self->packet
        unless defined $packet;

    my %info;
    @info{ qw( response_code  packet_length) }
    = unpack 'a n', $packet;

    @info{qw( response_code response_code_meaning ) } =
    $self->code_meaning( $info{response_code} );

    $info{headers_length} = $info{packet_length} - 3;
    $self->headers_length( $info{headers_length} );

    return $self->info( \%info );
}

sub code_meaning {
    my ( $class, $code ) = @_;
    return @{ $Response_meaning_of_code{ $code } };
}

sub _make_response_codes {
    return (
        "\x90" => [ 100, 'Continue' ],
        "\xA0" => [ 200, 'OK, Success' ],
        "\xA1" => [ 201, 'Created' ],
        "\xA2" => [ 202, 'Accepted' ],
        "\xA3" => [ 203, 'Non-Authoritative Information' ],
        "\xA4" => [ 204, 'No Content' ],
        "\xA5" => [ 205, 'Reset Content' ],
        "\xA6" => [ 206, 'Partial Content' ],
        "\xB0" => [ 300, 'Multiple Choices' ],
        "\xB1" => [ 301, 'Moved Permanently' ],
        "\xB2" => [ 302, 'Moved temporarily' ],
        "\xB3" => [ 303, 'See Other' ],
        "\xB4" => [ 304, 'Not modified' ],
        "\xB5" => [ 305, 'Use Proxy' ],
        "\xC0" => [ 400, q|Bad Request - server couldn't understand request| ],
        "\xC1" => [ 401, 'Unauthorized' ],
        "\xC2" => [ 402, 'Payment required' ],
        "\xC3" => [ 403, 'Forbidden - operation is understood but refused' ],
        "\xC4" => [ 404, 'Not Found' ],
        "\xC5" => [ 405, 'Method not allowed' ],
        "\xC6" => [ 406, 'Not Acceptable' ],
        "\xC7" => [ 407, 'Proxy Authentication required' ],
        "\xC8" => [ 408, 'Request Time Out' ],
        "\xC9" => [ 409, 'Conflict' ],
        "\xCA" => [ 410, 'Gone' ],
        "\xCB" => [ 411, 'Length Required' ],
        "\xCC" => [ 412, 'Precondition failed' ],
        "\xCD" => [ 413, 'Requested entity too large' ],
        "\xCE" => [ 414, 'Request URL too large' ],
        "\xCF" => [ 415, 'Unsupported media type' ],
        "\xD0" => [ 500, 'Internal Server Error' ],
        "\xD1" => [ 501, 'Not Implemented' ],
        "\xD2" => [ 502, 'Bad Gateway' ],
        "\xD3" => [ 503, 'Service Unavailable' ],
        "\xD4" => [ 504, 'Gateway Timeout' ],
        "\xD5" => [ 505, 'HTTP version not supported' ],
        "\xE0" => [ undef, 'Database Full' ],
        "\xE1" => [ undef, 'Database Locked' ],
    );
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT parseable

=head1 NAME

Net::OBEX::Response::Generic - interpret OBEX protocol generic response packets

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Net::OBEX::Response::Generic;

    my $res = Net::OBEX::Response::Generic->new;

    # read 3 bytes of the packet from the socket there somewhere
    # now parse it:
    my $response_ref = $res->parse_info( $data_from_the_socket );

    if ( $response_ref->{headers_length} ) {
        # ok, looks like we got some headers in this packet
        # read $response_ref->{headers_length} bytes from the socket
        # here and parse the headers.
    }

    # OMG SO COMPLICATED!!
    # Why not use Net::OBEX::Response parse_sock() method instead?

=head1 DESCRIPTION

B<WARNING!!! this module is still in early alpha stage. It is recommended
that you use it only for testing.>

This module is used internally by L<Net::OBEX::Response> and that's what
you probably should be using.
The module provides means to interpret raw OBEX protocol responses. For
parsing C<Connect> responses see L<Net::OBEX::Response::Connect>

=head1 CONSTRUCTOR

=head2 new

    my $res = Net::OBEX::Response::Generic->new;

Takes no arguments, returns a freshly baked Net::OBEX::Response::Generic
object ready to be used and abused.

=head1 METHODS

=head2 parse_info

    $res->packet( $data_from_wire );
    my $generic_response = $res->parse_info;

    # or

    my $generic_response = $res->parse_info( $data_from_wire );

Takes one optional argument which
is the raw data from the wire representing the packet. If called without
arguments will use the data which you set via C<packet()> method (see below)
Returns a hashref with the following keys/values:

Sample return (descriptions are below):

    $VAR1 = {
        'packet_length' => 3,
        'response_code' => 200,
        'headers_length' => 0,
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

=head2 code_meaning

    my ( $http_code, $meaning ) = $res->code_meaning( "\xA0" );

Takes one argument which is the byte representing the response code.
Returns a list of two elements, the first one is the HTTP code of the
response (such as C<404>) the second element is the human parseable meaning
of the code (such as C<Not Found>).

=head2 packet

    my $old_packet = $res->packet;

    $res->packet( $new_data_from_the_wire );

Returns a currently set data of the packet. When called with an optional
argument will set the current data to parse to whatever you specify in
the argument.

=head2 info

    my $info_ref = $res->info;

Must be called after a call to C<parse_info()>. Takes no arguments, returns
a hashref which is the same as the return value of the last call to
C<parse_info()> method. See the description of C<parse_info()> method
above for more information.

=head2 headers_length

    my $length_of_packet_headers = $res->headers_length;

Must be called after a call to C<parse_info()>. Takes no arguments,
returns the length of packet headers in bytes (this is what you still need
to read from the socket to get a complete packet). Note: this is the same
as the contents of C<headers_length> key of the C<parse_info()> return.


=head1 SEE ALSO

L<Net::OBEX::Packet::Headers>, L<Net::OBEX::Response>,
L<Net::OBEX::Response::Connect>

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