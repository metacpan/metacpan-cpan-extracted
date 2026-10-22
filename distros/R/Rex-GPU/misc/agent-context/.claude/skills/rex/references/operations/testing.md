# Testing strategy and evidence levels

## Separate four test layers

**Static review:** parse the package structure and inspect source without loading the
Rexfile. The shipped linter flags a small set of risky constructs; it is not a Perl
parser, taint analyzer, or safety certificate. Review imported modules and execution
contexts manually. Treat zero findings as "no configured pattern matched" only.

**Pure unit tests:** validate plans, path policy, option schemas, rendering inputs,
and status-adapter decisions without Rex or a network. Standard Perl Test::More is
appropriate for these helpers. Use normal Exporter for pure modules when no Rex
registration behavior is needed. Test invalid input and keep the input immutable.

**Rex/controller integration:** load the approved Rexfile in a disposable controller
with known dependencies. Execute the local temporary-directory smoke example,
list the intended tasks, and verify imports/feature flags. This step is not covered
by static regex tests or by compiling only a standalone helper.

**Transport/target integration:** test real SSH and filesystem operations against
disposable hosts. Include the exact backend, sudo, OS/tool versions, and workload.
A mock returning a successful command string does not verify transport, host keys,
real drivers, reboot recovery, or Kubernetes readiness.

## Minimum backend contract matrix

For each supported combination: successful exec; exit 7 and raw status; separate
stdout/stderr; trailing-newline behavior; timeout with remote process reconciliation;
missing and changed host-key rejection; missing SFTP; file round trip with quotes,
spaces and non-ASCII bytes; denied read/write; empty file; sudo; large output; and
post-exception context cleanup. Verify File and Fs interfaces separately because
their checks and buffering differ.

## Convergence and operations tests

Apply once, reapply unchanged, change one input, reject invalid input before mutation,
fail during activation, and resume after interruption. Confirm that a failed canary
prevents later hosts from changing. Test independent health gates, not just command
exit. For cluster or GPU adapters, add domain-specific integration and hardware tests.

Rex::Test::Base documents VM-oriented helpers, but its old example images are not a
recommendation for current infrastructure. Choose an approved supported disposable
image and validate the harness. The shipped `evals/cases.json` is an agent-evaluation
specification, not a claim that those scenarios have been run against an LLM.

Use [the test matrix](../../templates/test-matrix.md) to record exact evidence and
[VALIDATION.md](../../VALIDATION.md) for this package's actual executed checks.

## Evidence and scope

- [Rex::Test::Base (release documentation)](https://metacpan.org/pod/Rex::Test::Base)
- [lib/Rex/Exporter.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Exporter.pm)
- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Exec/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Exec/LibSSH.pm)
