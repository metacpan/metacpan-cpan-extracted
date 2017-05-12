package Net::BitTorrent::Protocol::BEP03;
our $VERSION = "1.5.3";
use Carp qw[carp];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (
    build => [
        qw[ build_handshake build_keepalive build_choke build_unchoke
            build_interested build_not_interested build_have
            build_bitfield build_request build_piece build_cancel
            build_port ]
    ],
    parse => [
        qw[ parse_handshake parse_keepalive
            parse_choke parse_unchoke parse_interested
            parse_not_interested parse_have parse_bitfield
            parse_request parse_piece parse_cancel parse_port ]
    ],
    types => [
        qw[ $HANDSHAKE $KEEPALIVE $CHOKE $UNCHOKE $INTERESTED
            $NOT_INTERESTED $HAVE $BITFIELD $REQUEST $PIECE $CANCEL $PORT ]
    ]
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;
#
our $HANDSHAKE      = -1;
our $KEEPALIVE      = '';
our $CHOKE          = 0;
our $UNCHOKE        = 1;
our $INTERESTED     = 2;
our $NOT_INTERESTED = 3;
our $HAVE           = 4;
our $BITFIELD       = 5;
our $REQUEST        = 6;
our $PIECE          = 7;
our $CANCEL         = 8;
our $PORT           = 9;
#
my $info_hash_constraint;

sub build_handshake {
    my ($reserved, $infohash, $peerid) = @_;
    if ((!defined $reserved) || (length $reserved != 8)) {
        carp sprintf
            '%s::build_handshake() requires 8 bytes of reserved data',
            __PACKAGE__;
        return;
    }
    if ((!defined $infohash) || (length $infohash != 20)) {
        carp sprintf '%s::build_handshake() requires proper infohash',
            __PACKAGE__;
        return;
    }
    if ((!defined $peerid) || (length $peerid != 20)) {
        carp sprintf '%s::build_handshake() requires a well formed peer id',
            __PACKAGE__;
        return;
    }
    return pack 'c/a* a8 a20 a20', 'BitTorrent protocol',
        $reserved, $infohash,
        $peerid;
}
sub build_keepalive      { return pack('N',  0); }
sub build_choke          { return pack('Nc', 1, 0); }
sub build_unchoke        { return pack('Nc', 1, 1); }
sub build_interested     { return pack('Nc', 1, 2); }
sub build_not_interested { return pack('Nc', 1, 3); }

sub build_have {
    my ($index) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf
            '%s::build_have() requires an integer index parameter',
            __PACKAGE__;
        return;
    }
    return pack('NcN', 5, 4, $index);
}

sub build_bitfield {
    my ($bitfield) = @_;
    if ((!$bitfield) || (unpack('b*', $bitfield) !~ m[^[01]+$])) {
        carp sprintf 'Malformed bitfield passed to %s::build_bitfield()',
            __PACKAGE__;
        return;
    }
    return
        pack('Nca*',
             (length($bitfield) + 1),
             5, pack 'B*', unpack 'b*', $bitfield);
}

sub build_request {
    my ($index, $offset, $length) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf
            '%s::build_request() requires an integer index parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $offset) || ($offset !~ m[^\d+$])) {
        carp sprintf '%s::build_request() requires an offset parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $length) || ($length !~ m[^\d+$])) {
        carp sprintf '%s::build_request() requires an length parameter',
            __PACKAGE__;
        return;
    }
    my $packed = pack('NNN', $index, $offset, $length);
    return pack('Nca*', length($packed) + 1, 6, $packed);
}

sub build_piece {
    my ($index, $offset, $data) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf '%s::build_piece() requires an index parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $offset) || ($offset !~ m[^\d+$])) {
        carp sprintf '%s::build_piece() requires an offset parameter',
            __PACKAGE__;
        return;
    }
    if (!defined $data) {
        carp sprintf '%s::build_piece() requires data to work with',
            __PACKAGE__;
        return;
    }
    my $packed = pack('N2a*', $index, $offset, $data);
    return pack('Nca*', length($packed) + 1, 7, $packed);
}

sub build_cancel {
    my ($index, $offset, $length) = @_;
    if ((!defined $index) || ($index !~ m[^\d+$])) {
        carp sprintf
            '%s::build_cancel() requires an integer index parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $offset) || ($offset !~ m[^\d+$])) {
        carp sprintf '%s::build_cancel() requires an offset parameter',
            __PACKAGE__;
        return;
    }
    if ((!defined $length) || ($length !~ m[^\d+$])) {
        carp sprintf '%s::build_cancel() requires an length parameter',
            __PACKAGE__;
        return;
    }
    my $packed = pack('N3', $index, $offset, $length);
    return pack('Nca*', length($packed) + 1, 8, $packed);
}

sub build_port {
    my ($port) = @_;
    if ((!defined $port) || ($port !~ m[^\d+$])) {
        carp sprintf '%s::build_port() requires an index parameter',
            __PACKAGE__;
        return;
    }
    return pack('Ncnn', length($port) + 1, 9, $port);
}

sub parse_handshake {
    my ($packet) = @_;
    if (!$packet || (length($packet) < 68)) {
        return {fatal => 1, error => 'Not enough data for HANDSHAKE'};
    }
    my ($protocol_name, $reserved, $infohash, $peerid)
        = unpack('c/a a8 a20 a20', $packet);
    if ($protocol_name ne 'BitTorrent protocol') {
        return {fatal => 1,
                error => sprintf('Improper HANDSHAKE; Bad protocol name (%s)',
                                 $protocol_name)
        };
    }
    return [$reserved, $infohash, $peerid];
}
sub parse_keepalive      { return; }
sub parse_choke          { return; }
sub parse_unchoke        { return; }
sub parse_interested     { return; }
sub parse_not_interested { return; }

sub parse_have {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 1)) {
        return {fatal => 1, error => 'Incorrect packet length for HAVE'};
    }
    return unpack('N', $packet);
}

sub parse_bitfield {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 1)) {
        return {fatal => 1, error => 'Incorrect packet length for BITFIELD'};
    }
    return (pack 'b*', unpack 'B*', $packet);
}

sub parse_request {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 9)) {
        return {fatal => 1,
                error =>
                    sprintf(
                      'Incorrect packet length for REQUEST (%d requires >=9)',
                      length($packet || ''))
        };
    }
    return ([unpack('N3', $packet)]);
}

sub parse_piece {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 9)) {
        return {
            fatal => 1,
            error =>
                sprintf('Incorrect packet length for PIECE (%d requires >=9)',
                        length($packet || ''))
        };
    }
    return ([unpack('N2a*', $packet)]);
}

sub parse_cancel {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 9)) {
        return {fatal => 1,
                error =>
                    sprintf(
                       'Incorrect packet length for CANCEL (%d requires >=9)',
                       length($packet || ''))
        };
    }
    return ([unpack('N3', $packet)]);
}

sub parse_port {
    my ($packet) = @_;
    if ((!$packet) || (length($packet) < 1)) {
        return {fatal => 1, error => 'Incorrect packet length for PORT'};
    }
    return (unpack 'nn', $packet);
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP03 - Packet Utilities for BEP03, the Basic BitTorrent Wire Protocol

=head1 Synopsis

    use Net::BitTorrent::Protocol::BEP03 qw[:build];

    # Tell them what we want...
    my $handshake = build_handshake(
        pack('C*', split('', '00000000')),
        pack('H*', 'ddaa46b1ddbfd3564fca526d1b68420b6cd54201'),
        'your-peer-id-in-here'
    );

    # And the inverse...
    use Net::BitTorrent::Protocol::BEP03 qw[:parse];
    my ($reserved, $infohash, $peerid) = parse_handshake( $handshake );

=head1 Description

What would BitTorrent be without packets? TCP noise, mostly.

For similar work and the specifications behind these packets, move on down to
the L<See Also|/"See Also"> section.

If you're looking for quick, pure Perl bencode/bdecode functions, you should
give L<Net::BitTorrent::Protocol::BEP03::Bencode> a shot.

=head1 Importing from Net::BitTorrent::Protocol::BEP03

There are three tags available for import. To get them all in one go, use the
C<:all> tag.

=over

=item C<:types>

Packet types

For more on what these packets actually mean, see the BitTorrent Spec. This is
a list of the currently supported packet types:

=over

=item C<$HANDSHAKE>

=item C<$KEEPALIVE>

=item C<$CHOKE>

=item C<$UNCHOKE>

=item C<$INTERESTED>

=item C<$NOT_INTERESTED>

=item C<$HAVE>

=item C<$BITFIELD>

=item C<$REQUEST>

=item C<$PIECE>

=item C<$CANCEL>

=item C<$PORT>

=back

=item C<:build>

These create packets ready-to-send to remote peers. See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets. The same packet
types we can build, we can also parse.  See
L<Parsing Functions|/"Parsing Functions">.

=back

=head2 Building Functions

=over

=item C<build_handshake ( $reserved, $infohash, $peerid )>

Creates an initial handshake packet. All parameters must conform to the
BitTorrent spec:

=over

=item C<$reserved>

...is the 8 byte string used to represent a client's capabilities for
extensions to the protocol.

=item C<$infohash>

...is the 20 byte SHA1 hash of the bencoded info from the metainfo file.

=item C<$peerid>

...is 20 bytes. Be creative.

=back

=item C<build_keepalive ( )>

Creates a keep-alive packet. The keep-alive packet is zero bytes, specified
with the length prefix set to zero. There is no message ID and no payload.
Peers may close a connection if they receive no packets (keep-alive or any
other packet) for a certain period of time, so a keep-alive packet must be
sent to maintain the connection alive if no command have been sent for a given
amount of time. This amount of time is generally two minutes.

=item C<build_choke ( )>

Creates a choke packet. The choke packet is fixed-length and has no payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_unchoke ( )>

Creates an unchoke packet. The unchoke packet is fixed-length and has no
payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_interested ( )>

Creates an interested packet. The interested packet is fixed-length and has
no payload.

=item C<build_not_interested ( )>

Creates a not interested packet. The not interested packet is fixed-length
and has no payload.

=item C<build_have ( $index )>

Creates a have packet. The have packet is fixed length. The payload is the
zero-based INDEX of a piece that has just been successfully downloaded and
verified via the hash.

I<That is the strict definition, in reality some games may be played. In
particular because peers are extremely unlikely to download pieces that they
already have, a peer may choose not to advertise having a piece to a peer that
already has that piece. At a minimum "HAVE suppression" will result in a 50%
reduction in the number of HAVE packets, this translates to around a 25-35%
reduction in protocol overhead. At the same time, it may be worthwhile to send
a HAVE packet to a peer that has that piece already since it will be useful in
determining which piece is rare.>

I<A malicious peer might also choose to advertise having pieces that it knows
the peer will never download. Due to this, attempting to model peers using
this information is a bad idea.>

=item C<build_bitfield ( $bitfield )>

Creates a bitfield packet. The bitfield packet is variable length, where C<X>
is the length of the C<$bitfield>. The payload is a C<$bitfield> representing
the pieces that have been successfully downloaded. The high bit in the first
byte corresponds to piece index 0. Bits that are cleared indicated a missing
piece, and set bits indicate a valid and available piece. Spare bits at the
end are set to zero.

A bitfield packet may only be sent immediately after the
L<handshake|/"build_handshake ( $reserved, $infohash, $peerid )"> sequence is
completed, and before any other packets are sent. It is optional, and need not
be sent if a client has no pieces or uses one of the Fast Extension packets:
L<have all|Net::BitTorrent::Protocol::BEP06/"build_have_all ( )"> or
L<have none|Net::BitTorrent::Protocol::BEP06/"build_have_none ( )">.

=begin :parser

I<A bitfield of the wrong length is considered an error. Clients should drop
the connection if they receive bitfields that are not of the correct size, or
if the bitfield has any of the spare bits set.>

=end :parser

=item C<build_request ( $index, $offset, $length )>

Creates a request packet. The request packet is fixed length, and is used to
request a block. The payload contains the following information:

=over

=item C<$index>

...is an integer specifying the zero-based piece index.

=item C<$offset>

...is an integer specifying the zero-based byte offset within the piece.

=item C<$length>

...is an integer specifying the requested length.

=back

See Also: L<build_cancel|/"build_cancel ( $index, $offset, $length )">

=item C<build_piece ( $index, $offset, $data )>

Creates a piece packet. The piece packet is variable length, where C<X> is
the length of the C<$data>. The payload contains the following information:

=over

=item C<$index>

...is an integer specifying the zero-based piece index.

=item C<$offset>

...is an integer specifying the zero-based byte offset within the piece.

=item C<$data>

...is the block of data, which is a subset of the piece specified by C<$index>.

=back

Before sending pieces to remote peers, the client should verify that the piece
matches the SHA1 hash related to it in the .torrent metainfo.

=item C<build_cancel ( $index, $offset, $length )>

Creates a cancel packet. The cancel packet is fixed length, and is used to
cancel L<block requests|/"build_request ( $index, $offset, $length )">. The
payload is identical to that of the
L<request|/"build_request ( $index, $offset, $length )"> packet. It is
typically used during 'End Game.'

See Also: http://tinyurl.com/NB-docs-EndGame - End Game

=item C<build_port ( $port )>

Creates a packet containing the listen port a peer's DHT node is listening on.

Please note that the port packet has been replaced by parts of the
L<extension protocol|Net::BitTorrent::Protocol::BEP10> and is no longer used
by a majority of modern clients. I have provided it here only for legacy
support; it will not be removed from this module unless it is removed from the
official specification.

=back

=head2 Parsing Functions

These are the parsing counterparts for the C<build_> functions.

When the packet is invalid, a hash reference is returned with the following
keys:

=over

=item C<error>

The value is a string describing what went wrong.

=item C<fatal>

If parsing the packet is impossible, this is true. For other problems (not
enough data, etc.), an untrue value is here.

=back


Return values for valid packets are explained below.

=over

=item C<parse_handshake( $data )>

Returns an array reference containing the C<$reserved_bytes>, C<$infohash>,
and C<$peerid]>.

=item C<parse_keepalive( $data )>

Returns an empty list. Keepalive packets do not contain a playload.

=item C<parse_choke( $data )>

Returns an empty list. Choke packets do not contain a playload.

=item C<parse_unchoke( $data )>

Returns an empty list. Unchoke packets do not contain a playload.

=item C<parse_interested( $data )>

Returns an empty list. Interested packets do not contain a playload.

=item C<parse_not_interested( $data )>

Returns an empty list. Not interested packets do not contain a playload.

=item C<parse_have( $data )>

Returns an integer.

=item C<parse_bitfield( $data )>

Returns the packed bitfield in ascending order. This makes things easy when
working with C<vec(...)>.

=item C<parse_request( $data )>

Returns an array reference containing the C<$index>, C<$offset>, and
C<$length>.

=item C<parse_piece( $data )>

Returns an array reference containing teh C<$index>, C<$offset>, and
C<$block>.

=item C<parse_cancel( $data )>

Returns an array reference containing the C<$index>, C<$offset>, and
C<$length>.

=item C<parse_port( $data )>

Returns a single integer containing the listen port a peer's DHT node is
listening on.

=back

=head1 See Also

http://bittorrent.org/beps/bep_0003.html - The BitTorrent Protocol
Specification

http://wiki.theory.org/BitTorrentSpecification - An annotated guide to the
BitTorrent protocol

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2016 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=cut
