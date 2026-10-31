---
name: perl-net-async-kubernetes
description: Use when calling Net::Async::Kubernetes from another project — kubeconfig or in-cluster setup, list/get/patch Futures, API errors, watcher reconnects, controller workqueue.
---

# Net::Async::Kubernetes — calling it

IO::Async Kubernetes client: an `IO::Async::Notifier` whose CRUD methods return Futures that
resolve to typed `IO::K8s` objects. Request and object semantics are `perl-kubernetes-rest`
and `perl-io-k8s-kubernetes-classes`; Future lifetime in general is `perl-io-async-future`.
Changing the dist itself: `nak-core`, `nak-hazards`, `nak-runtime`, `nak-testing`.

## Connect

```perl
my $loop = IO::Async::Loop->new;
my $kube = Net::Async::Kubernetes->new(kubeconfig => $path, context => 'prod'); # context optional
# or: Net::Async::Kubernetes->new;              # in-cluster, or the default kubeconfig
$loop->add($kube);                               # the loop keeps the client alive
```

- Order: explicit `server`+`credentials` (hashrefs ok), then `kubeconfig`/`context`, then with no
  arguments the default kubeconfig (`KUBECONFIG`, `~/.kube/config`), then the pod's service-account
  token (`KUBERNETES_SERVICE_HOST/PORT`, `ca.crt`). A mounted kubeconfig therefore wins over in-cluster.
- A `kubeconfig`/`context` that cannot resolve croaks in `new`. With no arguments a failed
  detection is silent: `new` succeeds and the first request croaks `server or kubeconfig required`
  synchronously. Make the first call `Future->call(sub { $kube->list(...) })` to get a failed Future.
- `kubeconfig` is a path, never the YAML text (a document croaks `Kubeconfig not found`). A document
  in memory goes to a temp file. The file is read once in `new`; inline certs and tokens live on in
  memory, so it may go afterwards, but files it points at must stay.
- `resource_map` replaces the default map: spread it, `{ %{IO::K8s->default_resource_map},
  OCPNode => '+OCP::K8s::OCPNode' }`, or give CRD bundles as `with => ['IO::K8s::GatewayAPI']`.
  With `resource_map_from_cluster => 1`, run `$kube->discover->get` once at start-up; otherwise the
  first use blocks the loop. Names may be qualified: `'autoscaling/v1/HorizontalPodAutoscaler'`.
- Requests carry no timeout; bound one with
  `Future->wait_any($f, $loop->delay_future(after => 30)->then_fail('no answer in 30s'))` (the loser is cancelled).

## CRUD

Name positional or keyed: `get('Pod', 'web', namespace => 'ns')` = `get('Pod', name => 'web', ...)`.

| call | resolves to |
|---|---|
| `list($kind, namespace, labelSelector, fieldSelector, limit, continue, resourceVersion)` | `IO::K8s::List`: `->items` (arrayref), `->metadata->resourceVersion / continue` |
| `get`, `create($obj)`, `update($obj)`, `patch`, `patch_status`, `update_status`, `ensure($obj_or_manifest)` | the inflated object |
| `delete($kind, $name, ...)` or `delete($obj)` | `1` (`propagationPolicy => 'Background'` for Job-like owners) |

- `patch` defaults to `strategic`; custom resources answer 415 to it, so pass `type => 'merge'`.
  A CRD with a status subresource drops `status` from `patch`/`update` and still answers 2xx: write
  it with `patch_status('OCPNode', $name, namespace => $ns, patch => { status => {...} })` (merge default).
- `ensure` is create-or-update (GET, then POST or PUT at the server's resourceVersion, one retry on 409).
- A mistyped option fails the Future before any request, naming the allowed ones.

## Errors

A status of 400 and up fails the Future as `->fail($error, 'http', $response)`; `$error` is a
`Kubernetes::REST::APIError` (`code reason message body`, stringifies to the text) and
`$response->status` separates 404 from 409. Transport failures (refused, TLS) fail with the
transport's plain message and no category.

```perl
$kube->get('OCPNode', $name, namespace => $ns)->catch(http => sub {
    my ($err, undef, $res) = @_;
    return Future->done(undef) if $res->status == 404;   # absent
    return Future->fail(@_);                              # 409, 403, 5xx
})->then(sub { my ($node) = @_; ... });
```

On 409 re-`get` and retry, or use `patch`/`ensure`, which need no resourceVersion from you.
Bad input that is known before a request fails the Future, except in `update`, `update_status`,
`ensure`, `expand_class` and `watcher`, which croak synchronously: wrap those in `Future->call`.

## Futures

- Outside a running loop (scripts, CLIs) `->get` blocks until done. In code the loop calls
  (callbacks, reconciles) chain with `->then`/`await`: a `->get` there runs the loop re-entrantly
  from inside a callback.
- Keep every Future you care about: store it, return it, or `->retain` a fire-and-forget call.
  Mock responses resolve at once, so a dropped Future passes offline tests and hangs live.

## Watcher

```perl
my $w = $kube->watcher('OCPNode', namespace => $ns, timeout => 300,
    on_added    => sub { my ($obj) = @_; ... },
    on_modified => sub { my ($obj) = @_; ... },
    on_deleted  => sub { my ($obj) = @_; ... },
    on_error    => sub { my ($status) = @_; warn $status->{message} },
);   # starts with the loop; $w->stop / $w->start
```

- Callbacks get the inflated object (`on_event` gets the `WatchEvent`, `names => qr/../`,
  `label_selector`, `field_selector` filter). Only event types with a callback are delivered:
  `on_added` alone drops MODIFIED and DELETED. BOOKMARK events never reach a callback.
- A fresh watch starts without a resourceVersion, so the server first sends every existing object as
  ADDED. The server-side `timeout` ends a cycle and the watcher reconnects at once from the last
  resourceVersion (no repeats). On **410 Gone** (event or HTTP status; never reaches `on_error`) it
  drops the version and replays: every live object arrives as ADDED again, and deletions during the
  gap arrive never. Reconcile idempotently, treat ADDED as "exists", and `list` periodically to catch what was missed.
- A failed attempt (refused, 401/403/5xx, stream closed within `min_watch_duration` 1s or after an
  ERROR event) is retried with backoff 1s doubling to 30s (`reconnect_delay`, `max_reconnect_delay`,
  `reconnect_jitter`) and reported to `on_error` as a Status hashref (`reason` `WatchFailed`, `code`,
  `message`, `details.retryAfterSeconds`); without `on_error` it is `warn`ed. It retries forever unless `max_retries`
  is set, so a dead watch looks like a quiet process: pair it with a periodic `list` health check.
  Mid-stream `ERROR` events (403) arrive on `on_error` as the raw Status.
- Callbacks run unguarded: a `die` escapes `$loop->run`. Catch inside, hand real work to a queue.
- An unresolvable kind croaks from `watcher()` (once the client is in a loop), so register CRDs first.

## Controller

A workqueue instead of a hand-rolled reconcile loop; it owns the watchers.

```perl
my $ctl = $kube->controller(
    retry_delay  => [1, 5, 30],                       # scalar | arrayref by attempt | sub($attempt,$ctx,$err)
    on_reconcile => sub {
        my ($ctx) = @_;   # {controller kube resource event_type object key attempt}
        return $ctx->{controller}->patch_status($ctx->{object}, status => { phase => 'Ready' });
    },
    on_watch_error => sub { my ($status, $ctx) = @_; warn $status->{message} },
);
$ctl->watch_resource('OCPNode', namespace => $ns);       # key_for => sub($obj,$spec) to coalesce kinds
```

- The reconcile returns a Future (or a plain value = done). A failed Future or `die` retries per
  `retry_delay` (default 1s) without a cap; `$ctx->{attempt}` counts up.
- Events for one key coalesce (the latest wins); the default key is `Kind:ns/name`. Reconciles run
  one at a time across all keys, so a slow one delays everything: keep it async.
- DELETED arrives as a reconcile with `event_type` DELETED and the last known object.
- `stop` is teardown: queue and watchers go, a restart re-lists everything. The controller holds
  the client weakly: keep `$kube` (the loop does once added).
- `$ctl->get_object`/`list_objects` wrap the client. `$ctl->patch_status($obj, status => {...})` (merge
  default) and `$ctl->update_status($obj)` report every error as a failed Future, never a croak.

## Duplex

`port_forward`, `port_forward_listen` (local TCP like `kubectl port-forward`, resolves to a listener
with `port_for($remote)` and `stop`), `exec`, `attach`, `cp_to_pod`, `cp_from_pod` use websockets and
return sessions (`write_port`, `write_stdin`, `resize`, `close`). `on_data($session,$port,$bytes)`
and `on_frame($channel,$payload)` run unguarded inside the loop. Options are in the POD of each method.

## Testing without a cluster

No mock transport ships with the installed dist (`t/lib/MockTransport.pm` is test code). Stand
in a fake with the same method names, as a `IO::Async::Notifier` subclass if you `$loop->add` it:
`list` returns `Future->done($list_obj)`, `watcher` returns a notifier that fires your callbacks, and
`Future->fail($err, http => $res)` stages a 404. Put the fake behind your own seam (an attribute
holding the client), so the code under test never builds a real one.
