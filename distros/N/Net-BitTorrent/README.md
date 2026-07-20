# NAME

Net::BitTorrent - Complete, Modern BitTorrent Client Library

# SYNOPSIS

```perl
use v5.40;
use Net::BitTorrent;
use Net::BitTorrent::Types qw[:encryption];

# Initialize the client
my $client = Net::BitTorrent->new(
    upnp_enabled => 1,
    encryption   => ENCRYPTION_REQUIRED # or 'required'
);

# Unified add() handles magnets, .torrents, or v1/v2 infohashes
# Supports 20/32-byte binary or 40/64-character hex strings
my $torrent = $client->add("magnet:?xt=urn:btih:...", "./downloads");

# Simple event handling
$client->on(torrent_added => sub ($nb, $t) {
    say "New swarm added: " . $t->name;
    $t->start();
});

# Advanced: Manual event loop integration
# while (1) {
#     $client->tick(0.1);
#     select(undef, undef, undef, 0.1);
# }

# Wait for all downloads to finish
$client->wait();

# Graceful shutdown
$client->shutdown();
```

# DESCRIPTION

`Net::BitTorrent` is a comprehensive, high-performance BitTorrent client library rewritten from the ground up for
**Modern Perl (v5.40+)** using the native `class` feature.

The library is designed around three core principles:

- 1. Loop-agnosticism: The core logic is decoupled from I/O. You can drive it with a simple `while` loop, integrate it into `IO::Async`, `Mojo::IOLoop`, or even run it in a synchronous environment.
- 2. BitTorrent v2 first: Full support for **BEP 52 (BitTorrent v2)**, including SHA-256 infohashes, Merkle tree block verification, and hybrid v1/v2 swarms.
- 3. Security: Features like **BEP 42 (DHT Security)**, **Protocol Encryption (MSE/PE)**, and peer reputation tracking are built-in and enabled by default.

## How Everything Fits Together

Net::BitTorrent uses a hierarchical architecture to manage the complexities of the protocol:

### 1. The Client ([Net::BitTorrent](https://metacpan.org/pod/Net%3A%3ABitTorrent))

The entry point. It manages multiple swarms, global rate limits, decentralized discovery (DHT/LPD), and unified UDP
packet routing. It also provides a centralized "hashing queue" to prevent block verification from starving your CPU.

### 2. Torrents ([Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent))

Orchestrates a single swarm. It manages its own list of discovered peers, the Piece Picker (rarest-first logic), and
communicates with the Trackers. It acts as the bridge between the network (Peers) and the local disk (Storage).

### 3. Peers ([Net::BitTorrent::Peer](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3APeer))

Tracks the state of a single connection (choking, interested, transfer rates). It uses a **Protocol Handler** to speak
the wire protocol and a **Net::BitTorrent::Transport** (TCP or uTP) to move bytes.

### 4. Storage ([Net::BitTorrent::Storage](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3AStorage))

Manages files on disk. It uses Merkle trees for per-block verification (v2) and handles the "virtual contiguous file"
mapping required for v1 compatibility. It includes an asynchronous disk cache to keep the main loop fast.

# METHODS

## `new( %params )`

Creates a new client instance.

```perl
my $client = Net::BitTorrent->new(
    port         => 6881,
    encryption   => 'required', # 'none', 'preferred', or 'required'
    upnp_enabled => 1
);
```

This method initializes the BitTorrent engine with custom configuration.

Expected parameters:

- `port` - optional

    The port to listen on for incoming connections. Defaults to a random port in the dynamic range.

- `user_agent` - optional

    The user agent string reported to trackers and peers.

- `max_peers` - optional

    The maximum number of connected peers across all active torents. If you'd rather set per-torrent limits, see
    [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent)'s `max_peers` field.

- `encryption` - optional

    The encryption requirement level. Can be `none`, `preferred`, or `required` (default).

- `upnp_enabled` - optional

    Whether to attempt UPnP port mapping. Defaults to false.

- `bepXX` - optional

    Toggles for specific BEPs (e.g., `bep05 => 0` to disable DHT). Defaults to enabled for supported BEPs.

## `on( $event, $callback )`

Registers a global callback for client-level events.

```perl
$client->on(torrent_added => sub ($nb, $torrent) {
    warn "Added: " . $torrent->name;
});
```

This method allows you to react to system-wide changes or automate actions for newly added swarms.

Expected parameters:

- `$event`

    The name of the event to listen for (e.g., `torrent_added`).

- `$callback`

    The code reference to execute when the event is emitted.

## `add( $thing, $base_path, [%args] )`

The recommended, unified method for adding a swarm.

```
# Add a .torrent file
$client->add("ubuntu.torrent", "./iso");

# Add a magnet link
$client->add("magnet:?xt=urn:btih:...", "./data");
```

This method automatically detects the type of the first parameter and adds the corresponding swarm. It returns a
[Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) object on success.

Expected parameters:

- `$thing`

    The resource to add. Can be a file path, a Magnet URI, or an infohash (hex or binary).

- `$base_path`

    The directory where the torrent's data will be stored.

- `%args` - optional

    Optional parameters to pass to the [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) constructor.

## `add_torrent( $path, $base_path, [%args] )`

Adds a torrent from a local `.torrent` file.

```perl
my $t = $client->add_torrent("linux.torrent", "/downloads");
```

This method is for adding a swarm specifically from a metadata file. It returns a [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) object.

Expected parameters:

- `$path`

    The path to the `.torrent` file.

- `$base_path`

    The directory where the torrent's data will be stored.

- `%args` - optional

    Optional parameters to pass to the [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) constructor.

## `add_infohash( $ih, $base_path, [%args] )`

Adds a torrent by its info hash.

```perl
my $t = $client->add_infohash(pack('H*', '...'), './data');
```

This method is useful for bootstrapping a swarm when only the hash is known. It returns a [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent)
object.

Expected parameters:

- `$ih`

    The infohash. Can be a 20-byte (v1) or 32-byte (v2) binary string, or a 40/64 character hex string.

- `$base_path`

    The directory where the torrent's data will be stored.

- `%args` - optional

    Optional parameters to pass to the [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) constructor.

## `add_magnet( $uri, $base_path, [%args] )`

Adds a torrent from a Magnet URI.

```perl
my $t = $client->add_magnet("magnet:?xt=urn:btmh:...", "./data");
```

This method allows adding resources from web links. It returns a [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) object.

Expected parameters:

- `$uri`

    The Magnet URI.

- `$base_path`

    The directory where the torrent's data will be stored.

- `%args` - optional

    Optional parameters to pass to the [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) constructor.

## `torrents( )`

Returns a list of all active torrents.

```perl
my $list = $client->torrents( );
```

This method returns an array reference containing all currently managed [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) objects.

## `finished( )`

Returns a list of completed torrents.

```perl
my $done = $client->finished();
```

This method returns an array reference of all managed torrents that have completed their download.

## `wait( [$condition], [$timeout] )`

Blocks execution until a condition is met.

```
$client->wait();
```

This method runs the internal event loop until the provided condition returns true or a timeout is reached. It returns
a boolean indicating if the condition was met.

Expected parameters:

- `$condition` - optional

    A code reference that returns true to stop waiting. Defaults to waiting for all torrents to finish.

- `$timeout` - optional

    The maximum number of seconds to wait.

## `tick( [$timeout] )`

The "heartbeat" of the library.

```
$client->tick(0.1);
```

This method performs discovery, updates swarm logic, and handles network I/O.

Expected parameters:

- `$timeout` - optional

    The duration in seconds since the last call. Defaults to 0.1.

## `save_state( $path )`

Persists session state to a file.

```
$client->save_state('session.json');
```

This method saves the current client state to a JSON file.

Expected parameters:

- `$path`

    The file path where the state will be saved.

## `load_state( $path )`

Restores session state from a file.

```
$client->load_state('session.json');
```

This method loads client state from a JSON file.

Expected parameters:

- `$path`

    The file path to load the state from.

## `dht_get( $target, $callback )`

Retrieves data from the DHT.

```perl
$client->dht_get($target_hash, sub ($value, $node) { ... });
```

This method initiates a DHT lookup for the specified target hash.

Expected parameters:

- `$target`

    The 20-byte SHA-1 hash of the data key.

- `$callback`

    The code reference called when data is found.

## `dht_put( $value, [$callback] )`

Stores data in the DHT.

```
$client->dht_put('My Shared Note');
```

This method stores immutable data in the DHT.

Expected parameters:

- `$value`

    The data to store.

- `$callback` - optional

    The code reference called when the store operation completes.

## `dht_scrape( $infohash, $callback )`

Performs a decentralized scrape.

```perl
$client->dht_scrape($infohash, sub ($stats) { ... });
```

This method queries the DHT for seeder and leecher counts.

Expected parameters:

- `$infohash`

    The infohash to scrape.

- `$callback`

    The code reference called with the scrape results.

## `shutdown( )`

Gracefully stops the client.

```
$client->shutdown();
```

This method stops all swarms, unmaps ports, and releases resources.

## `features( )`

Returns the enabled features.

```perl
my $f = $client->features();
```

This method returns a hash reference containing the status of various BEPs.

## `set_limit_down( $val )`

Sets the global download rate limit.

```
$client->set_limit_down( 1024 * 1024 ); # 1MiB/s
```

This method sets the maximum download rate in bytes per second.

Expected parameters:

- `$val`

    The limit in bytes per second. Use 0 for unlimited.

## `hashing_queue_size( )`

Returns the number of pieces waiting for verification.

```perl
my $size = $client->hashing_queue_size();
```

This method returns the current size of the background hashing queue.

## `queue_verification( $torrent, $index, $data )`

Queues a piece for background verification.

```
$client->queue_verification( $torrent, $index, $data );
```

This method adds a piece to the throttled background hashing queue.

Expected parameters:

- `$torrent`

    The [Net::BitTorrent::Torrent](https://metacpan.org/pod/Net%3A%3ABitTorrent%3A%3ATorrent) object the piece belongs to.

- `$index`

    The piece index.

- `$data`

    The piece data.

# SUPPORTED BEPS

- **BEP 03**: The BitTorrent Protocol (TCP)
- **BEP 05**: Mainline DHT
- **BEP 06**: Fast Extension
- **BEP 09**: Metadata Exchange
- **BEP 10**: Extension Protocol
- **BEP 11**: Peer Exchange (PEX)
- **BEP 14**: Local Peer Discovery (LPD)
- **BEP 29**: uTP (UDP Transport)
- **BEP 42**: DHT Security Extensions
- **BEP 52**: BitTorrent v2
- **BEP 53**: Magnet URI Extension

# AUTHOR

Sanko Robinson - [https://github.com/sanko](https://github.com/sanko)

# COPYRIGHT

Copyright (C) 2008-2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
