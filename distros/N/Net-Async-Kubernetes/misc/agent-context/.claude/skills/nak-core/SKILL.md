---
name: nak-core
description: Load before editing Net::Async::Kubernetes — the Kubernetes::REST seam, class resolution and error convention, ensure/ensure_only, Watcher and Controller mechanics, websocket duplex transport, the dual-mode test harness.
---

# Net::Async::Kubernetes — Core Architecture

Async Kubernetes client on IO::Async. `Kubernetes::REST` is used as
request-builder/response-inflater; its own `io` backend never carries a request —
except discovery when `discover` did not read it first (see
`resource_map_from_cluster` below). `IO::K8s` provides the typed objects. `$VERSION`
is hand-written in every module; dzil bumps it.

## Classes

- **`Net::Async::Kubernetes`** (`lib/.../Kubernetes.pm`) — IO::Async::Notifier. Config:
  `kubeconfig`, `context`, `server`, `credentials`, `resource_map`,
  `resource_map_from_cluster` (default 0), `with` (CRD providers, passed to
  `Kubernetes::REST->new(with =>)`, public there since 1.108). Public API (all returning Futures unless
  noted): `list` → `IO::K8s::List` (use `->items`!; `labelSelector`/`fieldSelector`
  go out as query parameters), `get`/`create`/`update`/`patch` → inflated object,
  `patch_status` (PATCH `.../status`, default type `merge`) / `update_status` (PUT
  `.../status`, whole object) → inflated object, `delete` → `1` (`propagationPolicy`
  Background|Foreground|Orphan as query parameter; any other value or unknown option key
  fails the Future, worded as in Kubernetes::REST), `ensure` → object,
  `ensure_all` → objects in input order, `ensure_only` → the applied objects,
  `discover` → nothing (see Unstructured and discovery), `log` →
  full text or `undef` with `on_line`, `port_forward`/`exec`/`attach` → session,
  `cp_to_pod`/`cp_from_pod` → `{local,remote,bytes,stderr,status}`. Non-Future:
  `rest` (the lazy `Kubernetes::REST`), `new_object`, `expand_class`, `watcher(...)`,
  `controller(...)` (both `add_child` the returned notifier).
- **`Net::Async::Kubernetes::PortForwardSession`** (`lib/.../PortForwardSession.pm`) —
  own file since 0.008, `use`d from `Kubernetes.pm`. Blessed hashref around `ws_client`:
  `write_channel($ch,$payload)`, `write_stdin`, `resize(width=>,height=>)` (channel 4
  JSON), `close($code?,$payload?)`; aliases `write`/`stdin`.
- **`Net::Async::Kubernetes::Watcher`** — Notifier; auto-reconnecting watch stream.
  Config: `kube` (**weak ref**), `resource`, `namespace`, `timeout` (300),
  `label_selector`, `field_selector`, `names`, `event_types`, `reconnect_delay` (1),
  `max_reconnect_delay` (30), `reconnect_jitter` (0.2), `max_retries` (undef =
  forever), `min_watch_duration` (1; the five are validated in `configure`, croak),
  `on_added/on_modified/on_deleted/on_error/on_event`.
  `start` idempotent; `stop`.
- **`Net::Async::Kubernetes::Controller`** — Notifier; minimal controller runtime.
  Config: `kube` (**weak ref**) OR client-construction keys (builds its own client,
  held strongly — it owns that one), `on_reconcile` (required), `on_watch_error`,
  `retry_delay` (scalar|arrayref|coderef, default 1). API:
  `watch_resource($resource, %watcher_args, key_for=>sub)`, `start`/`stop`,
  `get_object`/`list_objects` (thin `$kube->` wrappers), `patch_status` (own signature
  `status => {...}`, merge default; refuses any other key itself (k65) — the client
  only sees `patch`/`type` — and an odd list after the object or the positional
  name (k68, `Invalid arguments to patch_status()`, as the keyed form always did;
  the client refuses it the same way since k69); builds `{status => ...}` and
  delegates to the client's `patch_status`), `update_status` (delegates to the client's). Both report
  every bad input as a failed Future — `update_status` pre-checks with `_object_class`
  where the client would croak.

## Request pipeline — the Kubernetes::REST seam

One lazy `Kubernetes::REST` in `rest` (`_rest` is the same); one shared
`Net::Async::HTTP` in `_http` (`max_connections_per_host => 0` so watch streams don't
starve CRUD — never add a second UA). Uniform CRUD shape:

```
my ($class, $error) = $self->_resolve_class($name);        # or _object_class($label, $obj)
(my $path, $error) = $self->_request_path($class, $name_or_obj, name=>, namespace=>);
return Future->fail($error) unless defined $path;             # croak in croaking methods
  → $rest->prepare_request(METHOD, $path, body=>, parameters=>, headers=>)
  → $self->_checked_request($req, "op class")      # _do_request + _checked_response
  → ->then { $rest->inflate_object/inflate_list($self->_exact_class($class), $res) }
```

Use only the public building blocks: `expand_class`, `build_path`, `prepare_request`,
`check_response` (croaks on status ≥ 400; called only in `_checked_response`),
`inflate_object`, `inflate_list`, `process_watch_chunk`, `process_log_chunk`,
plus the documented `io` attribute. Never call `_`-prefixed Kubernetes::REST internals;
where the client needs one's behaviour it keeps a private mirror of its own
(`_unstructured_hint`, `_api_version_and_kind`, `_exact_class`).

### Class resolution and the error convention

Nothing unusable reaches `build_path`, which would die synchronously without naming
the resource:

- `_resolve_class($name)` — `$rest->expand_class` fails closed for a qualified name
  (`undef`) but open for a bare Kind (a fabricated `IO::K8s::<Kind>`); both, and a
  fabricated name that does not load, are "unknown resource '…'". A reference in
  the class-name position (a manifest hashref handed to `patch`) never reaches
  `expand_class`: `_resource_name_error` refuses it with "resource name must be a
  string, got a HASH reference" (a blessed one: "got an object of class …").
  Everything else goes to `_usable_class`. `get` and `delete` (class form) call
  the same helper on their object-name positional too — `get('Pod', $ref)`,
  `delete('Pod', {name=>'web'})` would otherwise stringify it into the path and
  fail only as the server's 404 (k70, t/37); the `_named_args` methods (`log`, the
  duplex methods, `patch`'s class form) already refuse a reference there as
  `Invalid arguments to METHOD()` via their `!ref` positional test.
- `_usable_class($name, $class)` — the class must load (else its load error) and
  answer `api_version` as a class method (else "not a Kubernetes resource class" — a
  bare `List`, `Resource`, `Types`, `Unstructured`). `IO::K8s::Unstructured` passes
  unless reached through its own bare name. The public `expand_class` therefore loads
  what it returns.
- `_object_class($label, $object)` — the same check on `ref($object)` for the object
  forms (`create`, `update`, `update_status`, `patch`, `patch_status`, `delete`,
  `ensure`); not blessed → "requires an IO::K8s object".

All three return the class or `(undef, $message)`; the caller reports it per its
contract. So does `_unknown_argument_error($label, \%args, @allowed)` (k63): the
first unknown key in sort order as `Unknown argument 'KEY' to METHOD() (allowed:
a, b)` — Kubernetes::REST's wording — checked right after argument parsing, before
class resolution, in `list` (`_list_request`), `get`, `log`, `patch`/`patch_status`
(`_patch_args`; object form only `patch`, `type`) and `ensure_only` (croaks);
k65 added `port_forward`, `exec`, `attach`, `cp_to_pod`, `cp_from_pod` (before,
leftovers went to `build_path`, which reads a stray `subresource` into the path;
since k67 these five and `log` parse through `_named_args($label, \@args,
@allowed)`: one list per method is both the positional-name test — a first
argument that is an allowed key, or a reference, starts the keyed form — and the
unknown-key check; returns `(undef, %args)` or the message, `Invalid arguments
to METHOD()` for an odd list; test: `t/45`) and
the Controller's `patch_status` (via `$self->kube->`; object form only
`status`, `type`) — all failed Futures, right after argument parsing (cp_*: after
their loop check);
`delete` uses it too (k64), after its class and name checks as since k60, and
`_propagation_policy_error` words a bad policy as REST does: `Unknown
propagationPolicy 'x' for delete() (use: Background, Foreground, Orphan)`.
`watcher` needs none: `IO::Async::Notifier::configure` croaks on an
unknown key. An odd option list (k69, test `t/46`) is `Invalid arguments to
METHOD()`, checked before the unknown-key check — never a Perl warning and a
request without the stray key's value: failed Future in `get` (own parse: a
lone argument stays the name even when spelled `namespace`, which
`_named_args` would refuse), `list`/`_list_request`, `_patch_args` (object
form a direct check, class form through `_named_args`), `delete` and the
`_named_args` methods; croak in `ensure_only`, `watcher`, `controller` and the
Controller's `watch_resource`. A new method taking options does the same.
**Input errors known before any request croak synchronously** in
`expand_class`, when a watcher starts, and in `update`, `update_status`, `ensure`
(incl. `ensure_only`'s hashref resolution and missing `label`); every other
Future-returning method returns `Future->fail($message)`. `ensure_all` never croaks —
an `ensure` croak fails its chain. **Errors of the flow itself** are always failed
Futures: HTTP ≥ 400 → `_checked_response($response, $context)` →
`Future->fail($err, 'http', $response)`, `$err` exactly what `check_response` throws
(a `Kubernetes::REST::APIError` object — never rebuilt here); transport failures as the transport reports them. Every status
check goes through `_checked_response` (`_checked_request` = `_do_request` + it), the
unchecked `ensure`/`ensure_only` branches included; only the Watcher still calls
`check_response` itself, for the cause text of its `WatchFailed` report.

### Unstructured and discovery

- `resource_map_from_cluster => 1`: Kubernetes::REST fetches discovery (`GET /api`,
  `GET /apis`) **through its own synchronous `io`** (LWP by default), once, on first
  use — it blocks the loop and bypasses `_do_request` — unless `discover` ran first.
  Its map resolves shipped Kinds; a Kind discovery lists but nothing ships resolves
  to `IO::K8s::Unstructured`.
- `discover` (k59, never called implicitly): off without `resource_map_from_cluster`
  (done, nothing sent). Otherwise REST's `prepare_discovery_requests`: both
  requests through `_checked_request`
  (`needs_all`; ≥ 400 → `fail($err, 'http', $response)`), then `absorb_discovery`
  inside `then` (a croak — bad JSON — fails the Future); `absorb_discovery` false =
  legacy discovery, still done, REST reads it synchronously on first use. Test:
  `t/42` (recording REST io).
- Unstructured has no class-level api_version; `build_path` needs `kind` (and
  `api_version`) from the caller and takes plural and scope from the discovery catalog.
  `build_path` is called in one place only, `_request_path($class, $ident, %args)`
  (CRUD, status, log, duplex, both paths in `ensure`, the Watcher), which adds
  `_unstructured_hint($class, $ident)`: empty for typed classes;
  `kind`/`apiVersion` of an Unstructured object; a name split like `expand_class`
  splits it (a qualified `group/version/Kind` keeps group and version; `+…` and
  `…::…` names carry no Kind).
- An `apiVersion` in the hint pins the group/version. Kubernetes::REST refuses a
  pinned one the cluster does not serve (its k43); the client checks that itself as
  well: `_request_path` rejects a path outside
  `/apis/<group>/<version>/` (`/api/<version>/` for core) with REST's message, and
  `_usable_class` probes a qualified name that resolved to Unstructured through
  `_request_path` (no request, cached catalog) → "unknown resource".
- Without discovery (`resource_map_from_cluster` 0, the default), or for an explicit
  `IO::K8s::Unstructured` class name or an Unstructured object without `kind`,
  `build_path` croaks. `_request_path` catches it and returns `(undef, $message)`
  (location stripped), which the caller reports like a resolution error: failed
  Future, or croak in `update`/`update_status`/`ensure`/the Watcher's start.
- Unstructured status lives in the unknown-fields bag: read it via `TO_JSON`, never
  `->status`.

### Unchecked requests

`_request_unchecked(METHOD, $path, %opts)` resolves with the raw
`Kubernetes::REST::HTTPResponse`. `_list_request` / `_delete_request` are `list` /
`delete` up to that point and resolve with `($class, $response)` (argument errors
still fail first). Branch on `$response->status`, never on the text `check_response`
croaks with.

### Transports

- `_do_request` wraps the HTTP::Response back into `Kubernetes::REST::HTTPResponse` —
  that re-wrap is the seam mocks and live transport share.
- `_do_streaming_request($req, $on_chunk)` (GET-only): `on_header` installs the chunk
  callback; resolves at the end of the stream with a `Kubernetes::REST::HTTPResponse`
  — empty content for a success, the error body for a status ≥ 400. An error body is
  never passed to `$on_chunk` (it would pass for a log line or a watch event); the
  caller runs `check_response` on the response.
- Override points the test harness replaces: `_do_request`, `_do_streaming_request`,
  `_do_duplex_request`, `_add_to_loop`, `_make_websocket_client`.

## ensure / ensure_all / ensure_only

- Hashref → `_manifest_to_object`: `apiVersion` is authoritative
  (`expand_class($kind, $apiVersion)`, croak naming both if nothing serves it); no
  apiVersion → bare Kind. The resolved class goes to `struct_to_object` as
  `'+'.$class` — a plain `Gizmo` (from `'+Gizmo'` in the map) would be re-read as a
  Kind.
- `ensure`: unchecked GET → 404: POST; POST 409 → refetch → the same path as an
  existing object. Existing: core `v1` PersistentVolumeClaim returned unchanged;
  `batch/v1` Job returned while active/succeeded, else delete with `propagationPolicy`
  Background (failure ignored) + `create`; anything else PUT at the server's
  resourceVersion (written back into the caller's object), a 409 there refetches once
  and calls `update` (no further retry).
  Special cases are matched by `_api_version_and_kind` (exact apiVersion + Kind; class
  data for typed objects, instance data for Unstructured) — never by class name.
- `ensure_all`: strictly sequential Future chain; the first failure stops it.
- `ensure_only`: resolves every hashref first, then `ensure_all`, then per kind ×
  namespace (sequential) `_list_request` and per unexpected item (sequential)
  `_delete_request` with `propagationPolicy` (option, default Background; an unknown
  value croaks up front). Key = (API group, Kind, namespace, name) from each object —
  never from the `kinds` string; no version. A 404 on list or delete is silent;
  any other failure (HTTP error, transport error, unresolvable `kinds` entry) is
  `carp`ed (`ensure_only: cannot list <Kind> in namespace '<ns>' | at cluster scope,
  nothing pruned there: <reason>` / `cannot delete <Kind> '<name>' …`) and the prune
  goes on. The reason drops the caught croak's location; carp's own points into
  Future (the callback's caller). A dying `$SIG{__WARN__}` fails the Future. Resolves
  to the applied objects either way.

## Watcher mechanics

- Params per cycle: `watch=true`, `timeoutSeconds`, tracked `resourceVersion`,
  selectors. `resourceVersion` updated from every processed chunk result. Resolving
  the resource croaks in `_start_watch` (at add/start).
- **410 Gone**: clears `resourceVersion`, drops remaining events in that chunk, is NOT
  delivered to `on_error`; stream ends naturally and reconnects without a version.
- Reconnect: a cycle that ends with status < 400 → immediate restart (and failure
  count reset) — unless it ended right after a non-410 ERROR event, or without any
  event within `min_watch_duration` (default 1 s, client-go's "very short watch";
  measured with `_now` = `$loop->time`, the test override point). Those, a response
  ≥ 400 and a failed request → `_watch_failed`: delay `reconnect_delay * 2**(n-1)`
  capped at `max_reconnect_delay` (exponent capped at 64), then shortened (never
  lengthened) by `reconnect_jitter * _random_fraction` and rounded to ms
  (`_random_fraction` = `rand`, the test override point; tests that assert delays
  pass `reconnect_jitter => 0`), held in `_retry_future`;
  a non-ERROR event on a stream resets the failure count (an ERROR event never
  does; a 410 counts as an event for the empty-stream rule). Each failure is
  reported — whatever `event_types` says — as a `Status` hashref (`reason =>
  'WatchFailed'`, `code` = HTTP status, the ending ERROR event's code, or 0,
  `message` "watch X failed, retrying in Ns: cause" (`_cause_text`, k74: an
  APIError as `HTTP <code> <reason>: <message>` from its accessors, the body when
  it holds no Status; anything else without its trailing ` at FILE line N.`),
  `details => {kind,
  retryAfterSeconds}`) to `on_error`, else `warn`. Past `max_retries` consecutive
  failures it stops first, then reports "giving up after N retries". No
  `allowWatchBookmarks`, no informer cache.
- `start` is a no-op while watching or waiting on `_retry_future`, and resets the
  failure count. `stop` cancels a pending `_retry_future` and defers `$f->cancel` via
  `$loop->later` — cancelling inside the connection's own `on_read` triggers
  Net::Async::HTTP's "Spurious on_read of connection while idle". Any new cancel path
  must defer the same way. `on_error` may call `stop`.
- Dispatch order: type filter (explicit `event_types`, else derived from which
  callbacks are set; `on_event` = catch-all), name filter (skipped for ERROR), then
  `on_event($event)` and one of `on_added/on_modified/on_deleted($object)`;
  `on_error` gets the **raw hashref** for ERROR events. Callbacks are not eval-guarded.

## Controller runtime

- `_add_to_loop` croaks without `kube`+`on_reconcile`, adds `kube` to the loop if
  needed, croaks on loop mismatch, then `start`.
- Workqueue: key = `key_for->($object,$spec)` else `"ns/name"`. Newest event
  overwrites the queued entry's ctx (latest state wins); `active` entries get
  `dirty=1` and requeue after the in-flight reconcile; `queued` dedups.
- Entry lifetime: an entry is **dropped once its key reconciles cleanly** (nothing
  queued, dirty or retrying) — `{entries}` is not a cache, it is pending work.
  A failed key keeps entry, `failures` and armed retry, so backoff survives.
  `DELETED` needs no case of its own; its reconcile ends in the same branch.
- The drain **skips** a queued key whose entry is gone instead of abandoning the
  rest of the queue. Unreachable today; it guards the next change to the prune
  conditions.
- **Reconciles are globally serialized** (`active_key`) — one in flight per
  controller, not per key; long reconciles head-of-line block everything.
- Reconcile return: die → failed Future; non-Future → done. Failure increments
  `failures` and schedules retry via `retry_delay` (coderef `($attempt,$ctx,$error)`,
  arrayref indexed by attempt, scalar; 0/false ⇒ hot `$loop->later` requeue). No
  attempt cap, no jitter.
- ctx hashref: `{controller, kube, resource, event_type, object, key, attempt}`.
  `controller` and `kube` are **weak** — the ctx outlives the reconcile inside the
  entry, and both would otherwise cycle (`kube → children → controller → kube`, and
  `controller → entries → ctx → controller` closing on itself). Valid for the whole
  reconcile including chained Futures; a ctx kept past that keeps nothing alive.
- Watch ERROR events and the watcher's `WatchFailed` reports reach
  `on_watch_error($error, {controller,kube,resource})`, not the workqueue — they carry
  a `Status` hashref with no key to dedup on. An `on_error` passed to
  `watch_resource` takes precedence for that watch.
- `stop` is teardown, not pause: it stops each watch **and detaches it from the
  client** (`remove_from_parent` — `kube->watcher` had `add_child`ed it), clears the
  queue plus the `queued`/`dirty` flags, and drops retry timers. Failure counts stay.
  A restart builds fresh watchers that re-LIST, so a watcher handle kept from
  `watch_resource` is worthless after a `stop`.
- `watch_resource` before the controller is started returns `undef` (spec is stored,
  watcher starts on `start`).

## Duplex transport (port_forward / exec / attach / cp)

- Build normal request with `Connection: Upgrade`, `Upgrade: websocket`,
  `Sec-WebSocket-Protocol` (default `v4.channel.k8s.io`), then `_do_duplex_request`:
  https→wss URL, headers converted to `Protocol::WebSocket::Request` (drops
  connection/upgrade/host/key/version; keeps `Authorization`),
  `_make_websocket_client` (mock override point), `->connect(..., _ssl_options)`,
  resolves with a `PortForwardSession`.
- Channels (first byte of each binary frame): 0 stdin, 1 stdout, 2 stderr, 3
  error/status JSON, 4 TTY resize. `on_frame->($channel,$payload)`; `on_close` fires
  at most once; user callbacks eval-wrapped → `on_error`.
- `port_forward` appends ports manually as `?ports=N&ports=M`; `exec`/`attach` pass
  `command`/flags via `parameters` (arrayref expansion). Defaults: stdin=false,
  stdout=true, stderr=true, tty=false.
- `cp_to_pod`: slurps the local file **fully into memory**, `exec` with
  `sh -c 'head -c "$1" > "$2"'`, uploads via `_send_stdin_chunks` (sequential 64 KiB
  Future chain). `cp_from_pod`: `cat $remote`, accumulates ch1 in memory. Failure
  detection = regex `/"status"\s*:\s*"Failure"/i` on the ch3 payload. Requires
  `sh`+`head` / `cat` in the container. **Not tar** — `Changes` 0.006/0.007 wording
  is stale.
- All duplex/cp paths require the client to already be in a loop; `_do_duplex_request`
  names the calling method via its `caller =>` argument, the cp helpers check the loop
  themselves.

## TLS / auth

- Config resolution: explicit `server`/`credentials` win; else
  `Kubernetes::REST::Kubeconfig` (explicit `kubeconfig` or `context` → croaks at
  construct with the reason, e.g. `Context not found: x`; auto-detection without
  either → silent eval, errors surface later as croaking accessors); else in-cluster
  SA token (`Kubeconfig->api` falls back to it when no kubeconfig file exists, even
  with a context).
- `_ssl_options` computed **once and cached**, splatted flat into every request and
  connect: `SSL_verify_mode` from `ssl_verify_server`, `SSL_{ca,cert,key}_file`
  pass-through; inline `ssl_*_pem` from kubeconfig is materialized to `File::Temp`
  files (handles retained in `{_ssl_tempfiles}` for the client's lifetime, so paths
  stay valid); `*_pem` wins over same-kind `*_file`. No SNI/`SSL_hostname` is set.
- https/wss need `IO::Async::SSL`, which Net::Async::HTTP / WebSocket only recommend;
  the cpanfile requires it.

## Test harness — dual-mode

`t/lib/MockTransport.pm` (functions, module-level state) + `t/lib/TestKube.pm`
(`is_live`, `make_kube`, `loop`). `is_live()` = `TEST_KUBERNETES_REST_KUBECONFIG` set.
`make_kube()` returns a mocked client (`https://mock.local`, `MockTransport::install`)
or a live one from the kubeconfig; both added to the process-wide memoized `loop()`.

- `MockTransport::install($kube)` monkeypatches **the class** `ref($kube)`
  (`_do_request`, `_do_streaming_request`, `_do_duplex_request`, `_add_to_loop` →
  no-op). Irreversible per process — never mix a real client into a file that calls
  `install`. A test subclass of the client gets its own patched copy.
- Registration: `reset()` first; `mock_response($method,$path,$data,$status,\%opts)` —
  key is `"METHOD path"` **including the query string** (sorted asciibetical by key,
  as `prepare_request` builds it); `{delay => 1}` resolves one tick later, which makes
  wrongly-parallel orchestration visible in `request_log`. `mock_response_queue(
  $method,$path,[$data,$status],...)` answers one entry per request (FIFO), then falls
  back to `mock_response`/404 — for 409 races and retries. Unregistered → 404 Status.
  `mock_watch_events($path,\@events,\%opts)` (`complete` ⇒ resolve → reconnect;
  `fail` ⇒ backoff retry; `status` ⇒ response code; no opts ⇒ pending until `stop`);
  `mock_stream_chunks` for `log()`; `mock_duplex_session`. A `status` ≥ 400 on either
  is a rejection, as on the real transport: nothing reaches the chunk callback, the
  request resolves (no `complete` needed) with a Status error body. Streaming/duplex paths are
  matched **without** query string. Inspect via `last_request()`/`request_log()`.
- Discovery in mock mode (`t/32-mock-unstructured.t`): a client subclass overrides
  `rest` to build the `Kubernetes::REST` with an `io` (consumes
  `Kubernetes::REST::Role::IO`; needs `call` and `call_streaming`) that answers
  `GET /api` / `GET /apis` with an `APIGroupDiscoveryList`. Resource requests still go
  through the mocked `_do_request`; assert the io saw only discovery.
- The mocked `_do_duplex_request` never invokes callbacks — exec/attach/cp behavior is
  tested by `local *Net::Async::Kubernetes::exec` / `_make_websocket_client`
  monkeypatching instead (see `t/13-duplex-transport.t`, `t/16-mock-cp.t`).
- Dual-mode test skeleton: `use lib 't/lib'; use TestKube qw(is_live make_kube loop);`
  `require MockTransport unless is_live()`; wrap mock registrations in
  `unless (is_live()) {…}` and live-only setup in `if (is_live()) {…}`; always use
  `loop()` (never a fresh loop); arm a `loop()->watch_time` watchdog next to every
  async assertion; `ok($ok || is_live(), …)` where live timing is unreliable.
- Mode map: `10-dual-*`/`11-dual-*` = dual (TestKube); `01-crud.t`/`02-watcher.t` =
  live-only (`skip_all` without kubeconfig); everything else mock-only, no cluster.
  Note: `12-` is used twice (`12-controller.t`, `12-mock-port-forward.t`).
- A call that may still die synchronously goes through `eval` in the test
  (`my $r = eval { $kube->x(...)->get }; is($@, '', ...)`) — an uncaught die ends the
  whole file, not just the subtest.
- Run: `prove -l t/` (mock) · `TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config
  prove -lv t/` (live, minikube only — mutates the cluster).

### Against the pinned Kubernetes::REST / IO::K8s (k66)

`maint/prove-pinned.sh [--lib DIR] [--setup] [--setup-only] [-- PROVE_ARGS]` reads
both minimum versions from the `cpanfile`, installs exactly those plus the rest of
the cpanfile (test phase included, `--notest`) into a self-contained `cpanm -L`
local::lib — default `${TMPDIR:-/tmp}/nak-pinned-REST-<pin>-IOK8s-<pin>`, reused
while the cpanfile is unchanged (`--setup` reruns cpanm) — and runs prove (default
`-lr t/`; one file: `-- -l t/42-mock-discover.t`) with `PERL5LIB`, `PERLLIB`,
`PERL5OPT`, `PERL_LOCAL_LIB_ROOT`, `PERL_MB_OPT`, `PERL_MM_OPT`, `PERL_CPANM_OPT`,
`HARNESS_PERL_SWITCHES` and `TEST_KUBERNETES_REST_KUBECONFIG` unset. First it prints
the loaded versions and paths and stops on a version other than the pin, a module
loaded from outside DIR, or a copy of either dist in another `@INC` dir. Never an
`-I` overlay of an older `lib/` instead: it still finds what that release lacks in
`~/perl5` (1.109's `Kubernetes/REST/APIError.pm` next to 1.108's `REST.pm` — t/39
then expects an APIError object from a `check_response` that throws a string). A
sibling working tree is checked with `prove -l -I/home/getty/dev/kubernetes-rest/lib`
(read only). cpanm needs the network on first setup.

## Invariants & traps

- `list()` returns `IO::K8s::List` — always `->items`.
- Never `->get` a Future inside a callback (watcher/reconcile/on_frame) — deadlock.
- Retention: Watcher and Controller both weaken `kube` (a client the Controller built
  itself is held strongly — it owns it). A GC'd client ⇒ its watches die silently.
- `watcher()`/`controller()` already `add_child` — never `$loop->add` the child again.
  A watcher created before the client is in a loop starts when the client is added.
- No URI escaping anywhere in path or parameters — special chars in names, label
  selectors, and exec commands go out raw.
- `sub delete`/`exec`/`log` shadow builtins in the client package (and `close` in
  PortForwardSession) — fine as methods, but bareword calls inside those packages hit
  CORE.
- cpanfile pins: `Kubernetes::REST >= 1.109`, `IO::K8s >= 1.108`, `IO::Async >= 0.80`,
  `IO::Async::SSL >= 0.12`, `Net::Async::HTTP >= 0.49`,
  `Net::Async::WebSocket::Client >= 0.14`, `Future >= 0.47`, perl 5.020. Both K8s deps
  are Getty dists — pin released CPAN versions only (skill `getty-perl-core`).
- The locally installed Kubernetes::REST / IO::K8s is often ahead of the pin. Check
  behaviour that matters against the pinned releases with `maint/prove-pinned.sh`
  (see the test harness section), not with a `-I` overlay of an older `lib/`.
- A single-segment class (`'+Gizmo'` → `Gizmo`) handed to Kubernetes::REST's
  `inflate_object`/`inflate_list`/`process_watch_chunk` as it is could be read as a
  Kind (REST before 1.109 did: dropped list items, inflated as whatever the map's
  short key `Gizmo` names, `ensure_only` pruned in that group). Every inflate call
  site, the Watcher's `process_watch_chunk` included, passes `_exact_class($class)`
  (`'+Class'` for a loaded class doing `IO::K8s::Role::Resource`, the rule of REST's
  private helper). A new inflate call site must do the same.
- POD style is inline `=method`/`=attr` next to the sub (`Kubernetes.pm`,
  `Watcher.pm`); `Controller.pm` keeps its POD in `__END__` — match per-file.
