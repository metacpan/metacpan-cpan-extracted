# Adapter contract

**Audience:** authors of per-port signature adapters (one per language).
**Companion files:** [`surface_schema_v2.json`](surface_schema_v2.json),
[`type_vocabulary.yaml`](type_vocabulary.yaml),
[`type_aliases.yaml`](type_aliases.yaml).

A *signature adapter* is the small program each port ships that runs the
port's native API-extraction tool (`griffe`, `System.Reflection`,
`api-extractor`, `cargo-public-api`, `revapi`, `phpDocumentor/Reflection`,
`yard --json`, Type::Tiny `signature_for`, `libclang`) and translates the
resulting native shape into the canonical signature JSON shape defined by
`surface_schema_v2.json`. Every port has exactly one adapter; every
adapter writes to the canonical shape.

This document is the contract. Follow it and your adapter slots into the
audit pipeline; deviate and `diff_port_signatures.py` will reject your
output before it can mask drift.

## What the adapter MUST do

1. **Run the port's native tool.** The contract names a specific tool per
   port (see `SIGNATURE_AUDIT_PLAN.md` Phase 4). Adapters do not invent
   their own enumeration. They consume the chosen tool's structured output
   and forward.

2. **Translate native types via `type_aliases.yaml`.** The native tool
   emits types in the language's own type system (e.g. `System.String`,
   `java.lang.Integer`, `&str`). The adapter looks up each native type in
   `type_aliases.yaml` under its language section and emits the canonical
   form. **Do not infer types from heuristics.** If `type_aliases.yaml`
   doesn't have an entry, fail loudly (see rule 5).

3. **Translate names to Python-canonical form at adapter time.** The
   canonical inventory uses Python's naming conventions: snake_case method
   names, dotted module paths (`signalwire.core.agent_base`), PascalCase
   class names. Adapters MUST convert their native names (`SetPromptText`
   in C# / TS, `set_prompt_text` in Ruby/Perl, `SignalWire::Agent::set_prompt_text`
   in C++) to the Python-reference form during emit, not at diff time.
   Otherwise diffs don't line up.

4. **Validate output against `surface_schema_v2.json` before writing.**
   Use the language's standard JSON Schema validator. If the output
   doesn't validate, the adapter exits non-zero and prints which property
   failed. Do not write a non-validating file to disk.

5. **Fail loudly on any type not in `type_vocabulary.yaml` AND not
   resolvable via `type_aliases.yaml`.** The adapter raises an exception
   with file:line of the source method, the offending native type, and a
   suggestion: extend the vocabulary with rationale, add an alias entry,
   or document the divergence in `PORT_SIGNATURE_OMISSIONS.md`.
   **Never** silently fall back to `any`. `any` is a type the SDK
   uses deliberately (when the Python reference has `Any`); it is not the
   adapter's escape hatch for unknown.

6. **Ship golden tests.** Every adapter ships ~20–30 hand-curated input/
   output pairs in `tests/<port>_adapter/golden/<symbol>.json`. Each
   golden pair takes a known method's native representation and asserts
   the adapter's emitted canonical JSON byte-matches the curated file.
   Goldens are the contract: a future adapter rewrite that breaks them
   fails CI loudly. The first 5 goldens MUST cover: a simple positional
   method, an optional / nullable parameter, a generic / parameterized
   return type, a callable parameter, and a class-reference parameter.

7. **Be reproducible.** Given the same source tree and the same pinned
   tool version, two runs produce byte-identical canonical JSON. No
   timestamps, no machine-specific paths, no sort-order differences.

## What the adapter MUST NOT do

- **Infer.** No heuristics, no regex over source code, no "well, the
  parameter is named `path` so it's probably a string." If the native tool
  doesn't tell you the type, the answer is "fail loudly," not "guess
  string."
- **Re-implement parsing.** The native tool already handles the language's
  hard parts (templates in C++, generics in .NET, trait resolution in
  Rust). Forward its answer. Don't reparse the source yourself.
- **Hide differences via permissive aliases.** If you find yourself
  tempted to add `JavaScript.Object: any` so the adapter passes, stop:
  that masks drift. Find the specific case the tool emits and alias that
  case narrowly, not the whole `Object` family.
- **Ship a `signature_confidence: best_effort` field.** If your adapter
  can't produce trustworthy output for some method, that method goes in
  `PORT_SIGNATURE_OMISSIONS.md` with rationale. The audit either trusts
  every entry it sees or doesn't ship.

## Output file layout

```
<port-repo>/
  port_signatures.json          # canonical, schema-valid output
  PORT_SIGNATURE_OMISSIONS.md   # documented divergences from Python reference
  tests/<port>_adapter/golden/  # ~20–30 golden test files
  scripts/enumerate_signatures.<ext>  # the adapter itself
```

`port_signatures.json` is committed alongside the existing
`port_surface.json` (the name-only inventory). The two coexist; the
existing surface-audit keeps using `port_surface.json`, while the new
signature-audit uses `port_signatures.json`.

## Diff and CI

`diff_port_signatures.py` (porting-sdk) consumes the port's
`port_signatures.json`, the reference `python_signatures.json`, and the
port's `PORT_SIGNATURE_OMISSIONS.md`, and reports drift. It is the
audit-time equivalent of `diff_port_surface.py` — same UX, signature-
level resolution.

CI integration: each port's CI workflow runs the adapter, validates
output against the schema, and runs `diff_port_signatures.py` against
the reference. Failure conditions are:

- Schema validation failed (adapter bug)
- Diff found drift not covered by `PORT_SIGNATURE_OMISSIONS.md`
- Golden test broken (adapter regression)
- Loud failure raised inside the adapter (unknown type)

Phase 6 of `SIGNATURE_AUDIT_PLAN.md` adds a cross-port consistency probe:
~50 known-parity methods, all 9 ports, byte-identical canonical output.
Catches single-port adapter drift the day it happens.

## Why this contract is small

Because the work is mechanical, not creative. The native tools do the
parsing; `type_aliases.yaml` handles the cross-language vocabulary; the
schema validates structure; the goldens lock the cases. The adapter is
glue. Glue should be a switch statement, not a heuristic engine.

## Where to push back on this contract

If a real port hits a limitation that isn't covered above — e.g. a
language whose tool emits a structurally-different shape, or a SignalWire
SDK feature that genuinely requires a generic type variable not modelled
in `type_vocabulary.yaml` — the right move is to file an issue with the
specific case, propose a concrete extension to one of the three v2 files
(schema, vocabulary, aliases), and ship the change in lockstep across the
porting-sdk and the affected adapter. Do not work around the contract
silently.
