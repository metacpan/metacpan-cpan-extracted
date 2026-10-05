---
name: net-async-keycloak-core
description: Use when working on Net::Async::Keycloak — the IO::Async/Future client for Keycloak's OIDC endpoints and Admin REST API, its module layout, error classes, or its tests.
---

# Net::Async::Keycloak core

IO::Async-based client for Keycloak, the async twin of `WWW::Keycloak`
(`~/dev/p5-www-keycloak`), modelled on `Net::Async::Zitadel` (`~/dev/p5-net-async-zitadel`).
Phase 1 is built (2026-10-03); the plan is `docs/superpowers/plans/2026-10-03-net-async-keycloak-phase-1.md`.
Requests are built and responses read by `WWW::Keycloak::Role::HTTP` (`build_request`,
`read_response`); `Net::Async::Keycloak::Role::HTTP` only sends, and classes compose it
**before** the sync role so its error classes win. `ensure_*_f` compare with
`WWW::Keycloak::Diff`. The tests in `t/20`–`t/60` and `t/90` are WWW::Keycloak's, ported to
`_f->get`; when the sync tests change, port them again.

## Module map

- `Net::Async::Keycloak` — Moo class extending `IO::Async::Notifier`: `base_url`, `realm`,
  optional credentials; lazy `http` (`Net::Async::HTTP`, added as child), lazy `oidc` and
  `admin`.
- `Net::Async::Keycloak::OIDC` — discovery, JWKS, token verification, userinfo,
  introspection, token and device endpoints.
- `Net::Async::Keycloak::Admin` — Admin REST API: realms, clients, users, credentials.
- `Net::Async::Keycloak::Error` — base; `::Validation`, `::Network`, `::API`, one package
  per file.

## Invariants

- **The sync twin leads.** Every public method here exists in `WWW::Keycloak` under the
  same name plus `_f`. Do not invent API here; if the twin lacks it, ticket the twin.
- **Every method returns a Future and never blocks.** No `->get` in library code, no
  synchronous HTTP client.
- **Notifier construction.** `IO::Async::Notifier->new` hands every key to `configure`,
  which croaks on unknown keys — strip own attributes in `FOREIGNBUILDARGS`, as
  `Net::Async::Zitadel` does.
- **Keycloak facts are verified, not remembered** — see the twin's core skill; the same
  rule applies here.
- **Live tests are opt-in** (`KEYCLOAK_LIVE_TEST=1 KEYCLOAK_URL=…`). A default
  `prove -lr t` passes with them skipped.
