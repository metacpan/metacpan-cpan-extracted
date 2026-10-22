---
name: rex-libssh-channel
description: "The Net::LibSSH channel API this Rex backend uses, and the four traps of that API: read(undef) reads nothing, exit_status before EOF, sequential stdout/stderr, no fork and no thread safety."
---

# Rex::LibSSH — Net::LibSSH-Kanal

Die Net::LibSSH-Oberfläche, die dieses Backend benutzt, und die Fallen, die sie birgt.
Die Modul-Verträge (`Connection`, `Exec`, `Fs`, `File`) stehen in `rex-libssh-core`.

## Net::LibSSH — the surface this backend uses

`Net::LibSSH` 0.002, XS over libssh (not libssh2 — that is `Net::SSH2`).

```perl
my $ssh = Net::LibSSH->new;
$ssh->option( host => $h, port => $p, user => $u, timeout => $t );
$ssh->option( strict_hostkeycheck => 0 );
$ssh->connect       or die $ssh->error;   # 1 / 0
$ssh->auth_publickey($privkey) || $ssh->auth_agent || $ssh->auth_password($pw);

my $ch = $ssh->channel;          # one channel = one command, for its whole lifetime
$ch->exec($cmd);                 # exactly once per channel
my $out = $ch->read;             # slurp stdout to EOF
my $err = $ch->read( -1, 1 );    # slurp stderr
$ch->write($data); $ch->send_eof;  # stdin, for `cat > file`
my $rc = $ch->exit_status;       # AFTER reading; -1 until the remote process exits
$ch->close;
```

## Vier Fallen in dieser API

1. **`read(undef)` reads nothing.** undef numifies to 0 and the call returns an empty
   string. Pass `-1` or no argument to slurp. A `$len` threaded through from a caller
   that may be undef silently yields empty files.
2. **`exit_status` before EOF returns `-1`.** Read all output first, then ask. `-1`
   shifted into `$?` looks like a wildly wrong exit code rather than "not finished".
3. **stdout then stderr, sequentially, is safe** — libssh pumps all protocol messages
   (including stderr window adjustments) while blocking in the stdout read, so this does
   not deadlock the way a naive select loop over two pipes would. Don't "fix" it into
   interleaved reads.
4. **Not thread-safe, no fork support — one connection per process.** Rex's
   `parallelism` forks per host. Each child must build its own session; a session
   inherited across a fork is a use-after-free in C, not a Perl error.
