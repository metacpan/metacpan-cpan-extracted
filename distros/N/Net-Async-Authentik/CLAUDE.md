# CLAUDE.md

Net::Async::Authentik — IO::Async-based client for authentik: the async twin of
`WWW::Authentik` (`p5-www-authentik`), same API surface with `_f` suffixes returning
Futures, a structural sibling of `Net::Async::Keycloak`. Moo-based on
`IO::Async::Notifier`; released to CPAN via Dist::Zilla `[@Author::GETTY]`.

The sync twin leads: an API lands in `p5-www-authentik` first and is mirrored here.

**Phase 1 is built** against authentik 2026.8.3. The design is the sync twin's
`docs/superpowers/specs/2026-10-04-www-authentik-design.md`; this repo's plan is
`docs/superpowers/plans/2026-10-04-net-async-authentik-phase-1.md`, and it holds what
`Net::Async::HTTP` does differently from LWP.

## Modules

- `Net::Async::Authentik` — facade extending `IO::Async::Notifier`: `base_url`, optional
  `application`, `client_id` and `token`; lazy `http` (`Net::Async::HTTP`, added as a
  child), lazy `oidc` and `api`. Add it to a loop before the first request.
- `Net::Async::Authentik::OIDC` — per application, every method with `_f`. Callers
  waiting on the discovery document or the keys share one fetch.
- `Net::Async::Authentik::API` — the REST API v3 with `_paged_f`, `resolve_f` and the
  `ensure_*_f` methods.
- `Net::Async::Authentik::Role::HTTP` — `send_request_f` and `fail_validation`, composed
  before `WWW::Authentik::Role::HTTP` so its error classes win.
- `Net::Async::Authentik::Error` — base; `::Validation`, `::Network`, `::API`, each also
  the matching `WWW::Authentik::Error` class.

## What comes from the sync distribution

`build_request`, `read_response` and `flatten_field_errors` from
`WWW::Authentik::Role::HTTP`, the comparison from `WWW::Authentik::Diff`, and the
resolution table plus `uuid_pattern`/`integer_pattern` from `WWW::Authentik::API`. Do not
copy any of it. Everything with I/O is written here.

`t/lib/FakeAuthentik.pm` is the one exception: a test file cannot be a dependency, so it
is a copy, and `t/00-load.t` fails when the two drift.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/net-async-authentik-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-async-authentik-worker` (default) |
| Write/extend tests | `net-async-authentik-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-async-authentik-release-manager` |
| Write/maintain POD | `net-async-authentik-doc-writer` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Commands

The synchronous distribution has to be on the path for every run:

```bash
export PERL5LIB=$HOME/dev/p5-www-authentik/lib

prove -lr t          # full test suite (recursive; live tests skip by default)
dzil test --all      # including the author and release tests
dzil build           # build the distribution

# the live suite, against a throwaway authentik from t/authentik/
AUTHENTIK_LIVE_TEST=1 AUTHENTIK_URL=http://127.0.0.1:9000 AUTHENTIK_TOKEN=... prove -lv t/90-live-authentik.t
```

`LICENSE` is committed, not generated at build time; re-run `dzil genlicense` and
`git add LICENSE` after changing license, holder or year in `dist.ini`.
