#!/usr/bin/env perl

use v5.38;
use experimental 'class';
use Future::AsyncAwait;

use PAGI::FastAPI;

my $app = PAGI::FastAPI->new();

# 1. HTML Dashboard Route
$app->get('/', handler => async sub ($c) {
    return $c->html(<<'HTML');
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PAGI SSE - Live System Monitor</title>
    <style>
        body { font-family: monospace; background: #121212; color: #00ffcc; padding: 2rem; }
        .card { border: 1px solid #00ffcc; padding: 1rem; border-radius: 8px; max-width: 400px; }
        .metric { font-size: 1.5rem; margin: 0.5rem 0; }
        .bar { background: #333; height: 10px; border-radius: 5px; overflow: hidden; }
        .fill { background: #00ffcc; height: 100%; width: 0%; transition: width 0.3s; }
    </style>
</head>
<body>
    <div class="card">
        <h2>⚡ Live System Status</h2>
        <div class="metric">CPU: <span id="cpu">0</span>%</div>
        <div class="bar"><div id="cpu-bar" class="fill"></div></div>

        <div class="metric">Memory: <span id="mem">0</span> MB</div>

        <p><small>Status: <span id="status" style="color:yellow">Connecting...</span></small></p>
    </div>

    <script>
        const evtSource = new EventSource('/api/v1/metrics');

        evtSource.onopen = () => {
            document.getElementById('status').innerText = 'Connected (Live)';
            document.getElementById('status').style.color = '#00ffcc';
        };

        evtSource.onmessage = (e) => {
            const data = JSON.parse(e.data);

            document.getElementById('cpu').innerText = data.cpu;
            document.getElementById('cpu-bar').style.width = data.cpu + '%';
            document.getElementById('mem').innerText = data.memory_mb;
        };

        evtSource.onerror = () => {
            document.getElementById('status').innerText = 'Reconnecting...';
            document.getElementById('status').style.color = 'red';
        };
    </script>
</body>
</html>
HTML
});

# 2. SSE Metrics Stream Endpoint
$app->get('/api/v1/metrics', handler => async sub ($c) {
    return $c->sse(async sub ($sse) {
        await $sse->keepalive(15);

        my $count = 0;

        while (1) {
            $count++;

            my $metric_payload = {
                cpu       => int(rand(80)) + 10,
                memory_mb => int(rand(200)) + 500,
                tick      => $count,
            };

            await $sse->send_json($metric_payload);
            await $c->sleep(1);
        }
    });
});

# Return application entry point
$app->to_app;
