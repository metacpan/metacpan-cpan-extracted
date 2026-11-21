---
name: skill-assessment
description: "Use when judging how good or how strong a skill, agent or rule file is — auditing a SKILL.md, a .claude/agents/*.md or a rules file, scoring a skill set or a skilletor source, deciding whether a skill earns its context cost, checking that a description triggers and the body is followed, or comparing two versions of a skill. Also for 'is this skill any good', 'does this skill even fire', /skill-doctor and claude plugin eval results."
---

# Skill Assessment

Measures two different things and never confuses them:

- **Quality** — what the text is: a router that fires on the right prompts and a
  payload that changes behavior per token spent. Judged against a rubric,
  criterion by criterion.
- **Strength** — what the text does: the behavior delta between an agent with
  and without it. Measured by runs, never inferred from reading.

A skill can be well-written and weak (the agent did it right anyway) or ugly
and strong. Report both, separately. Authoring the fix is `skill-authoring`'s
job; shrinking is `skill-compressor`'s; checking a convention against real code
is `skill-mining`'s. This skill produces the verdict and the routed fix list.

## Workflow

1. **Inventory.** List every item under assessment with type (skill / agent /
   rule), size and description length:
   `node scripts/skill-static-check.mjs --inventory <paths…>`.
2. **Static check** (execute): `node scripts/skill-static-check.mjs <paths…>`.
   Mechanical criteria only — frontmatter keys, description budget, body
   length, unresolved references, chained references, time-sensitive
   wording, pleading, agent tool keys, briefing resolution, rules budget.
   One line per finding, non-zero exit on errors.
3. **Rubric pass** (read): [references/rubric.md](references/rubric.md).
   Walk sections A–C for every item, E for agents, F for rules. Score yes/no
   per criterion; every fail gets a route.
4. **Strength** — only for skills whose quality pass did not already end in
   "delete" or "split": run the measurement below, record the level with the
   evidence line.
5. **Scorecard** in the rubric's format, one block per item, then a fix list
   ranked by (strength lost × ease). File each fix as a ticket where a board is
   in scope; do not fix in the same pass — an assessor that edits stops
   measuring and starts defending its edits.

Done when: every item has a scorecard block, every fail carries a route, every
strength level above S0 quotes a run.

## Measuring strength

Three instruments, cheapest first. Use the one that fits; state which you used.

### 1. Two-arm eval — `claude plugin eval` (skills in a plugin or source)

The eval runner runs each case with and without the plugin and reports
**Δ = with − without** per case — that Δ *is* the strength number. A source in
skilletor layout (`skills/<name>/SKILL.md`) is a plugin once it has a
`.claude-plugin/plugin.json`; a lone skill gets a throwaway wrapper directory
with that manifest and the skill under `skills/`.

Suite layout, one directory per case:

```
evals/<case>/prompt.md          # frontmatter: max_turns, timeout_seconds, allowed_tools; body = the prompt
evals/<case>/graders/fired.md   # type: tool_used, tool: Skill, input_match on the skill name → S1 (retrieval)
evals/<case>/graders/effect.md  # type: llm | regex | file_exists — the baseline failure, stated as PASS/FAIL → S2
```

```bash
claude plugin eval <plugin-dir> --runs 3 --no-publish --json results.json   # two-arm by default
claude plugin eval <plugin-dir> --case '<name>' --runs 1                     # smoke
```

Read `cases[].aggregates.delta`: ≈0 with a passing without-arm → S0; the
`fired` grader passing but no delta → S1 (retrieved, not followed); positive
delta → S2. Off-target retrieval: add one case with an unrelated prompt and a
`fired` grader set to `max: 0`. Results land in `evals/results/` — keep that
out of git. Every run is billed and takes minutes; say so before starting one
on someone else's account.

### 2. Fresh-subagent A/B (agents, rules, anything not in a plugin)

Same idea by hand, per `skill-authoring` "Testing": one subagent with the
item present, one without, same real task, compare the transcripts on the
baseline failure. Retrieval is tested by giving only the description (the
skill listing) and asking the agent to pick. For discipline rules add
pressure (deadline, sunk cost, "just this once") and collect the
rationalizations — each becomes a counter in the text. One run per side is a
smoke test; S3 needs repeated runs.

For a briefed agent the retrieval question is different: the skill is forced
into context, so measure whether the agent answers a skill-only question
**without** calling the `Skill` tool. Reaching for `Skill` means the briefing
did not fire.

### 3. Field signal — `/skill-doctor`

Reports uses in the last 7 days and context cost per loaded skill. A skill
with zero uses is either not needed here or has a router that never matches
(A1–A3) — decide which by reading the description against the prompts that
should have hit it. High cost with low use is a `skill-compressor` candidate.
This measures the installed set on one machine, not the skill in general.

## Judging without fooling yourself

- **Rereading is not testing.** Finding a skill clear proves nothing about
  whether an agent without your context follows it.
- **The baseline decides.** No observed failure without the skill → S0,
  whatever the prose looks like; the honest verdict is "delete".
- **A summarising description hides a weak body.** When the agent follows the
  description and never reads the body, the body is dead weight — check by
  putting a fact only the body carries into the task.
- **Size is a cost, not a merit.** Report effect per line; a long S2 loses to a
  short S2.
- **Assess the version on disk**, by path, and quote line numbers — a verdict
  nobody can locate is a remark.

## Related

- `skill-authoring` — description and body rules the rubric is built on.
- `skill-compressor` — the route for "too long for its effect".
- `skill-mining` — the route for "is this convention real".
- `getty-skill-library` — where a skill lives and how an installed one is
  edited in its source.
