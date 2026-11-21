# Assessment rubric — skills, agents, rules

Every criterion is a yes/no you can point at: a line in the file, a run you
made, a number. Score by counting fails, not by impression. Each criterion
names the fix route so a fail turns into work, not a remark.

## Contents

- A. Router — the description
- B. Payload — the body
- C. Truth — is it real?
- D. Strength — does it change behavior?
- E. Agents
- F. Rules
- Scorecard format

## A. Router — the description

| # | Criterion | How to check | Fix route |
|---|---|---|---|
| A1 | States **when** to use, never how it works | No process verbs ("scaffolds", "generates X by Y"); no step list | `skill-authoring` |
| A2 | Third person, opens from the trigger | Starts "Use when…" or names the situation first | `skill-authoring` |
| A3 | Carries the grep terms an agent would search | Exact commands, error strings, file types, synonyms present | `skill-authoring` |
| A4 | One trigger, stated once | Synonyms of one trigger; no second unrelated trigger smuggled in | split the skill |
| A5 | Fits the budget | Static check reports length; over budget → the router is truncated in the listing | shorten |
| A6 | Disjoint from siblings | Two skills in the same set do not claim the same prompt; the sibling check in `scripts/skill-static-check.mjs` flags shared trigger terms | merge or sharpen both |

## B. Payload — the body

| # | Criterion | How to check | Fix route |
|---|---|---|---|
| B1 | Every paragraph changes behavior | For each paragraph: would a strong agent do this anyway? Yes → fail | prune (`skill-compressor`) |
| B2 | One archetype | Reference / convention / workflow / concept — not a mix (`skill-authoring` `references/archetypes.md`) | split |
| B3 | One excellent example | Real, runnable as pasted, from an actual case; not three mediocre ones | replace |
| B4 | Positive form | Rules say what to do; prohibitions only for hard guardrails, paired with the target | rewrite |
| B5 | Checkable completion criteria | "Done when…" states something verifiable, not "make sure it is complete" | add the criterion |
| B6 | One term per concept | Same word the code and sibling skills use | normalise |
| B7 | No time-sensitive content | No dates, versions, "new", "recently", "currently" outside an "old patterns" heading | delete or date-proof |
| B8 | Progressive disclosure | Body ≤ ~150 lines; `references/`, `templates/`, `scripts/` linked one level deep, links resolve, no chain | move material out |
| B9 | Does not duplicate the environment | Nothing `--help`, a config file, or the directory listing reveals on its own | point at the lookup |
| B10 | Scripts say execute or read | Each linked script is labelled as one or the other | label it |
| B11 | No pleading | No "MANDATORY: load X first", no "IMPORTANT" shouting — briefing or the description carries that | delete |

## C. Truth — is it real?

| # | Criterion | How to check | Fix route |
|---|---|---|---|
| C1 | Facts check against the tool | Run the commands, read the code the skill describes; each claim holds | correct or delete |
| C2 | Conventions are practised, not invented | Evidence in hand-written code with counts and counter-counts | `skill-mining` |
| C3 | Cross-references resolve | Every named skill, file, ADR exists | fix the name |

## D. Strength — does it change behavior?

Strength is measured, never judged from the text. Each level requires the
previous one.

| Level | Meaning | Evidence required |
|---|---|---|
| S0 | No-op | Baseline run (no skill) already does the right thing — the skill should not exist |
| S1 | Retrieved | Fresh agent finds the skill from the description alone for the target prompt, and does not for two unrelated prompts |
| S2 | Effective | With-skill run removes the baseline failure; the agent follows the body, not just the description |
| S3 | Robust | For discipline rules: holds under pressure (deadline, sunk cost, "just this once") across repeated runs; the rationalizations it produced are countered in the text |

Efficiency = effect per token: record body size (lines, bytes) next to the
level. A 40-line S2 beats a 300-line S2.

Procedure and prompt shapes: `SKILL.md` → "Measuring strength".

## E. Agents

| # | Criterion | How to check | Fix route |
|---|---|---|---|
| E1 | Description written for the dispatcher | Says what the agent owns, what it never does, trigger keywords | rewrite |
| E2 | `briefing.skills` all resolve | Static check; the hook denies the spawn otherwise | fix names / add skill |
| E3 | Uses `briefing.skills`, not top-level `skills:` | Static check — the bare key is ignored by briefing | move the list |
| E4 | Tools match the role | Audit/report roles have no `Edit`/`Write`; workers do | fix `allowed-tools` |
| E5 | Body restates no skill content | Diff body against briefed skills; overlap → fail | delete from body |
| E6 | Body holds only repo truth | ADR pointers, exact commands and traps, invariants that live nowhere else | move the rest to a skill |
| E7 | Briefing list is lean | Every listed skill is needed for the lane; a worker briefed with nine skills burns context before its first thought | trim |
| E8 | Model matches judgment | `inherit` for the default worker, `sonnet` for checklist lanes, `opus` where architecture judgment is the job | adjust |

## F. Rules

| # | Criterion | How to check | Fix route |
|---|---|---|---|
| F1 | Under ~90 lines | Static check | move to a skill |
| F2 | Only what must be true before the first tool call | Discipline, delegation lock, coordination, permission gates, hazards | move the rest |
| F3 | No duplicated skill content | References skills by name | delete |
| F4 | Hazards name mechanism, trap, alternative | "Never X" alone fails; "X because Y; the naive check passes because Z; do W instead" passes | rewrite |
| F5 | Delegation lock names real agents | Every agent in the table exists in `.claude/agents/` | fix |

## Scorecard format

One block per item, then a ranked fix list across the set.

```markdown
### <path>
Type: skill | agent | rule · Archetype: <…> · Size: <lines> lines / <bytes> B · Description: <chars> chars
Fails: A1 A5 B7 B8 · Passes: <count>/<total>
Strength: S2 (baseline: <one line>; with skill: <one line>; retrieval 1/1 on-target, 0/2 off-target)
Top fix: <one sentence, routed: skill-authoring | skill-compressor | skill-mining | split | delete>
```

Never leave a fail without a route, and never score strength above S0 without
a run you can quote.
