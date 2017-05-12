#!/usr/bin/perl -w
package Net::BitTorrent::Protocol;
{
    use strict;
    use warnings;
    use Carp qw[carp];
    use lib q[../../../lib];
    use Net::BitTorrent::Util qw[:bencode];
    use version qw[qv];
    our $VERSION_BASE = 50; our $UNSTABLE_RELEASE = 0; our $VERSION = sprintf(($UNSTABLE_RELEASE ? q[%.3f_%03d] : q[%.3f]), (version->new(($VERSION_BASE))->numify / 1000), $UNSTABLE_RELEASE);
    use vars qw[@EXPORT_OK %EXPORT_TAGS];
    use Exporter qw[];
    *import = *import = *Exporter::import;
    @EXPORT_OK = qw[build_handshake build_keepalive build_choke build_unchoke
        build_interested  build_not_interested build_have build_bitfield
        build_request build_piece build_cancel build_port build_suggest
        build_allowed_fast build_reject build_have_all build_have_none
        build_extended parse_packet _parse_handshake _parse_keepalive
        _parse_choke _parse_unchoke _parse_interested _parse_not_interested
        _parse_have _parse_bitfield _parse_request _parse_piece _parse_cancel
        _parse_port _parse_suggest _parse_have_all _parse_have_none
        _parse_reject _parse_allowed_fast _parse_extended HANDSHAKE KEEPALIVE
        CHOKE UNCHOKE INTERESTED NOT_INTERESTED HAVE BITFIELD REQUEST PIECE
        CANCEL PORT SUGGEST HAVE_ALL HAVE_NONE REJECT ALLOWED_FAST EXTPROTOCOL
        _build_dht_reply_get_peers _build_dht_query_get_peers
        _build_dht_reply_values    _build_dht_query_announce
        _build_dht_reply_ping      _build_dht_query_ping
        _build_dht_reply_find_node _build_dht_query_find_node];
    %EXPORT_TAGS = (
        all   => [@EXPORT_OK],
        build => [
            qw[build_handshake build_keepalive build_choke build_unchoke
                build_interested  build_not_interested build_have
                build_bitfield build_request build_piece build_cancel
                build_port build_suggest build_allowed_fast build_reject
                build_have_all build_have_none build_extended]
        ],
        parse => [
            qw[parse_packet _parse_handshake _parse_keepalive
                _parse_choke _parse_unchoke _parse_interested
                _parse_not_interested _parse_have _parse_bitfield
                _parse_request _parse_piece _parse_cancel _parse_port
                _parse_suggest _parse_have_all _parse_have_none
                _parse_reject _parse_allowed_fast _parse_extended]
        ],
        types => [
            qw[HANDSHAKE KEEPALIVE CHOKE UNCHOKE INTERESTED NOT_INTERESTED
                HAVE BITFIELD REQUEST PIECE CANCEL PORT SUGGEST HAVE_ALL
                HAVE_NONE REJECT ALLOWED_FAST EXTPROTOCOL]
        ],
        dht => [
            qw[_build_dht_reply_get_peers _build_dht_query_get_peers
                _build_dht_reply_values    _build_dht_query_announce
                _build_dht_reply_ping      _build_dht_query_ping
                _build_dht_reply_find_node _build_dht_query_find_node]
        ],

        # XXX - Move MSE-related functions from N::B::Peer
        #mse => [qw[  ]]
    );
    sub HANDSHAKE      {-1}
    sub KEEPALIVE      {q[]}
    sub CHOKE          {0}
    sub UNCHOKE        {1}
    sub INTERESTED     {2}
    sub NOT_INTERESTED {3}
    sub HAVE           {4}
    sub BITFIELD       {5}
    sub REQUEST        {6}
    sub PIECE          {7}
    sub CANCEL         {8}
    sub PORT           {9}
    sub SUGGEST        {13}
    sub HAVE_ALL       {14}
    sub HAVE_NONE      {15}
    sub REJECT         {16}
    sub ALLOWED_FAST   {17}
    sub EXTPROTOCOL    {20}

    sub build_handshake {
        my ($reserved, $infohash, $peerid) = @_;
        if (   (grep { not defined } @_[0 .. 2])
            || (length($reserved) != 8)
            || (length($infohash) != 20)
            || (length($peerid) != 20))
        {   carp
                q[Malformed parameters for Net::BitTorrent::Protocol::build_handshake()];
            return;
        }
        return
            pack(q[c/a* a8 a20 a20],
                 q[BitTorrent protocol],
                 $reserved, $infohash, $peerid);
    }
    sub build_keepalive      { return pack(q[N],  0); }
    sub build_choke          { return pack(q[Nc], 1, 0); }
    sub build_unchoke        { return pack(q[Nc], 1, 1); }
    sub build_interested     { return pack(q[Nc], 1, 2); }
    sub build_not_interested { return pack(q[Nc], 1, 3); }

    sub build_have {
        my ($index) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_have() requires an integer index parameter];
            return;
        }
        return pack(q[NcN], 5, 4, $index);
    }

    sub build_bitfield {
        my ($bitfield) = @_;
        if ((!$bitfield) || (unpack(q[b*], $bitfield) !~ m[^[01]+$])) {
            carp
                q[Malformed bitfield passed to Net::BitTorrent::Protocol::build_bitfield()];
            return;
        }
        return pack(q[Nca*], (length($bitfield) + 1), 5, $bitfield);
    }

    sub build_request {
        my ($index, $offset, $length) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_request() requires an integer index parameter];
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_request() requires an offset parameter];
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_request() requires an length parameter];
            return;
        }
        my $packed = pack(q[NNN], $index, $offset, $length);
        return pack(q[Nca*], length($packed) + 1, 6, $packed);
    }

    sub build_piece {
        my ($index, $offset, $data) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_piece() requires an index parameter];
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_piece() requires an offset parameter];
            return;
        }
        if (!$data or !$$data) {
            carp
                q[Net::BitTorrent::Protocol::build_piece() requires data to work with];
            return;
        }
        my $packed = pack(q[N2a*], $index, $offset, $$data);
        return pack(q[Nca*], length($packed) + 1, 7, $packed);
    }

    sub build_cancel {
        my ($index, $offset, $length) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_cancel() requires an integer index parameter];
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_cancel() requires an offset parameter];
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_cancel() requires an length parameter];
            return;
        }
        my $packed = pack(q[N3], $index, $offset, $length);
        return pack(q[Nca*], length($packed) + 1, 8, $packed);
    }

    sub build_port {
        my ($port) = @_;
        if ((!defined $port) || ($port !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_port() requires an index parameter];
            return;
        }
        return pack(q[NcN], length($port) + 1, 9, $port);
    }

    sub build_suggest {
        my ($index) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_suggest() requires an index parameter];
            return;
        }
        return pack(q[NcN], 5, 13, $index);
    }
    sub build_have_all  { return pack(q[Nc], 1, 14); }
    sub build_have_none { return pack(q[Nc], 1, 15); }

    sub build_reject {
        my ($index, $offset, $length) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_reject() requires an index parameter];
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_reject() requires an offset parameter];
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_reject() requires an length parameter];
            return;
        }
        my $packed = pack(q[N3], $index, $offset, $length);
        return pack(q[Nca*], length($packed) + 1, 16, $packed);
    }

    sub build_allowed_fast {
        my ($index) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_allowed_fast() requires an index parameter];
            return;
        }
        return pack(q[NcN], 5, 17, $index);
    }

    sub build_extended {
        my ($msgID, $data) = @_;
        if ((!defined $msgID) || ($msgID !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::build_extended() requires a message id parameter];
            return;
        }
        if ((!$data) || (ref($data) ne q[HASH])) {
            carp
                q[Net::BitTorrent::Protocol::build_extended() requires a payload];
            return;
        }
        my $packet = pack(q[ca*], $msgID, bencode($data));
        return pack(q[Nca*], length($packet) + 1, 20, $packet);
    }
    my %parse_packet_dispatch = (&KEEPALIVE      => \&_parse_keepalive,
                                 &CHOKE          => \&_parse_choke,
                                 &UNCHOKE        => \&_parse_unchoke,
                                 &INTERESTED     => \&_parse_interested,
                                 &NOT_INTERESTED => \&_parse_not_interested,
                                 &HAVE           => \&_parse_have,
                                 &BITFIELD       => \&_parse_bitfield,
                                 &REQUEST        => \&_parse_request,
                                 &PIECE          => \&_parse_piece,
                                 &CANCEL         => \&_parse_cancel,
                                 &PORT           => \&_parse_port,
                                 &SUGGEST        => \&_parse_suggest,
                                 &HAVE_ALL       => \&_parse_have_all,
                                 &HAVE_NONE      => \&_parse_have_none,
                                 &REJECT         => \&_parse_reject,
                                 &ALLOWED_FAST   => \&_parse_allowed_fast,
                                 &EXTPROTOCOL    => \&_parse_extended
    );

    sub parse_packet {
        my ($data) = @_;
        if ((!$data) || (ref($data) ne q[SCALAR]) || (!$$data)) {
            carp
                q[Net::BitTorrent::Protocol::parse_packet() needs data to parse];
            return;
        }
        my ($packet);
        if (unpack(q[c], $$data) == 0x13) {
            my @payload = _parse_handshake(substr($$data, 0, 68, q[]));
            $packet = {Type    => HANDSHAKE,
                       Payload => @payload
                }
                if @payload;
        }
        elsif (    (defined unpack(q[N], $$data))
               and (unpack(q[N], $$data) =~ m[\d]))
        {   if ((unpack(q[N], $$data) <= length($$data))) {
                (my ($packet_data), $$data) = unpack(q[N/aa*], $$data);
                (my ($type), $packet_data) = unpack(q[ca*], $packet_data);
                if (defined $parse_packet_dispatch{$type}) {
                    my $payload = $parse_packet_dispatch{$type}($packet_data);
                    $packet = {Type => $type,
                               (defined $payload
                                ? (Payload => $payload)
                                : ()
                               )
                    };
                }
                elsif (eval q[require Data::Dump]) {
                    carp
                        sprintf
                        <<'END', Data::Dump::pp($type), Data::Dump::pp($packet);
Unhandled/Unknown packet where:
Type   = %s
Packet = %s
END
                }
            }
        }
        return $packet;
    }

    sub _parse_handshake {
        my ($packet) = @_;
        if (!$packet || (length($packet) < 68)) {

            #carp q[Not enough data for handshake packet];
            return;
        }
        my ($protocol_name, $reserved, $infohash, $peerid)
            = unpack(q[c/a a8 a20 a20], $packet);
        if ($protocol_name ne q[BitTorrent protocol]) {

            #carp sprintf(q[Improper handshake; Bad protocol name (%s)],
            #             $protocol_name);
            return;
        }
        return [$reserved, $infohash, $peerid];
    }
    sub _parse_keepalive      { return; }
    sub _parse_choke          { return; }
    sub _parse_unchoke        { return; }
    sub _parse_interested     { return; }
    sub _parse_not_interested { return; }

    sub _parse_have {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #carp q[Incorrect packet length for HAVE];
            return;
        }
        return unpack(q[N], $packet);
    }

    sub _parse_bitfield {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #carp q[Incorrect packet length for BITFIELD];
            return;
        }
        return (pack q[b*], unpack q[B*], $packet);
    }

    sub _parse_request {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

           #carp
           #    sprintf(
           #         q[Incorrect packet length for REQUEST (%d requires >=9)],
           #         length($packet || q[]));
            return;
        }
        return ([unpack(q[N3], $packet)]);
    }

    sub _parse_piece {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

           #carp
           #    sprintf(
           #           q[Incorrect packet length for PIECE (%d requires >=9)],
           #           length($packet || q[]));
            return;
        }
        return ([unpack(q[N2a*], $packet)]);
    }

    sub _parse_cancel {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

           #carp
           #    sprintf(
           #          q[Incorrect packet length for CANCEL (%d requires >=9)],
           #          length($packet || q[]));
            return;
        }
        return ([unpack(q[N3], $packet)]);
    }

    sub _parse_port {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #carp q[Incorrect packet length for PORT];
            return;
        }
        return (unpack q[N], $packet);
    }

    sub _parse_suggest {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #carp q[Incorrect packet length for SUGGEST];
            return;
        }
        return unpack(q[N], $packet);
    }
    sub _parse_have_all  { return; }
    sub _parse_have_none { return; }

    sub _parse_reject {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

           #carp
           #    sprintf(
           #          q[Incorrect packet length for REJECT (%d requires >=9)],
           #          length($packet || q[]));
            return;
        }
        return ([unpack(q[N3], $packet)]);
    }

    sub _parse_allowed_fast {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #carp q[Incorrect packet length for FASTSET];
            return;
        }
        return unpack(q[N], $packet);
    }

    sub _parse_extended {
        my ($packet) = @_;
        if ((!$packet) || (!length($packet))) { return; }
        my ($id, $payload) = unpack(q[ca*], $packet);
        return ([$id, scalar bdecode($payload)]);
    }

    sub _build_dht_query_ping {
        my ($tid, $id) = @_;
        if (!defined $tid) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_ping() requires a 'token id' parameter];
            return;
        }
        if (!defined $id) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_ping() requires an 'client id' parameter];
            return;
        }
        return
            bencode({t => $tid,
                     y => q[q],
                     q => q[ping],
                     a => {id => $id},
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_query_announce {
        my ($tid, $id, $infohash, $token, $port) = @_;
        if (!defined $tid) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_announce() requires a 'token id' parameter];
            return;
        }
        if (!defined $id) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_announce() requires an 'client id' parameter];
            return;
        }
        if (!defined $token) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_announce() requires an 'token' parameter];
            return;
        }
        if ((!defined $infohash) || (length($infohash) != 20)) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_announce() requires an 'infohash' parameter];
            return;
        }
        if ((!defined $tid) || ($port !~ m[^\d+$])) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_ping() requires a 'port' parameter];
            return;
        }
        return
            bencode({t => $tid,
                     y => q[q],
                     q => q[announce_peer],
                     a => {id        => $id,
                           port      => $port,
                           info_hash => $infohash,
                           token     => $token
                     },
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_query_find_node {
        my ($tid, $id, $target) = @_;
        if (!defined $tid) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_find_node() requires a 'token id' parameter];
            return;
        }
        if (!defined $id) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_find_node() requires an 'client id' parameter];
            return;
        }
        if ((!defined $target) || (length($target) != 20)) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_find_node() requires an 'target' parameter];
            return;
        }
        return
            bencode({t => $tid,
                     y => q[q],
                     q => q[find_node],
                     a => {id     => $id,
                           target => $target
                     },
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_query_get_peers {
        my ($tid, $id, $info_hash) = @_;
        if (!defined $tid) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_get_peers() requires a 'token id' parameter];
            return;
        }
        if (!defined $id) {
            carp
                q[Net::BitTorrent::Protocol::_build_dht_query_get_peers() requires an 'client id' parameter];
            return;
        }
        if ((!defined $info_hash) || (length($info_hash) != 20)) {
            Carp::confess
                q[Net::BitTorrent::Protocol::_build_dht_query_get_peers() requires an 'info_hash' parameter];
            return;
        }
        return
            bencode({t => $tid,
                     y => q[q],
                     q => q[get_peers],
                     a => {id => $id, info_hash => $info_hash},
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_reply_ping {
        my ($tid, $id) = @_;
        return bencode(
                      {t => $tid, y => q[r], r => {id => $id}, v => q[NB00]});
    }

    sub _build_dht_reply_find_node {
        my ($tid, $id, $nodes) = @_;
        return
            bencode({t => $tid,
                     y => q[r],
                     r => {id => $id, nodes => $nodes},
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_reply_get_peers {
        my ($tid, $id, $nodes, $token) = @_;
        return
            bencode({t => $tid,
                     y => q[r],
                     r => {id => $id, token => $token, nodes => $nodes},
                     v => q[NB00]
                    }
            );
    }

    sub _build_dht_reply_values {
        my ($tid, $id, $values, $token) = @_;
        return
            bencode({t => $tid,
                     y => q[r],
                     r => {id     => $id,
                           token  => $token,
                           values => $values
                     },
                     v => q[NB00]
                    }
            );
    }
    1;
}

=pod

=head1 NAME

Net::BitTorrent::Protocol - Packet utilities for the BitTorrent protocol

=head1 Synopsis

    use Net::BitTorrent::Protocol qw[:build parse_packet];

    # Tell them what we want...
    my $handshake = build_handshake(
        pack('C*', split('', '00000000')),
        pack('H*', 'ddaa46b1ddbfd3564fca526d1b68420b6cd54201'),
        'your-peer-id-in-here'
    );

    # And the inverse...
    my ($reserved, $infohash, $peerid) = parse_packet( $handshake );

=head1 Description

What would BitTorrent be without packets?   TCP noise, mostly.

For similar work and links to the specifications behind these packets,
move on down to the L<See Also|/"See Also"> section.

=head1 Exporting from Net::BitTorrent::Protocol

There are three tags available for import.  To get them all in one go,
use the C<:all> tag.

=over

=item C<:types>

Packet types

For more on what these packets actually mean, see the BitTorrent Spec.
This is a list of the currently supported packet types:

=over

=item HANDSHAKE

=item KEEPALIVE

=item CHOKE

=item UNCHOKE

=item INTERESTED

=item NOT_INTERESTED

=item HAVE

=item BITFIELD

=item REQUEST

=item PIECE

=item CANCEL

=item PORT

=item SUGGEST

=item HAVE_ALL

=item HAVE_NONE

=item REJECT

=item ALLOWED_FAST

=item EXTPROTOCOL

=back

=item C<:build>

These create packets ready-to-send to remote peers.  See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets.

=back

=head2 Building Functions

=over

=item C<build_handshake ( RESERVED, INFOHASH, PEERID )>

Creates an initial handshake packet.  All parameters must conform to
the BitTorrent spec:

=over

=item C<RESERVED>

...is the 8 byte string used to represent a client's capabilities for
extensions to the protocol.

=item C<INFOHASH>

...is the 20 byte SHA1 hash of the bencoded info from the metainfo
file.

=item C<PEERID>

...is 20 bytes.

=back

=item C<build_keepalive ( )>

Creates a keep-alive packet.  The keep-alive packet is zero bytes,
specified with the length prefix set to zero.  There is no message ID and
no payload.  Peers may close a connection if they receive no packets
(keep-alive or any other packet) for a certain period of time, so a keep-
alive packet must be sent to maintain the connection alive if no command
have been sent for a given amount of time.  This amount of time is
generally two minutes.

=item C<build_choke ( )>

Creates a choke packet.  The choke packet is fixed-length and has no
payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_unchoke ( )>

Creates an unchoke packet.  The unchoke packet is fixed-length and
has no payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_interested ( )>

Creates an interested packet.  The interested packet is fixed-length
and has no payload.

=item C<build_not_interested ( )>

Creates a not interested packet.  The not interested packet is
fixed-length and has no payload.

=item C<build_have ( INDEX )>

Creates a have packet.  The have packet is fixed length.  The
payload is the zero-based INDEX of a piece that has just been
successfully downloaded and verified via the hash.

I<That is the strict definition, in reality some games may be played.
In particular because peers are extremely unlikely to download pieces
that they already have, a peer may choose not to advertise having a
piece to a peer that already has that piece.  At a minimum "HAVE
suppression" will result in a 50% reduction in the number of HAVE
packets, this translates to around a 25-35% reduction in protocol
overhead. At the same time, it may be worthwhile to send a HAVE
packet to a peer that has that piece already since it will be useful
in determining which piece is rare.>

I<A malicious peer might also choose to advertise having pieces that
it knows the peer will never download. Due to this attempting to model
peers using this information is a bad idea.>

=item C<build_bitfield ( BITFIELD )>

Creates a bitfield packet.  The bitfield packet is variable length,
where C<X> is the length of the C<BITFIELD>.  The payload is a
C<BITFIELD> representing the pieces that have been successfully
downloaded.  The high bit in the first byte corresponds to piece index
0.  Bits that are cleared indicated a missing piece, and set bits
indicate a valid and available piece. Spare bits at the end are set to
zero.

A bitfield packet may only be sent immediately after the
L<handshaking|/"build_handshake ( RESERVED, INFOHASH, PEERID )">
sequence is completed, and before any other packets are sent.  It is
optional, and need not be sent if a client has no pieces or uses one
of the Fast Extension packets: L<have all|/"build_have_all ( )"> or
L<have none|/"build_have_none ( )">.

=begin :parser

I<A bitfield of the wrong length is considered an error.  Clients
should drop the connection if they receive bitfields that are not of
the correct size, or if the bitfield has any of the spare bits set.>

=end :parser

=item C<build_request ( INDEX, OFFSET, LENGTH )>

Creates a request packet.  The request packet is fixed length, and
is used to request a block.  The payload contains the following
information:

=over

=item C<INDEX>

...is an integer specifying the zero-based piece index.

=item C<OFFSET>

...is an integer specifying the zero-based byte offset within the
piece.

=item C<LENGTH>

...is an integer specifying the requested length.

=back

See Also: L<build_cancel|/"build_cancel ( INDEX, OFFSET, LENGTH )">

=item C<build_piece ( INDEX, OFFSET, DATA )>

Creates a piece packet.  The piece packet is variable length, where
C<X> is the length of the L<DATA>.  The payload contains the following
information:

=over

=item C<INDEX>

...is an integer specifying the zero-based piece index.

=item C<OFFSET>

...is an integer specifying the zero-based byte offset within the
piece.

=item C<DATA>

...is the block of data, which is a subset of the piece specified by
C<INDEX>.

=back

Before sending pieces to remote peers, the client should verify that
the piece matches the SHA1 hash related to it in the .torrent
metainfo.

=item C<build_cancel ( INDEX, OFFSET, LENGTH )>

Creates a cancel packet.  The cancel packet is fixed length, and is
used to cancel
L<block requests|/"build_request ( INDEX, OFFSET, LENGTH )">.  The
payload is identical to that of the
L<request|/"build_request ( INDEX, OFFSET, LENGTH )"> packet.  It is
typically used during 'End Game.'

See Also: http://tinyurl.com/NB-docs-EndGame - End Game

=item C<build_extended ( DATA )>

Creates an extended protocol packet.

=back

=head3 Legacy Packets

The following packets are either part of the base protocol or one of
the common extensions but have either been superseded or simply
removed from the majority of clients.  I have provided them here only
for legacy support; they will not be removed in the future.

=over

=item C<build_port ( PORT )>

Creates a port packet.

See also: http://bittorrent.org/beps/bep_0003.html - The BitTorrent
Protocol Specification

=item C<build_allowed_fast ( INDEX )>

Creates an Allowed Fast packet.

uTorrent never advertises a fast set... why should we?

See also: http://bittorrent.org/beps/bep_0006.html - Fast Extension

=item C<build_suggest ( INDEX )>

Creates a Suggest Piece packet.

Super seeding is not supported by Net::BitTorrent.  Yet.

See also: http://bittorrent.org/beps/bep_0006.html - Fast Extension

=item C<build_reject ( INDEX, OFFSET, LENGTH )>

Creates a Reject Request packet.

See also: http://bittorrent.org/beps/bep_0006.html - Fast Extension

=item C<build_have_all ( )>

Creates a Have All packet.

See also: http://bittorrent.org/beps/bep_0006.html - Fast Extension

=item C<build_have_none ( )>

Creates a Have None packet.

See also: http://bittorrent.org/beps/bep_0006.html - Fast Extension

=back

=head2 Parsing Function(s)

=over

=item C<parse_packet( DATA )>

Attempts to parse any known packet from the data (a scalar ref) passed to it.
On success, the payload and type are returned and the packet is removed from
the incoming data ref.  C<undef> is returned on failure.

=back

=head1 See Also

http://bittorrent.org/beps/bep_0003.html - The BitTorrent Protocol
Specification

http://bittorrent.org/beps/bep_0006.html - Fast Extension

http://bittorrent.org/beps/bep_0010.html - Extension Protocol

http://wiki.theory.org/BitTorrentSpecification - An annotated guide to
the BitTorrent protocol

L<Net::BitTorrent::PeerPacket|Net::BitTorrent::PeerPacket> - by Joshua
McAdams

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2009 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.  See the F<LICENSE>
file included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered
by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

Neither this module nor the L<Author|/Author> is affiliated with
BitTorrent, Inc.

=for svn $Id: Protocol.pm d3c97de 2009-09-12 04:31:46Z sanko@cpan.org $

=cut
