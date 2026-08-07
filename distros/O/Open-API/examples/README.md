# Open::API example: a CSRF-protected petstore

A complete server and client driven by one OpenAPI 3.1 document
([petstore.json](petstore.json)), showing CSRF protection end to end.

## Files

- `petstore.json` - the spec (routed and validated in C on both sides); a
  `POST /login` establishes the session
- `server.pl` - a Hyperman server: `to_app` with secure headers, an Origin
  allowlist, and a single-use server-side CSRF token issued at login
- `client.pl` - `Open::API::Client` that handles the CSRF handshake
  transparently

## Run it

In one terminal:

    perl examples/server.pl 5000

In another:

    perl examples/client.pl http://127.0.0.1:5000

Or open <http://127.0.0.1:5000/docs> in a browser: `ui => 1` on the server
serves the built-in docs UI (see `perldoc Open::API::UI`; it needs the
sibling Template::Stencil built). Log in via try-it-out on `POST /login`
with `security: []`, then create a pet - the page reads the rotated `csrf`
cookie and sends `X-CSRF-Token` on every unsafe call automatically.

Expected output from the client:

    GET  /pets (anon)  -> 401 (not logged in)
    POST /login        -> 200 (user=alice)
    GET  /pets         -> 200 (user=alice)
    POST /pets  (rex ) -> 201 ok (token rotated for next call)
    POST /pets  (milo) -> 201 ok (token rotated for next call)
    POST /pets  (aria) -> 201 ok (token rotated for next call)
    DELETE /pets/1     -> 204

    without csrf => 1 : POST /login -> 403 (blocked at the Origin check, as expected)

## What to notice

- **Authentication is a declared security scheme.** The spec has a `session`
  `apiKey`-in-cookie scheme, required document-wide; the server's `security`
  checker validates the `sid` cookie and hands the user back in
  `$env->{'openapi.auth'}`. A call before login is a plain **401** (that is the
  security check, independent of CSRF - note it fires on the `GET`, which CSRF
  never touches).
- Login is the one operation with `security: []` (you cannot authenticate a
  request that has no session yet) and is also the one unsafe operation the
  CSRF `check` callback lets through - but it is still guarded by the Origin
  check.
- The client supplied **no** credential for the cookie scheme: a session cookie
  is ambient, so the cookie jar carries it after login and the client does not
  demand it up front. (A `bearer` or header `apiKey` scheme, which is not
  ambient, you would pass via `security => { ... }`.)
- The server keeps the CSRF token in a per-session store and **rotates it on
  every successful state change** - each token is single-use. There is no
  stateless "double-submit" token.
- The client only had to say `csrf => 1`. It presents the `Origin` the server
  requires, captures the token the server sets (at login and on every
  rotation), and echoes it in the `X-CSRF-Token` header on
  `POST`/`PUT`/`PATCH`/`DELETE`, without any per-call code.
- A client that does not opt in is blocked at the Origin check - it cannot
  even log in.

See `perldoc Open::API` (the CSRF, SECURITY, RESPONSE HEADERS and CORS
sections) and `perldoc Open::API::Client` for the full picture.
