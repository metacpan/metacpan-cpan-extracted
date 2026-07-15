# High-Priority Proposal: A Source-Mapped Template Compiler

Status: Proposed

Priority: Highest architectural improvement for the next development cycle

## Summary

Replace the current sequence of raw template-string rewrites with a small,
source-mapped intermediate representation (IR).

The goal is not to build a large template AST or replace PPI. The goal is to
make source location, output behavior, and transformation intent explicit.
Each parsed template node should retain the source span that produced it, and
all later transformations should operate on those nodes instead of preserving
line numbers indirectly through replacement strings and escaped-newline
sentinels.

This is the single highest-leverage improvement because it addresses the
systemic cause of several recent diagnostic bugs while making future syntax
safer to add. It also creates natural module boundaries without performing a
cosmetic split of `Template::EmbeddedPerl.pm`.

## Why This Matters

The current compiler obtains the right behavior through several interacting
string protocols:

1. `Template::EmbeddedPerl::Arguments->rewrite` replaces `% args` with generated
   Perl and manually adds newlines to preserve source positions.
2. Smart-line conversion rewrites `%` and `%=` lines into ordinary template
   tags and adds `\\\n` sentinels for consumed physical newlines.
3. Comment removal, trim-close handling, escaped delimiters, and interpolation
   rewrite the same text again.
4. `compile` interprets leading and trailing `\\\n` sequences as generated
   Perl newlines rather than rendered output.
5. A top-level `#line` directive resets generated Perl to the template source,
   after which correctness depends on every previous rewrite preserving the
   exact physical newline count.

Each part is locally understandable, but their composition is fragile. A
change to one rewrite can alter the assumptions of another. The recent bugs
around repeated continued comments, smart lines, wrappers, source names, and
warning locations are examples of that coupling.

The growing regression matrix is valuable, but tests alone cannot make an
implicit source-position protocol easy to extend. Source location should be a
first-class compiler value rather than an emergent property of generated
newline counts.

## Current Pipeline

At a high level, `from_string` currently performs this work:

```text
raw template
  -> normalize line endings
  -> rewrite % args into template syntax
  -> rewrite smart lines into template syntax
  -> split template tags with regular expressions
  -> remove comments and process escaping/trimming/interpolation
  -> parse embedded Perl fragments with PPI
  -> concatenate generated Perl strings
  -> repair generated line counts with newlines
  -> wrap in package/subroutine code and add #line
  -> eval
```

The proposed pipeline is:

```text
raw template
  -> SourceDocument
  -> source-aware lexer
  -> source-mapped IR nodes
  -> semantic transforms over nodes
  -> PPI analysis of Perl-bearing nodes
  -> source-aware Perl code generation
  -> wrapper generation and eval
```

The key difference is that every stage receives and returns structured nodes
with source spans. No stage must infer source position from replacement-string
length or synthetic newlines.

## Goals

- Preserve rendered output byte-for-byte for all existing templates.
- Preserve every existing public constructor option and rendering API.
- Preserve custom delimiters, custom line markers, and custom comment markers.
- Preserve existing block-capture behavior and continue using PPI to analyze
  embedded Perl.
- Report the correct source, line, and eventually column for compile errors,
  runtime errors, warnings, and compiler-generated validation errors.
- Make comments, smart lines, trimming, interpolation, and `% args` independent
  transformations with explicit contracts.
- Give future syntax extensions a supported way to preserve source mappings.
- Create small compiler components that can be tested without rendering a full
  template.
- Keep the no-feature fast path inexpensive.

## Non-Goals

- Do not replace embedded Perl with a restricted expression language.
- Do not turn the core template engine into an HTML parser.
- Do not implement HTML attribute directives as part of this migration.
- Do not replace PPI unless a separate investigation demonstrates a concrete
  need.
- Do not redesign typed views, partials, layouts, content blocks, or render
  frames.
- Do not change escaping defaults or safe-string behavior.
- Do not expose the new IR publicly in the first release.
- Do not require Moo or another object framework as a runtime dependency.

## Design Principles

### 1. Source positions are data

Every node carries an immutable source span. Generated nodes carry an explicit
anchor span and a reason describing the transform that created them.

### 2. Output behavior is explicit

Trimming or suppressing a newline should be represented as node metadata or as
an explicit change to a text node. It should not be encoded in a magic string
that a later compiler stage must recognize.

### 3. Perl remains Perl

Embedded code and expressions remain strings of Perl associated with source
spans. PPI continues to analyze those fragments for block-capture behavior and
argument syntax.

### 4. Core parsing remains format-neutral

The engine supports HTML, plain text, JavaScript, and other output. The core IR
must describe template structure, not HTML structure. An optional future HTML
directive preprocessor can produce source-mapped template nodes without making
the core compiler HTML-specific.

### 5. Compatibility precedes cleanup

Introduce the new pipeline behind characterization tests. Switch production
compilation only after old and new behavior agree. Remove compatibility hacks
after the new path is established, not before.

## Source Model

Introduce an internal `SourceDocument` value containing:

```text
normalized_text
diagnostic_source
line_start_offsets
original_line_ending_metadata (optional)
```

The normalized text should preserve the engine's existing line-ending
semantics. Source spans refer to offsets in that normalized text.

A `SourceSpan` should contain at least:

```text
start_offset
end_offset
start_line
start_column
end_line
end_column
```

Line numbers are one-based for diagnostics. Offsets and columns may be stored
zero-based internally if that simplifies slicing. The convention must be
documented and tested.

Columns should count Perl characters rather than encoded UTF-8 bytes. This
keeps diagnostics meaningful for decoded Unicode templates. Byte encoding is
only a storage or hashing concern, not a source-coordinate concern.

Generated code that does not correspond one-to-one with source text should use
an anchored origin:

```text
origin_span: the directive or node that caused generation
generated_by: args | interpolation | capture | wrapper | other
```

The wrapper itself has no template span and should remain outside template
diagnostic mapping.

## Minimal Intermediate Representation

The first IR should remain deliberately small.

### Text

```text
type: text
value: exact rendered text
span: SourceSpan
```

The value is the post-template-syntax text that should be appended to output.
Escaped delimiters and comment removal are resolved before code generation.

### Code

```text
type: code
perl: embedded Perl source
span: SourceSpan
ppi: optional analyzed PPI document
capture_open: boolean or structured capture metadata
capture_close: boolean or structured capture metadata
```

### Expression

```text
type: expression
perl: embedded Perl expression
span: SourceSpan
trim_value: boolean
auto_escape: inherited compiler option
auto_flatten: inherited compiler option
```

Compiler options can remain on the compiler rather than being copied onto each
node. The important point is that expression behavior is explicit, not encoded
by altering the Perl string prematurely.

### GeneratedCode

```text
type: generated_code
perl: compiler-generated Perl
origin_span: SourceSpan
generated_by: descriptive identifier
```

This node supports generated argument bindings and capture plumbing while
keeping their diagnostic origin explicit.

### Optional Directive Node

An `args` node may be useful during parsing:

```text
type: args
declarations: parsed declaration records
span: SourceSpan
```

It can then lower into one or more `generated_code` nodes. This is preferable
to replacing the directive with a synthetic `<% ... %>` string and parsing the
replacement a second time.

Do not introduce additional node types until a real transformation requires
them.

## Proposed Compiler Stages

### Stage 1: Normalize and index the source

- Normalize line endings exactly as the current engine does.
- Build line-start offsets once.
- Normalize the diagnostic source label once.
- Retain the normalized template for diagnostic excerpts and caching.

### Stage 2: Lex template structure

Scan the template once and emit source-mapped nodes for:

- ordinary text;
- code tags;
- expression tags;
- smart code lines;
- smart expression lines;
- comments;
- escaped syntax markers;
- trim-close markers;
- `% args` directives.

The scanner must honor configured open, close, expression, line, and comment
markers. It does not need to understand Perl beyond locating template syntax.

A scanner is preferable to a growing stack of global regular-expression
substitutions because it has one cursor, one source document, and explicit
span creation. Regular expressions can still recognize local syntax at the
cursor.

### Stage 3: Apply semantic transforms

Transforms receive nodes and return nodes while preserving or deriving source
spans.

Initial transforms:

- validate and lower `% args`;
- split interpolated text into text and expression nodes;
- apply comment removal;
- apply leading/trailing newline trimming;
- unescape syntax markers;
- prepare capture metadata for embedded Perl blocks.

The exact ordering is part of the compiler contract and must be documented.
Each transform should have focused tests proving both node output and source
mapping.

### Stage 4: Analyze Perl-bearing nodes

Use PPI for the jobs it currently performs well:

- parse argument declarations;
- identify unmatched block openings and closings;
- distinguish control blocks from value-producing blocks;
- inject capture plumbing where required.

Avoid mutating a PPI tree without preserving the originating node's span.
Generated PPI tokens should remain associated with the node that caused them.

### Stage 5: Generate Perl

Generate wrapper code separately from template body code.

Before each executable template node, emit a native Perl line directive for
that node's source line:

```perl
#line 12 "views/example.epl"
```

For a multiline Perl node, Perl's normal line counting handles subsequent
lines. The next node resets the location again, so generated output statements
and capture plumbing do not cause drift between source nodes.

Text nodes should generate output append statements without relying on their
generated Perl newline count to preserve later diagnostics.

### Stage 6: Compile and cache

- Evaluate generated Perl as today.
- Keep the cache source-aware.
- Include all compiler options that alter generated code in cache identity.
- Keep normalized source labels safely serialized before hashing.
- Store the source document or sufficient line data for runtime diagnostic
  excerpts.

Cache-key expansion beyond the current source-label fix should be handled only
when the new compiler makes option identity explicit. It should not become an
unbounded configuration redesign.

## Diagnostics

The new pipeline should support two diagnostic classes.

### Compiler-owned diagnostics

Lexer and transform errors should be structured internally:

```text
message
source
span
category
```

Examples include malformed `% args`, unterminated template tags, or invalid
future directives. Formatting occurs once at the public boundary.

### Native Perl diagnostics

Generated Perl should use exact per-node `#line` directives. Native compile
errors, runtime exceptions, and warnings can then report template locations
without reconstructing offsets from the generated wrapper.

The existing formatter remains responsible for:

- adding nearby template lines;
- preserving unrelated helper or module locations;
- preserving render stacks;
- accepting only exact template or legacy eval locations.

With per-node directives, the formatter no longer depends on generated Perl
having the same total newline count as the template.

## Public API Compatibility

`parse_template` and `compile` are documented methods. The migration must not
silently change their signatures or return values.

Recommended compatibility approach:

1. Add a private `_parse_document` method that returns the new IR.
2. Keep `parse_template` callable with its existing arguments and legacy array
   return shape during the compatibility period.
3. Implement `parse_template` as an adapter over the new IR once parity is
   established.
4. Add a private `_compile_document` method for IR compilation.
5. Keep `compile` as a compatibility adapter for existing callers.
6. Move `from_string` to the private document pipeline only after parity tests
   pass.

If the legacy methods cannot represent a new internal behavior, deprecate them
with a documented release window rather than changing them in place. A future
major release can decide whether the IR should become public.

The following APIs and behaviors must remain unchanged:

- `new`, class-method construction, and subclass configuration;
- `from_string`, `from_file`, `from_fh`, and `from_data`;
- `render` and `render_view`;
- compiled object's `render` behavior;
- helper injection and helper override behavior;
- typed view construction and template resolution;
- partial, layout, yield, and named content behavior;
- safe-string and escaping behavior;
- template directory priority;
- source-aware cache reuse and isolation.

## Suggested Internal Module Boundaries

The module split should follow ownership created by the IR, not line count.

```text
Template::EmbeddedPerl::SourceDocument
Template::EmbeddedPerl::SourceSpan
Template::EmbeddedPerl::Parser
Template::EmbeddedPerl::IR
Template::EmbeddedPerl::Transform::Arguments
Template::EmbeddedPerl::Transform::Interpolation
Template::EmbeddedPerl::PerlAnalyzer
Template::EmbeddedPerl::Compiler
Template::EmbeddedPerl::Diagnostic
```

This is a direction, not a requirement to create every file immediately.
Start with the smallest boundaries that make source mapping testable. Plain
blessed values with simple accessors are sufficient; do not add a runtime object
framework solely for internal compiler records.

`Template::EmbeddedPerl` should remain the facade that owns configuration,
helpers, source loading, caching, and public construction methods.

## Incremental Migration Plan

### Phase 0: Characterize current behavior

- Expand byte-for-byte output fixtures for every syntax feature.
- Keep exact diagnostic tests for compile errors, runtime errors, and warnings.
- Record custom delimiter, marker, CRLF, Unicode, cache, and wrapper behavior.
- Build a representative corpus from existing test templates and cookbook
  examples.
- Establish a basic compile-time benchmark.

Exit condition: current behavior is captured well enough to compare two
compiler paths mechanically.

### Phase 1: Introduce source values

- Add internal `SourceDocument` and `SourceSpan` values.
- Add tests for ASCII, Unicode, LF, CRLF, empty input, and final lines without a
  newline.
- Do not change production parsing yet.

Exit condition: any normalized source offset can be converted reliably to a
line and column.

### Phase 2: Build the source-aware lexer

- Emit minimal IR nodes without PPI analysis.
- Compare reconstructed output or node coverage against the original source.
- Test all configured syntax markers and escaping combinations.
- Run the lexer in tests alongside the current parser, not as a permanent
  production dual path.

Exit condition: the lexer covers every source character exactly once or marks
it explicitly as consumed syntax.

### Phase 3: Move transformations one at a time

Recommended order:

1. comments and escaped comment markers;
2. smart lines;
3. trim-close behavior and escaped newlines;
4. interpolation;
5. `% args` parsing and lowering;
6. capture-block metadata.

For each transformation:

- add focused IR and span tests;
- compare rendered output with the current compiler;
- compare diagnostics for affected templates;
- remove the corresponding string rewrite only after parity.

Exit condition: the new IR contains all information required for code
generation without newline sentinels.

### Phase 4: Generate Perl from the IR

- Add `_compile_document`.
- Emit per-node `#line` directives.
- Preserve wrapper, preamble, prepend, escaping, flattening, and capture
  behavior.
- Compare output and diagnostics against the existing compiler over the full
  corpus.

Exit condition: the new compiler passes all existing tests and the parity
corpus without using synthetic source-count newlines.

### Phase 5: Switch `from_string`

- Route production compilation through the new private pipeline.
- Retain public compatibility adapters.
- Remove dead string-rewrite and sentinel code.
- Run full tests, POD checks, distribution build checks, and benchmarks.

Exit condition: one production compiler path remains and public behavior is
unchanged.

### Phase 6: Validate extensibility

Only after migration is complete, design one small optional syntax extension
against the new transform interface. HTML attribute directives are a likely
candidate, but they should have their own design cycle and should not be used to
justify unneeded IR complexity in advance.

Exit condition: the extension can preserve source spans without modifying core
code generation or reintroducing raw-string line repair.

## Testing Strategy

### Output compatibility

- Compare old and new compilers byte-for-byte over a fixed template corpus
  while both implementations exist in tests.
- Cover empty output, whitespace-only output, no final newline, CRLF input,
  escaped syntax, comments, smart lines, trims, interpolation, args, block
  capture, partials, layouts, content blocks, and typed views.
- Test safe strings and auto-escaping independently from parser changes.

### Source mapping

For each syntax family, test:

- compile failure location;
- runtime failure location;
- warning location;
- source path with spaces, quotes, controls, Unicode, and ` line <digits>`;
- preamble and prepend with multiple lines;
- first, middle, and final template positions;
- templates with and without a final newline;
- custom delimiters and markers;
- LF and CRLF input.

Assertions should check exact source and line, not merely the presence of an
error.

### Transform contracts

Each transform should have tests that inspect nodes directly:

- input node sequence;
- output node sequence;
- unchanged spans;
- generated-node anchor spans;
- exact output-affecting metadata.

These tests should avoid asserting incidental generated Perl formatting.

### Perl generation

- Test generated code only at stable boundaries such as `#line` placement and
  wrapper separation.
- Prefer rendering and diagnostic behavior over full generated-string snapshots.
- Retain explicit block-capture tests because PPI tree mutation is specialized
  behavior with a high regression cost.

### Composition and cache behavior

- Retain nested partial, layout, and typed-view render-stack tests.
- Verify identical template and source reuse a coderef.
- Verify identical text under different sources does not share stale source
  metadata.
- Verify Unicode sources remain cacheable.
- Verify compiler options that change generated code cannot collide.

### Fuzz and property testing

After the deterministic suite is stable, add bounded generated cases for:

- random text surrounding escaped and unescaped delimiters;
- random newline placement;
- repeated comments and smart lines;
- combinations of trim markers;
- Unicode text and source names.

Useful properties include no parser crash, full source coverage, deterministic
IR, and output parity with the legacy compiler for supported inputs.

## Performance Requirements

- Templates without optional syntax should not incur a material compile-time
  regression.
- Rendering performance should remain unchanged because parsing and IR work
  happen before render.
- Line-offset indexing should be linear in template length and performed once.
- Transform passes should be linear in node count wherever possible.
- Avoid reparsing the entire template for each syntax feature.
- Cache-hit behavior should not construct a fresh IR unless needed for returned
  metadata.

Record a baseline before migration. A practical initial acceptance threshold is
no more than a 10 percent compile-time regression on representative templates,
unless the slower result is explicitly accepted for a measured correctness
benefit.

## Major Risks And Mitigations

### Block capture is unusually specialized

Risk: moving code boundaries changes how unmatched PPI blocks are identified or
how `$_O` is localized and returned.

Mitigation: migrate capture handling last, preserve the existing PPI behavior
initially, and use focused nested `map`, callback, control-block, and signature
tests.

### Trimming and escaping have many interactions

Risk: a cleaner parser accidentally changes output whitespace.

Mitigation: treat text-node values as exact output contracts and require
byte-for-byte parity fixtures before switching production paths.

### Public parser/compiler methods are documented

Risk: internal cleanup breaks callers using `parse_template` or `compile`.

Mitigation: add private IR methods and compatibility adapters. Do not change
documented return shapes in a minor release.

### Custom syntax markers create ambiguous local grammars

Risk: a scanner works for defaults but not multi-character or overlapping
custom markers.

Mitigation: define marker precedence explicitly and port all custom-marker
tests before production cutover.

### Unicode offsets can mix characters and bytes

Risk: columns or slices are wrong for decoded templates.

Mitigation: use character offsets inside `SourceDocument`; encode only at I/O or
hash boundaries.

### A long-lived dual compiler doubles maintenance

Risk: parity scaffolding becomes permanent.

Mitigation: keep the alternate path private and test-only, define phase exit
criteria, and delete the old implementation immediately after production
cutover passes verification.

## Alternatives Considered

### Split `Template::EmbeddedPerl.pm` without changing representation

This would improve navigation but retain the hidden newline protocol across
module boundaries. It treats the symptom rather than the primary design issue.
Module extraction should follow the new ownership boundaries.

### Add more newline-repair helpers

Centralizing sentinel counting would reduce duplication but would not make
transform origins explicit. Every new syntax feature would still need to obey
the same implicit generated-line contract.

### Build a full template or HTML AST

A full AST is unnecessary for the current engine and risks making a
format-neutral template compiler HTML-specific. A small token/IR sequence with
source spans provides the needed correctness and extensibility at lower cost.

### Replace PPI

PPI enables the engine's distinctive block-capture behavior. Replacing it would
add substantial risk without addressing the raw-template source mapping issue.

### Keep the current compiler and rely on regression tests

The existing tests should remain, but the number of interaction tests grows
combinatorially as syntax is added. Tests are most effective when paired with a
representation that makes invalid source mappings difficult to express.

## Definition Of Done

- [ ] Existing rendered output is byte-for-byte identical across the parity
      corpus.
- [ ] All current public methods and documented return shapes remain compatible.
- [ ] Every template node carries a source span.
- [ ] Generated nodes carry an explicit source anchor and generation reason.
- [ ] `% args`, smart lines, comments, trimming, interpolation, and capture
      behavior no longer depend on synthetic newline sentinels.
- [ ] Code generation emits source directives at executable node boundaries.
- [ ] Compile errors, runtime errors, and warnings report exact template sources
      and lines across the diagnostic matrix.
- [ ] Preamble and prepend code do not affect template locations.
- [ ] Helper and module diagnostics remain untouched.
- [ ] Cache reuse and source isolation remain correct, including Unicode paths.
- [ ] Partial, layout, content-block, and typed-view composition suites pass.
- [ ] Full test suite, POD checks, distribution checks, and diff checks pass.
- [ ] Compile-time benchmark remains within the accepted threshold.
- [ ] The legacy production parser/compiler path and sentinel repair code are
      removed after cutover.
- [ ] Internal architecture and source-span conventions are documented.

## Recommended First Deliverable

Do not begin by rewriting `parse_template`.

The first implementation deliverable should contain only:

1. `SourceDocument` and `SourceSpan` internal values;
2. line/column tests for LF, CRLF, Unicode, empty input, and no final newline;
3. a source-aware lexer that recognizes existing tags and text without applying
   semantic transforms;
4. tests proving complete source coverage and correct spans;
5. no production behavior change.

That deliverable validates the core representation at low risk. Once it is
stable, the transformation and code-generation phases can proceed as separate,
reviewable changes.
