# Proc::Spawner and its graph: the split of the executor (2026-11-02)

**Status: EXPERIMENTAL.** The user endorsed every choice experimentally (2026-11-02, 00:24) and asked for this split (00:32: "Please start"). The decisions taken while writing it, G1–G6 in section 6, are experimental too and wait for approval.

Until 2026-11-01 one module, `ShellSpawn`, did everything: the shell, the starting of children, the event loop, and a graph that only recorded and drew what happened. Now there are three layers, and the graph is what gets executed:

| Module | Lines | What it does | Depends on |
|---|---|---|---|
| `lib/Proc/Spawner.pm` (+ `Spawner.xs`) | 148 code lines (230 with its POD) | starts a child with a given fd table and any posix_spawn setting; runs the one event loop that reports "a child ended", "an fd is readable/writable"; its XS part is the former binding `PosixSpawn` | – |
| `lib/Proc/Spawner/Graph.pm` | 263 | the graph: open files (ends) with hold counts, process nodes, Perl's own reads and writes; each process carries what to do when it ends; the notation, pictures, running hand-written graphs | `Proc::Spawner` |
| `lib/Proc/ShellSpawn.pm` (+ `ShellSpawn/Large.pm`) | 638 (+199) | only the shell: words, redirections, contexts, builtins, traps, jobs | both |

`lib/SpawnGraph.pm` is gone; its notation, drawing and runner are in `Proc::Spawner::Graph`.

**Renamed 2026-11-02, 07:30 (the user: "`PosixSpawn` should be subsumed by `Proc::Spawner`. The rest should be put into `Proc::`"; names option A).** One distribution, `Proc-Spawner`, built at the top of the bundle with `perl Makefile.PL && make`. Older docs use the old names:

| Old name | New name |
|---|---|
| `PosixSpawn` (XS binding, its own directory and Makefile.PL) | part of `Proc::Spawner`: `Spawner.xs` at the top; the raw call `PosixSpawn::spawn` is now `Proc::Spawner::spawn`, an alias of the XSUB `__posix_spawn` (the user: the same interface should have a chance to work on POSIX and Windows, so no `posix_` in its name), with a sixth, optional argument `{ OPTION => 'drop' | 'fail' }`: what a port lacking an option (Windows) does with it, defaults in `%Proc::Spawner::UNSUPPORTED` (`'*' => 'fail'`, EXPERIMENTAL); the call with the fd table and `on_exit`, formerly `spawn`, is now `start`; `fpe_at_exec`, `chld_to_fd`, `chld_restore` are in `Proc::Spawner` |
| `ShellSpawn`, `ShellSpawn::Large` | `Proc::ShellSpawn`, `Proc::ShellSpawn::Large` (`lib/Proc/`) |
| `ShellSubset`, `ShellSubsetSmall`, `ShellSubsetLarge` (in `parser/`) | `Proc::ShellSubset`, `Proc::ShellSubset::Small`, `Proc::ShellSubset::Large` (`lib/Proc/`); the test scripts are in `t/parser/` (since 09:58) and find `lib/` themselves |

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

Example (from `t/spawner.t`): `echo hello` writes into pipe 1. When it ends, its handler starts `cat` reading pipe 1 and writing pipe 2, which Perl reads.

```perl
my $g = Proc::Spawner::Graph->new;
my ($r, $w) = $g->new_pipe; my ($pr, $pw) = $g->new_pipe;
sub then_cat { my ($g, $node, $st, $r, $pw) = @_;
  $g->start('/bin/cat', ['cat'], undef, { 0 => $r, 1 => $pw });
  Proc::Spawner::Graph::release($_) for $r, $pw }
$g->start('/bin/sh', ['sh', '-c', 'echo hello'], undef, { 1 => $w }, on_exit => ['main::then_cat', $r, $pw]);
Proc::Spawner::Graph::release($w);
```

**Hand-written graphs** in the notation (`sgraph/*.sg`) now run on this engine. `after P1 fail` becomes a named handler on P1 (`Proc::Spawner::Graph::then`) that starts the processes waiting for P1, or marks them `never` and releases their ends. `sgraph/run-graph.pl` checks every process's fds with the reporter program: 17 of 17 processes as drawn (6 examples).

**Pictures.** `Proc::Spawner::Graph->new(dot => DIR)` writes the graph after every event (start, exit, close) as `DIR/trace-001.dot`, …; the executor does this with `TRACE=dot`.

## 3. How ShellSpawn uses them

- One graph for the whole program, `$ShellSpawn::G`, so a background job that outlives `run()` stays in it.
- A context's map (child fd → end) is the `MAP` given to `$G->start`. Contexts hold and release ends as before.
- Each child's node carries the shell's continuation: `on_exit => ['ShellSpawn::resume', K]`, and `resume` calls `K` with sh's `$?`.
- `$( … )`, `read` and here-documents are `perl_read` and `perl_write` nodes.
- What stays shell-specific is in `ShellSpawn::spawn`: the PATH search and its messages, the environment, which signals children get back as default, the ENOEXEC fallback to `/bin/sh`.

## 4. Behaviour changes

1. **Only our own children are reaped** (G2). The loop calls `waitpid(PID, WNOHANG)` for each child it started, instead of `waitpid(-1, …)`. So it no longer takes the statuses of the caller's own children (finding C2). If other code takes a status of ours first, the child is reported with status undef instead of being waited for forever; the shell gives `$?` = 1 for it (G3).
2. The trace says `reaped PID: wait status W` (the raw status) instead of sh's `$?`.
3. In pictures, an ended process shows `exited N` or `signal N`, and the Perl node also shows Perl's writes (here-documents), not only its reads.

Nothing else changed: on every battery the old and the new executor print the same output, messages and status for all 234 command lines (only pid lengths differ).

## 5. Tested

In 0.03 (2026-11-03), `t/dash.t` gives: `largebattery.txt` 111 of 114 agree with dash, `battery.txt` 42/43, `fdbattery.txt` 14/14, `sigenv.txt` 12/12, `t1.txt` 39/45, `t2.txt` 42/44 (one line's order varies, as in dash), `t3.txt` 16/17, `pspawn-d2.txt` 9/10, `pspawn-l10.txt` 6/9, `large-subset-b13.txt` 37/38; every other line is a known difference (`t/dash-known.txt`). Post-0.03 adds `large-subset-p6.txt`: 19 of 19 (21 of 21 in post2-0.03); the other batteries, run again on post-0.03, give the same counts as 0.03. In 0.04: `largebattery.txt` 108 of 114 (three lines more now differ from dash on purpose: `getopts` leaves `OPTARG` unset, rule E), `large-subset-p6.txt` 25 of 25, and the new `large-subset-e.txt` 2 of 10 (the other 8 are rule-E choices listed in `t/dash-known.txt`); the rest as in 0.03. The counts below are pre-0.01 (2026-11-02).

- `t/spawner.t`: 20 tests (32 since 2026-11-02, 08:00: every posix_spawn setting, and the raw `spawn`) of `Proc::Spawner` and the graph: fd tables (including colliding fd numbers), closed fds, `chdir`, `umask`, ignored signals and `sigdefault`, exit and signal statuses, a 1 MB write by Perl without blocking, R1 (reactions never interleave), D2, "nothing left to wait for", a status taken by other code, a handler starting the next process. All pass, with the C handler and with the fallback.
- Against dash, as before the split: `largebattery.txt` 99/103 (106/110 after the 7 lines added for L6–L8, see the known issues), `battery.txt` 42/43, `fdbattery.txt` 14/14, `sigenv.txt` 12/12, `t1.txt` 39/45, `t2.txt` 43/44, `t3.txt` 16/17. The same numbers as before also with `PARSER=small` and `PARSER=base`.
- `hyg.pl`: parent fds unchanged, no zombies. `mem.pl` on four commands and `sigprobe/mem-large.pl`: RSS flat over 1,500 runs. After 6,500 runs the graph holds 1 process node. `sigprobe/exec-stress.pl`: 9,750 children in 15 s, finished normally. `large-subset-difffuzz.pl`, seeds 7, 11, 23 × 200: one difference, the order of lines from parallel pipeline elements, which dash varies too.
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
- posix_spawn also cannot make a child **ignore** a signal (it inherits what Perl ignores), nor set **resource limits** or the **nice** value.

- Windows (W1–W3, section 8), to be written in `Proc::Spawner` now that it exists; cannot be tested here.
- Known issue X15: the shell layer still breaks some cycles by hand (contexts in their scopes). The two new modules have none.
- `Proc::Spawner` is still loaded from `lib/`, not packaged as a distribution; the binding `PosixSpawn` is separate.

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
- **Not implemented:** `umask`, a non-empty `sigmask`, ignoring signals in the child, `pgroup => PGID` (joining a group), `setsid`, `tcsetpgrp`, `sched`, `cgroup`.
- **Already defined by Perl on Windows, so used as they are:** the command line built from the argument list (`create_command_line()`, the quoting of multi-arg `system`), the status (`((U8) exitcode) << 8`, from `win32_waitpid()`), and waiting for children (`win32_msgwait()` over the process handles).
- **Testing on Linux "as on Windows":** a runtime list of what the platform lacks (empty on Linux, the list above on Windows, settable in tests), consulted where the XS now consults the missing extensions; a test then runs the batteries with the Windows list. argv and exit statuses need no test of ours: they are Perl's.
