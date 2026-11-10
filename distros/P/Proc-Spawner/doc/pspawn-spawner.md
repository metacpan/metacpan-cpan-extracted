# Proc::Spawner and its graph: the split of the executor (2026-11-02)

**Status: EXPERIMENTAL.** The user endorsed every choice experimentally (2026-11-02, 00:24) and asked for this split (00:32: "Please start"). The decisions taken while writing it, G1–G6 in section 6, are experimental too and wait for approval.

Until 2026-11-01 one module, `ShellSpawn`, did everything: the shell, the starting of children, the event loop, and a graph that only recorded and drew what happened. Now there are three layers, and the graph is what gets executed:

| Module | Lines | What it does | Depends on |
|---|---|---|---|
| [`lib/Proc/Spawner.pm`](../lib/Proc/Spawner.pm) (+ [`Spawner.xs`](../Spawner.xs)) | 148 code lines (230 with its POD) | starts a child with a given fd table and any posix_spawn setting; runs the one event loop that reports "a child ended", "an fd is readable/writable"; its XS part is the former binding `PosixSpawn` | – |
| [`lib/Proc/Spawner/Loop.pm`](../lib/Proc/Spawner/Loop.pm) (+ [`Loop/POSIX.pm`](../lib/Proc/Spawner/Loop/POSIX.pm), [`Loop/Win32.pm`](../lib/Proc/Spawner/Loop/Win32.pm), [`win_loop.h`](../win_loop.h)) | post-0.10 | the one event loop (W5): queued calls, timers, reads, writes, ended children, one interface on POSIX (`select`, SIGCHLD) and on Windows (an I/O completion port); `Proc::Spawner`'s `on_read`, `on_write`, `defer`, `wait_until`, `poll` are its old names | `Proc::Spawner`'s XS |
| [`lib/Proc/Spawner/Graph.pm`](../lib/Proc/Spawner/Graph.pm) | 263 | the graph: open files (ends) with hold counts, process nodes, Perl's own reads and writes; each process carries what to do when it ends; the notation, pictures, running hand-written graphs | `Proc::Spawner` |
| [`lib/Proc/ShellSpawn.pm`](../lib/Proc/ShellSpawn.pm) (+ [`ShellSpawn/Large.pm`](../lib/Proc/ShellSpawn/Large.pm)) | 638 (+199) | only the shell: words, redirections, contexts, builtins, traps, jobs | both |

`lib/SpawnGraph.pm` is gone; its notation, drawing and runner are in `Proc::Spawner::Graph`.

**Renamed 2026-11-02, 07:30 (the user: "`PosixSpawn` should be subsumed by `Proc::Spawner`. The rest should be put into `Proc::`"; names option A).** One distribution, `Proc-Spawner`, built at the top of the bundle with `perl Makefile.PL && make`. Older docs use the old names:

| Old name | New name |
|---|---|
| `PosixSpawn` (XS binding, its own directory and Makefile.PL) | part of `Proc::Spawner`: [`Spawner.xs`](../Spawner.xs) at the top; the raw call `PosixSpawn::spawn` is now `Proc::Spawner::spawn`, an alias of the XSUB `__posix_spawn` (the user: the same interface should have a chance to work on POSIX and Windows, so no `posix_` in its name), with a sixth, optional argument `{ OPTION => 'drop' | 'fail' }`: what a port lacking an option (Windows) does with it, defaults in `%Proc::Spawner::UNSUPPORTED` (`'*' => 'fail'`, EXPERIMENTAL); the call with the fd table and `on_exit`, formerly `spawn`, is now `start`; `fpe_at_exec`, `chld_to_fd`, `chld_restore` are in `Proc::Spawner` |
| `ShellSpawn`, `ShellSpawn::Large` | `Proc::ShellSpawn`, `Proc::ShellSpawn::Large` ([`lib/Proc/`](../lib/Proc)) |
| `ShellSubset`, `ShellSubsetSmall`, `ShellSubsetLarge` (in `parser/`) | `Proc::ShellSubset`, `Proc::ShellSubset::Small`, `Proc::ShellSubset::Large` ([`lib/Proc/`](../lib/Proc)); the test scripts are in [`t/parser/`](../t/parser) (since 09:58) and find [`lib/`](../lib) themselves |

Include paths are now `lib` and `blib/arch`. The A4 message says "Proc::ShellSubset::Large: … is not supported" since 0.02 (it said "ShellSubsetLarge: …" before).

## 1. Proc::Spawner: the small one

Five functions; nothing about pipes, files or the shell.

| Call | Meaning |
|---|---|
| `start(PATH, ARGV, ENVP, FDS, %opt)` (was `spawn`) | starts a child; returns its pid, or undef with `$!`. `FDS = { CHILD_FD => PARENT_FD, or undef for "closed" }`; fds not listed are inherited as they are (if not close-on-exec). `FDS` values may also be `[PATH, FLAGS, MODE]`: opened in the child. Options (2026-11-02, the user: "more or less all the fields of `posix_spawn` should be supported"): `chdir`, `fchdir`, `sigdefault => [signals]`, `sigmask => [signals]`, `pgroup`, `setsid`, `tcsetpgrp`, `resetids`, `sched`, `cgroup`, `search`, `pidfd` (then in list context the pid and a pidfd), `umask`, `unsupported => HASH` (passed to `spawn`), `on_exit => CODE`. Signals by name or number; an unknown name dies. The full list is in the module's header comment. |
| `on_read(FD, N, CODE)` | one read of at most N bytes when FD is readable: `CODE->(BYTES)`, or `CODE->(undef)` at end of file |
| `on_write(FD, BYTES, CODE)` | writes BYTES as the reader takes them, never blocking Perl; `CODE->()` when done or the reader is gone |
| `defer(CODE, ARGS)` | queue `CODE->(ARGS)` |
| `wait_until(CODE)` | run the queue and wait for events until `CODE->()` is true |

Example: `ls` with its output in a pipe whose read end Perl reads, while `ls`'s fd 2 is closed:

```perl
pipe my $r, my $w;
my ($out, $st, $eof) = ('');
Proc::Spawner::spawn('/bin/ls', ['ls'], undef, { 1 => fileno $w, 2 => undef }, on_exit => sub { $st = shift });
close $w;
Proc::Spawner::on_read($r, 4096, sub { defined $_[0] ? ($out .= $_[0], Proc::Spawner::on_read($r, 4096, __SUB__)) : ($eof = 1) });
Proc::Spawner::wait_until(sub { $eof && defined $st });
```

The rules, as decided on the page "Child Exit Wake-up":

- **R1.** Every callback runs from the queue, one at a time: never inside a signal handler, never inside another callback. A child that ends while a callback runs is noticed, and its `on_exit` queued, only after that callback returns.
- **D2.** A callback never waits: `wait_until` called from inside one dies with "wait inside a reaction".
- **D1.** While `wait_until` runs, SIGCHLD has a C handler (from the binding) that writes one byte into a pipe; the loop `select`s on that pipe. No Perl code runs inside the signal, and no wake-up is lost. Without the C function (another binding), a deferred Perl handler is used, and `select` wakes every 50 ms.
- **D3.** SIGCHLD is ours only while `wait_until` runs; the previous handler is put back afterwards. (Since post-0.04, `Proc::ShellSpawn` installs a deferred SIGCHLD handler of its own between `run()` calls while background jobs remain, the user's choice B of question K3; it calls `Proc::Spawner::poll()`. `Proc::Spawner` itself still keeps D3.)

## 2. Proc::Spawner::Graph: the executable graph

The graph says, for the current moment, which of our children, and which of Perl's own reads and writes, use which open file. Each process node carries what to do when it ends.

- **Ends.** An end is an open file the parent keeps: a pipe half (`r`, `w`), a file, or one of the parent's own fds (`parent`). Whoever needs an end holds it (`hold`); the last `release` closes the parent's copy. Ends are close-on-exec, so a child gets exactly what its fd table gives it. Made by `$g->new_pipe`, `$g->file_end(FH, MODE, PATH)`, `$g->parent_end(N)`.
- **Processes.** `$g->start(PATH, ARGV, ENVP, MAP, on_exit => HANDLER, …)`, where `MAP = { CHILD_FD => end, or undef }`, starts the child and adds its node. The node records its edges (fd, how it is used, end), its pid and its state: running, `exited N`, `signal N`.
- **Perl's own reads and writes.** `$g->perl_read(END, N, HANDLER)` and `$g->perl_write(END, BYTES, HANDLER)` are nodes too (drawn as the process "Perl"), so the graph knows which ends the parent itself still uses, including ends the caller never sees.
- **Handlers.** A handler is a code ref, or `[NAME, DATA…]` with NAME a fully qualified sub name, its module loaded at first use (the user's choice for parse trees, 2026-11-01 16:08, carried over). When the process ends, `NAME->(GRAPH, NODE, WAIT_STATUS, DATA…)` runs from the queue. It may start new processes (each with its own handler), release ends, read and write; it never waits. So the graph grows and shrinks as it runs.
- **No reference cycles.** The graph holds its processes; a process holds its ends and its handler's data; ends point back only weakly (`peer`, `g`). Handlers get the graph as an argument, so their data never needs to hold it. A handler is dropped from its node once called. An ended process leaves the graph once it shares no end, or pipe, with a running process or with one of Perl's own reads and writes.

Example (from [`t/spawner.t`](../t/spawner.t)): `echo hello` writes into pipe 1. When it ends, its handler starts `cat` reading pipe 1 and writing pipe 2, which Perl reads.

```perl
my $g = Proc::Spawner::Graph->new;
my ($r, $w) = $g->new_pipe; my ($pr, $pw) = $g->new_pipe;
sub then_cat { my ($g, $node, $st, $r, $pw) = @_;
  $g->start('/bin/cat', ['cat'], undef, { 0 => $r, 1 => $pw });
  Proc::Spawner::Graph::release($_) for $r, $pw }
$g->start('/bin/sh', ['sh', '-c', 'echo hello'], undef, { 1 => $w }, on_exit => ['main::then_cat', $r, $pw]);
Proc::Spawner::Graph::release($w);
```

**Hand-written graphs** in the notation (`sgraph/*.sg`) now run on this engine. `after P1 fail` becomes a named handler on P1 (`Proc::Spawner::Graph::then`) that starts the processes waiting for P1, or marks them `never` and releases their ends. [`sgraph/run-graph.pl`](../t/sgraph/run-graph.pl) checks every process's fds with the reporter program: 17 of 17 processes as drawn (6 examples).

**Pictures.** `Proc::Spawner::Graph->new(dot => DIR)` writes the graph after every event (start, exit, close) as `DIR/trace-001.dot`, …; the executor does this with `TRACE=dot`.

## 3. How ShellSpawn uses them

- One graph for the whole program, `$ShellSpawn::G`, so a background job that outlives `run()` stays in it.
- A context's map (child fd → end) is the `MAP` given to `$G->start`. Contexts hold and release ends as before.
- Each child's node carries the shell's continuation: `on_exit => ['ShellSpawn::resume', K]`, and `resume` calls `K` with sh's `$?`.
- `$( … )`, `read` and here-documents are `perl_read` and `perl_write` nodes.
- What stays shell-specific is in `ShellSpawn::spawn`: the PATH search and its messages, the environment, which signals children get back as default, the ENOEXEC fallback to `/bin/sh`.

## 4. Behaviour changes

1. **Only our own children are reaped** (G2). The loop calls `waitpid(PID, WNOHANG)` for each child it started, instead of `waitpid(-1, …)`. So it no longer takes the statuses of the caller's own children (finding C2). If other code takes a status of ours first, the child is reported with status undef instead of being waited for forever; the shell gives `$?` = 1 for it (G3). On Windows other code cannot take it: the exit code stays with the process handle the module keeps until it has reported the child, so other code's `waitpid` and ours both get it (checked under Wine, post-0.10, `t/spawner.t`).
2. The trace says `reaped PID: wait status W` (the raw status) instead of sh's `$?`.
3. In pictures, an ended process shows `exited N` or `signal N`, and the Perl node also shows Perl's writes (here-documents), not only its reads.

Nothing else changed: on every battery the old and the new executor print the same output, messages and status for all 234 command lines (only pid lengths differ).

## 5. Tested

In 0.03 (2026-11-03), [`t/dash.t`](../t/dash.t) gives: [`largebattery.txt`](../t/batteries/largebattery.txt) 111 of 114 agree with dash, [`battery.txt`](../t/batteries/battery.txt) 42/43, [`fdbattery.txt`](../t/batteries/fdbattery.txt) 14/14, [`sigenv.txt`](../t/batteries/sigenv.txt) 12/12, [`t1.txt`](../t/batteries/t1.txt) 39/45, [`t2.txt`](../t/batteries/t2.txt) 42/44 (one line's order varies, as in dash), [`t3.txt`](../t/batteries/t3.txt) 16/17, [`pspawn-d2.txt`](../t/batteries/pspawn-d2.txt) 9/10, [`pspawn-l10.txt`](../t/batteries/pspawn-l10.txt) 6/9, [`large-subset-b13.txt`](../t/batteries/large-subset-b13.txt) 37/38; every other line is a known difference ([`t/dash-known.txt`](../t/dash-known.txt)). Post-0.03 adds [`large-subset-p6.txt`](../t/batteries/large-subset-p6.txt): 19 of 19 (21 of 21 in post2-0.03); the other batteries, run again on post-0.03, give the same counts as 0.03. In 0.04: [`largebattery.txt`](../t/batteries/largebattery.txt) 108 of 114 (three lines more now differ from dash on purpose: `getopts` leaves `OPTARG` unset, rule E), [`large-subset-p6.txt`](../t/batteries/large-subset-p6.txt) 25 of 25, and the new [`large-subset-e.txt`](../t/batteries/large-subset-e.txt) 2 of 10 (the other 8 are rule-E choices listed in [`t/dash-known.txt`](../t/dash-known.txt)); the rest as in 0.03. The counts below are pre-0.01 (2026-11-02).

- [`t/spawner.t`](../t/spawner.t): 20 tests (32 since 2026-11-02, 08:00: every posix_spawn setting, and the raw `spawn`) of `Proc::Spawner` and the graph: fd tables (including colliding fd numbers), closed fds, `chdir`, `umask`, ignored signals and `sigdefault`, exit and signal statuses, a 1 MB write by Perl without blocking, R1 (reactions never interleave), D2, "nothing left to wait for", a status taken by other code, a handler starting the next process. All pass, with the C handler and with the fallback.
- Against dash, as before the split: [`largebattery.txt`](../t/batteries/largebattery.txt) 99/103 (106/110 after the 7 lines added for L6–L8, see the known issues), [`battery.txt`](../t/batteries/battery.txt) 42/43, [`fdbattery.txt`](../t/batteries/fdbattery.txt) 14/14, [`sigenv.txt`](../t/batteries/sigenv.txt) 12/12, [`t1.txt`](../t/batteries/t1.txt) 39/45, [`t2.txt`](../t/batteries/t2.txt) 43/44, [`t3.txt`](../t/batteries/t3.txt) 16/17. The same numbers as before also with `PARSER=small` and `PARSER=base`.
- `hyg.pl`: parent fds unchanged, no zombies. `mem.pl` on four commands and [`sigprobe/mem-large.pl`](https://github.com/ilyaz-ai/Proc-Spawner/blob/project-2026-11-03/claude/pspawn-tree/sigprobe/mem-large.pl): RSS flat over 1,500 runs. After 6,500 runs the graph holds 1 process node. [`sigprobe/exec-stress.pl`](https://github.com/ilyaz-ai/Proc-Spawner/blob/project-2026-11-03/claude/pspawn-tree/sigprobe/exec-stress.pl): 9,750 children in 15 s, finished normally. `large-subset-difffuzz.pl`, seeds 7, 11, 23 × 200: one difference, the order of lines from parallel pipeline elements, which dash varies too.
- `TRACE=dot`: 18 pictures for a three-pipeline string; all render.

## 6. Decisions taken while writing it (EXPERIMENTAL, waiting for approval)

- **G1.** `Proc::Spawner` takes code refs only. Sub names (with data) are the graph's business, so the small module knows nothing of naming.
- **G2.** Reap per pid, not with `waitpid(-1)` (section 4).
- **G3.** A status taken by other code: `on_exit` gets undef; the graph's state is `lost`; the shell's `$?` is 1.
- **G4.** The graph is an object; ShellSpawn uses one for the whole program.
- **G5.** A handler is removed from its node when it is called, so its data (the shell's continuation, with its contexts) is freed even while the ended node stays in the graph for a while.
- **G6.** `Proc::Spawner` works with fd numbers. The graph leaves out of the fd table an fd of the parent's that a child gets under its own number (it is inherited anyway); every other entry becomes a `dup2`, also onto itself, which clears close-on-exec.

## 7. Not done

- **Whatever flips process-wide state for a while is bullet-proof only in non-threaded execution** (documented limitation, the user, 2026-11-02: "Same for other stuff which needs temporary flipping around the call"). The places:
  - `Proc::Spawner::start`: Perl's umask, just around the call (posix_spawn has no umask setting);
  - `Proc::Spawner::wait_until`: the SIGCHLD action, while it waits (decision D3);
  - `Proc::ShellSpawn::open_end`: Perl's umask, set to the shell's while a redirection's file is opened;
  - `Proc::ShellSpawn::run`: SIGINT, SIGQUIT and SIGPIPE ignored while it runs; traps set in `%SIG` while it runs (`trap`, in `Proc::ShellSpawn::Large`), put back after it.
- posix_spawn also cannot make a child **ignore** a signal (it inherits what Perl ignores), nor set **resource limits** or the **nice** value. Since post-0.08 these are set around the call too (decision M1, below).

- Windows (W1–W3, section 8), to be written in `Proc::Spawner` now that it exists; cannot be tested here.
- Known issue X15: the shell layer still breaks some cycles by hand (contexts in their scopes). The two new modules have none.
- `Proc::Spawner` is still loaded from [`lib/`](../lib), not packaged as a distribution; the binding `PosixSpawn` is separate.

## 8. Windows (decided 2026-11-02, not written yet; in the distribution since post-0.04: no CPAN release had it, it was only in the Project's later copy of 0.01; checked against CPAN's 0.01 to 0.04 on 2026-11-05)

The user's rule: **what Windows can do fully and natively is implemented; everything else is reported as not implemented**, so the caller's `unsupported` hash (or `%Proc::Spawner::UNSUPPORTED`) decides between drop and fail, and a caller may use a workaround that is safe only in single-threaded execution (as the umask is set around the call on Linux). No "approximate" category.

- **Implemented** (per-call parameters of `CreateProcessW`, or preparation that touches nothing shared, or nothing to do):
  - the child's fds 0–2 (`STARTUPINFO` with `STARTF_USESTDHANDLES`, as Perl's own `do_spawnvp_handles()` in `win32/win32.c`);
  - "only these handles", and so `close`, `closefrom` (`PROC_THREAD_ATTRIBUTE_HANDLE_LIST`);
  - `chdir` (`lpCurrentDirectory`); `fchdir` (the directory handle's path);
  - a file "opened in the child" (opened by the parent, its relative path taken from the child's directory);
  - `search` (our own lookup through PATH and PATHEXT);
  - `pidfd` (the process handle that `CreateProcess` returns); `pgroup => 0` (`CREATE_NEW_PROCESS_GROUP`);
  - `sigdefault`, `resetids` (nothing is inherited, there is no set-user-id).
  - fds 3 and up through the C runtime's `lpReserved2`: per call and thread-safe, but only children built on that runtime read it; decided earlier as W1–W3 (Go), with programs known to ignore it (`java`, `javaw`) refused such fds.
- **Not implemented:** `umask`, a non-empty `sigmask`, ignoring signals in the child (but `PIPE`, and `INT` in a new group: nothing to do, post-0.08), `pgroup => PGID` (joining a group), `setsid`, `tcsetpgrp`, `sched`, `cgroup`.
- **Already defined by Perl on Windows, so used as they are:** the command line built from the argument list (`create_command_line()`, the quoting of multi-arg `system`), the status (`((U8) exitcode) << 8`, from `win32_waitpid()`), and waiting for children (`win32_msgwait()` over the process handles).
- **What spawn does when the primitive lacks a setting (post-0.06; the user, 2026-11-05).** `$Proc::Spawner::MISSING` is a bitmap of the settings the primitive does not do itself: what this build's libc lacks (`Proc::Spawner::__native()` lists what it has), plus `PROC_SPAWNER_MISSING` (names, for tests). `Proc::Spawner::spawn` (which wraps the XSUB `__posix_spawn`) does each missing one in this process, around the call, and undoes it afterwards; this is bullet-proof only with one thread, as the umask always was. A setting that cannot be done so is unsupported: dropped or failed, as `UNSUPPORTED` says.

| Setting | posix_spawn (glibc 2.39) | Windows, natively (`CreateProcessW`) | When missing: done around the call |
|---|---|---|---|
| `dup2`, `close`, `open`, `closefrom` (the child's fds) | yes (`closefrom`: 2.34) | fds 0-2 (`STARTUPINFO`), the handle list (`close`, `closefrom`), a file opened by the parent; fds 3 and up through the C runtime's `lpReserved2` | this process arranges its own fds as the child should have them (`close`: close-on-exec), saving and putting back what it changes; one of the four missing means all four, and `chdir`, `fchdir` too (the actions keep their order) |
| `chdir`, `fchdir` | 2.29, 2.29 | `lpCurrentDirectory` (`fchdir`: the directory handle's path) | this process changes directory and comes back (through an fd of `.`) |
| `search` | `posix_spawnp` | our own lookup through PATH and PATHEXT | PATH looked up here |
| `pidfd` | `pidfd_spawn` (2.39) | the process handle | `pidfd_open` right after the call (Linux 5.3); none: the pid alone |
| `sigdefault` | yes | nothing to do (nothing is inherited) | an ignored signal set back to its default around the call |
| `sigmask` | yes | no signals | this process's mask set around the call |
| `pgroup => PGID` (joining a group) | yes | no | this process joins the group around the call |
| `pgroup => 0` (a new group) | yes | `CREATE_NEW_PROCESS_GROUP` | not possible (the child's pid is known only after): unsupported |
| `resetids` | yes | nothing to do (no set-user-id) | the effective ids set to the real ones around the call |
| `setsid` | 2.26 | no | not possible (no way back): unsupported |
| `tcsetpgrp` | 2.35 | no | not possible (the child's group is known only after): unsupported |
| `sched`, `cgroup` | yes, 2.35 | no | not undone reliably: unsupported |
| `umask` | (none) | (none) | always set around the call |
| `sigignore`, `rlimit`, `nice` (post-0.08, M1) | (none) | no | always set around the call, in C by the XSUB (below); unsupported where it cannot be put back |
| posix_spawn itself (post-0.08, M2) | yes | ([`win_spawn.h`](../win_spawn.h)) | fork and exec; without fork either, Perl's own `system { FILE } 1, ARGV`; everything else around the call |

**What posix_spawn has no option for (post-0.08; the user, 2026-11-06, decision M1: "do the around-the-call settings where they can be undone, and (temporarily) fail for the rest").** `start(..., sigignore => [SIGNALS], rlimit => { NAME => SOFT | [SOFT, HARD] }, nice => INCREMENT)`; in `spawn`'s attributes `sigignore => [SIGNUMS]`, `rlimit => [[RESOURCE, SOFT, HARD], ...]` (undef: as ours; `'unlimited'`), `nice => INCREMENT`. The XSUB sets them in this process right around the call, in C (nothing is allocated and no Perl code runs in between, [`Spawner.xs`](../Spawner.xs), `around_parse`), with every signal blocked meanwhile, and puts them back right after; the child gets the signal mask from before. Unsupported (dropped or failed, as `UNSUPPORTED` says), because it could not be put back or would harm this process meanwhile:
- a hard limit lower than ours without `CAP_SYS_RESOURCE` (raising it back needs it; as root in a container without that capability too: checked here, where root lacks it);
- a higher nice value unless `CAP_SYS_NICE` or `RLIMIT_NICE` allows lowering it back (checked as an unprivileged user: `nice => 5` ENOTSUP, `drop` drops it);
- a CPU limit this process has used up already (it would get `SIGXCPU`);
- ignoring `SIGCHLD` (our other children ending meanwhile would be reaped by the kernel, their statuses lost);
- on Windows, `rlimit` of resources with no counterpart there (below), and `sigignore` but for what a Windows child does anyway: `PIPE` (there is no SIGPIPE: a write into a closed pipe fails, as with SIGPIPE ignored) and `INT` when the child is in a new process group (`new_group`, on by default; Windows turns Ctrl-C off in a new group, and Perl's `kill INT`, `GenerateConsoleCtrlEvent(CTRL_C_EVENT, pid)`, does not reach it). Other signals reach a Windows child only as Perl's `kill`: `TERM` and `BREAK` as Ctrl-Break (the child's default ends it), anything else as `TerminateProcess` (`win32/win32.c`, `terminate_process`): none can be ignored there.

Failing as the child would: a lower nice value without privilege (`EACCES`), a limit above our hard one without privilege (`EPERM`), an unknown resource (`EINVAL`); a signal both in `sigignore` and `sigdefault`, `SIGKILL`, `SIGSTOP`: `EINVAL`. A memory limit (`AS`) lower than what this process uses makes glibc's posix_spawn fail (`ENOMEM`: it maps the child's stack in our address space), where a child setting it before exec would not (checked: `AS` 10 MB fails, ours is put back, later calls work; with fork and exec, M2, the same call succeeds). On Linux `nice` and the signal mask are per thread, so only the calling thread sees them; the signal actions and the limits are the process's (bullet-proof only in non-threaded execution, as the umask). A signal arriving meanwhile stays pending (Linux keeps a blocked signal pending although it is ignored) and is delivered after.

**`nice` and `rlimit` on Windows (post-0.09; the user, 2026-11-08, decision W4: "(c) and (b); (c) beats (b) if present").** Windows' own settings, exact, per child: `win_priority` (a priority class: `idle`, `below_normal`, `normal`, `above_normal`, `high`, `realtime`), set with `SetPriorityClass` on the child while it is still suspended (Wine ignores the class given as a creation flag, Windows honours both), and `win_job` (limits of a job of the child's own: `ProcessMemoryLimit`, `JobMemoryLimit` in bytes of committed memory, `PerProcessUserTimeLimit`, `PerJobUserTimeLimit` in 100-ns ticks of user time, `ActiveProcessLimit`; the job is nested in the `kill_with_parent` one, which needs Windows 8, and closed with the child's handle). `nice` and `rlimit` are mapped to them, approximately: `nice` from our class's nice value (`idle` 19, `below_normal` 5, `normal` 0, `above_normal` -5, `high` -10, `realtime` -20) plus the increment, to `idle` (10 and up), `below_normal` (1 to 9), `normal` (0), `above_normal` (-1 to -9) or `high` (-10 and below), never `realtime`; `rlimit` `AS` and `DATA` to `ProcessMemoryLimit` (committed memory, not address space; the smaller wins), `CPU` to `PerProcessUserTimeLimit`, `NPROC` to `ActiveProcessLimit` (the processes in the child's job, not the user's), each from the soft value if set, else the hard one (Windows has one limit and ends the child at it, where Unix sends SIGXCPU at the soft CPU limit); `NOFILE`, `CORE`, `FSIZE`, `STACK` and the rest have no counterpart: unsupported. `win_priority` and `win_job` beat the mapping where both are given; elsewhere they are unsupported. Checked under Wine with a child that prints its priority class: `win_priority`, `nice` 5, 15, -12, and `nice` with `win_priority` give the classes above; a resource with no counterpart fails with `ENOTSUP` or is dropped; an unknown class fails with `EINVAL`. Wine stores no job limits (a plain C program setting them reads back none), so their effect is not checked here, only that the child starts with them; the mapping is tested on Linux (`t/spawner.t`).

**No posix_spawn at all (post-0.08; the user, 2026-11-06, decision M2: as Run 0.06's forkless mode, branch `project-2026-11-03`, `claude/Run-0.06/`).** `Makefile.PL` now probes `posix_spawn` itself (`POSIX_SPAWN`); without it, or with `PROC_SPAWNER_MISSING=posix_spawn` (tests), the primitive is the XSUB `__spawn_nowait`: fork and exec, in C, with nothing in between but the signal mask put back (as `spawnvp(P_NOWAIT)` on a system with a plain spawn; exec's errno comes back through a close-on-exec pipe). Every other setting is then missing and done around the call as above (`setsid`, `pgroup => 0`, `tcsetpgrp`, `sched`, `cgroup` unsupported); `rlimit`, `sigignore`, `nice` as M1. argv reaches the child exactly (execve). Checked: the whole suite passes so (58 tests), and a build without posix_spawn (`PROC_SPAWNER_WITHOUT=POSIX_SPAWN`) passes [`t/spawner.t`](../t/spawner.t) and [`t/dash.t`](../t/dash.t). Where there is no fork either (Windows when posix_spawn is masked, OS/2, VMS; on Linux with `PROC_SPAWNER_MISSING="posix_spawn fork"`: `$Proc::Spawner::PRIMITIVE` is `system1`), the redirections are delegated to Run (the user, 2026-11-07: "one of the major points of the exercise"; "it must delegate the whole code of redirection to Run"): Run 0.07, in repository `ilyaz-ai/run` (0.02 to 0.06 as released, then 0.07), to be released before Proc-Spawner needs it. `Run::start(1, ARGV, REDIRS, ERRS, FILE)` applies the redirections in this process around Perl's own spawn, `system { FILE } 1, ARGV` (P_NOWAIT; on Unix Run emulates it by fork and exec), and puts our fds back; the fd actions become Run's `[FD => {fd => M}]`, `{close => 1}`, and a file opened here as `{filehandle => FH, pin => 1}`; `chdir` and `fchdir` are done here, in order, so an `open`'s relative path is taken from the directory of that moment. What Perl's spawn does on Windows (`win32/win32.c` of 5.38.2, `do_spawnvp_handles`, `create_command_line`):
- **argv**: Perl builds the command line itself: an argument with blanks is put in quotes, but quotes and backslashes in it are not escaped, so a child sees other arguments (the table above). ❰BUG❱ in Perl ([`doc/perl-win32-system-bugs.md`](perl-win32-system-bugs.md), to be reported); the arguments are passed as they are, and the tests of exact argv and batch files are TODO on this branch until Perl is fixed (the user: no bug-for-bug workaround).
- **the program**: looked up here (PATH and PATHEXT as [`win_spawn.h`](../win_spawn.h), with `search`; otherwise as given, relative to the directory then): posix_spawn's meaning of FILE, not Perl's (which searches PATH always).
- **fds**: the child gets the standard handles of the moment (`GetStdHandle`), which the C runtime's `dup2` and `close` set for fds 0-2; the child sees no fds 3 and up: `dup2` or `open` onto them is unsupported, `close` and `closefrom` of them need nothing. But Perl's spawn passes the child every inheritable handle (`bInheritHandles`, no list), and Perl makes its handles inheritable (no close-on-exec by `$^F` on Windows), so a child could hold, unseen, the write end of its own input pipe and never see end of file (X38). Since post-0.10 our fds from 3 up are made not inheritable for the call and put back after, as POSIX has it (the user, 2026-11-09: "do as on POSIX"). **Not thread-safe**: a spawn in another thread meanwhile does not pass them either. (Windows' own thread-safe way is the list of handles a child gets, `PROC_THREAD_ATTRIBUTE_HANDLE_LIST`, which [`win_spawn.h`](../win_spawn.h) uses; Perl's spawn does not: ❰BUG❱ in Perl, [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md), 4; its section 5 lists every workaround of ours.)
- **the rest**: a new process group always (`pgroup => 0` needs nothing, a group to join is unsupported); `sigdefault`, `resetids`, an empty `sigmask` need nothing (nothing is inherited); a non-empty `sigmask`, `pidfd`, `fchdir` are unsupported; the environment is `%ENV`, set around the call; at most 64 children at once (Perl's table; `EAGAIN` after); the child is Perl's, so Perl's `waitpid` takes its status.
- Checked: on Linux the whole suite through Run (`PROC_SPAWNER_MISSING="posix_spawn fork"`, Run's forkless mode); under Wine with Strawberry Perl 5.38.2, [`t/windows.t`](../t/windows.t) through both primitives: 13 pass with [`win_spawn.h`](../win_spawn.h), and with `system1` 13 pass and the 2 TODO fail (argv, a batch file: Wine's cmd.exe does not strip the quotes Perl puts around a batch file's whole line; real Windows unchecked). Under Wine the tests must run with Windows' own standard handles (`cmd /c "perl t\windows.t > out.txt"`): Wine's handles for a Linux stdout cannot be fdopened (EINVAL), which Run's saving of fd 1 needs. OS/2 and VMS are not tested.

**The Windows primitive (post-0.06, EXPERIMENTAL, not yet built into the module).** [`win_spawn.h`](../win_spawn.h) is `posix_spawn` on `CreateProcessW`, in plain C; [`Spawner.xs`](../Spawner.xs) includes it under `_WIN32` and `#define`s the `posix_spawn` names to it, so `__posix_spawn` stays one source. It does the Windows column of the table above: the child's fds 0-2 through `STARTUPINFO`, fds 3 and up through the C runtime's `lpReserved2` table, exactly the handles the child should have through `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` (inheritable copies made for the call, so the parent's handles keep their flags); the file actions in order on a table of the child's fds (an `open` by the parent, relative to the child's directory); argv quoted as the C runtime parses it back; `posix_spawnp` through PATH and PATHEXT (a relative program name is taken from the child's directory, after `chdir`, as glibc does); `pgroup => 0` as `CREATE_NEW_PROCESS_GROUP`; `ENOTSUP` for the rest. The process handle is kept, so the exit code survives until the child is waited for (`__win_spawn_handle`, `__win_spawn_forget`). Checked with MinGW-w64 under Wine; compiled for x86, x64 and ARM64. Still to do on Windows: building the module with a Windows Perl, waiting for children through the kept handles, and the event loop without SIGCHLD.

**Compared with Perl's own spawn on Windows** (`do_spawnvp_handles()`, `create_command_line()`, `qualified_path()`, `win32_waitpid()`, `win32_kill()` in `win32/win32.c` of perl 5.38.2; 2026-11-05). Fixed in [`win_spawn.h`](../win_spawn.h) and [`Spawner.xs`](../Spawner.xs) after the comparison:
- the program without an extension: PATHEXT's extensions first, the bare name last (Perl tries `.exe` first; a bare `prog`, say an MSYS script beside `prog.exe`, cannot be run); a quoted PATH entry (`"C:\a;b"`) is one entry, as Perl reads it;
- `cmd.exe /c` (or `/x/c`) with two or more words after it: the rest gets one more pair of quotes, which cmd strips by its own rules, as Perl does;
- the environment block sorted by name, ignoring case, with the parent's hidden `=C:` entries (each drive's directory) kept;
- a command line over 32766 characters: `E2BIG`;
- strings: Perl's own `CreateProcessA` takes bytes in the ANSI code page; so a string Perl does not hold as UTF-8 is read as ANSI, one it holds as UTF-8 as UTF-8;
- the child's default environment and directory are Perl's (`PerlEnv_get_childenv`, `PerlEnv_get_childdir`), which with pseudo-forks can differ from the process's;
- memory: compiled against Strawberry Perl 5.38.2 (`PERL_IMPLICIT_SYS`), `malloc` and `free` are Perl's macros for the interpreter's allocator; [`win_spawn.h`](../win_spawn.h) now allocates on the process heap itself (it mixed allocators before). `Spawner.dll` then compiles and links against Strawberry Perl's headers and `libperl538.a` with MinGW-w64; it has not been loaded yet.

Run under Wine with Strawberry Perl 5.38.2 (the user's approval, 2026-11-05): `Spawner.dll` built with MinGW-w64 against its headers and `libperl538.a` loads; `Proc::Spawner::spawn` starts Windows' `perl.exe`, an `open` action gives it a file as stdout, Perl's own `waitpid` reaps it (status 3), and `%Proc::Spawner::WINDOWS` works. This found two faults, fixed: `spawn` gave the count of its results, not the pid, in scalar context (its wrapper; on Linux only when a setting is missing); `Proc::Spawner` used `fcntl` and `SIGCHLD` at load time. On Windows the loop now polls for ended children every `$TICK`; Perl's `select` there works on sockets only, so `on_read`, `on_write` of pipes are not done yet.

How the child sees its arguments (a Windows `perl.exe` printing `@ARGV`; given: `a b`, `q"x`, `c\\`, the empty string, `x "y" z`, `tail\`, `d\"e`, `%PATH%`, `a&b`):

| Started by | The child's `@ARGV` |
|---|---|
| Perl's own `system LIST` | two arguments: `[a b] [qx c\\ " x y z tail\ d"e %PATH% a&b]` (quotes taken as quoting, the empty one gone; a `-e` program with `"` in it does not even compile) |
| `Proc::Spawner::spawn` | all nine, as given |

Choices (the user, 2026-11-05), in `%Proc::Spawner::WINDOWS` ([`win_spawn.h`](../win_spawn.h): `WIN_OPT_*`), every child:
- **`new_group`** (default on): `CREATE_NEW_PROCESS_GROUP`. Ctrl-C at the console reaches the parent, not the children: the parent is the one to be killed, and it is to kill its children (the user).
- **`kill_with_parent`** (default on): the child is in a job object (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`) whose only handle is the parent's, so Windows ends the children when the parent ends, however it ends. The child is started suspended, put in the job, then resumed, so nothing it starts escapes. Checked under Wine (a child that would write a file after 3 seconds: killed when the parent exits; with the option off, it writes it). Before Windows 8, a parent that is in a job already cannot put its children in another one: they then run outside it.
- **`new_console`** (default on, as Perl): a child with none of fds 0-2 gets a console of its own (`CREATE_NEW_CONSOLE`); off: it shares ours with no standard handles.

**Batch files** (`.bat`, `.cmd`) run (the user: most arguments can be passed safely, and the others can be recognized): through the system's `cmd.exe /e:ON /v:OFF /d /c ""SCRIPT" ARGS"` (not a cmd.exe found on PATH), each argument quoted for cmd as Rust's standard library does since BatBadBut (CVE-2024-24576): quoted unless it has only letters, digits and `#$*+-./:?@\_`; `"` doubled; `%` written `%%cd:~,%`, which cmd expands to a single `%`, so no `%NAME%` is expanded; a trailing `\` quotes it too. Refused (`EINVAL`): an argument with CR or LF (cmd ends the line there), a script path with `"` or ending in `\`. The script sees each argument as cmd shows it (`%1` with the quotes, `%~1` without). Under Wine, `& | < >` and quotes arrive literally and nothing else runs; `%` does not (Wine's cmd reads `%%` on a command line as one `%`, real cmd does not); not checked on real Windows.

**Unicode:** the child is started with `CreateProcessW` (UTF-16 command line, environment and paths), Perl's own with `CreateProcessA` (the ANSI code page). A string Perl holds as UTF-8 therefore reaches the child as it is, whatever the code page; one it holds as bytes is read in the ANSI code page, as Perl's spawn reads it.

**Windows versions:** the explicit handle list needs Vista; Windows 7's console handles are pseudo-handles that the list refuses, so they are left out of it (the child reaches the console through `STARTUPINFO`); nested job objects need Windows 8. Not tested before Windows 10 (Wine 9 imitates 10).

The kept process handle is released once the loop has the child's status (post-0.08: `reap` calls `Proc::Spawner::reaped`, which calls `__win_spawn_forget`; since post-0.10 `start`'s child watch does; a caller of the raw `spawn` who waits itself calls `reaped(PID)`). Checked under Wine with Strawberry Perl 5.38.2: one child's handle is gone after its status (0.08: still open), and 1,100 children in a row all give their status.  With 1,100 children started before any is waited for, all ended by then, 0.09's fixed table of 1,024 kept handles lost 76 statuses (the children whose handles did not fit were closed at once; known issue X34); since post-0.09 the table grows, and none is lost (checked under Wine both ways). `rlimit`, `sigignore`, `nice` fail there with `ENOTSUP`, or are dropped.

Done post-0.09: `Win32::SetChildShowWindow` is honoured as by Perl's own spawn (`STARTF_USESHOWWINDOW` and `wShowWindow` from Perl's `w32_use_showwindow`, `w32_showwindow`; checked under Wine with a child that prints its startup info: the same through both primitives, before, after `SetChildShowWindow(0)` and `(7)`, and after resetting it); more than 64 children at once (the loop polls each child, so Windows' limit of 64 handles per wait does not apply: 100 at once checked; Perl's own spawn, `system1`, still stops at 64, Perl's table); building through `Makefile.PL` (no POSIX probes there; checked under Wine with Strawberry Perl's own gcc and gmake: `perl Makefile.PL`, `gmake` without a warning, `gmake test` of `t/windows.t` and `t/parsers.t`).

Done post-0.10, **W5**: the loop is [`Proc::Spawner::Loop`](../lib/Proc/Spawner/Loop.pm), with a Windows backend on an I/O completion port; how it works and what was checked: [`pspawn-loop.md`](pspawn-loop.md). The shell layer on top runs there too since post-0.10: [`pspawn-shell-windows.md`](pspawn-shell-windows.md).

**`Proc::ShellSpawn` on Windows, before its port** (the port came later on 2026-11-09: [`pspawn-shell-windows.md`](pspawn-shell-windows.md)).** What runs there: `Proc::Spawner` (the primitive, [`win_spawn.h`](../win_spawn.h)), the loop ([`pspawn-loop.md`](pspawn-loop.md)), the parsers, and the programs `Proc::ShellSpawn` runs inside Perl (X21: `echo`, `printf`, `test`, `[`, `true`, `false`). The shell layer itself did not, before the port: found under Wine on 2026-11-09, when the snippet library was to run there ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 7, "W5"), every `run()` died at once, first at `getppid` (for `$PPID`; Windows Perl has none), then, past that in a scratch copy, in `Proc::Spawner::Graph` at `fcntl` with `F_GETFL` (a handle's mode), and the graph's pipes were made as FIFOs and reopened through `/proc`, which Windows lacks too (the port takes `$PPID` from `NtQueryInformationProcess` and does without `fcntl` and `/proc` there). Under Wine with Strawberry Perl 5.38.2.2, on the code of post-0.10, these pass: [`t/loop.t`](../t/loop.t), [`t/windows.t`](../t/windows.t), [`t/parsers.t`](../t/parsers.t), [`t/programs.t`](../t/programs.t) (skipped there: Ctrl-C without a console, the comparisons with dash, bash and coreutils), and the large parser over all 45,501 extracted corpus samples gives the same trees and rejections as on Linux.

Still not done: the inheritable copies of handles exist during the call, so another thread's `CreateProcess` with inheritance could take them (one thread assumed).

While this process's fds or directory are changed, every signal is blocked, so no handler of ours sees them; the child's mask is set by the primitive. If `sigmask` is missing too, the signals cannot be blocked without the child inheriting that: then a handler running in that moment would see the changed fds. Tests: [`t/missing-matrix.pl`](../t/missing-matrix.pl) runs the whole suite once per entry of the bitmap, then with all emulable settings missing, with the Windows column's gaps, and with everything missing.

- **Testing on Linux "as on Windows":** a runtime list of what the platform lacks (empty on Linux, the list above on Windows, settable in tests), consulted where the XS now consults the missing extensions; a test then runs the batteries with the Windows list. argv and exit statuses need no test of ours: they are Perl's.
