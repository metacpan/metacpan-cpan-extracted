---
name: getty-git-usage
description: "Use when landing or pushing work in a Getty repo — rebase vs merge, a force-push after a rebase, stacked branches, cleaning up history before a PR. Commit messages and `Changes`: getty-git-commit-style."
---

# Git usage

Short version: **keep the history linear.** A branch lands rebased, not merged.

## Landing work

```bash
git fetch origin
git rebase origin/main        # not merge
git push --force-with-lease    # after a rebase, never plain --force
```

For a pull request, `gh pr merge <n> --rebase --delete-branch`, not `--squash`.
Squashing folds the branch's small commits into one, and with them goes what they are
for: `git bisect` down to the commit that broke something, reverting one commit,
cherry-picking one.

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
small — a typo fix is a commit. Who commits is the house rule `agent-delegation`'s: the
release-manager in an agent team, otherwise the main session. A local commit of
finished work needs no separate go-ahead; the push is the decision that waits. Work
parked in a working tree until it is "done" lands as one lump that nobody can bisect,
revert or cherry-pick in parts.

**Installed skills are not committed.** skilletor keeps the shared skills under
`.claude/skills/` out of git; a repo commits `.claude/skilletor.json`,
`.claude/.gitignore` and the skills it owns. A shared skill git still tracks surfaces
as a change after every edit to its source — untrack it
(`git rm -r --cached .claude/skills/<name>`) instead of committing it.

Message wording and `Changes` entries: skill `getty-git-commit-style`.

## Before pushing

Run whatever the repo uses to check itself — its test script, `bash -n`, `py_compile`.
CI is a safety net, not the first place a failure should surface.

Never rewrite history that is already on `main`.
