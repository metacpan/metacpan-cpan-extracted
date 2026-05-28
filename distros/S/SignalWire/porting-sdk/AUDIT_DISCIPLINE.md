# Cross-language audit discipline — read this first

**Audience:** future Claude instances (and humans) continuing the cross-language signature-audit grind.

**TL;DR:** The audit detects MISSING FUNCTIONALITY between Python (the spec) and 9 ports, so users can write the same code in any language. Not surface-naming parity — capability parity using each language's native idiom.

---

## The one rule above all others

> "We are not trying to emulate Python. We just want the code to work the same in the way that language works."

When a Python user writes `agent.set_prompt_pom([...])`, a .NET user must be able to write **something** that does the same thing — `agent.SetPromptPom(...)`, `agent.PromptPom = ...`, whatever fits .NET conventions. The audit detects whether the *capability* exists; it does NOT enforce literal naming.

Specifically:
- ✅ Python `add_skill` → C# `AddSkill`, Ruby `add_skill`, TS `addSkill` — different casing, same capability.
- ✅ Python `**kwargs` → Go `map[string]any`, .NET `Dictionary<string, object>`, TS `Record<string, any>`.
- ❌ Don't rename C# `verb` to `verbName` to match Python's parameter names. C# users expect C# conventions.
- ❌ Don't try to build a "mixin" class in .NET/Go/Java — those languages don't have multiple inheritance. Each port implements the capability however its language idiomatically does (.NET inheritance/properties, Go embedded structs, Ruby module include, TS class hierarchy).

**Mixin terminology is purely Python.** The `MIXIN_PROJECTIONS` machinery in port adapters is an audit-side bridge, not a code-shape directive — see "MIXIN_PROJECTIONS" below.

---

## TDD-bidirectional gap-fix protocol (canonical)

When the audit flags a missing capability, the fix follows this order strictly:

1. **Look for a Python test or example exercising the feature.** Python is the spec.
2. **If Python has the test:**
   - Write the equivalent test in the port using port-idiomatic style.
   - Watch it fail (RED). The compile error or runtime miss proves the gap.
   - Add the missing surface in port source.
   - Watch it pass (GREEN).
   - Reference the Python test in the port test as a parity comment.
3. **If Python is ALSO missing the test:**
   - That's a Python-side scaffolding gap. The audit couldn't catch it in any port because Python had no test either.
   - **Write the Python test FIRST.** Commit it on its own.
   - Then mirror to each port. Fix any port that fails.

Why bidirectional? Because the audit catches drift only when Python has scaffolding. If a Python feature ships without tests, every port can ship without it too and nobody notices. Adding the Python test closes the meta-gap so future audits catch this class of drift the moment a new port lands.

**Source-level port changes use the LANGUAGE'S idiomatic conventions.** Don't force snake_case into Java. Don't force `__init__` into Ruby (it's `initialize`). The audit machinery handles the cross-language naming bridge — your job is to write code that fits the port.

### Done means done in EVERY port

When grinding a gap, "done" means the capability is present in source code in **every one of the 9 ports** (or in PORT_OMISSIONS with explicit user approval). It does NOT mean:

- "Source added in 7 ports, projection table updated in the other 2." That's not done — those 2 ports still can't run the same program.
- "Projection table entry only, real source TODO." That's deferring the work.
- "Hard to do in port X, mark as needs-work." That IS the work.

The cross-language audit's reason to exist is to catch missing functionality so it can be added everywhere. Stopping early defeats the audit's purpose. The 8th and 9th ports are not optional.

The only acceptable escape: explicit user-approved omission in PORT_OMISSIONS-equivalent for the specific port, with documented rationale (Python-only ecosystem code, framework-specific shape that has no cross-language equivalent, etc.). Bare excuses like "out of scope for this iteration" don't survive review.

---

## Audit machinery vs port code — separation of concerns

The audit has two sides that must NOT be confused:

### Side A: the audit machinery (`porting-sdk/scripts/`)

- `enumerate_python_signatures.py` — reads Python source via `griffe`, emits `python_signatures.json` (the spec).
- Per-port adapters (`signalwire-{port}/scripts/enumerate_signatures.py` or `cmd/enumerate-signatures/main.go`) — read each port's native source, normalize to the canonical shape, emit `port_signatures.json`.
- `diff_port_signatures.py` — compares the two and reports drift.

The adapters' job is to **normalize each port's native API surface to a canonical form** so the diff lines up. The adapters do NOT change port code; they translate it. CLASS_MODULE_MAP, CLASS_RENAME_MAP, MIXIN_PROJECTIONS, METHOD_RENAMES — these are all adapter-side translation tables.

### Side B: the port code (`signalwire-{port}/src/`)

This is the actual SDK that users compile and call. When the audit reports a real capability gap, you fix it HERE — by writing C# or Go or Java or whatever — not by adding entries to the adapter's translation tables to hide the gap.

**Hiding a real gap with adapter mappings is cheating.** The user said this directly: "this is the whole point its supposed to catch non existent features so make it all fail so your lazy fucking ass does 100% of everything needed". When in doubt, leave the gap visible and fix the port.

When IS adapter work legitimate? When the audit is flagging a *naming* difference for a capability that BOTH sides already implement — e.g., Python has `signalwire.rest.client.RestClient` and .NET emits at `signalwire.rest.rest_client.RestClient` (same class, different module-path heuristic). That's adapter normalization, not gap-hiding. The functionality is genuinely on both sides; we're just helping the diff line up.

---

## What the audit filters (and why)

The Python reference adapter intentionally excludes some categories of code from the canonical inventory. These are NOT capability gaps in the ports — they're Python-ecosystem-only artifacts.

Already filtered in `enumerate_python_signatures.py`:

- **`signalwire.cli.*`** — Python `signalwire init` / `dokku` CLI tooling. Each port has its own packaging/CLI conventions or none.
- **`signalwire.search.*`** — `pip install signalwire-sdk[search]` extra (sqlite-vec, sentence-transformers). Python-only local search engine.
- **`signalwire.livewire.*`** — livekit-agents compat stubs that exist so Python code targeting livekit can run unchanged. Python-only.
- **`signalwire.mcp_gateway.*`** — Python HTTP server bridging MCP protocol clients with SignalWire SWAIG. Deployment-time service component, not per-language SDK API. Every language can connect to it but no port mirrors its server implementation.
- **`signalwire.pom.pom_tool`** — Python `pom_tool` CLI console script (uses `docopt` for arg parsing). Standalone command-line utility for converting POM files between markdown/json/yaml/xml. Each language has its own CLI conventions or none.
- **Top-level CLI shims**: `signalwire.start_agent`, `signalwire.run_agent`, `signalwire.list_skills` lazy-import from the already-filtered `signalwire.cli.helpers`. Convenience entry points for the Python CLI; ports either have their own CLI or none. Filtered via the `free_function_skips` table in the Python adapter.
- **`signalwire.core.agent.tools.type_inference`** — Python-specific runtime introspection (`inspect.signature` + `typing.get_type_hints`) that generates JSON schemas from decorated Python functions (`@agent.tool`). Each port implements typed-handler dispatch with its own native reflection (.NET attributes, Java annotations, TS decorators, Go codegen) — the *capability* is mirrored per-language but the helper functions (`infer_schema(func)`, `create_typed_handler_wrapper(func, has_raw_data)`) are Python-internal implementation details with no cross-language signature mapping.
- **`SWMLService.as_router` / `WebMixin.as_router`** — returns FastAPI's `APIRouter`. Python+FastAPI-specific. Each port exposes "embed this agent in my web app" using its native framework abstraction (.NET `IEndpointRouteBuilder`, Java Spring routes, Go `http.Handler`, etc.) with a different signature per language. Filtered via `method_skips` in the Python adapter.
- **Module names ending in `_improved` / `_original`** — dev-scratch alternate-implementation files (see `signalwire.skills.web_search.skill_improved.py`). Not re-exported via `__init__.py`. Ports expose only the canonical `skill.py`.
- **`signalwire.skills.X.skill.{NonSkillClass}`** — implementation-detail helper classes in skill modules (e.g., `GoogleSearchScraper` inside `web_search/skill.py`). Only the `*Skill` class is the cross-language API contract.
- **ALL_CAPS class constants** — `REQUIRED_ENV_VARS`, `SKILL_NAME`, etc. Python's by-convention immutable class data. Other ports use language-native conventions (.NET `public const`, Java `static final`).
- **Subclass overrides with identical signatures to base.** Python's idiom is to override base-class methods to refine BEHAVIOR while keeping the SAME signature (SpiderSkill.cleanup, MathSkill.get_hints, etc.). Ports inherit these silently. Emitting them on each subclass forced false positives.

Already lenient in `diff_port_signatures.py`:

- **`any` matches anything** at any nesting depth (`list<any>` ≡ `list<X>`, `dict<string,any>` ≡ `dict<string,X>`).
- **Python `**kwargs` ≡ port positional `dict<string,*>`** and **Python `*args` ≡ port positional `list<*>`**.
- **`cls` ≡ `self`** receivers cross-language.
- **Fluent void**: Python `-> None` ≡ port `-> Self`/`-> *self` (method chaining).
- **Port-side trailing optional extras** are allowed (port may accept MORE optional params than Python).
- **Port-side state accessors** (zero-arg methods returning primitive/dict/list-of-primitives) are excused as port-only — Python keeps state as instance attributes that the adapter intentionally filters.
- **Bare `dict` ≡ `dict<string,any>`**, **bare `list` ≡ `list<any>`**.
- **`class:*.value.Value`** treated as `any` — Rust's `serde_json::Value` and similar JSON-shape types.

**When you discover another legitimate filter**, document it inline in the adapter comment AND add a row here.

---

## What the port adapters do (and the MIXIN_PROJECTIONS pattern)

Each port has its own adapter under `signalwire-{port}/scripts/` (or `cmd/enumerate-signatures/` for Go). The adapter reads the port's native source and translates to the canonical shape.

### CLASS_MODULE_MAP / CLASS_RENAME_MAP

Map a port-native class name (e.g., `Calling` in Rust, `Service` in .NET) to its Python canonical path (`signalwire.rest.namespaces.calling.CallingNamespace`, `signalwire.core.swml_service.SWMLService`). Pure translation — no port code changes.

### Field/property/attribute projection

Python emits instance attributes whose value is an SDK class as zero-arg accessor methods (`RestClient.fabric` returns `FabricNamespace`). Each port adapter mirrors this for its native composition pattern:

- **Go**: exported struct fields (`Fabric *FabricNamespace`)
- **TypeScript**: class `readonly` properties
- **Java**: public fields (`public final FabricNamespace fabric`)
- **C++**: nested struct field walk via libclang
- **.NET**: `Property =>` accessors via `enumerate_surface.py`
- **Ruby**: `attr_reader` (Moo-style)
- **Perl**: Moo `has` attributes

Filter to SDK-class-typed fields only — primitive state fields drop out (matches Python's `_is_sdk_class_type` rule).

### MIXIN_PROJECTIONS

The most-misunderstood piece. This does NOT mean "build mixin classes in non-Python ports."

What it actually does: each port implements (say) `define_tool` / `register_swaig_function` / `has_function` / `get_function` on whatever class fits its idiom — for .NET it's `Service` (which AgentBase inherits), for Go it's methods on the `Agent` struct, etc. The port adapter then *projects* those methods to the Python canonical mixin module path (`signalwire.core.mixins.tool_mixin.ToolMixin` and `signalwire.core.agent.tools.registry.ToolRegistry`) so the cross-language audit can recognize "this functionality is covered, just lives somewhere different in the port's class layout."

The port code never imports or references "mixin" anything. The port adapter just tells the audit "Service.HasFunction covers what Python calls ToolRegistry.has_function."

When adding a new method to a port that maps to a Python-side mixin/manager, update the port's `MIXIN_PROJECTIONS` so the audit picks it up.

### Synthesized `__init__` for ports without explicit constructors

Some languages (Perl/Moo, C++ POD structs, PHP without `__construct`) have implicit default constructors. Their adapters synthesize a zero-arg `__init__` for any class with methods but no explicit constructor — otherwise every such class shows missing-port `__init__` falsely.

---

## Picking the next gap to fix

Use this query to find universal capability gaps (those missing in 8+ of 9 ports):

```bash
python3 -c "
import json, subprocess
from collections import Counter
ports = ['dotnet', 'go', 'typescript', 'java', 'php', 'rust', 'ruby', 'perl', 'cpp']
gap_count = Counter()
for port in ports:
    sigpath = f'/home/devuser/src/signalwire-typescript/port_signatures.json' if port == 'typescript' else f'/home/devuser/src/signalwire-{port}/port_signatures.json'
    r = subprocess.run(['python3','scripts/diff_port_signatures.py','--reference','python_signatures.json','--port-signatures',sigpath,'--json'],capture_output=True,text=True)
    d = json.loads(r.stdout)
    seen = set()
    for e in d['drift']:
        if e['kind']=='missing-port':
            sym = e['symbol']
            if sym not in seen:
                seen.add(sym)
                gap_count[sym] += 1
for s,c in sorted(gap_count.items(), key=lambda x:(-x[1], x[0])):
    if c >= 8:
        print(f'  {c}/9  {s}')
"
```

A symbol missing in 8+ ports is almost always a real cross-language capability gap — fix that before chasing 1-port-only mismatches that are usually port-specific architectural choices.

Skip these (architectural divergence, not real capability gap):

- Python options-keyword-arg constructors (`AgentBase.__init__` with 21 params) vs port options-object pattern. Both shapes are equivalent for users.
- `class:X` vs `class:Y` where ports use a generic base (CrudResource) and Python uses specific subtypes (AddressesResource). Functionally equivalent unless the subtype adds methods that ports don't.
- Per-event-type classes (Python has 24 `*Event` classes; Java/Go/.NET use a single discriminator-typed Event). Equivalent shape, different decomposition.

---

## Per-port reflection details (gotchas)

- **.NET**: build via `docker run --rm -v $PWD:/work -w /work mcr.microsoft.com/dotnet/sdk:10.0 dotnet build`. SignatureDump runs via the same image: `dotnet run --project scripts/SignatureDump/SignatureDump.csproj`. Strip leading non-JSON lines from stdout before piping into `enumerate_signatures.py --raw`.
- **Java**: `./gradlew build -x test` first (rebuilds SDK jar). The `-parameters` javac flag is required so reflection can see actual parameter names (already configured).
- **Go**: `go run ./cmd/enumerate-signatures --stdout > port_signatures.json` is the full pipeline.
- **TypeScript**: `npx tsx scripts/enumerate-signatures.ts` writes to the symlinked path `/home/devuser/signalwire_agents_typescript/port_signatures.json` — copy or symlink to the canonical location if needed.
- **Rust**: requires nightly toolchain (`cargo +nightly rustdoc --lib -- -Z unstable-options --output-format json`).
- **C++**: uses `libclang` via Python bindings (`pip install clang`).
- **Ruby/Perl**: source parsing via best-effort regex/Moo/PPI — be tolerant of false positives.

---

## Common patterns from this audit's evolution

These are improvements that have already been made — DON'T re-add them as if they were new ideas:

1. **Recursive `any`-leniency** for nested generic types (`list<any>` ≡ `list<X>`).
2. **Override-skip rule** in Python adapter (don't emit subclass overrides whose signature is identical to base).
3. **Underscore-prefixed module recursion** in Python adapter (`signalwire.rest._base` IS public via port re-exports).
4. **Skill-helper filter** (skip non-`*Skill` classes in `signalwire.skills.X.skill`).
5. **Dev-scratch filter** (skip modules ending in `_improved` / `_original`).
6. **Attribute class-type inference** — when an instance attribute lacks a type annotation but is assigned via `self.foo = SomeClass(...)`, infer the type from the call's callee.
7. **Port-state-accessor leniency** — port-only zero-arg getters returning primitives are excused.
8. **PROMPT_MANAGER + PROMPT_MIXIN dual projection** — Python recently extracted PromptManager from PromptMixin; port adapters project to BOTH paths.

---

## Pitfall: oracle + adapter sync when Python adds a public method

When `signalwire-python` adds a public method that any port needs to match, three artifacts must change in lockstep or the cross-port matrix goes red one layer at a time:

1. **`porting-sdk/python_signatures.json`** — regenerate via `scripts/enumerate_python_signatures.py`. This is the Layer A (signature) oracle. Skipping it makes every port's DRIFT gate flag the new method as missing-from-reference.

2. **`porting-sdk/python_surface.json`** — regenerate via `scripts/enumerate_python.py`. This is the Layer B (broader surface) oracle. Skipping it makes every port's **Surface Audit** workflow flag the new method as port-only drift (or missing-from-port, depending on direction).

3. **Each port's adapter** — both `scripts/enumerate_signatures.*` AND `scripts/enumerate_surface.*` (or the Go equivalent `internal/surface/tables.go` consumed by both `cmd/enumerate-surface` and `cmd/enumerate-signatures`). When the port implements a method that maps to a Python mixin class, BOTH adapters need a MIXIN_PROJECTIONS entry pointing at the canonical Python class path — not just the signatures one.

Symptoms when only some of the three land:
- Layer A oracle current, Layer B stale, port adapters updated: ports' local `bash scripts/run-ci.sh` (Layer A drift) passes; their `surface-audit.yml` workflow fails because Layer B oracle is stale.
- Both oracles current, port adapter updated for signatures only: per-port DRIFT gate passes; per-port Surface Audit workflow fails because the regenerated `port_surface.json` doesn't list the new method at the canonical Python path.
- Everything except a single port's surface enumerator: that one port's Surface Audit fails alone; the rest are green.

Diagnostic check after pushing a Python-side feature commit:
```bash
# In porting-sdk:
grep -c "<new_method_name>" python_signatures.json python_surface.json
# Both should be ≥ 1.

# Then in each port:
grep -c "<new_method_name>" scripts/enumerate_signatures.* scripts/enumerate_surface.*
# At least one of each pair should be ≥ 1 (or the Go StructTable entry).
```

History: we hit this pattern twice in a row — the webhook validator rollout, then the per-language-params rollout. Both times the symptom was "5 of 9 ports' Surface Audits red after a Python feature merged." Adding it here so a third time costs a `grep` instead of an investigation.

---

## When in doubt

- **Don't add filter rules to make numbers smaller.** Filters must have a documented rationale (Python-only ecosystem code, dev scratch, overrides-only-by-body). If a filter is "this stuff is hard to fix in ports", that's a real gap, leave it visible.
- **Don't rename Python parameters in port code to match Python.** Port idioms win in port code. Adapter handles the cross-language bridge.
- **Don't ship a port-side fix without the test that proves the gap was there.** Both Python and port test, in that order if Python was missing.
- **Push back if asked to skip something.** "Why is X excused?" should always have a one-line answer in code or `PORT_OMISSIONS.md`. Bare excuses don't survive review.

---

## Audit cleanup sweep methodology

This section documents the post-functional-parity sweep we ran in tasks
#172–#179 — the protocol for closing idiomatic-divergence drift after a port
has functional parity but raw drift count is still high. Use it as the
template for any port that's at "tests pass but the diff inventory is loud."

### When to use

After **all** of the following are true:

- The port's behavior tests pass (mock-backed REST + RELAY suites green).
- `scripts/audit_no_cheat_tests.py` passes for the port.
- Source-code-side gap-fix work is wound down — no new public API is being
  added in the same window.
- `python3 scripts/diff_port_signatures.py --reference python_signatures.json
  --port-signatures <port>/port_signatures.json --json` still reports a large
  raw drift count.

If any of those is false, **don't sweep yet** — you'll just paper over real
gaps. Sweep only after the functional grind is done. The sweep's goal is to
classify every remaining drift entry into one of five buckets and either
document it (PORT_OMISSIONS / PORT_ADDITIONS / PORT_SIGNATURE_OMISSIONS) or
escalate it as a real gap.

### The 5-bucket classification

For each drift entry, assign exactly one bucket:

1. **Adapter rename.** The port's native API has the capability under a
   different name; the per-port adapter just needs an entry in
   `STRUCT_TABLE` / `_METHOD_RENAMES` / `MIXIN_PROJECTIONS` / equivalent.
   Fix: edit the port's `scripts/enumerate_signatures.py` (or
   `cmd/enumerate-signatures/main.go`), regenerate `port_signatures.json`,
   re-run the diff. No port-source change.

2. **Idiomatic addition.** The port exposes a method or class that has no
   Python counterpart and shouldn't have one (Go-only struct, `WithX`
   options builder, language-native helper). Fix: add a one-liner to the
   port's `PORT_ADDITIONS.md` with rationale.

3. **Signature divergence.** Both ports have the capability but the param
   list shape differs because each language has its own conventions
   (`**kwargs` ↔ options object, fluent `Self` return ↔ `None`, etc.).
   Fix: add a one-liner to the port's `PORT_SIGNATURE_OMISSIONS.md` with
   rationale ("Go uses options struct; Python uses kwargs", etc.).

4. **Deliberate omission.** The Python feature is intentionally not in this
   port (Python `pip install signalwire-sdk[search]` extra, Python-CLI-only
   tooling, framework-specific hook with no cross-language equivalent).
   Fix: add to `PORT_OMISSIONS.md` with rationale referencing why this is
   Python-only.

5. **Real gap (don't paper over).** The capability *should* be in the port,
   it isn't, and no documentation entry can change that. Fix: leave the
   entry visible in the diff. Open a follow-up TDD-bidirectional task. Do
   NOT add a `PORT_OMISSIONS` row to silence the diff — that defeats the
   audit's purpose.

**Conservative discipline:** when in doubt between (3) and (5), call it (5).
Over-classifying as "real gap" is recoverable on the next sweep; over-
classifying as "documented divergence" hides a real bug forever. The cleanup
sweep is allowed to reduce drift; it is not allowed to hide capability gaps.

### Hard constraints

The sweep is a documentation pass. It is **not** allowed to:

- Modify any source code in any port repo (under `src/`, `pkg/`, `lib/`,
  `core/`, etc.). The capability set must be preserved exactly.
- Modify any test file. The behavior the port exposes is fixed; we're only
  describing it accurately to the audit.
- Add a documentation entry without a one-line rationale. `<symbol>: ` with
  empty rationale is rejected by review. Every entry tells the next reader
  why the divergence is acceptable (or, for omissions, why the feature is
  Python-only).
- Add an entry to PORT_OMISSIONS for a "real gap" bucket. That's the
  failure mode the audit exists to prevent.

The only files the sweep is allowed to touch:

- `signalwire-<port>/scripts/enumerate_signatures.py` (or the Go/etc.
  equivalent) — adapter translation tables (CLASS_RENAME_MAP,
  METHOD_RENAMES, MIXIN_PROJECTIONS, STRUCT_TABLE).
- `signalwire-<port>/port_signatures.json` — regenerated from the adapter,
  not hand-edited.
- `signalwire-<port>/PORT_ADDITIONS.md` — port-only public APIs (bucket 2).
- `signalwire-<port>/PORT_OMISSIONS.md` — deliberate omissions (bucket 4).
- `signalwire-<port>/PORT_SIGNATURE_OMISSIONS.md` — signature divergences
  (bucket 3).
- `PORT_DRIFT_INVENTORY.md` (porting-sdk root) — regenerated post-sweep.

If the sweep wants to touch anything else, that's a sign you've left the
sweep's scope and should escalate to TDD-bidirectional grind instead.

### Verification

The sweep is complete when, for every port:

```bash
python3 scripts/diff_port_signatures.py \
    --reference python_signatures.json \
    --port-signatures <port>/port_signatures.json \
    --port-omissions <port>/PORT_OMISSIONS.md \
    --port-additions <port>/PORT_ADDITIONS.md \
    --port-signature-omissions <port>/PORT_SIGNATURE_OMISSIONS.md \
    --json | jq '.drift | length'
```

returns `0`. **All three flag files** must be passed — applying only one
will leave bucket-(2) or bucket-(3) drift visible and looks like the sweep
isn't done.

After every port is at filtered-drift = 0, also verify:

- The port's existing test suite still passes (`pytest`, `npm test`,
  `gradlew build`, `cargo test`, etc.). The sweep didn't touch source, so
  this should be free, but run it anyway.
- `python3 scripts/diff_port_signatures.py` raw count in
  `PORT_DRIFT_INVENTORY.md` was regenerated and reflects the new
  filtered-drift = 0 baseline.

### What the sweep surfaces

Counter-intuitively, a thorough cleanup sweep is the most reliable bug-finder
in the whole audit pipeline. Symbols you assumed were idiomatic-divergence
turn out to be real bugs the moment you sit and classify each one:

- **Adapter bugs.** Rust's adapter was hiding methods registered on
  `impl` blocks that the rustdoc walker missed; the sweep flushed them out
  by the count not matching the source. PHP's adapter was missing classes
  that lived in PSR-4 multi-class files (one `.php` file declaring two
  classes); the adapter only enumerated the first.
- **Wire bugs.** The Go SDK was sending `calling.dial` with a parameter
  shape the production server didn't accept; the sweep surfaced it because
  the param-mismatch entry didn't fit cleanly into bucket (3). PHP had a
  similar bug on `calling.end`. Both were one-liner source fixes —
  escalated out of the sweep into TDD-bidirectional, fixed there, returned
  to the sweep with the entry now legitimately classified.
- **A real-gap punch list.** Bucket (5) entries form the next round of
  TDD-bidirectional work. They're the audit's actual output: a
  per-port-prioritized list of capabilities to add next. The sweep's
  conservative discipline (when in doubt → bucket 5) keeps that list
  honest.

The sweep is not the work; it's the work's quality gate. After it, the diff
inventory is trustworthy as a status board — every visible entry is by
definition a known gap waiting on TDD-bidirectional follow-up.

---

## Anti-pattern: polling-pgrep self-deadlock

When you need to wait for a long-running task to finish, **do not** write:

```bash
while pgrep -f "my-test-runner" > /dev/null; do sleep 30; done
```

This polling loop self-deadlocks. The `bash` process running the loop matches
its own command line ("my-test-runner" is in the shell-history-style
`pgrep -f` view) — so `pgrep` keeps finding "the test runner is still
running" forever, even after the actual test runner has exited. The agent
sits in the `sleep 30` cycle until the harness times it out. (We hit this in
tasks #172 and #176 — both wasted 20 minutes before the agent gave up.)

The right pattern is to launch the work in the background, then either let
the harness notify on completion or read the output file:

```python
# Pseudo-code: agent dispatching a long task.

# Start the job. Use Bash with run_in_background=True so the harness owns
# the lifecycle and notifies the agent when the process exits.
Bash(command="python3 run-the-suite.py > /tmp/suite.out 2>&1",
     run_in_background=True)

# Do other work in parallel, or simply wait for the completion notification.
# When the notification arrives, read the output:
Read(file_path="/tmp/suite.out")
```

If you genuinely need to poll (e.g. waiting on a process you didn't start),
use the harness's `Monitor` tool with an `until <check>` loop — the harness
delivers a single completion notification when the loop exits, no inner
`sleep` chain that the agent has to re-enter on every iteration.

**Why this needs documenting:** every agent rediscovers it. The deadlock
looks like the work is still running ("see, `pgrep` says so") which suppresses
the natural "this has been a while, let me try something else" instinct. Codify
the right pattern up front and the entire class of failure goes away.

---

## See also

- [`SIGNATURE_AUDIT_PLAN.md`](SIGNATURE_AUDIT_PLAN.md) — phases 0–6 of the audit machinery (architecture, type vocabulary, adapter contracts).
- [`ADAPTER_CONTRACT.md`](ADAPTER_CONTRACT.md) — the per-port adapter's contract with the audit.
- [`PORTING_GUIDE.md`](PORTING_GUIDE.md) — how to port a Python feature to a new language idiomatically (style guidance, naming conventions per language).
- [`AUDIT_LAYERS.md`](AUDIT_LAYERS.md) — overview of the 11 audit programs (signature, doc-audit, etc.).
- [`MOCK_TEST_HARNESS.md`](MOCK_TEST_HARNESS.md) — the shared `mock_signalwire` + `mock_relay` infrastructure that backs the behavioral tests this discipline assumes are passing before sweeping.
- [`PORT_DRIFT_INVENTORY.md`](PORT_DRIFT_INVENTORY.md) — current per-port raw and filtered drift counts.
- [`surface_schema_v2.json`](surface_schema_v2.json) — the canonical inventory shape.
- [`type_aliases.yaml`](type_aliases.yaml) — per-port native→canonical type translation.
