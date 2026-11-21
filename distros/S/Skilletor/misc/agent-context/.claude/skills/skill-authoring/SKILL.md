---
name: skill-authoring
description: "Use when writing or reworking a SKILL.md, or when a skill misfires — never triggers, fires on the wrong tasks, or is read but not followed."
---

# Skill Authoring

A skill is context loaded on demand. Only its `description` is always in the
agent's window; the body loads when the description fires. That makes the
description a router and the body a payload — and they follow different rules.

## Workflow

1. **Decide it should exist.** A skill earns its place when the knowledge is
   not derivable from the code, will be needed again, and an agent without it
   demonstrably does the wrong thing. Run the task once *without* the skill and
   watch what fails — that failure is the spec. No observed failure, no skill.
2. **Pick the archetype** — reference, convention, workflow, or concept. Each
   has its own structure and quality bar: [references/archetypes.md](references/archetypes.md).
3. **Write the description first** (rules below). If you cannot state when the
   skill should fire, the skill has no boundary yet.
4. **Write the body** (rules below).
5. **Test with a fresh agent**, never by rereading it yourself: give a subagent
   the task from step 1 with the skill present and compare against the baseline.
   Reading a skill and finding it clear proves nothing — you wrote it.
6. **Prune.** Delete every sentence the agent would do anyway. The test is
   behavioral: does the line change what the agent does versus its default?

## Description rules

The description decides whether the skill ever fires. It states **when to use
the skill — never how the skill works.**

- Triggering conditions only: tasks, symptoms, error messages, file types,
  the words a user would actually say. A workflow summary in the description
  is actively harmful — the agent follows the summary and skips the body.
- Third person, starts from the trigger ("Use when…").
- Include the search terms an agent would grep for: exact command names,
  error strings, synonyms ("compress/merge/shorten").
- One description per genuinely distinct trigger. Synonyms of one trigger are
  one trigger.

```yaml
# Bad — summarizes the process; the body will be skipped
description: Scaffolds dist.ini, cpanfile and t/ by copying a sibling dist

# Good — trigger conditions only
description: Use when creating a new CPAN distribution or polishing an
  existing one to house conventions — dist.ini, cpanfile, Changes, CI.
```

## Body rules

- **Assume a smart agent.** Explain the convention, the gotcha, the reason —
  never what a PDF is or how a library works. Challenge every paragraph:
  would the agent do this wrong without it?
- **One excellent example** beats three mediocre ones. Real, runnable, from an
  actual case. Never dilute across languages.
- **Progressive disclosure:** body under ~150 lines; heavy reference and
  branch-specific material goes to `references/*.md`, templates to
  `templates/`, runnable helpers to `scripts/` — each linked from the body,
  one level deep, never chained. Inline what every path through the skill
  needs; disclose what only some paths reach.
- **State the positive form.** "Write one-line comments" beats "don't write
  long comments" — a prohibition activates the thing it bans. Reserve
  prohibitions for hard guardrails, and pair them with the positive target.
- **Match form to failure.** Skipped-under-pressure rule → prohibition plus
  the exact rationalizations to refuse. Wrong-shaped output → a recipe or
  template stating what the output *is*. Omitted element → a required slot in
  the template. Condition-dependent behavior → "if X, then Y" keyed to
  something observable. Appending "unless it matters" to any of these reopens
  the negotiation — express real exceptions as their own conditional.
- **Completion criteria that can be checked.** "Every template placeholder
  substituted" drives work; "make sure it's complete" drives nothing.
- **Consistent terminology** — one term per concept, the same term the code
  and the other skills use.
- **No time-sensitive content.** No dates, no "the new API", no versions that
  will silently go stale; put superseded material under an explicit
  "old patterns" heading or delete it.
- Relative forward-slash paths inside the skill dir (`templates/dist.ini`),
  and say whether a script is to be **executed** or **read** — those are
  different instructions.

## Testing

Baseline first, then verify — both with fresh subagents, both on the real task:

1. **Baseline (without skill):** confirm the failure actually happens. If the
   agent already does it right, the skill is a no-op — stop.
2. **Verify (with skill):** the agent finds the skill from its description
   alone, follows the body, and the baseline failure is gone.
3. For discipline rules, add pressure to the scenario (deadline, sunk cost,
   "just this once") and collect the rationalizations the agent produces —
   each one becomes an explicit counter in the skill.

One run per side is a smoke test; trust it for retrieval and shape, not for
discipline rules — those need repeated runs before you believe them.

## Common mistakes

| Mistake | Fix |
|---|---|
| Description summarizes the workflow | Rewrite to triggers only |
| Narrative of one past session | Extract the reusable rule, drop the story |
| Restates what a linked skill/doc already says | Cross-reference by name |
| Duplicate of the environment (`--help`, config, layout) | Point at the lookup; cache only what no lookup reveals |
| Grows by accretion, never shrinks | Prune on every edit — stale layers cost every load |
| Tested by rereading it yourself | Fresh subagent on the real task |

## Related

- `skill-compressor` — shrinking or merging existing skills.
- `getty-skill-library` — where a skill lives, what it is named, and how it is
  shared (Getty's library conventions).
