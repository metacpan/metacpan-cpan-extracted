# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.1.0] - 2026-07-19

### Fixed
- [CVE-2026-57082](https://github.com/sanko/Net-BitTorrent.pm/security/advisories/GHSA-g444-x2c5-94hc) - Require `Crypt::URandom` to replace Perl's `CORE::rand(...)` for CSPRNG-safe random number generation across the entire codebase
- [CVE-2026-57079](https://github.com/sanko/Net-BitTorrent.pm/security/advisories/GHSA-5wc6-r65f-62rr) - Validate metadata file paths with `realpath` to prevent directory traversal via crafted metadata
- [CVE-2026-57080](https://github.com/sanko/Net-BitTorrent.pm/security/advisories/GHSA-7jr6-2jf4-6qc4) - Reject BitTorrent messages exceeding 16 MB to prevent memory exhaustion via oversized payloads
- [CVE-2026-57081](https://github.com/sanko/Net-BitTorrent.pm/security/advisories/GHSA-mv44-v82p-89xv) - Various protocol-level hardening against remote peer exploitation
- New `Net::BitTorrent::SSRF` module with `is_safe_ip`, `is_safe_host`, `is_safe_url`, and `resolve_and_pin` for IP/URL safety validation and DNS pinning
- Block outbound connections to RFC 1918 private ranges, loopback, link-local, multicast, cloud metadata endpoints, and IPv4-mapped IPv6 addresses
- HTTP tracker announce and scrape now resolve DNS and pin the IP before connecting to prevent TOCTOU DNS rebinding attacks
- UDP tracker validates sender IP matches the expected resolved address
- HTTP and UDP tracker response sizes are now capped (1 MB or 500 peers)
- Rate-limit MSE handshakes per-IP and `HP_CONNECT` messages (10/minute)
- Limit concurrent DHT queries per IP and cap pending UDP tracker transactions at 100
- Limit incoming PEX packets to 100 entries per list with validation of port ranges
- Limit BEP 10 remote extension maps to 50 and validate `metadata_size` field
- Cap DHT node unpacking at 200 nodes per response, filter port-0 nodes
- Cap per-torrent discovered peers at 10,000 and attempted connections at 5,000
- Cap block cache at 32 incomplete pieces and hashing queue at 32 entries
- Reject metadata exceeding `MAX_METADATA_SIZE` (10 MB) early in BEP 09 processing
- Track and limit inbound TCP buffer growth (4 MB per-connection limit)
- Validate payload length for every BitTorrent message type (CHOKE, UNCHOKE, HAVE, REQUEST, PIECE, etc.)
- Validate HAVE index is within piece count, REQUEST index/begin/len within piece bounds
- Validate BEP 44 mutable data fields (key length, sig length, seq range) and immutable data size
- Cap BEP 44 storage entries and `ip_votes` hash at 500
- Validate `sample_infohashes` target length (20 or 32 bytes)
- Rate-limit DHT external IP changes to once per 5 minutes
- Constant-time VC comparison in MSE to prevent timing attacks
- Sanitize UDP tracker error messages and WebSeed `rel_path` to prevent injection
- WebSeed follows redirects manually with SSRF re-validation at each hop
- DHT sends are blocked by SSRF policy for unsafe destination IPs
- Log messages triggered by peer/tracker data are no longer fatal (won't kill the client based on bad data from a peer)
- Memory leak from `Torrent->Peer->parent_emitter->Torrent` reference cycle (weakened `parent_emitter`)
- Shared `%_requested_blocks` class variable across all Peer instances (now per-instance field)
- `blocks_pending` inconsistency where `_request_pieces` stored `1` but `peer_disconnected` compared with `== $peer`
- `_clear_piece_cache` not deleting `blocks_received`, causing stale entries after failed verification
- `is_finished` and `progress` returning wrong values due to `bytes_left` discrepancies with bitfield count
- `fetch_from_webseeds` not accounting `bytes_downloaded`, `bytes_left` decrement, or `piece_verified` event
- `_on_metadata_received` not setting `bytes_left` before transitioning to `STATE_RUNNING`
- `_request_next_block` not marking requested blocks in `requested_blocks` hash
- `_handle_piece_data` not tracking unsolicited PIECE messages or validating data length
- `_handle_reject` not cleaning up `blocks_pending` or decrementing `requested_blocks`
- `_check_interest` always sent `INTERESTED` regardless of whether peer actually has needed pieces

### Added
- `Net::BitTorrent->remove_torrent($thing)` accepts a Torrent object, hex infohash, or packed infohash for safe torrent removal
- `Net::BitTorrent::Peer` `cancel_request($index, $begin)` method for endgame duplicate cancellation
- `Net::BitTorrent::Emitter` `off($event, $cb)` method for removing callbacks
- `Net::BitTorrent::Torrent::DESTROY` disconnects peers and clears all data structures on garbage collection

### Changed
- Peer reputation blacklist threshold lowered from 50 to 20; `adjust_reputation` now caps at 0–100 and is a no-op after disconnect
- `Net::BitTorrent::Emitter` weakens `$parent_emitter` via `builtin::weaken` to break `Torrent->Peer->Emitter->Torrent` reference cycles causing memory leaks (I hope)
- Endgame mode now enters on a 60-second stall (no piece verification) in addition to the existing piece-count triggers
- Endgame duplicate request cancellation: when a block arrives, all other peers' inflight requests for that same block are immediately cancelled
- `_request_pieces` and `get_next_request` now consistently store peer objects in `%blocks_pending` (was inconsistent `1` vs peer object)
- `is_finished()` and `progress()` are now bitfield-based (`count/size`) instead of relying on `bytes_left`
- `_calculate_total_size()` result is cached to avoid repeated O(N) file tree traversal (especially with V2 metadata)
- `MAX_BLOCK_CACHE` reduced from 2048 to 32, `MAX_HASHING_QUEUE_SIZE` reduced from 128 to 32
- Storage write cache reduced from 128 MB to 16 MB
- Peer `requested_blocks` is now a per-instance hashref (was a class-level hash shared across all Peer instances)
- Zombie peer detection: peers are disconnected after 30s without response (with inflight requests) or 120s idle
- Peer `tick()` and `disconnected()` are idempotent via `$_disconnected` guard
- `Torrent::tick()` snapshots the peer list before iteration to prevent hash mutation during disconnect callbacks
- `_clear_piece_cache` now also deletes `blocks_received` to prevent stale entries after failed verification
- `load_state` validates bitfield size and metadata structure before applying
- `Torrent::announce` uses the client's *actual* `listen_port` and guards against missing `tracker_manager`
- DHT pending query cleanup is now deterministic (runs on every response) instead of probabilistic (1% chance)
- DHT `_check_external_ip` requires public IPs and per-source voting to prevent colluding-node manipulation
- `Net::BitTorrent::Protocol::BEP03` catches protocol processing errors and transitions to `CLOSED` state instead of crashing
- `Net::BitTorrent::Transport::TCP` calls `shutdown(2)` before `close()` and enforces 4 MB write/read buffer limits
- WebSeed auto-disables for unsafe URLs at construction time
- DHT `_unpack_nodes` filters out port-0 entries

## [v2.0.1] - 2026-02-14

### Fixed
- Corrected callbacks for 'data', 'infohash_identified', and other events.
- Fixed LRU cache bug in `Net::BitTorrent::Storage` where `_evict_one` incorrectly deleted entire file caches and `_flush_one` failed to remove data from cache after writing to disk.

## [v2.0.0] - 2026-02-13

### Changed
- Rewritten from scratch.

## [0.052] - 2010-04-02
This will probably be the last 'stable' version before Net::BitTorrent is rewritten. Stuff in TODO.pod will be expanded and used as a roadmap.

### Changed
- miniswarm tests are given less time before giving up

### Removed
- 'bad' test (checking if port was opened twice... which seems to be okay on some systems) has been removed
- Removing t/900_data/950_torrents/951_single.torrent which was used to test large file support (caused "Out of memory!" errors on smokers with limited resources)

## [0.051] - 2009-09-12
Meanwhile...
- New IRC-based support: irc://irc.p2p-network.com/net-bittorrent
- Bug tracker is now at http://github.com/sanko/net-bittorrent/issues

### Added
- New script /scripts/net-bittorrent.pl is installed with distribution. It is a very short version of /tatoeba/005-console.pl

### Fixed
- DHT nodes found in metadata are now handled according to spec
  - Bug reported by Wouter Godefroy via email

## [0.050] - 2009-02-13
With the addition of Protocol Encryption and the bugfix, I strongly suggest an upgrade for all users despite the API tweeks.

Meanwhile...
- Development moved to github: http://github.com/sanko/net-bittorrent

### Added
- Message Stream Encryption (enabled by default) with plaintext fallback
- (Start of a) Rewrite of t/[...]Peer.t to be more complete and emulate real-world sessions.
- New demonstration script: /tatoeba/005-console.pl
    - Formerly known as /scripts/bittorrent.pl

### Changed
- N::B::Peer objects have their sockets closed and removed *before* calling any peer_disconnect callbacks.
- Reasons handed to peer_disconnect callbacks are now language agnostic. Please see Notes section in Net::BitTorrent::Peer for more information.
- Shorter waiting period before filling requests (15s -> 3s)
- Default for number of allowed connections per host has changed (2 -> 1)
- General documentation cleanup

### Fixed
- Fixed major bug related to outgoing HAVE packets.
- Fix t/[...]/Protocol.t failures due to the limits of 32-bit math

## [0.049] - 2009-01-05
There are several incompatible changes and I've been coding with the flu this week.  Upgrade at your own risk.

THIS PROJECT IS ACTIVELY SEEKING DEVELOPERS. Ahem, I hate to shout but N::B could really use your help. Yes, you, the person reading this. If you're interested, see the "Joining the Project" section in Net::BitTorrent::Notes.

Various N::B::Torrent status and internal schedule fixes were made none of which really effect behavior.

Meanwhile...
- 2008 ends as it began: uneventfully.
- RIAA drops MediaSentry.

### Added
- New debugging demonstration in /tatoeba/002-debug.pl
- New threaded demonstration in /tatoeba/003-threads.pl
- New resume demonstration in /tatoeba/004-resume.pl

### Changed
- Net::BitTorrent::Torrent->peers() is now public
- Lists of potential peers are kept by their source (N::B::DHT, N::B::T::Tracker::HTTP, N::B::T::Tracker::UDP) rather than in Net::BitTorrent::Torrent.
- Resume system (yeah, the thing I added two versions ago) was deprecated and has been replaced.  I thought about it and changing the original .torrent's metadata is a bad idea so I switched from Rakshasa- to Rasterbar-like.
- N::B::T::Tracker::HTTP retry is now 30s on socket error (formerly 5m).
- N::B::Peer objects are disconnected if they don't complete handshake within 30s.
- Various tests temporarily tie STDERR to check as_string() output

## [0.046] - 2008-12-30
This is a major bug fix release with which introduces no incompatibilities. Upgrade is highly recommended.

### Added
- The first two in a series of demonstration scripts are in the /tatoeba/ directory

### Changed
- Net::BitTorrent::Torrent::HTTP->url() is now public
- Net::BitTorrent::Torrent::UDP->url() is now public
- Minor tweaking and clean up in Net::BitTorrent::Notes

### Fixed
- In 0.045, if no arguments were passed, Net::BitTorrent->new() failed to set set defaults, generate a peerid, or create a DHT object.

## [0.045] - 2008-12-26
No non-compatible API changes so upgrade is suggested.

The announce and discussion lists have been combined into a single list found at http://groups.google.com/group/net-bittorrent.

All code is now covered by the Artistic 2 License (actually since v0.040 but I failed to mention it in the changelog).

Meanwhile,...
+ the RIAA stops suing people and will, instead, cancel your 'net service (http://tinyurl.com/4h9omj) and bed your crush.
+ Australia plans to filter BitTorrent. (http://tinyurl.com/95uvg5) ...eventually (http://tinyurl.com/a4juwy).

### Added
- [Beta] Torrent resume system (see Net::BitTorrent::Notes).

### Changed
- Net::BitTorrent::Torrent->hashcheck() clears the bitfield when it begins.
- scripts/bittorrent.pl supports resume (overwrites .torrent file).

### Fixed
- Close related sockets on N::B::DESTROY (left behind FIN_WAIT1 on Win32).
- DHT actually works. For real this time.

## [0.042] - 2008-12-04
PAUSE vs. The World (Writable Files)

### Changed
- as_string() is now a public method in all classes
- as_string() is documented all around
- Affected tests updated to reflect as_string() change
- Synopsis in README now matches that of N::B proper
- More silly POD changes for scripts/bittorrent.pl ((sigh))

### Fixed
- Fixed crash bug (call to legacy method) on failure to write data to disk

## [0.040] - 2008-12-01
Since the previous stable release, Net::BitTorrent has been rewritten from scratch, so yeah, 90% of everything internal has changed, the API was redesigned as well.  I've been pushing dev builds for more than three months so... yeah.

See the Notes section (in original changelog) for API and Compatibility info.

### Added
- Torrents can now be paused, stopped, and started (alpha code)
- Torrent objects can now be created without a parent client for informational use (See perldoc Net::BitTorrent::Torrent)
- UDP trackers are now supported
- Fast Ext. is back

### Changed
- Net::BitTorrent::Session::* is now Net::BitTorrent::Torrent::* thanks to one very squeaky wheel.
- PeerID spec has changed (stability marker is now 'U'nstable/'S'table instead of the less obvious and misleading 'S'VN/'C'PAN)
- Torrents aren't automatically checked when loaded.
- PeerID, DHT node ID, ExtProtocol name, and dist version are all generated in Net::BitTorrent::Version

### Fixed
- DHT actually works
- No longer floods the system with CLOSE_WAIT sockets which eventually block the allocation of new sockets

## [0.027_001] - Fall 2008
Don't use this.  I'm serious.  I'm only uploading it to get some CPAN testers data.

### Changed
- Net::BitTorrent is going through a rewrite.  Idle hands...

## [0.025] - 2008-07-01
Please see the Compatibility Information section from the previous version.

Gah, what a waste of a great version number (0.025)... That's what I get for not eating my own dog food before shipping it.

I knew I was forgetting something.

### Fixed
- Fix crash bug by re-enabling N::B::S::Peer::_parse_packet_allowed_fast and N::B::S::Peer::_parse_packet_reject in the packet dispatch table
- Fixed crash bug in Data::Dumper usage in N::B::S::Peer and N::B::DHT
- Fixed non-critical bug in N::B::S::Peer when a connected peer goes ((poof)) in the middle of something.

## [0.024] - 2008-07-01
I'm sure I'm forgetting something... several somethings, in fact...

This is an UNSTABLE stable release.  There may be calls to old methods hiding out in a dark corner... data on the extended test suite, the rewritten API, and the alpha DHT code.  DO NOT INSTALL!  Stick with the 0.022 release!  As soon as I have a few reports, I will mark this distribution for deletion from PAUSE.

### Added
- New DHT-related callback: peer_outgoing_port
- DHT is included with this release.  It's really raw code so don't expect too much.

### Changed
- Entire API has changed.  See the Compatibility Information below.
- I've changed the API to pretty much everything in the distribution with a depreciation cycle.  Bold, yes? So, with so much having changed, putting a full list of what's changed will be a horrific waste of space.  These are the highlights:

    ```
      Old Mutator/Accessor         New Getter               New Setter
    --------------------------------------------------------------------------
    N::B
     maximum_buffer_size       get_max_buffer_per_conn  set_max_buffer_per_conn
     kbps_down                 get_max_dl_rate          set_max_dl_rate
     kbps_up                   get_max_ul_rate          set_max_ul_rate
     maximum_peers_per_client  get_conns_per_client     set_conns_per_client
     maximum_peers_per_session get_conns_per_session    set_conns_per_session
     maximum_peers_half_open   get_max_halfopen         set_max_halfopen
     debug_level               get_debug_level          set_debug_level
     maximum_requests_per_peer get_ul_slots_per_session set_ul_slots_per_session
     maximum_requests_size     get_ul_slot_size         get_ul_slot_size
     peer_id                   get_peer_id              --NA--
     sockport                  get_sockport             --NA--
     sockaddr                  get_sockaddr             --NA--
     sessions                  get_sessions             --NA--
    N::B::S::Piece
     check                     get_cached_integrity
     verify                    get_verified_integrity
    ```

- The arguments Net::BitTorrent's constructor expects have been changed to stay in step with the new get/set methods:

    ```
             Old                           New
      ------------------------------------------------------------------------
      maximum_peers_per_client      conns_per_client
      maximum_peers_per_session     conns_per_session
      kbps_down                     max_dl_rate
      kbps_up                       max_ul_rate
      maximum_peers_half_open       max_halfopen
      maximum_buffer_size           max_buffer_per_conn
      maximum_requests_size         ul_slot_size
      maximum_requests_per_peer     ul_slots_per_session
    ```

### Removed
- Accessor: N::B->timeout( [NEWVAL] ). This was the select timeout used in N::B::do_one_loop().  It has been removed completely in favor of a new optional parameter passed to N::B::do_one_loop( [TIMEOUT] ) itself.

## [0.022] - 2008-05-24
Upgrade is not required in general but recommended for heavy callback users.

More POD tweaks.

Very few changes to scripts/web-gui.pl.  These are untested changes, btw.

### Added
- Callback system is complete.
    - N::B::S::Tracker was the holdup...

## [0.020] - 2008-05-22
Upgrade is recommended in general.

Upgrade is strongly recommended for Win32 systems.

To keep N::B from growing too messy and to make co-development attractive, I'm imposing some coding standards, defining what should be internal, and deciding how N::B should behave.  Between that and the nice weather, the addition of new features (DHT, UDP trackers, etc.) will be pushed back a bit.  The next few releases will probably be bugfix, API, and base protocol-behavioral changes.

Documentation rework in progress.

What's the cutoff for apologizing for things you said in high school?

### Added
- New accessor: N::B::Session::name() - see N::B::Session docs
- New methods for alternative event processing:
    - N::B::process_connections() - implement your own select() statement
    - N::B::process_timers() - easily keep internal timers up to date
- (The piece containing) Outgoing blocks are verified for integrity before being sent to remote peers.  Just in case.
- New sample code: scripts/web-gui.pl
    - µTorrent WebUI-like demo of alternative event processing.

### Changed
- Experimental kbps_up and kbps_down methods and N::B::new() parameters have been renamed properly: kBps_up, kBps_down.  Bits.  Bytes.  It happens.
- Plenty of layout and ideology changes.  None of which immediately affect usability or behavior.
- Extended charset filenames are now handled properly on Win32.
    - Depends on properly encoded utf8 metadata (and the J-Pop fans rejoice)

### Removed
- Experimental N::B::use_unicode() has been removed as wide char filenames are now handled transparently on Win32.

### Fixed
- #1: Line 231 Piece.pm - Check existence of $self->session->files->[$f]->size
    - New .torrent metadata integrity checks during add_session() and piece read/write.
    - Log warning and undef returned when N::B::add_session() is handed a .torrent that does not contain files. (eh, it's a start)

## [0.018] - 2008-04-24
Upgrade is strongly recommended.

New feature: Transfer limits to control how much bandwidth N::B is allowed to use.

No longer causes taint warnings.

perl 5.8.1 required.  This is based solely on available CPAN Reporter PASS/FAIL tests and may not be a true representative value.

### Added
- New methods: kbps_up, kbps_down
- New optional parameters for N::B::new(): kbps_up, kbps_down

### Deprecated
- Old style set_callback_* syntax is depreciated.

### Fixed
- Fixed crash bug in N::B::S::Peer during endgame

## [0.015] - 2008-04-11
### Fixed
- Dup of 0.013 to fix bad M::B dist.  Something fishy going on with the gzip'd file.  Some systems (like PAUSE) properly extract directories and some (like the cpan shell) extract it all into the base directory causing build failures.

## [0.013] - 2008-04-11
Upgrade is recommended.

This is a documentation update.  100% coverage.

### Added
- Early Fast Peers and Ext. Protocol testing. (disabled by default)

### Changed
- log callbacks now include a message level.  See N::B::Util/"LOG LEVELS".

### Removed
- removed peer_outgoing_packet callback in favor of more specific, per-packet-type callbacks.

### Fixed
- Fixed a bug causing files to be re-opened every time they are read.
- Tons of N::B::S::Peer refactoring.  (and much more to do)

## [0.008] - 2008-04-01
### Changed
- It actually exists
- See above

[Unreleased]: https://github.com/sanko/Net-BitTorrent.pm/compare/v2.1.0...HEAD
[v2.1.0]: https://github.com/sanko/Net-BitTorrent.pm/compare/v2.0.1...v2.1.0
[v2.0.1]: https://github.com/sanko/Net-BitTorrent.pm/compare/v2.0.0...v2.0.1
[v2.0.0]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.052...v2.0.0
[0.052]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.051...0.052
[0.051]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.050...0.051
[0.050]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.049...0.050
[0.049]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.046...0.049
[0.046]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.045...0.046
[0.045]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.042...0.045
[0.042]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.040...0.042
[0.040]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.027_001...0.040
[0.027_001]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.025...0.027_001
[0.025]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.024...0.025
[0.024]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.022...0.024
[0.022]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.020...0.022
[0.020]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.018...0.020
[0.018]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.015...0.018
[0.015]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.013...0.015
[0.013]: https://github.com/sanko/Net-BitTorrent.pm/compare/0.008...0.013
[0.008]: https://github.com/sanko/Net-BitTorrent.pm/releases/tag/0.008
