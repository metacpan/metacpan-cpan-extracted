
package Net::OBEX::Packet::Headers::Byte4;

use strict;
use warnings;
use Carp;

use base 'Net::OBEX::Packet::Headers::Base';

our $VERSION = '1.001001'; # VERSION

my %Header_HI_For = (
    count           => "\xC0",
    length          => "\xC3",
    timeb           => "\xC4",
    connection_id   => "\xCB",
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


1;

__END__

=encoding utf8

=for stopwords timeb

=head1 NAME

Net::OBEX::Packet::Headers::Byte4 - construct
"4-byte sequence" OBEX headers.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Net::OBEX::Packet::Headers::Byte4;

    my $raw = Net::OBEX::Packet::Headers::Byte4->new(
        connection_id   => '1234',
    )->make;

=head1 DESCRIPTION

B<WARNING!!! This module is still in alpha stage. Use it for test purposes
only as interface might change in the future>.

The module provides means to create OBEX protocol C<0xC0>
(4 byte quantity - transmitted in network byte order (high byte first))
packet headers.
Unless you are making a custom header you
probably want to use L<Net::OBEX::Packet::Headers> instead.

=head1 CONSTRUCTOR

=head2 new

    # "Connection ID" header
    my $header
    = Net::OBEX::Packet::Headers::Byte4->new( connection_id => 'foos' );

    # Custom header with HI of 0xC9
    my $header
    = Net::OBEX::Packet::Headers::Byte4->new( "\xC9" => 'foos' );

Constructs and returns a Net::OBEX::Packet::Headers::Byte4 object.
Two arguments: first is the byte of the HI identifier of the header
and second argument is the 1 byte value of the header.
B<Note:> instead of the HI identifier byte you may use one of the names
of standard OBEX headers. The possible names you can use are as follows:

=over 10

=item count

The C<Count> header (Number of objects (used by Connect))

=item length

The C<Length> header (the length of the object in bytes)

=item timeb

(B<note the 'b'>) The C<Time> header (date/time stamp - 4 byte version
(for compatibility only)) See C<time> in
L<Net::OBEX::Packet::Headers::ByteSeq> for the
preferred time header.

=item connection_id

The C<Connection ID> header (an identifier used for OBEX connection
multiplexing)

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

    $header->hi( "\xC9" );

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