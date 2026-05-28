# CLAUDE.md — Front-Door Rules of Engagement

This is the first thing any agent (Claude, Codex, Cursor, etc.) should read when opening this repo. It's a 5-minute orientation; deeper docs are linked per topic. **Do not duplicate content here that's covered in the deeper docs — point at them.**

---

## 1. What this repo is

`porting-sdk/` is the cross-port shared infrastructure for the SignalWire SDK port matrix. **Python is the reference implementation.** Nine other ports (Go, TypeScript, Java, PHP, Ruby, Perl, Rust, C++, dotnet) target functional parity with Python using each language's idioms. All 10 ports (Python + 9) are bound to the shared mock servers and run the same 4-gate CI flow.

This repo holds the audit pipeline, the shared mock servers (REST + RELAY), the canonical Python surface oracle, the wire-shape schemas, and the methodology docs. **No port code lives here** — port code lives in the sibling `~/src/signalwire-<lang>/` repos.

---

## 2. The non-negotiable rules

- **Match Python exactly unless documented.** Every divergence between a port and the Python reference must be in that port's `PORT_OMISSIONS.md` / `PORT_ADDITIONS.md` / `PORT_SIGNATURE_OMISSIONS.md` with a one-line rationale. A "skip list" never means "stub"; it means we deliberately don't implement and we say why. See [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

- **Functional parity, not stylistic mimicry.** Each port uses its language's idioms — `Result<T,E>` in Rust, error returns in Go, Builder pattern in Java, factory functions in Go, etc. Don't reshape a port to look like Python; document the divergence in the port's omissions/additions file and move on. Drift count is a tool, not the goal.

- **Tests must drive real behavior.** No `mock.patch` / `MagicMock` of HTTP/WS transport. Each test pairs a behavioral assertion with a journal/wire assertion against the shared mocks. See [`MOCK_TEST_HARNESS.md`](MOCK_TEST_HARNESS.md) and the no-cheat-tests section of [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

- **TDD-bidirectional protocol** for missing functionality: Python test (write one if missing) → port the test → RED → implement → GREEN → commit. **Never stub. Never mark "TODO" — every port gets the actual source code.** See the TDD-bidirectional gap-fix section of [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

- **Verify with runnable programs, not by asking agents to read code.** The drift / coverage / cheat audits in `scripts/` are the source of truth. Re-run them; don't trust an agent's claim. Key tools: [`scripts/diff_port_signatures.py`](scripts/diff_port_signatures.py), [`scripts/audit_python_test_coverage.py`](scripts/audit_python_test_coverage.py), [`scripts/audit_no_cheat_tests.py`](scripts/audit_no_cheat_tests.py).

- **Adapter rename tables must update alongside source.** Adding a method to a port is half the work; the per-port adapter (`internal/surface/tables.go` / `_METHOD_RENAMES` / `MIXIN_PROJECTIONS` etc.) must also map native→Python or drift just shifts category, not count. See the adapter-rename-tables section of [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

- **Real gaps go on a separate-work list during cleanup sweeps.** Conservative discipline: if it's not clearly idiomatic divergence, list it as a real gap to fix rather than papering over with omissions/additions. See the audit-cleanup-sweep methodology section of [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

---

## 3. Agent-execution gotchas

- **Polling-pgrep is a self-deadlock.** A loop like `while pgrep -f "X" > /dev/null; do sleep N; done` matches the bash one-liner running the loop itself, because the bash command line contains "X" as a literal. The loop never exits. Use `Bash(run_in_background=true)` and the harness's completion notification + `Read` of the output file. See the polling-pgrep anti-pattern section of [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md).

- **Java: rebuild the JAR before re-enumerating.** Run `./gradlew --no-daemon build -x test` BEFORE re-running `enumerate_signatures.py` — the adapter reads the JAR and won't see new methods until rebuild.

- **PSR-4 multi-class file invisibility (PHP).** PHP autoloaders expect file-per-class. Classes co-located in one file are invisible to the audit's class enumerator. Split when adding new classes.

- **`pip install` is NOT required for the shared mocks.** Adjacency-based discovery walks `__file__` upward to find `porting-sdk/test_harness/<name>/` and prepends it to `sys.path` / `PYTHONPATH`. Cloning porting-sdk as a sibling of the port repo is sufficient. See the architecture section of [`MOCK_TEST_HARNESS.md`](MOCK_TEST_HARNESS.md).

---

## 4. Where things live

| File / Directory | Purpose |
|---|---|
| [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md) | Methodology rules, verification queries, sweep types, anti-patterns |
| [`PORTING_GUIDE.md`](PORTING_GUIDE.md) | Per-port porting playbook |
| [`MOCK_TEST_HARNESS.md`](MOCK_TEST_HARNESS.md) | Shared `mock_signalwire` (REST) + `mock_relay` (WS) infrastructure |
| [`RELAY_IMPLEMENTATION_GUIDE.md`](RELAY_IMPLEMENTATION_GUIDE.md) | RELAY WebSocket protocol spec — read before any RELAY work |
| [`webhooks.md`](webhooks.md) | Inbound webhook signature validation spec — read before any AgentBase / SWMLService work that exposes signed routes |
| [`ADAPTER_CONTRACT.md`](ADAPTER_CONTRACT.md) | What per-port enumerators must produce |
| [`PORT_DRIFT_INVENTORY.md`](PORT_DRIFT_INVENTORY.md) | Current per-port drift state |
| [`CI_PLAN.md`](CI_PLAN.md) | 3-layer CI architecture (Layer 1 per-port PR / Layer 2 cross-port matrix / Layer 3 nightly cron) |
| [`RELEASE_PIPELINE.md`](RELEASE_PIPELINE.md) | Deferred Layer 4: versioned-artifact release pipeline + per-port version pinning |
| [`python_signatures.json`](python_signatures.json) / [`python_surface.json`](python_surface.json) | Reference oracle (regenerate via `enumerate_python.py` / `enumerate_python_signatures.py`) |
| [`surface_schema_v2.json`](surface_schema_v2.json) / [`type_aliases.yaml`](type_aliases.yaml) / [`type_vocabulary.yaml`](type_vocabulary.yaml) | Schema definitions for the audit pipeline |
| `rest-apis/<namespace>/openapi.yaml` | REST contract sources (13 namespaces: calling, chat, compatibility, datasphere, fabric, fax, logs, message, project, pubsub, relay-rest, video, voice) |
| `relay-protocol/*.json` | RELAY contract sources (extracted from C# via [`scripts/extract_relay_schemas.py`](scripts/extract_relay_schemas.py)) |
| [`scripts/`](scripts/) | Audit + extraction tooling — every script supports `--help` |
| [`test_harness/mock_signalwire/`](test_harness/mock_signalwire/) | REST mock server package |
| [`test_harness/mock_relay/`](test_harness/mock_relay/) | RELAY WS mock server package |
| [`.github/workflows/cross-port.yml`](.github/workflows/cross-port.yml) | Layer 2 (PR/push) + Layer 3 (nightly cron) — 9-port matrix |
| [`.github/workflows/test.yml`](.github/workflows/test.yml) | Layer 1 for porting-sdk itself: pytest on mock_signalwire/mock_relay/audit_coverage_smoke |
| [`.github/workflows/audit-checklist.yml`](.github/workflows/audit-checklist.yml) | Checklist + Python surface freshness vs signalwire-python |

---

## 5. How to verify your work

The standard verification recipe — run from each port's repo root after generating that port's signature/surface JSON via its adapter:

```bash
# 1. Drift must be zero across signatures, surface omissions, and surface additions.
python3 ~/src/porting-sdk/scripts/diff_port_signatures.py \
  --reference ~/src/porting-sdk/python_signatures.json \
  --port-signatures ./port_signatures.json \
  --omissions ./PORT_SIGNATURE_OMISSIONS.md \
  --surface-omissions ./PORT_OMISSIONS.md \
  --surface-additions ./PORT_ADDITIONS.md

# 2. Tests must remain green (each port's native test runner).

# 3. If you wrote new tests, audit for cheat patterns.
python3 ~/src/porting-sdk/scripts/audit_no_cheat_tests.py --root ./tests
```

Exit code 0 from `diff_port_signatures.py` (with all 3 surface flags) is the bar. Anything else is a real gap or a missing entry in the omissions/additions docs.

---

## 6. Running the gates

Each port has [`scripts/run-ci.sh`](scripts/run-ci.sh) that runs the full gate set locally. Same script is invoked by the per-port GitHub Actions workflows and by porting-sdk's cross-port matrix. **No drift between local and CI behavior** — that's the design.

### CI auth: PORTING_SDK_TOKEN

`signalwire/porting-sdk` is private. Each port repo's CI workflows clone it via `actions/checkout@v4` with `token: ${{ secrets.PORTING_SDK_TOKEN }}` — a fine-grained PAT with `Contents: Read` on porting-sdk only, registered as a secret in each of the 10 SDK repos. porting-sdk's own `cross-port.yml` doesn't need the token because it clones itself (uses default `${{ github.token }}`) and pulls the public port repos.

```bash
# Per-port (run from inside any signalwire-<lang> repo)
bash scripts/run-ci.sh

# Cross-port (run from porting-sdk; runs PSDK's own tests + iterates 9 ports)
bash /usr/local/home/devuser/src/porting-sdk/scripts/run-cross-port-ci.sh
```

Each per-port script runs 4 gates in order: TEST → SIGNATURES → DRIFT → NO-CHEAT. Exit codes: `0` (all PASS), `1` (gate failure), `2` (porting-sdk not adjacent / not resolvable).

If the port is dotnet, the script also handles mock-server lifecycle (probe-then-spawn with cleanup trap) and per-framework serial execution (`net8.0` → `net9.0` → `net10.0`, not parallel — see the multi-process / multi-target concurrency section of [`MOCK_TEST_HARNESS.md`](MOCK_TEST_HARNESS.md) for why). Other ports' helpers do probe-or-spawn themselves via the per-test mocktest helper.

If a script doesn't exist in your port's repo yet, copy from `signalwire-typescript/scripts/run-ci.sh` (cleanest reference) and adapt the language-test command.

---

## 7. Per-port adjacency layout

The convention:

```
~/src/
  porting-sdk/                  <- this repo (cross-port infrastructure)
  signalwire-python/            <- reference implementation
  signalwire-go/
  signalwire-typescript/
  signalwire-java/
  signalwire-php/
  signalwire-ruby/
  signalwire-perl/
  signalwire-rust/
  signalwire-cpp/
  signalwire-dotnet/            <- in matrix; not yet bound to shared mocks
```

The shared mocks find each other via relative-path walk from a port's test file `__file__` upward to a `porting-sdk/test_harness/<name>/` sibling. **Cloning porting-sdk alongside the port repo is sufficient — no install steps required.**

---

## 8. Before you do anything

1. `git pull` (or at least `git fetch && git status`) in every repo you'll touch — porting-sdk and the port(s).
2. Read the relevant deeper doc for your task (see the table in section 4).
3. If you're going to write code: TDD-bidirectional. If you're going to verify a claim: re-run the audit script, don't trust an agent's read.
4. **Never push without user review.** Local commits are fine. `git push` is a separate gated action that requires explicit user instruction.
