# Installation, releases, and feature bundles

## Four independent version axes

Record Rex's installed distribution version, Perl version, transport module versions,
and native libraries/client programs. The Rex feature bundle is a fifth, independent
behavior choice. `use Rex -feature => ['1.4']` does not install Rex 1.4 or pin CPAN.
The researched stable distribution is 1.16.1; inspected master contains a development
placeholder. Extension main branches contain post-release version increments.

Do not rewrite the bundle to the current release number just to make it look newer.
Preserve the application's established compatibility contract, review the activated
behaviors, and test before changing it. The inspected 1.4 bundle includes earlier
behaviors: task-call support, CMDB/template integration, changed `set` semantics,
filesystem autodie, no-tty operation, Template::NG, and task-chaining arguments.
It is not equivalent to enabling command `exec_autodie` for all `run` calls.

## Installation procedure

Use an isolated controller environment or the site's package policy. Pin the Rex
release and chosen optional modules; retain dependency resolution and the native
library versions in the project's lock/build record. Install only the backend you
intend to use and its dependencies. OpenSSH involves Net::OpenSSH and filesystem
support through Net::SFTP::Foreign; SSH involves Net::SSH2/libssh2; LibSSH involves
Rex::LibSSH and Net::LibSSH/libssh. These are distinct stacks.

Use the shipped inspector first. In a trusted installed environment, an actual
runtime check can then use `perl -MRex -e 'print "$Rex::VERSION\n"'` and `rex -v`.
Different shell PATHs, Perl interpreters, local::lib settings, and service accounts
may resolve different installations. Record the loaded `%INC` paths when debugging
shadowing, but do not execute an untrusted project to obtain them.

## Imports and upgrade controls

The feature import already exports common DSL modules. Extra `use Rex::Commands::*`
statements can document dependencies, but are not universally necessary. Rex::Exporter
uses option-style imports, not standard Exporter's function-name whitelist syntax.
Ordinary helper code can use normal Perl Exporter.

**Practice:** upgrade the controller, transport, and application extensions separately
in a disposable matrix. Preserve a working controller image for rollback. Recheck
status encoding, host-key rejection, file byte fidelity, notifications, and a second
apply; a successful import alone is not an operational upgrade test.

## Evidence and scope

- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [lib/Rex/Exporter.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Exporter.pm)
- [Rex (release documentation)](https://metacpan.org/pod/Rex)
- [Rex::LibSSH (release documentation)](https://metacpan.org/pod/Rex::LibSSH)
