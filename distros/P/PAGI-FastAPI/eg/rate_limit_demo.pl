#!/usr/bin/env perl

use v5.38;
use experimental qw(try);
use Future::AsyncAwait;

use PAGI::FastAPI;
use PAGI::FastAPI::RateLimit::Driver::Memory;

# A single key resolver, shared by every limiter below. It layers one
# demo-only override (an X-Demo-Client header) on top of the framework's
# own documented default chain, so a single browser tab can simulate
# multiple independent clients just by switching a dropdown, normally
# you'd rely on X-API-Key or the caller's IP alone.
my $key_cb = sub ($c) {
    return $c->header('X-Demo-Client')
        // $c->header('X-API-Key')
        // $c->header('X-Forwarded-For')
        // $c->scope->{client}[0]
        // '127.0.0.1';
};

# Explicit driver instances (rather than letting add_rate_limit/rate_limit
# build their own) purely so /limits/reset below can reach in and clear a
# client's counters directly via reset_async(). Each limiter's counters
# are otherwise completely independent, driver-per-instance by default,
# see the note on /api/expensive.
my $app_driver    = PAGI::FastAPI::RateLimit::Driver::Memory->new;
my $route_driver  = PAGI::FastAPI::RateLimit::Driver::Memory->new;

my $app = PAGI::FastAPI->new(
    title   => 'PAGI::FastAPI Rate Limiting Demo',
    version => '1.0.0',
);

# App-wide limiter, applied via add_middleware directly (rather than the
# add_rate_limit() convenience wrapper) so we can exempt /limits/reset
# and the dashboard itself from it below. add_rate_limit() has no path-
# exclusion option, it wraps literally everything, and an admin/
# reset action gated by the very quota it exists to clear would make
# the demo unrecoverable once a client's budget runs out, which defeats
# the endpoint's purpose.
my $app_wide_limiter = PAGI::FastAPI::Middleware::RateLimit->new(
    requests => 10,
    window   => 20,
    key_cb   => $key_cb,
    driver   => $app_driver,
);
$app->add_middleware(async sub ($c, $next) {
    my $path = $c->scope->{path} // '';
    return await $next->($c) if $path eq '/' || $path eq '/limits/reset';
    return await $app_wide_limiter->handle($c, $next);
});

$app->get('/',
    handler => async sub ($c) {
        return $c->html(<<'HTML');
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PAGI::FastAPI Rate Limiting</title>
    <style>
        body { font-family: sans-serif; margin: 2em; max-width: 720px; }
        h2 { margin-bottom: 0.2em; }
        .sub { color: #666; margin-top: 0; }
        .card { border: 1px solid #ddd; border-radius: 8px; padding: 1.2em 1.5em; margin-bottom: 1.2em; }
        .row { display: flex; gap: 0.6em; align-items: center; margin-bottom: 0.8em; flex-wrap: wrap; }
        label { font-size: 0.9em; color: #444; }
        select, input[type="text"] { padding: 6px; font-size: 1em; }
        button { padding: 8px 14px; font-size: 0.95em; cursor: pointer; }
        button.danger { background: #fdeaea; border-color: #e0a0a0; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 0.8em; font-weight: bold; }
        .ok  { background: #e6f7e9; color: #1a7a34; }
        .bad { background: #fdeaea; color: #b3261e; }
        #log { border: 1px solid #ddd; border-radius: 8px; height: 260px; overflow-y: scroll; padding: 10px; font-family: monospace; font-size: 0.85em; }
        .entry { margin-bottom: 4px; white-space: pre-wrap; }
        .empty { color: #999; font-style: italic; }
    </style>
</head>
<body>
    <h2>Rate Limiting</h2>
    <p class="sub">One app-wide limit (10 req / 20s) plus a stricter per-route limit on /api/expensive (3 req / 15s), two independent budgets, both keyed the same way.</p>

    <div class="card">
        <div class="row">
            <label for="client">Simulated client:</label>
            <select id="client">
                <option value="alice">alice</option>
                <option value="bob">bob</option>
                <option value="carol">carol</option>
            </select>
            <span class="sub">(sent as X-Demo-Client, switch clients to see independent quotas)</span>
        </div>
        <div class="row">
            <button id="callCheap">Call /api/cheap</button>
            <button id="callExpensive">Call /api/expensive</button>
            <button id="hammer">Hammer /api/expensive x5</button>
            <button id="reset" class="danger">Reset my limits</button>
        </div>
    </div>

    <h3>Log</h3>
    <p class="sub">/api/expensive shows two budgets (app-wide and route) since two limiters gate it; /api/cheap only shows one.</p>
    <div id="log"><div class="empty">Nothing called yet...</div></div>

    <script>
        const logEl    = document.getElementById('log');
        const clientEl = document.getElementById('client');

        function log(line, ok) {
            if (logEl.querySelector('.empty')) logEl.innerHTML = '';
            const div = document.createElement('div');
            div.className = 'entry';
            div.innerHTML = line;
            logEl.prepend(div);
        }

        // Routes gated by BOTH the app-wide limiter and a per-route
        // limiter (currently just /api/expensive) end up with two
        // x-ratelimit-* headers on the same response: each RateLimit
        // middleware instance tracks its own independent budget and
        // intentionally adds its own header values via Context::add_header
        // (rather than Context::set_header, which replaces same-named
        // headers) so both budgets are visible at once.
        // fetch()'s Headers.get() silently comma-joins duplicate header
        // values into one string, so we split that back apart here rather
        // than showing a confusing mashed-together number.
        function parseAll(res, name) {
            const raw = res.headers.get(name);
            if (!raw) return [];
            return raw.split(',').map(s => s.trim());
        }

        async function call(path) {
            const res = await fetch(path, {
                headers: { 'X-Demo-Client': clientEl.value },
            });
            const body = await res.json();
            const limits      = parseAll(res, 'x-ratelimit-limit');
            const remainings  = parseAll(res, 'x-ratelimit-remaining');
            const retryAfter  = res.headers.get('retry-after');
            const badge = res.status === 429
                ? '<span class="badge bad">429 blocked</span>'
                : '<span class="badge ok">' + res.status + ' ok</span>';

            let line = badge + ' ' + path + '  ';
            if (limits.length > 1) {
                // app-wide limiter runs outermost and sets its headers
                // first; the per-route limiter (innermost) sets its own
                // right after, so [0] is always app-wide, [1] is the
                // route's own, stricter budget.
                line += 'app-wide: limit=' + limits[0] + ' remaining=' + remainings[0]
                      + ' &nbsp;|&nbsp; route: limit=' + limits[1] + ' remaining=' + remainings[1];
            } else {
                line += 'limit=' + limits[0] + ' remaining=' + remainings[0];
            }
            if (retryAfter) line += ' retry-after=' + retryAfter + 's';
            log(line);
        }

        document.getElementById('callCheap').onclick     = () => call('/api/cheap');
        document.getElementById('callExpensive').onclick = () => call('/api/expensive');

        document.getElementById('hammer').onclick = async () => {
            for (let i = 0; i < 5; i++) {
                await call('/api/expensive');
            }
        };

        document.getElementById('reset').onclick = async () => {
            const res = await fetch('/limits/reset', { headers: { 'X-Demo-Client': clientEl.value } });
            if (res.ok) {
                log('<span class="badge ok">reset</span> cleared limits for ' + clientEl.value);
            } else {
                log('<span class="badge bad">' + res.status + '</span> reset failed for ' + clientEl.value);
            }
        };
    </script>
</body>
</html>
HTML
    }
);

# Only the app-wide 10-req/20s limit applies here.
$app->get('/api/cheap',
    handler => async sub ($c) {
        return { ok => 1, endpoint => 'cheap' };
    }
);

# The app-wide limit (10/20s) AND this route's own, stricter limit
# (3/15s) both apply, the app-wide middleware wraps the whole app
# (except / and /limits/reset, see above), and rate_limit wraps just
# this handler again on top of that. They're independent budgets
# against independent counters (each PAGI::FastAPI::Middleware
# ::RateLimit instance gets its own driver unless one is passed
# explicitly, as it is here), not a shared, stacked count, so a
# client can still have 7 of 10 app-wide requests left while being
# fully blocked here, or vice versa.
$app->get('/api/expensive',
    rate_limit => {
        requests => 3,
        window   => 15,
        key_cb   => $key_cb,
        driver   => $route_driver,
    },
    handler => async sub ($c) {
        return { ok => 1, endpoint => 'expensive' };
    }
);

# Not part of PAGI::FastAPI::RateLimit::Driver's public contract for end
# users to call mid-request in a real app, this exists purely so the
# demo can be replayed without restarting the server. Deliberately
# exempt from the app-wide limiter (see above) so it always works, even
# once a client's app-wide budget is fully exhausted.
$app->get('/limits/reset',
    handler => async sub ($c) {
        my $key = $key_cb->($c);
        await $app_driver->reset_async($key);
        await $route_driver->reset_async($key);
        return { reset => 1, key => $key };
    }
);

$app->to_app;
