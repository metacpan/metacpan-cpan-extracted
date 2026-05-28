# Cross-language signature audit — implementation plan

**Status:** proposed, not started.
**Owner:** porting-sdk maintainers + per-port adapter authors.
**Estimated effort:** ~30 working days at one engineer; ~3 calendar weeks if Phase 4 fans out across agents under review.

> **Future readers / Claude instances:** before grinding gaps, read
> [`AUDIT_DISCIPLINE.md`](AUDIT_DISCIPLINE.md) end-to-end. It captures the
> capability-not-naming framing, MIXIN_PROJECTIONS pattern, full filter
> rationale, per-port reflection gotchas, and "don't re-derive these"
> patterns the audit has already absorbed. The TDD-bidirectional protocol
> below is the canonical micro-flow; AUDIT_DISCIPLINE.md is the macro
> orientation.

## Discipline: closing identified gaps (TDD bidirectional)

When the audit flags a gap in a non-Python port, the fix protocol is:

  1. **Look for a Python test or example that exercises the missing
     feature.** Python is the spec; if a test exists, the port simply
     missed catching up.
  2. **If Python has the test:**
     - Write the equivalent test in the port using port-idiomatic style
       (camelCase / kebab-case / etc. — NOT Python-style naming).
     - Run the port test, watch it fail to compile or fail-at-runtime
       (the RED step proves the gap).
     - Add the missing surface in port source.
     - Run the port test again, watch it pass (GREEN).
     - Reference the Python test in the port test as a parity comment.
  3. **If Python is ALSO missing the test/example:**
     - That's a Python-side gap — the audit was unable to flag the port
       because Python had no scaffolding either.
     - **Write the Python test/example FIRST.** This is what would have
       caught the port miss originally. Commit it.
     - Then write the equivalent test in every port that exposes the
       feature, and fix any port that's missing it.

Rationale: gaps the audit doesn't catch usually correspond to Python
features that have no scaffolding test. Adding the test on the Python
side ensures future audits catch this class of drift as soon as a
new port ships without it.

Source-level changes in ports should follow the language's idiomatic
conventions (param names, casing, type-system features) — the audit's
job is to verify that the same code can be written across languages,
NOT to enforce literal Python parameter names on every port.

## Goal

Detect API drift between the Python reference SDK and each of the nine ports
(.NET, Java, TypeScript, Rust, Go, Ruby, PHP, Perl, C++) at **signature
granularity** — parameter names, types, defaults, return types — not just at
name granularity (which is what the existing `surface-audit` does).

Today's `diff_port_surface.py` only diffs *names*. A method that grows a
required parameter, swaps `string` for `int`, or changes its return type
passes silently. The Python reference can drift in any of those directions
and CI stays green. This plan closes that gap, plus three smaller related
holes around the existing audits.

## Non-goals (this iteration)

- Behavioral parity testing beyond what the existing 11 audits cover. Test
  coverage is a different program; quantifying it (Phase 5) is in scope, but
  expanding behavioral fixtures is not.
- Re-platforming the SDK strategy onto Smithy (AWS, June 2025) or TypeSpec
  (Azure, GA 2025), which would eliminate drift architecturally by
  generating all SDKs from a single IDL. That's a months-long initiative
  with different trade-offs and is captured separately.
- Replacing the existing per-port name-level enumerators wholesale. The new
  signature data extends the JSON shape; existing name-level diffs continue
  working unchanged.

## The 4 real gaps — verified against source

Stripping the speculative framing of the prior `AUDIT_COVERAGE_TESTS.md`
critique and the rounds of pressure-testing that followed it, the actually
real holes in today's audit suite are:

1. **Method signature drift undetected.** The surface-audit's JSON only
   stores names. Confirmed at `cmd/enumerate-surface/main.go:1285-1289`
   (`methods map[string]struct{}`). A method that grows a required parameter,
   swaps `string` for `int`, or changes its return type passes silently.
2. **`PORT_ADDITIONS.md` is unenforced.** Confirmed at
   `cmd/enumerate-surface/main.go:1454` — unmapped Go structs `continue`
   silently. You can ship Go-only public API and CI doesn't notice.
3. **Functional-options helpers (`WithSTT`, `WithTTS`, …) are silent.**
   Confirmed at `main.go:1494` — only functions in `freeFnTable` reach the
   Python-shape JSON. Empirically: 0 hits in `port_surface.json`, 2 hits in
   `port_surface_go.json`. Special case of #2 for free functions.
4. **Behavioral audit coverage is uneven.** `audit_skills_dispatch`,
   `audit_rest_transport`, `audit_relay_handshake`, and `audit_http_swml`
   exercise many methods, but methods outside their fixtures (e.g. simple
   getters, unused-but-public utility methods) get no behavioral check.
   This is incomplete coverage, not a broken audit.

That's the entire list of real gaps. Everything else in earlier critiques
("AI verifies AI," "metaprogramming edges," "type aliasing is a judgment
call") was either hypothetical or out of scope for verification machinery.

## What this plan closes

| Gap | Closed by | Phase |
| --- | --- | --- |
| 1. Signature drift | `diff_port_signatures.py` + per-port adapter | 1–4 |
| 2. `PORT_ADDITIONS.md` unenforced | Enumerator emits `port_additions_actual.json`, diff cross-checks | 3 |
| 3. Functional-options helpers silent | Same enforcement applied to free functions | 3 |
| 4. Behavioral coverage invisible | `audit_coverage_map.py` quantifies (does NOT close) | 5 |
| Bonus: replace 535-line vibes doc | `AUDIT_LAYERS.md` (50 lines) | 0 |

Gap 4 is **quantified, not closed.** Closing it means writing more
behavioral fixtures. That is a separate program — not a verification
audit. The ratchet is "coverage % may not regress on PR," not "coverage
must hit 100%."

## Verified tooling per port

The following tools were verified against current state (early 2026) via web
search; each entry cites maintenance status as of the verification.

| Port | Tool | Status / source |
| --- | --- | --- |
| Python | `griffe` v2.0.2 (March 2026) | mkdocstrings org, Pawamoy maintainer; reference oracle |
| .NET | `Microsoft.DotNet.ApiCompat.Tool` (in-box .NET SDK) or raw `System.Reflection` | NuGet Nov 2025; ApiCompat is now bundled, was previously in `dotnet/arcade` |
| Java | `revapi` 0.28.4 (April 2025) | Iceberg, Palantir use it; semantic diff layer |
| TypeScript | `@microsoft/api-extractor` v7.58.7 (Jan 2026) | Microsoft uses for Office, Teams, Rush; no successor |
| Rust | `cargo-public-api` + `rustdoc --output-format json` via pinned nightly toolchain (e.g. `nightly-2025-08-02`); optionally also `cargo-semver-checks` v0.47 for breaking-change detection | rustdoc-json still nightly-only as of early 2026 (RFC 2963 tracking issue still open); the documented end-user path is `cargo +nightly rustdoc -- -Z unstable-options --output-format json`. `cargo-public-api` wraps this and exposes a structured `PublicApi` library type. **Do NOT use `RUSTC_BOOTSTRAP=1` — it is "actively discouraged" by the Rust project (compiler-team issue #350 proposes restricting it).** `cargo-semver-checks` itself runs on stable but handles rustdoc-json internally; not directly usable for our extract step |
| Go | `golang.org/x/exp/apidiff` (Go team) or `joelanford/go-apidiff` v0.8.3 (May 2025) | Operator-SDK uses go-apidiff in CI; preferred over hand-rolled `go/types` walker |
| PHP | `phpDocumentor/Reflection` 6.6.0 (April 2026) | Symfony PropertyInfo uses it; 1000+ packagist dependents |
| Ruby | `Method#parameters` (stdlib) + `yard --json` | YARD maintenance is light (~3 open issues, 0.9.43 in 2026) but functional |
| Perl | `Type::Params signature_for` (Type::Tiny v2.8.0, March 2025) | Toby Inkster (TOBYINK) actively recommends this as the 2025 idiom; runtime-introspectable signatures with types and defaults via `Type::Params::Signature` objects. Requires port-side refactor (cpanfile 5.026 → 5.026 + Type::Tiny dep) |
| C++ | `libclang` Python bindings | Only mature option; `cppast` is stagnating; heavyweight LLVM dep but unavoidable |

### Strategic alternatives considered but not selected

- **AWS Smithy / Azure TypeSpec / Google GAPIC** — eliminate drift by
  generating all SDKs from a single IDL. Different architecture; out of
  scope for this iteration. If SignalWire ever revisits SDK strategy, these
  are the prior art to start from.
- **Doxygen XML** — covers C++/Java/Python/PHP with one tool; could
  consolidate 4 of 9 adapters. Has quirks (XML output is verbose,
  doc-comment-centric). Worth a follow-up evaluation but not the v1 path.
- **`tree-sitter`-based extractors** — multi-language AST walking is real,
  but no single tool is "the" authoritative answer per language. Useful as a
  fallback for languages without a canonical extractor; we don't need it
  given the verified per-port list above.

## Explicitly out of scope (and why)

Several rigor improvements were proposed during plan iteration. Each is
real engineering, but each was rejected against the bar of "closes a
verified gap in today's audit suite." This section refutes each one
explicitly so future critics don't reopen them without new evidence.

### Property-based cross-port testing (rejected)

**The idea:** Generate random typed inputs in Python via Hypothesis;
dispatch through every port's harness; byte-compare normalized outputs.
Catches behavior drift across ports for any method whose output is
deterministic.

**Why rejected:** The behavioral audits already exercise the
highest-stakes methods (skills handlers, REST operations, RELAY transport,
SWML rendering). For methods outside that set, property-based testing
catches *theoretical* divergence, not divergence we have evidence is
occurring. The cost (~3 weeks, plus output normalization layer per port)
is bounded; the impact is bounded by "are there real divergences in the
methods this would cover" — and we have no evidence there are.

**Reopen if:** an actual divergence appears between two ports' output
bytes for the same input. Until then, this is rigor without motivation.

### Cross-validation with stdlib reflection (rejected)

**The idea:** For ports where stdlib reflection exists (Python
`inspect.signature`, .NET `System.Reflection`, etc.), run *both* the
chosen adapter tool *and* the stdlib reflection, assert agreement.
Eliminates the "AI-built-verifies-AI-built" objection for those ports.

**Why rejected:** The trust model already addresses this concern via
upstream-tool ground truth (`griffe` for Python is third-party, but
.NET `System.Reflection` and Java reflection ARE the canonical paths the
plan already specifies). Adding a second-tool cross-check is rigor on top
of rigor. The first time this catches a real bug would also be the first
time the canonical tool was wrong — and our adapters consume the canonical
tool's output directly, so an adapter-introduced bug would already trigger
the cross-port consistency probe in Phase 6.

**Reopen if:** the cross-port consistency probe ships and proves
insufficient (i.e. silent adapter bugs are slipping through it). Until
then, this is duplicate work.

### protoc-style conformance suite (rejected)

**The idea:** For each canonical type, write reference values in every
port; serialize through documented serializer; byte-compare. Verifies the
type alias table empirically.

**Why rejected:** Wrong analogy. protoc has a wire format; "did this
language's encoder produce the same bytes" is a decidable question.
Our problem is *signature description*, not *wire serialization*. There
is no canonical "the bytes a Python method's signature produces" — there's
only the JSON our adapter emits for it. The protoc-style conformance suite
solves a different problem.

**Reopen if:** our problem changes (e.g. SignalWire moves to a wire-
format-based SDK definition like Smithy). Not applicable to the current
audit goal.

### Generated `type_aliases.yaml` from conformance (rejected)

**The idea:** Auto-generate the cross-language type alias table by
running round-trip serialization tests, instead of curating it by hand.

**Why rejected:** The hand-curated table starts small (~15 canonical
types). Each entry is reviewable in code review with rationale. Generating
it from a conformance suite is rigor improvement, not bug fix. If the
table grows past ~50 entries and reviewers start questioning specific
aliases, revisit. Not before.

**Reopen if:** `type_aliases.yaml` exceeds 50 entries OR a reviewer
challenges a specific alias and we can't defend it on inspection.

### Framework-pattern recognition (Moo, decorators, source generators)

**The idea:** The Perl port uses Moo (`has 'foo' => (...)`), which
materializes accessor methods at class-creation time. The current adapter
plan won't see them. Same issue applies to .NET source generators,
TypeScript decorators that synthesize methods, etc. Build framework-aware
recognition into each adapter.

**Why deferred (not categorically rejected):** This IS a real gap, but
the SignalWire SDK uses a small known set of these patterns. Address
reactively: when an audit run shows a method missing because Moo
materialized it, add Moo recognition then. Pre-building coverage for
hypothetical future framework adoption is speculative.

**Reopen when:** an audit run flags a Moo-materialized accessor (or
equivalent in another port) as missing. Then add the framework rule.

### Perl `signature_for` strict mode (deferred)

**The idea:** CI fails on any public Perl `sub` that lacks a `signature_for`
declaration. Converts opt-in into mechanical policy.

**Why deferred:** The Phase 4 Perl refactor handles every existing public
method. New methods are caught by review. Strict mode is one extra CI step
on top of an already-correct codebase; if reviewers consistently miss the
opt-in requirement on PRs, add it.

**Reopen when:** a PR lands a public Perl method without `signature_for`
and the audit doesn't catch it.

### External steering committee signoff (rejected)

**The idea:** Submit the audit design and trust model to a Rust steering
committee member, .NET API design council reviewer, etc. for one-time
signoff.

**Why rejected:** This was hallucinated rigor. There is no documented
procedure for external steering committees to review external projects'
audit designs. Submitting a blog post or RFC-style write-up and inviting
community review is real, but provides no formal signoff and no guaranteed
engagement. Process trust ultimately rests on the upstream-authored tools
and reproducibility, both of which are already in scope.

**Reopen if:** a critic provides evidence that such a review channel exists
and is responsive. Not seen.

### Behavior parity for *every* method (rejected — diminishing returns)

**The idea:** Write fixtures that exercise every public method, achieving
100% behavioral coverage.

**Why rejected:** A getter that returns `self.name` doesn't need a
behavioral fixture; verifying its existence is enough. The cost grows
linearly in method count; the marginal value drops sharply after the
high-stakes methods are covered. The Phase 5 coverage map exposes which
methods are uncovered so the team can prioritize fixture authoring on
real-stakes targets, not chase a 100% number.

**Reopen if:** a regression slips through because a low-stakes method
silently changed behavior. At that point, write the fixture for that
method, not all methods.

### Smithy/TypeSpec re-platform

Already in non-goals above. Repeating here for the refutation index: this
is the architecturally correct answer to "eliminate drift." It is also a
12+ month re-platform of the SDK strategy. Not in scope for verification
machinery work; captured separately if the user wants to evaluate it.

## Canonical schema

Every port's adapter emits the same JSON shape, owned by porting-sdk:

```json
{
  "version": "2",
  "modules": {
    "signalwire.core.agent_base": {
      "classes": {
        "AgentBase": {
          "methods": {
            "set_prompt": {
              "params": [
                {"name": "self", "kind": "self"},
                {"name": "text", "type": "string", "required": true},
                {"name": "pom",  "type": "list<dict>", "required": false, "default": null}
              ],
              "returns": "void"
            }
          }
        }
      },
      "functions": {
        "create_simple_context": {
          "params": [
            {"name": "name", "type": "string", "required": true}
          ],
          "returns": "class:signalwire.core.contexts.Context"
        }
      }
    }
  }
}
```

### Type vocabulary

A small fixed set of canonical types. Adapters map native types into this
vocabulary; types outside the vocabulary cause **loud failure** at adapter
write time, not silent fallback to `any`.

```yaml
# type_vocabulary.yaml
primitive:
  - string
  - int
  - float
  - bool
  - bytes
  - datetime
  - any
  - void
parameterized:
  - dict<K,V>
  - list<T>
  - tuple<...>
  - optional<T>
  - union<T,U,...>
  - callable<args,ret>
class_ref:
  - "class:<dotted-name>"   # e.g. class:signalwire.core.agent_base.AgentBase
```

Permissive aliases (`type_aliases.yaml`) handle cross-language type
synonyms: `str ↔ string`, `dict ↔ Dictionary ↔ Map ↔ Hash`, etc. Strict
on parameter names and parameter count; lenient on type expression *only*
to the extent the alias table permits.

## Phases

### Phase 0 — Foundation (2 days)

Lock the contract before any port-side work begins.

**Deliverables (porting-sdk):**
- `surface_schema_v2.json` — JSON Schema for the canonical shape above.
- `type_vocabulary.yaml` — fixed enum of canonical types.
- `type_aliases.yaml` — cross-language alias table (initially small;
  grows via documented additions during Phase 2).
- `ADAPTER_CONTRACT.md` — input/output spec, schema validation rule,
  golden-test requirement, "fail loudly on unknown types" rule.
- `AUDIT_LAYERS.md` — the 50-line replacement for the n00b doc. Names the
  three audit programs (`diff_port_surface.py`, `diff_port_signatures.py`,
  `audit_docs.py`), what each catches, what each misses, links to the
  relevant workflow comment.
- Delete `AUDIT_COVERAGE_TESTS.md` (or trim to a stub that points at
  `AUDIT_LAYERS.md`).

**Done when:** `jsonschema` validates a hand-written canonical signature
file against `surface_schema_v2.json`, and `AUDIT_LAYERS.md` is reviewed.

### Phase 1 — Python reference oracle (2 days)

Python is the source of truth. Build the Python adapter first so every
other port has something to diff against.

**Deliverables (porting-sdk):**
- `enumerate_python_signatures.py` — uses `griffe` to walk
  `signalwire-python/signalwire/`, emits `python_signatures.json` per
  `surface_schema_v2.json`.
- ~30 hand-curated golden tests in
  `tests/python_adapter/golden/*.json` covering: simple positional, kw-only,
  optional, union, callable, dataclass, generic, `*args`/`**kwargs`,
  property, classmethod, staticmethod.
- `diff_port_signatures.py` — sibling of `diff_port_surface.py`. Strict on
  param names + count; lenient on type via `type_aliases.yaml`.
- Verification: Python signatures diffed against Python signatures returns
  empty.

**Done when:** `python_signatures.json` exists, schema-valid, all goldens
pass, self-diff is clean.

### Phase 2 — .NET first port end-to-end (3 days)

Pick .NET because `Microsoft.DotNet.ApiCompat.Tool` is the most polished
verified tool and the test loop is fastest in the current development
environment.

**Deliverables (signalwire-dotnet):**
- `enumerate_dotnet_signatures.cs` (or .py shelling out) using
  `System.Reflection` over the built DLL. Emits canonical JSON.
- ~20 golden tests for .NET-specific patterns: nullable refs, generics,
  `Func<>`/`Action<>`, default values, async `Task<T>`, init-only setters.
- Run `diff_port_signatures.py` against Python — expect drift. Triage:
  - Real port drift → fix in `signalwire-dotnet`.
  - Documented divergence → entry in new `PORT_SIGNATURE_OMISSIONS.md`
    with rationale.
  - Type-system gap → expand `type_vocabulary.yaml` or
    `type_aliases.yaml`.
- CI integration in `.github/workflows/`.

This is the "does the design survive contact with reality" gate.
Iterate the schema and vocabulary based on what .NET's type system
surfaces. Do not move to Phase 3 until the design has survived this
phase without ad-hoc patches.

**Done when:** `signalwire-dotnet`'s signature diff exits clean (with
documented omissions) and CI step is green on a PR.

### Phase 3 — Go upgrade + PORT_ADDITIONS enforcement (2 days)

**Deliverables (signalwire-go):**
- Replace the `go/ast` walker in `cmd/enumerate-surface/main.go` with
  `golang.org/x/exp/apidiff` (Go team's tool). Emit canonical signatures
  alongside the existing name-level surface.
- Change `main.go:1454` (silent struct skip) and `main.go:1494` (silent
  free-function skip): emit unmapped symbols into
  `port_additions_actual.json`.
- `diff_port_surface.py` extended: every entry in
  `port_additions_actual.json` must also appear in `PORT_ADDITIONS.md`
  with a rationale, or the audit fails.
- Decide `WithSTT` / `WithTTS`: Python parity → add to `freeFnTable`;
  Go-idiom → add to `PORT_ADDITIONS.md`.

**Done when:** Go signature diff clean, `PORT_ADDITIONS.md` is enforced
(removing an entry turns CI red), the previously-silent functional-options
helpers are explicitly classified.

### Phase 4 — Fan-out to remaining ports (~2 days each, 7 ports = ~14 days)

Each port: native tool → adapter → ~20 goldens → diff against Python →
triage → CI step. Document any port-specific aliasing in that port's
`PORT_SIGNATURE_OMISSIONS.md`.

**Recommended order** (easy → hard, validates the design progressively):

1. **TypeScript** — `@microsoft/api-extractor` emits well-documented
   `.api.json`; mostly mechanical translation.
2. **Java** — `revapi` JSON output is stable and semantic.
3. **PHP** — `phpDocumentor/Reflection` is Symfony-grade.
4. **Rust** — install pinned nightly toolchain (e.g. `nightly-2025-08-02`)
   in CI alongside stable; run `cargo +nightly rustdoc --lib -- -Z
   unstable-options --output-format json`; consume via `cargo-public-api`
   (preferred: structured `PublicApi` library type) or parse with
   `rustdoc-types` directly (more control). Pin `rustdoc-types` to match
   the nightly date. Belt-and-suspenders: also adopt `cargo-semver-checks`
   for Rust-internal breakage detection. **Do not use `RUSTC_BOOTSTRAP=1`**
   — it is "actively discouraged" by the Rust project; nightly toolchain
   is the documented path that `cargo-public-api` uses.
5. **Ruby** — `Method#parameters` + `yard --json`. Watch for YARD
   maintenance gaps; have a fallback plan.
6. **Perl** — see Phase 4 sub-plan below. Largest port-side refactor.
7. **C++** — `libclang` Python bindings. Heaviest dep, complex types
   (templates, overloads, namespaces); save for last when the schema and
   vocabulary are stable.

#### Phase 4 sub-plan: Perl

Perl is the only port that requires a real source-level refactor before
the adapter can do its job. The 2025 ecosystem update (Type::Tiny v2.8.0,
March 2025) makes this tractable; pre-2025 it would have been "best
effort with disclaimer."

**Today's Perl port state:**
- `cpanfile`: `requires 'perl', '5.026';`
- Methods use convention-style unpack: `my ($self, $arg1, $arg2) = @_;`
- No `use feature 'signatures'`, no Type::Tiny, no Function::Parameters.

**Refactor required:**
- Add `requires 'Type::Tiny', '2.8.0';` to `cpanfile`.
- For every public method, add a `signature_for` declaration adjacent to
  the existing `sub` (the `my (..) = @_;` pattern stays unchanged):

  ```perl
  use Type::Params -sigs;
  use Types::Standard qw(Str Int Bool Optional ArrayRef HashRef);

  signature_for set_prompt => (
      method => 1,
      pos    => [ Str, Optional[ArrayRef[HashRef]] ],
      names  => [ qw(text pom) ],
  );

  sub set_prompt {
      my ($self, $text, $pom) = @_;
      ...
  }
  ```

- Adapter loads each `.pm` module, calls
  `Type::Params::signature_for($sub_name)`, reads param names + Type::Tiny
  constraints + defaults reflectively, emits canonical JSON.

**Why not native 5.36 signatures alone?** Because Perl 5.36 native
signatures are stable as syntax but **provide no runtime introspection
mechanism** (multiple 2025 sources confirm this). The compiler discards
signature info after parsing. `signature_for` is the only path that gives
runtime-introspectable signatures with types.

**Why not best-effort PPI + POD?** Because the existing port has ~50
public methods using convention-style unpack with no POD type
annotations; the adapter would mark every entry as
`signature_confidence: best_effort` and reviewers would learn to ignore
the audit. Trustworthy beats covered.

**Effort:** ~2 days for the cpanfile bump + mechanical translation +
adapter. Same total as the other Phase 4 ports.

### Phase 5 — Behavioral coverage map (3 days)

Quantify the existing behavioral-audit coverage gap. Doesn't close it —
makes it visible.

**Deliverables (porting-sdk + per-port harnesses):**
- Each behavioral harness (`SkillsAuditHarness`, `RestAuditHarness`,
  `RelayAuditHarness`, etc.) prints a marker line on dispatch:

  ```
  coverage_marker: signalwire.skills.web_search.WebSearchSkill.handler
  ```

- `audit_coverage_map.py` aggregates marker lines across all 11 audits
  per port, builds `audit_coverage.json`:

  ```json
  {
    "signalwire.skills.web_search.WebSearchSkill.handler": [
      "audit_skills_dispatch"
    ],
    "signalwire.core.agent_base.AgentBase.set_prompt": []
  }
  ```

- `audit_checklist.py` reports per-port:
  `"X% of public methods exercised by ≥1 behavioral audit"`.
- Methods with empty coverage lists are flagged for follow-up fixture
  authoring (separate program — not closed in this plan).

**Done when:** running `audit_checklist.py` prints a coverage % per port,
sortable by uncovered-method-count.

### Phase 6 — CI integration + cross-port consistency probe (1 day)

**Deliverables:**
- Each port's CI workflow: signature-diff step alongside existing
  surface-diff step.
- New porting-sdk job: take ~50 hand-picked methods documented as having
  identical signatures across all ports (e.g. `AgentBase.set_prompt`,
  `WebSearchSkill.handler`), run every port's adapter, assert all 9 emit
  byte-identical canonical signatures (Python is the oracle, so we expect
  9 ports to match Python).
- Adapter-drift detection: any single-port deviation that doesn't appear
  in *any* port's `PORT_SIGNATURE_OMISSIONS.md` is an adapter bug, not a
  port bug.

**Done when:** a PR to any port that breaks signature parity goes red,
with the failing method named in the CI output.

## Trust model

The audit must work even when adapters are AI-written and may guess.
Mitigations, in order of leverage:

1. **Don't ask the adapter to infer — only to forward.** Every native tool
   already emits a structured, typed representation (`griffe` AST nodes,
   `System.Reflection.Type` objects, `rustdoc-json` type IDs, etc.). The
   adapter is a `switch` over an enumerated input vocabulary mapping each
   case to canonical. Not heuristics, not regex over source.
2. **Schema validation at the boundary.** Every adapter's output validates
   against `surface_schema_v2.json` before it's accepted. Catches "AI
   emitted `String` but the canonical vocab is `string`" structurally.
3. **Golden-file tests per adapter.** Hand-curated input/output pairs.
   AI rewriting an adapter breaks goldens loudly. The goldens are the
   contract.
4. **Loud failures on unknown types.** Adapter sees a type not in
   `type_vocabulary.yaml` → `RuntimeError` with `file:line`, not silent
   fallback to `any`. Forces a human decision: extend the vocabulary, add
   to `type_aliases.yaml`, or document the divergence in
   `PORT_SIGNATURE_OMISSIONS.md`.
5. **Cross-port consistency probe** (Phase 6). 50 known-parity methods
   diffed across all 9 adapters; any single-port deviation is an adapter
   bug. Catches "TS adapter started emitting `string` differently than
   the others" the day it happens.
6. **Python is the oracle, period.** `griffe` parsing the reference
   Python SDK is authoritative. Every other adapter's output is verified
   against Python via the diff. Drift is named, not silent.

The pattern: every place AI could "guess" becomes a place where the
schema, the goldens, the cross-port probe, or the loud failure forces a
human in the loop. Same principle as the existing audit suite — verify
with programs, not vibes.

## Decision points the user owns

1. **Perl** — adopt `Type::Params signature_for` (recommended) and refactor
   the Perl port, or skip Perl signature audit entirely and document?
   *Recommend: refactor. ~2 days, gives Perl the same trust model as
   every other port.*
2. **Rust toolchain** — install pinned nightly in CI (recommended) or wait
   for rustdoc-json stabilization?
   *Recommend: install pinned nightly. This is the documented path
   `cargo-public-api` uses; `RUSTC_BOOTSTRAP=1` was previously suggested
   here but research showed it is "actively discouraged" by the Rust
   project (compiler-team issue #350 proposes restricting it). The CI
   cost is one extra `rustup toolchain install` step. Alternative
   ("don't audit Rust until rustdoc-json stabilizes") has no ETA — the
   RFC 2963 tracking issue is still open as of early 2026.*
3. **AUDIT_COVERAGE_TESTS.md** — delete entirely, or trim to a stub?
   *Recommend: delete. The 50-line replacement (`AUDIT_LAYERS.md`)
   lives in porting-sdk, not in individual port repos, so it stays
   consistent across the 10 ports.*
4. **Phase 4 parallelization** — sequence under one engineer's review, or
   parallelize across agents?
   *Recommend: sequence the first 3 ports under direct review; the first
   3 will surface schema/vocabulary issues that need a single
   decision-maker reconciling them. Parallelize the remaining 4 once the
   design is locked.*

## Definition of done

- All 9 ports emit canonical signature JSON validating against
  `surface_schema_v2.json`.
- `diff_port_signatures.py` exits clean against all 9 ports (with
  documented `PORT_SIGNATURE_OMISSIONS.md` entries).
- `PORT_ADDITIONS.md` is enforced for Go and equivalent for the other
  ports.
- `audit_coverage_map.py` reports behavioral-coverage % per port; CI
  ratchets (no regression on PR).
- `AUDIT_COVERAGE_TESTS.md` is deleted; `AUDIT_LAYERS.md` is the canonical
  description of what audits catch what.
- The cross-port consistency probe (Phase 6) catches a deliberate
  test-mutation in CI.

## Sanity checks (baked into the phases above, not separate work)

These exist so the audit ratchets without manual oversight:

- **Pre-commit `jsonschema` validation** on every `*_signatures.json`
  checked in (Phase 0 deliverable).
- **CI cross-port consistency probe** — 50 known-parity methods, all 9
  ports, byte-identical canonical signatures (Phase 6 deliverable).
- **Loud-failure assertion** on unknown types in any adapter (Phase 0
  contract requirement).
- **Coverage ratchet** — Phase 5 reports % coverage per port; a PR may
  not regress it. We don't aim for 100%, we aim for "no backsliding."
- **Per-release reproducibility check** — human re-runs the audit
  pipeline from a clean checkout, asserts the JSON matches the committed
  `port_signatures.json`. ~30 minutes per release.

Five mechanical sanity checks. No new work; they are inherent to the
phase deliverables above.

## Sources (verified early 2026)

### Per-language tooling
- [griffe releases (mkdocstrings)](https://github.com/mkdocstrings/griffe/releases)
- [Microsoft.DotNet.ApiCompat.Tool on NuGet](https://www.nuget.org/packages/Microsoft.DotNet.ApiCompat.Tool/8.0.115)
- [ApiCompat moved into the .NET SDK](https://blog.fkan.se/ci-cd/apicompat-has-moved-into-the-net-sdk/)
- [revapi](https://github.com/revapi/revapi)
- [@microsoft/api-extractor on npm](https://www.npmjs.com/package/@microsoft/api-extractor)
- [api-extractor changelog](https://github.com/microsoft/rushstack/blob/main/apps/api-extractor/CHANGELOG.md)
- [rustdoc unstable features](https://doc.rust-lang.org/rustdoc/unstable-features.html)
- [RFC 2963 rustdoc-json](https://rust-lang.github.io/rfcs/2963-rustdoc-json.html)
- [rustdoc-json on docs.rs](https://docs.rs/about/rustdoc-json)
- [Rust project goals Dec 2025 update](https://blog.rust-lang.org/2026/01/05/project-goals-2025-december-update/)
- [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks)
- [cargo-public-api](https://github.com/cargo-public-api/cargo-public-api) — preferred extract tool; documents nightly-toolchain requirement
- [public-api crate on docs.rs](https://docs.rs/public-api) — structured `PublicApi` library type for consumers
- [rustdoc-types crate on docs.rs](https://docs.rs/rustdoc-types) — re-export of `rustdoc-json-types` for direct rustdoc-json parsing
- [RUSTC_BOOTSTRAP "actively discouraged" — Rust internals thread](https://internals.rust-lang.org/t/why-is-rustc-bootstrap-so-actively-discouraged/24123)
- [Rust compiler-team issue #350 — proposed user-confirmation gate on RUSTC_BOOTSTRAP](https://github.com/rust-lang/compiler-team/issues/350)
- [golang.org/x/exp/apidiff](https://pkg.go.dev/golang.org/x/exp/apidiff)
- [joelanford/go-apidiff](https://github.com/joelanford/go-apidiff)
- [phpDocumentor/Reflection](https://github.com/phpDocumentor/Reflection)
- [phpdocumentor/reflection on Packagist](https://packagist.org/packages/phpdocumentor/reflection)
- [YARD on GitHub](https://github.com/lsegal/yard)

### Perl ecosystem (verified March–May 2025)
- [Type::Tiny 2.8.0 Released — Toby Inkster (March 2025)](https://blogs.perl.org/users/toby_inkster/2025/03/typetiny-280-released.html)
- [Type::Params on metacpan](https://metacpan.org/pod/Type::Params)
- [PPI 1.283 (May 2025)](https://metacpan.org/release/MITHALDU/PPI-1.283)
- [PPI 1.282-TRIAL signature support (Feb 2025)](https://metacpan.org/release/MITHALDU/PPI-1.282-TRIAL)
- [perlsub — current signatures docs](https://perldoc.perl.org/perlsub)
- [De-experimentalising signatures (Perl issue #18537)](https://github.com/Perl/perl5/issues/18537)
- [Function::Parameters](https://metacpan.org/pod/Function::Parameters)
- [Better Perl with subroutine signatures and type validation — Phoenix Trap](https://phoenixtrap.com/2021/01/27/better-perl-with-subroutine-signatures-and-type-validation/)

### Strategic prior art
- [AWS Smithy API models open-sourced (June 2025)](https://aws.amazon.com/blogs/aws/introducing-aws-api-models-and-publicly-available-resources-for-aws-api-definitions/)
- [Azure TypeSpec overview](https://learn.microsoft.com/en-us/azure/developer/typespec/overview)
- [Google GAPIC generators](https://googleapis.github.io/gapic-generators/)
