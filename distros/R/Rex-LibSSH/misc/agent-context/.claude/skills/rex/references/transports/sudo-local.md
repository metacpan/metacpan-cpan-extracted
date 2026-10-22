# Privilege contexts and local execution

## Privilege is part of the operation contract

Rex supports global sudo, individual sudo commands, and sudo code blocks. Its
documented sudo support requires Perl on the remote system. Authentication for SSH
and authorization for sudo are separate. A login success does not establish that a
package install or privileged file replacement will work.

Under sudo, the connection's effective type can resolve to `Sudo`, changing the
Exec/Fs/File implementation. Therefore the raw transport name alone is insufficient
for status decoding and capability diagnosis. Check the factory-selected class
inside the exact block that fails. Do not hardcode an underlying driver to bypass
sudo dispatch unless that behavior is intentional and covered by tests.

## Scope changes narrowly

**Practice:** authenticate as an approved non-root account and escalate only the
smallest operation that requires it, subject to site policy. Do not embed a password
in the Rexfile or pass it through CLI arguments. Do not request a weaker sudoers
policy solely to make a task succeed. Test noninteractive sudo with the actual
account and allowed commands; do not assume a TTY or password prompt is available.

Keep the application plan separate from execution. Validate the target path, owner,
service, and parameters before entering the privileged block. On exceptions, verify
that later operations return to the intended privilege state. Nested dynamic
contexts are not a substitute for an explicit cleanup and error policy.

## Local operations require equivalent care

A local task can modify the controller with the controller's privileges. This
includes a developer laptop, CI worker, or central automation host. A task that
should never run locally should check `Rex::is_local()` inside its body; the CLI
can override locality. A local lab example should instead require local context and
use a newly created private temporary directory.

For local build artifacts, use ordinary Perl functions in a clearly named local
stage. For remote writes, use the intended Rex interface. Avoid a mix such as local
`open('/etc/config')` followed by remote `service` under the assumption that both
refer to the same machine. Unit tests should explicitly distinguish these effects.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Connection/OpenSSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Connection/OpenSSH.pm)
- [lib/Rex/Interface/Fs.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Fs.pm)
- [lib/Rex/Interface/Connection/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Connection/LibSSH.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
