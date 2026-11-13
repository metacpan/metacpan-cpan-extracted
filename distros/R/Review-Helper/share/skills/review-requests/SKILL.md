---
name: review-requests
description: Handle open review-helper requests - run a two-sided debate on a commit, file, or section the human questioned, and split a file into sections again. Use when the user says a review has requests, or when review-helper feedback output lists open requests.
allowed-tools: Bash(review-helper *) Bash(git show *) Bash(git log *) Bash(git diff *) Bash(git grep *) Bash(git rev-parse *) Bash(git status *)
---

# Handling review requests

The human flagged parts of a review for deeper work: a **debate** on whether
something is right, or a new **split** of a file into sections. You do the
work and record the results through the fill sheet.

## Find them

```
review-helper feedback FILE --open
review-helper sheet FILE
```

The feedback JSON's `requests` list gives each request's kind, target
(review, commit, file, or section), and the human's `note`. In the sheet they
are `debate` items (`request:<id>`) and `split` items (`split:<file id>`).
Fill them with the sheet loop from the review-build skill.

## Debate

For each debate, dispatch two sub-agents with fresh context, in parallel:

- **For** — makes the strongest case for the target as written.
- **Against** — makes the strongest case against it, or for a concrete
  alternative.

Give each one:

- the target: commit sha, and path and section name when present; for a
  `topic` (a topic of a squashed review), its name and its paths, which
  `review-helper sheet --all FILE` lists in its `topics` item: the debate is
  about those files, not the whole squashed change;
- the human's note, verbatim;
- to read the code at that commit with git, read-only, and the two tips in
  the review-build skill's "Splitting a file" for exact line numbers;
- the task: a concise, evidence-based case citing files and lines, at most
  about 200 words, changing nothing.

Record the results as `case_for` and `case_against`. Keep each concise and
faithful to its sub-agent; do not add your own verdict.

A finished debate leaves the sheet. Only when the user asks you to rewrite
a case, or to correct one you got wrong, run `review-helper sheet --all FILE`:
it also lists finished debates with their current cases. Send back only the
items you change, `rev` as printed, as the review-build skill describes.

## Split

The split item's `about.request.note` says what the human wants, and
`about.sections` lists the file's current split. Split the file again as
the review-build skill's "Splitting a file" describes, with the note in
mind: give the whole list in `sections`, keeping the names and lines of
units that stay as they are, with their first lines. Do not send `about.sections` back as it is: it has no
first lines, so `fill` would reject it.

The re-split file's sections come back as section items in the next sheet,
to explain afresh: no explanation carries from the earlier split. Section
feedback and debate requests follow their section by name; those on a
section that no longer exists, or that the commit no longer changes, move
to the file, noting the section they were on. A guide whose step names such
a section comes back in the sheet to be written again.

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

## Finish

Tell the user which requests are done, and give the review's URL (see
"Serve the review").
