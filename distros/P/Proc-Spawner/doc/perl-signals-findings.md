# Perl's signal and child-process model: what we found (for fixing at Perl's level)

**The one place for these findings.** The user asked on 2026-11-01 that everything we learn about deficiencies of Perl's signal model be collected here, so that it can eventually be fixed in Perl itself. Add new findings here, with their evidence; other docs should point here instead of repeating them.

Updated 2026-11-01. Tested on Perl 5.38.2 (Debian/Ubuntu build, threaded), glibc 2.39, Linux 6.18. The probe scripts are in `claude/perl-signals-probes.tar.gz-base64.txt`.

Words used:
- A **handler** is the Perl sub given for a signal, in `%SIG` or through `POSIX::sigaction`.
- **Deferred** ("safe") delivery: when the signal arrives, Perl's own C handler only notes it, and Perl runs the Perl handler later, at a point between two Perl operations where its state is consistent. This is what `%SIG` gives.
- **Immediate** ("unsafe") delivery: Perl runs the Perl handler inside the C signal handler, in the middle of whatever Perl was doing.
- A **lost wake-up**: the program is about to wait (in `select`, `sleep`, …) for something that has in fact already happened, so it waits too long, possibly forever.

Each finding says what happens, how we know (tested here, or reasoned), what it costs us, and what Perl could change. **❰BUG❱** marks a defect.

## 1. Delivering signals to Perl code

**S1. `POSIX::sigaction` installs immediate handlers by default, `%SIG` deferred ones.**
- Source: `POSIX.pm` creates every `POSIX::SigAction` with `SAFE => 0`. The documentation only says that to handle a signal safely one sets the "safe" flag (`$action->safe(1)`), and points to perlipc.
- Tested (`when.pl`): a child ended 0.2 s into a 3.9-second `sort`. The immediate handler ran at 0.21 s, inside the sort; the deferred one ran when the sort ended.
- Perl could: make deferred the default, or at least warn in the `sigaction` entry that the default is the dangerous kind.

**S2. ❰BUG❱ (in our executor, caused by S1) An immediate handler corrupts Perl's heap.**
- Tested (`stress.pl`): children end continuously, while the main program allocates and frees memory. The handler only writes one byte to a pipe and counts.
  - Immediate: 4 runs out of 4 aborted after a few seconds. glibc reported "malloc(): unaligned fastbin chunk detected", or a failed assertion in `sysmalloc`. Exit status 134 (SIGABRT).
  - Deferred: 4 runs out of 4 finished normally, each after about 24,000 children.
- Consequence: the executor `ShellSpawn` installed exactly such a handler (`POSIX::sigaction` without `safe`) while its loop ran. Tested (`exec-stress.pl`, the executor running loops of short pipelines for 20 s): it died with a segmentation fault in 4 runs out of 4. Its known issue X8 (a stray "Undefined value assigned to typeglob" once, at the line that restores the old SIGCHLD action) is very likely this. Recorded as X14 in `claude/pspawn-known-issues.md`. Interim fix (B1 on the page "Child Exit Wake-up", applied 2026-11-01): a deferred handler, with a 50 ms timeout on `select` against S3; then 4 runs out of 4 finished normally, and the dash comparisons and speed did not change.

**S3. A deferred handler that becomes due just before a blocking call runs only after that call returns: a lost wake-up.**
- Perl checks for pending signals only at certain points between operations. A signal that arrives after the last check, but before the system call (`select`, `sleep`, `read`, …) starts waiting, does not interrupt that call: the kernel delivered it already, to Perl's C handler, which only took a note.
- Tested (`window2.pl`): the parent sorts two million numbers while evaluating the arguments of `select`, and a child ends during the sort. The handler writes a byte to a pipe that `select` waits on.
  - Deferred: `select` woke up only at its 3-second timeout. Without a timeout it would have waited forever.
  - Immediate: `select` returned at once.
- So in Perl, the standard "self-pipe" technique (the handler writes to a pipe the main loop watches) has no lost wake-up only with an immediate handler, which is unsafe (S2). With a deferred handler, a wake-up can come late by up to the wait's timeout, and never without one.
- C programs avoid this with `pselect`/`ppoll` (block the signal, then atomically unblock it and wait), or by writing the byte from a C handler. Perl offers neither: `select` and `sleep` are plain calls, and a Perl handler cannot be a C function. (`POSIX::sigsuspend` is atomic, but waits for signals only, not for file descriptors.)
- Perl could:
  - (a) offer a built-in "signal to file descriptor" mode: `$SIG{CHLD} = \*FH` (or a `POSIX` function) makes Perl's C handler write a byte to that handle, safely, in addition to queuing the Perl handler. Prototyped in our binding (`PosixSpawn::chld_to_fd`, a C handler that only calls `write(2)`): no lost wake-up (`select` returned as soon as the sort of the S3 test ended, with a 30 s timeout), no crash under the S2 stress, and no measurable cost (`rate.pl`: about 1,900–1,980 children per second with no handler, a deferred Perl handler, or the C handler);
  - (b) or make its own blocking calls atomic with respect to pending deferred signals (check, then block with `pselect`/`ppoll` and the signal mask), so a signal noted just before the call still interrupts it.

**S4. `kill` to the program's own pid runs pending deferred handlers at once.**
- Tested (`facts.pl`, item 5): after `kill 'USR1', $$`, the handler has already run within the same expression.
- Consequence: tests that signal themselves cannot show S3; our first test of S3 showed nothing for this reason. A signal from another process is needed.

**S5. `%SIG` installs handlers without `SA_RESTART`.**
- Tested (`facts.pl`, item 1): the flags of a `%SIG` handler, read back with `POSIX::sigaction`, lack `SA_RESTART`. Earlier test (page "Run Graph API", item L5): under such a SIGCHLD handler, a `sysread` on a pipe failed with "Interrupted system call" when an unrelated child ended.
- Not every call is hit: buffered PerlIO reads retry after running the handler (tested, `checks2.pl`: `readline` on a pipe got its line), and so do `wait` and `waitpid`. `sysread`, `syswrite`, `accept` and the like fail with EINTR.
- Consequence: a library that sets a SIGCHLD handler through `%SIG` makes the program's `sysread` and the like fail whenever a child ends. With `POSIX::sigaction`, the library can combine `SA_RESTART` with `safe(1)`; then the deferred handler waits until the restarted call returns. That is presumably why `%SIG` omits `SA_RESTART`: Perl could not run deferred handlers during a restarted call, since it never sees the restart.
- Perl could: let `%SIG` take flags, for code that prefers restarted calls to prompt handlers.

**S6. `sleep` and `select` return early whenever a handled signal arrives, even with `SA_RESTART`.**
- On Linux (signal(7)), the kernel never restarts these calls. Tested (`facts.pl`, item 2): `sleep 2` returned after 0.2 s when a child ended under an `SA_RESTART` handler.
- Consequence: any SIGCHLD handler that a spawning library keeps installed outside its own loop (item L5 on "Run Graph API") shortens the caller's `sleep` and `select`.
- Perl could: provide resumable forms (sleep until a deadline), or document this next to `sleep` and `select`.

**S7. A deferred handler can run between the kernel's reaping of a child and the moment Perl code stores that status.**
- Tested in the chat "Overriding waitpid in Perl" (2026-10-30): a pure-Perl `waitpid` wrapper was interrupted there by a handler that died; the status was lost, and a second `waitpid` returned -1.
- Consequence: any Perl-level bookkeeping of statuses must block signals around the reap, or tolerate the loss.

## 2. Children's exit statuses

**C1. `$SIG{CHLD} = 'IGNORE'` discards the statuses of all children of the process.**
- Tested (`facts.pl`, item 4): `waitpid` returned -1 ("No child processes"), and `system` returned -1. `SA_NOCLDWAIT` has the same effect (reasoned).
- The setting is process-wide and is the one in force when a child ends. A library cannot keep its own children's statuses while the caller ignores SIGCHLD, except by taking over the handler (item L5 on "Run Graph API", with the costs of S5 and S6) or by an intermediate watchman process per child.
- A pidfd does not help: under `IGNORE`, the pidfd of a child from `pidfd_spawn` became readable, but `waitpid` then gave -1, "No child processes" (tested, `checks2.pl`).
- Perl could: offer per-child status retention (see C2).

**C2. There is no reliable way to stop other code from reaping our children.**
- Tested in the chat "Overriding waitpid in Perl" (2026-10-30):
  - A `CORE::GLOBAL::waitpid` override misses code compiled before it, `CORE::waitpid`, `&CORE::waitpid`, `POSIX::waitpid` (POSIX.pm calls `CORE::waitpid`), `wait`, and the waits inside `system`, backticks and `close` of a piped open.
  - Wrapping the op checker of `waitpid` catches more, but still misses code compiled earlier and the internal waits.
  - Only interposing the C library's `waitpid` (LD_PRELOAD or patching the GOT) catches every Perl path. Even that misses `syscall(&SYS_wait4, …)` and glibc's own `system(3)` and `popen(3)`.
  - Two threads, one in `waitpid($pid, 0)` and one in `waitpid(-1, 0)`: whichever is in the kernel first gets the child; the other gets ECHILD (tested).
- Perl already has the mechanism, internally and only on builds without `waitpid` (and on OS/2): `PL_pidstatus` keeps statuses that a wait took for someone else.
- Perl could: offer a "claim this pid" facility. Waits that do not name a claimed pid would leave it alone (they could use `waitid` with `WNOWAIT` to look before reaping, tested to work through `syscall`); statuses taken anyway would be kept for the claimer.

**C3. ❰BUG❱ in Perl: assigning to `${^CHILD_ERROR_NATIVE}` sets `$^C` instead.**
- Tested (`facts.pl`, item 3; `checks2.pl`): after `${^CHILD_ERROR_NATIVE} = 7`, `$^C` (the flag of `perl -c`, "compile only") is 1, and `${^CHILD_ERROR_NATIVE}` still reads 0. No error or warning, also under `use strict` and `-w`. Assigning 0 sets `$^C` back to 0.
- Cause, in blead's `mg.c` (checked 2026-11-01): `Perl_magic_get` tells `$^C` and `${^CHILD_ERROR_NATIVE}` apart (`case '\003'` compares the rest of the name), but `Perl_magic_set` does not: its `case '\003'` sets `PL_minus_c` for every name starting with `^C`.
- perlvar (blead) does not say whether the variable can be assigned.
- Expected: the assignment either works (as for `$?`) or dies with "Modification of a read-only value attempted". It must not change `$^C`.
- Consequence for us: a Perl-level `waitpid` replacement cannot make `${^CHILD_ERROR_NATIVE}` agree with `$?`, and trying silently changes `$^C`.

**C4. `waitpid` sets `$?` to -1 also when `WNOHANG` finds nothing.**
- Tested: `waitpid($pid, WNOHANG)` on a running child returns 0 and sets `$?` to -1 (as does a wait on a pid that is no child). A status kept in `$?` from before is lost.
- Perl could: leave `$?` alone when nothing was reaped; at least document it.

## 3. What children inherit

**I1. SIGFPE: Perl ignores it for itself, and restores the original setting only in its own `exec`.**
- Perl ignores SIGFPE at startup (`PERL_FPU_INIT`) and puts back the setting it found then only in its own ways of starting programs (`exec`, and the child side of `system`, backticks and piped `open`) (`PERL_FPU_PRE_EXEC`, the global `PL_sigfpe_saved`). Children started any other way (posix_spawn, XS code) get SIGFPE ignored.
- Tested: every child of the executor had SIGFPE ignored, until we read `PL_sigfpe_saved` from XS (`PosixSpawn::fpe_at_exec()`; fixed issue E1 in `claude/pspawn-known-issues.md`).
- Perl could: expose that saved setting (for example in `POSIX`), so that other ways of starting programs can do the same without XS.

**I2. Signals the Perl program ignores are ignored in its children too.**
- This is Unix semantics, not Perl's choice, but it matters: with `$SIG{PIPE} = 'IGNORE'` in the program, `system 'yes | head -1'` prints the extra message "yes: standard output: Broken pipe" (tested), where sh shows nothing; a program that ignores its write errors would loop forever. Our executor resets such signals in the child (posix_spawn's `sigdefault`), except those already ignored when it was loaded (as sh keeps signals ignored at its own start).
- Perl could: offer the same reset for `system` and `exec`, as an option.

**I3. For reference (documented, followed by us): `system` ignores SIGINT and SIGQUIT in the parent while it waits.**

## 4. Where these came from

- This session's tests: `when.pl` (S1), `stress.pl` (S2), `window2.pl` (S3), `facts.pl` (S4, S5, S6, C1, C3), `checks2.pl` (S5, C1, and `select` on fd 1100, which works), `exec-stress.pl` (S2 in the executor), `chandler.pl` and `rate.pl` (the C handler of S3 (a)), `pidfd.pl` (a pidfd from `pidfd_spawn` becomes readable when the child exits: `select` returned after 0.30 s for `sleep 0.3`, with no signal handler).
- The chat "Overriding waitpid in Perl" (2026-10-30) and its page "unwaitpid Design" (https://claude.ai/artifact/BsyqPKCyFpYSCH2aiZvFHw): C2, C3, S7, and the `waitid`/`WNOWAIT` technique. Its planned docs (`claude/unwaitpid-investigation.md`, `claude/unwaitpid-upstream-reports.md`) were never written; their Perl findings are here now.
- The page "Run Graph API" (https://claude.ai/artifact/NGmE3geAjdC6bfTaGn3Kv3), items R4, R11, L4, L5, L6: S5, S6, C1, C2.
- `claude/pspawn-run-shortcomings.md` (in Proc-Spawner 0.03), section 3, and `claude/pspawn-design.md`, sections 2 and 9: I1, I2, C1.

## 5. Candidates for reports to Perl (perlbug), none filed yet

1. C3: assigning to `${^CHILD_ERROR_NATIVE}` sets `$^C` (confirmed in blead's `mg.c`).
2. S1: document prominently that `POSIX::sigaction` handlers are immediate unless `safe(1)`; S2 shows the consequence.
3. S3: no way to wait for a deferred signal without a lost wake-up; ask for a signal-to-fd mode or for atomic waits.
4. C2: a "claim this pid" facility, generalizing `PL_pidstatus`.
5. I1: expose `PL_sigfpe_saved`.
6. C4 and S5, S6: documentation, or options.
