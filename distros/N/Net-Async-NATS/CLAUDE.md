# CLAUDE.md

## Distribution

Net::Async::NATS — Async NATS messaging client for IO::Async.

Uses Dist::Zilla with `[@Author::GETTY]` plugin bundle.

## What is NATS?

NATS is a lightweight, high-performance messaging system. The wire protocol is text-based over TCP, similar to Redis or SMTP in simplicity. No JetStream — this client implements core NATS pub/sub only.

## Architecture

```
Net::Async::NATS            — Main client (IO::Async::Notifier)
  ├── connect/disconnect     — TCP + CONNECT/INFO handshake
  ├── publish                — PUB <subject> <bytes>\r\n<payload>\r\n
  ├── subscribe/unsubscribe  — SUB/UNSUB with callback dispatch
  ├── request                — Request/Reply via auto-generated _INBOX
  └── ping                   — PING/PONG keepalive

Net::Async::NATS::Subscription — Subscription value object (sid, subject, queue, callback)
```

## NATS Wire Protocol Reference

All commands are CRLF-terminated (`\r\n`). Protocol is case-insensitive.

### Server → Client
- `INFO {json}\r\n` — Server info (sent on connect, may repeat)
- `MSG <subject> <sid> [reply-to] <#bytes>\r\n[payload]\r\n` — Message delivery
- `HMSG <subject> <sid> [reply-to] <#hdr_bytes> <#total_bytes>\r\n[headers]\r\n\r\n[payload]\r\n` — Message with headers
- `PING\r\n` — Keepalive probe (client must respond PONG)
- `PONG\r\n` — Response to client PING
- `+OK\r\n` — Acknowledgement (only if verbose=true)
- `-ERR '<message>'\r\n` — Error (some close connection, some don't)

### Client → Server
- `CONNECT {json}\r\n` — Auth + capabilities (sent after receiving INFO)
- `PUB <subject> [reply-to] <#bytes>\r\n[payload]\r\n` — Publish
- `HPUB <subject> [reply-to] <#hdr_bytes> <#total_bytes>\r\n[headers]\r\n\r\n[payload]\r\n` — Publish with headers
- `SUB <subject> [queue] <sid>\r\n` — Subscribe
- `UNSUB <sid> [max_msgs]\r\n` — Unsubscribe (optionally after N messages)
- `PING\r\n` / `PONG\r\n` — Keepalive

### Key CONNECT JSON fields
`verbose`, `pedantic`, `tls_required`, `auth_token`, `user`, `pass`, `name`, `lang`, `version`, `protocol` (1=dynamic cluster info), `echo`, `headers`, `no_responders`, `nkey`, `jwt`, `sig`

### Key INFO JSON fields
`server_id`, `server_name`, `version`, `max_payload`, `proto`, `auth_required`, `tls_required`, `connect_urls`, `headers`, `jetstream`, `nonce`

## Dependencies

- **IO::Async** / **IO::Async::Stream** — Async TCP
- **Future** / **Future::AsyncAwait** — Async control flow
- **JSON::MaybeXS** — JSON encode/decode for INFO/CONNECT

No Moo/Moose — uses plain `parent 'IO::Async::Notifier'` like Net::Async::Kubernetes.

## File Structure

```
lib/Net/Async/NATS.pm              — Main client
lib/Net/Async/NATS/Subscription.pm — Subscription object
t/00-load.t                        — Module loading
t/01-subscription.t                — Subscription object unit tests
t/02-protocol-parse.t              — Wire protocol parsing (no network)
t/03-live.t                        — Live integration tests (needs NATS server)
```

## Testing

```bash
prove -l t/                              # Unit tests (no NATS needed)
TEST_NATS_HOST=localhost prove -lv t/    # All tests including live
```

Live tests (`t/03-live.t`) require `TEST_NATS_HOST` env var. They use `test.nats.perl.*` subjects to avoid collision.

## PodWeaver

Uses `@Author::GETTY` conventions: inline `=attr`, `=method`, `=seealso`. No manual NAME/VERSION/AUTHOR/COPYRIGHT sections. Every `.pm` needs `# ABSTRACT:`.

## TODO / Future Work

- [ ] TLS support (IO::Async::SSL)
- [ ] NKey/JWT authentication
- [ ] HPUB (publish with headers)
- [ ] Header parsing in HMSG (currently delivers payload only)
- [ ] Queue group load balancing tests
- [ ] Configurable PING interval
- [ ] Cluster URL failover from INFO.connect_urls
- [ ] Drain mode (graceful unsubscribe)
