# Validation report

Build date: **2026-10-09**. Scope: the skill package, its offline tools, and its pure
Perl helper. No managed host was changed, and no upstream repository was modified.

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| Python unit tests | **42 tests passed**, no skips | [Full output](audit/results/python-tests.txt) |
| Pure Perl plan tests | **19 assertions passed** | [TAP output](audit/results/perl-tests.txt) |
| Standalone Perl inspector syntax | Passed with `perl -c` | Compiled only the supplied inspector, not a Rexfile |
| Pure Perl helper syntax | Passed with `perl -c` | No Rex dependency or target connection |
| Python source compilation | Passed | Scripts and test module compiled as Python source, not executed Rex |
| Module inventory | Executed; the eight inspected Rex/transport module names were absent | [Inventory JSON](audit/results/module-inventory.json) |
| Static review of four shipped Rexfiles | No configured pattern matched | [Review JSON](audit/results/example-static-review.json); **not** a Perl syntax or safety proof |
| Original input preservation | SHA256 matched the uploaded input | Byte-for-byte archived baseline |
| Package paths/frontmatter/local Markdown links/JSON | Passed in the finalized directory | Reproduce with `python3 scripts/validate_package.py .` |
| Manifest coverage and SHA256 | Passed; every shipped file except MANIFEST.json is hashed | Reproduce with the validator |
| ZIP round trip | Extracted package validated; offline suites rerun | External release-validation report accompanies the ZIP |

The first Python test run found an incorrect test expectation for the inventory
module count (nine instead of eight). The assertion was corrected to check the exact
expected module-name set, then all 42 tests were rerun successfully. This was a test
expectation issue, not an observed Rex backend defect.

## Not executed or not established

Rex is not installed in the working environment. Therefore the Rex-dependent
Rexfiles and Example::RexAdapter were **not** compiled or run against Rex. The local
Rex smoke task remains an integration asset, not a passed test. There was no remote
SSH, SFTP, sudo, backend status, timeout/cancellation, hardware GPU, or Kubernetes
integration test. No agent was run against the 20 evaluation scenarios.

The code review used specific GitHub files/ranges and release documentation.
A local clone/dependency download was unavailable. No complete source checkout,
release-tarball equivalence, complete native-library audit, exhaustive provider review,
performance benchmark, or security certification is claimed. Implementation findings
are pinned observations and must be checked against the installed version.

## Reproduce offline validation

From the extracted `rex/` directory:

```sh
python3 scripts/validate_package.py .
python3 -B -m unittest discover -s tests -v
perl examples/module/t/plan.t
perl -c scripts/inspect_rex.pl
perl -c examples/module/lib/Example/Plan.pm
perl scripts/inspect_rex.pl
```

Use Python 3.10+ and a standard Perl installation. `-B` prevents unmanifested Python
bytecode files. Do not write test output into this folder unless intentionally making
a new package and regenerating its manifest. The validator does not fetch remote
URLs, resolve renderer-specific Markdown anchors, or verify publisher authenticity.

## Remaining acceptance work

Use [the target matrix](templates/test-matrix.md) for each approved backend/OS/sudo
combination. At minimum, establish host-key rejection, status contract, file fidelity,
permission failure behavior, timeout reconciliation, and a second unchanged apply.
Add application-health, GPU-workload, or cluster tests only when those integrations
are actually used. Mocked commands and code inspection must remain separate from
real target evidence.
