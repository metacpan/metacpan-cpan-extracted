# The event loop: `Proc::Spawner::Loop` (W5, post-0.10)

One event loop per process, with one interface on POSIX and on Windows. The interface is in the module's POD
([`lib/Proc/Spawner/Loop.pm`](../lib/Proc/Spawner/Loop.pm)); this page says how it works and what was checked.
Decision W5: the user, 2026-11-08 ("Use the Windows' way"), 2026-11-09 ("in a separate module, with an \"elegant\" API
which may be shared between your POSIX approach and Win32"; "Can a handler for Ctrl-C report to the loop instead?").

## 1. The interface, in short

```perl
my $loop = Proc::Spawner::Loop->new;                       # always the same object
my $w = $loop->read($fh, 65536, sub { my ($bytes, $errno) = @_ });   # undef at end of file
$loop->write($fh, $bytes, sub { my $errno = shift });     # all written, or the error (EPIPE: the rest dropped)
$loop->child($pid, sub { my $status = shift });           # as $?; undef if other code took it
$loop->after(2.5, sub { ... });                           # a timer
$loop->defer(sub { ... }, @args);
$w->cancel; $w->active;
$loop->wait_until(sub { $done }); $loop->poll;
my ($r, $wr) = $loop->pipe(overlapped => 'r');            # Windows: those ends overlapped
```

`Proc::Spawner`'s `on_read`, `on_write`, `defer`, `wait_until` and `poll` are the same calls under their old names.
The rules are those of the page "Child Exit Wake-up" (in [`pspawn-spawner.md`](pspawn-spawner.md), section 1): every
callback runs from the queue, one at a time, never inside a signal or another callback (R1); a callback never waits
(D2); process-wide state (SIGCHLD, the console handler) is taken only while `wait_until` runs (D3).

## 2. How it works

The front end ([`Loop.pm`](../lib/Proc/Spawner/Loop.pm)) keeps the queue, the timers and the watches; a backend waits.

**POSIX** ([`Loop/POSIX.pm`](../lib/Proc/Spawner/Loop/POSIX.pm)): `select` on the fds; while `wait_until` runs, a C
handler for SIGCHLD writes one byte into a pipe the loop selects on (D1), then `waitpid(PID, WNOHANG)` for each child
watched. (This is the loop as it was before W5, moved.)

**Windows** ([`Loop/Win32.pm`](../lib/Proc/Spawner/Loop/Win32.pm), in C: [`win_loop.h`](../win_loop.h)): one I/O
completion port receives every event.

- A read or write on a handle opened for overlapped I/O is issued so (`NtQueryInformationFile` tells which handles
  are); one on a synchronous handle (Perl's own pipes, an end shared with children, a console) is done by a helper
  thread that posts its result to the port.
- A child's end is posted by `RegisterWaitForSingleObject` on its process handle (no limit of 64 handles); its status
  then comes from `waitpid`.
- **Signals.** The wait has no time limit of its own. While `wait_until` runs, a console control handler of ours
  posts Ctrl-C, Ctrl-Break, console close and shutdown to the port. Windows calls the newest handler first, so ours
  runs before Perl's own has marked the signal pending; the wait gives Perl's up to 200 ms to do so, then returns, and
  Perl runs the `%SIG` handler at once. `%SIG{INT}` at its default still ends the process (Perl's handler does that),
  `IGNORE` leaves the loop undisturbed. `$Proc::Spawner::Loop::Win32::CTRL = 0` leaves our handler out.
- **`alarm`.** Perl's is a timer message that only Perl's own message check reads: while an alarm is set, the wait
  goes in slices of 50 ms, each followed by that check.
- `$loop->pipe(overlapped => ...)` makes a named pipe of its own with those ends overlapped; give such an end to no
  child (a child does synchronous I/O on it).

## 3. What was checked

| Where | What | Result |
|---|---|---|
| Linux | the whole suite, also without posix_spawn, through Run (`RUN_AS_WIN32=1` too), with `/proc` hidden | pass |
| Linux | the snippet library, ours alone against the table of section 7 of [`large-subset-state.md`](large-subset/large-subset-state.md) | no change from W5 |
| Wine | the snippet library | could not run on 2026-11-09 before the shell layer's port ([`pspawn-spawner.md`](pspawn-spawner.md), section 8; ported later that day: [`pspawn-shell-windows.md`](pspawn-shell-windows.md)), and not run there since; the parser alone over all 45,501 extracted samples gives the same trees as on Linux |
| Wine, Strawberry Perl 5.38.2 | [`t/loop.t`](../t/loop.t): every pipe kind with 300,000 bytes each way, EPIPE, cancelled reads on both kinds of handle, timers, 80 children at once, a child writing into a pipe the loop reads | 17 pass, through both primitives (`system1`: 60 children, Perl's own table stops at 64) |
| Wine, with a console | Ctrl-C sent 0.5 s into a wait that nothing else could end before 3.5 s | `%SIG{INT}` handler ran at 0.54 s; without our handler only at the next event, 3.54 s |
| Wine | `alarm 1` during a wait | `%SIG{ALRM}` handler at 1.02 s |
| Wine, with a console | `%SIG{INT}` at its default; `IGNORE` | the process ends with Perl's "Terminating on signal SIGINT(2)"; the loop goes on |
| Wine | [`t/loop.t`](../t/loop.t)'s Ctrl-C test | 18 of 18 with a console; skipped without one |
| Wine | `perl Makefile.PL`, `gmake`, `gmake test` of `t/loop.t`, `t/windows.t`, `t/parsers.t`, `t/programs.t` with Strawberry Perl's own gcc | pass, no warning |

Wine has a console only on a terminal: these runs used a pseudo-terminal (`script`), and ran Perl directly, since
`cmd.exe` gets the Ctrl-C too and ends (the tricks repository's Wine topic has the details).

**Not checked:** real Windows. Wine calls console handlers as Windows documents (each event on a thread of its own,
the newest handler first), but only Wine was seen.

## 4. Known limits

- A read on a synchronous handle that is cancelled just as its helper thread enters `ReadFile` can stay blocked until
  data or end of file arrives (the window is between the thread's check of the flag and the call).
- Ctrl-C is the only wake-up for signals: another process's `kill` of a signal other than INT or BREAK on Windows is
  `TerminateProcess`, which needs no loop; Perl's pseudo-processes (fork emulation, unused here) post thread messages,
  which the wait does not see until an alarm is set.
