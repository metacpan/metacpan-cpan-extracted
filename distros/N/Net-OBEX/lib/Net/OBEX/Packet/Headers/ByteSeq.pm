
package Net::OBEX::Packet::Headers::ByteSeq;

use strict;
use warnings;
use Carp;

use base 'Net::OBEX::Packet::Headers::Base';

our $VERSION = '1.001001'; # VERSION

my %Header_HI_For = (
    type            => "\x42",
    time            => "\x44",
    target          => "\x46",
    http            => "\x47",
    body            => "\x48",
    end_of_body     => "\x49",
    who             => "\x4A",
    app_params      => "\x4C",
    auth_challenge  => "\x4D",
    auth_response   => "\x4E",
    object_class    => "\x4F",
);


sub new {
    my ( $class, $name, $value ) = @_;

    croak "Missing header name or HI identifier"
        unless defined $name;

    $name = $Header_HI_For{ lc $name }
        if exists $Header_HI_For{ lc $name };

    $value = ''
        unless defined $value;

    return bless {
        value  => $value,
        hi     => $name,
    }, $class;
}

sub make {
    my $self = shift;

    my $value = $self->value;
    unless ( length $value ) {
        return $self->hi . "\x00\x03";
    }

    my $header = $self->hi; # header code
    $header .= pack 'n', 3 + length $value;
    $header .= $value;
    return $self->header($header);
}

1;

__END__

=encoding utf8

=for stopwords html

=head1 NAME

Net::OBEX::Packet::Headers::ByteSeq - construct
"byte sequence" OBEX headers.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Net::OBEX::Packet::Headers::ByteSeq;

    my $raw = Net::OBEX::Packet::Headers::ByteSeq->new(
        target  => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09'
    )->make;

=head1 DESCRIPTION

B<WARNING!!! This module is still in alpha stage. Use it for test purposes
only as interface might change in the future>.

The module provides means to create OBEX protocol C<0x40>
(byte sequence, length prefixed with 2 byte unsigned integer)
packet headers. Unless you are making a custom header you
probably want to use L<Net::OBEX::Packet::Headers> instead.

=head1 CONSTRUCTOR

=head2 new

    # OBEX FTP "Target" header
    my $header
    = Net::OBEX::Packet::Headers::ByteSeq->new(
        target  => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09'
    );

    # Custom header with HI of 0x41
    my $header
    = Net::OBEX::Packet::Headers::ByteSeq->new( "\x41" => 'foos' );

Constructs and returns a Net::OBEX::Packet::Headers::Byte object.
Two arguments: first is the byte of the HI identifier of the header
and second argument is the 1 byte value of the header.
B<Note:> instead of the HI identifier byte you may use one of the names
of standard OBEX headers. The possible names you can use are as follows:

=over 10

=item type

The C<Type> header (type of object - e.g. text, html, binary,
manufacturer specific)

=item time

The C<Time> header (date/time stamp - ISO 8601 version
- preferred)

=item target

The C<Target> header (name of the service that operation is targeted to)

=item http

The C<HTTP> header (an HTTP 1.x header)

=item body

The C<Body> header (a chunk of the object body)

=item end_of_body

The C<End of Body> header (the final chunk of the object body)

=item who

The C<Who> header (identifies the OBEX application, used to tell if
talking to a peer)

=item app_params

The C<App. Parameters> header (extended application request and response
information)

=item auth_challenge

The C<Auth. Challenge> header (authentication digest-challenge)

=item auth_response

The C<Auth. Response> header (authentication digest-response)

=item object_class

The C<Object Class> header (OBEX Object class of object)

=back

=head1 METHODS

=head2 make

    my $raw_header = $header->make;

Takes no arguments, returns a raw data of the header suitable to go down
the wire.

=head2 header

    my $raw_header = $header->header;

Must be called after a call to C<make()>. Takes no arguments,
return value is the return of C<make()>, the only difference is that
data has been "made" already.

=head2 value

    my $old_value = $header->value;

    $header->value( $new_value );

Returns the currently set header value (see C<new()> method). If
called with an optional argument will set the header value to the
value of the argument, and the following calls to C<make()> will
produce headers with this new value.

=head2 hi

    my $old_hi = $header->hi;

    $header->hi( "\x41" );

Returns the currently set header HI identifier. If
called with an optional argument will set the header HI identifier to the
value of the argument, and the following calls to C<make()> will
produce headers with this new HI.

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