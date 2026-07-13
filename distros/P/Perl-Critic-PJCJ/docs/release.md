# Release process

## Before you start

1. Make sure all feature work is merged to `main`.

2. Add entries to `Changes.md` under the `{{$NEXT}}` heading. **Do not commit
   `Changes.md`** - the release command commits it on the release branch.

3. Ensure tests and lint pass:

   ```bash
   make test
   make lint
   ```

## Releasing

From `main`, with `Changes.md` uncommitted:

```bash
make release
```

The command walks through the full release with confirmation checkpoints (type
"yes" to proceed at each one):

01. Prompts for a version bump if the version in `dist.ini` still matches the
    last release.
02. Creates a GitHub ticket.
03. Creates a `GH-NNN-release` branch from `main`.
04. Commits `Changes.md` and the version bump on the branch.
05. Pushes the branch and opens a PR.
06. Pauses for you to review the PR.
07. Merges the PR.
08. Checks out `main` and pulls.
09. Runs `dzil release` - builds, tests, uploads to CPAN, rewrites `{{$NEXT}}`
    in `Changes.md`, commits, tags, and pushes.
10. Prints post-release verification steps.

## Partial workflow

To create only the ticket, branch, and PR without merging or releasing:

```bash
utils/run release-ticket
```

## Dry run

Preview what each step would do without executing anything:

```bash
utils/run --dryrun release
utils/run --dryrun release-ticket
```

## Post-release checks

- New version appears on [MetaCPAN](https://metacpan.org/dist/Perl-Critic-PJCJ).
- Git tag exists: `git tag -l`.
- `Changes.md` has a concrete version heading where `{{$NEXT}}` was, and a fresh
  `{{$NEXT}}` section above it.
