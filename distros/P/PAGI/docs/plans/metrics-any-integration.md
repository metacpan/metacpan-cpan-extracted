# Plan: Metrics::Any Integration for PAGI

**Status:** Draft - Pending Community Feedback
**Author:** Claude + jnapiorkowski
**Date:** 2025-12-27
**Branch:** `feature/metrics-any` (not yet created)

---

## Executive Summary

Add optional Metrics::Any instrumentation to PAGI, focused on metrics that nginx/reverse proxies **cannot** provide. This is a minimal, pragmatic approach that avoids duplicating what production infrastructure already offers.

### Scope

| Component | Include? | Rationale |
|-----------|:--------:|-----------|
| PAGI::Server core instrumentation | ✅ | WebSocket/SSE stats, worker health |
| PAGI::App::Metrics endpoint | ✅ | Simple `/metrics` exposure |
| PAGI::Middleware::Metrics | ❌ | HTTP metrics covered by nginx |
| PAGI::Cookbook documentation | ✅ | Teach custom app metrics |

### Value Proposition

**What nginx gives you:** HTTP request counts, latency, status codes, bytes, connections

**What only PAGI can give you:**
- WebSocket message counts (sent/received)
- SSE event counts
- Lifespan startup/shutdown timing
- Worker spawn/respawn counts
- Internal connection states
- Custom application metrics (via Metrics::Any in user code)

---

## Technical Decisions

### 1. Dependency Strategy: Optional

Metrics::Any is **optional**. PAGI::Server starts and runs without it.

```perl
# Pattern: graceful degradation
our $METRICS_AVAILABLE;
our $metrics;

BEGIN {
    $METRICS_AVAILABLE = eval {
        require Metrics::Any;
        Metrics::Any->import('$metrics', name_prefix => ['pagi', 'server']);
        1;
    };
    unless ($METRICS_AVAILABLE) {
        $metrics = PAGI::Server::NullMetrics->new;
    }
}
```

### 2. Performance Strategy: Batch Mode

High-frequency metrics use batch mode (~18ns overhead vs ~1µs):

```perl
my $ws_messages_received = 0;
my $ws_messages_sent = 0;

$metrics->add_batch_mode_callback(sub {
    $metrics->inc_counter_by('websocket_messages_received', $ws_messages_received);
    $metrics->inc_counter_by('websocket_messages_sent', $ws_messages_sent);
    $ws_messages_received = $ws_messages_sent = 0;
});

# In hot path - just increment local var
sub on_ws_message { $ws_messages_received++; ... }
```

### 3. Multi-Worker Strategy: Document Limitation

**For v1:**
- Pull model (`/metrics` endpoint) works with single worker only
- Push model (StatsD adapter) works with any worker count
- Document: "For multi-worker Prometheus, use StatsD as intermediary or run single-worker behind load balancer"

**Future consideration:** Shared mmap files like Gunicorn (not in v1)

### 4. Naming Convention

```
pagi_server_*     - Server-level metrics (connections, workers)
pagi_websocket_*  - WebSocket-specific metrics
pagi_sse_*        - SSE-specific metrics
```

User app metrics use their own prefix via Metrics::Any.

### 5. Endpoint Exposure: Explicit App

No magic. Users explicitly mount the metrics endpoint:

```perl
use PAGI::App::Metrics;
use PAGI::App::URLMap;

my $app = PAGI::App::URLMap->new(
    '/metrics' => PAGI::App::Metrics->new,
    '/'        => $my_app,
);
```

---

## Metrics Inventory

### Server Core (`lib/PAGI/Server.pm`)

| Metric | Type | Labels | Batch? | Description |
|--------|------|--------|:------:|-------------|
| `pagi_server_connections_total` | counter | - | ✅ | Total connections accepted |
| `pagi_server_connections_active` | gauge | - | ❌ | Current open connections |
| `pagi_server_workers_active` | gauge | - | ❌ | Current worker count (multi-worker) |
| `pagi_server_worker_spawns_total` | counter | - | ✅ | Worker spawn/respawn events |
| `pagi_server_lifespan_startup_seconds` | gauge | - | ❌ | Last lifespan startup duration |
| `pagi_server_lifespan_shutdown_seconds` | gauge | - | ❌ | Last lifespan shutdown duration |

### WebSocket (`lib/PAGI/Server.pm` or `lib/PAGI/WebSocket.pm`)

| Metric | Type | Labels | Batch? | Description |
|--------|------|--------|:------:|-------------|
| `pagi_websocket_connections_total` | counter | - | ✅ | Total WS connections opened |
| `pagi_websocket_connections_active` | gauge | - | ❌ | Current open WS connections |
| `pagi_websocket_messages_received_total` | counter | - | ✅ | Messages received from clients |
| `pagi_websocket_messages_sent_total` | counter | - | ✅ | Messages sent to clients |
| `pagi_websocket_bytes_received_total` | counter | - | ✅ | Bytes received |
| `pagi_websocket_bytes_sent_total` | counter | - | ✅ | Bytes sent |

### SSE (`lib/PAGI/Server.pm` or `lib/PAGI/SSE.pm`)

| Metric | Type | Labels | Batch? | Description |
|--------|------|--------|:------:|-------------|
| `pagi_sse_connections_total` | counter | - | ✅ | Total SSE connections opened |
| `pagi_sse_connections_active` | gauge | - | ❌ | Current open SSE connections |
| `pagi_sse_events_sent_total` | counter | - | ✅ | Events sent to clients |
| `pagi_sse_bytes_sent_total` | counter | - | ✅ | Bytes sent |

---

## Implementation Plan

### Phase 0: Preparation

**Step 0.1: Create feature branch**
```bash
git checkout -b feature/metrics-any
git push -u origin feature/metrics-any
```

**Step 0.2: Verify baseline - run full test suite**
```bash
prove -l t/
RELEASE_TESTING=1 prove -l t/signal-*.t
```

**Step 0.3: Add Metrics::Any as optional dependency**
- Update `dist.ini` with `recommends = Metrics::Any`
- Update `cpanfile` if present
- Commit: "Add Metrics::Any as optional dependency"

**Step 0.4: Create test file skeleton**
```bash
touch t/metrics.t
```

**Step 0.5: Verify tests still pass**
```bash
prove -l t/
```

---

### Phase 1: Null Metrics Stub

**Goal:** Create infrastructure that allows metrics calls without Metrics::Any installed.

**Step 1.1: Create `lib/PAGI/Server/NullMetrics.pm`**
```perl
package PAGI::Server::NullMetrics;
use strict;
use warnings;

sub new { bless {}, shift }
sub make_counter { }
sub make_gauge { }
sub make_distribution { }
sub make_timer { }
sub inc_counter { }
sub inc_counter_by { }
sub set_gauge { }
sub report_distribution { }
sub report_timer { }
sub add_batch_mode_callback { 0 }  # Returns false

1;
```

**Step 1.2: Add conditional loading to `lib/PAGI/Server.pm`**
```perl
# Near top of file, after use statements
our $METRICS_AVAILABLE;
our $metrics;

BEGIN {
    $METRICS_AVAILABLE = eval {
        require Metrics::Any;
        Metrics::Any->import('$metrics', name_prefix => ['pagi', 'server']);
        1;
    };
    unless ($METRICS_AVAILABLE) {
        require PAGI::Server::NullMetrics;
        $metrics = PAGI::Server::NullMetrics->new;
    }
}
```

**Step 1.3: Write tests for NullMetrics**
```perl
# t/metrics.t
use Test2::V0;
use PAGI::Server::NullMetrics;

my $null = PAGI::Server::NullMetrics->new;
ok($null, 'NullMetrics instantiates');
ok(!$null->add_batch_mode_callback(sub {}), 'batch mode returns false');
lives_ok { $null->inc_counter('foo') } 'inc_counter is no-op';
lives_ok { $null->set_gauge('bar', 42) } 'set_gauge is no-op';

done_testing;
```

**Step 1.4: Run tests**
```bash
prove -l t/metrics.t
prove -l t/
```

**Step 1.5: Commit**
```bash
git add lib/PAGI/Server/NullMetrics.pm lib/PAGI/Server.pm t/metrics.t
git commit -m "Add NullMetrics stub for optional Metrics::Any support"
```

---

### Phase 2: Server Core Metrics

**Goal:** Instrument connection and worker lifecycle.

**Step 2.1: Define metrics at server startup**
```perl
# In _configure or listen method
sub _setup_metrics {
    my ($self) = @_;

    $metrics->make_counter('connections_total',
        description => 'Total connections accepted');
    $metrics->make_gauge('connections_active',
        description => 'Current open connections');

    if ($self->{workers}) {
        $metrics->make_gauge('workers_active',
            description => 'Current worker count');
        $metrics->make_counter('worker_spawns_total',
            description => 'Worker spawn events');
    }

    $metrics->make_gauge('lifespan_startup_seconds',
        description => 'Last lifespan startup duration');
    $metrics->make_gauge('lifespan_shutdown_seconds',
        description => 'Last lifespan shutdown duration');
}
```

**Step 2.2: Add batch mode variables for high-frequency counters**
```perl
# Package variables for batch mode
our $batch_connections_total = 0;

# Setup batch callback
if ($METRICS_AVAILABLE && $metrics->add_batch_mode_callback(sub {
    $metrics->inc_counter_by('connections_total', $batch_connections_total);
    $batch_connections_total = 0;
})) {
    # Batch mode active
} else {
    # Direct mode fallback (or null metrics)
}
```

**Step 2.3: Instrument `_on_connection`**
```perl
sub _on_connection {
    my ($self, $stream) = @_;

    $batch_connections_total++;
    $metrics->set_gauge('connections_active', ++$self->{_active_connections});

    # ... existing code ...
}
```

**Step 2.4: Instrument connection close**
```perl
# In connection cleanup
$metrics->set_gauge('connections_active', --$self->{_active_connections});
```

**Step 2.5: Instrument worker spawning (multi-worker)**
```perl
# In _spawn_worker
$metrics->inc_counter('worker_spawns_total');
$metrics->set_gauge('workers_active', scalar keys %{$self->{worker_pids}});

# In worker exit callback
$metrics->set_gauge('workers_active', scalar keys %{$self->{worker_pids}});
```

**Step 2.6: Instrument lifespan timing**
```perl
# In _run_lifespan_startup
my $start = Time::HiRes::time();
# ... existing startup code ...
$metrics->set_gauge('lifespan_startup_seconds', Time::HiRes::time() - $start);

# In _run_lifespan_shutdown
my $start = Time::HiRes::time();
# ... existing shutdown code ...
$metrics->set_gauge('lifespan_shutdown_seconds', Time::HiRes::time() - $start);
```

**Step 2.7: Write tests**
```perl
# t/metrics.t - add tests for server metrics
subtest 'Server metrics with Metrics::Any' => sub {
    plan skip_all => 'Metrics::Any not installed'
        unless eval { require Metrics::Any; 1 };

    use Metrics::Any::Adapter 'Test';
    # ... test that metrics are recorded ...
};
```

**Step 2.8: Run tests**
```bash
prove -l t/metrics.t
prove -l t/
```

**Step 2.9: Commit**
```bash
git add -A
git commit -m "Add server core metrics (connections, workers, lifespan)"
```

---

### Phase 3: WebSocket Metrics

**Goal:** Instrument WebSocket message and connection counts.

**Step 3.1: Add WebSocket metric definitions**
```perl
# In _setup_metrics or WebSocket initialization
$metrics->make_counter('websocket_connections_total');
$metrics->make_gauge('websocket_connections_active');
$metrics->make_counter('websocket_messages_received_total');
$metrics->make_counter('websocket_messages_sent_total');
$metrics->make_counter('websocket_bytes_received_total', units => 'bytes');
$metrics->make_counter('websocket_bytes_sent_total', units => 'bytes');
```

**Step 3.2: Add batch variables**
```perl
our $batch_ws_messages_received = 0;
our $batch_ws_messages_sent = 0;
our $batch_ws_bytes_received = 0;
our $batch_ws_bytes_sent = 0;
```

**Step 3.3: Instrument WebSocket connection open**
```perl
# When WebSocket upgrade completes
$metrics->inc_counter('websocket_connections_total');
$metrics->set_gauge('websocket_connections_active', ++$self->{_active_ws});
```

**Step 3.4: Instrument WebSocket message receive**
```perl
# In WebSocket frame receive handler
$batch_ws_messages_received++;
$batch_ws_bytes_received += length($payload);
```

**Step 3.5: Instrument WebSocket message send**
```perl
# In WebSocket frame send
$batch_ws_messages_sent++;
$batch_ws_bytes_sent += length($payload);
```

**Step 3.6: Instrument WebSocket connection close**
```perl
# When WebSocket closes
$metrics->set_gauge('websocket_connections_active', --$self->{_active_ws});
```

**Step 3.7: Write WebSocket metrics tests**
```perl
# t/metrics.t
subtest 'WebSocket metrics' => sub {
    # Start server, establish WS connection, send messages
    # Verify metrics incremented
};
```

**Step 3.8: Run tests**
```bash
prove -l t/metrics.t t/04-websocket.t
prove -l t/
```

**Step 3.9: Commit**
```bash
git add -A
git commit -m "Add WebSocket metrics (connections, messages, bytes)"
```

---

### Phase 4: SSE Metrics

**Goal:** Instrument SSE event and connection counts.

**Step 4.1: Add SSE metric definitions**
```perl
$metrics->make_counter('sse_connections_total');
$metrics->make_gauge('sse_connections_active');
$metrics->make_counter('sse_events_sent_total');
$metrics->make_counter('sse_bytes_sent_total', units => 'bytes');
```

**Step 4.2: Add batch variables**
```perl
our $batch_sse_events_sent = 0;
our $batch_sse_bytes_sent = 0;
```

**Step 4.3: Instrument SSE connection lifecycle**
```perl
# On SSE connection start
$metrics->inc_counter('sse_connections_total');
$metrics->set_gauge('sse_connections_active', ++$self->{_active_sse});

# On SSE connection close
$metrics->set_gauge('sse_connections_active', --$self->{_active_sse});
```

**Step 4.4: Instrument SSE event send**
```perl
# In SSE send handler
$batch_sse_events_sent++;
$batch_sse_bytes_sent += length($event_data);
```

**Step 4.5: Write SSE metrics tests**
```perl
# t/metrics.t
subtest 'SSE metrics' => sub {
    # Start server, establish SSE connection, receive events
    # Verify metrics incremented
};
```

**Step 4.6: Run tests**
```bash
prove -l t/metrics.t t/05-sse.t
prove -l t/
```

**Step 4.7: Commit**
```bash
git add -A
git commit -m "Add SSE metrics (connections, events, bytes)"
```

---

### Phase 5: Metrics Endpoint App

**Goal:** Create simple app to expose `/metrics` endpoint.

**Step 5.1: Create `lib/PAGI/App/Metrics.pm`**
```perl
package PAGI::App::Metrics;
use strict;
use warnings;
use Future::AsyncAwait;

sub new {
    my ($class, %args) = @_;
    bless {
        path => $args{path} // '/metrics',
    }, $class;
}

async sub app {
    my ($self, $scope, $receive, $send) = @_;

    return unless $scope->{type} eq 'http';

    # Check if Prometheus adapter is active
    my $body;
    eval {
        require Net::Prometheus;
        $body = Net::Prometheus->new->render;
    };

    if ($@) {
        $body = "# Metrics::Any::Adapter::Prometheus not configured\n";
    }

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type', 'text/plain; version=0.0.4; charset=utf-8'],
        ],
    });

    await $send->({
        type => 'http.response.body',
        body => $body,
    });
}

1;
```

**Step 5.2: Write tests**
```perl
# t/metrics.t
subtest 'Metrics endpoint app' => sub {
    use PAGI::App::Metrics;
    use PAGI::Test::Client;

    my $app = PAGI::App::Metrics->new;
    my $client = PAGI::Test::Client->new(app => $app);

    my $res = $client->get('/metrics');
    is($res->code, 200, 'metrics endpoint returns 200');
    like($res->content_type, qr{text/plain}, 'correct content type');
};
```

**Step 5.3: Run tests**
```bash
prove -l t/metrics.t
prove -l t/
```

**Step 5.4: Commit**
```bash
git add lib/PAGI/App/Metrics.pm t/metrics.t
git commit -m "Add PAGI::App::Metrics endpoint for Prometheus scraping"
```

**Step 5.5: Add integration example**
```perl
# examples/metrics/app.pl
use Metrics::Any::Adapter 'Prometheus';
use PAGI::App::URLMap;
use PAGI::App::Metrics;

my $main_app = async sub {
    my ($scope, $receive, $send) = @_;
    # ... your app ...
};

my $app = PAGI::App::URLMap->new(
    '/metrics' => PAGI::App::Metrics->new,
    '/'        => $main_app,
);
```

**Step 5.6: Commit**
```bash
git add examples/metrics/
git commit -m "Add metrics example app"
```

---

### Phase 6: Documentation

**Goal:** Document metrics usage in cookbook.

**Step 6.1: Create cookbook entry**

Create `lib/PAGI/Cookbook.pod` section or separate file:

```pod
=head1 METRICS AND OBSERVABILITY

PAGI::Server includes optional integration with L<Metrics::Any> to expose
server-level metrics for monitoring.

B<Note:> This only works with PAGI::Server. Other PAGI-compliant servers
may or may not provide similar instrumentation.

=head2 What PAGI Metrics Provide

PAGI::Server exposes metrics for things that a reverse proxy like nginx
B<cannot> see:

=over 4

=item * WebSocket message counts and bytes

=item * SSE event counts and bytes

=item * Lifespan startup/shutdown timing

=item * Worker spawn/respawn events (multi-worker mode)

=back

For HTTP request metrics (counts, latency, status codes), use your reverse
proxy's metrics - nginx/Caddy/HAProxy all have excellent Prometheus exporters.

=head2 Quick Start

    # 1. Install optional dependency
    cpanm Metrics::Any Metrics::Any::Adapter::Prometheus Net::Prometheus

    # 2. In your app:
    use Metrics::Any::Adapter 'Prometheus';
    use PAGI::App::URLMap;
    use PAGI::App::Metrics;

    my $app = PAGI::App::URLMap->new(
        '/metrics' => PAGI::App::Metrics->new,
        '/'        => $my_app,
    );

    # 3. Run server
    pagi-server app.pl

    # 4. Scrape metrics
    curl http://localhost:5000/metrics

=head2 Available Metrics

    # Server core
    pagi_server_connections_total
    pagi_server_connections_active
    pagi_server_workers_active
    pagi_server_worker_spawns_total
    pagi_server_lifespan_startup_seconds
    pagi_server_lifespan_shutdown_seconds

    # WebSocket
    pagi_websocket_connections_total
    pagi_websocket_connections_active
    pagi_websocket_messages_received_total
    pagi_websocket_messages_sent_total
    pagi_websocket_bytes_received_total
    pagi_websocket_bytes_sent_total

    # SSE
    pagi_sse_connections_total
    pagi_sse_connections_active
    pagi_sse_events_sent_total
    pagi_sse_bytes_sent_total

=head2 Adding Custom Application Metrics

Use L<Metrics::Any> directly in your application code:

    use Metrics::Any '$metrics', name_prefix => ['myapp'];

    $metrics->make_counter('logins_total',
        labels => [qw(method)]);

    # In your login handler
    $metrics->inc_counter('logins_total', { method => 'oauth' });

See L<Metrics::Any> documentation for full API.

=head2 Multi-Worker Considerations

In multi-worker mode, each worker maintains its own metrics. The C</metrics>
endpoint only shows metrics from the worker that handles the scrape request.

For multi-worker deployments, consider:

=over 4

=item * Use StatsD adapter (push model) for aggregation

=item * Run single-worker behind load balancer (one worker per pod)

=item * Use nginx metrics for HTTP, PAGI metrics for WS/SSE only

=back

=head2 Without Metrics::Any

If L<Metrics::Any> is not installed, PAGI::Server runs normally with zero
overhead. All metric calls become no-ops.

=cut
```

**Step 6.2: Add to POD in Server.pm**
```pod
=head1 METRICS

PAGI::Server optionally integrates with L<Metrics::Any> to expose server
metrics. See L<PAGI::Cookbook/"METRICS AND OBSERVABILITY"> for details.

If Metrics::Any is not installed, the server runs normally with zero overhead.
```

**Step 6.3: Run pod tests**
```bash
podchecker lib/PAGI/Server.pm
podchecker lib/PAGI/Cookbook.pod
```

**Step 6.4: Commit**
```bash
git add lib/PAGI/Cookbook.pod lib/PAGI/Server.pm
git commit -m "Add metrics documentation to cookbook"
```

---

### Phase 7: Final Verification

**Step 7.1: Run complete test suite**
```bash
prove -l t/
RELEASE_TESTING=1 prove -l t/
```

**Step 7.2: Test with Metrics::Any installed**
```bash
cpanm Metrics::Any Metrics::Any::Adapter::Prometheus Net::Prometheus
prove -l t/metrics.t
```

**Step 7.3: Test without Metrics::Any**
```bash
# In a clean environment or with Metrics::Any uninstalled
prove -l t/01-hello-http.t t/04-websocket.t t/05-sse.t
```

**Step 7.4: Manual integration test**
```bash
# Terminal 1
perl -Ilib -MMetrics::Any::Adapter=Prometheus examples/metrics/app.pl

# Terminal 2
curl http://localhost:5000/metrics | grep pagi_
```

**Step 7.5: Commit any final fixes**
```bash
git add -A
git commit -m "Final fixes from integration testing"
```

**Step 7.6: Create summary commit/tag**
```bash
git log --oneline feature/metrics-any ^main
```

---

## Files Changed/Created

### New Files
- `lib/PAGI/Server/NullMetrics.pm` - No-op stub
- `lib/PAGI/App/Metrics.pm` - Prometheus endpoint
- `lib/PAGI/Cookbook.pod` - Documentation (or section in existing)
- `t/metrics.t` - Test suite
- `examples/metrics/app.pl` - Example app

### Modified Files
- `lib/PAGI/Server.pm` - Core instrumentation
- `dist.ini` - Optional dependency

---

## Open Questions for Community

1. **Is this scope right?** Focus on WS/SSE metrics that nginx can't provide, skip HTTP request metrics?

2. **Multi-worker story?** Document limitation and recommend StatsD for multi-worker, or invest in shared aggregation?

3. **Metric names?** `pagi_server_*` vs `pagi_*` prefix?

4. **Labels?** Should WebSocket/SSE metrics have labels (e.g., by endpoint path)?

---

## Effort Estimate

| Phase | Effort |
|-------|--------|
| Phase 0: Preparation | 15 min |
| Phase 1: Null Metrics Stub | 30 min |
| Phase 2: Server Core Metrics | 1-2 hours |
| Phase 3: WebSocket Metrics | 1 hour |
| Phase 4: SSE Metrics | 45 min |
| Phase 5: Metrics Endpoint | 45 min |
| Phase 6: Documentation | 1 hour |
| Phase 7: Final Verification | 30 min |
| **Total** | **~6-7 hours** |

---

## Resume Notes

If picking this up later:

1. Check which phase was completed: `git log --oneline feature/metrics-any`
2. Run tests to verify state: `prove -l t/`
3. Each phase ends with a commit - safe to resume from any phase boundary
4. If Metrics::Any not installed: `cpanm Metrics::Any`
5. Key decision: batch mode for high-frequency metrics (messages, bytes), direct calls for gauges (active counts)
