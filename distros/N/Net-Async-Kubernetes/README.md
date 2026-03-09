# Net::Async::Kubernetes

Async Kubernetes client for Perl built on [IO::Async](https://metacpan.org/pod/IO::Async).

All API calls return [Future](https://metacpan.org/pod/Future) objects for non-blocking operation. Includes a [Watcher](https://metacpan.org/pod/Net::Async::Kubernetes::Watcher) with auto-reconnect for streaming resource events.

## Features

- **Future-based CRUD + logs**: `list()`, `get()`, `create()`, `update()`, `patch()`, `delete()`, `log()`
- **Port-forward API**: `port_forward()` with built-in WebSocket duplex transport
- **Exec API**: `exec()` with built-in WebSocket duplex transport
- **Streaming watch** with auto-reconnect and resumable `resourceVersion` tracking
- **Event callbacks**: `on_added`, `on_modified`, `on_deleted`, `on_error`, `on_event`
- **Client-side filtering**: `names` (regex/string/array) and `event_types` for declarative event filtering
- **Smart event dispatch**: only processes event types that have registered callbacks
- **Automatic 410 Gone recovery**: clears resourceVersion and restarts
- **Auto-reconnect** on stream completion and connection errors
- **Three patch types**: strategic-merge (default), merge, json
- **Custom Resource Definition (CRD) support** via `resource_map`
- **Kubeconfig support** (`~/.kube/config`) with context selection
- **In-cluster authentication**: auto-detects service account token when running inside a Kubernetes pod
- **SSL/TLS** with client certificates
- Built on [Kubernetes::REST](https://metacpan.org/pod/Kubernetes::REST) and [IO::K8s](https://metacpan.org/pod/IO::K8s)

## Installation

    cpanm Net::Async::Kubernetes

## Synopsis

```perl
use IO::Async::Loop;
use Net::Async::Kubernetes;

my $loop = IO::Async::Loop->new;

# From kubeconfig (easiest)
my $kube = Net::Async::Kubernetes->new(
    kubeconfig => "$ENV{HOME}/.kube/config",
);
$loop->add($kube);

# In-cluster: auto-detects service account token (no config needed)
my $kube = Net::Async::Kubernetes->new;
$loop->add($kube);

# Or with explicit server/credentials
my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://kubernetes.local:6443' },
    credentials => { token => $token },
);
$loop->add($kube);

# List pods
my $pods = $kube->list('Pod', namespace => 'default')->get;

# Get a specific pod
my $pod = $kube->get('Pod', 'nginx', namespace => 'default')->get;

# Create a resource
my $cm = $kube->_rest->new_object(ConfigMap =>
    metadata => { name => 'my-config', namespace => 'default' },
    data     => { key => 'value' },
);
my $created = $kube->create($cm)->get;

# Patch a resource
my $patched = $kube->patch('Deployment', 'web',
    namespace => 'default',
    patch     => { spec => { replicas => 3 } },
    type      => 'merge',
)->get;

# Delete a resource
$kube->delete('Pod', 'nginx', namespace => 'default')->get;

# One-shot pod logs
my $text = $kube->log('Pod', 'nginx',
    namespace => 'default',
    tailLines => 100,
)->get;

# Stream pod logs (like kubectl logs -f)
$kube->log('Pod', 'nginx',
    namespace => 'default',
    follow    => 1,
    on_line   => sub { my ($event) = @_; say $event->line },
)->get;

# Port-forward (built-in websocket duplex support)
my $pf = $kube->port_forward('Pod', 'nginx',
    namespace => 'default',
    ports     => [8080],
    on_frame  => sub {
        my ($channel, $payload) = @_;
        ...
    },
)->get;

$pf->write_channel(0, "GET / HTTP/1.1\r\n\r\n");
$pf->close(code => 1000);

# Exec (built-in websocket duplex support)
my $exec = $kube->exec('Pod', 'nginx',
    namespace => 'default',
    command   => ['sh', '-c', 'id'],
    on_frame  => sub {
        my ($channel, $payload) = @_;
        ...
    },
)->get;

# Watch for changes with auto-reconnect
my $watcher = $kube->watcher('Pod',
    namespace      => 'default',
    label_selector => 'app=web',
    on_added    => sub { my ($pod) = @_; say "Added: " . $pod->metadata->name },
    on_modified => sub { my ($pod) = @_; say "Modified: " . $pod->metadata->name },
    on_deleted  => sub { my ($pod) = @_; say "Deleted: " . $pod->metadata->name },
);

$loop->run;

# Filter events client-side
my $watcher = $kube->watcher('Pod',
    namespace   => 'default',
    names       => [qr/^nginx/, qr/^redis/],  # only matching names
    event_types => ['ADDED', 'DELETED'],        # skip MODIFIED
    on_added    => sub { my ($pod) = @_; say "New: " . $pod->metadata->name },
    on_deleted  => sub { my ($pod) = @_; say "Gone: " . $pod->metadata->name },
);

# Or just set the callbacks you care about - event types auto-derive
my $watcher = $kube->watcher('Pod',
    namespace => 'default',
    on_added  => sub { ... },  # only ADDED events dispatched
);
```

## Testing

```bash
# Run mock tests (no cluster needed)
prove -l t/

# Run against a real cluster (e.g. minikube)
TEST_KUBERNETES_REST_KUBECONFIG=~/.kube/config prove -lv t/
```

## Documentation

Full documentation is available on [MetaCPAN](https://metacpan.org/pod/Net::Async::Kubernetes).

## See Also

- [Kubernetes::REST](https://metacpan.org/pod/Kubernetes::REST) - Synchronous Kubernetes REST client
- [IO::K8s](https://metacpan.org/pod/IO::K8s) - Kubernetes API objects for Perl
- [IO::Async](https://metacpan.org/pod/IO::Async) - Async framework
- [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP) - HTTP client used for transport

## Author

Torsten Raudssus <torsten@raudssus.de>

## License

This is free software licensed under the Apache License 2.0.
