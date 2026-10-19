---
name: getty-git-usage
description: "Use when committing, pushing, or landing work in a Getty repo — commit/push cadence, rebase vs merge, cleaning history before a PR, stacked branches, cutting a release. Commit wording: getty-git-commit-style."
---

# Git usage

Short version: **keep the history linear.** A branch lands rebased, not merged.

## Landing work

```bash
git fetch origin
git rebase origin/main        # not merge
git push --force-with-lease    # after a rebase, never plain --force
```

For a pull request, `gh pr merge <n> --rebase --delete-branch`. Squash is the wrong
choice where a release is cut from commit prefixes: squashing replaces the individual
`feat:`/`fix:` subjects with the PR title, and a PR title without a prefix produces no
release at all.

Merge commits are not forbidden, they are just not the default. Reach for one when the
branch genuinely represents parallel work whose shape is worth keeping — not to avoid a
rebase.

## Stacked branches

A branch based on another branch is fine and common here, but note what GitHub does when
the lower one lands: it **closes** the dependent PR and refuses to reopen it. Rebase the
next branch onto `main`, force-push, and open a fresh PR. Reference the old number in the
body so the trail survives.

## Commits

**Commit early and commit often.** One finished piece of work per commit, however
small — a typo fix is a commit. Wrapping up what you just finished is expected and
needs no separate go-ahead; pushing is the decision that waits. The history here is
kept linear and never squashed precisely so those small commits survive into `main`,
where they are what makes `git bisect`, a one-commit revert and a cherry-pick possible
at all. Work parked in a working tree until it is "done" throws all three away and
lands as a lump nobody can unpick later.

**A skill file that arrived by hardlink is its own commit.** Anything under
`.claude/skills/` is shared from the repo that owns it, so an edit made anywhere lands
in every working tree linking it — as a change nobody made *here*. Commit it in this
repo too, on its own, never folded into a code commit: it is someone else's edit
passing through, and a shared commit would file it under a message that does not
describe it.

Conventional prefixes (`feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`, `refactor:`),
always `--signoff`. The prefix is not decoration where a release workflow reads it:
`feat:` cuts a minor, `fix:` a patch, `feat!:` or a `BREAKING CHANGE:` body a major.
Everything else cuts nothing.

Message wording, body structure and multi-repo commits: see `getty-git-commit-style`.

## Before pushing

Run whatever the repo uses to check itself — its test script, `bash -n`, `py_compile`.
CI is a safety net, not the first place a failure should surface.

Never rewrite history that is already on `main`.
