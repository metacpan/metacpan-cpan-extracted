---
name: skilletor
description: "skilletor CLI — installs and updates skills, agents and rules from remote sources for Claude Code, Codex and Hermes Agent. Use when adding a source, installing/uninstalling a skill/agent/rule, all of a type or a name pattern (`*@source`, `perl-*@source`) from a source, writing or installing a bundle (`bundles/<name>.yaml`, `bundle:name@source`, `install.bundles`), switching an item on/off per project via vars, editing a skilletor.json or its `targets`, running sync/check/status, asking 'where does this skill come from' or 'why did this file change', or before editing a file skilletor manages (including skilletor-rules.md and the skilletor pointer block in AGENTS.md)."
---

# skilletor — remote skills, agents and rules for Claude Code, Codex and Hermes Agent

## Running the CLI

- **Claude Code:** `skilletor` is on the Bash tool's `PATH`.
- **Codex:** the plugin's `bin/` is **not** on `PATH` — a bare `skilletor` fails. Run
  `<plugin root>/bin/skilletor`; the plugin root is two directories above this SKILL.md,
  whose path Codex listed with the skill (`…/skilletor/<version>/skills/skilletor/SKILL.md`
  → `…/skilletor/<version>/bin/skilletor`). Take `<version>` from that listed path, never
  from memory — it changes on every plugin update. Codex runs skilletor's hooks only once
  trusted in `/hooks` (again after an update changes them); until then `sync` by hand.
- **Hermes Agent:** `hermes skilletor <command>` runs the CLI the plugin uses. Setting
  skilletor up for Hermes (targets, plugin, CLI): [references/hermes.md](references/hermes.md).

## Do not hand-edit a managed file — change it in the source

Files skilletor owns are **build artifacts**: every `sync` re-renders them from the source
and overwrites local edits (the report names each). Edit the item **in its source** and
re-`sync`. Author mode: `"shared": { "local": "~/dev/skills" }` in your **user** config
overrides the same-named `git` source, read directly on every sync while that checkout exists.

| Type (under `~` or the project root) | Claude Code | Codex (`$CODEX_HOME` defaults to `~/.codex`) |
|---|---|---|
| skill | `.claude/skills/<name>/` | `.agents/skills/<name>/` |
| agent | `.claude/agents/.local.<name>.md` | `.codex/agents/.local.<name>.toml` (user: `$CODEX_HOME/agents/`) |
| rule | `.claude/rules/.local.<name>.md` | a section of `.codex/skilletor-rules.md` (user: `$CODEX_HOME/skilletor-rules.md`) |

Hermes Agent gets **skills only**: `<Hermes home>/skills/<name>/` (user), `.hermes/skills/<name>/`
(project; none while `codex` is a target there) — [references/hermes.md](references/hermes.md).

A file is managed when its path is in `<scope>/.claude/skilletor.lock.json` (Codex keys
`codex:skills/<name>` etc., Hermes `hermes:skills/<name>`) — check the lock before editing;
files not in it are yours. In `AGENTS.md` only the block between `<!-- skilletor:begin -->`
and `<!-- skilletor:end -->` is managed; in a `.gitignore` and the project's `.worktreeinclude`
only the one between `# >>> skilletor >>>` and `# <<< skilletor <<<`. A conflict blocks the
whole item, and `sync --force` can **delete** the user's own files: read
[references/sync.md](references/sync.md) before forcing, and when a report shows a conflict,
a partial item, an overlap or `git rm --cached` warning, or a due `check`.

## Commands

```bash
skilletor add [name] <spec> [--project]   # add a source (resolves shorthand, trusts it), then sync
skilletor source list [--json] | source remove <name> [--project] [--force]   # --force: even with installed items
skilletor available [source] [--json]     # catalog of trusted sources: type, name, description, installed?
skilletor install <item>... [--project]   # name@source (type:name@source if ambiguous), bundle:name@source
skilletor install 'rule:*@shared' 'skill:perl-*@shared'   # wildcard/pattern: type prefix required, quote it
skilletor uninstall <item>... [--project] # [type:]name@source (no type: every list); wildcards, bundle: as written
skilletor sync | check | status           # --scope user|project|all, --json, --project-dir <dir>
skilletor sync --force                    # overwrite and adopt unmanaged files reported as conflicts
skilletor trust <source>                  # confirm a project-declared source (shows the backend it trusts)
```

`add`, `install`, `uninstall`, `source remove` edit one `skilletor.json`, then sync; a config
error there → exit 2, the edit stays saved. `uninstall` or `source remove` of an entry or
source that config does not declare → exit 1, config untouched even with `--force`; the error
names what covers it or where else it is declared. `check` writes nothing; non-zero = a sync
is due. An option the command does not take → exit 2, nothing runs (`--project-dir` goes with
all); `-h` anywhere only prints usage, `-v` only as first argument.

## Sources

Sources use `skills/<name>/`, `agents/<name>.md`, `rules/<name>.md`; Claude plugin repos
work too (`skilletor add obra/superpowers`, `skilletor add anthropics` → anthropics/skills),
and a repo's own `.claude/` items (`skilletor add Getty/karr`). Skills anywhere else: set
`path` on the entry. A GitHub/GitLab/Codeberg/Hugging Face tree link
(`github.com/o/r/tree/<ref>`, `…/releases/tag/<tag>`) adds the repo pinned to `<ref>`. `add`
never replaces a source: to pin one already configured, set `ref` in its entry by hand
(`{ "ref": "v2" }` in `skilletor.local.json` pins a project's source on this machine). Read
[references/sources.md](references/sources.md) for `add`'s default name, every link form, its
exit-1 cases, `path`, and the rules for source names and entry fields.

## Config

The declaring file sets the scope: `~/.claude/skilletor.json` (user, installs under `~`),
`<project>/.claude/skilletor.json` (project, committed), `<project>/.claude/skilletor.local.json`
(machine-local, not committed; installs like project).

**A project using skilletor** gets the plugin required in its committed `.claude/settings.json`
by the next sync (`… updated — commit it`): tell the user to commit it with `skilletor.json`,
or a fresh checkout lacks the (gitignored) items. Details: [references/sync.md](references/sync.md).

```json
{
  "sources": {
    "shared": { "git": "https://github.com/Getty/skills", "ref": "main" },
    "team":   { "url": "https://skills.example.com/skills.tar.gz" },
    "mine":   { "local": "~/dev/my-skills" }
  },
  "install": { "skills": ["perl-moo@shared"], "agents": ["karr@shared"],
               "rules": ["commit-style@team"], "bundles": ["perl@shared"] },
  "vars": { "kubernetes": true }, "gitignore": true, "checkInterval": 1800
}
```

- Only `skill`, `agent`, `rule` are installable — never hooks, settings or MCP configs.
- `ref` (git) is a plain branch, tag or commit name — omit it, never `""`, for the remote's
  HEAD; `url` is `https://` only. `ref` and `path` merge project < user < local, replaced whole.
- `gitignore` (default true: commit `skilletor.json` and each `.gitignore` the report names)
  and `checkInterval` (user file only): [references/sync.md](references/sync.md).
- `targets` (any of `claude`, `codex`, `hermes`; unset = auto-detected, `hermes` never is):
  it **replaces** detection — list every harness wanted, `["claude", "codex", "hermes"]`
  to add Hermes (`["hermes"]` alone drops the others). The user file sets the machine's set,
  a project or local file only narrows it (`["claude"]` keeps a project's `AGENTS.md` and
  `.codex/` untouched). Details: [references/codex.md](references/codex.md).

### Wildcards and name patterns — `*@source`, `perl-*@source`

`"rules": ["*@shared"]` (or `"rule:*@shared"`) declares every rule the source offers; `*`
matches anywhere in the name (`"skills": ["perl-*@shared"]`, `"rule:*-style@shared"`),
re-expanded on every sync. A pattern matching nothing warns; a bare `*` stays silent. An
explicit entry beats a wildcard (warning if from another source). A source that can't be
resolved (offline, untrusted, broken) keeps everything it installed.

An item installed by a wildcard or bundle can't be uninstalled by name: uninstall
`type:*@source` / `bundle:name@source`, or gate the item via vars (empty render → skipped).

## Bundles — `install.bundles`

A source's `bundles/<name>.yaml` (or `.yml`) names a set of items; a config declares it
once. Vars: `source defaults < bundle < user < project < local`. A bundle naming another
source's items (`name@<address>`): `install bundle:` offers to add it (no TTY: exit 1,
prints `skilletor add …`); **`sync` and hooks never add sources** — they warn and skip those
items. Put an agent and the skills its `briefing.skills` names in one bundle (a user agent
never sees project skills). Read [references/bundles.md](references/bundles.md) before
writing one, and on a bundle error or a `briefing skills not installed` warning.

## Templates

A source file ending in `.njk` is rendered with Nunjucks (installed with `.njk` stripped);
every other file is copied byte for byte. A `.njk` main file that renders empty (after its
frontmatter) switches the item off in that scope and target, installed copy removed. A
`{% if %}` in frontmatter opens with `{%-`, or its blank line silently truncates a
`briefing:` block. Read [references/templates.md](references/templates.md) before writing or
debugging a template (context variables, undefined `vars.*`, `f` beside `f.njk`, the on/off
pattern).

## Trust

`skilletor add` (or your own user config or `skilletor.local.json`) trusts a source. A
backend from a cloned repo's committed `skilletor.json` — a source only it declares, or a
`local`/`git`/`url` it adds to one of yours that ends up used — is neither fetched nor
rendered until `skilletor trust <name>`, which trusts exactly the backend in use; a changed
address or a switch of that backend (a `local` dir appearing or vanishing) lapses it. A
project never changes what your user-scope items are built from. Trust means code
execution, the same level as installing a plugin.
