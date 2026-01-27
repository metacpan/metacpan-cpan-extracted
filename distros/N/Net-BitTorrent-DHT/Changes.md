# Changelog

All notable changes to Net::BitTorrent::DHT will be documented in this file.

## [v2.0.0] - 2026-01-26

This is a total rewrite. I was breaking apart the Kademlia stuff into smaller pieces for a larger, non-BitTorrent related project so I spent a day on this...

### Added

- Pulled out of Net::BitTorrent::DHT for use in other DHTs.
- Supports...
  - BEP05: Core DHT spec
  - BEP32: IPv6
  - BEP33: DHT scrape
  - BEP42: Secure DHT
  - BEP43: Readonly DHT node
  - BEP44: Arbitrary mutable/immutable data storage in the DHT network (very nice)
  - BEP51: Infohash indexing

## [v1.0.3] 2014-11-29

### Changed

- Declare Type::Standard dependency

## [v1.0.2] 2014-06-26

### Changed

- Serve as a standalone node by default
- Update to NB::Protocol v1.0.2 and above

## [v1.0.1] 2014-06-21

### Changed

- Generate local node id based on external IP (work in progress)
- Use a condvar in address resolver instead of forcing the event loop

## [v1.0.0] 2014-06-21

- original version (broken from unstable Net::BitTorrent dist)

[Unreleased]: https://github.com/sanko/Net-BitTorrent-DHT.pm/compare/v2.0.0...HEAD
[v2.0.0]: https://github.com/sanko/Net-BitTorrent-DHT.pm/compare/v1.0.3...v2.0.0
[v1.0.3]: https://github.com/sanko/Net-BitTorrent-DHT.pm/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/sanko/Net-BitTorrent-DHT.pm/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/sanko/Net-BitTorrent-DHT.pm/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Net-BitTorrent-DHT.pm/releases/tag/v1.0.0
