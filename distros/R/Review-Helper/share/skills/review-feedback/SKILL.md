---
name: review-feedback
description: Act on a human's review-helper feedback - change the code as new commits, add a new iteration to the review, and fill in responses and fresh explanations. Use when the user says the review has feedback, hands over a review-helper feedback export, or asks to address review comments made in review-helper.
allowed-tools: Bash(review-helper *) Bash(git show *) Bash(git log *) Bash(git diff *) Bash(git grep *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git status *)
---

# Acting on review feedback

The human left feedback in review-helper. You act on it, add the changes to
the review as a new iteration, and answer each item so the human can see what
happened without reading every diff again.

## Read the feedback

```
review-helper feedback FILE --open
```

`FILE` is the review file; `review-helper list` shows this repository's
reviews if you do not have it. The JSON has a `feedback` list and a
`requests` list. Each feedback item anchors to a commit, and possibly a path,
section, and `line` on the `old` or `new` side of that commit. Each item's
`reviewer` names who wrote it, or is null when the file did not record it.
A `topic` on a `commit` item names a topic of a squashed review: the item is
about that topic's files only, not the whole squashed change;
`review-helper sheet --all FILE` lists each topic's paths in its `topics`
item. A `review` item may keep the `commit` and `topic` it was given on, as
context, after the agent's topics fill removed that topic (a `topic` of `""`:
it was on the files not in a topic yet). Read the code it points at, at its
commit; the review-build skill's "Splitting a file" has two tips for exact
line numbers.

If `requests` is not empty, handle them first with the review-requests skill:
they refer to the current iteration.

## Act on it

- Before changing code, read the review-notes skill and record notes as you
  work, exactly as for the original change. What a fix round finds and
  fixes is a journal entry, unless the fix changes behavior the reviewer
  should check.
- Make code changes as new commits, following this repository's own commit
  rules. Do not rewrite the reviewed commits unless those rules or the user
  say to.
- Do what each item asks. Decline only with a concrete reason, such as a
  conflict with the project's documented design. Ask the user when an item is
  unclear rather than guessing.

## New iteration

```
review-helper iterate FILE [--base <rev>] [--head <rev>]
```

The base defaults to the previous iteration's, the head to `HEAD`. Pass
`--base` if the branch was rebased onto a new base. It prints the new
iteration number. Explanations, reading order, and flags carry forward for
unchanged commits, and so does the split of a file whose change is the same.
A carried flag whose code changed is pending: the sheet asks you to keep,
recolor or retire it. So is every flag of a commit you amended, rebased with
changes or dropped, or of an empty commit you rebased (`about.rewritten`):
it now sits on the last commit that changes its file, or on the last commit
when none does. Your new journal entries go into the new iteration.
In a squashed review (same base), flags and the explanations of unchanged
files carry, files keep their topic, and a topic's what/why/how carry only
when all its files are unchanged; the summary and other topics are left for
you to rewrite. New files wait for a topic: fill the `topics` item first,
alone, as the review-project skill says. Every other changed file needs a new
split, and its sections new explanations; the split item shows the previous
split as context.

## Fill

Run the sheet loop from the review-build skill (`sheet`, fill, `fill`, until
nothing required remains), writing every item as that skill describes. This
time the sheet also has:

- **summary** `note` — what this iteration changed, in a sentence or two.
- **feedback** — one per open item: `status` `addressed` or `declined`, and
  `response`: what you did and in which commit, or why you declined. One or
  two sentences. Feedback on a flag (`about.target` `flag`; `about.flag`
  gives its note id and sentence) is the reviewer commenting on that flag:
  answer it the same way.
- **flag** — one per pending flag, as the review-build skill describes. A
  red flag whose problem a fix solved is retired, or turns yellow when the
  reviewer may still object to the fix, the reason naming the commit; a flag
  the change made moot is retired. To recolor or retire a flag that is not
  pending, after a reviewer's comment on it, take
  `review-helper sheet --all FILE`.
- New or changed commits, files, splits and sections, and your new flag notes.
- **guide** — a new guide for this iteration, focused on what changed: walk
  the human through each fix, highlighting the changed lines. Skip what the
  previous iteration's guide already showed.

## Serve the review

If you already started a server for this review in this session and it is
still running, give its URL again. Otherwise start one yourself: run
`review-helper serve FILE` as a background process, so it keeps running,
and give the user the URL it prints on its first line. If the user wants to
review with others on their network, start it (stopping your earlier one)
with `review-helper serve FILE --listen 0.0.0.0` and give them the URL with
the token, the first one it prints; anyone holding it can read the review
and leave feedback. Stop the server when the review is closed, or when the
user asks.

A server already running for the review shows the new iteration on reload.

## Finish

Tell the user the new iteration is ready, summarize what was addressed and
declined, and give the review's URL (see "Serve the review").
