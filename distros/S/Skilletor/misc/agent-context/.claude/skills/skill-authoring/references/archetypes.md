# Skill archetypes

Four shapes a skill takes. Pick one before writing — mixing them is how skills
bloat. Each entry: when it applies, the skeleton, the quality bar, and a live
example from Getty's library.

## Contents

- Reference — documents how a tool, API, or protocol behaves
- Convention — prescribes a house choice among valid options
- Workflow — walks a multi-step procedure to a checkable end state
- Concept — teaches a mental model or architecture

## Reference

**When:** the agent needs facts about how something behaves — an API surface,
a protocol, a tool's semantics. True for anyone using the thing, not just for
this house. Examples: `perl-mcp`, `kubernetes-concepts`.

**Skeleton:**

```markdown
# <Thing>

One paragraph: what it is, where it runs, the one fact that prevents the
most common misuse.

## <Operation/area 1>
Signature or call shape, one runnable example, the gotcha.

## <Operation/area 2>
…

## Errors / edge cases
Symptom → cause → fix, as a table.
```

**Quality bar:** every fact checkable against the real tool; examples runnable
as pasted; no advice, no style opinions (those are a convention skill). Over
~150 lines, split by domain into `references/<area>.md` so a task loads only
its area. Long reference files start with a table of contents.

## Convention

**When:** several approaches are valid and the house picked one — style,
naming, message formats, tool choice. The skill exists so the choice is applied
silently, not re-litigated. Examples: `getty-git-commit-style`,
`getty-perl-core`.

**Skeleton:**

```markdown
# <Convention>

## Rules
The choices, each on one line, imperative. No justification longer than a
clause — the agent needs the rule, not the debate.

## Examples
One good, one bad, both real. The bad one labeled with *why* it is bad.

## Edge cases
The situations where the rule bends, each as "if X → Y".
```

**Quality bar:** an agent that has read it produces conforming output without
mentioning the convention. Rules stated positively (what to write, not what to
avoid). If a rule is mechanically checkable, say what checks it (linter, CI)
instead of restating the linter's config.

## Workflow

**When:** a multi-step procedure where order matters, steps can be skipped
under pressure, or half-done work looks done. Examples: `getty-create-software`,
`getty-perl-distribution`.

**Skeleton:**

```markdown
# <Workflow>

One paragraph: the end state this produces.

## Step 0 — preconditions
What must exist/resolve before starting, with the commands that check it.

## Step 1 — <action>
The action, the exact commands, and the completion criterion — how the
agent knows this step is done.

## Step N — verify
A concrete check on the end state. Output to expect, not "make sure it
works".
```

**Quality bar:** every step ends on a checkable criterion ("every placeholder
substituted", "all names resolve"); fragile operations get exact commands (low
freedom), open decisions get heuristics (high freedom) — match strictness to
how badly a wrong guess hurts. Branch-specific detail moves to
`references/<branch>.md` so the main path stays a single visible spine.
Validation loops beat trust: run the check, fix, re-run, only then proceed.

## Concept

**When:** the agent needs a mental model to make many small decisions
correctly — an architecture, a vocabulary, a set of invariants. No steps to
follow; the payoff is that other skills and prompts can use the vocabulary.
Example: a project's `<prefix>-core` skill.

**Skeleton:**

```markdown
# <Model>

The model in at most four sentences — this is the part other documents
will lean on.

## <Component / layer>
What it is, what it owns, what it never does.

## Invariants
The rules that hold everywhere, each independently checkable.

## Boundaries
What is explicitly out of scope / someone else's job.
```

**Quality bar:** the named terms are the ones the code actually uses; every
"never does" is real (an invented invariant is worse than none); short enough
to be briefed into a subagent whole. If it needs steps, it has a workflow
hiding inside — split it out.
