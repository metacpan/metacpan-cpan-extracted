# skilletor House Rules

The shared house rules come from skilletor — bundle `getty-house@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination. They load as
`.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

The Claude Code plugin + CLI that installs skills, agents and rules from remote sources; its
payload is other people's skills (architecture: skill `skilletor-core`). Public artifacts —
code, comments, docs, skills — are English. Read first: exports, immediate callers,
`EngineContext`, and the spec section the module implements.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug `src/`, `test/`, hooks, build, plugin wiring | `skilletor-worker` (default) |
| Judge quality or strength of a skill, agent, rule, source or eval result | `skilletor-skill-auditor` |
| Write, rework, shrink or merge a SKILL.md, agent, rule or `.njk` item | `skilletor-skill-author` |
| Commits, `Changes`, card → done, pre-release audit | `skilletor-release-manager` |
| Read-only research, audit, gap analysis | `skilletor-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `src/`, `test/`, `hooks/`, `bin/`, `dist/`, `scripts/`,
`lib/`, `script/`, `t/`, `maint/`, `cpanfile`, `dist.ini`, `.github/workflows/`, the
plugin manifest, and the text of any skill, agent or rule file (this repo's `.claude/` set and
`skills/skilletor`). `README.md`, `docs/` and ticket notes are not.

## Release

`npm test`, `npm run build`, `npm run check-dist` are fine anytime. Any edit to
`Getty/marketplace` is under the publish gate too, like `git tag`, a push and `gh release`.
`dzil release` tags, pushes and creates the GitHub release: it is under the publish gate.
`DZIL_BINARY_SKIP=1 dzil build` is fine anytime.

## Hazards

- **A green `tsc` can still crash at runtime** — Node's type-stripping rejects non-erasable
  syntax; `npm test` is the check that counts.
- **`dist/` is committed and CI diffs it** — every `src/` change ships with a rebuilt
  `dist/skilletor.js` in the same commit or CI fails `check-dist`.
- **The CLI writes to the real home and this repo** — hand tests use a temp cwd with temp `HOME`
  and `CODEX_HOME`.
- **Agent files: `tools:`, not `allowed-tools`** — Claude Code ignores unknown agent fields
  silently, so a misnamed key hands an auditor write access.
- **dzil gathers git-tracked files only** — `git add` a new file before `dzil build`, or the
  tarball lacks it.
- **One version line** — lib `$VERSION` x.yyyzzz is package.json x.y.z (0.008000 = 0.8.0); after
  `dzil release` lib is one bump ahead (0.008001) until the next release prepares package.json
  (`t/02-version.t` accepts both, `maint/version-tie.pl` gates the release).
- **Eval runs are billed** (`claude plugin eval` spawns full sessions) — start one only when the
  ticket or the user asks.
