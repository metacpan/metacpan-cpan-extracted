# Rex change brief

## Scope and authorization

Task/operation: [name]. Project commit: [commit]. Desired-state digest: [non-secret].
Authorized targets: [explicit snapshot]. Exclusions: [hosts]. Environment: [name].
Authorized mutations: [operations]. Destructive actions separately approved: [yes/no/not applicable].

## Verified runtime and capabilities

Controller OS/Perl/Rex: [versions]. Configured backend: [name/version].
Effective Exec/Fs/File drivers under the required privilege context: [classes].
Native client/library and target tools: [versions]. Host-key trust source: [verified source].
Required operations and evidence: [exec/metadata/file/transfer/sudo].

## Preconditions and plan

Input schema validated: [result]. Inventory resolved: [result]. Recovery access: [result].
Current state: [observations]. Proposed state: [non-secret summary].
Stages: [preflight → stage → validate → apply → activate → health].
No-change criteria: [exact]. Canary and wave barriers: [exact].

## Failure policy

Per-stage deadline: [values and remote termination behavior]. Retry policy: [by failure class].
Stop conditions: [conditions]. Last safe rollback point: [stage]. Irreversible changes: [list].
Recovery/resume procedure: [steps]. Still-running remote work after timeout: [how checked].

## Evidence and handoff

Tests actually run: [commands/versions/results]. Tests not run: [gaps].
Per-host state and health: [sanitized report]. Secrets/artifact retention: [policy].
Next authorized action: [one precise action or stop].
