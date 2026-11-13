---
name: review-publish
description: Post the human's own review-helper feedback to the pull or merge request it reviews, word for word, through the human's own account, after they confirm the exact list. Use when the user asks to publish, post, or send their review-helper feedback to the PR/MR.
allowed-tools: Bash(review-helper *)
---

# Publishing feedback to a pull request

The human wrote feedback in review-helper. You carry it to the pull or merge
request, unchanged, as their comments. You are a transport, not an author.

## The rules

- **Verbatim.** Post each item's `text` exactly as `review-helper feedback
  FILE --publish` prints it: the human's `body`, after a fixed location
  prefix when it is a general comment. Never edit, correct, summarize,
  translate, reformat, or add to it.
- **The human's words only.** Post only feedback items. Never post flags,
  summaries, `response` text, debate cases, requests, or anything you wrote.
- **Unposted, open items by default**, as `--publish` lists them. Include
  others only when the user names them: then pass the id of every item to
  post, the default ones included.
- **Confirm first.** Show the exact list and post nothing until the user
  explicitly says yes to it. If they drop or change items, show the new list
  and ask again.
- **The human's account.** Post through the user's own forge tools and
  login, each post approved as it comes; never ask the user to pre-allow
  forge writes. Never ask for a token or password in chat, and never print
  one.
- **Mark each post.** After each successful post, run
  `review-helper published FILE ID` before the next one.
- **Stop on the first failure.** Report the error and what was posted. Do not
  retry, reword, or mark the failed item. A refused line comment is not a
  failure: post its `fallback` as a general comment instead.

This fits the project's AI/LLM policy, which keeps agents out of pull request
discussion: the human wrote every word and approved each post, and it goes
out under their name. You only move their text.

## Gather

```
review-helper feedback FILE --publish [ID...]
```

`FILE` is the review file; `review-helper list` shows this repository's
reviews. With no `ID`, it lists the open items not yet posted; with ids,
those items. `review-helper feedback FILE` shows every item, with its
`reviewer` (who wrote it, or null when the file did not record it).

Each item has its `id`, the `text` to post, and `anchor`. An `anchor` of
`{ path, line, side }` makes it a line comment there, on the request's diff
as of the review's `head`, with `fallback` the general comment to post if
the forge refuses it. A null `anchor` makes it a general comment. The prefix
in a general comment names where the human gave the item: its file and line,
section, commit, topic, or flag, and nothing for the whole change.

You need the request's URL: the one the review was built from (`--source`),
or ask the user. Use the tools you have for this repository's forge: its
command-line tool, an MCP server, or similar. If you have none, say so and
stop.

## Confirm

Show the user, numbered, for every item: its id, the request, where it goes
(line comment at the anchor's `path:line` and side, or general comment), and
its exact `text` (for a line comment, also its `fallback`), in a fence longer
than any inside it. Ask whether to post these. Wait for an explicit yes.

## Post

One post per item, with your forge tool: a line comment at its `anchor`, or
a general comment, giving the tool the item's decoded `text` exactly. Where
the tool takes the commit to comment on, give it the `head`. Where the tool
can read the text from a file or standard input, take it from the
`--publish` output rather than retyping it. If the forge refuses a line
comment, post the item's `fallback` as a general comment instead. After each
successful post:

```
review-helper published FILE ID
```

## Finish

Tell the user what was posted, with links where the forge returned them, and
anything not posted and why.
