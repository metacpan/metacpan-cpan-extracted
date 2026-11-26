# Net::LibSSH

XS Perl binding for libssh — SSH library without SFTP dependency.

## What It Is

Net::LibSSH wraps the C libssh library (NOT libssh2). It exposes exec channels,
not a file transfer API — there is no put/get here. Key difference from
Net::SSH2: file operations are built on top of those exec channels, not on
SFTP. The SFTP support is optional and returns `undef` gracefully when the
subsystem is absent — that is what `Rex::LibSSH` uses downstream to detect
SFTP availability.

## Module Structure

- `Net::LibSSH` — session: connect, auth, channel(), sftp()
- `Net::LibSSH::Channel` — exec, read, write, send_eof, exit_status, close
- `Net::LibSSH::SFTP` — stat() (optional, undef if no SFTP subsystem)

All implementation lives in `LibSSH.xs`; the three `.pm` files hold `$VERSION`,
`XSLoader::load` and POD.

## Usage

```perl
use Net::LibSSH;

my $ssh = Net::LibSSH->new;
$ssh->option(host => 'server.example.com');
$ssh->option(user => 'root');
$ssh->connect or die $ssh->error;
$ssh->auth_agent or die $ssh->error;

my $ch = $ssh->channel;
$ch->exec('uname -r');
print $ch->read;
print "exit: ", $ch->exit_status, "\n";   # before close() — close() NULLs the channel
$ch->close;
```

## Build

This is an XS module — requires a C compiler and libssh headers, supplied by
`Alien::libssh`. Dist::Zilla is the only build path (`[@Author::GETTY]` with
`xs_alien = Alien::libssh`, `xs_object = LibSSH`):

```bash
dzil build
dzil test
```

There is deliberately no `Makefile.PL` in the working directory. A hand-written
one resolving flags via `pkg-config` used to live here; it linked against a
different libssh than the release does, so a green local `make test` said
nothing about the released build. Don't reintroduce it — build configuration
belongs in `dist.ini`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — the delegation lock is a shared house rule (skilletor bundle
`getty-cpan-dist@getty`); lanes and hazards are in `.claude/rules/net-libssh-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `net-libssh-worker` (default) |
| Write/extend tests | `net-libssh-test-writer` |
| Write/maintain POD | `net-libssh-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `net-libssh-release-manager` |

The agents carry their skills via `skills:` (see `.claude/agents/`); the
main agent delegates rather than loading them. Skill sources live under
`.claude/skills/`. The XS knowledge is split in two: `perl-xs` holds the general
Perl/C boundary rules (magic-based objects and their free hooks, typemap syntax
and its escaping trap, refcounting, `ppport.h`, testing for crashes and leaks),
while `net-libssh-core` holds what is specific to this distribution — the three
object types, the generation counter that makes `disconnect()` survivable, and
the API contracts `Rex::LibSSH` depends on. `perl-xs`, `getty-perl-core`,
`getty-perl-release-author-getty` and the `kanban-issues-karr-*` skills are installed by
skilletor; `net-libssh-core` and `net-libssh-hazards` are owned here.
