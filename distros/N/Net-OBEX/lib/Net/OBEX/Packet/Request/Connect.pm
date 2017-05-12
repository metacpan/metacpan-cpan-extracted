
package Net::OBEX::Packet::Request::Connect;

use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

use Carp;
use base qw(Class::Data::Accessor Net::OBEX::Packet::Request::Base);

__PACKAGE__->mk_classaccessors(
    qw(
        mtu
        version
        flags
    )
);

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;
    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    %args = (
        mtu       => 4096,
        version   => "\x10",
        flags     => "\x00",
        headers   => [],

        %args,
    );


    return bless \%args, $class;
}

sub make {
    my $self = shift;
    my $headers = join '', @{ $self->headers };

    my $packet = $self->version . $self->flags . pack 'n', $self->mtu;
    $packet .= $headers;

    $packet = "\x80" . (pack 'n', 3 + length $packet) . $packet;

    return $self->raw( $packet );
}

1;

__END__

=encoding utf8

=for stopwords MTU mtu

=head1 NAME

Net::OBEX::Packet::Request::Connect - create OBEX protocol C<Connect> request packets.

=head1 SYNOPSIS

    use Net::OBEX::Packet::Request::Connect;

    my $conn = Net::OBEX::Packet::Request::Connect->new(
        headers => [ $bunch, $of, $raw, $headers ],
    );

    my $connect_packet = $conn->make;

    $conn->headers([]); # reset headers.

    my $connect_packet2 = $conn->make;

=head1 DESCRIPTION

B<WARNING!!! This module is in an early alpha stage. It is recommended
that you use it only for testing.>

The module provides means to create OBEX protocol C<Connect>
(C<0x80>) packets.
It is used internally by L<Net::OBEX::Packet::Request> module and you
probably want to use that instead.

=head1 CONSTRUCTOR

=head2 new

    my $conn = Net::OBEX::Packet::Request::Connect->new;

    my $conn2 = Net::OBEX::Packet::Request::Connect->new(
        mtu       => 4096,
        version   => "\x10",
        flags     => "\x00",
        headers   => [ $bunch, $of, $raw, $headers ],
    );

Returns a brand new Net::OBEX::Packet::Request::Connect object, takes
several arguments, all of which are optional. Possible arguments are
as follows:

=head3 headers

    my $conn2 = Net::OBEX::Packet::Request::Connect->new(
        headers   => [ $bunch, $of, $raw, $headers ],
    );

B<Optional>. Takes an arrayref as a value elements of which are raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those. B<Defaults to:> C<[]> (no headers)

=head3 mtu

    my $conn2 = Net::OBEX::Packet::Request::Connect->new( mtu => 4096 );

B<Optional> Specifies the MTU (Maximum Transmission Unit), or in
other words, the largest packet the device can accept. B<Defaults to:>
C<4096>

=head3 version

    my $conn2 = Net::OBEX::Packet::Request::Connect->new(
        version => "\x10",
    );

B<Optional>. Takes a byte representing the OBEX protocol version used
in the conversation encoded with the major number in the high
order 4 bits, and the minor version in the low order 4 bits.
B<Defaults to:> C<"\x10"> (version 1.0) and you probably don't want to
change that right now.

=head3 flags

    my $conn2 = Net::OBEX::Packet::Request::Connect->new(
        flags => "\x00",
    );

B<Optional>. Takes a byte representing the connect packet "flags".
Currently the all bits of the request packet flags are reserved and
must be set to zero, therefore you shouldn't be using this one.
B<Defaults to:> C<"\x00"> (all bits set to zero)

=head1 METHODS

=head2 make

    my $raw_packet = $conn->make;

Takes no arguments, returns a raw OBEX Connect packet ready to go
down the wire.

=head1 ACCESSORS/MUTATORS

=head2 headers

    my $old_headers_ref = $conn->headers;

    $conn->headers( [ $bunch, $of, $raw, $headers ] );

Takes an arrayref as a value elements of which are raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those. If you want your packet to have no headers specify an empty
arrayref (C<[]>) as an argument. Returns an arrayref of currently set
headers.

=head2 raw

    my $raw_packet = $conn->raw;

Must be called after a call to C<make()> (see above). Takes no
arguments. Returns the raw
packet which was made with last C<make()> (i.e. the return value of
last C<make()>).

=head2 mtu

    my $old_mtu = $conn->mtu;

    $conn->mtu(1024);

Returns a currently set MTU, the maximum length of a packet the
device can accept. Takes one argument which is the MTU in bytes.

=head2 version

    my $old_version = $conn->version;

    $conn->version( "\x10" );

Returns a byte representing the currently set OBEX protocol version.
Takes one optional argument which is the byte representing the
OBEX protocol version to use encoded with the major number in the high
order 4 bits, and the minor version in the low order 4 bits.
You probably don't want to play with this.

=head2 flags

    my $old_flags = $conn->flags;

    $conn->flags("\x00");

Returns a byte representing the currently set Connect packet "flags".
Takes one optional argument which is the byte representing
Connect pack "flags" to use. In the request Connect packet all bits
of "flags" byte are B<reserved>, thus you probably don't want to play
with this.

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