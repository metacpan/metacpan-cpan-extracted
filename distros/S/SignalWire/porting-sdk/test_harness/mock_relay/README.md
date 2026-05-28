# mock-relay

A schema-driven mock SignalWire RELAY WebSocket server. Loads the JSON schemas
under `porting-sdk/relay-protocol/` (extracted from `switchblade` C# Params /
Result classes via `scripts/extract_relay_schemas.py`) and synthesises
JSON-RPC 2.0 responses for every RELAY verb. Same role for RELAY as
`mock_signalwire` plays for REST: one shared test backend for all nine SDK
ports.

## Why

The Python relay tests use `MagicMock` of the WebSocket transport. That's
fine for unit tests of the client's internal state machine, but it does
*not* exercise the wire format, and it can't be reused by the eight
non-Python ports. The mock RELAY server fills that gap — every port boots
the same `mock-relay` process and runs its real SDK against it.

The schemas come from the production C# server, so the wire shapes the
mock validates and synthesises against are the ones the real server
expects. Running the extractor on a fresh switchblade checkout regenerates
every JSON Schema deterministically.

## Install

```bash
cd porting-sdk/test_harness/mock_relay
pip install -e .
```

Installs the `mock-relay` console script and the `mock_relay` Python
package.

## Run

```bash
mock-relay
# or
python -m mock_relay
```

Defaults:

- WebSocket: `ws://127.0.0.1:8773` (env: `MOCK_RELAY_PORT`, flag: `--ws-port`)
- HTTP control plane: `http://127.0.0.1:9773` (env: `MOCK_RELAY_HTTP_PORT`,
  flag: `--http-port`)

The HTTP port defaults to `WS_PORT + 1000` so an agent can override one
and have the other slot in. `--schema-root` overrides the location of the
JSON schemas (default: `porting-sdk/relay-protocol/`).

## Use from a test (Python)

```python
from mock_relay import MockRelayServer
from signalwire.relay import RelayClient

srv = MockRelayServer(host="127.0.0.1", ws_port=0, http_port=0).start()
try:
    client = RelayClient(project="test", token="test", host=srv.relay_host)
    # The SDK uses wss:// by default — our smoke fixture monkeypatches the
    # connect URI to ws:// (see tests/mock_relay/test_python_smoke.py).
    ...
finally:
    srv.stop()
```

Any port (Go, TS, Java, Ruby, Perl, PHP, Rust, C++) that points at the
mock's `ws://host:port` and presents a non-empty project/token will get a
synthesised RELAY session.

## Schemas

Every method is one or two JSON-Schema 2020-12 documents under
`porting-sdk/relay-protocol/`:

- `<method>.params.json` — input shape (validated against incoming
  `signalwire.execute` `params.params`).
- `<method>.result.json` — output shape (used to choose default fields in
  the synthesised `result`).
- `<method>.event.json` — for messaging.* events whose payloads aren't
  derived from a Params/Result class.

Every schema document carries `x-source`:

- `switchblade` — derived from a `PublicCall<Verb>{Params,Result}.cs`
  (the ~112 calling verbs).
- `blade` — derived from the Blade envelope frames in
  `switchblade/Messages/` (`signalwire.connect`, `.ping`, `.execute`,
  `.reauthenticate`, `.disconnect`).
- `messaging-python` — derived from
  `signalwire/relay/client.py:send_message` (switchblade has no
  `PublicMessage*` classes; the C# handler forwards a `JObject` to the
  messaging gateway).
- `mod_infrastructure` — placeholder for FreeSWITCH-side methods
  registered via `swclt_sess_register_protocol_method` in
  `mod_infrastructure/relay.c` that aren't exposed as a switchblade
  Params class. These are flagged `x-permissive: true`; the mock accepts
  any payload for them.

## Control plane

Tests interact with `mock-relay` over plain HTTP, not a second WebSocket.
That keeps test code simple — `requests` or `curl` works from anywhere.

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/__mock__/health` | `{"status":"ok", "schemas_loaded": 128, ...}` |
| `GET`  | `/__mock__/specs` | List loaded schemas (debug). |
| `GET`  | `/__mock__/journal` | Every WS frame, `recv` and `send`. |
| `POST` | `/__mock__/journal/reset` | Clear the journal ring buffer. |
| `GET`  | `/__mock__/sessions` | List active WebSocket sessions. |
| `POST` | `/__mock__/push` | Push a frame to one or all sessions. |
| `POST` | `/__mock__/inbound_call` | Convenience helper: emit an inbound call sequence. |
| `POST` | `/__mock__/scenario_play` | Run a scripted timeline (sleep / push / expect_recv). |
| `GET`  | `/__mock__/scenarios` | List queued scenario overrides. |
| `POST` | `/__mock__/scenarios/reset` | Drain all queued scenarios. |
| `POST` | `/__mock__/scenarios/<method>` | Queue scripted post-RPC events for `<method>`. |
| `POST` | `/__mock__/scenarios/dial` | Queue a dial dance: state events + winner. |
| `POST` | `/__mock__/scenarios/_unconditional` | Push a list of frames immediately (no waiting RPC). |

Scenario bodies are FIFO consume-once: push N scenarios on a method, the
next N executes consume them in order, then the method reverts to the
default synthesis.

### Scripting events for a method

```bash
curl -X POST http://localhost:9773/__mock__/scenarios/calling.play \
     -H 'Content-Type: application/json' \
     -d '[
       {"emit": {"state": "playing", "call_id": "c1", "control_id": "ctl1"}, "delay_ms": 5},
       {"emit": {"state": "finished", "call_id": "c1", "control_id": "ctl1"}, "delay_ms": 10}
     ]'
```

After the next `calling.play` execute, the mock will:

1. Send the JSON-RPC response (`{"code":"200","message":"Playing"}`).
2. After 5ms, emit a `signalwire.event` with
   `event_type: "calling.call.play", params.state: "playing"`.
3. After another 10ms, emit a `signalwire.event` with
   `params.state: "finished"`.

The default `event_type` is derived from the method name:
`calling.play` → `calling.call.play`, `calling.record` →
`calling.call.record`, etc. Override it explicitly with
`{"emit": {...}, "event_type": "calling.error"}`.

### Scripting a dial

`calling.dial` is the only method whose response carries no `call_id` —
the `call_id` arrives via subsequent events keyed by `tag`. The
`scenarios/dial` endpoint scripts the full dance:

```bash
curl -X POST http://localhost:9773/__mock__/scenarios/dial \
     -H 'Content-Type: application/json' \
     -d '{
       "tag": "my-dial-tag",
       "winner_call_id": "winner-1",
       "states": ["created", "ringing", "answered"],
       "node_id": "node-mock-1",
       "device": {"type":"phone","params":{"to_number":"+15551112222","from_number":"+15553334444"}},
       "losers": [
         {"call_id": "loser-1", "states": ["created", "ended"]}
       ]
     }'
```

After the next `calling.dial` whose params carry `tag == "my-dial-tag"`,
the mock emits `calling.call.state` events for the winner (created →
ringing → answered), then state events for each loser (created → ended),
then a single `calling.call.dial` event with
`dial_state: "answered"` and the winner's `call_id`.

## Server-initiated pushes

The endpoints in the previous section script events that fire *after* a
matching SDK-initiated RPC. The endpoints in **this** section let a test
inject frames the SDK didn't ask for — the dominant flow for
realtime-API-style consumers (incoming call notifications, async state
changes, server-side broadcasts).

### Server vs SDK initiated

* **Scenarios** (`/__mock__/scenarios/...`) fire AFTER a matching
  `signalwire.execute`. They simulate the post-RPC event flow:
  `play()` → response → `state:playing` → `state:finished`.
* **Pushes** (`/__mock__/push`, `/__mock__/inbound_call`,
  `/__mock__/scenario_play`, `/__mock__/scenarios/_unconditional`) deliver
  frames immediately to one or every connected session, with no preceding
  RPC. They simulate the server pushing notifications to the SDK.

### Sessions

Every WebSocket connection gets a server-issued session id (UUID hex,
generated at connect time). List active sessions:

```bash
curl http://localhost:9773/__mock__/sessions | jq .
```

```json
{
  "sessions": [
    {
      "id": "f70af522ac4f4ea9b2a84e6ec6cb16fb",
      "connection_id": "conn-f70af522ac4f",
      "connected_at": 1716135123.45,
      "peer_addr": "127.0.0.1:55834",
      "protocol_string": "signalwire_741ba27fea314c2e8ebd0e7078657b49"
    }
  ]
}
```

The `id` is what `/push` and friends accept as `session_id`. Sessions are
removed when the WebSocket closes; entries also carry the protocol string
issued by `signalwire.connect` so tests can correlate to specific clients.

### Pushing a single frame

```bash
curl -X POST http://localhost:9773/__mock__/push \
     -H 'Content-Type: application/json' \
     -d '{
       "frame": {
         "jsonrpc": "2.0",
         "id": "evt-1",
         "method": "signalwire.event",
         "params": {
           "event_type": "calling.call.state",
           "params": {
             "call_id": "c1",
             "call_state": "answered",
             "direction": "inbound"
           }
         }
       }
     }'
```

Response: `{"sent_to": ["<session_id_1>", ...], "count": N}`.

Target a single session with the query string:

```bash
curl -X POST 'http://localhost:9773/__mock__/push?session_id=f70af522ac4f4ea9b2a84e6ec6cb16fb' \
     -H 'Content-Type: application/json' \
     -d '{"frame": {...}}'
```

### Inbound call helper

`/__mock__/inbound_call` scripts the typical inbound-call sequence so
tests don't have to hand-build `signalwire.event` envelopes:

```bash
curl -X POST http://localhost:9773/__mock__/inbound_call \
     -H 'Content-Type: application/json' \
     -d '{
       "call_id": "incoming-1",
       "from_number": "+15551234567",
       "to_number": "+15559876543",
       "context": "default",
       "auto_states": ["created", "ringing"],
       "delay_ms": 50
     }'
```

The first state arrives as a `calling.call.receive` event (the wire shape
the production server uses to announce a new inbound call — it's what
triggers a Python SDK's `on_call` handler). Subsequent states arrive as
`calling.call.state` updates. Frames are paced `delay_ms` apart so timing
looks realistic.

Body fields:

* `call_id` — optional, generated if omitted.
* `from_number`, `to_number` — placed into `device.params` on each event.
* `context` — defaults to `"default"`.
* `auto_states` — array of state names; defaults to `["created"]`.
* `delay_ms` — pause between states; defaults to 50ms.
* `session_id` — optional; broadcasts to all sessions if omitted.

Response (broadcast):

```json
{
  "sent_to": ["<session_id_1>"],
  "count": 1,
  "call_id": "incoming-1",
  "states_emitted": ["created", "ringing"]
}
```

### Scripted timelines (`scenario_play`)

`/__mock__/scenario_play` runs a richer timeline that mixes pushes,
sleeps, and `expect_recv` checkpoints (block until the SDK sends a given
method back, then continue):

```bash
curl -X POST http://localhost:9773/__mock__/scenario_play \
     -H 'Content-Type: application/json' \
     -d '[
       {"sleep_ms": 100},
       {"push": {"frame": {"jsonrpc":"2.0","method":"signalwire.event","params":{"event_type":"calling.call.receive","params":{"call_id":"c1","call_state":"created","direction":"inbound"}}}}},
       {"expect_recv": {"method": "calling.answer", "timeout_ms": 5000}},
       {"push": {"frame": {"jsonrpc":"2.0","method":"signalwire.event","params":{"event_type":"calling.call.state","params":{"call_id":"c1","call_state":"answered","direction":"inbound"}}}}}
     ]'
```

Operation kinds:

* `{"sleep_ms": <int>}` — pause the timeline for N milliseconds.
* `{"push": {"frame": {...}, "session_id": "<optional>"}}` — emit a
  frame. Without `session_id` the frame is broadcast to every session.
* `{"expect_recv": {"method": "<name>", "timeout_ms": <int>, "session_id": "<optional>"}}`
  — block until an inbound frame matching the given method arrives, or
  abort the scenario on timeout.

Returns:

* `{"status": "completed", "steps": N}` when every step succeeded.
* `{"status": "timeout", "at_step": N, "expected_method": "...", "steps_completed": M}`
  on `expect_recv` timeout.

### Unconditional scenario

If a test prefers the existing scenario JSON shape over the bare-frame
`/push` shape, `/__mock__/scenarios/_unconditional` accepts the same
`[{"emit": {...}, "event_type": "...", "delay_ms": N}, ...]` body but
fires immediately (instead of waiting for an RPC):

```bash
curl -X POST http://localhost:9773/__mock__/scenarios/_unconditional \
     -H 'Content-Type: application/json' \
     -d '[
       {"emit": {"call_id":"c1","call_state":"created","direction":"inbound"}, "event_type": "calling.call.receive"},
       {"emit": {"call_id":"c1","call_state":"answered","direction":"inbound"}, "event_type": "calling.call.state", "delay_ms": 50}
     ]'
```

This endpoint does NOT push entries into the per-method scenario queue —
the listing at `/__mock__/scenarios` is unaffected.

### Worked example: inbound call + answer

```python
# Test fires in parallel with an SDK that has registered an on_call handler.
# 1. Push the inbound call.
requests.post(f"{srv.http_url}/__mock__/inbound_call", json={
    "call_id": "incoming-1",
    "from_number": "+15551234567",
    "to_number": "+15559876543",
})
# 2. SDK on_call fires; SDK calls call.answer() which sends calling.answer.
# 3. Push the answered state.
requests.post(f"{srv.http_url}/__mock__/push", json={
    "frame": {"jsonrpc":"2.0","method":"signalwire.event","params":{
        "event_type": "calling.call.state",
        "params": {"call_id":"incoming-1", "call_state":"answered", "direction":"inbound"},
    }},
})
# 4. Inspect /__mock__/journal to confirm the SDK's calling.answer was logged.
```

### Journal

```bash
curl http://localhost:9773/__mock__/journal | jq .
```

Each entry has:

```json
{
  "timestamp": 1716135123.45,
  "direction": "recv",
  "method": "signalwire.execute",
  "request_id": "abc-123",
  "frame": { ...full JSON-RPC frame... },
  "connection_id": "conn-...",
  "session_id": "..."
}
```

The `session_id` is the same UUID that `/__mock__/sessions` reports — use
it to filter the journal when multiple SDKs are connected concurrently.

A 1000-frame ring buffer; resets via `POST /__mock__/journal/reset`.

## What it actually does

1. **Loads schemas at startup** — every `relay-protocol/*.json`. Errors
   are surfaced in `/__mock__/health.schema_load_errors`, not raised.
2. **Accepts WebSocket connections on `ws://host:port`** — no path,
   matching the production server.
3. **Authenticates `signalwire.connect`** — checks for non-empty
   `authentication.project` + `authentication.token` (or `jwt_token`),
   issues a fresh `protocol` UUID, returns a `ConnectResult` shape with
   the agent's contexts echoed in `subscriptions`. Stores the protocol
   so reconnect-with-protocol-string returns
   `session_restored: true`.
4. **Routes `signalwire.execute`** — looks up the inner `params.method`,
   validates `params.params` against the params schema (for non-permissive
   methods), synthesises a `result` from the result schema, returns it.
5. **Emits scripted events** — if the test queued a scenario for the
   method, fires the events with the configured delays.
6. **Responds to `signalwire.ping`** — returns a fresh timestamp.
7. **Records every frame** in the journal.

## Adding a new RELAY verb

1. Add a `PublicCall<Name>Params.cs` (and optionally
   `PublicCall<Name>Result.cs`) under
   `switchblade/RelayPlugin/Calling/`. For FreeSWITCH-side methods, just
   register them in `mod_infrastructure/relay.c` via
   `swclt_sess_register_protocol_method`.
2. Run `python3 scripts/extract_relay_schemas.py`. The script:
   - Parses the new C# class with the line-based regex parser.
   - Maps the class basename to a method name (handles `Pause`, `Resume`,
     `Stop`, `Volume`, `StartInputTimers` as sub-commands; everything else
     goes through camel→snake).
   - Emits `relay-protocol/<method>.params.json` and
     `relay-protocol/<method>.result.json` deterministically.
3. **Mock auto-picks up the schema** — restart `mock-relay` and the new
   verb is callable; no code change in `mock_relay/` is required.
4. (Optional) Add a default message for the method in
   `mock_relay/handlers.py:_DEFAULT_MESSAGES` if you want a more specific
   default response than `"OK"`.
5. (Optional) Author a fixture under
   `tests/mock_relay/fixtures/<method>.json` if the method needs scripted
   post-RPC events.
6. Per-port test files now have a target for the new method.

CI integration: `python3 scripts/extract_relay_schemas.py --check` exits
non-zero if the on-disk schemas drift from what the script would emit.
Wire that into your CI to catch out-of-band edits to the JSON files.

## Caveats

- **No TLS.** Production uses `wss://`. The mock only speaks `ws://`.
  SDKs that hard-wire `wss://` need a tweak (the smoke test does this
  via the SDK's URL override hook).
- **Auth is open by design.** Any non-empty project + token (or any
  non-empty `jwt_token`) is accepted; the mock doesn't validate them
  against anything. To test 401 paths, pass an empty project or token.
- **No connection-level rate limiting / fairness.** A misbehaving SDK
  can DoS itself.
- **Schemas are best-effort permissive.** Most calling-method param
  schemas allow `additionalProperties: true` so SDKs that send extra
  fields don't get rejected. If you need to assert "extra fields were
  not sent", consult the journal.
