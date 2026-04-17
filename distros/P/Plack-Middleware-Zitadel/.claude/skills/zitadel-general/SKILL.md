---
name: zitadel-general
description: "General ZITADEL workflow for HI integration and WWW::Zitadel maintenance (OIDC, Management API, tests, k8s live checks)"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

Use this skill when working on ZITADEL-related tasks in this workspace, especially:

- finishing or extending `p5-www-zitadel`
- integrating ZITADEL into `hi-proto` services
- writing/maintaining tests and docs for OIDC + Management API flows
- validating live setup in Kubernetes

## Primary repos

- Sync client: `p5-www-zitadel/` — `WWW::Zitadel::*`
- Async client: `p5-net-async-zitadel/` — `Net::Async::Zitadel::*` (IO::Async, Future-based, `_f` suffix)
- HI app integration target: `hi-proto/`

Both client repos have identical Management API surface. Async methods are `method_f` returning Futures.

## Workflow

1. Determine scope first:
- `library`: API client behavior in `WWW::Zitadel::*` or `Net::Async::Zitadel::*`
- `integration`: how HI services consume verified identity
- `deployment`: k8s runtime (issuer, DNS, cert, gateway, live checks)

2. For library changes — keep both repos in sync:
- Sync: edit `lib/WWW/Zitadel/Management.pm` and `t/03-management.t`
- Async: edit `lib/Net/Async/Zitadel/Management.pm` and `t/03-management.t`
- Keep live tests opt-in (sync: `t/90-live-zitadel.t`; async: `t/10-integration.t`)
- Update `Changes` in both repos

3. For OIDC changes (sync → async differences):
- Sync: `WWW::Zitadel::OIDC` — blocking LWP calls
- Async: `Net::Async::Zitadel::OIDC` — has `discovery_ttl`/`jwks_ttl` caching attrs and JWKS in-flight coalescing

4. Always validate with:
```bash
cd /storage/raid/home/getty/dev/perl/p5-www-zitadel && prove -lr t
cd /storage/raid/home/getty/dev/perl/p5-net-async-zitadel && prove -lr t
```

5. Optional live validation (sync):
```bash
ZITADEL_LIVE_TEST=1 \
ZITADEL_ISSUER='https://<issuer>' \
prove -lv t/90-live-zitadel.t
```

6. Optional live validation (async):
```bash
ZITADEL_ISSUER='https://<issuer>' \
ZITADEL_TOKEN='<pat>' \
prove -lv t/10-integration.t
```

7. Optional pod-to-issuer connectivity test:
```bash
ZITADEL_K8S_TEST=1 \
ZITADEL_ISSUER='https://<issuer>' \
ZITADEL_KUBECONFIG='/storage/raid/home/getty/avatar/.kube/config' \
prove -lv t/91-k8s-pod.t
```

## PostgreSQL 18 note

- If setup fails with `partitioned tables cannot be unlogged`, this is a ZITADEL migration compatibility issue in older ZITADEL versions, not a generic PostgreSQL 18 problem.
- Use ZITADEL versions that include PG18 compatibility fix (v4.11.0+ line).

## Documentation rules

- Keep README examples executable and aligned with real method names.
- Keep POD and README consistent.
- Record any new behavior in `Changes` under `{{$NEXT}}`.
