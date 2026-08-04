# Changelog

## 0.3.4 - 2026-08-03

### Added

- Added `Net::NATS2::Base`, which exports `has` for generating fluent
  getter/setter accessors with scalar or lazy defaults.
- Added NKey authentication with a public key and nonce-signing callback.
- Added `TODO.md` to track planned NATS Server 2.xx and broader client support.

### Changed

- Refactored NATS2 model classes to use the shared accessor implementation.
- Replaced internal lvalue accessor updates with fluent setter calls while
  preserving numeric subscription ID and message-count behavior.

## 0.3.3 - 2026-07-31

### Fixes

- Sync README.md vs Pod

## 0.3.2 - 2026-07-21

### Fixes

- Skip tests if NATS server is unavailable.

## 0.3.1 - 2026-07-21

Added JetStream protocol support. Added auto-reconnect feature.

### Added

- Added `hpublish` and its `publish_with_headers` alias for NATS `HPUB`.
- Added `HMSG` delivery support. Received messages expose the raw header block
  through `headers` and its byte length through `header_length`.
- Added header capability tracking from the server `INFO` message.
- Added `Net::NATS2::JetStream` with account info, stream create/update/info,
  list, purge, delete, and synchronous publish acknowledgements.
- Added durable pull-consumer creation, batch fetches, next-message retrieval,
  and `ACK`, `NAK`, and `TERM` message replies.
- Added opt-in automatic reconnection with configurable attempts and delay;
  existing subscriptions are restored after reconnecting.

### Fixed

- Advertise header support in `CONNECT` and avoid sending `HPUB` when the
  server reports that headers are unavailable.
- Calculate `PUB` and `HPUB` payload lengths in UTF-8 bytes and encode
  UTF-8-flagged outbound protocol data before writing it to the socket.
- Send the current `tls_required` CONNECT option rather than the legacy
  `ssl_required` option.
- Restore `nats://` URI host, port, user, and password accessors with current
  versions of the `URI` module.
- Added `Client->request_sync` for request/reply APIs that need a single
  synchronous response, including JetStream.

## 0.3.0

This is a maintained fork of Carwyn Moore's `Net::NATS::Client` 0.2.2.

### Breaking changes

- Renamed the distribution from `Net-NATS-Client` to `Net-NATS2-Client`.
- Renamed the public module namespace from `Net::NATS::*` to `Net::NATS2::*`.
- Replaced the public `URI::nats` scheme adapter with the internal
  `Net::NATS2::URI` class.  Construct clients with `Net::NATS2::Client`.

### Changed

- Removed the `Class::XSAccessor` dependency.  All constructors, accessors,
  lvalue accessors, and the subscription defined predicate are now implemented
  in pure Perl.
- Declared Perl 5.10.1 as the minimum supported Perl version.
- Updated examples, tests, POD, README, distribution metadata, and upstream
  attribution for the new namespace.
- Moved the full MIT licence text to `LICENSE`, retaining both the upstream and
  fork copyright notices.
- Made `Subscription->auto_unsubscribe` and `Subscription->unsubscribe`
  fluent by returning the subscription object.

### Fixed

- Avoided direct `sysread` and `substr` mutation of the connection buffer
  accessor, preventing the `realloc(): invalid pointer` abort seen during
  socket reads.

### Added

- Added tests. Tests require Docker Compose.
- Added `Net::NATS2::Client->ping($timeout)` for explicit connection liveness
  checks.  It sends `PING`, waits for `PONG`, and continues dispatching normal
  protocol operations while it waits.
- Added regression coverage for pure-Perl accessors, NATS URI parsing,
  publish/subscribe behavior, and PING/PONG liveness checks.
