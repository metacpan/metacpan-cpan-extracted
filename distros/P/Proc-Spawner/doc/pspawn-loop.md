# The event loop: `Proc::Spawner::Loop` (W5, post-0.10)

`Proc::Spawner::Loop` is the one event loop of a process. It runs queued calls and timers, reads and writes fds
without blocking Perl, and reports ended children, with the same interface on POSIX and on Windows. The interface is
in the module's POD ([`lib/Proc/Spawner/Loop.pm`](../lib/Proc/Spawner/Loop.pm)); this page says how the loop works
and what was checked.

It was made by decision W5: the user, 2026-11-08 ("Use the Windows' way"), and 2026-11-09 ("in a separate module,
with an \"elegant\" API which may be shared between your POSIX approach and Win32"; "Can a handler for Ctrl-C report
to the loop instead?").

## <a id="my-section-1"></a>1. The interface, in short

```perl
my $loop = Proc::Spawner::Loop->new;                       # always the same object
my $w = $loop->read($fh, 65536, sub { my ($bytes, $errno) = @_ });   # $bytes undef at end of file
$loop->write($fh, $bytes, sub { my $errno = shift });     # all written, or the error (EPIPE: the rest dropped)
$loop->child($pid, sub { my $status = shift });           # as $?; undef if other code took it
$loop->after(2.5, sub { ... });                           # a timer
$loop->defer(sub { ... }, @args);
$w->cancel; $w->active;                                   # $w: what read, write, child and after return
$loop->wait_until(sub { $done }); $loop->poll;
my ($r, $wr) = $loop->pipe(overlapped => 'r');            # Windows: those ends overlapped
```

`Proc::Spawner`'s `on_read`, `on_write`, `defer`, `wait_until` and `poll` are the same calls under their old names.

The loop keeps the rules decided on the page "Child Exit Wake-up" (listed in
[`pspawn-spawner.md`](pspawn-spawner.md#my-section-1), section 1):

- **R1.** Every callback runs from the queue, one at a time: never inside a signal handler, never inside another
  callback.
- **D2.** A callback never waits.
- **D3.** The loop changes process-wide state (the SIGCHLD action on POSIX, a console control handler on Windows) only
  while `wait_until` runs.

## <a id="my-section-2"></a>2. How it works

The front end ([`Loop.pm`](../lib/Proc/Spawner/Loop.pm)) keeps the queue, the timers and the watches. A backend, one
per platform, does the waiting.

### <a id="my-posix"></a>POSIX

[`Loop/POSIX.pm`](../lib/Proc/Spawner/Loop/POSIX.pm) waits in `select` on the fds. While `wait_until` runs, a C handler
for SIGCHLD writes one byte into a pipe that the loop also selects on (D1: the handler is written in C, [`pspawn-extensions.md`](pspawn-extensions.md)). When that pipe is readable, the loop calls
`waitpid(PID, WNOHANG)` for each child it watches. This is the loop as it was before W5, moved into its own module.

### <a id="my-windows"></a>Windows

[`Loop/Win32.pm`](../lib/Proc/Spawner/Loop/Win32.pm), written in C in [`win_loop.h`](../win_loop.h), waits on one I/O
completion port, which receives every event.

- **Reads and writes.** On a handle opened for overlapped I/O, the read or write is issued as overlapped I/O
  (`NtQueryInformationFile` tells which handles are). On a synchronous handle (Perl's own pipes, an end shared with
  children, a console), a helper thread does the read or write and posts its result to the port.
- **Children.** `RegisterWaitForSingleObject` on a child's process handle posts the child's end to the port, so there
  is no limit of 64 handles. The child's status then comes from `waitpid`.
- **Signals.** The wait has no time limit of its own. While `wait_until` runs, the loop installs a console control
  handler, which posts Ctrl-C, Ctrl-Break, console close and shutdown to the port. Windows calls the newest handler
  first, so the loop's handler runs before Perl's own handler has marked the signal pending. The wait therefore gives
  Perl's handler time to do so: it returns as soon as the signal is pending, or after 200 ms at most, and Perl runs the `%SIG` handler at once.
  - With `%SIG{INT}` at its default, the process still ends (Perl's handler does that).
  - With `IGNORE`, the loop goes on undisturbed.
  - `$Proc::Spawner::Loop::Win32::CTRL = 0` leaves the loop's handler out.
- **`alarm`.** Perl's `alarm` is a timer message that only Perl's own message check reads. So while an alarm is set,
  the loop waits in slices of 50 ms, each followed by that check.
- **Overlapped pipes.** `$loop->pipe(overlapped => ...)` makes a named pipe of its own, with the ends that
  `overlapped` names (`'r'`, `'w'` or `'rw'`) opened for overlapped I/O. Give such an end to no child: a child does
  synchronous I/O on it.

## <a id="my-section-3"></a>3. What was checked

| Where | What | Result |
|---|---|---|
| Linux | the whole suite, as built, and again in each of these: without posix_spawn; through Run, the user's module that starts programs where there is neither posix_spawn nor fork (also with `RUN_AS_WIN32=1`); with `/proc` hidden | pass |
| Linux | the snippet library (the corpus snippets the large parser accepts), run by `Proc::ShellSpawn` alone and compared with the table of section 7 of [`large-subset-state.md`](large-subset/large-subset-state.md#my-section-7) | no change from W5 |
| Wine | the snippet library | could not run on 2026-11-09, before the shell layer was ported to Windows ([`pspawn-spawner.md`](pspawn-spawner.md#my-section-8), section 8; ported later that day: [`pspawn-shell-windows.md`](pspawn-shell-windows.md)); it ran there on 2026-11-18/19 (the code of post-0.12), through both primitives, against the run on Linux of 2026-11-17: ["The large subset under Wine" in `pspawn-shell-windows.md`](pspawn-shell-windows.md#my-the-large-subset-under-wine); the parser alone over all 45,501 extracted samples gives the same trees as on Linux |
| Wine, Strawberry Perl 5.38.2 | [`t/loop.t`](../t/loop.t): every pipe kind with 300,000 bytes each way, EPIPE, cancelled reads on both kinds of handle, timers, 80 children at once, a child writing into a pipe the loop reads | 17 pass, through both primitives (`win_spawn.h`'s posix_spawn, and `system1`: 60 children, since Perl's own table stops at 64) |
| Wine, with a console | Ctrl-C sent 0.5 s into a wait that nothing else could end before 3.5 s | the `%SIG{INT}` handler ran at 0.54 s; without the loop's console handler, only at the next event, 3.54 s |
| Wine | `alarm 1` during a wait | the `%SIG{ALRM}` handler ran at 1.02 s |
| Wine, with a console | `%SIG{INT}` at its default; `IGNORE` | the process ends with Perl's "Terminating on signal SIGINT(2)"; the loop goes on |
| Wine | [`t/loop.t`](../t/loop.t)'s Ctrl-C test | passes with a console (then `t/loop.t` gives 18 of 18); skipped without one (the 17 above) |
| Wine | `perl Makefile.PL`, `gmake`, `gmake test` of [`t/loop.t`](../t/loop.t), [`t/windows.t`](../t/windows.t), [`t/parsers.t`](../t/parsers.t), [`t/programs.t`](../t/programs.t) with Strawberry Perl's own gcc | pass, no warning |

Wine has a console only on a terminal. So these runs used a pseudo-terminal (`script`), and ran Perl directly rather
than through `cmd.exe`, since `cmd.exe` gets the Ctrl-C too and ends (the tricks repository's Wine topic has the
details).

**Not checked:** real Windows. Wine calls console handlers as Windows documents it (each event on a thread of its own,
the newest handler first), but only Wine's behaviour was tested.

## <a id="my-section-4"></a>4. Known limits

- A read on a synchronous handle can stay blocked until data or end of file arrives, if it is cancelled just as its
  helper thread enters `ReadFile` (between the thread's check of the cancel flag and the call).
- Ctrl-C (and the other console events above) is the only signal that wakes the wait at once on Windows (an `alarm` is seen within 50 ms, by the slices above):
  - another process's `kill` of a signal other than INT or BREAK is `TerminateProcess` there, which needs no loop;
  - Perl's pseudo-processes (its fork emulation, which these modules do not use) post thread messages instead, and
    the wait does not see them until an alarm is set.
