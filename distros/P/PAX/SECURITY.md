# Security Policy

## Scope

PAX packages Perl applications into standalone executables and bundles runtime
payloads, assets, and helper code. Report vulnerabilities that affect:

- the public `pax build` and `pax run` workflow
- standalone runtime extraction, loading, and helper dispatch
- bundled dependency resolution and runtime payload packaging
- embedded asset handling and packaged web-application execution

## Reporting a Vulnerability

Please report security issues privately before opening a public issue.

- Contact: `security@manif3station.dev`
- Backup contact: `https://github.com/manif3station/PAX/security/advisories`

Include:

- the PAX version
- the target operating system and Perl version
- whether the issue affects `pax build`, `pax run`, or a produced standalone
  binary
- a minimal reproducer or fixture
- whether the issue requires local access, crafted input, or a packaged binary

## Triage Expectations

Issues in the standalone loader, packaged helper dispatch, runtime payload
extraction, and build-time dependency discovery are treated as high priority
because they affect the trust boundary of produced binaries.
