# CLAUDE.md

Net::Async::Keycloak — IO::Async-based client for Keycloak: the async twin of `WWW::Keycloak` (`p5-www-keycloak`), same API surface with `_f` suffixes returning Futures, modelled on `Net::Async::Zitadel`. Moo-based on `IO::Async::Notifier`; released to CPAN via Dist::Zilla `[@Author::GETTY]`.

The sync twin leads: an API lands in `p5-www-keycloak` first and is mirrored here. Phase 1 is built; until WWW-Keycloak is installed, run tests with `PERL5LIB=~/dev/p5-www-keycloak/lib`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/net-async-keycloak-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-async-keycloak-worker` (default) |
| Write/extend tests | `net-async-keycloak-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-async-keycloak-release-manager` |
| Write/maintain POD | `net-async-keycloak-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Commands

```bash
prove -lr t          # full test suite (recursive; live tests skip by default)
dzil build           # build the distribution
dzil test            # test via Dist::Zilla
```

`LICENSE` is committed, not generated at build time; re-run `dzil genlicense` and
`git add LICENSE` after changing license, holder or year in `dist.ini`.
