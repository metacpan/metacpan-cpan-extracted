# CLAUDE.md

## Project Overview

MooX::Cmd is a **framework** for command-organized CLI apps written with Moo.
It does not ship an application — it ships the machinery that turns a Moo class
tree into a command line application with nested subcommands.

## Modules

- **MooX::Cmd** — the importer: `use MooX::Cmd` composes the role, adds the
  creation method and applies the import options
- **MooX::Cmd::Role** — the engine: attributes, `@ARGV` split, command discovery,
  chain construction, the execute call
- **MooX::Cmd::Tester** — the test helper: `test_cmd` / `test_cmd_ok`
- **MooX::Cmd::Role::AbbrevCmds** — optional role: unambiguous prefixes work
- **MooX::Cmd::Role::ConfigFromFile** — optional role: per-command config sections

## The contract

- the command name is the package below `command_base`, lowercased
- only the **deepest** command of the chain executes; the parents are only
  instantiated
- `execute($self, $args_ref, $chain_ref)`; the return value is stored as an
  arrayref under `command_execute_return_method_name`
- the creation chain tries `new_with_options` before `new`

## Testing

```bash
prove -lr t/     # the suite
prove -lr xt/    # author tests: perlcritic, pod coverage, changes, kwalitee, perltidy
```

The test applications live under `t/lib/`, the config fixtures under `etc/`.

## Code Style

- Moo classes with `is => 'ro'`, `croak` instead of `die`
- every file under `lib/` carries its own `our $VERSION`
- the optional roles load their external dependency only when the role is used

The conventions above are the short list; the binding ones live in the skills and
are force-loaded into the agents below. Do not restate them here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the delegation lock and the publish gate are shared house rules (skilletor bundle
`getty-cpan-dist@getty`); lanes and the framework contract are in
`.claude/rules/moox-cmd-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `moox-cmd-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `moox-cmd-release-manager` |

Only the release-manager commits; a worker leaves a commit-ready tree and a report.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The shared skills under `.claude/skills/`
are **installed** from the Getty library by skilletor — they are not edited here.
`moox-cmd-core` is the one skill this repo owns: module map, the import options,
the command contract, the tester semantics, the vocabulary and the known rough
edges.

## State of the code

- `prove -lr t/` runs eight files; the tests of the optional
  roles run because `MooX::ConfigFromFile` and `Text::Abbrev` are test requirements.
- `LICENSE` is tracked and `dist.ini` carries `copyright_year`, so `dzil build` runs.
- Every module under `lib/` carries `our $VERSION` after `use strict; use warnings;`.
- The skills under `.claude/skills/` are installed by skilletor; `moox-cmd-core` is the
  repo's own.
- CI: `.github/workflows/ci.yml` runs `t/` and `xt/` on Perl 5.30, 5.38 and 5.40; it never releases.
