# Run: shortcomings found, and the fixes so far (2026-10-30 to 2026-11-01)

`Run` is the user's process-spawning module (`Run-0.04.tar.gz-base64.txt` in this project), studied as a back end for executing ShellSubset parse trees. This document collects what was found wrong or missing, and what was fixed in the versions made in this project (0.05 and 0.06, `claude/Run-0.05.tar.gz-base64.txt`, `claude/Run-0.06.tar.gz-base64.txt`). The detailed history is in `claude/run-executor-investigation.md` and `claude/run-executor-upstream-reports.md`; the redesign discussion is on the checklist pages "Run 0.07 Jobs" and "Run Graph API".

Since 2026-11-01 the executor for the simplest scenario uses posix_spawn(3) instead (`claude/pspawn-design.md`). Run stays relevant where there is no posix_spawn (Win32, OS/2), see the last section.

## 1. Bugs, all fixed

| ID | Shortcoming (0.04) | Fix | In |
|---|---|---|---|
| R1 | `new_system('a b')` with one element went through `system STRING`: shell metacharacters reached `/bin/sh`, and a program name with a blank was split. | Tree nodes always use `exec { PROG } LIST` / `system { PROG } LIST`; the exported `spawn` keeps the builtin's one-string meaning. | 0.05 |
| R2 | File targets were opened with 2-argument `open`: `-` meant STDOUT, `&1` meant a dup, leading blanks were dropped, `<>` could not create a file. | `{filename => NAME, mode => OP}` opens NAME literally with sh's `< > >| >> <>` (sysopen). The old form stays. | 0.05 |
| R3 | `$data->{result}` was set only on failure and never reset; `new_chain` failed if any command failed. | `result` is the `$?` of every command (0 included) or -1 if nothing started; `new_chain` succeeds iff its last command does. | 0.05 |
| R4 | `new_readpipe` never reaped its kid (one zombie per call; status lost). | The kid is reaped and its status kept. | 0.05 |
| R5 | Forkless: the exec-error pipe of the emulated spawn could land on an fd that a redirection had just closed under a Perl handle; PerlIO counted two owners, never closed the fd, and the parent hung. Seen only under `prove`, depending on which fds were free. | `close_fd()` closes such handles at the fd level too. 30 of 62 fd placements hung before, none after. | 0.06 |
| — | An exec failure was reported twice (and warned under `-w`); messages showed a stale `$!`. | One message, no stale `$!`. | 0.05 |
| — | First draft of `new_pipeline` (0.05): a `die` inside a forked copy escaped it; its messages were lost; `result` was stale in error paths. Found by a cold review. | Fixed before 0.05 was published. | 0.05 |

## 2. Design limits of the 0.04 tree layer

- **No exit statuses in the API.** `run` returned 1 or undef. (0.05: statuses in `$data->{result}`. Decided for the redesign: a dualvar, true iff success, numeric value `$?`.)
- **No multi-stage pipelines, and nothing but a single program in the background or in a pipe.** `new_pipe('w', new_or(A, B))` refused ("cannot 'or' with spawn"). (0.05: `new_pipeline`, which runs one compound element in the parent with its pipe ends kept open until it ends, and further compound elements in forked copies of Perl.)
- **No continuations.** A tree ran by recursion, waiting for each command. So, without fork, a pipeline could contain only one compound element, a background chain (`a && b &`) was impossible, and `$( a; b )` with more output than a pipe holds would deadlock.
- **Ends kept open too long.** 0.05 kept a compound element's pipe ends until its last command had *ended*. The rule decided since (your message of 2026-10-30, 18:39): close the parent's copy of an end once every process that could use it has *started*.
- **`$( … )` kept trailing newlines** (documented behaviour, unlike sh).

## 3. Problems of the environment, with the remedies found

- **Other code collecting Run's children** (`wait`, `waitpid(-1, …)`, a SIGCHLD handler looping over `waitpid(-1, WNOHANG)`): Run's status is lost. Remedies: wait only for own pids (decided); override `CORE::GLOBAL::wait`/`waitpid` to stash Run's statuses, as Perl does internally with `PL_pidstatus` on builds without `waitpid` and on OS/2 (tested; does not cover `POSIX::waitpid` or XS code).
- **`$SIG{CHLD} = 'IGNORE'`** makes the kernel discard children's statuses. Remedy (tested): while Run has children, Run's own handler (installed with `SA_RESTART`) reaps them and acts out the caller's setting for the caller's children. Side effect: `sleep` and `select` in the caller return early when a child ends. Alternative on Unix: a watchman process per child that reports the status through a pipe.
- **Signals ignored by the Perl program** (`$SIG{PIPE} = 'IGNORE'`) stay ignored in children: `yes | head -1` would not end by SIGPIPE. Remedy: reset them in the child (posix_spawn's `sigdefault`), except those already ignored when the module was loaded (inherited from the environment, as sh keeps them).

## 4. What stays relevant if posix_spawn is used

- Win32 has no posix_spawn: Run's forkless path (redirections applied in the parent around `spawn`, the "wraparound") remains the way there, with its limits: other threads see the redirected fds; on Win32 a kid gets only fds 0–2.
- The redirection-order rules (outer redirections, then the pipe, then the command's own) and the fd-number conflicts (a source fd that is also a target) apply to both; `claude/pspawn-design.md` section 4 shows how the posix_spawn executor resolves them with scratch fds.
- The tests written for Run (`t/fdtable.t`, `t/pipeline.t`, `t/forkless.t`) document cases that any executor must get right.
