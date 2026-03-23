---
name: release
description: >
  Release workflow for Perl-Critic-PJCJ. Use when preparing or performing
  a CPAN release. Both commands live in utils/run and support --dryrun.
user_invocable: true
---

# Release workflow for Perl-Critic-PJCJ

## IMPORTANT — interactive commands

`make release` and `utils/run release-ticket` are **interactive**
scripts with multiple confirmation prompts. **Do not run them
yourself.** Instead, tell the user which command to run and explain
the preconditions. The user must run the command in their own
terminal.

## Commands

- **`make release`** — full release: creates a GitHub ticket,
  branch, PR, merges, then runs `dzil release` (CPAN upload, tag,
  push). Confirmation checkpoints before every external action.
- **`utils/run release-ticket`** — creates only the ticket, branch,
  and PR. Use when you want to prepare without releasing.

Both support `--dryrun` and must be run from `main` with a clean
working tree (excluding `Changes.md`, which should be uncommitted).
`release` also requires entries under `{{$NEXT}}` in `Changes.md`.

## What you should do

1. Verify the preconditions (correct branch, clean tree, changelog
   entries, tests and lint passing).
2. Tell the user which command to run (e.g. `make release`).
3. Do **not** execute the command on their behalf.

See `docs/release.md` for the full developer guide.
