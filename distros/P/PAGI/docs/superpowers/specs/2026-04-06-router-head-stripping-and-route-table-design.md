# Router: HEAD Body Stripping and Route Table API

**Date**: 2026-04-06
**Scope**: `PAGI::App::Router`, `PAGI::Endpoint::Router`

## Feature 1: HEAD Body Stripping

### Problem

The router correctly matches HEAD requests to GET routes (line 734 of `App/Router.pm`), but does not strip the response body. RFC 9110 requires HEAD responses to have no body while preserving the same headers (including Content-Length) the GET response would have sent.

### Design

In the router's HTTP dispatch, when `$method eq 'HEAD'` and we match a GET route, wrap the `$send` coderef before passing it to the handler.

The wrapper:

- Passes `http.response.start` events through unchanged, preserving status code and all headers including Content-Length.
- Intercepts `http.response.body` events and sends them with `body => ''` (empty string) while preserving the `more` flag so the handler's send/done lifecycle completes normally.

### Location

`lib/PAGI/App/Router.pm`, inside the HTTP dispatch block (around lines 756-764), immediately before calling `$route->{_handler}`.

### Behavior Details

- Only applies when the original request method is HEAD and the matched route method is GET.
- Does NOT apply to routes explicitly registered with `head()` -- those handlers are responsible for their own response.
- Content-Length header from the GET handler is preserved per RFC 9110.
- Transfer-Encoding, Content-Type, and all other headers pass through unchanged.

## Feature 2: Route Table API

### Problem

There is no way to programmatically inspect all registered routes. The existing `named_routes()` method only returns routes that have been explicitly named. Debugging routing issues requires reading registration code rather than querying the router.

### Design

Add a `route_table()` method to `PAGI::App::Router` that returns an arrayref of hashrefs describing every registered route and mount.

### Entry Format

Each entry is a hashref with these keys:

```perl
{
    type        => 'http',            # 'http' | 'websocket' | 'sse' | 'mount'
    method      => 'GET',             # HTTP routes only; string, arrayref, or '*'
    path        => '/users/:id',      # the pattern as registered
    name        => 'users.show',      # undef if unnamed
    params      => ['id'],            # parameter names extracted from path
    constraints => { id => qr/\d+/ }, # inline + chained constraints; empty hashref if none
    middleware  => 2,                  # count of middleware attached to this route
}
```

For mount entries:

```perl
{
    type       => 'mount',
    path       => '/api',             # the mount prefix
    name       => undef,              # mounts are not named
    params     => [],                 # mounts have no params
    constraints => {},
    middleware => 1,                   # count of middleware on the mount
}
```

Mount entries do not include a `method` key since mounts handle all methods.

### Ordering

Routes are returned in this order:
1. HTTP routes (registration order)
2. WebSocket routes (registration order)
3. SSE routes (registration order)
4. Mounts (registration order)

This matches the dispatch priority in `to_app`.

### Location

- `lib/PAGI/App/Router.pm` -- new `route_table()` method
- `lib/PAGI/Endpoint/Router.pm` -- pass-through `route_table()` that delegates to the internal `PAGI::App::Router`

### Constraint Merging

Each route entry's `constraints` hashref merges inline constraints (from `{name:pattern}` syntax) and chained constraints (from `->constraints()`). Both are stored as compiled regexes (`qr/.../`).

## Testing

### HEAD Body Stripping Tests

- HEAD request to a GET route returns status 200, correct headers, empty body
- HEAD request to a GET route preserves Content-Length from the GET handler
- HEAD request to an explicit `head()` route is NOT wrapped (handler controls response)
- HEAD request to a non-existent route returns 404
- HEAD request where path matches but only POST is registered returns 405
- Streaming GET handler (multiple `http.response.body` with `more => 1`) has all body chunks stripped under HEAD

### Route Table Tests

- Empty router returns empty arrayref
- HTTP routes appear with correct type, method, path, params, name
- WebSocket and SSE routes appear with correct type
- Mounts appear with correct type and prefix
- Unnamed routes have `name => undef`
- Constraints (inline and chained) appear in constraints hashref
- Middleware count is accurate
- Ordering: HTTP before WebSocket before SSE before mounts
- `Endpoint::Router` pass-through returns same data as underlying `App::Router`
