---
name: getty-git-commit-style
description: Use when committing in a Getty repository — writing or amending a commit message or a Changes/CHANGELOG entry, stamping a release's version line, or committing across several repos.
---

# Commit Message Style

## Format

```
<summary line — imperative or "<component>: <what>", no type prefix, max ~72 chars>

<body — one line per change, no filler>

Co-Authored-By: Claude <Model> <noreply@anthropic.com>
```

## Rules

- **Summary line**: describe the primary intent, in one of two forms:
  - imperative mood ("Add", "Fix", "Rename", "Remove"):
    `Rename _dbic_connect_attributes to _dbio_connect_attributes`
  - `<component>: <what>`, the component saying *where* the change lies — a file, a
    directory, a command, an area:
    `README.md: rework for first-time readers, with current limits stated`
- **No type prefix**: what stands before the colon names a place, never the kind of change —
  no Conventional Commits type (`feat:`, `fix:`, `docs:`, `chore(scope):`). A place whose
  name is also a type word (docs, test, tests, ci, build, chore) is written as its path:
  `docs/plan.md:`, `t/hooks.t:`, `.github/workflows/ci.yml:`, never bare `docs:`
- **No `--signoff`**: commit without `-s`; the message carries no `Signed-off-by:` line, only the co-author trailer below
- **Body**: list every discrete change on its own line, no bullets needed, no prose explanations
- **Completeness**: every file-level change must be mentioned — don't silently lump things together
- **Brevity**: state what changed, not why it's important or how it works — the diff shows that
- **No filler**: no "This commit...", no "In this change...", no "Also..."
- **No @ symbols**: never use `@` in commit messages (e.g. write `[DBIO]` not `[@DBIO]`) — platforms like GitHub interpret `@word` as user/org mentions
- **Language**: English
- **Co-Author**: append the Co-Authored-By line whenever Claude wrote or co-wrote the changes.
  Name the model that actually did the work — read it from the session rather than
  copying a version out of an older commit or out of this file. If the harness
  prescribes its own trailers (a session link, a different spelling), use those verbatim.

## Examples

Good:
```
Rename _dbic_connect_attributes to _dbio_connect_attributes

Storage/DBI.pm: accessor declaration and two call sites
Schema/Versioned.pm: one call site
```

Good:
```
Migrate to [DBIO] bundle, fix _Util rename, add POD

Switch dist.ini from [Author::GETTY] to [DBIO].
Fix DBIO::_Util -> DBIO::Util in Storage::ASE.
Fix _dbic_cinnect_attributes typo in Storage::FreeTDS.
Add inline POD to all four modules.
Clean up cpanfile, remove deps already in DBIO core.
Add CLAUDE.md and README.md.
```

Bad (too vague):
```
Update driver code and documentation
```

Bad (too verbose):
```
This commit updates the Sybase driver distribution to use the new
[DBIO] Dist::Zilla plugin bundle instead of the previous [Author::GETTY]
bundle. Additionally, it fixes an issue where...
```

## Changelog entries

Every repo that cuts releases keeps one file named `Changes`, in the CPAN format,
whatever it is written in — a Perl dist, a Node CLI, a Claude Code or Codex plugin:

```
Revision history for <name>

{{$NEXT}}
  - Entry for what is on main and not released yet, wrapped at 78 columns,
    continuation lines under the text.

0.006     2026-08-30 14:35:09Z
  - Entry.
```

- **`{{$NEXT}}`, alone on its line, is the unreleased section.** Entries go directly
  under it: two spaces, `- `, plain text. The file has no other structure — no `#`
  headings, no `Added`/`Fixed` groups, newest release first.
- **A release turns that line into the version line** — the version padded to nine
  columns, a space, the UTC time (`printf '%-9s %s' "$version" "$(date -u '+%F %TZ')"`)
  — and puts a fresh `{{$NEXT}}` and a blank line above it. Dist::Zilla does this
  during `dzil release`; there a version line is never written by hand. Everywhere
  else it is part of the commit that bumps the version in the manifests, or of the
  release workflow that does.
- **An entry is not a release.** It lands under `{{$NEXT}}` and leaves every version
  number alone.
- **A `CHANGELOG.md` or a README section that plays this part is converted**, not
  kept beside it: same text, this format, the old file removed and its references
  repointed. A repo without any gets `Changes` with its released versions as far as
  tags and history name them. A version line written this way takes its time from
  git — the tagged commit, without a tag the commit that set the version
  (`TZ=UTC git log -1 --date=format-local:'%F %TZ' --format=%cd <commit>`) — not
  from a guess.

The entry belongs in the same commit as the change it describes, and the rules above
apply to it unchanged. One thing makes it harder than a commit message: a message is
written once and never seen again, while the unreleased section stays open for weeks
and is edited again every time the same area is touched.

**One topic, one entry.** Before writing a bullet, read the unreleased section for the
topic you are about to describe. If it already has one, **rewrite that bullet** to say
where the code now stands — never append a second. Three bullets circling one option
are three chances to contradict each other, and the reader wants the released state,
not the sequence of attempts that produced it.

**Describe the destination, not the journey.** No "used to", no "previously", no
walkthrough of the mechanism, no defence of the alternative that lost. Name what is
true now and what a user does differently because of it. The reasoning has homes that
keep it — the commit body, the ticket, an ADR; a changelog is read by someone who
never saw the old behaviour.

**Reference only the tracker the repo publishes.** In a changelog a `#123` earns its
place when the reader can open it — GitHub or Gitea issues on a repo that has them. An
internal board ticket is unreadable outside the workspace, so it does not appear there
at all: name the change instead of the number. A commit message may carry one, written
in the board's own notation (karr ids are `k254`) — never as `#254`, which every
hosting platform resolves against *its* issue 254: a dead link today, someone else's
bug once the repo has that many.

Aim for one to three lines per entry, and let the count of entries fall out of the
work rather than the detail per entry. For scale: a mature Getty distribution carries
320 releases in a 348-line `Changes` — a whole history shorter than a single unreleased
section that was allowed to accrete.

## Multi-repo commits

When committing across multiple repos in a workspace, each repo gets its own
commit with its own message, and that message describes this repo's change.

- **A card on another repo's board** is named in that board's notation:
  `agent-developer k3`, never `#3`.
- **Beyond that, a product repo's message names no other repo.**
- **A hub repo names its family's commits** (`agent-bun-runtime 5ef1201`,
  `Getty/skills 9c5ed41`): recording the state across repos is its job (skill
  `getty-developer-hub`).

## HEREDOC usage

Always pass commit messages via HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Summary line

Body lines here.

Co-Authored-By: Claude <Model> <noreply@anthropic.com>
EOF
)"
```
