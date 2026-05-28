# Release Pipeline (deferred)

This doc captures the design of the porting-sdk release / version-pinning pipeline that was scoped during the CI buildout but deliberately not shipped. Layers 1 (per-repo PR gate), 2 (porting-sdk cross-port matrix), and 3 (nightly full-matrix) are live and green. The pinning story is item 5 of the original setup checklist in [`CI_PLAN.md`](CI_PLAN.md) §6.

Status: **deferred**. The current always-HEAD model is safe in practice because Layers 2+3 catch drift before merge. Revisit when one of the triggers below hits.

---

## Why we deferred

The current model: each port's `audit.yml` checks out `signalwire/porting-sdk@main`. A porting-sdk merge can in principle make port repos red, but Layer 2 fans the porting-sdk PR out across all 9 ports' `bash scripts/run-ci.sh` before merge — so anything that would break a port is caught and the porting-sdk PR doesn't merge until it's clean. Layer 3's nightly cron catches drift introduced by port-side merges that happened after the last cross-port run.

In practice, this gets us 95% of the value of pinning without the overhead of:
- 9 Renovate PRs per porting-sdk release
- A separate workflow that has to stay green to publish
- Tagging discipline coordination across the matrix

The 5% it doesn't get us: external forks of port repos can't run CI without porting-sdk read access, and we have no clean "this port shipped against porting-sdk vX.Y.Z" attestation.

## Triggers to revisit

Cut the release pipeline when:
1. You publish your first official port release with semver and want a verifiable claim about what porting-sdk version it was tested against.
2. External contributors start submitting PRs and the porting-sdk private-repo dependency becomes a friction point.
3. Layer 2 or 3 lets a regression slip through and pinning would've caught it.
4. Renovate PR #3 lands or someone wires another bot — the bot needs versioned artifacts to track.

Until one of those, the always-HEAD model with Layer 2+3 backstop is the right trade-off.

---

## Design (what to ship when we revisit)

### 1. `release.yml` workflow in porting-sdk

Triggered on tag push (`v[0-9]+.[0-9]+.[0-9]+`). Bundles the audit-stable artifacts as a GitHub Release:

- `python_signatures.json` — Layer A reference oracle
- `python_surface.json` — Layer B reference oracle
- `relay-protocol/*.json` — RELAY wire schemas
- `rest-apis/*/openapi.yaml` — REST contract sources
- `type_aliases.yaml` — cross-language type vocabulary
- `surface_schema_v2.json` — output schema
- `test_harness/mock_signalwire/` and `mock_relay/` as installable wheels (optional — these can also be installed via `pip install -e` against a checkout)

Output: a single `porting-sdk-vX.Y.Z.tar.gz` attached to the release, plus the wheels if shipped.

```yaml
# .github/workflows/release.yml in porting-sdk
name: Release
on:
  push:
    tags: ["v*.*.*"]

jobs:
  bundle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Bundle artifacts
        run: |
          mkdir -p dist
          tar -czf dist/porting-sdk-${{ github.ref_name }}.tar.gz \
            python_signatures.json python_surface.json \
            relay-protocol/ rest-apis/ \
            type_aliases.yaml type_vocabulary.yaml \
            surface_schema_v2.json
      - name: Build mock wheels
        run: |
          pip install build
          python -m build test_harness/mock_signalwire/ -o dist/
          python -m build test_harness/mock_relay/ -o dist/
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

### 2. Per-port `.porting-sdk-version` pin file

Each port repo gets a single-line file at its root:

```
$ cat .porting-sdk-version
v1.2.3
```

### 3. Per-port `audit.yml` reads the pin

```yaml
- name: Read porting-sdk pin
  run: echo "PSDK_REF=$(cat .porting-sdk-version)" >> $GITHUB_ENV

- name: Check out porting-sdk @ pin
  uses: actions/checkout@v4
  with:
    repository: signalwire/porting-sdk
    ref: ${{ env.PSDK_REF }}
    path: porting-sdk
    token: ${{ secrets.PORTING_SDK_TOKEN }}
```

(Layer 2's `cross-port.yml` continues to check out porting-sdk at the PR SHA — that gate doesn't pin; it always tests "this PR vs all-ports-at-HEAD" because that's its whole job.)

### 4. Renovate config

`.github/renovate.json` in each port repo (or a shared template via PR #3):

```json
{
  "regexManagers": [
    {
      "fileMatch": ["^\\.porting-sdk-version$"],
      "matchStrings": ["^(?<currentValue>v.+)$"],
      "depNameTemplate": "signalwire/porting-sdk",
      "datasourceTemplate": "github-releases"
    }
  ]
}
```

Renovate watches porting-sdk releases and opens a PR per port to bump the pin. The port's CI runs against the new pin. Green PRs auto-merge (or wait for human review depending on config). Red PRs sit until a human investigates.

### 5. Migration plan

Going from always-HEAD to pinned without breaking everything:

1. Cut `v1.0.0` of porting-sdk at the current main HEAD.
2. Run `release.yml` once via `workflow_dispatch` to populate the first release.
3. Add `.porting-sdk-version: v1.0.0` to each port repo (one PR per port — could batch via a script).
4. Update each port's `audit.yml` to read the pin (one PR per port; same or follow-on).
5. Wire Renovate per port repo (or via a shared template).
6. Cut `v1.0.1` to verify the bump flow.
7. Document for the team: porting-sdk PRs that would break a port now block both Layer 2 (matrix) AND any Renovate PR opened for that port. If you see Renovate PR red, look at Layer 2 results from the porting-sdk PR that produced the bump.

Total work: ~1–2 hours for the workflow + per-port wiring (could be 11 small parallel agents per the original plan).

---

## What we'd lose if we never ship this

Mostly nothing for the SignalWire-internal flow. You'd still want it if any of these become real:

- **External contributor runs CI on a fork**: today they can't clone porting-sdk without `PORTING_SDK_TOKEN`. With releases, they fetch the tarball.
- **"This SDK was tested against porting-sdk vX.Y.Z" attestation** in release notes / git history.
- **Stability windows**: freeze a port's porting-sdk pin while you cut a port release, decoupled from porting-sdk's own release cadence.

If those needs surface, this doc has the design ready to go.

---

## References

- [`CI_PLAN.md`](CI_PLAN.md) §6 item 5 — original mention as deferred work
- porting-sdk PR #3 — Renovate-bot config (paused)
- The current 4-gate set per port: TEST → SIGNATURES → DRIFT → NO-CHEAT (mirrors locally and in CI)
