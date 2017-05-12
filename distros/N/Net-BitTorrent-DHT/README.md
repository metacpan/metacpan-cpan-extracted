# NAME

Net::BitTorrent::DHT - Kademlia-like DHT Node for BitTorrent

# Synopsis

    use Net::BitTorrent::DHT;
    use AnyEvent;
    use Bit::Vector;
    # Standalone node with user-defined port and boot_nodes
    my $dht = Net::BitTorrent::DHT->new(
          port => [1337 .. 1340, 0],
          boot_nodes =>
              [['router.bittorrent.com', 6881], ['router.utorrent.com', 6881]]
    );

    my $peer_quest
    = $dht->get_peers(Bit::Vector->new_Hex('ab97a7bca78f2628380e6609a8241a7fb02aa981'), \&dht_cb);

    # tick, tick, tick, ...
    AnyEvent->condvar->recv;

    sub dht_cb {
        my ($infohash, $node, $peers) = @_;
        printf "We found %d peers for %s from %s:%d via DHT\n\t%s\n",
            scalar(@$peers),
            $infohash->to_Hex, $node->host, $node->port,
            join ', ', map { sprintf '%s:%d', @$_ } @$peers;
    }

# Description

BitTorrent uses a "distributed sloppy hash table" (DHT) for storing peer
contact information for "trackerless" torrents. In effect, each peer becomes a
tracker. The protocol is based on [Kademila](#kademlia) and is implemented
over UDP.

# Methods

[Net::BitTorrent::DHT](https://metacpan.org/pod/Net::BitTorrent::DHT)'s API is simple but powerful.
...well, I think so anyway.

# Net::BitTorrent::DHT->new( )

The constructor accepts a number different arguments which all greatly affect
the function of your DHT node. Any combination of the following arguments may
be used during construction.

For brevity, the following examples assume you are building a
[standalone node](https://metacpan.org/pod/Net::BitTorrent::DHT::Standalone) (for reasearch, etc.).

## Net::BitTorrent::DHT->new( nodeid => ... )

During construction, our local DHT nodeID can be set during construction. This
is mostly useful when creating a
[standalone DHT node](https://metacpan.org/pod/Net::BitTorrent::DHT::Standalone).

    use Net::BitTorrent::DHT;
    # Bit::Vector object
    use Bit::Vector;
    my $node_c = Net::BitTorrent::DHT->new(
        nodeid => Bit::Vector->new_Hex( 160, 'ABCD' x 10 )
    );
    # A SHA1 digest
    use Digest::SHA;
    my $node_d = Net::BitTorrent::DHT->new(
            nodeid => Bit::Vector->new_Hex( 160, Digest::SHA::sha1( $possibly_random_value ) )
    );

Note that storing and reusing DHT nodeIDs over a number of sessions may seem
advantagious (as if you had a "reserved parking place" in the DHT network) but
will likely not improve performance as unseen nodeIDs are removed from remote
routing tables after a half hour.

NodeIDs, are 160-bit integers.

## Net::BitTorrent::DHT->new( port => ... )

Opens a specific UDP port number to the outside world on both IPv4 and IPv6.

    use Net::BitTorrent::DHT;
    # A single possible port
    my $node_a = Net::BitTorrent::DHT->new( port => 1123 );
    # A list of ports
    my $node_b = Net::BitTorrent::DHT->new( port => [1235 .. 9875] );

Note that when handed a list of ports, they are each tried until we are able
to bind to the specific port.

# Net::BitTorrent::DHT->find\_node( $target, $callback )

This method asks for remote nodes with nodeIDs closer to our target. As the
remote nodes respond, the callback is called with the following arguments:

- target

    This is the target nodeid. This is useful when you've set the same callback
    for multiple, concurrent `find_node( )` [quest](#quests-and-callbacks).

    Targets are 160-bit [Bit::Vector](https://metacpan.org/pod/Bit::Vector) objects.

- node

    This is a blessed object. TODO.

- nodes

    This is a list of ip:port combinations the remote node claims are close to our
    target.

A single `find_node` [quest](https://metacpan.org/pod/Net::BitTorrent::Notes#Quests-and-Callbacks)
is an array ref which contains the following data:

- target

    This is the target nodeID.

- coderef

    This is the callback triggered as we locate new peers.

- nodes

    This is a list of nodes we have announced to so far.

- timer

    This is an [AnyEvent](https://metacpan.org/pod/AnyEvent) timer which is triggered every few minutes.

    Don't modify this.

# Net::BitTorrent::DHT->get\_peers( $infohash, $callback )

This method initiates a search for peers serving a torrent with this infohash.
As they are found, the callback is called with the following arguments:

- infohash

    This is the infohash related to these peers. This is useful when you've set
    the same callback for multiple, concurrent `get_peers( )` quests. This is a
    160-bit [Bit::Vector](https://metacpan.org/pod/Bit::Vector) object.

- node

    This is a blessed object. TODO.

- peers

    This is an array ref of peers sent to us by aforementioned remote node.

A single `get_peers` [quest](https://metacpan.org/pod/Net::BitTorrent::Notes#Quests-and-Callbacks)
is an array ref which contains the following data:

- infohash

    This is the infohash related to these peers. This is a 160-bit
    [Bit::Vector](https://metacpan.org/pod/Bit::Vector) object.

- coderef

    This is the callback triggered as we locate new peers.

- peers

    This is a compacted list of all peers found so far. This is probably more
    useful than the list passed to the callback.

- timer

    This is an [AnyEvent](https://metacpan.org/pod/AnyEvent) timer which is triggered every five minutes.
    When triggered, the node requests new peers from nodes in the bucket nearest
    to the infohash.

    Don't modify this.

# Net::BitTorrent::DHT->**announce\_peer**( $infohash, $port, $callback )

This method announces that the peer controlling the querying node is
downloading a torrent on a port. These outgoing queries are sent to nodes
'close' to the target infohash. As the remote nodes respond, the callback is
called with the following arguments:

- infohash

    This is the infohash related to this announcment. This is useful when you've
    set the same callback for multiple, concurrent `announce_peer( )`
    [quest](#quests-and-callbacks). Infohashes are 160-bit
    [Bit::Vector](https://metacpan.org/pod/Bit::Vector) objects.

- port

    This is port you defined above.

- node

    This is a blessed object. TODO.

A single `announce_peer` [quest](#quests-and-callbacks) is an array ref
which contains the following data:

- infohash

    This is the infohash related to these peers. This is a 160-bit
    [Bit::Vector](https://metacpan.org/pod/Bit::Vector) object.

- coderef

    This is the callback triggered as we locate new peers.

- port

    This is port you defined above.

- nodes

    This is a list of nodes we have announced to so far.

- timer

    This is an [AnyEvent](https://metacpan.org/pod/AnyEvent) timer which is triggered every few minutes.

    Don't modify this.

`announce_peer` queries require a token sent in reply to a `get_peers` query
so they should be used together.

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    my $quest_a = $dht->announce_peer(Bit::Vector->new_Hex('A' x 40), 6881, \&dht_cb);
    my $quest_b = $dht->announce_peer(Bit::Vector->new_Hex('1' x 40), 9585, \&dht_cb);

    sub dht_cb {
        my ($infohash, $port, $node) = @_;
        say sprintf '%s:%d now knows we are serving %s on port %d',
            $node->host, $node->port, $infohash->to_Hex, $port;
    }

# Net::BitTorrent::DHT->dump\_ipv4\_buckets( )

This is a quick utility method which returns or prints (depending on context)
a list of the IPv4-based routing table's bucket structure.

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    # After some time has passed...
    $node->dump_ipv4_buckets; # prints to STDOUT with say
    my @dump = $node->dump_ipv4_buckets; # returns list of lines

# Net::BitTorrent::DHT->dump\_ipv6\_buckets( )

This is a quick utility method which returns or prints (depending on context)
a list of the IPv6-based routing table's bucket structure.

    use Net::BitTorrent::DHT;
    my $node = Net::BitTorrent::DHT->new( );
    # After some time has passed...
    $node->dump_ipv6_buckets; # prints to STDOUT with say
    my @dump = $node->dump_ipv6_buckets; # returns list of lines

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2008-2014 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
[The Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
See the `LICENSE` file included with this distribution or
[notes on the Artistic License 2.0](http://www.perlfoundation.org/artistic_2_0_notes)
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/us/legalcode).
See the
[clarification of the CCA-SA3.0](http://creativecommons.org/licenses/by-sa/3.0/us/).

Neither this module nor the [Author](#author) is affiliated with BitTorrent,
Inc.
