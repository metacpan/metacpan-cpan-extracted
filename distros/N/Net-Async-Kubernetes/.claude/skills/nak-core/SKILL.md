---
name: nak-core
description: Load before editing Net::Async::Kubernetes — the Kubernetes::REST seam, Watcher and Controller mechanics, websocket duplex transport, the dual-mode test harness.
---

# Net::Async::Kubernetes — Core Architecture

Async Kubernetes client on IO::Async. `Kubernetes::REST` is used **purely** as
request-builder/response-inflater (its own `io` backend is never invoked); `IO::K8s`
provides the typed objects. `$VERSION` is hand-written in every module; dzil bumps it.

## Classes

- **`Net::Async::Kubernetes`** (`lib/.../Kubernetes.pm`) — IO::Async::Notifier. Config:
  `kubeconfig`, `context`, `server`, `credentials`, `resource_map`,
  `resource_map_from_cluster`. Public API (all returning Futures unless noted):
  `list` → `IO::K8s::List` (use `->items`!), `get`/`create`/`update`/`patch` →
  inflated object, `delete` → `1`, `log` → full text or `undef` with `on_line`,
  `port_forward`/`exec`/`attach` → session, `cp_to_pod`/`cp_from_pod` →
  `{local,remote,bytes,stderr,status}`. Non-Future: `expand_class`, `watcher(...)`,
  `controller(...)` (both `add_child` the returned notifier).
- **`Net::Async::Kubernetes::PortForwardSession`** (`lib/.../PortForwardSession.pm`) —
  own file since 0.008, `use`d from `Kubernetes.pm`. Blessed hashref around `ws_client`:
  `write_channel($ch,$payload)`, `write_stdin`, `resize(width=>,height=>)` (channel 4
  JSON), `close($code?,$payload?)`; aliases `write`/`stdin`.
- **`Net::Async::Kubernetes::Watcher`** — Notifier; auto-reconnecting watch stream.
  Config: `kube` (**weak ref**), `resource`, `namespace`, `timeout` (300),
  `label_selector`, `field_selector`, `names`, `event_types`,
  `on_added/on_modified/on_deleted/on_error/on_event`. `start` idempotent; `stop`.
- **`Net::Async::Kubernetes::Controller`** — Notifier; minimal controller runtime.
  Config: `kube` (**weak ref**) OR client-construction keys (builds its own client,
  held strongly — it owns that one), `on_reconcile` (required), `on_watch_error`,
  `retry_delay` (scalar|arrayref|coderef, default 1). API:
  `watch_resource($resource, %watcher_args, key_for=>sub)`, `start`/`stop`,
  `get_object`/`list_objects` (thin `$kube->` wrappers), `patch_status` (PATCH
  `.../status`, default type `merge`), `update_status` (PUT `$object->TO_JSON`).

## Request pipeline — the Kubernetes::REST seam

One lazy `Kubernetes::REST` in `_rest`; one shared `Net::Async::HTTP` in `_http`
(`max_connections_per_host => 0` so watch streams don't starve CRUD — never add a
second UA). Uniform CRUD shape:

```
$rest->build_path($class, name=>, namespace=>)
  → $rest->prepare_request(METHOD, $path, body=>, parameters=>, headers=>)
  → $self->_do_request($req)
  → ->then { $rest->check_response($res, "op class"); $rest->inflate_object/inflate_list }
```

Use only the public building blocks: `expand_class`, `build_path`, `prepare_request`,
`check_response` (croaks on status ≥ 400 — inside `->then` that becomes a failed
Future), `inflate_object`, `inflate_list`, `process_watch_chunk`, `process_log_chunk`.
Never reach for `_`-prefixed Kubernetes::REST internals.

`expand_class` **fails closed**: a qualified `"group/version/Kind"` that is not in the
resource map returns `undef` (a bare unknown `Kind` still falls back to `IO::K8s::$Kind`).
Every call site guards it — `Future->fail("unknown resource …")` where the contract is a
Future, `croak` on the two synchronous paths (`$kube->expand_class`, starting a watcher).
Unguarded, that `undef` reaches `build_path` and dies with "argument is not a module name".

`_do_request` wraps the HTTP::Response back into `Kubernetes::REST::HTTPResponse` —
that re-wrap is the seam mocks and live transport share. `_do_streaming_request` is
the same with an `on_header`-installed chunk callback (GET-only, resolved response has
empty content). Override points the test harness replaces: `_do_request`,
`_do_streaming_request`, `_do_duplex_request`, `_add_to_loop`,
`_make_websocket_client`.

## Watcher mechanics

- Params per cycle: `watch=true`, `timeoutSeconds`, tracked `resourceVersion`,
  selectors. `resourceVersion` updated from every processed chunk result.
- **410 Gone**: clears `resourceVersion`, drops remaining events in that chunk, is NOT
  delivered to `on_error`; stream ends naturally and reconnects without a version.
- Reconnect: clean end → immediate restart; failure → fixed 1 s retry, forever. No
  backoff, no `allowWatchBookmarks`, no informer cache.
- Dispatch order: type filter (explicit `event_types`, else derived from which
  callbacks are set; `on_event` = catch-all), name filter (skipped for ERROR), then
  `on_event($event)` and one of `on_added/on_modified/on_deleted($object)`;
  `on_error` gets the **raw hashref** for ERROR events. Callbacks are not eval-guarded.
- `stop` defers `$f->cancel` via `$loop->later` — cancelling inside the connection's
  own `on_read` triggers Net::Async::HTTP's "Spurious on_read of connection while
  idle". Any new cancel path must defer the same way.

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
- Watch ERROR events reach `on_watch_error($error, {controller,kube,resource})`, not
  the workqueue — they carry a raw `Status` hashref with no key to dedup on. An
  `on_error` passed to `watch_resource` takes precedence for that watch.
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
- All duplex/cp paths require the client to already be in a loop; the failure message
  hardcodes "port_forward" regardless of caller (known defect).

## TLS / auth

- Config resolution: explicit `server`/`credentials` win; else
  `Kubernetes::REST::Kubeconfig` (explicit `kubeconfig` → croaks at construct on bad
  file; auto-detection → silent eval, errors surface later as croaking accessors);
  else in-cluster SA token.
- `_ssl_options` computed **once and cached**, splatted flat into every request and
  connect: `SSL_verify_mode` from `ssl_verify_server`, `SSL_{ca,cert,key}_file`
  pass-through; inline `ssl_*_pem` from kubeconfig is materialized to `File::Temp`
  files (handles retained in `{_ssl_tempfiles}` for the client's lifetime, so paths
  stay valid); `*_pem` wins over same-kind `*_file`. No SNI/`SSL_hostname` is set.

## Test harness — dual-mode

`t/lib/MockTransport.pm` (functions, module-level state) + `t/lib/TestKube.pm`
(`is_live`, `make_kube`, `loop`). `is_live()` = `TEST_KUBERNETES_REST_KUBECONFIG` set.
`make_kube()` returns a mocked client (`https://mock.local`, `MockTransport::install`)
or a live one from the kubeconfig; both added to the process-wide memoized `loop()`.

- `MockTransport::install($kube)` monkeypatches **the class** (`_do_request`,
  `_do_streaming_request`, `_do_duplex_request`, `_add_to_loop` → no-op). Irreversible
  per process — never mix a real client into a file that calls `install`.
- Registration: `reset()` first; `mock_response($method,$path,$data,$status)` — key is
  `"METHOD path"` **including the query string** (sorted asciibetical by key, as
  `prepare_request` builds it); `mock_watch_events($path,\@events,\%opts)` (`complete`
  ⇒ resolve → reconnect; `fail` ⇒ 1 s retry; no opts ⇒ pending until `stop`);
  `mock_stream_chunks` for `log()`; `mock_duplex_session`. Streaming/duplex paths are
  matched **without** query string. Inspect via `last_request()`/`request_log()`.
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
- Run: `prove -l t/` (mock) · `TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config
  prove -lv t/` (live, minikube only — mutates the cluster).

## Invariants & traps

- `list()` returns `IO::K8s::List` — always `->items`. (POD claiming ArrayRef is a
  known defect.)
- Error style is mixed: most argument validation returns a synchronously failed
  Future, but `update()` **croaks** on missing metadata/name; `check_response` croaks
  inside `->then` (becomes failed Future).
- Never `->get` a Future inside a callback (watcher/reconcile/on_frame) — deadlock.
- Retention: Watcher weakens `kube` (never keeps the client alive — GC'd client ⇒
  watch dies silently). Controller does **not** weaken and is `add_child`ed by the
  client ⇒ reference cycle; remove explicitly when done.
- `watcher()`/`controller()` already `add_child` — never `$loop->add` the child again.
  A watcher created before the client is in a loop starts when the client is added.
- No URI escaping anywhere in path or parameters — special chars in names, label
  selectors, and exec commands go out raw.
- `sub delete`/`exec`/`log` shadow builtins in the client package (and `close` in
  PortForwardSession) — fine as methods, but bareword calls inside those packages hit
  CORE.
- cpanfile pins: `Kubernetes::REST >= 1.106`, `IO::K8s >= 1.105`, `IO::Async >= 0.80`,
  `Net::Async::HTTP >= 0.49`, `Net::Async::WebSocket::Client >= 0.14`, perl 5.020.
  Both K8s deps are Getty dists — pin released CPAN versions only (skill `getty-perl-core`).
- POD style is inline `=method`/`=attr` next to the sub (`Kubernetes.pm`,
  `Watcher.pm`); `Controller.pm` keeps its POD in `__END__` — match per-file.
