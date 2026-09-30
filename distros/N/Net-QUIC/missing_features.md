# Missing QUIC Features

This document tracks canonical QUIC capabilities that Net::QUIC does not yet
implement or expose as supported public features.

It separates gaps in the base QUIC/TLS transport from standardized extensions
and from lower-level capabilities that ngtcp2 may already provide internally
but Net::QUIC does not yet expose.

## Base QUIC and TLS features not yet implemented

### TLS session resumption

Net::QUIC does not currently save and reuse TLS session tickets to resume a
previous QUIC connection.

This is separate from 0-RTT. Session resumption can be useful even when early
application data is not enabled.

### 0-RTT / early data

A returning client cannot currently send application stream data before the new
handshake completes.

This requires session resumption plus safe retention and validation of the
transport parameters that matter to early data.

### Active connection migration

Net::QUIC currently advertises active migration as disabled.

There is no public API for moving an established connection to a different
local address, interface, socket, or peer path.

### Path management and validation

Net::QUIC does not currently expose path probing, path validation state, path
failure, path selection, or path switching.

ngtcp2 already provides underlying path machinery, but Net::QUIC does not yet
turn it into a supported public feature.

### Server preferred address

A server cannot advertise a preferred address and a client cannot validate and
move to that address after the handshake.

### NEW_TOKEN support

Net::QUIC supports Retry and Retry-token address validation, but it does not
yet implement the separate NEW_TOKEN mechanism for giving a client a token it
can use on a future connection.

### PMTU discovery

Net::QUIC does not actively discover and maintain the largest safe UDP payload
for each network path.

Packet sizing and PMTU policy currently remain internal.

### ECN

Net::QUIC does not currently:

- receive ECN markings from UDP ancillary data
- pass received ECN information into ngtcp2
- select ECN markings for outgoing packets
- expose ECN validation or state

### TLS client-certificate authentication

The client verifies the server certificate today.

The server cannot currently request and validate a client certificate for
mutual TLS authentication.

## Base QUIC operations not yet exposed cleanly

### Independent RESET_STREAM and STOP_SENDING

The public Stream API currently provides a combined reset operation.

QUIC has two independent directional operations:

- RESET_STREAM aborts the local sending side
- STOP_SENDING asks the peer to stop its sending side

Net::QUIC should eventually expose these independently.

### Application PING / keepalive

Net::QUIC does not expose an application-level way to request a QUIC PING or a
keepalive policy for deliberately preventing an otherwise idle connection from
timing out.

### Application-initiated key update

The required TLS/ngtcp2 key-update callback is already wired, so key update
support is not absent at the protocol level.

Net::QUIC does not currently expose a public operation for deliberately
initiating a new 1-RTT key phase.

### Connection-close reason text

Application connection close supports an error code, but Net::QUIC does not
currently expose the optional human-readable reason phrase carried by a QUIC
CONNECTION_CLOSE frame.

### Connection ID policy

Connection IDs are currently managed internally.

Net::QUIC does not expose deployment-specific CID policy such as:

- zero-length connection IDs
- custom connection ID generation
- custom CID lengths
- custom rotation policy

## Standardized QUIC extensions not yet implemented

### QUIC DATAGRAM

Net::QUIC does not implement the standardized QUIC DATAGRAM extension for
unreliable, unordered application datagrams carried inside a QUIC connection.

This is distinct from Net::QUIC::Datagram, which represents the UDP packets
that carry QUIC itself.

### Compatible Version Negotiation

The server can already generate Version Negotiation packets and advertises QUIC
v1 and v2.

Net::QUIC does not yet expose the complete compatible-version-negotiation flow
or its associated transport parameters.

### Complete QUIC v2 client selection

The server can accept the version present in a valid client Initial, and
Version Negotiation advertises v1 and v2.

The client currently starts with QUIC v1 and there is no public version
selection or preferred-version policy.

### QUIC bit greasing

Net::QUIC does not currently expose or deliberately configure QUIC-bit
greasing behavior.

### qlog

Net::QUIC does not expose ngtcp2 qlog events or provide a qlog output API.

This is an observability feature rather than an application transport feature,
but it is a common part of mature QUIC implementations.

### Congestion-controller selection and tuning

Congestion control is already present through ngtcp2.

Net::QUIC does not currently expose controller selection or lower-level
congestion-control tuning such as controller choice, initial RTT policy, or
other advanced recovery knobs.

## Highest-priority remaining transport features

The largest remaining feature groups are:

1. TLS session resumption
2. 0-RTT / early data
3. active migration and path management
4. independent RESET_STREAM and STOP_SENDING operations
5. QUIC DATAGRAM
6. preferred address and NEW_TOKEN
7. PMTU discovery
8. ECN
9. complete QUIC v2 / compatible version negotiation
10. qlog and advanced congestion-control configuration

## Already implemented

The following should not be treated as missing:

- QUIC v1 transport
- server acceptance of negotiated QUIC versions
- Version Negotiation responses
- TLS 1.3
- ALPN
- server certificate verification
- optional private CA files
- bidirectional streams
- unidirectional streams
- concurrent stream limits
- stream-credit replenishment
- connection-level and stream-level flow control
- FIN
- stream reset
- connection close
- closing and draining periods
- idle timeout
- handshake timeout
- loss recovery
- congestion control
- Retry
- Retry-token address validation
- anti-amplification handling through ngtcp2
- connection IDs
- connection ID routing and retirement
- Stateless Reset
- explicit connection error information
- exact local-path handling
- UDP backpressure handling
- event-loop-neutral Driver integration

## Not currently considered part of the initial missing-feature list

Multipath QUIC is intentionally not included in the initial completeness list.

It is a newer extension area rather than part of the original base QUIC
transport feature set and should be evaluated separately after the core
remaining features above.
