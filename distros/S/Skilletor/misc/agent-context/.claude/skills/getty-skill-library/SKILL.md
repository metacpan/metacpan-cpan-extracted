---
name: getty-skill-library
description: "Use when adding, naming, moving or renaming a skill in Getty's projects, installing one into a repo with skilletor, or before editing an installed SKILL.md."
---

# Getty's Skill Library

How skills are owned, named, shared, and edited across Getty's
projects. The shared library is [Getty/skills](https://github.com/Getty/skills);
the transport is [skilletor](https://github.com/Getty/skilletor) — one source
file per skill, installed copies everywhere else.

## Where a skill lives

**A skill lives in the repo that owns its subject.** A Perl module keeps its
module skill, a cluster repo keeps its cluster skill. The shared library holds
only what has no single home:

- Knowledge a *second, unrelated* project needs → promote it to the
  library as `<group>/<name>/` and install it back as `<name>@getty`. Write it
  where it is used first; promotion is triggered by the second consumer, never
  by anticipation.
- A skill only *related* repos share stays with its owner: the owner repo is a
  skilletor source of its own, and the siblings install `<name>@<owner>`.
- Skills that run only user-level (never installed into a project, e.g.
  `getty-agent-team`) also live in the library — it is their home repo.
- The moment a shared skill turns out to belong to one project, it moves
  there and the library drops it.

Groups are one directory level under the repo root, each with a `README.md`
listing its skills; the root `README.md` lists the groups (the directory
listing is the authority — this skill deliberately doesn't enumerate them).
Create a new group only when no existing one fits — a domain name, never a
`misc` drawer. "Didn't know where to put it" means a new group is due, not
that the nearest group absorbs it.

## Naming

Pattern: `{lang}-{name}` (`perl-mcp`) or `{tool}` (`rex`), kebab-case.
Prepend `getty-` when the skill **prescribes** — a house choice among valid
options (`getty-git-usage`: rebase, not merge) or the API of Getty's own
software. Drop the prefix when it is **reference** — equally true for anyone
using the tool (`kubernetes-concepts`, `perl-mcp`). The test: does it tell you
what Getty chose, or just what the tool does?

Skill names are flat and global across all sources — check for collisions
before naming (`skilletor available`). Renaming a skill means chasing every
`install.skills` entry in a `skilletor.json`, every `briefing.skills` entry and
every `CLAUDE.md` reference in every consuming repo; name it right the first
time.

## Editing a shared skill — edit the source

An installed skill is a build artifact. skilletor owns every skill directory
that carries its `.gitignore` (`# installed by skilletor`), and the next sync
overwrites whatever was edited there. **Edit the skill in its source, then sync
the consumer:**

```bash
$EDITOR ~/dev/skills/<group>/<skill>/SKILL.md   # the source: plain file, any tool
skilletor sync                                   # in a consuming repo
skilletor sync --scope user                      # for ~/.claude/skills
```

On Getty's machines `~/.claude/skilletor.json` maps each source name to its
checkout (`"getty": { "local": "~/dev/skills" }`), which overrides the
same-named `git` source in a project's committed config. While the checkout
exists every sync reads it directly — a local change needs no push to arrive.
Everyone else gets it once it is pushed.

A skill directory without skilletor's `.gitignore` is the repo's own: tracked,
edited in place. `skilletor status` lists what is managed.

## Wiring a project

```bash
skilletor add Getty --project                     # source `getty` = github.com/Getty/skills
skilletor install getty-git-usage@getty perl-mcp@getty --project
skilletor status                                  # declared vs. installed
```

- Commit `.claude/skilletor.json` and `.claude/.gitignore`. Installed skills
  stay out of git; the repo's own skills stay tracked.
- A root `.gitignore` that ignores `.claude/*` behind an allowlist needs
  `!.claude/skilletor.json` and `!.claude/.gitignore`, or the config is
  silently never committed.
- Take each skill from the repo that owns it: library skills `@getty`, karr's
  `@karr`, a sibling's `@<owner>`. A repo that merely holds an installed copy
  does not offer it.

## Old pattern — manage-skills hardlinks

Shared skills used to be hardlinked with manage-skills. A leftover link shows
as a link count above 1 (`stat -c %h SKILL.md`). skilletor leaves a file alone
while its content matches the source, so such a link survives a migration:
delete the managed skill directory and `skilletor sync` to get a plain copy.
Until then the file *is* the source — an in-place edit there changes it for
every repo still linked.

## Distribution duties (library repo)

Three routes ship the same files: skilletor source, Claude Code plugin,
Codex plugin. When skills or groups are added, renamed, or moved:

1. Update the group `README.md` and the root `README.md` skill lists — they
   are hand-maintained and drift silently.
2. Add the skill to the `skills` array in `.claude-plugin/plugin.json` **and**
   `.codex-plugin/plugin.json`, by hand. A grouped layout lists every skill
   path individually, and skilletor finds the library's skills through that
   array — a skill missing there cannot be installed. Validate with
   `claude plugin validate .` (the root-CLAUDE.md warning is expected; don't
   use `--strict`).
3. The marketplace entry lives in `Getty/marketplace`, not here.

`bin/check-listings` in the library repo verifies all of this at once — group
README entry, group-table count, the skill table, both manifests, and that the
frontmatter `name` matches the directory. Run it after adding or renaming a
skill; it exits non-zero with one line per omission.

## Related

- `skill-authoring` — how to write the skill's content.
- `skill-compressor` — shrinking or merging existing skills.
- `skilletor` (plugin skill) — the CLI in full: sources, bundles, vars, trust.
