# Mock test harness — shared backends for cross-port behavioral tests

**Audience:** anyone writing or maintaining tests in any of the nine SignalWire
SDK ports (Python, .NET, Go, TypeScript, Java, PHP, Ruby, Perl, Rust, C++).

**TL;DR:** Two long-lived mock servers (one for REST, one for the RELAY
WebSocket) ship from `porting-sdk/test_harness/`. Every port's test suite
points its real SDK at them. The wire shapes the mocks accept and synthesize
come from the same sources the production servers were built from (OpenAPI for
REST, switchblade C# `[JsonProperty]` attributes for RELAY) — so a test that
asserts on the journal is asserting against the real wire shape.

---

## 1. What it is

Two shared mock servers live under `porting-sdk/test_harness/`:

| Mock | Path | Role |
|---|---|---|
| `mock_signalwire` | `test_harness/mock_signalwire/` | Schema-driven REST API mock; loads 13 OpenAPI specs, synthesizes JSON responses. |
| `mock_relay` | `test_harness/mock_relay/` | Schema-driven RELAY WebSocket mock; loads JSON-Schema documents extracted from switchblade C# Params/Result classes, synthesizes JSON-RPC 2.0 frames. |

Each is a Python package with its own `pyproject.toml`, console script
(`mock-signalwire` / `mock-relay`), and HTTP control plane. Each port's tests
boot the same processes — there's exactly one mock implementation per
transport, regardless of which language is running the tests.

The full per-mock READMEs:

- `test_harness/mock_signalwire/README.md`
- `test_harness/mock_relay/README.md`

This doc is the cross-port view: how every port's test suite finds, starts,
and uses them, plus the discipline they enforce.

---

## 2. Architecture

### Adjacency-based discovery (no install required)

Every port's test helper walks up from the test file looking for a sibling
`porting-sdk/test_harness/<name>/` directory. When found, the package path
is prepended to `sys.path` (or the language equivalent) so the mock import
resolves without `pip install`. Reference: the `_discover_mock_package()`
function in `signalwire-python/tests/unit/relay/conftest.py` (mirrored in
the matching `tests/unit/rest/conftest.py`).

The contract is just: clone `porting-sdk` next to your language repo
(`~/src/porting-sdk/`, `~/src/signalwire-python/`, `~/src/signalwire-go/`,
…) and the per-port test helpers find it. No editable install, no
`PYTHONPATH`, no env var.

### Probe-or-spawn pattern

The non-Python ports can't import the Python mock package, so each ships a
helper that probes `http://127.0.0.1:<port>/__mock__/health` first; if a
mock is already running (previous test run, interactive `mock-relay`
process, concurrent suite) it reuses it, otherwise it spawns the
`mock-signalwire` / `mock-relay` console script as a detached subprocess,
polls health until ready, and tears it down on suite exit. Reference:
`signalwire-typescript/tests/relay/mocktest.ts` — see `probeHealth()` and
the spawn block.

### HTTP control plane at `/__mock__/`

Tests interact with a running mock over plain HTTP, not a second WebSocket.
Both mocks expose the same endpoint shape:

| Method | Path | Both | Purpose |
|---|---|:-:|---|
| `GET`  | `/__mock__/health` | yes | `{"status":"ok", "specs_loaded": 13, ...}` |
| `GET`  | `/__mock__/journal` | yes | Every recorded request/frame, in order. |
| `POST` | `/__mock__/journal/reset` | yes | Clear the journal ring buffer. |
| `GET`  | `/__mock__/scenarios` | yes | List queued scenario overrides. |
| `POST` | `/__mock__/scenarios/<id>` | yes | Push a single FIFO consume-once override. |
| `POST` | `/__mock__/scenarios/reset` | yes | Drain the scenario queue. |

`mock_relay` adds session-aware push endpoints — see section 5.

A test's typical lifecycle:

```
beforeEach: POST /__mock__/journal/reset + POST /__mock__/scenarios/reset
           (optionally POST a scenario override)
test body:  drive the SDK; SDK hits the mock over real HTTP/WS
assertions: behavioral (return value / state) + journal-shape
            (GET /__mock__/journal, assert on the recorded frames)
```

## Multi-process / multi-target test concurrency

### The shared mock is a single process per port slot

Each port runs its own `mock_signalwire` (port 8765–8772, 8784) and
`mock_relay` (8775–8782, 8785) instance. The journal is a single ring
buffer; sessions are a single registry; broadcast/push events go to ALL
connected sessions. Concurrent access from multiple test processes WILL
stomp on each other — journal frames from test A interleave with test B,
scenario queues drain into the wrong test, broadcast pushes hit sessions
that didn't expect them. In-process mutexes don't fix this; the contention
is across operating-system processes against the same TCP listener.

### Two failure modes, two fixes

**Failure mode A — multi-binary integration tests (Rust pattern).**
Languages where a single test invocation spawns N child processes hit this:
each `tests/*.rs` file is its own binary in Cargo, and Go's per-package
test binaries behave the same. In-process mutexes (`OnceLock<Mutex<()>>`,
`std::sync::Mutex`, `tokio::sync::Mutex`, etc.) only serialize within one
binary. The shared mock server crosses binary boundaries — N test
binaries running in parallel each construct their own mock client and
race against the journal.

Fix: **cross-process file lock**. Reference implementation in
[`signalwire-rust/tests/common/relay_mocktest.rs`](../signalwire-rust/tests/common/relay_mocktest.rs)
— uses `flock(LOCK_EX)` on `/tmp/signalwire-rust-mock-relay.lock` plus
`wait_for_no_sessions(2s)` poll before each test. The lock is held for
the lifetime of the test, then released on drop. Other ports that hit
this pattern (Go integration tests across packages, for example) should
adopt the same `flock` approach.

**Failure mode B — multi-target frameworks within one runner (.NET pattern).**
`dotnet test` runs `net8.0` / `net9.0` / `net10.0` in parallel by default
when a project's `<TargetFrameworks>` lists multiple TFMs. All three
framework runs hit the same mock server's port simultaneously and journal
state stomps even within a single `dotnet test` invocation.

Fix: **serial per-framework execution** in the CI runner script.
Reference implementation in
[`signalwire-dotnet/scripts/run-ci.sh`](../signalwire-dotnet/scripts/run-ci.sh)
— invokes `dotnet test --framework net8.0` then `--framework net9.0`
then `--framework net10.0` rather than the parallel default. Each
framework run gets the journal to itself.

### When you add a new port or new test runner

Ask: does my test invocation spawn multiple processes that each construct
their own mock client? If yes, you need either cross-process locking
(Failure mode A) or per-process mock-server isolation (different port per
worker). The shared mock is single-tenant; treat it that way.

---

### Per-port helpers

Every port has a small `mocktest.<ext>` (or equivalently named) helper
that owns the spawn/probe + control-plane HTTP calls:

| Port | REST helper | RELAY helper |
|---|---|---|
| Python | `signalwire-python/tests/unit/rest/conftest.py` | `signalwire-python/tests/unit/relay/conftest.py` |
| TypeScript | `signalwire-typescript/tests/rest/mocktest.ts` | `signalwire-typescript/tests/relay/mocktest.ts` |
| Go | `signalwire-go/pkg/rest/internal/mocktest/mocktest.go` | `signalwire-go/pkg/relay/internal/mocktest/mocktest.go` |
| Java | `signalwire-java/src/test/java/com/signalwire/sdk/rest/*MockTest.java` (per-test bootstrap) | `signalwire-java/src/test/java/com/signalwire/sdk/relay/RelayMockTest.java` |
| PHP | `signalwire-php/tests/Rest/*MockTest.php` (per-class) | `signalwire-php/tests/Relay/MockTest.php` |
| Ruby | `signalwire-ruby/tests/rest/*_mock_test.rb` | `signalwire-ruby/tests/relay/mock_test.rb` |
| Perl | `signalwire-perl/t/lib/MockTest.pm` | `signalwire-perl/t/lib/RelayMockTest.pm` |
| Rust | `signalwire-rust/tests/common/mocktest.rs` | `signalwire-rust/tests/common/relay_mocktest.rs` |
| C++ | `signalwire-cpp/tests/mocktest.{cpp,hpp}` | `signalwire-cpp/tests/relay_mocktest.{cpp,hpp}` |
| .NET | `signalwire-dotnet/tests/RestMock/*MockTest.cs` | `signalwire-dotnet/tests/RelayMockTest.cs` |

---

## 3. The wire-shape sources

The whole point of these mocks is that their wire validation is the same wire
shape the production servers expect. Two source pipelines feed them:

### REST: 13 OpenAPI specs

Under `rest-apis/<namespace>/openapi.yaml` — one spec per namespace
(`calling`, `chat`, `compatibility`, `datasphere`, `fabric`, `fax`, `logs`,
`message`, `project`, `pubsub`, `relay-rest`, `video`, `voice`).

`mock_signalwire` loads all of them at startup, builds a route table from
`(METHOD, path_template)`, authenticates basic auth, and synthesizes
responses by walking each operation's `responses[2xx]` schema (preferring
`example` → `examples[0]` → schema example → deterministic synthesis).

### RELAY: switchblade C# `[JsonProperty]` extraction

The `~112` calling verbs in switchblade are the canonical RELAY schema
authority. `scripts/extract_relay_schemas.py` parses each
`PublicCall<Verb>{Params,Result}.cs` line-by-line, follows nested types
(`CallDevice`, etc.), and emits one or two JSON-Schema 2020-12 documents per
method to `relay-protocol/<method>.{params,result}.json`. The Newtonsoft
`Required = Required.Always` vs `NullValueHandling = NullValueHandling.Ignore`
attributes determine the schema's `required` array.

Source files: `~/src/switchblade/RelayPlugin/Calling/PublicCall*.cs`
(56 Params files, plus matching Result files).

Other inputs the script handles:

- **`switchblade/Messages/`** for the Blade envelope frames
  (`signalwire.connect`, `.execute`, `.ping`, `.disconnect`,
  `.reauthenticate`).
- **`mod_infrastructure/relay.c`** for FreeSWITCH-side methods registered
  via `swclt_sess_register_protocol_method` that don't have a switchblade
  Params class. These get a permissive placeholder schema marked
  `"x-source": "mod_infrastructure"` and `"x-permissive": true` so the
  mock accepts any payload.
- **Python `signalwire/relay/client.py`** as a fallback for `messaging.send`
  (switchblade has no `PublicMessage*` classes).

`mock_relay` loads every `relay-protocol/*.json` at startup and synthesizes
JSON-RPC 2.0 frames from them; per-method `_DEFAULT_MESSAGES` overrides live
in `test_harness/mock_relay/mock_relay/handlers.py`.

CI integration:
```bash
python3 scripts/extract_relay_schemas.py --check
```
exits non-zero if the on-disk schemas drift from what the script would emit.

---

## 4. Adding a new verb

### REST

1. Add (or update) the operation in the relevant
   `rest-apis/<namespace>/openapi.yaml`.
2. Add a `responses[2xx].content[application/json].example` (or `examples[0]`,
   or a schema-level example) so the mock has a deterministic body to return.
3. Restart `mock-signalwire`. The new endpoint is callable; no code change in
   `mock_signalwire/` is required.
4. Per-port test files now have a target for the new endpoint.

### RELAY

Full workflow in `test_harness/mock_relay/README.md`, `## Adding a new RELAY
verb`. Summary: add `PublicCall<Name>{Params,Result}.cs` under
`~/src/switchblade/RelayPlugin/Calling/` (or register in
`mod_infrastructure/relay.c` for FreeSWITCH-side methods); run
`python3 scripts/extract_relay_schemas.py` to regenerate
`relay-protocol/<method>.{params,result}.json`; restart `mock-relay`. The
mock auto-loads — no `test_harness/mock_relay/mock_relay/` code change
required. Optional: add a per-method default body in
`mock_relay/handlers.py:_DEFAULT_MESSAGES` or a scripted-events fixture under
`tests/mock_relay/fixtures/<method>.json`.

In both cases the mock is the source-of-truth checkpoint: if the spec or
switchblade doesn't have the wire shape, neither does the mock, and the test
will tell you. Drift between port and production server shows up as a failing
journal assertion.

---

## 5. Server-initiated push (Relay only)

REST is request/response — the SDK initiates everything. RELAY is bidirectional
— the server can push frames the SDK didn't ask for. `mock_relay` exposes three
endpoints for that flow:

| Endpoint | Purpose |
|---|---|
| `POST /__mock__/push` | Send a single frame to one or all sessions. |
| `POST /__mock__/inbound_call` | Convenience helper: emit the typical inbound-call sequence (`calling.call.receive` followed by `calling.call.state` updates). |
| `POST /__mock__/scenario_play` | Run a scripted timeline mixing `sleep_ms`, `push`, and `expect_recv` checkpoints. |
| `POST /__mock__/scenarios/_unconditional` | Push a list of frames immediately using the existing scenario JSON shape. |

Sessions: every WebSocket connection gets a server-issued UUID. List active
ones with `GET /__mock__/sessions`. Push with `?session_id=...` to target one,
omit to broadcast.

Reference: `test_harness/mock_relay/README.md`, `## Server-initiated pushes`
section. Tests covering the wire shape live at
`tests/mock_relay/test_pushes.py`.

The dominant consumer of these endpoints is the realtime-API side: tests
that simulate "incoming call arrives → SDK's `on_call` handler fires → SDK
calls `call.answer()` → server pushes the answered state event."

---

## 6. Coverage so far

Order-of-magnitude counts of mock-backed tests per port (counted by test-case
declarations in files matching the per-port mock-test naming convention):

| Port | Mock-backed test cases (approx) |
|---|---:|
| Python | 142 |
| TypeScript | 298 |
| Go | 97 |
| Java | 298 |
| PHP | 345 |
| Ruby | 298 |
| Perl | 664 |
| Rust | 287 |
| C++ | 293 |
| **Total** | **~2700** |

.NET tests (`signalwire-dotnet/tests/`) bind to the shared mocks via
`tests/RestMock/*MockTest.cs` and `tests/RelayMockTest.cs`. The per-
port helper paths are listed in section 2's "Per-port helpers" table.

---

## 7. No-cheat-tests discipline

A mock-backed test isn't just "code that exits 0." Every test must do **both**
of the following:

1. **Behavioral assertion** — observe what the SDK exposed back to the
   developer (return value, parsed state, exception type, callback args).
2. **Journal assertion** — call `GET /__mock__/journal` and assert on what
   the SDK actually sent over the wire (method name, request id presence,
   shape of `params`, etc.).

Neither alone is sufficient:

- Behavioral-only can pass even if the SDK is sending the wrong wire shape,
  because the mock's permissive synthesis will still return *something*.
- Journal-only can pass even if the SDK ignored the response and returned
  garbage to the user.

### What's NOT allowed

- `mock.patch(...)` of HTTP or WebSocket libraries (`requests`, `httpx`,
  `aiohttp`, `websockets`, `websocket-client`, etc.) inside a mock-backed
  test. The whole point is to drive real sockets.
- Asserting only that the mock journal is non-empty (`len(journal) > 0`) —
  that's an assert-true that doesn't shape-check anything.
- Asserting only that the SDK didn't raise.

### What IS allowed (the one carve-out)

Patching the SDK's hard-coded WebSocket URI when the SDK has no `host=`
constructor kwarg. The Python relay client is the canonical case: it bakes
`wss://relay.signalwire.com/...` into connect, so the test patches
`websockets.connect` to redirect that URI to the mock's
`ws://127.0.0.1:<port>/`. See
`signalwire-python/tests/unit/relay/conftest.py:_ws_redirect_to_mock`.
This is a transport-level redirect, not a transport stub — the SDK's real
websockets library still establishes a real socket to the mock. Ports that
*do* expose `host=` (or equivalent) must use it instead.

`scripts/audit_no_cheat_tests.py` flags tests that assert nothing, mock the
thing under test, or only check exception type with no payload shape. Journal
assertions are what catch wire-format drift between SDKs and the real
production servers — they're the reason the shared mocks exist.

---

## See also

- [`test_harness/mock_signalwire/README.md`](test_harness/mock_signalwire/README.md) — REST mock reference.
- [`test_harness/mock_relay/README.md`](test_harness/mock_relay/README.md) — RELAY mock reference, including the full server-initiated-push protocol.
- [`MOCK_RELAY_GAPS.md`](MOCK_RELAY_GAPS.md), [`MOCK_SIGNALWIRE_GAPS.md`](MOCK_SIGNALWIRE_GAPS.md) — methods/endpoints with known synthesis or schema gaps.
- [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md), `## Audit cleanup sweep methodology` — how to drive raw drift to zero after the mock-backed tests are passing.
- `scripts/audit_no_cheat_tests.py` — automated detection of cheat-tests; runs in CI.
