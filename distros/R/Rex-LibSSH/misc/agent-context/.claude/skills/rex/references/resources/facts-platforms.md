# Facts, target tools, and platform compatibility

## Facts describe the current execution context

The Gather API exposes OS, kernel, network, and hardware information and family
predicates. Its documentation describes these as non-mutating functions. That does
not establish that all gatherer implementations require only an exec channel or
that every extension's detection routine is read-only. In particular, Rex::GPU's
default detector can install `pciutils` if `lspci` is missing.

Gather facts after confirming the intended target context. Do not use the
controller's `$^O`, `%ENV`, or local `/etc/os-release` as the remote platform. Keep
the distinction between OS version, kernel version, architecture, libc, shell,
package provider, and init system. Similar OS names do not imply identical commands
or repository behavior.

## Normalize only what the policy needs

Treat version facts as strings. A tested policy may extract a leading major integer,
but a blanket `int(...)` discards meaningful components and does not parse all
version formats. Validate shape before extracting; preserve the original value for
audit. Do not lexically compare dotted versions or assume all vendors use the same
ordering and release semantics.

Family predicates are convenience helpers, not complete compatibility declarations.
Verify how the installed gatherer classifies the actual derivative distribution.
For unfamiliar targets, fail with an explicit unsupported-platform message instead
of routing silently into the nearest package-manager family.

## Tool capabilities are more precise than platform slogans

**Practice:** when a backend needs `stat -c`, a shell, `cat`, or remote Perl, test
that requirement on the target image. A command named `stat` can have incompatible
options. A container may lack systemd despite sharing its host's kernel. An embedded
image may expose a subset of BusyBox applets. Do not label an entire platform
supported based on a single successful `uname`.

Cache expensive facts within a coherent run, but invalidate facts that can change
after installing packages, rebooting, changing hostname, or reconfiguring networking.
Document whether a resumed operation starts a new fact snapshot. Limit broad fact
dumps because addresses, usernames, mount points, and hardware IDs may be sensitive.

## Evidence and scope

- [Rex::Commands::Gather (release documentation)](https://metacpan.org/pod/Rex::Commands::Gather)
- [lib/Rex/GPU.pm](https://github.com/Getty/rex-gpu/blob/bded1977b558c2fb6a46ae09ad2379acc5287775/lib/Rex/GPU.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
