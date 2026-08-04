# TODO

## Core client and JetStream capabilities

- [ ] Add JWT-based authorization, including a JWT callback and nonce-signing
  callback for user credentials.
- [ ] Surface `No Responders` (`503`) responses from request/reply operations
  as a distinct result.
- [ ] Handle Lame Duck Mode server notifications by draining or reconnecting
  before the server closes the client connection.
- [ ] Add client-side draining for subscriptions and pending publishes.
- [ ] Add JetStream Key-Value Store APIs.
- [ ] Add JetStream Object Store APIs.

