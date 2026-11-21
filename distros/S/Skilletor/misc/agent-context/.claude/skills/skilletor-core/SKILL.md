---
name: skilletor-core
description: "Use when changing skilletor's own code, tests, build or plugin wiring — src/, test/, dist/, hooks.json, plugin.json, the bundled skilletor skill — or when a change must be verified against a real Claude Code or Codex session. Also when a test passes under tsc but fails under node, or dist/ drifts from src/."
---

# skilletor — architecture and invariants

skilletor is a Claude Code, Codex and Hermes plugin plus a standalone CLI that installs
**skills, agents and rules** from remote sources for each targeted harness, in
user scope (`~`) and project scope (the project root), re-rendering every sync. Its payload is
other people's skills, so two kinds of work meet here: TypeScript on the engine, and
authoring/assessing the skill-shaped files it ships and syncs. Design spec:
`docs/superpowers/specs/2026-09-22-skilletor-design.md`. User-facing CLI and
config reference: `skills/skilletor/SKILL.md` (the skill the plugin ships) —
read it instead of re-deriving the config format.

## Module boundaries (spec §10) — keep them

```
cli.ts        arguments, dispatch                     commands.ts  add/install/… edit config, then sync
config.ts     load/merge/validate + edit operations   spec.ts      shorthand → {git|url|local} + a GitHub link's ref, path
probe.ts      real probe for `add` (ls-remote, HEAD)  sources/*    resolve(), check() per backend
catalog.ts    scan a source dir → items (plugin.json) bundles.ts   bundle files, `*` name patterns
render.ts     build one item in memory (Nunjucks)     apply.ts     diff → atomic write → clean
gitignore.ts  .gitignore/.worktreeinclude blocks §6.4 briefing.ts  installed agent's briefing skills present? (§6.7)
lock.ts       lock read/write                         state.ts     trust, last-check, pending-report, mutex
engine.ts     sync / check / status pipeline          hooks.ts     SessionStart, UserPromptSubmit, CwdChanged, PostToolUse; black box
report.ts     text / json / hook output               targets.ts   harness detection, LAYOUTS, lock keys
convert.ts    agent Markdown → Codex TOML             agentsmd.ts  Codex rules file, AGENTS.md pointer, hook trust
frontmatter.ts  YAML subset reader                    toml.ts      TOML writer (no dependency)
fsutil.ts     hash, atomicWrite, innerSegments        gitenv.ts    gitEnv(): the env of every git run
claudesettings.ts  plan the project settings.json plugin requirement (§6.8); engine writes
```

- `sources/*` knows nothing about templating; `render` nothing about the
  target filesystem; `apply` nothing about sources. A change that makes one of
  them import the other is a design change — file a ticket, don't sneak it in.
- Every git run is `execFile*` (no shell) with `env: gitEnv()` — never `{...process.env}`:
  an exported `GIT_DIR` (a git hook, `rebase -x`) would aim a cache's `reset --hard` at
  that repository. A user's address or ref goes after `--`.
- Everything a backend needs (probe, timeout, cache root, `home`, `codexHome`,
  harness `markers`, `isGitWorkTree`, `pluginRoot`) is injected through `EngineContext`;
  tests rely on that to run against temp directories and never look at the real machine.
  Every new `EngineContext` fixture sets `isGitWorkTree: () => false` — the temp dir's real
  location must not decide whether user-scope `.gitignore` blocks appear.
- Before touching `catalog.ts`, a source's `path` or backend-less source entries in
  `config.ts`, read [references/sources.md](references/sources.md).
- `briefing.ts` reads installed agent files (never renders) — a warning source, not a
  pipeline stage; it must not block a sync.
- `apply` knows nothing about harnesses: it gets a lock key → root function.
  Per-harness knowledge lives in `LAYOUTS` (`targets.ts`); output conversion
  (`convert.ts`) runs in the engine between render and apply.

## Invariants that must survive any change

- **Render-and-compare, no invalidation.** Every sync builds every declared item
  in memory and diffs against disk + lock. There is no cache of rendered output —
  but `check` asks for a sync only when a source version or the render-inputs hash
  moves, so a release that changes what a sync makes of unchanged sources and inputs
  bumps `RENDER_FORMAT` (`engine.ts`), or earlier installs wait for a source to move.
  A change to what a url cache tree holds bumps `URL_CACHE_FORMAT` (`sources/url.ts`).
- **The lock is the ownership boundary.** One lock per scope, always
  `<scope>/.claude/skilletor.lock.json`, for every harness. Claude keys stay
  unprefixed (`skills/foo`); the others carry their harness (`codex:skills/foo`,
  `hermes:…`), paths relative to that key's root. Only paths in the lock are ever
  overwritten or deleted; entries with an unknown prefix are kept untouched. A path on disk that is not in the lock
  is a conflict (reported, untouched; `--force` adopts it). A managed file that
  diverged from its lock hash is overwritten and named in the report.
- **Codex rules: the rules file is owned, `AGENTS.md` is shared.** Rules are
  `block: true` lock entries keyed on `skilletor-rules.md`; `apply` never touches disk
  for them — the engine rebuilds the whole rules file from the new lock. The Codex
  `SessionStart` hook (`--harness codex`) injects it on startup/clear, never on resume.
  `AGENTS.md` gets only a fixed pointer between `<!-- skilletor:begin -->`/`end`; text
  outside the markers is never modified, and a refusal (malformed markers, symlink,
  `CLAUDE.md` identity) skips only the pointer, even with `--force`.
- **Installable types are exactly** `skill`, `agent`, `rule` (`ITEM_TYPES` in
  `config.ts`); where each lands is `LAYOUTS[harness].roots[type]` per scope.
  Hooks and MCP configs are never synced; settings only as the next bullet says.
- **`.claude/settings.json` is add-only, project scope only** (spec §6.8). A project
  sync with a committed `skilletor.json`, `claude` targeted and `claudeSettings` not
  `false` adds `skilletor@<m>` to `enabledPlugins` and every marketplace an enabled entry
  needs to `extraKnownMarketplaces`; no existing key changes (a `false` stays). Never
  `~/.claude/settings.json` or `settings.local.json`. `<m>` and its source are read, never
  written, from `<home>/.claude/plugins/`; a non-remote source (directory, file, local git
  path) never enters the committed file — a warning. Its virtual result must preserve implicit project targets; if not, this skips only settings (unlike an unresolved project scope) while items sync normally, with a warning to set explicit project `targets` then sync; neither targets nor provenance are written.
  Only an actionable plan with `SettingsPlan.next` is `check` layout drift (`layout:claude-settings`); warning-only and target-preservation-guarded plans are not.
- **Item names ignore case** on every platform (one directory on macOS/Windows): a new
  comparison or map key of item names goes through `nameKey()` (`config.ts`).
- **Targets:** machine set = user `targets` ?? detected markers (empty → config error, nothing touched); it is the user-scope set and a project allowlist, not every project's targets.
  Project order is local explicit `targets` > committed explicit `targets` > genuine local harness evidence, intersected with it. Skilletor-generated output, empty settings, and settings with only skilletor-generated plugin/marketplace declarations are never evidence.
  No evidence bootstraps a sole machine target; with several, leave project output unchanged and warn for explicit project `targets`. Explicit project targets, including a deliberate dual-harness list, decide fresh checkouts.
  Hook event and invoking harness never affect selection. Only Claude and Codex have machine-detection markers; Hermes (skills only, spec `2026-10-04-hermes-target-design.md`) needs user-level explicit opt-in, then genuine project `.hermes` evidence may select it.
  Its home is `$HERMES_HOME` else `defaultHermesHome()` (`targets.ts`; `%LOCALAPPDATA%\hermes` on Windows). Every item renders once per active target with `harness` in the context; empty render skips per target.
- **Managed blocks follow the layout, never items or targets.** The `.gitignore` blocks
  and the project's `.worktreeinclude` block (`worktreeIncludeEntries`, `engine.ts`) list
  every harness's roots, so committed files agree across machines; a `.worktreeinclude`
  block other than the one a sync writes is `layout` drift in `check`. A root or
  `LAYOUTS` change moves both, and this repo's committed `.worktreeinclude` with it.
- **Templating:** only `*.njk` is rendered (installed with `.njk` stripped);
  everything else is copied byte for byte. A skill's file keeps its source's owner
  executable bit (a `.njk` passes its bit to what it renders); agents, rules and
  generated files never carry it. The lock hashes bytes only (`check` sees no mode);
  a sync rewrites a file whose bit is wrong. Context has no `env.*`. An undefined
  variable is an error, and a template error leaves that item at its old state.
- **Trust:** a source declared only in a project config is not fetched until
  `skilletor trust <name>`; a changed URL lapses trust.
- **Security:** item names, tar entries, includes and a source's `path` cannot escape
  source or target root; symlinks in sources are rejected; `url` sources are HTTPS-only.
- **A hook never disturbs the session:** every path in `hooks.ts` catches, exits
  0, and surfaces problems as one warning line. Offline → cache + warning.
- **Config default vs. fallback:** `checkInterval` defaults to 1800 s in
  `config.ts`; the `DEFAULT_INTERVAL` in `hooks.ts` is only the fallback when the
  config cannot be loaded. `<= 0` disables the in-session check.

## Activation facts (measured in the spike, spec §12)

Claude Code: skills written mid-session are usable at once; agents and rules are
read at session start or `/reload-plugins` and take effect from the **next**
prompt. Codex (lists a skill written mid-session from the next session) and Hermes
(skill index built before the sync) report every item "active from the next … session".
`report.ts` `ACTIVATION` / `HARNESS_ACTIVATION` state this — keep the wording honest
when adding item types, harnesses or changing the report.

## Code conventions

- **Erasable TypeScript only.** Tests run `.ts` through Node's type-stripping:
  constructor parameter properties, `enum`, runtime `namespace` fail with
  `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX`, and `tsc --noEmit` does **not** catch it.
  Assign fields in the constructor body; `npm test` is the check that counts.
- Runtime dependency is Nunjucks alone. Adding another is a design decision.
- Public artifacts (code, comments, docs, README, this skill) are English.

## Verify — every code change

```bash
npm run typecheck && npm test        # node:test, temp dirs
node --test --import ./test/setup.ts test/<file>.test.ts   # one file; setup.ts drops GIT_DIR, HERMES_HOME, CLAUDE_PLUGIN_ROOT & co.
npm run build && npm run check-dist  # dist/skilletor.js is committed; CI diffs it
```

- **`dist/` ships.** Any `src/` change without `npm run build` fails CI's
  `check-dist`. Commit `dist/skilletor.js` with the source change.
- Test git fixtures use `git init -b main` (the default branch name is not
  portable). Path comparisons go through `realpathSync` (macOS `/var` →
  `/private/var`). Several tests create symlinks — Windows is not in CI. A spawned
  CLI's env comes from `homeEnv()` (`test/helpers/harness.ts`): on Windows the home is
  `USERPROFILE`, and `LOCALAPPDATA` holds Hermes' default home — `HOME` alone leaks.
- **A CLI run from the checkout acts on the real `~/.claude/`, `~/.agents/`, Codex
  home and this repo's real `.claude/skilletor.json`.** Before a hand test, a hook
  drive or a live Claude Code check, read [references/hand-tests.md](references/hand-tests.md).

## Release surface (audit, never perform)

`package.json`, `.codex-plugin/plugin.json` and `hermes/skilletor/plugin.yaml` carry the
same version (tests enforce it); `.claude-plugin/plugin.json` carries none, Claude Code
takes the plugin version from the commit; a tag `vX.Y.Z` matches the three; `README.md` and `skills/skilletor/SKILL.md` restate the
CLI reference and must match `src/cli.ts` usage text. Steps and the marketplace
entry: `docs/release.md`. Tagging, pushing and marketplace edits are the
maintainer's, on explicit go-ahead only.

## Hazards of this repo

- **Agent files take `tools:`, not `allowed-tools`.** Claude Code ignores unknown agent fields
  silently, so a misnamed key hands an auditor write access.
- **Eval runs are billed** — `claude plugin eval` spawns full sessions. Start one only when the
  ticket or the user asks.
