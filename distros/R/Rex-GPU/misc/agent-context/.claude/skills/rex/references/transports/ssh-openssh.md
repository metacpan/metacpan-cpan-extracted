# SSH and OpenSSH backend distinctions

## Name the stack correctly

`SSH` refers to the Net::SSH2/libssh2 implementation. `OpenSSH` uses Net::OpenSSH
and the system SSH client. The inspected core import enables preference for
Net::OpenSSH when available, so "Net::SSH2 is always the default" is unreliable.
Inspect the selected connection rather than inferring it from installed packages.

OpenSSH passes configured OpenSSH options and supports its documented proxy path.
That does not prove another backend accepts the same settings. Capture the effective
configuration with secrets removed and compare it to a manual SSH invocation using
the same identity, hostname, port, host-key store, and proxy. A successful interactive
login may use a different agent, config file, environment, or privilege policy.

## Why exec succeeds but file operations fail

The OpenSSH connection code establishes authentication and then attempts SFTP
initialization inside `eval`. An SFTP initialization error can leave an otherwise
usable command connection. Filesystem methods such as `is_file` then call `stat` on
the returned SFTP object without first guaranteeing it exists. An undefined-object
error at that point is consistent with missing/failed SFTP initialization; it does
not, by itself, establish whether the cause is server configuration, client module
availability, permissions, a proxy, or a closed channel.

The SSH filesystem also depends on SFTP for common metadata calls, while some
operations invoke remote Perl or native commands. Its Unix transfer methods use
SCP in inspected code. Never extrapolate those details to a generic system `scp`
command, whose behavior belongs to the installed client version.

## Control connection diagnosis

**Practice:** inspect the actual Net::OpenSSH-owned control socket and its permissions.
Check that its parent is private and the process owner matches the controller user.
A manual `ssh -O exit host` with unrelated config may not address Rex's master.
When cleanup is authorized, identify the exact socket first and use `ssh -S` with
that socket for a check/exit. Do not kill all SSH processes or delete all sockets.

Prefer a minimal reproduction that runs a harmless command followed by a metadata
read on one approved host. Keep logs bounded and sanitized; backend debug output
can include command content and authentication-related options.

## Evidence and scope

- [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm)
- [lib/Rex/Interface/Fs/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/OpenSSH.pm)
- [lib/Rex/Interface/Fs/SSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs/SSH.pm)
- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
