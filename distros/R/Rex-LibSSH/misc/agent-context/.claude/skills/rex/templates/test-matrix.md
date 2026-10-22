# Target validation matrix

Use one row per exact controller/backend/target/privilege combination. A code-inspection
expectation is not a pass. Store synthetic test data, not production credentials.

| Combination | Trust reject | Exec exit 7/raw | Stdout/stderr | Files/bytes | Sudo | Timeout reconciliation | Second apply | Evidence |
|---|---|---|---|---|---|---|---|---|
| [versions] | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | NOT RUN | [log location] |

## Required negative cases

Unknown/changed host key; missing SFTP; denied metadata/read/write; unknown platform;
invalid path/options; full destination; interrupted transfer; failed activation;
large stderr/stdout; controller disconnect; still-running remote command after timeout.

## Domain-specific additions

GPU: actual workload, driver/toolkit ownership, reboot, runtime device availability.
Kubernetes: API unreachable/forbidden, CNI readiness, held-version rerun, identity/CIDR
rejection, canary stop, backup/recovery. Mark hardware not exercised as NOT RUN.

## Evidence summary

Test date: [date]. Project/controller image: [digests]. Approved targets: [ids].
Passed: [cases]. Failed: [cases]. Not run: [cases/reasons].
Decision: [accept limited scope / reject / further tests required].
