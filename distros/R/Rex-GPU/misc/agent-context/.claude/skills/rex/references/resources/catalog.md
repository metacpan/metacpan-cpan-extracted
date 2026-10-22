# Resource routing and the bounds of this skill

## Discover APIs without guessing them

The core imports and command catalog expose more than run/file/pkg/service. This
skill deliberately provides deeper operational guidance for the common paths and
routes less frequently used capabilities to their authoritative module documentation.
Availability does not imply compatibility with the selected target or backend.

| Need | Starting module or subsystem | What to establish before using it |
|---|---|---|
| Low-level metadata/directories | Rex::Commands::Fs | Backend, path semantics, missing vs denied access |
| File content/templates | Rex::Commands::File | Ownership, encoding, staging, change callbacks |
| Transfer | Rex::Commands::Upload / Download / Sync | Which machine is source, protocol, external tools, integrity |
| Processes and log following | Rex::Commands::Process / Tail | Matching scope, bounded output, stop/timeout semantics |
| OS facts | Rex::Commands::Gather | Actual target, cache freshness, gatherer/tool requirements |
| Users and jobs | Rex::Commands::User / Cron | Provider API, privilege, secret handling, replacement rules |
| Kernel and tunables | Rex::Commands::Kernel / Sysctl | Runtime vs persistent state, reboot and recovery |
| Host records | Rex::Commands::Host | Name ownership, remote file access, identity dependencies |
| Firewall | Rex::Resource::firewall | Provider, rule ownership, persistence, retained management access |
| Reporting and hooks | Rex::Report / Rex::Hook | Observed event semantics, secret filtering, skipped hooks |
| Virtualization and test harnesses | Installed virtualization modules / Rex::Test::Base | Current provider support, disposable image, cleanup |

These names are routing targets, not statements that every subsystem was
implementation-audited during this build. See the exact coverage in the source map.
Do not claim universal Windows, BSD, network-device, cloud, or virtualization support
from the existence of an interface name. Source and installed POD decide the API;
a disposable contract test decides whether your operation works in its environment.

**Practice:** when adding a specialized operation, document its required modules,
minimum verified versions, target tools, side effects, error semantics, and test
matrix in the project's adapter reference. Keep domain-specific rules outside the
generic Rex entrypoint. A module that wraps a tool is not a replacement for that
tool's installation, credentials, compatibility policy, or operational expertise.

## Evidence and scope

- [lib/Rex.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex.pm)
- [Rex::Commands (release documentation)](https://metacpan.org/pod/Rex::Commands)
- [Rex::Test::Base (release documentation)](https://metacpan.org/pod/Rex::Test::Base)
