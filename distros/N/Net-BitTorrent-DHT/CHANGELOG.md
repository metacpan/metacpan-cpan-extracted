# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Initial BitTorrent DHT implementation using Net::Kademlia base.
- Integration with Net::BitTorrent::Protocol::BEP03::Bencode.
- Basic PING query handling.

[v1.0.2] 2014-06-26

### Changed

- Serve as a standalone node by default
- Update to NB::Protocol v1.0.2 and above

[v1.0.1] 2014-06-21

### Changed

- Generate local node id based on external IP (work in progress)
- Use a condvar in address resolver instead of forcing the event loop

[v1.0.0] 2014-06-21

### Changed

- original version (broken from unstable Net::BitTorrent dist)
