---
name: review-add-notes
description: Give a second opinion on an existing review-helper review that another agent built - read the change, record your own notes on suspected problems and deviations, and place them as flags without touching anything else in the review. Use when the user asks for another agent's notes, a second look, or extra flags on a review.
allowed-tools: Bash(review-helper *) Bash(git show *) Bash(git log *) Bash(git diff *) Bash(git grep *) Bash(git rev-parse *)
---

# Adding notes to a review

Another agent built this review. You read the change with fresh eyes and add
flags where the human should look. You add notes and nothing else: the
summaries, guide, splits, feedback, and responses stay as they are.

## Read the change

`FILE` is the review file; `review-helper list` shows this repository's
reviews if you do not have it.

```
review-helper feedback FILE
```

shows what the human already said; do not repeat it as notes. Its `base` and
`head` keys give the latest iteration's range; read the commits `base..head`.
A squashed review's entries all have the head's sha: place its notes on the
head sha, and the path picks the topic; a note with `path: null` also needs
its `topic`. Read the code at its commits with git; the review-build skill's
"Splitting a file" has two tips for exact line numbers. Read the linked
issue or spec when the user names one.

## Record notes

Record each finding as you make it, with `review-helper note` as the
review-notes skill shows. Keep each printed note id: you place only those.
Record flags only: a journal entry reaches a review only when it is built or
iterated, which is not yours to do here.

- A suspected problem — a bug, missing test, risky edge case, security or
  compatibility issue: `--flag red --kind note`.
- A departure from the spec, issue, or plan the change implements, or from
  what its summary claims, that its author may defend: `--flag yellow --kind
  deviation`.

Give `--unit` or `--snippet` so you can place each note on exact lines. Say
in `--detail` what you checked and what the human should confirm. Do not flag
what the existing flags already say.

## Place them

```
review-helper sheet FILE
```

Fill **only** the `note` items whose id is `note:<id>` for an id you
recorded: set `commit` (sha), `path`, and `lines` (`[start, end]`) to the
exact lines, choosing the commit that wrote that code. Use `lines: null` for
the whole file and `path: null` for the whole commit. Leave every other item
null, including other notes in the journal, which belong to someone else
(the journal is per worktree; keep to one review per worktree at a time).
Write the sheet to a temporary file outside the working tree and run:

```
review-helper fill FILE <that file>
```

If it rejects an item, fix that item and fill again. It reports the other
agent's remaining items too; they are not yours to fill.

## Finish

Tell the user how many red and yellow flags you added, and to reload the
review page to see them.
