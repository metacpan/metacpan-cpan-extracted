# Mojo-Darkpan reference

Mapped: whole repo, 2026-10-22, at `main` (530ec23) plus uncommitted changes: `Dockerfile` rewrite, PR #5 patch, traversal and config fixes, `t/01_routes.t`.

| Page | Contents |
|------|----------|
| [overview.md](overview.md) | What the system is, major parts, deployment |
| [module-map.md](module-map.md) | One row per module |
| [entry-points.md](entry-points.md) | Routes, CLIs, config inputs |
| [domains.md](domains.md) | Domain areas, code locations, term gaps |
| [data-flow.md](data-flow.md) | Upload, index and list flows; on-disk layout |
| [external-systems.md](external-systems.md) | OrePAN2, LDAP, git, CPAN clients |
| [test-landscape.md](test-landscape.md) | Tests and how to run them |
| [build-and-deploy.md](build-and-deploy.md) | Build tooling, Dockerfile, CI |

## Commands

No `AGENTS.md` `Commands:` line exists; discovered from the repo.

| Task | Command |
|------|---------|
| Install deps | `cpanm --installdeps .` (from `cpanfile`) |
| Test | `prove -l t` |
| Run (production mode) | `perl script/darkpan --port 3000 [--config config.json]` |
| Run (dev, morbo reload) | `perl script/darkpan --devmode` |
| Docker | `docker build --tag mojo-darkpan:latest .` |

No lint, format or type-check commands are configured.
