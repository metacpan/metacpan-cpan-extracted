# Security policy

## Supported versions

Security fixes are evaluated for the latest released minor version. Earlier
versions may not receive patches.

## Reporting a vulnerability

Please use GitHub's **private vulnerability reporting** feature, if enabled,
or contact **Scott Muller <scott@21h.io>** privately with the details.
Do not open a public issue containing secrets, exploit details, or
proprietary source code. Include a minimal synthetic reproduction when feasible.

## Threat model and restrictions

- Perl CodeMap does **not execute** scanned Perl source code.
- Reports are self-contained; their viewer makes no background network calls.
- Reports with source embedding contain the **actual source code**, and may
  expose credentials, personal information, internal paths or proprietary code.
  Treat them like source archives.
- Avoid uploading private reports to public CI artifacts, Pages, or public
  cloud buckets. Use access controls, artifact expiration, and secret scanning.
- Third-party browser links (via `--source-base`) open only when clicked.
- Never run the analyzer with higher filesystem privileges than necessary.
- `--from-json` input must be treated as untrusted. Source rehydration confines
  reads to a selected root, but the report retains any text already contained
  in its JSON input.

The project is a static visualization tool, not a secure sandbox or source
scanner for secrets. Use specialized secret-scanning tools separately.
