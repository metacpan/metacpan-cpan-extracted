---
title: Running it
nav: Running it
order: 1
---

# Running it

```sh
cd example/Chat
./bin/punk-chat
```

Then open `https://localhost:5443/` and accept the certificate warning.

## What that script does

`bin/punk-chat` generates a self-signed certificate if there is not one
already, starts the application on a Hyperman worker, and puts a TLS
terminator in front of it.

TLS is deliberately not configured in `lib/Chat.pm`. A certificate is a
property of a listener, not of an application, and terminating in front is the
only shape that serves `wss://` on a Hyperman deployment. See the README for
the longer version of that argument.

That argument is now about WebSockets and nothing else. `sse` routes and
`$c->stream` used to share it - all three were built on `detach`, which
refuses TLS because the OpenSSL session state belongs to the server - and
they no longer do: both run on Hyperman's stream-handle seam, which works on
TLS and over HTTP/2. An application whose live updates are server-sent events
can point `tls_cert` and `tls_key` at Hyperman and skip the terminator
entirely.

## Without TLS

For poking at it with `curl`, the plain app is an ordinary PSGI application:

```sh
plackup app.psgi
```

WebSockets will want a real server rather than the default one:

```sh
hyperman --app app.psgi --port 5000
```

## The database

State lives in a SQLite file next to the application, created on first run.
Point it somewhere else with `PUNK_CHAT_DSN`:

```sh
PUNK_CHAT_DSN='dbi:SQLite:dbname=/tmp/chat.db' ./bin/punk-chat
```
