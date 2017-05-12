package Net::BitTorrent::Protocol::BEP05;
use strict;
use warnings;
our $VERSION = "1.5.3";
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode];
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use Exporter qw[];
*import = *import = *Exporter::import;
%EXPORT_TAGS = (
    build => [
        qw[build_get_peers_query build_get_peers_reply
            build_announce_peer_query build_announce_peer_reply
            build_ping_query build_ping_reply build_find_node_query
            build_find_node_reply build_error_reply]
    ],
    parse => [qw[ ]],    # XXX - None yet
    query => [
        qw[build_get_peers_query build_announce_peer_query build_ping_query
            build_find_node_query]
    ],
    reply => [
        qw[build_get_peers_reply build_announce_peer_reply build_ping_reply
            build_find_node_reply build_error_reply]
    ]
);
@EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = \@EXPORT_OK;

# Node ID and version
our $v = 'NB' . pack 'C2', $VERSION =~ m[\.(\d+)]g;

#
sub build_ping_query ($$) {
    my ($tid, $nid) = @_;
    return
        bencode({t => $tid,
                 y => 'q',
                 q => 'ping',
                 a => {id => $nid},
                 v => $v
                }
        );
}

sub build_announce_peer_query ($$$$$) {
    my ($tid, $nid, $info_hash, $token, $port) = @_;
    return
        bencode({t => $tid,
                 y => 'q',
                 q => 'announce_peer',
                 a => {id        => $nid,
                       port      => $port,
                       info_hash => $info_hash,
                       token     => $token
                 },
                 v => $v
                }
        );
}

sub build_find_node_query ($$$) {
    my ($tid, $nid, $target) = @_;
    return
        bencode({t => $tid,
                 y => 'q',
                 q => 'find_node',
                 a => {id     => $nid,
                       target => $target
                 },
                 v => $v
                }
        );
}

sub build_get_peers_query ($$$) {
    my ($tid, $nid, $info_hash) = @_;
    return
        bencode({t => $tid,
                 y => 'q',
                 q => 'get_peers',
                 a => {id => $nid, info_hash => $info_hash},
                 v => $v
                }
        );
}

sub build_ping_reply ($$) {
    my ($tid, $nid) = @_;
    return bencode({t => $tid, y => 'r', r => {id => $nid}, v => $v});
}

sub build_announce_peer_reply ($$) {
    my ($tid, $nid) = @_;
    return bencode({t => $tid, y => 'r', r => {id => $nid}, v => $v});
}

sub build_find_node_reply ($$$) {
    my ($tid, $nid, $nodes) = @_;
    return
        bencode({t => $tid,
                 y => 'r',
                 r => {id => $nid, nodes => $nodes},
                 v => $v
                }
        );
}

sub build_get_peers_reply ($$$$$) {
    my ($tid, $nid, $values, $nodes, $token) = @_;
    return
        bencode({t => $tid,
                 y => 'r',
                 r => {id    => $nid,
                       token => $token,
                       (@$values ? (values => $values) : ()),
                       ($nodes   ? (nodes  => $nodes)  : ())
                 },
                 v => $v
                }
        );
}

sub build_error_reply ($@) {
    my ($tid, $error) = @_;
    return
        bencode({t => $tid,
                 y => 'e',
                 e => $error,
                 v => $v
                }
        );
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP05 - Packet Utilities for BEP05: The DHT Protocol

=head1 Description

BitTorrent uses a "distributed sloppy hash table" (DHT) for storing peer
contact information for "trackerless" torrents. In effect, each peer becomes a
tracker. The protocol is based on Kademila and is implemented over UDP. This
module provides packet building functions for this protocol.

=head1 Importing From Net::BitTorrent::Protocol::BEP05

By default, nothing is exported.

You may import any of the following or use one or more of these tag:

=over

=item C<:all>

Imports everything. If you're importing anything, this is probably what you
want.

=item C<:query>

Imports the functions which generate query messages.

=item C<:reply>

Imports the functions which generate proper responses to query messages.

=back

=head1 Functions

Note that all functions require a transaction ID. Please see the
L<related section|/"Transaction IDs"> below. Queries also require a user
generated L<node ID|/"Node IDs">.

=over

=item C<build_get_peers_reply( $tid, $nid, $values, $nodes, $token )>

Generates an appropriate reply to a
L<get_peers query|/"build_get_peers_query( $tid, $nid, $info_hash )">.

=item C<build_get_peers_query( $tid, $nid, $info_hash )>

Generates a C<get_peers> packet. C<$info_hash> is the infohash of the torrent
you're seeking peers for.

If the queried node has peers for the infohash, they are returned in a key
"values" as a list of strings. Each string containing "compact" format peer
information for a single peer.

If the queried node has no peers for the infohash, a key "nodes" is returned
containing the K nodes in the queried nodes routing table closest to the
infohash supplied in the query. In either case a "token" key is also included
in the return value. The token value is a required argument for a future
L<announce_peer query|/"build_announce_peer_query( $tid, $nid, $info_hash, $token, $port )">.
The token value should be a short binary string.

=item C<build_announce_peer_reply( $tid, $nid )>

Generates a packet suitable for use as a response to an
L<announce peer query|/"build_announce_peer_query( $tid, $nid, $info_hash, $token, $port )">.

=item C<build_announce_peer_query( $tid, $nid, $info_hash, $token, $port )>

This packet announces that the peer controlling the querying node is
downloading a torrent and is accepting peers for said torrent on a certain
port. C<$info_hash> contains the infohash of the torrent and C<$token> is
taken from the response to a previous
L<get_peers query|/"build_get_peers_query( $tid, $nid, $info_hash )">.

The queried node must verify that the token was previously sent to the same IP
address as the querying node. Then the queried node should store the IP
address of the querying node and the supplied port number under the infohash
in its store of peer contact information.

=item C<build_ping_reply( $tid, $nid )>

Generates the pong to a L<ping query|/"build_ping_query( $tid, $nid )">.

=item C<build_ping_query( $tid, $nid )>

Generates a simple ping packet.

=item C<build_find_node_reply( $tid, $nid, $nodes )>

A find node reply contains a string which is a compacted list of the K (8)
good C<$nodes> nearest to the target from the routing table.

=item C<build_find_node_query( $tid, $nid, $target )>

Find node is used to find the contact information for a node given its ID.
C<$target> contains the ID of the node sought by the queryer.

=item C<build_error_reply( $tid, $error )>

Generates an error packet. An error may be sent in reply to any query.
C<$error> is a list ref. The first element is an integer representing the
error code. The second element is a string containing the error message which
may or may not be suitable for display. Errors are sent when a query cannot be
fulfilled. The following describes the possible error codes:

    Code    Description
    ----------------------------------------------
    201     Generic Error
    202     Server Error
    203     Protocol Error such as a malformed packet, invalid arguments, or
                a bad token
    204     Method Unknown

=back

=head1 Transaction IDs

Every message has a transaction ID which is created by the querying node and
is echoed in the response so responses may be correlated with multiple queries
to the same node. The transaction ID should be a short string of binary
numbers, in general 2 characters are enough as they cover C<2 ** 16>
outstanding queries.

=head1 Node IDs

Each node has a globally unique identifier known as the "node ID." Node IDs
are chosen at random from the same 160-bit space as BitTorrent infohashes. A
"distance metric" is used to compare two node IDs or a node ID and an infohash
for "closeness."

=head1 See Also

=over

=item BEP 05: DHT Protocol

http://bittorrent.org/beps/bep_0005.html

=back

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2010-2012 by Sanko Robinson <sanko@cpan.org>

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
