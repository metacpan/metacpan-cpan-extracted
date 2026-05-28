# CI Plan

This doc captures the GitHub Actions wiring for the SignalWire SDK port matrix. The local runners (`scripts/run-ci.sh` per repo + `scripts/run-cross-port-ci.sh` here) implement the canonical gate set; the CI workflows just invoke them. **No drift between local and CI behavior** — that's the design.

Status (2026-05-07): **Layers 1–3 shipped and green**. Release pipeline (Layer 4 / version-pinning) deliberately deferred — see [`RELEASE_PIPELINE.md`](RELEASE_PIPELINE.md).

| Layer | Where | What | Status |
|---|---|---|---|
| 1 | each `signalwire-<lang>` repo | per-port PR gate (4-gate `run-ci.sh`) | ✅ all 10 repos |
| 2 | porting-sdk `cross-port.yml` | porting-sdk PRs fan out to all 9 ports | ✅ shipped |
| 3 | porting-sdk `cross-port.yml` (cron) | nightly full-matrix at 09:00 UTC | ✅ shipped |
| 4 | porting-sdk `release.yml` (TBD) | versioned artifacts so ports can pin | ⏸ deferred |

---

## 1. Architecture — three layers, each catching different failure modes

### Layer 1: per-repo PR gate

Runs on every PR to a port repo. Single GitHub Actions workflow per port, ~5–10 min.

```yaml
# .github/workflows/audit.yml in each signalwire-<lang>/ repo

name: audit
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { path: signalwire-<lang> }

      - uses: actions/checkout@v4
        with:
          repository: signalwire/porting-sdk
          ssh-key: ${{ secrets.PORTING_SDK_DEPLOY_KEY }}
          path: porting-sdk
          ref: main  # or pin to a known-good SHA

      - uses: actions/checkout@v4
        with:
          repository: signalwire/signalwire-python
          path: signalwire-python
          ref: main

      - name: install language toolchain
        # Go: actions/setup-go
        # TS:  actions/setup-node@v4 (Node 24)
        # Java: actions/setup-java@v4 (JDK 17+)
        # PHP: shivammathur/setup-php
        # Ruby: ruby/setup-ruby
        # Perl: shogo82148/actions-setup-perl
        # Rust: actions-rust-lang/setup-rust-toolchain
        # C++: cmake + clang already on ubuntu runners
        # dotnet: actions/setup-dotnet@v4 (or use the SDK Docker image)

      - name: setup Python (always — needed for the audit + mock servers)
        uses: actions/setup-python@v5
        with: { python-version: "3.12" }

      - name: install audit dependencies
        run: pip install -r ../porting-sdk/requirements.txt

      - name: run CI gates
        working-directory: signalwire-<lang>
        env:
          PORTING_SDK: ${{ github.workspace }}/porting-sdk
        run: bash scripts/run-ci.sh
```

### Layer 2: porting-sdk PR gate

A change to porting-sdk affects all ports — `python_signatures.json` regen, `rest-apis/*/openapi.yaml` changes, `relay-protocol/*.json` changes (regenerated from C# via `extract_relay_schemas.py`), schema/type-alias changes. Workflow:

```yaml
# .github/workflows/cross-port.yml in porting-sdk

name: cross-port
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  porting-sdk-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt
      - run: pip install -e test_harness/mock_signalwire test_harness/mock_relay
      - run: pytest tests/mock_signalwire/ tests/mock_relay/ tests/audit_coverage_smoke.py
      - run: python3 scripts/extract_relay_schemas.py --check

  per-port-audit:
    strategy:
      fail-fast: false
      matrix:
        port: [go, typescript, java, php, ruby, perl, rust, cpp, dotnet]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { path: porting-sdk }

      - uses: actions/checkout@v4
        with:
          repository: signalwire/signalwire-${{ matrix.port }}
          path: signalwire-${{ matrix.port }}
          ref: main

      - uses: actions/checkout@v4
        with:
          repository: signalwire/signalwire-python
          path: signalwire-python
          ref: main

      - name: install language toolchain (per matrix.port)
        # ...

      - run: bash scripts/run-ci.sh
        working-directory: signalwire-${{ matrix.port }}
        env:
          PORTING_SDK: ${{ github.workspace }}/porting-sdk
```

Catches "I added a new RELAY method to the schema but X port doesn't have it yet" before the porting-sdk PR merges.

### Layer 3: nightly cross-repo full-matrix

Same as Layer 2 but pulling each port at HEAD (not pinned). Catches drift between port repos that merged after the last cross-repo run. Optional but useful early-warning.

```yaml
# .github/workflows/nightly.yml in porting-sdk
on:
  schedule: [{ cron: "0 9 * * *" }]  # 09:00 UTC daily
  workflow_dispatch: {}              # manual trigger
```

Same matrix as Layer 2 but no pinned `ref` — uses each port's main HEAD.

---

## 2. The gate set (same locally and in CI)

Each per-port `bash scripts/run-ci.sh` runs 4 gates in order. Exit non-zero on first failure (or aggregates). Output format: `[GATE-NAME] ... PASS|FAIL: <reason>` per line, final `==> CI PASS` or `==> CI FAIL (gates: <list>)`.

| # | Gate | Command (per port) | Blocks PR? |
|---|---|---|---|
| 1 | TEST | `go test ./...` / `npx vitest run` / `gradle test` / `phpunit` / `rake test` / `prove t/` / `cargo test --tests -- --test-threads=1` / `cmake --build && ./build/run_tests` / `dotnet test` / `pytest tests/unit/` | ✅ |
| 2 | SIGNATURES | per-port enumerator regen of `port_signatures.json` (Java needs `gradle build` first; C++ needs cmake; dotnet needs `dotnet build` without `--no-restore`) | ✅ |
| 3 | DRIFT | `python3 ../porting-sdk/scripts/diff_port_signatures.py --reference ... --port-signatures port_signatures.json --surface-omissions PORT_OMISSIONS.md --surface-additions PORT_ADDITIONS.md --omissions PORT_SIGNATURE_OMISSIONS.md` — must show 0 drift | ✅ |
| 4 | NO-CHEAT | `python3 ../porting-sdk/scripts/audit_no_cheat_tests.py --root .` — must report clean | ✅ |

Cross-port `bash scripts/run-cross-port-ci.sh` adds:

| # | Gate | Command |
|---|---|---|
| 1a | PSDK-TESTS | `pytest tests/mock_signalwire/ tests/mock_relay/ tests/audit_coverage_smoke.py` |
| 1b | RELAY-SCHEMA-SYNC | `python3 scripts/extract_relay_schemas.py --check` (drift-detect for the C# → JSON-schema extractor) |
| 2 | PER-PORT (×9) | invokes each port's `bash scripts/run-ci.sh` |
| 3 | DRIFT-SUMMARY | per-port filtered drift count, advisory only |

---

## 3. Per-port quirks the CI workflows must honor

### Java
Rebuild the JAR before regenerating signatures:
```bash
./gradlew --no-daemon build -x test
python3 scripts/enumerate_signatures.py
```
Without rebuild, the adapter reads a stale JAR and won't see new methods.

### C++
`enumerate_signatures.py` walks headers via libclang — takes ~3 min on a cold cache. Cache friendly between runs. cmake build also needed before tests.

### dotnet
- **Use Docker** (`mcr.microsoft.com/dotnet/sdk:10.0` + `--network host`) — `dotnet` not necessarily in PATH on every runner.
- **Multi-target races on shared mock servers** — net8/net9/net10 in parallel will stomp on each other's journal state. The local `scripts/run-ci.sh` already runs frameworks sequentially via a `dotnet_test_per_framework` loop. CI must invoke that script (don't reach for raw `dotnet test` in the workflow YAML).
- **Mocks must be running on host before the docker run** — the script's probe-then-spawn handles this; CI just needs Python on the runner so the spawn can succeed.

### Rust
- Run `cargo test -- --test-threads=1` always (in-binary mock journal can race even with single-binary runs).
- **Cross-binary cargo concurrency**: each `tests/*.rs` is a separate binary. The shared mock_relay broadcasts to ALL connected sessions across binaries. `tests/common/relay_mocktest.rs` uses `flock(LOCK_EX)` on `/tmp/signalwire-rust-mock-relay.lock` plus `wait_for_no_sessions(2s)` to serialize. CI runners must allow the lockfile to be writable.

### TypeScript
Use Node 24 — vitest 4.x has a `node:util styleText` import that fails on Node 18 and Node 20. The local script handles this via a hardcoded path; CI uses `actions/setup-node@v4` with `node-version: 24`.

### Perl
`prove -Ilib -It/lib t/` is the canonical entry. Adapter regen via `python3 scripts/enumerate_signatures.py` after `prove`.

### Ruby
`bundle install` then `bundle exec rake test` (or however the repo's existing runner is invoked — check the Rakefile in each port).

### Go
`go test ./...` covers everything. Adapter regen via `go run ./cmd/enumerate-signatures > port_signatures.json`.

### PHP
`vendor/bin/phpunit` after `composer install --no-interaction`. Adapter regen via `python3 scripts/enumerate_signatures.py`.

### Python (signalwire-python)
The SIGNATURES gate regenerates the *reference* (`python_signatures.json` over in `../porting-sdk/`). Treat the reference as immutable from this side — if regen produces a diff, it means the Python source legitimately changed and the cross-port matrix needs to re-audit. Layer 2/3 catches that.

---

## 4. Cross-repo dependency: porting-sdk is private

`signalwire/porting-sdk` is **PRIVATE**. The 10 SDK repos are PUBLIC. CI workflows in the public repos that need to clone porting-sdk will fail without credentials.

### Options

1. **Deploy key per port repo** (recommended). Generate one SSH keypair, register the public half as a deploy-key on `signalwire/porting-sdk` (read-only), the private half as `secrets.PORTING_SDK_DEPLOY_KEY` in each port repo. `actions/checkout@v4` uses it via the `ssh-key:` input shown above.

2. **Fine-grained PAT** with `Contents: Read` on `signalwire/porting-sdk` only. Stored as a secret in each port repo.

3. **Make porting-sdk public**. Trade-off: simplifies CI but exposes the audit machinery + cross-port test contracts. Not necessarily a problem (the per-port mocks already shipped publicly via the SDKs), but worth a deliberate decision.

### Cross-org consumers

If someone outside SignalWire forks a port repo and tries to run CI, the porting-sdk checkout fails. Their tests skip cleanly via the adjacency-discovery walker — that's the design (see `MOCK_TEST_HARNESS.md` "Adjacency-based discovery" section). The CI workflow should treat "porting-sdk not adjacent" as a passing-with-warning state, not a fail, so external forks aren't blocked.

---

## 5. Cost estimates per Layer 1 run

Per-port wall time (approximate, on a clean GitHub-hosted runner):

| Port | Wall time | Notes |
|---|---:|---|
| Python | 2–3 min | pytest -q is fast |
| Ruby | 2–3 min | minitest |
| PHP | 2–3 min | phpunit |
| Perl | 2–4 min | prove |
| Go | 2–3 min | `go test ./...` |
| TypeScript | 4–5 min | vitest + Node 24 |
| Rust | 5–7 min | cargo test, esp. integration tests with mock spawn |
| Java | 6–8 min | gradle JAR rebuild + adapter regen |
| C++ | 8–12 min | cmake + libclang for the enumerator |
| dotnet | 8–10 min | Docker pull + build + test on net8/9/10 sequentially |

With matrix-parallel workers, a Layer 2 run takes ~12 min (slowest port). Layer 1 PR feedback per language is ≤10 min — acceptable.

---

## 6. Setup checklist (mechanical, ~12–16 hours of work)

1. Generate SSH deploy key for `signalwire/porting-sdk`, add as `secrets.PORTING_SDK_DEPLOY_KEY` in each of the 10 SDK repos.
2. Write `.github/workflows/audit.yml` once (template above), copy with port-specific tweaks into each of the 10 SDK repos. Per-repo PR + push triggers. Each one calls `bash scripts/run-ci.sh`.
3. Write `.github/workflows/cross-port.yml` in porting-sdk with the 9-port matrix. Triggers on porting-sdk PR + push.
4. Write `.github/workflows/nightly.yml` in porting-sdk with the same matrix on a `schedule:` trigger.
5. Optionally: `.github/workflows/release.yml` in porting-sdk that publishes `python_signatures.json` + `relay-protocol/*.json` + the `mock_*` packages as a versioned release artifact, so per-port CIs can pin to a specific porting-sdk version rather than always-HEAD.

Could be dispatched as 11 small parallel agents (~2–3 hours wall time) — one per repo for the workflow YAML, plus porting-sdk's two workflows.

---

## 7. Local equivalent (already shipped)

To run the same gate set locally, no install needed beyond the language toolchain and a Python 3.12.

### One-time setup: clone the matrix

Adjacency contract: `~/src/porting-sdk/` adjacent to each `~/src/signalwire-<lang>/`. The mocks find each other via relative-path walk; **no pip-install required** (see `MOCK_TEST_HARNESS.md` "Adjacency-based discovery" section).

Clone all 11 repos side-by-side:

```bash
mkdir -p ~/src && cd ~/src

# Cross-port infrastructure (PRIVATE — needs read access on signalwire/porting-sdk)
git clone git@github.com:signalwire/porting-sdk.git

# Reference implementation (the spec for all other ports)
git clone git@github.com:signalwire/signalwire-python.git

# 9 port repos
for lang in go typescript java php ruby perl rust cpp dotnet; do
    git clone git@github.com:signalwire/signalwire-$lang.git
done
```

Or as a one-liner:

```bash
mkdir -p ~/src && cd ~/src && \
for r in porting-sdk signalwire-{python,go,typescript,java,php,ruby,perl,rust,cpp,dotnet}; do
    git clone git@github.com:signalwire/$r.git
done
```

Resulting layout:

```
~/src/
  porting-sdk/                ← cross-port infra + audit machinery + mock servers
  signalwire-python/          ← reference implementation
  signalwire-go/
  signalwire-typescript/
  signalwire-java/
  signalwire-php/
  signalwire-ruby/
  signalwire-perl/
  signalwire-rust/
  signalwire-cpp/
  signalwire-dotnet/
```

If you only have one port checked out, the per-port `scripts/run-ci.sh` will detect the missing porting-sdk and skip the gates that depend on it (drift + no-cheat audit) with a clear message — so cloning just porting-sdk + the one port you're working on is enough; cross-port aggregation requires all 11.

### Required toolchains

Install whatever languages you intend to test. Audit always needs Python 3.12+:

| Need to test | Tools |
|---|---|
| Python | python 3.12+, `pip install -r porting-sdk/requirements.txt` |
| Go | go 1.21+ |
| TypeScript | Node 24+ (vitest 4.x requires `node:util.styleText`; Node 18/20 will fail) |
| Java | JDK 17+ + gradle wrapper |
| PHP | PHP 8.2+ + composer |
| Ruby | Ruby 3.x + bundler |
| Perl | Perl 5.32+ + cpanm |
| Rust | rustup with stable channel |
| C++ | cmake 3.20+ + clang/gcc + libclang (for the signature enumerator) |
| dotnet | Docker (`mcr.microsoft.com/dotnet/sdk:10.0`) — no native install required |

### Running the gates

```bash
# Per-port (run from inside any signalwire-<lang> repo)
cd ~/src/signalwire-<lang>
bash scripts/run-ci.sh

# Cross-port (run from porting-sdk; runs PSDK's own tests + iterates all 9 ports)
cd ~/src/porting-sdk
bash scripts/run-cross-port-ci.sh
```

Each per-port script runs 4 gates in order: TEST → SIGNATURES → DRIFT → NO-CHEAT, with `[GATE-NAME] ... PASS|FAIL: <reason>` per line, final `==> CI PASS` or `==> CI FAIL (gates: <list>)`. Exit 0 (all PASS), 1 (gate failure), 2 (porting-sdk not adjacent).

Cross-port adds two PSDK-side gates (`PSDK-TESTS` and `RELAY-SCHEMA-SYNC`) plus a per-port drift summary at the end.

### Updating the matrix

```bash
# Pull all repos (run from ~/src/)
for r in porting-sdk signalwire-{python,go,typescript,java,php,ruby,perl,rust,cpp,dotnet}; do
    (cd $r && git pull)
done
```

If a port adds a new RELAY method (in `~/src/switchblade/RelayPlugin/Calling/PublicCall<X>{Params,Result}.cs` or in `~/src/mod_infrastructure/relay.c`), regenerate the cross-port schemas:

```bash
cd ~/src/porting-sdk
python3 scripts/extract_relay_schemas.py    # regenerates relay-protocol/*.json
```

The mock_relay server auto-loads new schemas on next start; per-port mocktest helpers don't need code changes.

---

## 8. References

- `MOCK_TEST_HARNESS.md` — shared mock infrastructure architecture
- `AUDIT_DISCIPLINE.md` — methodology rules, sweep types, anti-patterns
- `RELAY_IMPLEMENTATION_GUIDE.md` — RELAY WebSocket protocol spec
- `PORT_DRIFT_INVENTORY.md` — current per-port drift state
- `CLAUDE.md` — front-door rules of engagement (includes Running the gates section)
- `scripts/diff_port_signatures.py --help` — drift gate
- `scripts/audit_no_cheat_tests.py --help` — cheat gate
- `scripts/extract_relay_schemas.py --help` — RELAY schema extractor (with `--check` for CI)
