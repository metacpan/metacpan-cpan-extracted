---
name: review-notes
description: Record points of interest for the human reviewer while writing code — wrong assumptions, deviations from a plan or spec, misunderstandings exposed by tests, corrections made in self-review, and anything else the reviewer should notice. Read this BEFORE writing any code for a change that will be reviewed with review-helper, and keep doing it for the whole task.
allowed-tools: Bash(review-helper note *)
---

# Recording review notes

A human will review this work with `review-helper`. A note that needs their
judgment becomes a **flag** beside the lines it concerns; every other note
is a **journal entry**, listed at the end of the review for their
information. The context behind a note only exists while you work: record
each one **when it happens**, not at the end.

## What to record

Record a note whenever:

- **An assumption proved wrong** — about the code, an API, the data, the
  user's intent. Include what you believed and what was true.
- **You deviated** from the plan, spec, architecture, or the user's words —
  and why.
- **A test exposed a misunderstanding** — not every red test, only ones that
  changed how you understood the problem.
- **Self-review or code review corrected something** that a reviewer of the
  final code would not otherwise know was once wrong.
- **A point deserves attention** — a subtle invariant, a non-obvious
  tradeoff, a place you are unsure about, a workaround for something
  external.

Record only what a reviewer would need. Do not record routine progress, typo
fixes, or things the code and its comments already make obvious.

## Flag or journal entry

- **Yellow flag** (`--flag yellow`) — a reviewer may object: a decision you
  made, a deviation, or a problem you solved in a way you are not sure will
  be accepted.
- **Red flag** (`--flag red`) — probably a problem, still unsolved. Nothing
  you solved is red.
- **Journal entry** (no `--flag`) — everything else: worth knowing, but no
  one is likely to object.

One flag per decision. A finding from a review-and-fix round is a journal
entry, unless the fix changes behavior a reviewer should check.

## Kind

A label for where the note came from; `other` when none fits, and the
default: `deviation` (from the plan, spec, architecture or the user's
words), `assumption` (one that proved wrong), `self-review` (a correction
found re-reading your work), `test-revealed` (a misunderstanding a test
exposed), `note` (a point worth the reviewer's attention).

## How

```
review-helper note [--flag yellow|red] [--kind <kind>] --path <file> \
    [--unit <sub/method/function name>] [--snippet <short code excerpt>] \
    --sentence <one sentence> [--detail <text>]
```

- `--path` is relative to the repository root. Use the file the note is
  about, even if it is not written yet.
- `--unit` names the sub, method or function. For a flag, give `--unit` or
  `--snippet` (a short distinctive line or fragment) when it concerns
  specific code: they help place it on exact lines once the review is built.
- `--sentence` is what the reviewer sees first: one plain sentence, on one
  line.
- `--detail` is the full story — what you expected, what happened, what you
  did, and what the reviewer should check.

The command needs no review file and works in any worktree. It prints the
note's id. The journal is per worktree and shared by everything done there, so
keep to one reviewed change per worktree at a time. A build or iteration takes
every journal entry in the worktree's journal; flags are placed only for the
notes their agent recognizes.

Example:

```
review-helper note --flag red --kind deviation --path lib/Foo/Cache.pm \
    --unit expire --snippet 'return unless $self->{+TTL};' \
    --sentence 'Expiry is skipped when TTL is zero, contrary to the spec.' \
    --detail 'The spec says TTL 0 expires immediately. Three callers in lib/Foo/Session.pm pass 0 to mean "never expire", so this keeps their behavior; changing them is out of scope. The owner should decide whether the spec or the callers change.'
```

## Writing style

Short sentences, plain words. The reviewer reads dozens of these; make the
first sentence carry the point.
