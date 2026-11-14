# ShellSpawn: running ShellSubset parse trees with posix_spawn (2026-11-01)

Code: `claude/pspawn-tree.tar.gz-base64.txt` (`base64 -d`, `tar xzf`): `PosixSpawn/` (XS binding), `lib/ShellSpawn.pm` (the executor), [`try.pl`](../t/try.pl), `compare.pl`, [`battery.txt`](../t/batteries/battery.txt), [`fdbattery.txt`](../t/batteries/fdbattery.txt), `fds`, `hyg.pl`, `traces.txt`; since 2026-11-02 the executor runs on [`lib/Proc/Spawner.pm`](../lib/Proc/Spawner.pm) (starting children, the event loop) and [`lib/Proc/Spawner/Graph.pm`](../lib/Proc/Spawner/Graph.pm) (the executable spawn graph), both EXPERIMENTAL and described in [`pspawn-spawner.md`](pspawn-spawner.md); hand-written graphs: `sgraph/`, described in [`pspawn-graph.md`](pspawn-graph.md); tests of the two modules: [`t/spawner.t`](../t/spawner.t); the large subset and the extension points (EXPERIMENTAL): `lib/ShellSpawn/Large.pm`, described in [`pspawn-extensions.md`](pspawn-extensions.md). The executor alone: `claude/pspawn-ShellSpawn.pm`. Build: `cd PosixSpawn && perl Makefile.PL && make`. Run: `TRACE=1 perl try.pl 'COMMAND'`.

## 1. The scenario

As decided on 2026-11-01: this module is the only code that starts children of the process; it may set `SIGCHLD` as it likes; posix_spawn is available. So: no `fork` in Perl, no wraparound, `waitpid(-1, WNOHANG)` is allowed (every child is ours).

## 2. The posix_spawn binding

Neither CPAN module exposes file actions: Proc::FastSpawn has `spawn`, `spawnp` and `fd_inherit`; POSIX::RT::Spawn has one `spawn` like `system LIST`. Hence `PosixSpawn` (XS, ~150 lines):

`PosixSpawn::spawn(FILE, \@ARGV, \@ENV_OR_UNDEF, \@ACTIONS, \%ATTR)` returns the pid, or the empty list with `$!`. Actions in order: `[dup2 => FROM, TO]`, `[close => FD]`, `[open => FD, PATH, FLAGS, MODE]`, `[chdir => DIR]`, `[fchdir => FD]`, `[closefrom => FD]` (the last three are glibc extensions). `[tcsetpgrp => FD]` (glibc). Attributes: `search` (posix_spawnp), `sigdefault => [SIGNUMS]`, `sigmask => [SIGNUMS]`, `pgroup => PGID`, `setsid => 1`, `resetids => 1`, `sched => [POLICY, PRIORITY]`, `cgroup => FD` (glibc), `pidfd => 1`. With `pidfd`, glibc 2.39's `pidfd_spawn` is used and `spawn` returns `(PID, PIDFD)`.

`PosixSpawn::fpe_at_exec()` says what Perl's own `exec` would give a child for SIGFPE: 1 ignored, 0 default, -1 this Perl leaves SIGFPE alone. Perl ignores SIGFPE for itself at startup (`PERL_FPU_INIT`) and, around `exec`, restores the disposition it found then (`PERL_FPU_PRE_EXEC`, the global `PL_sigfpe_saved`).

Facts checked on glibc 2.39 (Linux):

- A child gets only fds 0–2 by default, because Perl's own handles above `$^F` are close-on-exec.
- `dup2` from an fd onto the same number clears close-on-exec (the child got fd 4 with `[dup2 => 4, 4]`).
- Failures are reported synchronously as errno: a bad `dup2` source (EBADF), a failing `open` action, a missing program (ENOENT), a non-executable file (EACCES). A failing `open` action cannot be told apart from a failing exec, so the executor opens files itself (section 4).
- `close` of an fd that is not open is ignored.
- `posix_spawnp` searches the `PATH` of the calling process, not the one in the child's environment; so the executor searches `PATH` itself, with the command's own `PATH=` setting.
- A signal ignored in the parent stays ignored in the child unless listed in `sigdefault`.

## 3. Objects

- **End**: an fd the parent keeps open for its children: a pipe end or an opened file, always close-on-exec, with a **hold count**. A new end starts with one hold owned by its creator. When the count reaches 0, the parent closes it ("forgets" the end). The parent's own fds 0–2 are ends that are never closed.
- **Context**: a map from child fd numbers to ends (or `undef` for "closed"), plus the shell state (variables, exported names, the virtual current directory, `$?`, `$!`). A context made with a new map holds every end in it, once per entry, and releases them once.
- **Shell scope**: the main string, a subshell, a `$( … )`, a background chain, and each element of a pipeline of two or more commands. Each has copies of the shell state and its own `exit`. Contexts made in it are registered there and released when it ends, also when it ends by `exit`.
- **Loop scope**: one per loop iteration, so that `break` and `continue` release the contexts of the iterations they leave.
- **Graph nodes** (EXPERIMENTAL, since 2026-11-01): every end is also an end node of the spawn graph, and every start makes a process node with its final fd table; with `TRACE=dot` the executor writes one Graphviz picture per event. The closing rule is unchanged (hold counts). See [`pspawn-graph.md`](pspawn-graph.md).

## 4. From a command to posix_spawn

For a simple command:

1. Expand the settings (`NAME=value`, left to right, each seeing the ones before), then the words. A `$( … )` runs first, asynchronously.
2. Apply the redirections to a **copy of the context's map**, in the order written, in the parent: `n>&m` copies entry m, `n>&-` sets `undef`, `n>file` opens the file in the parent (sysopen, close-on-exec) and puts the new end in entry n. So `2>&1 >f` and `>f 2>&1` come out as in sh, by construction.
3. Builtins (`:`, `exit`, `break`, `continue`, `read`) run in the parent with that map. Otherwise: find the program in `PATH`, and spawn.
4. **File actions from the map** (`Proc::Spawner::actions()` since 2026-11-02, on fd numbers; the graph leaves out a parent fd that a child gets under its own number): for every target fd t whose end has parent fd f ≠ t, `dup2(f, t)`; for `undef`, `close(t)`. A source fd f that is itself a target with another end would be overwritten before its turn: it is first copied to a scratch fd above every fd involved, and the scratch fds are closed at the end. A target whose end is already at the same number gets `dup2(t, t)` only if the parent's fd is close-on-exec (to clear the flag). Then `chdir` if the virtual current directory is not the real one; `sigmask => []`; `sigdefault` = the signals the Perl program has set to IGNORE since the module was loaded.
5. Release the command's own opened files (their creator's holds), then the contexts in `$tail`.

Example from `traces.txt`: `echo $x 3>&1 1>&2 2>&3 >/dev/null` gives the map {1: '/dev/null' at parent fd 3, 2: our fd 1, 3: our fd 1}. Both parent fds 3 and 1 are targets with other ends, so: `dup2 3->10, dup2 1->11, dup2 10->1, dup2 11->2, dup2 11->3, close 10, close 11`.

## 5. When the parent forgets an end

Every construct is run as `x_*(context, node, $tail, $k)`: `$k` is the continuation that gets the status; `$tail` lists the contexts to release **right after the last process the construct can start has started**. That is the rule of 2026-10-30: forget an end once all processes that could use it have started.

- In a list or an and-or chain, only the last element gets `$tail`; the others pass `undef`, since something may follow. If a later element turns out not to run (`a && b` with a failing), the construct releases its contexts when it ends.
- A loop never passes a tail into its body; it releases at its end.
- A pipeline gives each element a context holding its pipe ends, with that context as its tail; a simple-command element releases it right after its spawn. The pipeline's own `$tail` is released after all elements have been launched.
- A group, `if`, loop or subshell with redirections gets a context for them, released at its tail or at its end.

Example (`traces.txt`), `{ false || cat /etc/hostname; } | wc -l >/dev/null`: the read end is closed right after `wc` starts; the write end stays open while `false` runs (because `cat` may follow) and is closed right after `cat` starts.

## 6. The loop

One loop, `loop_until(DONE)` (since 2026-11-02 `Proc::Spawner::wait_until`): runs queued continuations; reaps with `waitpid(PID, WNOHANG)` for each of its own children (until 2026-11-01 `waitpid(-1, WNOHANG)`, which took other code's statuses); then `select`s on a self-pipe written by the `SIGCHLD` handler (installed with `SA_RESTART` while the loop runs, the previous handler restored after) and on the fds being read for `$( … )` and `read`. Since 2026-11-01 the byte is written by a C handler in the binding (`PosixSpawn::chld_to_fd`; decision D1, EXPERIMENTAL, awaiting approval, [`pspawn-extensions.md`](pspawn-extensions.md)), so `select` waits without limit. The fallback, used only without that function, is a deferred Perl handler with `select` waking every 50 ms (`$Proc::Spawner::TICK`): an immediate handler corrupted Perl's heap, and a deferred one can miss a child that ends just before `select` starts waiting (known issue X14; [`perl-signals-findings.md`](perl-signals-findings.md), S1–S3). The final fix is decision D1 on the page "Child Exit Wake-up". Every continuation is queued, never called from another one, so a loop of builtins (`while :; do :; done`) runs in constant memory. Each `on_read` is one read; the callback asks again. `read` reads one byte at a time, so later commands get the rest of the input, as in sh.

`run(STRING)` returns when the foreground commands have finished. A background chain started by it goes on at once, also between `run` calls (since post-0.04, the user's choice B of question K3, 2026-11-03): while background jobs remain, `Proc::ShellSpawn` keeps a deferred SIGCHLD handler installed, which calls `Proc::Spawner::poll()` (what is ready now, without waiting) when a child ends; it keeps the program's `$?` and `$!` as they were (X55). The costs, documented: **while such jobs remain, the program's own `sleep` and `select` return early whenever a child ends** (they are interrupted by the signal; [`doc/perl-signals-findings.md`](perl-signals-findings.md), the consequence of item L5); a program's own `$SIG{CHLD}` code is called after ours, and a `$SIG{CHLD}` set later replaces ours (the jobs then go on only in later `run` calls). A chain that waits for Perl to read a pipe (`$( )`, `read`) may still stall if the writing child fills the pipe and so never ends. An `END` block finishes the jobs before Perl exits. Until 0.04 the chains went on only inside `run` and at exit (known issue X1).

## 7. Tested (2026-11-01)

- `compare.pl battery.txt`: 43 command lines (pipelines, and-or, groups, subshells, loops, `case`, `read`, `$( )`, `$(( ))`, `${x:-w}` forms, globbing, errors with their messages and statuses). 41 give the same output, messages and status as dash. The other 2 are outside the subset (`wait`, a bracket expression with an expansion).
- `compare.pl fdbattery.txt`: 14 command lines run the `fds` helper (as `./fds`; run `compare.pl` in the bundle's top directory), which prints the child's open fds and what they are. All 14 agree with dash, including scratch-fd swaps.
- `hyg.pl`: after each of 40 command lines, the parent's fd table is the same as before. No zombies are left. `yes | head -1` ends at once although Perl ignores SIGPIPE.
- A separate agent reviewed the code cold and wrote 106 more command lines ([`t1.txt`](../t/batteries/t1.txt), [`t2.txt`](../t/batteries/t2.txt), [`t3.txt`](../t/batteries/t3.txt) in the bundle). It found 15 problems, all fixed:
  - a hang when SIGCHLD interrupted `select`;
  - fds leaked by `exit` inside a loop;
  - a memory leak through reference cycles: about 75 KB per `run`, now flat over 3,000 runs;
  - `read` splitting with a non-blank IFS, backslashes and line continuation;
  - two reads on one fd;
  - `>&N` reaching the module's own fds;
  - settings seeing earlier settings across a `$( )`;
  - `$!` in subshells and pipelines;
  - `&&`, `||` and `?:` short-circuiting in `$(( ))`;
  - `[[:alpha:]]` in `case`;
  - `continue` and the loop status;
  - where error messages go;
  - an XS leak on croak.

  The remaining differences on those lines:
  - commands outside the subset;
  - arithmetic error messages worded differently;
  - dash crashing on an integer overflow;
  - `: & echo $!`, where no process was started (section 8);
  - the order of two stderr lines from parallel pipeline elements, which varies in dash too.
- Found by these tests in the parser: item P1 of [`pspawn-known-issues.md`](pspawn-known-issues.md), fixed in the project's parser on 2026-11-01.
- `compare.pl sigenv.txt`: signal dispositions, environment and identity of children (section 9).
- Rerun on 2026-11-01 (pre-0.01) after the graph objects went in: the same counts (battery 41/43 in 21 of 22 runs, see X13), `hyg.pl` clean, `mem.pl` and `xs.pl` flat. Hand-written graphs: [`sgraph/run-graph.pl`](../t/sgraph/run-graph.pl), 17 of 17 processes as drawn ([`pspawn-graph.md`](pspawn-graph.md), section 5).

## 8. Not done, or different (the current list: [`pspawn-known-issues.md`](pspawn-known-issues.md))

- Brace expansion (`brace` option) is not implemented; it dies.
- `redir_strict` (Q1's option) is not implemented: the default (dash's) behaviour only.
- `$!` is the pid of the background chain's first process (K4 option A); empty if that process had not started when the `&` returned (for example after a `$( )`).
- `exec cmd` runs as an ordinary command (the parser accepts it only where nothing can follow).
- `read`: field splitting with non-blank IFS characters is approximate.
- Error messages follow dash's wording for the cases tested; the prefix is `sh:` and there is no line number.
- Portability: `addchdir_np`, `addfchdir_np` and `addclosefrom_np` are glibc extensions (`chdir` is needed only after `cd` in a subshell). Only Linux with glibc 2.39 was tested.

## 9. posix_spawn's features: what is used (2026-11-01)

| Feature | Used | Why, or why not |
|---|---|---|
| `adddup2` | yes | every pipe end and redirection; scratch fds for conflicts (section 4) |
| `addclose` | yes | `n>&-`, and the scratch fds |
| `addopen` | no | the parent opens files itself: it can then say which redirection failed, and the commands of a group share one open file |
| `addchdir_np` | yes | when the virtual current directory (after `cd` in a subshell) is not the real one |
| `addfchdir_np` | no | would survive a renamed or removed directory (known issue X9) |
| `addclosefrom_np` | no | sh passes fds it inherited without close-on-exec, and so do we |
| `addtcsetpgrp_np` | no (bound) | job control only; fails with ENOTTY without a terminal |
| `setsigmask` | yes | always empty |
| `setsigdefault` | yes | SIGFPE unless it was ignored when Perl started (as Perl's own `exec` does); every signal Perl code has set to IGNORE since the module was loaded; SIGINT and SIGQUIT for foreground children only |
| `setpgroup` | no (bound) | a non-interactive sh puts everything in one group; needed to kill a whole background job |
| `RESETIDS`, `setsid`, scheduling, `setcgroup_np` | no (bound) | sh does not change them either; tested in the binding |
| `pidfd_spawn` (glibc 2.39) | no (bound) | a pollable fd per child would replace the SIGCHLD self-pipe; but the child is still an ordinary child, so other code's `waitpid(-1)` can still take its status |
| environment (`envp`) | yes | the exported variables (every name from `%ENV` that is an identifier, as dash; `PWD` kept up to date by `cd`) plus the command's own settings |

Signal dispositions, checked against dash with [`sigenv.txt`](../t/batteries/sigenv.txt) (11 of 12 agree; the 12th is `umask`, outside the subset): a foreground child has nothing ignored or blocked; a background child, also inside a subshell or a pipeline, has SIGINT and SIGQUIT ignored; a signal ignored when Perl started stays ignored, SIGFPE included (checked both ways with `trap '' FPE` in the parent of Perl). While `run()` runs, Perl itself ignores SIGINT and SIGQUIT, as Perl's `system` does.

Not set through posix_spawn, inherited as in sh: umask, resource limits, nice value, process group and session, controlling terminal.
