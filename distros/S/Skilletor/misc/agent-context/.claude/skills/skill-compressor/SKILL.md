---
name: skill-compressor
description: "Use when a skill, prompt or instruction file must shrink — compressing one, merging overlapping ones, cutting token cost."
---

# Skill Compressor

Convert verbose skills into compact, high-signal ones: minimum tokens, same
behavior. Extract execution rules — never just shorten prose. Treat the source
as material, not wording.

## Method

1. Read everything; write the one-line purpose.
2. Extract what changes behavior: hard rules, decision rules, workflow order,
   output formats, edge cases, "never" rules, tool usage.
3. Merge duplicates — one meaning, one place.
4. Classify project-specific references (below).
5. Rewrite as imperative rules: one rule per line, short words, no hedging
   ("Merge duplicate rules", never "You should consider analyzing…").
6. Compress examples around the code-safety rules (below).
7. Output the skill; run the self-check.

## Retention priority

Keep, in order: hard constraints · safety rules · output format · decision
rules · workflow steps · edge cases · tool usage · domain terms · minimal
examples. If unsure whether a detail matters → keep it, compressed.

Drop: motivation, repetition, vague advice, filler, redundant second examples.

Never drop: exact commands, exact file names, output schemas, "never" rules,
edge-case logic, tool order, anything about irreversible actions.

## Project-specific references

Find repo names, product names, internal tools, paths, URLs, personal names,
local commands. Classify each:

1. **essential** → keep (`dzil test` in a Dist::Zilla skill *is* the content)
2. **parameter** → `<placeholder>` (`./bin/foo-sync` → `<project sync command>`)
3. **example** → generalize or drop (`ask Paul` → `ask maintainer`)
4. **noise** → remove

Skip this section when compressing a deliberately house-specific skill
(`getty-*`) — its local references are the payload.

## Code example safety

Code blocks teach syntax; mangling them teaches fake syntax. Compress *around*
code, never inside it.

- Allowed: drop a second example of the same shape, collapse prose between
  blocks, shorten lead-ins ("Here is a complete example…" → "Example:").
- Never: delete lines from a block, merge examples that don't share a context,
  replace runnable code with pseudo-code unless marked `# pseudo`.
- Keep every token that changes what the example *does*: `use`/`import`/
  `package` lines, flags, end-of-package idioms, "why" comments
  (`# must come before X`). If the prose says "load A first, then B", both
  lines stay — cutting one turns the example into the bug it warns against.
- Placeholders must be unmistakable: `<MyClass>`, `My::Class`,
  `path/to/file`. Never bare identifiers (`Pkg`, `Foo`, `X`) — they read as
  real code and get pasted. In doubt, keep the realistic original: its token
  cost is tiny, wrong syntax is expensive.

## Names and descriptions

Routing metadata for new or merged skills follows `skill-authoring`
(triggers only, third person, keywords). For an existing skill keep the
original name and description — renames break `briefing.skills` lists and
cross-references in consuming repos. If a clearly better description exists,
append it as a suggestion under an "Optional metadata improvement" heading;
never auto-replace.

## Self-check before output

For each code block: pastable and working (or failing with the intended
lesson)? All `use`/`import` lines present or genuinely irrelevant?
Placeholders obviously placeholders? Every line the prose names still there?

For the whole skill: does each surviving line change behavior? Did any hard
constraint, "never" rule, or output format from the source disappear? If yes —
restore it.
