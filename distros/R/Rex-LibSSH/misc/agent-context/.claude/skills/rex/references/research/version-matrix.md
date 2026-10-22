# Version and evidence matrix

Verified against the available primary sources on **2026-10-09**. This is a research
snapshot, not a compatibility guarantee or an instruction to upgrade.

| Component | Indexed stable CPAN release | Release date | Inspected repository version literal | Interpretation |
|---|---|---|---|---|
| Rex | 1.16.1 | 2025-07-05 | 9999.99.99_99 | Development placeholder, not a released version |
| Rex::LibSSH | 0.004 | 2026-09-20 | 0.005 | Main was incremented after 0.004 |
| Rex::GPU | 0.004 | 2026-10-01 | 0.005 | Main was incremented after 0.004 |
| Rex::Rancher | 0.003 | 2026-10-01 | 0.004 | Main was incremented after 0.003 |

Rex's researched minimum Perl is 5.14.4. The package's Python utilities target
Python 3.10+; that is a requirement of these utilities, not of Rex. Native SSH/client
and platform-tool compatibility must be verified for the intended controller/target.

## Important constraints

Rex::LibSSH's documented secure host-key behavior requires Net::LibSSH 0.004 or later.
Rex::Rancher's GPU setup path requires a suitable Rex::GPU version (the inspected
orchestrator checks at least 0.002 when it owns setup); inspect the installed module
for additional application dependencies. These are not full transitive dependency
locks. Use the application's package manager and retain its resolved build record.

A feature bundle such as `1.4` is not a CPAN version pin. A successful `require` is
not a backend conformance test. Code on a pinned development commit may differ from
the released tarball even when changes appear small; verify the installed files
before applying an implementation-level conclusion.

## Sources

[Core release](https://metacpan.org/pod/Rex),
[LibSSH release](https://metacpan.org/pod/Rex::LibSSH),
[GPU release](https://metacpan.org/pod/Rex::GPU), and
[Rancher release](https://metacpan.org/pod/Rex::Rancher).
Exact repository commits and reviewed ranges are in
[the source map](source-map.md) and [SOURCE_LOCK.json](../../SOURCE_LOCK.json).
