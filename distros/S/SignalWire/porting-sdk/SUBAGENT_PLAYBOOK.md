# SUBAGENT_PLAYBOOK.md

How to dispatch sub-agents for SignalWire SDK port work. This file is the canonical reference for any Claude (or human) controlling sub-agents on these repos. Read it before writing an agent prompt.

The playbook exists because sub-agent dispatches that didn't follow it have failed in three specific ways:

1. **Force-pushed Go on 2026-04-28**, erasing 20 PR-merged commits from other devs (recovery merge restored them, but the rule was tightened: never push without explicit user review).
2. **Killed mid-flight Rust agent on 2026-04-29** that was about to push without review — would have shipped a partial, untested CLI HTTP fix.
3. **Killed PHP/Ruby/Perl/Java/.NET/Go/C++ agents on 2026-04-29** that were going to push 6 parallel commits with no review opportunity.

The playbook below codifies the rules that prevent those failures.

---

## Mandatory rules every dispatch enforces

These appear verbatim near the top of every agent prompt. Non-negotiable.

1. **Pull first.** `git -C <port> fetch origin && git -C <port> pull --ff-only origin main`. Before reading any code. Verify clean working tree before proceeding.
2. **Do NOT push.** Local commits only. The agent ends with `git status` showing N commits ahead of origin/main and reports those SHAs in its final report. Pushing is a separate human-gated step.
3. **Match Python exactly** unless the deviation is recorded in `PORT_OMISSIONS.md` with rationale. Python reference path: `/home/devuser/src/signalwire-python/signalwire/signalwire/`.
4. **Read the docs in full** before writing code:
   - `/usr/local/home/devuser/src/porting-sdk/PORTING_GUIDE.md` — especially "Production Code Discipline" (forbidden patterns, what tests must do, what examples must do, allow-list categories)
   - `/usr/local/home/devuser/src/porting-sdk/CHECKLIST_TEMPLATE.md` — Verification Discipline rules 1-9
   - `/usr/local/home/devuser/src/porting-sdk/INTENTIONAL_NON_IMPLEMENTATION.md` — the four legitimate categories for allow-list entries
   - The audit programs that will run as receipts — agents must read each one's first ~50 lines (the docstring) so they know the harness contract for each.
5. **Audits are receipts, not optional.** Every fix-mode dispatch ends by running the relevant audit programs and pasting exit codes in the final report. Agents are NOT believed without green program output. The main session re-runs the audits to verify; agents are not trusted on their word.
6. **Time-box substantial work.** If the agent hits a real blocker (compile error after 30+ minutes, architectural ambiguity), STOP and report it in section 4 of the report rather than papering over with a stub.
7. **No cheat tests.** A test that asserts a stub's canned output (e.g. `assert!(parsed.is_array())` against a `[]` return) is a violation; rewrite to assert real behavior, don't delete.
8. **Allow-list line numbers shift.** When the agent removes/adds code in a file with `INTENTIONAL_NON_IMPLEMENTATION.md` entries, line numbers move. After every substantive edit, re-run audit_stubs.py and update the allow-list line numbers if they shifted.
9. **Commit boundaries.** Multiple small reviewable commits, not one megacommit. Each commit message explains WHY (matching Python), lists what changed, and pastes audit exit codes verifying the commit.

---

## Dispatch modes — be explicit

Every agent prompt MUST clearly state which mode the agent is operating in. Agents that don't know whether to investigate-and-report or actually-fix-things produce ambiguous, partial work.

### Mode A: AUDIT only

Use when you want the agent to investigate, run audits, report findings — NOT change code.

Required prompt language:
> You are operating in **AUDIT-ONLY mode**. Do NOT modify any source code, do NOT add tests, do NOT add examples. Run the listed audits, capture exit codes and detailed output, return a report. Your final commit count is 0; you should not run `git commit` under any circumstances.

What the agent reports: per-audit exit code, top-N findings, recommendation for next steps. The user (or main session) decides what to fix.

### Mode B: FIX only (you've already audited)

Use when the audit work is already done and you've handed the agent a precise list of file:line items to fix.

Required prompt language:
> You are operating in **FIX-ONLY mode**. The audit phase has already happened. Below is the explicit list of items to fix, with file:line references and the desired behavior for each. Do NOT explore the repo for other gaps — only fix what's listed. After fixing, run the listed audits to confirm your fixes hold, paste exit codes, commit locally only.

The prompt must include:
- Explicit file:line list of what to change
- For each item: a 1-3 line description of the desired-behavior, with reference to a Python source file (file:line:method_name)
- The audit programs to run as receipts after fixing
- Exit-code expectations (e.g., "audit_stubs must drop from 5 to 0; audit_relay_handshake must go from exit 3 to exit 0")

### Mode C: AUDIT + FIX (most common)

Use for whole-port fix work. The agent both surfaces the issues and fixes them.

Required prompt language:
> You are operating in **AUDIT + FIX mode**. Run the listed audits to surface issues, fix every issue surfaced (matching Python's behavior), re-run the audits to confirm clean, commit locally per logical chunk. Do NOT push.

The prompt must include all of Mode B's items PLUS:
- Permission to explore the port for other gaps the audit might miss
- Explicit "if you find something not in the audit's scope but is clearly a stub or violates the parity rule, fix it and document in your report"

---

## The full prompt template

Every prompt is built from this template. Sections in `<ANGLE BRACKETS>` are filled in per dispatch.

```
You are completing the <PORT_NAME> SDK port (<ABS_PATH_TO_PORT_REPO>) per the
SignalWire SDK production-code-discipline rules. This is real engineering
work — no stubs, no shortcuts.

## NON-NEGOTIABLE RULES (read carefully)

1. **Pull first.** Before reading anything else, run
   `git -C <ABS_PATH_TO_PORT_REPO> fetch origin && git -C <ABS_PATH_TO_PORT_REPO> pull --ff-only origin main`.
   Confirm clean working tree before proceeding.

2. **DO NOT push to origin.** Local commits only. Wait for the user to review.
   Final report includes the local commit SHAs but you do NOT run
   `git push` under any circumstances.

3. **Read these docs IN FULL before writing any code:**
   - /usr/local/home/devuser/src/porting-sdk/PORTING_GUIDE.md (esp. "Production Code Discipline")
   - /usr/local/home/devuser/src/porting-sdk/CHECKLIST_TEMPLATE.md (Verification Discipline rules 1-9)
   - /usr/local/home/devuser/src/porting-sdk/INTENTIONAL_NON_IMPLEMENTATION.md (allow-list categories)
   - /usr/local/home/devuser/src/porting-sdk/SUBAGENT_PLAYBOOK.md (this file)
   - The audit programs you will run as receipts (read each one's docstring,
     lines 1-50):
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_stubs.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_no_cheat_tests.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_http_swml.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_relay_handshake.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_skills_dispatch.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_rest_transport.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_example_parity.py
     - /usr/local/home/devuser/src/porting-sdk/scripts/audit_test_parity.py

4. **Match Python exactly** unless the deviation is recorded in PORT_OMISSIONS.md
   with rationale. Python reference: /home/devuser/src/signalwire-python/signalwire/signalwire/.
   Specific files for this work:
   <LIST_OF_RELEVANT_PYTHON_FILES>

5. **Allow-list line numbers shift when you add/remove code.** After every
   substantive edit to a file with allow-list entries, re-run audit_stubs.py
   and update INTENTIONAL_NON_IMPLEMENTATION.md if line numbers shifted.

6. **Tests that ratify stubs are themselves bugs.** If you find a test
   asserting a stub's canned output, rewrite the test to assert real
   behavior, don't delete it.

7. **Commit boundaries:** make multiple small reviewable commits. Each
   commit message explains WHY (matching Python, etc.) and pastes the
   audit exit codes verifying the commit.

## MODE: <AUDIT | FIX | AUDIT+FIX>

<MODE_SPECIFIC_INSTRUCTIONS — see "Dispatch modes" in the playbook>

## ARCHITECTURE NOTES FOR THIS PORT

<PORT_SPECIFIC_NOTES — e.g., for Rust: "AgentBase uses Deref<Target=Service>;
AgentBase has its own handle_request that intercepts /post_prompt before
falling through to Service. The relay code is sync (Mutex everywhere, no
Tokio); pick sync tungstenite over async tokio-tungstenite to avoid a
Tokio refactor.">

## WHAT NEEDS DOING

<TASK_LIST — see "Per-task structure" below>

## REPORT FORMAT (mandatory)

Your final response must contain:

1. **Files changed/created** with brief descriptions (file path + 1-line "what").
2. **Local commit SHAs** in order, with one-line subjects each.
3. **Audit exit codes** — table of every audit run with exit code and the
   script's one-line summary. ALL relevant audits, not just the ones that
   passed.
4. **Difficulties / decisions** — explicitly call out:
   - Where Python's reference was unclear or didn't translate cleanly
   - Architecture choices made without explicit guidance
   - Tests that ratified stubs and had to be rewritten
   - Allow-list adjustments needed after line-number shifts
   - Any audit that exit-1'd that you couldn't make exit-0 — explain why
5. **NOT pushed** confirmation: "git status shows N commits ahead of
   origin/main; no `git push` was run."

Time budget: real engineering. Don't rush. Hit a genuine blocker → STOP and
report it in section 4 rather than papering over with a stub.

Begin by pulling and reading the docs.
```

---

## Per-task structure (used inside the prompt template)

Every task in `<TASK_LIST>` follows this shape:

```
### Task <LETTER>: <ONE-LINE SUMMARY>

**Goal:** <one paragraph — what the user-visible outcome is>

**Python reference:**
- <abs path>:<line range> — <what's there>
- <abs path>:<line range> — <what's there>

**Files to change:**
- <abs path> — <what to change>
- <abs path> — <what to change>

**Constraints:**
- <e.g. "Don't introduce new public API; match Python's signature exactly">
- <e.g. "Don't break existing tests — rewrite stub-asserting ones; new tests must drive real behavior">

**Receipts:**
- <audit command> must exit 0 (or "must drop from N to 0")
- <test command> must show "<test name> ok"
```

A task without a Python reference is suspect — the agent should ask before guessing.

---

## Audit programs — what each proves and what its harness contract is

### `audit_stubs.py`
- **Proves:** No stub function bodies. Forbidden patterns: "stub: in production", canned-error strings, NotImplementedError-with-stub-message, silent-canned-data (function with `_param`-prefixed args returning a fixed literal).
- **Allow-list:** `<port>/INTENTIONAL_NON_IMPLEMENTATION.md` — entries `- <file:line> — <one-line justification>`. Four allowed categories: optional-extra import guards, abstract base methods, documented platform restrictions, cross-API no-op shims.
- **Hard-coded** in the script — no per-port harness needed.

### `audit_no_cheat_tests.py`
- **Proves:** No tests that pass without doing work. Forbidden: `assert true`/`assert(1==1)`, empty test bodies, tests with no assertion, nullness-only checks (`assertNotNull`/`is not None` without content checks).
- **Allow-list:** `<port>/INTENTIONAL_THIN_TESTS.md`.
- **Hard-coded.**

### `audit_http_swml.py`
- **Proves:** Each port's `swmlservice_swaig_standalone` example serves real SWML on `GET /<route>` and dispatches a real handler on `POST /<route>/swaig`. Catches dispatcher stubs.
- **Harness contract:** `examples/swmlservice_swaig_standalone.{ext}` must respect `PORT` env var, register a `lookup_competitor` tool that returns text containing both "ACME" and "$79" when called with `competitor=ACME`.

### `audit_relay_handshake.py`
- **Proves:** RELAY client opens a real WebSocket, runs the JSON-RPC `signalwire.connect` handshake, parses auth response, subscribes contexts, dispatches inbound events.
- **Harness contract:** `examples/relay_audit_harness.{ext}` reads `SIGNALWIRE_RELAY_HOST`, `SIGNALWIRE_RELAY_SCHEME`, `SIGNALWIRE_PROJECT_ID`, `SIGNALWIRE_API_TOKEN`, `SIGNALWIRE_CONTEXTS`. Connects to `<scheme>://<host>/api/relay/ws`, sends connect+subscribe, waits up to 5s for an event, dispatches it via the on-event callback (the callback must explicitly emit a `method: "signalwire.event"` frame back so the audit fixture sees it), exits 0.

### `audit_skills_dispatch.py`
- **Proves:** Each network skill issues a real outbound HTTP request to the configured URL (proves transport real, not canned). 6 skills probed: `web_search`, `wikipedia_search`, `api_ninjas_trivia`, `weather_api`, `datasphere`, `spider`.
- **Harness contract:** `examples/skills_audit_harness.{ext}` reads `SKILL_NAME`, `SKILL_FIXTURE_URL`, `SKILL_HANDLER_ARGS` (JSON), per-skill upstream env var (e.g. `WEB_SEARCH_BASE_URL`), per-skill credential env vars. Loads the named skill, points it at `SKILL_FIXTURE_URL`, invokes the handler, prints parsed return as JSON, exits 0.

### `audit_rest_transport.py`
- **Proves:** Each port's REST client issues real HTTP with documented method/path/Basic-auth shape. 5 operations probed: `calling.list_calls`, `messaging.send`, `phone_numbers.list`, `fabric.subscribers.list`, `compatibility.calls.list`.
- **Harness contract:** `examples/rest_audit_harness.{ext}` reads `REST_OPERATION` (dotted name), `REST_FIXTURE_URL`, `REST_OPERATION_ARGS` (JSON), `SIGNALWIRE_PROJECT_ID`, `SIGNALWIRE_API_TOKEN`, `SIGNALWIRE_SPACE`. Constructs a REST client pointed at the fixture URL, invokes the named operation, prints parsed return as JSON, exits 0.

### `audit_test_parity.py`
- **Proves:** Every Python test (minus skip list) has a port-equivalent.
- **LIMITATION:** BDD-style `it('text')` test names don't auto-map to Python's `test_snake_case` — large false-positive miss reports on first run for ports using BDD style. Resolve by either renaming or recording in `PORT_TEST_OMISSIONS.md`.
- **No harness.**

### `audit_example_parity.py`
- **Proves:** Every Python example (minus skip list — search/pgvector/sigmond/bedrock) has a port-equivalent.
- **Allow-list:** `<port>/PORT_EXAMPLE_OMISSIONS.md`.
- **No harness.**

### `diff_port_surface.py` (existing)
- **Proves:** Every Python public symbol (class, function, method, module attribute) has a port equivalent named with the Python-canonical symbol path.
- **Requires:** `<port>/port_surface.json` (generated by per-port `enumerate_<lang>` script — currently SHIPS in Java, Ruby, Perl, C++, Go; MISSING in TypeScript, PHP, .NET, Rust). Per-port enumerate scripts must be written for the 4 missing ports.
- **Allow-list:** `<port>/PORT_OMISSIONS.md` and `<port>/PORT_ADDITIONS.md`.

### `audit_docs.py` (existing)
- **Proves:** Every method referenced in a port's docs/examples resolves in `port_surface.json`. Requires `port_surface.json`.
- **Allow-list:** `<port>/DOC_AUDIT_IGNORE.md`.

### `audit_checklist.py` (existing)
- **Proves:** Counts in CHECKLIST.md (41 SwaigFunctionResult action methods, 38 SWML verbs, 17 skills) match Python reference.
- **Hard-coded counts derived from Python ref.**

---

## Per-port architecture notes (must include in agent prompt)

These are gotchas that bit prior agent runs. Include the relevant ones in the `## ARCHITECTURE NOTES FOR THIS PORT` section.

### Rust
- `AgentBase` uses `Deref<Target=Service>` for inheritance; AgentBase has its own `handle_request` that intercepts `/post_prompt` before falling through to Service.
- The relay code is sync (`Mutex<...>` everywhere, no Tokio). Pick `tungstenite = "0.24"` (sync) over async `tokio-tungstenite` to avoid a Tokio refactor.
- Reader thread needs access to `Client` state — change `connect()` from `&self` to `self: &Arc<Self>`. The codebase already uses Arc<Call>/Arc<Message> idiom.
- `MaybeTlsStream::Plain` is `try_clone`-able but TLS variants aren't — pick the single-mutex socket model (read AND write through one mutex with mpsc channel for write contention).
- Cargo example convention: `examples/<name>.rs`, build with `cargo build --release --example <name>`.

### Go
- `pkg/agent/AgentBase` embeds `*swml.Service`. After my SWAIG-lift refactor, AgentBase no longer redeclares name/route/host/port/auth fields — they come from the embedded Service.
- Examples convention: `examples/<name>/main.go`. Build with `go build -o <bin> ./examples/<name>`.
- 4/28 force-push erased 20 PR commits; recovery merge restored them. Anything in `pkg/relay/...` from PRs #133-#176 is real and must not be regressed.

### .NET
- This host has NO `dotnet` SDK installed. Agents working on .NET must do source-audit only and document explicitly that `dotnet build` / `dotnet test` were not run; user must verify on a machine with the SDK installed.
- Service uses `_tools` / `_toolOrder` protected dicts. Public `Tools` accessor was added; reflection-based CLI loaders use it.

### Java
- Agent test framework: gradle. `gradle test` for the suite.
- Examples: `examples/<Name>.java` in default package (no `package` declaration). FQCN is just the class name.
- Build classpath needs gradle prep before reflection-based loaders work.

### PHP
- Composer-based. `./vendor/bin/phpunit` for tests.
- Logger.php uses bare `STDERR` inside namespace `SignalWire\Logging` — should be `\STDERR`. Failed under `php -S` per prior audit. **Fix this when touching that file.**
- 9 known stubs: 3 in `src/SignalWire/Relay/Client.php` (lines ~92, ~244, ~252), 8 in `src/SignalWire/Skills/Builtin/*.php`.

### Ruby
- `bundle exec rake test` for the suite.
- `lib/signalwire/swml/service.rb`'s `serve` method had a `Rack::Handler::WEBrick` issue against Rack 3.2.5; fixed in commit `7837101`. If touching that file, preserve the rackup-gem fallback.

### Perl
- `prove -lr t/` for the suite.
- ContextBuilder fix: `lib/SignalWire/Contexts.pm` already has the FULL DSL implementation. The bug is `lib/SignalWire/Agent/AgentBase.pm` does `require SignalWire::Contexts::ContextBuilder` which loads the 28-line stub instead. Fix: point at the real one and delete the stub OR replace the stub file's contents.

### C++
- CMake-based. `cmake --build build` and `cmake --build build --target <example>` for individual examples.
- One known stub: `// TODO: token validation hook would go here` in relay code.

### TypeScript
- `npm test` runs vitest. Examples run via `npx tsx <path>` because Node 18+ doesn't natively load .ts.
- BDD-style tests (`it('text')`) — `audit_test_parity` will report many false-positive misses; resolve via PORT_TEST_OMISSIONS.md or renames.

### Python
- The reference SDK. Most audits should be clean here. Search-related code is in `signalwire/search/` and is in skip lists.
- `Logger.py:118 STDERR` no longer applies (PHP-only).

---

## Port_surface.json status (gating diff_port_surface and audit_docs)

| Port | enumerate script | port_surface.json | gates audit_docs / diff_port_surface |
|---|---|---|---|
| Python | `scripts/enumerate_python.py` (in porting-sdk) | n/a (it IS the reference) | n/a |
| TypeScript | **MISSING** | **MISSING** | **BLOCKED** until written |
| PHP | **MISSING** | **MISSING** | **BLOCKED** |
| .NET | **MISSING** | **MISSING** | **BLOCKED** |
| Java | `scripts/enumerate_surface.py` | present | usable |
| Ruby | `scripts/enumerate_surface.rb` | present | usable |
| Perl | `scripts/enumerate_surface.pl` | present | usable |
| C++ | `scripts/enumerate_surface.py` | present | usable |
| Go | `cmd/enumerate-surface` | present | usable |
| Rust | **MISSING** | **MISSING** | **BLOCKED** until written |

For ports flagged BLOCKED: each AUDIT+FIX dispatch must include a task to write the enumerate script (if missing) before audit_docs / diff_port_surface can be run as receipts.

---

## Lessons learned — track new ones here

### From the killed agents (2026-04-29)

- **Composer permissions issue** (PHP relay): `composer.lock` had wrong owner from a prior run. Agent stopped at the perms issue. Sub-agents need `chown` permission OR the prompt should pre-fix permissions.
- **Stale build dirs** (Java): `.gradle.old-root-owned/` and `build.old-root-owned/` left from prior owner. Same root-cause as above.
- **Discovery during read** (Perl): agent found that `Contexts.pm` already had the full DSL, but `ContextBuilder.pm` was the stub. The fix is a 1-line `require` change, NOT writing 600 lines of new code. The prompt now flags this in the per-port architecture notes.
- **Force-push history gap** (Go): the 4/28 force-push erased 20 PRs. Any agent touching Go must understand that `pkg/relay/*.go` PR-merged content from #133-#176 is real and recently-restored; not to be regressed.

### From the successful Rust agent (2026-04-29)

- **`signalwire.connect` shape** — Python sends params nested under `authentication`. The audit fixture watches the top level too. Agent emitted both. Future agents: replicate the dual emission OR document the deviation.
- **`signalwire.event` ack semantics** — Python ack is `{jsonrpc, id, result:{}}` (no method field). Audit fixture only marks event-dispatched on a frame with `method == "signalwire.event"` from the client. Harness explicitly emits the method-bearing frame inside `on_event` callback. Documented in harness.
- **DataMap-based skills** — `api_ninjas_trivia` and `weather_api` are DataMap-based per Python (the platform fetches the URL). Audit expects the SDK to issue HTTP. Harness simulates the platform by extracting the webhook URL from the DataMap and executing the GET itself. Document this in harness.
- **Audit script bugs** — `audit_skills_dispatch` and `audit_rest_transport` originally matched `src/skills/`/`src/rest/` greedily, picking TS first regardless. Fixed by requiring `package.json` for TS and `Cargo.toml` for Rust. **The audit programs themselves can be wrong**; an agent that finds an audit misbehaving should fix the audit and document it.
- **`port_surface.json` MISSING for 4 ports** (TS, PHP, .NET, Rust). Agents working on those ports must write `enumerate_<lang>.<ext>` as part of their work to enable diff_port_surface and audit_docs.

---

## Choosing the next port to dispatch

Order by complexity/value if working through the whole list:

1. **PHP** — biggest concrete workload (3 relay stubs + 8 skill stubs). Best stress test for the playbook.
2. **.NET** — relay client + source-audit only (no dotnet on host). Good for catching playbook gaps around verification-without-build.
3. **Perl** — small (1 stub: ContextBuilder pointer fix is 1-line). Good for validating playbook on tiny work.
4. **C++** — small (1 stub: relay TODO). Good for validating multi-language mechanics.
5. **Go** — 4 stubs (bedrock + WithConfigFile + cXML). Already has port_surface.json.
6. **Java** — 0 stubs but 71 cheat tests + 28 missing examples. Test-rewrite work.
7. **TypeScript** — 0 stubs but 40 cheat tests + 40 missing examples. Same as Java + needs enumerate_ts.
8. **Ruby** — 0 stubs but 53 cheat tests + 34 missing examples. Test-rewrite work.

Each port also needs the 4 BLOCKED audits' prerequisites (enumerate_<lang>.<ext> for TS/PHP/.NET/Rust).

---

## Final dispatch checklist (use before pressing send)

Before invoking the Agent tool:

- [ ] Prompt opens with the four NON-NEGOTIABLE RULES (pull, no-push, match-python, read-docs).
- [ ] **MODE is explicitly stated** (AUDIT / FIX / AUDIT+FIX) with the exact language from the "Dispatch modes" section.
- [ ] Architecture notes for this specific port included verbatim (copy from "Per-port architecture notes" above).
- [ ] Each task has a Python reference (file:line:method). Tasks without a Python reference should be flagged for the user before dispatch.
- [ ] Audit programs the agent will run as receipts are listed with absolute paths.
- [ ] The REPORT FORMAT section is included verbatim — agent must produce all 5 sections.
- [ ] Final reminder: "Begin by pulling and reading the docs."
- [ ] `run_in_background: true` if you want to do other work in parallel; `false` if the agent's report is on the critical path.
- [ ] Model is `opus` per the user's standing instruction.
