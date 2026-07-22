# POE-Component-Server-JSONUnix

This module is a small, event-driven server that listens on a Unix
domain socket and speaks a simple JSON request/response protocol. It is
built on POE and is designed to be extended: the set of commands it
understands is a plain dispatch table you can add to at construction
time, at run time, or by subclassing.

It is suitable as a local control or RPC endpoint for a daemon -- the
sort of thing you talk to from a command-line tool, a cron job, or
another process on the same host.

The distribution ships with two clients, both of which also implement
the optional Unix-ownership authentication handshake:

- `POE::Component::Server::JSONUnix::Client` -- an event-driven POE
  client with request/response correlation, callback or event dispatch,
  and per-request timeouts.
- `POE::Component::Server::JSONUnix::BlockingClient` -- a simple
  blocking client for scripts and tools that do not use POE.

# INSTALL

## Source

```shell
perl Makefile.PL
make
make test
make install
```

## FreeBSD

```shell
pkg install p5-POE p5-JSON-MaybeXS p5-Cpanel-JSON-XS p5-App-cpanminus
cpanm POE::Component::Server::JSONUnix
```

## Debian

```shell
pkg apt-get install libpoe-perl libjson-maybexs-perl libcpanel-json-xs-perl cpanminus
cpanm POE::Component::Server::JSONUnix
```

# PROTOCOL

The framing is newline-delimited JSON: each message is a single JSON
object on its own line, terminated by "\n".

A request looks like:

```json
{"command":"add","args":{"numbers":[1,2,3]},"id":7}
```

| var       | required? | description                                                         |
|-----------|-----------|---------------------------------------------------------------------|
| `command` | yes       | The name of the command to run. "cmd" is accepted as an alias.      |
| `args`    | no        | An arbitrary payload passed straight through to the handler.        |
| `id`      | no        | Echoed so asynchronous clients can correlate replies with requests. |

A successful response:

```json
{"id":7,"status":"ok","result":{"sum":6}}
```

An error response:

```json
{"id":7,"status":"error","error":"unknown command: subtract"}
```

Malformed JSON, a non-object request, a missing command, an unknown
command, or a handler that dies all produce an "error" response rather
than disturbing the server or other clients.
