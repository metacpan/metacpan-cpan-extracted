# Proc::Spawner and its graph: the split of the executor (2026-11-02)

**Status: EXPERIMENTAL.** The user (the distribution's author, who makes its decisions) endorsed every choice experimentally (2026-11-02, 00:24) and asked for this split
(00:32: "Please start"). The decisions taken while writing it, G1–G6 in [section 6](#my-section-6), are experimental
too and wait for approval.

Until 2026-11-01 one module, `ShellSpawn`, did everything: the shell, the starting of children, the event loop, and a
graph that only recorded and drew what happened. Now there are three layers over a common event loop, four modules in all, and the graph is what gets executed (the *executor* is the shell layer, `Proc::ShellSpawn`; version labels such as post-0.10, the work after a release: [`README.md`](README.md#my-version-labels-of-the-results); W1–W7 are the Windows decisions of section 8, M1 and M2 those of what posix_spawn lacks, section 8 too):

| Module | Lines (with POD, 2026-11-18) | What it does | Depends on |
|---|---|---|---|
| [`lib/Proc/Spawner.pm`](../lib/Proc/Spawner.pm) (+ [`Spawner.xs`](../Spawner.xs)) | 694 (2026-11-02: 230) | starts a child with a given fd table and any posix_spawn setting; offers the calls of the one event loop that reports "a child ended", "an fd is readable/writable" (since W5 the loop itself is `Proc::Spawner::Loop`, the next row); its XS part is the former binding `PosixSpawn` | – |
| [`lib/Proc/Spawner/Loop.pm`](../lib/Proc/Spawner/Loop.pm) (+ [`Loop/POSIX.pm`](../lib/Proc/Spawner/Loop/POSIX.pm), [`Loop/Win32.pm`](../lib/Proc/Spawner/Loop/Win32.pm), [`win_loop.h`](../win_loop.h)) | 520 (since post-0.10) | the one event loop (W5): queued calls, timers, reads, writes, ended children, with one interface on POSIX (`select`, SIGCHLD) and on Windows (an I/O completion port); `Proc::Spawner`'s `on_read`, `on_write`, `defer`, `wait_until`, `poll` are its old names | `Proc::Spawner`'s XS |
| [`lib/Proc/Spawner/Graph.pm`](../lib/Proc/Spawner/Graph.pm) | 299 | the graph: open files (*ends*) with hold counts, process nodes, Perl's own reads and writes; each process node holds what to do when the process ends; also the notation, the pictures, and running hand-written graphs | `Proc::Spawner` |
| [`lib/Proc/ShellSpawn.pm`](../lib/Proc/ShellSpawn.pm) (+ [`ShellSpawn/Large.pm`](../lib/Proc/ShellSpawn/Large.pm), [`ShellSpawn/Builtins.pm`](../lib/Proc/ShellSpawn/Builtins.pm), [`ShellSpawn/Programs.pm`](../lib/Proc/ShellSpawn/Programs.pm)) | 981 (+319, +141, +376) | only the shell: words, redirections, contexts, builtins, traps, jobs | `Proc::Spawner` and `Proc::Spawner::Graph` |

`lib/SpawnGraph.pm` is gone; its notation, drawing and runner are in `Proc::Spawner::Graph`.

### <a id="my-the-old-names"></a>The old names

On 2026-11-02, 07:30, the modules were renamed (the user: "`PosixSpawn` should be subsumed by `Proc::Spawner`. The rest
should be put into `Proc::`"; names option A). There is one distribution, `Proc-Spawner`, built at the top of the
bundle with `perl Makefile.PL && make`. Older documents use the old names:

| Old name | New name |
|---|---|
| `PosixSpawn` (XS binding, its own directory and Makefile.PL) | part of `Proc::Spawner`: [`Spawner.xs`](../Spawner.xs) at the top (below) |
| `PosixSpawn::spawn` | `Proc::Spawner::spawn` (below) |
| `spawn`, the call with the fd table and `on_exit` | `start` |
| `fpe_at_exec`, `chld_to_fd`, `chld_restore` | in `Proc::Spawner` |
| `ShellSpawn`, `ShellSpawn::Large` | `Proc::ShellSpawn`, `Proc::ShellSpawn::Large` ([`lib/Proc/`](../lib/Proc)) |
| `ShellSubset`, `ShellSubsetSmall`, `ShellSubsetLarge` (in `parser/`) | `Proc::ShellSubset`, `Proc::ShellSubset::Small`, `Proc::ShellSubset::Large` ([`lib/Proc/`](../lib/Proc)); the test scripts are in [`t/parser/`](../t/parser) (since 09:58) and find [`lib/`](../lib) themselves |

The raw call `Proc::Spawner::spawn` wraps the XSUB `__posix_spawn` (section 8). It has no `posix_` in its name because
the same interface should have a chance to work on POSIX and on Windows (the user). It takes a sixth, optional
argument `{ OPTION => 'drop' | 'fail' }`: what a port lacking an option (Windows) does with it. The defaults are in
`%Proc::Spawner::UNSUPPORTED` (`'*' => 'fail'`, EXPERIMENTAL).

Include paths are now `lib` and `blib/arch`. The A4 message says "Proc::ShellSubset::Large: … is not supported" since
0.02 (it said "ShellSubsetLarge: …" before).

## <a id="my-section-1"></a>1. Proc::Spawner: the small one

`Proc::Spawner` has the functions below and the raw `spawn` (the primitive, with what it lacks done around it:
[section 8](#my-section-8)). It knows nothing about pipes, files or the shell.

| Call | Meaning |
|---|---|
| `start(PATH, ARGV, ENVP, FDS, %opt)` (was `spawn`) | starts a child; returns its pid, or undef with `$!` (FDS and the options: below) |
| `on_read(FD, N, CODE)` | one read of at most N bytes when FD is readable: `CODE->(BYTES)`, or `CODE->(undef)` at end of file |
| `on_write(FD, BYTES, CODE)` | writes BYTES as the reader takes them, never blocking Perl; `CODE->()` when done or the reader is gone |
| `defer(CODE, ARGS)` | queue `CODE->(ARGS)` |
| `wait_until(CODE)` | run the queue and wait for events until `CODE->()` is true |

**`start`'s arguments.**

- `FDS = { CHILD_FD => PARENT_FD, or undef for "closed" }`. Fds not listed are inherited as they are (if not
  close-on-exec). A value may also be `[PATH, FLAGS, MODE]`: a file opened in the child.
- The options (2026-11-02, the user: "more or less all the fields of `posix_spawn` should be supported"):
  - posix_spawn's settings: `chdir`, `fchdir`, `sigdefault => [signals]`, `sigmask => [signals]`, `pgroup`,
    `setsid`, `tcsetpgrp`, `resetids`, `sched`, `cgroup`, `search`, `pidfd` (then, in list context, the pid and a
    pidfd);
  - settings posix_spawn has no option for: `umask`, `sigignore`, `rlimit`, `nice` (M1);
  - Windows' own: `win_priority`, `win_job` (W4);
  - `unsupported => HASH` (passed to `spawn`), `on_exit => CODE`.
- Signals are given by name or number; an unknown name dies.
- The full list is in the module's header comment.

Example: `ls` with its output in a pipe whose read end Perl reads, while `ls`'s fd 2 is closed:

```perl
pipe my $r, my $w;
my ($out, $st, $eof) = ('');
Proc::Spawner::start('/bin/ls', ['ls'], undef, { 1 => fileno $w, 2 => undef }, on_exit => sub { $st = shift });
close $w;
Proc::Spawner::on_read($r, 4096, sub { defined $_[0] ? ($out .= $_[0], Proc::Spawner::on_read($r, 4096, __SUB__)) : ($eof = 1) });
Proc::Spawner::wait_until(sub { $eof && defined $st });
```

The rules, as decided on the page "Child Exit Wake-up":

- **R1.** Every callback runs from the queue, one at a time: never inside a signal handler, never inside another
  callback. A child that ends while a callback runs is noticed, and its `on_exit` queued, only after that callback
  returns.
- **D2.** A callback never waits: `wait_until` called from inside one dies with "wait inside a reaction".
- **D1.** While `wait_until` runs, SIGCHLD has a C handler (from the binding) that writes one byte into a pipe; the
  loop `select`s on that pipe. No Perl code runs inside the signal, and no wake-up is lost. Without the C function
  (another binding), a deferred Perl handler is used, and `select` wakes every 50 ms.
- **D3.** `Proc::Spawner` sets the SIGCHLD action only while `wait_until` runs; the previous handler is put back
  afterwards. (Since post-0.04, `Proc::ShellSpawn` installs a deferred SIGCHLD handler of its own between `run()` calls
  while background jobs remain, the user's choice B of question K3; it calls `Proc::Spawner::poll()`. `Proc::Spawner`
  itself still keeps D3.)

## <a id="my-section-2"></a>2. Proc::Spawner::Graph: the executable graph

The graph says, for the current moment, which of the children, and which of Perl's own reads and writes, use which
open file. Each process node holds what to do when the process ends.

- **Ends.** An *end* is an open file the parent keeps: a pipe half (`r`, `w`), a file, or one of the parent's own fds
  (`parent`). Whoever needs an end holds it (`hold`); the last `release` closes the parent's copy. Ends are
  close-on-exec (but `parent` ends, the parent's own fds, which stay as they are), so a child gets exactly what its fd table gives it. Ends are made by `$g->new_pipe`,
  `$g->file_end(FH, MODE, PATH)`, `$g->parent_end(N)`.
- **Processes.** `$g->start(PATH, ARGV, ENVP, MAP, on_exit => HANDLER, …)`, where
  `MAP = { CHILD_FD => end, or undef }`, starts the child and adds its node. The node records its edges (fd, how it is
  used, end), its pid and its state: `pending`, running, `exited N`, `signal N`, `lost` (its status was taken by other code), `never` (it was not started).
- **Perl's own reads and writes.** `$g->perl_read(END, N, HANDLER)` and `$g->perl_write(END, BYTES, HANDLER)` are
  nodes too (drawn as the process "Perl"), so the graph knows which ends the parent itself still uses, including ends
  the caller never sees.
- **Handlers.** A handler is a code ref, or `[NAME, DATA…]` with NAME a fully qualified sub name, whose module is
  loaded at first use (the user's choice for parse trees, 2026-11-01 16:08, applied here too). When the process ends,
  `NAME->(GRAPH, NODE, WAIT_STATUS, DATA…)` runs from the queue. It may start new processes (each with its own
  handler), release ends, read and write; it never waits. So the graph grows and shrinks as it runs.
- **No reference cycles.** The graph holds its processes; a process holds its ends and its handler's data; ends point
  back only weakly (`peer`, `g`). Handlers get the graph as an argument, so their data never needs to hold it. A
  handler is dropped from its node once called. An ended process leaves the graph once it shares no end, or pipe, with
  a running process or with one of Perl's own reads and writes.

Example (from [`t/spawner.t`](../t/spawner.t)): `echo hello` writes into pipe 1. When it ends, its handler starts `cat`
reading pipe 1 and writing pipe 2, which Perl reads.

```perl
my $g = Proc::Spawner::Graph->new;
my ($r, $w) = $g->new_pipe; my ($pr, $pw) = $g->new_pipe;
sub then_cat { my ($g, $node, $st, $r, $pw) = @_;
  $g->start('/bin/cat', ['cat'], undef, { 0 => $r, 1 => $pw });
  Proc::Spawner::Graph::release($_) for $r, $pw }
$g->start('/bin/sh', ['sh', '-c', 'echo hello'], undef, { 1 => $w }, on_exit => ['main::then_cat', $r, $pw]);
Proc::Spawner::Graph::release($w);
my $got = '';   # Perl reads pipe 2 until its end
$g->perl_read($pr, 100, sub { my ($g, $b) = @_; return Proc::Spawner::Graph::release($pr) unless defined $b;
                              $got .= $b; $g->perl_read($pr, 100, __SUB__) });
```

**Hand-written graphs** in the notation (`sgraph/*.sg`) now run on this engine. `after P1 fail` becomes a named handler
on P1 (`Proc::Spawner::Graph::then`) that starts the processes waiting for P1, or marks them `never` and releases their
ends. [`sgraph/run-graph.pl`](../t/sgraph/run-graph.pl) checks every process's fds with the reporter program: 17 of 17
processes as drawn (6 examples).

**Pictures.** `Proc::Spawner::Graph->new(dot => DIR)` writes the graph after every event (start, exit, close) as
`DIR/trace-001.dot`, …; the executor does this with `TRACE=dot`.

## <a id="my-section-3"></a>3. How ShellSpawn uses them

- One graph for the whole program, `$Proc::ShellSpawn::G`, so a background job that outlives `run()` stays in it.
- A context's map (child fd → end) is the `MAP` given to `$G->start`. Contexts hold and release ends as before.
- Each child's node carries the shell's continuation: `on_exit => ['Proc::ShellSpawn::resume', K]`, and `resume` calls
  `K` with sh's `$?`.
- `$( … )`, `read` and here-documents are `perl_read` and `perl_write` nodes.
- What stays shell-specific is in `Proc::ShellSpawn::spawn`: the PATH search and its messages, the environment, which
  signals children get back as default, the ENOEXEC fallback to `/bin/sh`.

## <a id="my-section-4"></a>4. Behaviour changes

1. **Only the module's own children are reaped** (G2). The loop calls `waitpid(PID, WNOHANG)` for each child it
   started, instead of `waitpid(-1, …)`. So it no longer takes the statuses of the caller's own children (finding C2).
   - If other code takes a status of one of the module's children first, the child is reported with status undef,
     instead of being waited for forever; the shell gives `$?` = 1 for it (G3).
   - On Windows, with `win_spawn.h`'s posix_spawn, other code cannot take it: the exit code stays with the process handle that the module keeps until it
     has reported the child, so other code's `waitpid` and the module's both get it (checked under Wine, post-0.10,
     [`t/spawner.t`](../t/spawner.t)).
2. The trace says `reaped PID: wait status W` (the raw status) instead of sh's `$?`.
3. In pictures, an ended process shows `exited N` or `signal N`, and the Perl node also shows Perl's writes
   (here-documents), not only its reads.

Nothing else changed: on every battery the old and the new executor print the same output, messages and status for all
234 command lines (only the lengths of pids differ).

## <a id="my-section-5"></a>5. Tested at the split (0.01 to 0.04)

This section keeps the counts of those releases. The tests of today: [section 8](#my-section-8) and
[`test-results/`](test-results) ([`t/dash.t`](../t/dash.t) passes, every line that differs from dash being listed in
[`t/dash-known.txt`](../t/dash-known.txt)). `hyg.pl` and `mem.pl` below were probes of that time.

### <a id="my-against-dash-in-0-03-and-0-04"></a>Against dash, in 0.03 and 0.04

[`t/dash.t`](../t/dash.t) runs each line of a battery in dash and in `Proc::ShellSpawn`; the counts are the lines that
agree with dash. Every other line is a known difference ([`t/dash-known.txt`](../t/dash-known.txt)).

| Battery | 0.03 (2026-11-03) | 0.04 |
|---|---|---|
| [`largebattery.txt`](../t/batteries/largebattery.txt) | 111 of 114 | 108 of 114 (three lines more now differ from dash on purpose: `getopts` leaves `OPTARG` unset, rule E) |
| [`battery.txt`](../t/batteries/battery.txt) | 42/43 | as in 0.03 |
| [`fdbattery.txt`](../t/batteries/fdbattery.txt) | 14/14 | as in 0.03 |
| [`sigenv.txt`](../t/batteries/sigenv.txt) | 12/12 | as in 0.03 |
| [`t1.txt`](../t/batteries/t1.txt) | 39/45 | as in 0.03 |
| [`t2.txt`](../t/batteries/t2.txt) | 42/44 (one line's order varies, as in dash) | as in 0.03 |
| [`t3.txt`](../t/batteries/t3.txt) | 16/17 | as in 0.03 |
| [`pspawn-d2.txt`](../t/batteries/pspawn-d2.txt) | 9/10 | as in 0.03 |
| [`pspawn-l10.txt`](../t/batteries/pspawn-l10.txt) | 6/9 | as in 0.03 |
| [`large-subset-b13.txt`](../t/batteries/large-subset-b13.txt) | 37/38 | as in 0.03 |
| [`large-subset-p6.txt`](../t/batteries/large-subset-p6.txt) | – (added post-0.03: 19 of 19; 21 of 21 in post2-0.03) | 25 of 25 |
| [`large-subset-e.txt`](../t/batteries/large-subset-e.txt) | – | 2 of 10 (new; the other 8 are rule-E choices listed in [`t/dash-known.txt`](../t/dash-known.txt)) |

The other batteries, run again on post-0.03, gave the same counts as in 0.03.

### <a id="my-before-0-01-2026-11-02"></a>Before 0.01 (2026-11-02)

- [`t/spawner.t`](../t/spawner.t): 20 tests (32 since 2026-11-02, 08:00: every posix_spawn setting, and the raw
  `spawn`) of `Proc::Spawner` and the graph: fd tables (including colliding fd numbers), closed fds, `chdir`, `umask`,
  ignored signals and `sigdefault`, exit and signal statuses, a 1 MB write by Perl without blocking, R1 (reactions
  never interleave), D2, "nothing left to wait for", a status taken by other code, a handler starting the next
  process. All pass, with the C handler and with the fallback.
- Against dash, as before the split: [`largebattery.txt`](../t/batteries/largebattery.txt) 99/103 (106/110 after the 7
  lines added for L6–L8, see the known issues), [`battery.txt`](../t/batteries/battery.txt) 42/43,
  [`fdbattery.txt`](../t/batteries/fdbattery.txt) 14/14, [`sigenv.txt`](../t/batteries/sigenv.txt) 12/12,
  [`t1.txt`](../t/batteries/t1.txt) 39/45, [`t2.txt`](../t/batteries/t2.txt) 43/44, [`t3.txt`](../t/batteries/t3.txt)
  16/17. The same counts as before also with `PARSER=small` and `PARSER=base`.
- `hyg.pl`: parent fds unchanged, no zombies.
- Memory: `mem.pl` on four commands and [`sigprobe/mem-large.pl, now t/memory.t`](../t/memory.t): RSS flat over 1,500
  runs. After 6,500 runs the graph holds 1 process node.
- [`sigprobe/exec-stress.pl, now t/stress.t`](../t/stress.t): 9,750 children in 15 s, finished normally.
- `large-subset-difffuzz.pl`, seeds 7, 11, 23 × 200: one difference, the order of lines from parallel pipeline
  elements, which dash varies too.
- `TRACE=dot`: 18 pictures for a snippet of three pipelines; all render.

## <a id="my-section-6"></a>6. Decisions taken while writing it (EXPERIMENTAL, waiting for approval)

- **G1.** `Proc::Spawner` takes code refs only. Sub names (with data) are the graph's business, so the small module
  knows nothing of naming.
- **G2.** Reap per pid, not with `waitpid(-1)` ([section 4](#my-section-4)).
- **G3.** A status taken by other code: `on_exit` gets undef; the graph's state is `lost`; the shell's `$?` is 1.
- **G4.** The graph is an object; ShellSpawn uses one for the whole program.
- **G5.** A handler is removed from its node when it is called, so its data (the shell's continuation, with its
  contexts) is freed even while the ended node stays in the graph for a while.
- **G6.** `Proc::Spawner` works with fd numbers. The graph leaves out of the fd table an fd of the parent's that a
  child gets under its own number (it is inherited anyway); every other entry becomes a `dup2`, also onto itself,
  which clears close-on-exec.

## <a id="my-section-7"></a>7. Not done

- **What changes process-wide state for a while is safe only in a program with one thread** (a documented limitation,
  the user, 2026-11-02: "Same for other stuff which needs temporary flipping around the call"). The places:
  - `Proc::Spawner::start`: Perl's umask, just around the call (posix_spawn has no umask setting);
  - `Proc::Spawner::wait_until`: the SIGCHLD action, while it waits (decision D3);
  - `Proc::ShellSpawn::open_end`: Perl's umask, set to the shell's while a redirection's file is opened;
  - `Proc::ShellSpawn::run`: SIGINT, SIGQUIT and SIGPIPE ignored while it runs; traps set in `%SIG` while it runs
    (`trap`, in `Proc::ShellSpawn::Large`), put back after it.
- posix_spawn also cannot make a child **ignore** a signal (it inherits what Perl ignores), nor set **resource
  limits** or the **nice** value. Since post-0.08 these are set around the call too (decision M1,
  [section 8](#my-section-8)).
- Windows: [section 8](#my-section-8).
- Known issue X15: the shell layer still breaks some reference cycles by hand (contexts in their scopes). The new
  modules have none.

## <a id="my-section-8"></a>8. Windows, and what the primitive lacks

Windows was decided on 2026-11-02 and written since post-0.04. It is in the distribution since post-0.04: no CPAN
release had it before (it was only in the Project's later copy of 0.01; checked against CPAN's 0.01 to 0.04 on
2026-11-05). This section also says what `spawn` does on any platform where the primitive lacks a setting.

**Terms.** The *primitive* is the call that starts a child: posix_spawn (on Windows, the posix_spawn of
[`win_spawn.h`](../win_spawn.h)); without it, fork and exec; without fork either, Perl's own `system 1, LIST` through
Run (*system1*); the approaches of [`README.md`](../README.md#my-the-approaches) are made of these. A setting is *done
around the call* when `Proc::Spawner` makes it in its own process just before the call and undoes it right after.
A setting is *unsupported* when it can be neither done by the primitive nor around the call: it is then dropped or
fails, as the caller's `unsupported` hash (or `%Proc::Spawner::UNSUPPORTED`) says.

### <a id="my-the-rule-for-windows"></a>The rule for Windows

The user's rule: **what Windows can do fully and natively is implemented; everything else is reported as not
implemented**. So the caller's `unsupported` hash (or `%Proc::Spawner::UNSUPPORTED`) decides between drop and fail,
and a caller may use a workaround that is safe only in single-threaded execution (as the umask is set around the call
on Linux). There is no "approximate" category (but W4, later, maps `nice` and `rlimit` approximately, by the user's decision: below).

- **Implemented** (per-call parameters of `CreateProcessW`, or preparation that touches nothing shared, or nothing to
  do):
  - the child's fds 0–2 (`STARTUPINFO` with `STARTF_USESTDHANDLES`, as Perl's own `do_spawnvp_handles()` in
    `win32/win32.c`);
  - "only these handles", and so `close`, `closefrom` (`PROC_THREAD_ATTRIBUTE_HANDLE_LIST`);
  - `chdir` (`lpCurrentDirectory`); `fchdir` (the directory handle's path);
  - a file "opened in the child" (opened by the parent, its relative path taken from the child's directory);
  - `search` (a lookup of its own through PATH and PATHEXT);
  - `pidfd` (the process handle that `CreateProcess` returns); `pgroup => 0` (`CREATE_NEW_PROCESS_GROUP`);
  - `sigdefault`, `resetids` (nothing is inherited, there is no set-user-id);
  - fds 3 and up through the C runtime's `lpReserved2`: per call and thread-safe, but only children built on that
    runtime read it; decided earlier as W1–W3 (Go), with such fds refused to programs known to ignore them (`java`,
    `javaw`).
- **Not implemented** by the file itself (what `Proc::Spawner` does around the call instead: the table below): `umask`, a non-empty `sigmask`, ignoring signals in the child (except `PIPE`, and `INT` in a
  new group, where there is nothing to do: post-0.08), `pgroup => PGID` (joining a group), `setsid`, `tcsetpgrp`,
  `sched`, `cgroup`.
- **Already defined by Perl on Windows, so used as they are:** the status (`((U8) exitcode) << 8`, from
  `win32_waitpid()`), and waiting for children (`win32_msgwait()` over the process handles). (The command line built from the argument list was at first Perl's `create_command_line()`, the quoting of multi-arg `system`; `win_spawn.h` now quotes it itself, as the C runtime parses it back: below.)

### <a id="my-what-spawn-does-when-the-primitive-lacks-a-setting"></a>What spawn does when the primitive lacks a setting

(post-0.06; the user, 2026-11-05)

- `%Proc::Spawner::MISSING` has as its keys the settings the primitive does not do itself: what this build's libc
  lacks (`Proc::Spawner::__native()` lists what it has), plus those named in `PROC_SPAWNER_MISSING` (for tests). It is
  a hash since post-0.12 (item JC3 of the review of the executor's code); until then it was a bitmap,
  `$Proc::Spawner::MISSING`.
- `Proc::Spawner::spawn` (which wraps the XSUB `__posix_spawn`) does each missing setting in this process, around the
  call, and undoes it afterwards. This is safe only with one thread, as the umask always was.
- A setting that cannot be done so is unsupported: dropped or failed, as `UNSUPPORTED` says.

| Setting | posix_spawn (glibc 2.39) | Windows, natively (`CreateProcessW`) | When missing: done around the call |
|---|---|---|---|
| `dup2`, `close`, `open`, `closefrom` (the child's fds) | yes (`closefrom`: 2.34) | fds 0-2 (`STARTUPINFO`), the handle list (`close`, `closefrom`), a file opened by the parent; fds 3 and up through the C runtime's `lpReserved2` | this process arranges its own fds as the child should have them (`close`: close-on-exec), saving and putting back what it changes; where a call asks for one of a missing kind, all four are done so, and `chdir`, `fchdir` too (the actions keep their order; per call since post-0.13, X67). Where `closefrom` is the only missing kind (glibc before 2.34, musl), nothing is done in this process since post-0.13: `closefrom N` becomes a `close` of each fd from N up that the child has at that point (this process's fds without close-on-exec, and the targets of the call's earlier `dup2` and `open`, less what it closed), and posix_spawn does them all in the child. Unlike the C library's `closefrom`, this misses an fd that another thread opens between the listing and the call |
| `chdir`, `fchdir` | 2.29, 2.29 | `lpCurrentDirectory` (`fchdir`: the directory handle's path) | this process changes directory and comes back (through an fd of `.`) |
| `search` | `posix_spawnp` | a lookup of its own through PATH and PATHEXT | PATH looked up here |
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
| `sigignore`, `rlimit`, `nice` (post-0.08, M1) | (none) | no (`sigignore` of PIPE, and of INT in a new group: nothing to do; `nice` and `rlimit` mapped by W4 to `win_priority` and `win_job`) | always set around the call, in C by the XSUB (below); unsupported where it cannot be put back |
| posix_spawn itself (post-0.08, M2) | yes | ([`win_spawn.h`](../win_spawn.h)) | fork and exec; without fork either, Perl's own `system { FILE } 1, ARGV`; everything else around the call |

### <a id="my-what-posix-spawn-has-no-option-for-m1"></a>What posix_spawn has no option for (M1)

(post-0.08; the user, 2026-11-06, decision M1: "do the around-the-call settings where they can be undone, and
(temporarily) fail for the rest")

- **How they are given.** To `start`: `sigignore => [SIGNALS]`, `rlimit => { NAME => SOFT | [SOFT, HARD] }`,
  `nice => INCREMENT`. In `spawn`'s attributes: `sigignore => [SIGNUMS]`, `rlimit => [[RESOURCE, SOFT, HARD], ...]`
  (undef: as this process has it; `'unlimited'`), `nice => INCREMENT`.
- **How they are set.** The XSUB sets them in this process right around the call, in C: nothing is allocated and no
  Perl code runs in between ([`Spawner.xs`](../Spawner.xs), `around_parse`). Every signal is blocked meanwhile, and
  the settings are put back right after; the child gets the signal mask from before.

**Unsupported** (dropped or failed, as `UNSUPPORTED` says), because the setting could not be put back, or would harm
this process meanwhile:
- a hard limit lower than this process's, without `CAP_SYS_RESOURCE` (raising it back needs that capability; so too as
  root in a container without it: checked here, where root lacks it);
- a higher nice value, unless `CAP_SYS_NICE` or `RLIMIT_NICE` allows lowering it back (checked as an unprivileged
  user: `nice => 5` gives ENOTSUP, and `drop` drops it);
- a CPU limit this process has used up already (it would get `SIGXCPU`);
- ignoring `SIGCHLD` (the module's other children ending meanwhile would be reaped by the kernel, their statuses
  lost);
- on Windows, `rlimit` of resources with no counterpart there (below), and `sigignore`, except for what a Windows child
  does anyway:
  - `PIPE`: there is no SIGPIPE; a write into a closed pipe fails, as with SIGPIPE ignored;
  - `INT` when the child is in a new process group (`new_group`; since post-0.12 decided by the child's SIGINT, W7, so
    `sigignore` of `INT` itself gives the child a new group). Windows turns Ctrl-C off in a new group, and Perl's
    `kill INT`, `GenerateConsoleCtrlEvent(CTRL_C_EVENT, pid)`, does not reach it.

  Other signals reach a Windows child only as Perl's `kill`: `TERM` and `BREAK` as Ctrl-Break (the child's default
  ends it), anything else as `TerminateProcess` (`win32/win32.c`, `terminate_process`). None of them can be ignored
  there.

**Failing as the child would:**
- a lower nice value without privilege: `EACCES`;
- a limit above this process's hard limit without privilege: `EPERM`;
- an unknown resource: `EINVAL`;
- a signal both in `sigignore` and in `sigdefault`, `SIGKILL`, `SIGSTOP`: `EINVAL`.

**A memory limit** (`AS`) lower than what this process uses makes glibc's posix_spawn fail (`ENOMEM`: it maps the
child's stack in this process's address space), where a child setting it before exec would not. Checked: `AS` 10 MB
fails, this process's limit is put back, later calls work; with fork and exec (M2) the same call succeeds.

**Threads.** On Linux `nice` and the signal mask are per thread, so only the calling thread sees them; the signal
actions and the limits belong to the whole process (so they are safe only in a program with one thread, as the umask
is). A signal arriving meanwhile stays pending (Linux keeps a blocked signal pending although it is ignored) and is
delivered after.

### <a id="my-nice-and-rlimit-on-windows-w4"></a>`nice` and `rlimit` on Windows (W4)

(post-0.09; the user, 2026-11-08, decision W4: "(c) and (b); (c) beats (b) if present")

**Windows' own settings**, exact, per child:
- `win_priority`: a priority class (`idle`, `below_normal`, `normal`, `above_normal`, `high`, `realtime`), set with
  `SetPriorityClass` on the child while it is still suspended (Wine ignores the class given as a creation flag;
  Windows honours both);
- `win_job`: limits of a job of the child's own: `ProcessMemoryLimit`, `JobMemoryLimit` (in bytes of committed
  memory), `PerProcessUserTimeLimit`, `PerJobUserTimeLimit` (in 100-ns ticks of user time), `ActiveProcessLimit`. The
  job is nested in the `kill_with_parent` one when that is on (which needs Windows 8), and is closed with the child's
  handle.

**`nice` mapped to a class**, approximately: the nice value of this process's class plus the increment gives the
class. The values and ranges are Cygwin's (`winprio_to_nice` and `nice_to_winprio` in its
`winsup/cygwin/miscfuncs.cc`), since post-0.12:

| Class | Its nice value | The nice values mapped to it |
|---|---|---|
| `idle` | 16 | 12 and up |
| `below_normal` | 8 | 4 to 11 |
| `normal` | 0 | -4 to 3 |
| `above_normal` | -8 | -5 to -12 |
| `high` | -16 | -13 and below |
| `realtime` | -20 | never |

Before post-0.12, `Proc::Spawner` used a table of its own: `idle` 19, `below_normal` 5, `above_normal` -5, `high`
-10, and only 0 as `normal`.

**`rlimit` mapped to `win_job`**, approximately:
- `AS` and `DATA` to `ProcessMemoryLimit` (committed memory, not address space; the smaller wins);
- `CPU` to `PerProcessUserTimeLimit`;
- `NPROC` to `ActiveProcessLimit` (the processes in the child's job, not the user's);
- each from the soft value if set, else the hard one (Windows has one limit and ends the child at it, where Unix sends
  SIGXCPU at the soft CPU limit);
- `NOFILE`, `CORE`, `FSIZE`, `STACK` and the rest have no counterpart: unsupported.

`win_priority` and `win_job` beat the mapping where both are given.

**Elsewhere** (not on Windows):
- `win_job` is unsupported.
- `win_priority` (post-0.12, the user, 2026-11-15) is mapped the other way: the child gets the class's nice value in
  the table, as the increment from this process's value (`win_priority => 'idle'` from nice 0 is `nice => 16`). It can
  and cannot do what `nice` can and cannot do: lowering the nice value needs `CAP_SYS_NICE` or `RLIMIT_NICE`, and a
  higher one is unsupported where it could not be put back.
- `nice`, if given, beats `win_priority` there.
- An unknown class fails with `EINVAL`.

**Checked** under Wine with a child that prints its priority class: `win_priority`, `nice` 5, 15, -12, and `nice` with
`win_priority` give the classes above; a resource with no counterpart fails with `ENOTSUP` or is dropped; an unknown
class fails with `EINVAL`. Wine stores no job limits (a plain C program setting them reads back none), so their effect
is not checked here, only that the child starts with them. The mapping is tested on Linux
([`t/spawner.t`](../t/spawner.t)).

### <a id="my-no-posix-spawn-at-all-m2"></a>No posix_spawn at all (M2)

(post-0.08; the user, 2026-11-06, decision M2: as Run 0.06's forkless mode, branch `project-2026-11-03`,
`claude/Run-0.06/`)

**Fork and exec.** [`Makefile.PL`](../Makefile.PL) now probes `posix_spawn` itself (`POSIX_SPAWN`). Without it, or with
`PROC_SPAWNER_MISSING=posix_spawn` (tests), the primitive is the XSUB `__spawn_nowait`: fork and exec, in C, with
nothing in between but putting the signal mask back (as `spawnvp(P_NOWAIT)` on a system with a plain spawn; exec's
errno comes back through a close-on-exec pipe).
- Every other setting is then missing and done around the call as above (`setsid`, `pgroup => 0`, `tcsetpgrp`,
  `sched`, `cgroup` are unsupported); `rlimit`, `sigignore`, `nice` as M1.
- argv reaches the child exactly (execve).
- Checked: the whole suite passes so (its 58 tests then), and a build without posix_spawn
  (`PROC_SPAWNER_WITHOUT=POSIX_SPAWN`) passes [`t/spawner.t`](../t/spawner.t) and [`t/dash.t`](../t/dash.t).

**Without fork either: system1.** This is the case on Windows when posix_spawn is masked, on OS/2 and VMS, and on
Linux with `PROC_SPAWNER_MISSING="posix_spawn fork"`; `$Proc::Spawner::PRIMITIVE` is then `system1`. The redirections
are delegated to Run (the user, 2026-11-07: "one of the major points of the exercise"; "it must delegate the whole
code of redirection to Run"): Run 0.07, in repository `ilyaz-ai/run` (0.02 to 0.06 as released, then 0.07; on CPAN
since 2026-11-10).
- `Run::start(1, ARGV, REDIRS, ERRS, FILE)` applies the redirections in this process around Perl's own spawn,
  `system { FILE } 1, ARGV` (P_NOWAIT; on Unix Run emulates it by fork and exec), and puts this process's fds back.
- The fd actions become Run's `[FD => {fd => M}]`, `{close => 1}`, and a file opened here as
  `{filehandle => FH, pin => 1}`.
- `chdir` and `fchdir` are done here, in order, so an `open`'s relative path is taken from the directory of that
  moment.

### <a id="my-perl-s-own-spawn-on-windows"></a>Perl's own spawn on Windows

What Perl's spawn does on Windows (`win32/win32.c` of 5.38.2, `do_spawnvp_handles`, `create_command_line`), and so
what system1 gives a child there:
- **argv**: Perl builds the command line itself. An argument with blanks is put in quotes, but quotes and backslashes
  in it are not escaped, so a child sees other arguments ([the table below](#my-how-the-child-sees-its-arguments)).
  ❰BUG❱ in Perl ([`doc/perl-win32-system-bugs.md`](perl-win32-system-bugs.md), to be reported). The arguments are
  passed as they are, and the tests of exact argv and of batch files are TODO with this primitive until Perl is fixed
  (the user: no bug-for-bug workaround).
- **the program**: looked up here (PATH and PATHEXT as [`win_spawn.h`](../win_spawn.h) does it, with `search`;
  otherwise as given, relative to the directory of that moment). This is posix_spawn's meaning of FILE, not Perl's
  (which always searches PATH).
- **fds**: the child gets the standard handles of the moment (`GetStdHandle`), which the C runtime's `dup2` and
  `close` set for fds 0-2. The child sees no fds 3 and up: `dup2` or `open` onto them is unsupported; `close` and
  `closefrom` of them need nothing.
  - But Perl's spawn passes the child every inheritable handle (`bInheritHandles`, no list), and Perl makes its
    handles inheritable (no close-on-exec by `$^F` on Windows). So a child could hold, unseen, the write end of its own
    input pipe and never see end of file (X38).
  - Since post-0.10, this process's fds from 3 up are made not inheritable for the call and put back after, as POSIX
    has it (the user, 2026-11-09: "do as on POSIX"). **Not thread-safe**: a spawn in another thread meanwhile does not
    pass them either.
  - Windows' own thread-safe way is the list of handles a child gets, `PROC_THREAD_ATTRIBUTE_HANDLE_LIST`, which
    [`win_spawn.h`](../win_spawn.h) uses; Perl's spawn does not: ❰BUG❱ in Perl,
    [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md#my-section-4), 4. Its
    [section 5](perl-win32-system-bugs.md#my-section-5) lists every workaround in this distribution.
- **the rest**:
  - always a new process group (Perl gives one to every child it does not wait for, as `system 1, ...`; a child that
    `system` waits for stays in Perl's group); so `pgroup => 0` needs nothing, and a group to join is unsupported;
  - `sigdefault`, `resetids`, an empty `sigmask` need nothing (nothing is inherited);
  - a non-empty `sigmask`, `pidfd`, `fchdir` are unsupported;
  - the environment is `%ENV`, set around the call;
  - at most 64 children at once (Perl's table; `EAGAIN` after);
  - the child is Perl's, so Perl's `waitpid` takes its status.

### <a id="my-the-test-records"></a>The test records

- **Checked again** (2026-11-17, post-0.12), and recorded: [`t/flavors.pl`](../t/flavors.pl) and
  [`t/missing-matrix.pl`](../t/missing-matrix.pl), run with `-o` at each release, record only what did not pass, so a
  record of just its header means every one passed. All pass:
  - on Linux, the four approaches ([`test-results/linux-flavors.txt`](test-results/linux-flavors.txt)) and the matrix's 23
    entries ([`test-results/linux-missing-matrix.txt`](test-results/linux-missing-matrix.txt));
  - under Wine, the three approaches ([`test-results/wine-flavors.txt`](test-results/wine-flavors.txt)) and the matrix's
    14 entries ([`test-results/wine-missing-matrix.txt`](test-results/wine-missing-matrix.txt)).
- **Per test** (2026-11-18; the user: a failing TODO test, and a test skipped because the flavor cannot do a setting,
  are counted apart, where prove counts them as passed). A *flavor* is an approach of the primitive as a test run chooses
  it. [`t/flavors-outcomes.pl`](../t/flavors-outcomes.pl) records each test's outcome in one flavor, and
  [`t/flavors-compare.pl`](../t/flavors-compare.pl) puts the flavors side by side
  ([`test-results/linux-flavors-by-test.txt`](test-results/linux-flavors-by-test.txt),
  [`test-results/wine-flavors-by-test.txt`](test-results/wine-flavors-by-test.txt); the test files only). No test
  failed in any flavor. Both are of 2026-11-26 (0.14); under Wine the seven Windows test files, `t/options.t` among them.

  | Flavor | Linux: ok | Linux: skipped | Wine: ok | Wine: skipped | Wine: TODO failing |
  |---|---|---|---|---|---|
  | as built | 330 | 4 | 219 | 25 | 0 |
  | the redirections only | 318 | 16 | 219 | 25 | 0 |
  | fork | 316 | 18 | – | – | – |
  | system1 | 306 | 28 | 214 | 29 | 5 |

  - On Linux no TODO test applies, and each flavor has 334 tests. 4 are skipped in every flavor (3 are for Windows; 1
    is not for root). fork skips `pgroup => 0` and `setsid` (2 tests; refused: the child does nothing between fork
    and exec, F1 in [`TODO`](../TODO.md)), and the 12 tests of `closefrom` taken as missing, which need a posix_spawn
    that does `dup2`, `close` and `open` itself: 4+2+12=18. system1 skips those 14 and `sigignore`, `rlimit`, `nice`
    (10 tests; also refused: their wrappers in C, M1, are around `posix_spawn` and fork only): 4+14+10=28. The approach
    with the redirections only, which marks every other setting missing, skips `pgroup => 0`, `setsid` and those 10:
    4+2+10=16; the 12 tests of `closefrom` run there.
  - Under Wine, system1's 5 TODO failures all come from Perl's own spawn: exact argv and a batch file
    ([`t/windows.t`](../t/windows.t)), and three lines of [`t/portable.t`](../t/portable.t) with `"` in an argument of
    `sh` ([`perl-win32-system-bugs.md`](perl-win32-system-bugs.md), 1). Its skips: `kill_with_parent` (no job) and
    `new_group` (always a new group). Its other differing tests: fd 3 is unsupported, and at most 60 children ran at
    once there (Perl's table has 64 places; the other 4 under Wine: not traced). The flavors do not run the same
    tests (some exist in one flavor only), so their sums differ: 244, 244 and 248 under Wine.
- **Under Wine** the tests must run with Windows' own standard handles (`cmd /c "perl t\windows.t > out.txt"`): Wine's
  handles for a Linux stdout cannot be fdopened (EINVAL), which Run's saving of fd 1 needs. The earlier counts
  (2026-11-14: 179, 179 and 181 under Wine, 156 per approach on Linux; post-0.08: the suite through Run, and
  [`t/windows.t`](../t/windows.t) through both primitives) are in [`Changes`](../Changes). OS/2 and VMS are not tested.

### <a id="my-the-windows-primitive"></a>The Windows primitive

(post-0.06, EXPERIMENTAL; built into the module since 0.07, through Makefile.PL since post-0.09)

[`win_spawn.h`](../win_spawn.h) is `posix_spawn` on `CreateProcessW`, in plain C. [`Spawner.xs`](../Spawner.xs)
includes it under `_WIN32` and `#define`s the `posix_spawn` names to it, so `__posix_spawn` stays one source. It does
the Windows column of the table above:
- the child's fds 0-2 through `STARTUPINFO`, fds 3 and up through the C runtime's `lpReserved2` table;
- exactly the handles the child should have, through `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` (inheritable copies are made
  for the call, so the parent's handles keep their flags);
- the file actions in order, on a table of the child's fds (an `open` by the parent, relative to the child's
  directory);
- argv quoted as the C runtime parses it back;
- `posix_spawnp` through PATH and PATHEXT (a relative program name is taken from the child's directory, after
  `chdir`, as glibc does);
- `pgroup => 0` as `CREATE_NEW_PROCESS_GROUP`;
- `ENOTSUP` for the rest.

The process handle is kept, so the exit code survives until the child is waited for (`__win_spawn_handle`,
`__win_spawn_forget`). Checked with MinGW-w64 under Wine; compiled for x86, x64 and ARM64.

### <a id="my-compared-with-perl-s-own-spawn-on-windows"></a>Compared with Perl's own spawn on Windows

(`do_spawnvp_handles()`, `create_command_line()`, `qualified_path()`, `win32_waitpid()`, `win32_kill()` in
`win32/win32.c` of perl 5.38.2; 2026-11-05.) Fixed in [`win_spawn.h`](../win_spawn.h) and
[`Spawner.xs`](../Spawner.xs) after the comparison:
- the program without an extension: PATHEXT's extensions first, the bare name last (Perl tries `.exe` first, so a bare
  `prog`, say an MSYS script beside `prog.exe`, cannot be run); a quoted PATH entry (`"C:\a;b"`) is one entry, as Perl
  reads it;
- `cmd.exe /c` (or `/x/c`) with two or more words after it: the rest gets one more pair of quotes, which cmd strips by
  its own rules, as Perl does;
- the environment block sorted by name, ignoring case, with the parent's hidden `=C:` entries (each drive's directory)
  kept;
- a command line over 32766 characters: `E2BIG`;
- Perl strings: Perl's own `CreateProcessA` takes bytes in the ANSI code page; so a Perl string not held as UTF-8 is
  read as ANSI, one held as UTF-8 as UTF-8;
- the child's default environment and directory are Perl's (`PerlEnv_get_childenv`, `PerlEnv_get_childdir`), which
  with pseudo-forks can differ from the process's;
- memory: compiled against Strawberry Perl 5.38.2 (`PERL_IMPLICIT_SYS`), `malloc` and `free` are Perl's macros for the
  interpreter's allocator; [`win_spawn.h`](../win_spawn.h) now allocates on the process heap itself (it mixed
  allocators before). `Spawner.dll` then compiles and links against Strawberry Perl's headers and `libperl538.a` with
  MinGW-w64 (it loads: below).

**Run under Wine** with Strawberry Perl 5.38.2 (the user's approval, 2026-11-05): `Spawner.dll`, built with MinGW-w64
against its headers and `libperl538.a`, loads; `Proc::Spawner::spawn` starts Windows' `perl.exe`, an `open` action
gives it a file as stdout, Perl's own `waitpid` reaps it (status 3), and `%Proc::Spawner::WINDOWS` works. This found
two faults, fixed:
- in scalar context `spawn` gave the count of its results, not the pid (its wrapper; on Linux only when a setting is
  missing);
- `Proc::Spawner` used `fcntl` and `SIGCHLD` at load time.

Then (until post-0.10) the loop polled for ended children every `$TICK`, and pipes could not be read or written in it
(Perl's `select` there works on sockets only); since W5 it is an I/O completion port (below).

### <a id="my-how-the-child-sees-its-arguments"></a>How the child sees its arguments

A Windows `perl.exe` printing `@ARGV`, given these nine arguments: `a b`, `q"x`, `c\\`, the empty string, `x "y" z`,
`tail\`, `d\"e`, `%PATH%`, `a&b`:

| Started by | The child's `@ARGV` |
|---|---|
| Perl's own `system LIST` | two arguments: `[a b] [qx c\\ " x y z tail\ d"e %PATH% a&b]` (quotes taken as quoting, the empty one gone; a `-e` program with `"` in it does not even compile) |
| `Proc::Spawner::spawn` | all nine, as given |

### <a id="my-choices-in-proc-spawner-windows"></a>Choices in `%Proc::Spawner::WINDOWS`

Choices (the user, 2026-11-05), for every child, in `%Proc::Spawner::WINDOWS` ([`win_spawn.h`](../win_spawn.h):
`WIN_OPT_*`):

- **`new_group`**: `CREATE_NEW_PROCESS_GROUP`, where Windows turns Ctrl-C off. Default on until 0.12; **`'auto'` since
  post-0.12** (the user, 2026-11-14, decision **W7**: "Of course" to Claude's proposal; `Proc::Spawner::win_new_group`).
  - `'auto'`: a new group only for a child that would have SIGINT ignored on POSIX: `sigignore` has `INT`, or
    `$SIG{INT}` is `'IGNORE'` and `sigdefault` does not have `INT` (`Proc::ShellSpawn`'s background jobs, not its
    foreground commands). Such a child goes on after a Ctrl-C at the console, as a POSIX asynchronous list ignores
    SIGINT. Every other child stays in Perl's group and gets the Ctrl-C itself, as a POSIX child in the foreground
    process group gets SIGINT. Perl's own spawn does the same (5.38.2's `win32/win32.c`: a new group only for
    `P_NOWAIT`, `system 1, ...`).
  - `1`: every child (the old default: "the parent is the one to be killed, and it is to kill its children", the user,
    2026-11-05).
  - `0`: none.
  - Checked under Wine ([`t/win_spawn.t`](../t/win_spawn.t)), for each case: the flag Windows records for a child in a
    new group (`ConsoleFlags` in its process parameters); not with a real Ctrl-C.
- **`kill_with_parent`**: default on until 0.12; **off since post-0.12** (the user, 2026-11-14, decision **W6**: as
  Perl's own spawn, which makes no job object; `win_spawn.h`'s `WIN_OPT_DEFAULT` no longer has it either, so Perl's
  copy inherits none of it).
  - On: the child is in a job object (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`) whose only handle is the parent's, so
    Windows ends the children when the parent ends, however it ends. The child is started suspended, put in the job,
    then resumed, so nothing it starts escapes. Nothing started here outlives the parent, and the children end by
    `TerminateProcess`, with no chance to clean up. Before Windows 8, a parent that is in a job already cannot put its
    children in another one: they then run outside it.
  - Off: a child still running when Perl ends keeps running, as with Perl's own spawn and on POSIX.
  - What the defaults cost on Windows is listed for users in the POD of `%Proc::Spawner::WINDOWS`: files kept open
    cannot be deleted; the console; Ctrl-C only on this console; Perl's `kill INT/TERM/BREAK` and a child in Perl's
    group; the primitive `system1`; and Ctrl-Break, which reaches every process on the console whatever the settings.
  - Checked under Wine: a child that would write a file after 3 seconds is killed when the parent exits; with the
    option off, it writes the file. [`t/windows.t`](../t/windows.t) tests this (a child that writes a file after 3
    seconds, its parent exiting at once: the file is written by default, and not with the option on), and
    [`t/win_spawn.t`](../t/win_spawn.t) checks that the defaults make no job.
- **`new_console`** (default on, as Perl): a child with none of fds 0-2 gets a console of its own
  (`CREATE_NEW_CONSOLE`); off: it shares this process's console, with no standard handles.

### <a id="my-batch-files"></a>Batch files

Batch files (`.bat`, `.cmd`) are run (the user: most arguments can be passed safely, and the others can be
recognized):
- through the system's `cmd.exe /e:ON /v:OFF /d /c ""SCRIPT" ARGS"` (not a cmd.exe found on PATH);
- each argument quoted for cmd as Rust's standard library does since BatBadBut (CVE-2024-24576):
  - quoted unless it has only letters, digits and `#$*+-./:?@\_`;
  - `"` doubled;
  - `%` written `%%cd:~,%`, which cmd expands to a single `%`, so no `%NAME%` is expanded;
  - a trailing `\` makes it quoted too.
- Refused (`EINVAL`): an argument with CR or LF (cmd ends the line there), a script path with `"` or ending in `\`.

The script sees each argument as cmd shows it (`%1` with the quotes, `%~1` without). Under Wine, `& | < >` and quotes
arrive literally and nothing else runs; `%` does not arrive as given (Wine's cmd reads `%%` on a command line as one
`%`, real cmd does not). Not checked on real Windows.

### <a id="my-unicode-and-windows-versions"></a>Unicode, and Windows versions

**Unicode:** the child is started with `CreateProcessW` (UTF-16 command line, environment and paths); Perl's own spawn
uses `CreateProcessA` (the ANSI code page). So a Perl string held as UTF-8 reaches the child as it is, whatever the
code page; one held as bytes is read in the ANSI code page, as Perl's spawn reads it.

**Windows versions:** the explicit handle list needs Vista. Windows 7's console handles are pseudo-handles that the
list refuses, so they are left out of it (the child reaches the console through `STARTUPINFO`). Nested job objects
need Windows 8. Not tested before Windows 10 (Wine 9 imitates 10).

### <a id="my-the-kept-process-handle"></a>The kept process handle

The kept process handle is released once the loop has the child's status. Since post-0.08 `reap` calls
`Proc::Spawner::reaped`, which calls `__win_spawn_forget`; since post-0.12 `start`'s child watch calls it (from W5,
post-0.10, to post-0.12 `reaped` was missing: known issue [X59](pspawn-known-issues.md#my-x59)). A caller of
the raw `spawn` who waits itself calls `reaped(PID)`.

Checked under Wine with Strawberry Perl 5.38.2:
- one child's handle is gone after its status (in 0.08 it was still open);
- 1,100 children in a row all give their status;
- 1,100 children started before any is waited for, all ended by then: 0.09's fixed table of 1,024 kept handles lost 76
  statuses (the children whose handles did not fit were closed at once; known issue
  [X34](pspawn-known-issues.md#my-x34)). Since post-0.09 the table grows, and none is lost (checked under Wine both
  ways).

`rlimit` and `nice` failed there with `ENOTSUP`, or were dropped, until post-0.09; since W4 they are mapped (`nice` to
a priority class, `rlimit` to `win_job`). `sigignore` of PIPE, and of INT in a new group, is accepted since post-0.08
(0.09). What has no counterpart fails or is dropped.

### <a id="my-done-later"></a>Done later

**Post-0.09:**
- `Win32::SetChildShowWindow` is honoured as by Perl's own spawn (`STARTF_USESHOWWINDOW` and `wShowWindow` from
  Perl's `w32_use_showwindow`, `w32_showwindow`). Checked under Wine with a child that prints its startup info: the
  same through both primitives, before, after `SetChildShowWindow(0)` and `(7)`, and after resetting it.
- More than 64 children at once: Windows' limit of 64 handles per wait does not apply (post-0.09 the loop polled each
  child; since W5 it waits with `RegisterWaitForSingleObject`). 100 at once checked, 80 in [`t/loop.t`](../t/loop.t).
  Perl's own spawn, `system1`, still stops at 64, Perl's table.
- Building through [`Makefile.PL`](../Makefile.PL) (no POSIX probes there). Checked under Wine with Strawberry Perl's
  own gcc and gmake: `perl Makefile.PL`, `gmake` without a warning, `gmake test` of [`t/windows.t`](../t/windows.t)
  and [`t/parsers.t`](../t/parsers.t).

**Post-0.10, W5:** the loop is [`Proc::Spawner::Loop`](../lib/Proc/Spawner/Loop.pm), with a Windows backend on an I/O
completion port; how it works and what was checked: [`pspawn-loop.md`](pspawn-loop.md). The shell layer on top runs
there too since post-0.10: [`pspawn-shell-windows.md`](pspawn-shell-windows.md).

**Post-0.12, [`win_spawn.h`](../win_spawn.h) per call, with hooks.** This was asked for so that Perl's core can take
the file as its own `posix_spawn` on Windows; a patch to Perl with a copy of it is being drafted in another session.
Nothing else in what `Proc::Spawner` does changes but the meaning of a key deleted from `%Proc::Spawner::WINDOWS` (below) and the three fixes below.
- **Attributes.** What was the file's, for the whole process, is now each call's: the `WIN_OPT_*` options,
  `wShowWindow` and the job that ends the children with the parent are attributes (`win_attr_setoptions`,
  `win_attr_setshowwindow`, `win_attr_setkilljob`; defaults as before). [`Spawner.xs`](../Spawner.xs) sets
  `%Proc::Spawner::WINDOWS` over the defaults in each call, where before it changed the file's variables; so a key
  deleted from the hash meant its last value before, and means its default now. The code page of every string is an
  attribute too (`win_attr_setcodepage`: UTF-8 by default, `CP_ACP` for Perl's own byte strings).
- **Hooks.** Where the file used the process's own state, a caller may plug in its own (`win_spawn_hooks_t`,
  `win_attr_sethooks`; a member left NULL: the file's way):
  - `keep`: the child's process handle, and its own job if any, go to the caller's table instead of the file's
    (Perl's `waitpid`, `kill` and `$?` know only Perl's own table);
  - `var`: `PATH` and `PATHEXT`;
  - `env`: the child's environment when `envp` is NULL;
  - `cwd`: the child's directory and the base of relative names;
  - `fd_handle`: `_get_osfhandle`;
  - `errno_of`: a Windows error as an errno.
- **The allocator** is chosen when the file is included (`WIN_SPAWN_MALLOC`, `WIN_SPAWN_REALLOC`, `WIN_SPAWN_FREE`;
  the process heap by default).
- **Threads.** The file's own job and child table are safe in several threads now
  (`InterlockedCompareExchangePointer`, an `SRWLOCK`).
- **Taken from the patch to Perl, with changes:** three options of the command line that `Proc::Spawner` does not set:
  - `WIN_OPT_CMD_RAW`: one word after `cmd.exe`'s `/c`, a command line for cmd, passed in one pair of quotes;
  - `WIN_OPT_ARGV_RAW`: the caller's own command line; no batch-file path;
  - `WIN_OPT_KEEP_QUOTED`: a word in quotes copied as it is, also inside the quotes after `/c` (the patch's version
    lost the opening quote there).

  The patch's way of handing over the process handle closed the child's own job, which ended the child at once when it
  had `win_job` limits and `kill_with_parent`; the hook `keep` gets the job too (both checked under Wine against the
  patch's file).
- **Perl's own environment and directory.** [`Spawner.xs`](../Spawner.xs) plugs in Perl's own environment and
  directory (`PerlEnv_getenv`, `PerlEnv_get_childenv`, `PerlEnv_get_childdir`, as Perl's own spawn takes them), in
  place of the `chdir` action it added before.
- **The three fixes**, found on the way in a pseudo-process (a child of Perl's fork emulation) under Wine
  ([`pspawn-known-issues.md`](pspawn-known-issues.md)):
  - X57: the program was looked up with the process's `PATH`, and a relative name from the process's directory;
  - X58: a name given twice in the environment gave either value; now the first;
  - X59: `reaped` was gone since W5.

  The child's directory and changed variables were right. A variable deleted in a pseudo-process still reaches the
  child under Wine, through Perl's own environment for a child, as with Perl's own spawn (a fault of Perl's where the
  process's environment is not sorted, as under Wine).
- **Checked** under Wine with Strawberry Perl 5.38.2.2: [`t/loop.t`](../t/loop.t), [`t/windows.t`](../t/windows.t),
  [`t/parsers.t`](../t/parsers.t), [`t/programs.t`](../t/programs.t), [`t/portable.t`](../t/portable.t) pass, and
  [`t/windows.t`](../t/windows.t) through both primitives. [`t/win_spawn.t`](../t/win_spawn.t) checks the file alone,
  through a C program ([`t/win/thooks.c`](../t/win/thooks.c), its child [`t/win/clchild.c`](../t/win/clchild.c)):
  every attribute and hook, the code page, the options of the command line (39 checks; on Windows built with Perl's
  own C compiler, elsewhere skipped unless `PROC_SPAWNER_WINE=1` with MinGW-w64 and Wine; passes both ways).
  **Not checked:** real Windows; several threads at once.

### <a id="my-proc-shellspawn-on-windows-before-its-port"></a>`Proc::ShellSpawn` on Windows, before its port

(The port came later on 2026-11-09: [`pspawn-shell-windows.md`](pspawn-shell-windows.md).)

What ran on Windows before the port: `Proc::Spawner` (the primitive, [`win_spawn.h`](../win_spawn.h)), the loop
([`pspawn-loop.md`](pspawn-loop.md)), the parsers, and the programs `Proc::ShellSpawn` runs inside Perl (X21: `echo`,
`printf`, `test`, `[`, `true`, `false`).

The shell layer itself did not. This was found under Wine on 2026-11-09, when the snippet library was to run there
([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-7), section 7, "W5"): every
`run()` died at once.
- First at `getppid` (for `$PPID`; Windows Perl has none).
- Then, past that in a scratch copy, in `Proc::Spawner::Graph` at `fcntl` with `F_GETFL` (a handle's mode).
- And the graph's pipes were made as FIFOs and reopened through `/proc`, which Windows lacks too.

The port takes `$PPID` from `NtQueryInformationProcess` and does without `fcntl` and `/proc` there. Under Wine with
Strawberry Perl 5.38.2.2, on the code of post-0.10, these pass: [`t/loop.t`](../t/loop.t),
[`t/windows.t`](../t/windows.t), [`t/parsers.t`](../t/parsers.t), [`t/programs.t`](../t/programs.t) (skipped there:
Ctrl-C without a console, the comparisons with dash, bash and coreutils). The large parser, over all 45,501 extracted
corpus samples, gives the same trees and rejections as on Linux.

### <a id="my-threads-and-signals"></a>Threads and signals

**Still not done:** the inheritable copies of handles exist during the call, so another thread's `CreateProcess` with
inheritance could take them (one thread assumed).

**Signals while this process is changed.** While `spawn` changes this process's fds or directory for a call, every
signal is blocked, so no signal handler of this process sees the change. Not on Windows, where Perl has no such
signals to block (X64); there the primitive has the child's (empty) `sigmask` natively. If `sigmask` is missing too, the signals
cannot be blocked without the child inheriting that: then a handler running in that moment would see the changed fds.

**The matrix.** [`t/missing-matrix.pl`](../t/missing-matrix.pl) runs the whole suite:
- once per setting the primitive does natively on this platform, with that setting missing (19 on Linux with glibc
  2.39, the M1 settings `rlimit`, `sigignore`, `nice` among them, which the XSUB itself sets around the call, in C; 11 on Windows);
- then with all emulable settings missing, with the Windows column's gaps, without posix_spawn, and with everything
  missing.

An entry that would be the same run as the tests as built, or as an entry before it, is skipped, and said so. Run: 14
entries under Wine, 23 on Linux.

- **Testing on Linux "as on Windows":** done: `PROC_SPAWNER_MISSING` and [`t/missing-matrix.pl`](../t/missing-matrix.pl)'s
  entry with the Windows column's gaps (above).
