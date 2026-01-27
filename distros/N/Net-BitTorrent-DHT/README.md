# NAME

Net::BitTorrent::DHT - BitTorrent Mainline DHT implementation

# SYNOPSIS

```perl
use Net::BitTorrent::DHT;

my $dht = Net::BitTorrent::DHT->new(
    node_id_bin => pack('H*', '0123456789abcdef0123456789abcdef01234567'),
    port        => 6881,
    address     => '0.0.0.0' # Optional: bind to specific address
    want_v6     => 1
);

# Connect to the DHT network
$dht->bootstrap();

# Event loop integration
while (1) {
    # Process incoming packets and timeouts
    my ($new_nodes, $found_peers, $data) = $dht->tick(0.1);

    # $found_peers contains Net::BitTorrent::DHT::Peer objects
    for my $peer (@$found_peers) {
        say "Found peer: " . $peer->to_string;
    }
}
```

# DESCRIPTION

`Net::BitTorrent::DHT` is a comprehensive implementation of the BitTorrent Mainline DHT protocol. It is designed to be
transport-agnostic and event-loop friendly, making it suitable for integration into existing applications. It uses
[Algorithm::Kademlia](https://metacpan.org/pod/Algorithm%3A%3AKademlia) for its core routing logic and [Net::BitTorrent::Protocol::BEP03::Bencode](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3AProtocol%3A%3ABEP03%3A%3ABencode) for wire
serialization.

# CONSTRUCTOR

## `new( %args )`

Creates a new DHT node instance. All arguments are optional.

```perl
my $dht = Net::BitTorrent::DHT->new( port => 8999 );
```

- `node_id_bin`

    A 20-byte binary string representing the unique Node ID. If not provided, one is generated randomly. It is recommended
    to persist this ID between sessions.

- `port`

    The UDP port to listen on. Defaults to `6881`.

- `address`

    The local address to bind to. Defaults to `undef` (binds to all interfaces).

- `want_v4`

    Boolean. Enable IPv4 support. Defaults to `1`.

- `want_v6`

    Boolean. Enable IPv6 support. Defaults to `1`.

- `v`

    A 4-byte binary string representing the client version (e.g., `NB21`). This is included in every message to identify
    the client software. The first two bytes should be a client identifier registered in BEP20, followed by two bytes
    representing the version number. Optional but recommended.

- `bep32`

    Boolean. Enable BEP 32 (IPv6 extensions). Defaults to `1`.

- `bep33`

    Boolean. Enable BEP 33 (Scraping). Defaults to `1`.

- `bep42`

    Boolean. Enable BEP 42 (Security Extensions). Defaults to `1`.

- `bep44`

    Boolean. Enable BEP 44 (Arbitrary Data). Defaults to `1`.

    Note: Only supports immutable data unless dependencies are met.

- `read_only`

    Boolean. Enable BEP 43 (Read-only mode). Defaults to `0`.

- `boot_nodes`

    An array reference of `[host, port]` tuples to use for bootstrapping. Defaults to standard public routers
    (`router.bittorrent.com`, etc.).

# METHODS

## `bootstrap( )`

Initializes the node by querying the bootstrap nodes. This kicks off the process of finding other nodes and populating
the routing table.

```
$dht->bootstrap( );
```

## `tick( [$timeout] )`

Checks for incoming packets and processes them. Should be called repeatedly in your event loop.

```perl
my ( $nodes, $peers, $data ) = $dht->tick( 0.5 );
```

Returns a list of three elements:

- `$nodes`: array of hash references representing new nodes found.
- `$peers`: array of `Net::BitTorrent::DHT::Peer` objects found (responses to `get_peers`).
- `$data`: hash of data or stats (responses to `get`, `scrape_peers`, `sample_infohashes`).

## `ping( $addr, $port )`

Sends a ping query to a remote node. Useful for checking liveness.

```
$dht->ping( '1.2.3.4', 6881 );
```

## `find_node_remote( $target_id, $addr, $port )`

Queries a node for nodes close to the target ID. Used during routing table maintenance and lookups.

```
$dht->find_node_remote( $target_id, '1.2.3.4', 6881 );
```

## `get_peers( $info_hash, $addr, $port )`

Queries a node for peers associated with an infohash. The primary method for peer discovery.

```
$dht->get_peers( $info_hash, '1.2.3.4', 6881 );
```

## `announce_peer( $info_hash, $token, $implied_port, $addr, $port, [$seed] )`

Announces to a remote node that you are a peer for the given infohash. Requires a valid `$token` received from a
previous `get_peers` response from that node.

```
# $token received from get_peers response
$dht->announce_peer( $info_hash, $token, 6881, '1.2.3.4', 6881, 1 );
```

## `get_remote( $target, $addr, $port )`

Sends a BEP 44 `get` query to retrieve data associated with a target (SHA1 hash of the key or value).

```
$dht->get_remote( $target_hash, '1.2.3.4', 6881 );
```

## `put_remote( \%args, $addr, $port )`

Sends a BEP 44 `put` query to store data on a remote node.

```perl
# Immutable Data
$dht->put_remote( { v => 'Hello World' }, '1.2.3.4', 6881 );

# Mutable Data
$dht->put_remote(
{   v    => 'New Value',
    k    => $public_key_bin,
    sig  => $signature_bin,
    seq  => $sequence_number,
    salt => 'optional_salt'
}, '1.2.3.4', 6881 );
```

## `scrape_peers_remote( $info_hash, $addr, $port )`

Sends a BEP 33 scrape query to get statistics (seeders/leechers) for an infohash.

```
$dht->scrape_peers_remote( $info_hash, '1.2.3.4', 6881 );
```

## `sample_infohashes_remote( $target_id, $addr, $port )`

Sends a BEP 51 sample infohashes query to discover infohashes stored on a node.

```
$dht->sample_infohashes_remote( $target_id, '1.2.3.4', 6881 );
```

## `export_state( )`

Returns the current state (routing table buckets, values, peers) as a hash reference. This is essential for saving the
DHT's progress so it doesn't have to re-bootstrap on restart.

```perl
my $state = $dht->export_state( );
# Save $state to disk...
```

## `import_state( $state )`

Restores the DHT state from a hash reference previously generated by `export_state()`.

```
$dht->import_state( $loaded_state );
```

## `run( )`

A simple blocking loop that calls `tick( 1 )` indefinitely. Useful for simple scripts.

```
$dht->run( );
```

## `handle_incoming( )`

Manually processes a single packet from the socket. Used when integrating with other event loops where you control the
socket reading.

```perl
$loop->watch_io(
    handle => $dht->socket,
    on_read_ready => sub {
        my ($nodes, $peers, $data) = $dht->handle_incoming();
        # ...
    }
);
```

# Event Loop Integration

This module is designed to be protocol-agnostic regarding the event loop.

## Using with IO::Select (Default)

Simply call `tick($timeout)` in your own loop.

## Using with IO::Async

```perl
my $handle = IO::Async::Handle->new(
    handle => $dht->socket,
    on_read_ready => sub {
        my ($nodes, $peers) = $dht->handle_incoming();
        # ...
    },
);
$loop->add($handle);
```

# Supported BEPs

This module implements the following BitTorrent Enhancement Proposals (BEPs):

## BEP 5: Mainline DHT Protocol

The core protocol implementation. It allows for decentralized peer discovery without a tracker.

## BEP 32: IPv6 Extensions

Adds support for IPv6 nodes and peers. Can be toggled via the `bep32` constructor argument.

## BEP 33: DHT Scrapes

Allows querying for the number of seeders and leechers for a specific infohash. Can be toggled via the `bep33`
constructor argument.

## BEP 42: DHT Security Extensions

Implements node ID validation to mitigate specific attacks. Can be toggled via the `bep42` constructor argument.

## BEP 43: Read-only DHT Nodes

Allows the node to participate in the DHT without being added to other nodes' routing tables. Useful for mobile devices
or low-bandwidth clients. Set the `read_only` constructor argument to a true value.

## BEP 44: Storing Arbitrary Data

Enables `get` and `put` operations for storing immutable and mutable data items in the DHT. Can be explicitly
disabled via the `bep44` constructor argument.

In order to handle mutable data, [Crypt::PK::Ed25519](https://metacpan.org/pod/Crypt%3A%3APK%3A%3AEd25519) or [Crypt::Perl::Ed25519::PublicKey](https://metacpan.org/pod/Crypt%3A%3APerl%3A%3AEd25519%3A%3APublicKey) must be installed.

## BEP 51: Infohash Indexing

Adds the `sample_infohashes` RPC to allow indexing of the DHT's content. Supported and enabled by default.

# SEE ALSO

[Algorithm::Kademlia](https://metacpan.org/pod/Algorithm%3A%3AKademlia), [Net::BitTorrent::Protocol::BEP03::Bencode](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3AProtocol%3A%3ABEP03%3A%3ABencode)

[BEP05](https://www.bittorrent.org/beps/bep_0005.html), [BEP20](https://www.bittorrent.org/beps/bep_0020.html),
[BEP32](https://www.bittorrent.org/beps/bep_0032.html), [BEP33](https://www.bittorrent.org/beps/bep_0033.html),
[BEP42](https://www.bittorrent.org/beps/bep_0042.html), [BEP43](https://www.bittorrent.org/beps/bep_0043.html),
[BEP44](https://www.bittorrent.org/beps/bep_0044.html), [BEP51](https://www.bittorrent.org/beps/bep_0051.html).

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2008-2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
