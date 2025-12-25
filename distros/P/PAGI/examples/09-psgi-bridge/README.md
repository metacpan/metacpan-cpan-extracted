# 09 – PSGI Bridge Demo

Wraps a synchronous PSGI app so it can run inside a PAGI HTTP scope:
- Converts the PAGI scope into a PSGI `%env` hash.
- Reads `http.request` events and exposes them as `psgi.input`.
- Sends the PSGI response back as PAGI `http.response.*` events.

This mirrors the compatibility guidance in `docs/specs/www.mkdn`.

*Note*: This demo assumes the PSGI app returns a simple arrayref `[ $status, $headers, $body_chunks ]`.

## Quick Start

**1. Start the server:**

```bash
pagi-server --app examples/09-psgi-bridge/app.pl --port 5000
```

**2. Demo with curl:**

```bash
# GET request - processed by legacy PSGI app
curl http://localhost:5000/
# => Hello from PSGI!

# POST request - body is passed through to PSGI
curl -X POST http://localhost:5000/ -d "data=test"
# => PSGI received: data=test

# The PSGI app runs synchronously but is wrapped in PAGI async interface
```

## Use Case

This bridge allows running existing PSGI applications (Catalyst, Dancer, Mojolicious::Lite, etc.) on a PAGI server without modification.

## Spec References

- PSGI compatibility guidance – `docs/specs/www.mkdn`
