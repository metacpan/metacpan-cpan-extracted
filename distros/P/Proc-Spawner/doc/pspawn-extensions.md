# ShellSpawn: extension points, and the large subset (2026-11-01)

**Status: EXPERIMENTAL; approved experimentally by the user on 2026-11-02 (00:24): "I (experimentally) endorsed every choice of yours."** On 2026-11-01 (16:08) the user decided one thing: handlers in the parse tree are named by **sub names**, not code references. He left everything else to Claude ("decide yourself"), and asked that those decisions be marked experimental and awaiting his approval. They include D1–D3, first proposed on the page "Child Exit Wake-up" (https://claude.ai/artifact/Rh3UW8TSzNFbMPnonbx4vz). Section 6 lists every such decision in one place.

**Words and IDs used here.**
- The *binding* is `PosixSpawn`, the project's XS module for posix_spawn.
- The *loop* is the executor's one place that waits (in `select`) for children to end and for pipes Perl itself reads or writes. A *reaction* is one continuation that the loop takes from its queue and runs; reactions run one at a time.
- A handler's arguments:
  - CONTEXT: the executor's per-command state (the fd table, and in `{sh}` the shell's variables, functions and options);
  - NODE: the parse-tree node;
  - TAIL: the contexts to release once the last process this node may start has started (or undef);
  - K: the continuation, called with the exit status;
  - ARGV and ENV: the expanded words and the settings written before the command;
  - DATA: what the command table stored with the name.
- IDs from other documents:
  - A4, A5 and U2: the run-time rules and a parser rule of [`large-subset/large-subset-spec.md`](large-subset/large-subset-spec.md);
  - B1, D1–D3 and R2: items of the page "Child Exit Wake-up";
  - E21, X2 and X15: [`pspawn-known-issues.md`](pspawn-known-issues.md).
- Files named in section 7 are in the bundle's top directory.

Code: `lib/ShellSpawn.pm` (the executor, also `claude/pspawn-ShellSpawn.pm`) and the new `lib/ShellSpawn/Large.pm` (also `claude/pspawn-ShellSpawn-Large.pm`), in the bundle `claude/pspawn-tree.tar.gz-base64.txt`. The bundle's `parser/` now holds `ShellSubsetLarge.pm` too.

## 1. What the executor runs now

`ShellSpawn::run(STRING, parser => CODE)` parses STRING with CODE, which returns a tree or an error hash; the same CODE reads the text of `eval`, `.` and trap actions. `run(TREE)` takes a ready tree. The user's decision of 2026-11-01 (19:39): the caller passes the parser, with a reasonable default. The default (Claude's choice, EXPERIMENTAL): the largest of `ShellSubsetLarge`, `ShellSubset`, `ShellSubsetSmall` that the caller has already loaded; if none is, `ShellSubset` is loaded. The executor loads no parser otherwise, and none of the three parsers needs a larger one (`ShellSubsetLarge` builds on `ShellSubset`). [`try.pl`](../t/try.pl) takes `PARSER=small`, `base` or `large` (default `large`). The large subset is [`large-subset/large-subset-spec.md`](large-subset/large-subset-spec.md): functions, `local`, `return`, `export`, `readonly`, `exec` anywhere and with redirections only, here-documents, positional parameters, `$#`, `$@`, `$*`, `$$`, the `${N=w} ${N?w} ${N%p} ${N#p}` forms, assignments in `$(( ))`, and the builtins `set shift eval . trap wait umask command getopts unset`, `cd -`, `kill … $$`.

## 2. The extension points

A handler is a sub named by its fully qualified name, such as `ShellSpawn::Large::b_shift`. The name is looked up at first use, and its module is loaded then (`ShellSpawn::handler`). A name, unlike a code reference, prints readably in a dumped tree, can be passed to another `perl` process, and cannot capture the tree, so it cannot form a reference cycle.

There are three kinds:

1. **Command nodes.** A node `{ ext => NAME, … }`, or a node with one of the keys of `%ShellSpawn::KIND` (`func export readonly local exec`, mapped to `ShellSpawn::Large::x_func` and so on). Called as `NAME->(CONTEXT, NODE, TAIL, K)`, like the executor's own `x_…` subs.
2. **Command names.** `%ShellSpawn::CMD` maps a name to `[NAME, DATA]`. The shell's own table `$context->{sh}{cmd}` is searched before `%ShellSpawn::CMD`; it holds the functions defined so far. Called as `NAME->(CONTEXT, ARGV, ENV, K, DATA)`, where CONTEXT holds the command's redirections. The old builtins (`: exit break continue read`) are in the table too. Every builtin left to sh (`alias`, `fc`, …) maps to `ShellSpawn::Large::b_unsupported` (A4).
3. **Word parts.** A Part `[ext => NAME, …]`, called as `NAME->(CONTEXT, PART, K)` with `K->(TEXT)`. No parser emits these yet. The limit of word parts: a handler passes one string to K, so it cannot make several fields, as `"$@"` must; that is why `$@` is in the core (section 3).

The rules for every handler:
- It calls K exactly once, now or later, or it ends the shell instead (`ShellSpawn::leave`, or `ShellSpawn::fail` after a message).
- It never waits (D2): it starts what it needs and continues in a callback.

The functions a handler may use (the "context API") are the executor's own: `var setvar expand expand_str each_async x_list x_cmd redirect spawn find_cmd msg defer leave fail hold release release_ctx release_all on_read on_write`.

## 3. What went into the core, and why

These change behaviour in many places, not at one node, so they are hooks in [`ShellSpawn.pm`](../lib/Proc/ShellSpawn.pm):
- **Parameters:** `$0` (`sh`), `$1`…, `$#`, `$$` (the PID of the Perl process, read once at the start of `run()`, the same in subshells), `$*`, and `"$@"`, which makes one field per parameter. A function call gets its own parameters.
- **The new `${…}` forms.** `${N%p}` and the like use the same pattern code as `case`. In an unquoted `${N:-w}`, quoted text (`["'", …]` parts) is not split.
- **`$(( ))`:** assignments (`= += -= *= /= %= <<= >>= &= ^= |=`), positional parameters, `$#`, `$$`.
- **Here-documents:** Perl writes the body into a pipe that the command reads. This uses the new loop primitive `on_write`, the counterpart of `on_read`; it never blocks.
- **`set` options:**
  - `-e` acts after an and-or list, not for conditions, the left side of `&&` and `||`, or `!` (a context flag `cond`);
  - `-u` on reading a variable;
  - `-f` in globbing;
  - `-C` in `>`;
  - `-a` in every assignment.
- **`readonly`:** checked in every assignment. A failing assignment ends the shell with status 2 (A5), and the commands after it do not run.
- **`umask`:** the shell keeps its own. The executor sets it only around each spawn and each file it opens, so Perl's own umask stays as it was.
- **Other changes:**
  - `cd -` uses and sets `OLDPWD`.
  - `exec cmd` ends the shell after the command.
  - A command whose words all expand to nothing still does its redirections (`x=; $x >f` creates f).
  - The EXIT trap runs once when a shell ends, also after `exit`; an `exit` inside it ends it there.
  - Subshells keep only ignored traps, as sh does.

## 4. What went into the plug-in module `ShellSpawn::Large`

- **Command nodes:** `x_func`, `x_export`, `x_readonly`, `x_local`, and `x_exec`, which applies the redirections to the current shell for the rest of the string.
- **Functions:** `call` runs the body in the current shell, with a frame. The frame holds the variables to put back (those of `local`, and the temporary assignments written before the call, as in `x=1 f`) and its return continuation. A `break` in a function body does not leave a loop that encloses the call. `b_return` uses the frame.
- **Builtins:** `b_shift`, `b_set`, `b_eval`, `b_dot`, `b_trap`, `b_wait`, `b_umask`, `b_command`, `b_getopts` (dash's `OPTIND` inside grouped options), `b_unset`, `b_kill`, `b_unsupported`.

## 5. Choices of behaviour (all as dash; checked against dash 0.5.12)

- Settings before a special builtin (`: . eval exec exit export readonly return set shift trap unset`, …) stay set afterwards. Before a function, they hold for the call only, and are exported to its commands. Before other builtins and programs, they are for that command only.
- `kill -SIG … $$`:
  - a trap for SIG runs it;
  - `trap '' SIG` ignores it;
  - otherwise the whole string ends: `run()` returns 128 + the signal number and sets `$ShellSpawn::SIGNALLED`. [`try.pl`](../t/try.pl) then kills itself with that signal, so its caller sees a death by the signal, as with `sh -c`.
- Traps for real signals are installed in `%SIG` while `run()` runs, as deferred handlers. They queue the action, which runs between two reactions. `run()` puts the old settings back.
- A signal ignored with `trap '' SIG` stays ignored in children.
- Error messages follow dash's wording ("x: is read only", "shift: can't shift that many", "x: parameter not set", "Illegal option -x", …), with the prefix `sh:`.

## 6. Decisions taken by Claude (all EXPERIMENTAL; endorsed experimentally by the user, 2026-11-02)

| ID | Decision | Where |
|---|---|---|
| D1 | Option A: a C handler for SIGCHLD in the binding (`PosixSpawn::chld_to_fd`, `chld_restore`) writes the wake-up byte; `select` waits without a timeout. B1's stop-gap (a deferred Perl handler, and `select` waking every 50 ms) stays as the fallback, used only if the binding lacks the function. | `loop_until`, `turn` |
| D2 | A wait started inside a reaction (a call into the loop, such as `run()`, from a queued continuation) dies: "ShellSpawn: wait inside a reaction". Before, it was allowed. | `loop_until` |
| D3 | No change: the SIGCHLD handler is installed only while the loop waits, and the previous one is put back when the loop returns. | `loop_until` |
| E1 | Three kinds of extension point, and their calling conventions (section 2). That they are named by sub names is the user's decision, not Claude's. | section 2 |
| E2 | The split between core hooks (section 3) and the plug-in module (section 4). | |
| E3 | Replaced by the user's decision of 19:39: the caller passes the parser (`run(STRING, parser => CODE)`). Claude's part: the default is the largest parser already loaded (section 1). A4 (stop with status 2 when something unsupported shows up only at run time) then applies only where the caller chose `ShellSubsetLarge`, or loaded it. | `run`, `default_parser` |
| E4 | `run()` reports a death by `kill … $$` as 128 + N plus `$SIGNALLED`, not by killing Perl. | `run`, `b_kill` |
| E5 | Signal traps act only between reactions, and only while `run()` runs. | `b_trap` |

To reject one of these, say which. D1 falls back to B1's stop-gap by removing the C handler; D2 to allowing nested waits; E3 to `ShellSubset::parse`. The others need a new design.

## 7. Tests (2026-11-01)

- **[`largebattery.txt`](../t/batteries/largebattery.txt):** 103 lines of the new constructs, compared with dash by `compare.pl`. `compare.pl` now reads `@N` as a newline and `@T` as a tab, for here-documents. **99 agree** (evening, after the fixes L1–L5 and the parser's `for NAME` without `in`, `claude/large-subset-forall.patch`). The other 4:
  - two strings the parser rejects: `$((y=2, 3))`, and settings before `export`;
  - `$0` is `sh` by the spec, while dash names itself;
  - a builtin left to sh, named only at run time, stops with status 2 (A4).
- **The older batteries, with the large grammar** (pre-0.01; the counts of 0.03 are in [`pspawn-spawner.md`](pspawn-spawner.md), section 5):
  - [`battery.txt`](../t/batteries/battery.txt) 42/43 (was 41: `wait` now works);
  - [`sigenv.txt`](../t/batteries/sigenv.txt) 12/12 (was 11: `umask`);
  - [`t1.txt`](../t/batteries/t1.txt) 39/45 (was 35);
  - [`fdbattery.txt`](../t/batteries/fdbattery.txt) 14/14, [`t2.txt`](../t/batteries/t2.txt) 42/44 (the known flaky order), [`t3.txt`](../t/batteries/t3.txt) 16/17 (`echo .*`, U2).
- **Other checks:**
  - `hyg.pl`: parent fds unchanged, no zombies.
  - `mem.pl`: flat.
  - [`sigprobe/mem-large.pl, now t/memory.t`](../t/memory.t): 1,500 runs of functions, `local`, traps, here-documents, `eval`, `getopts`, `wait` and arithmetic assignment, with RSS flat (12,176 → 12,196 kB). This found the arithmetic leak E21 of [`pspawn-known-issues.md`](pspawn-known-issues.md).
  - [`sigprobe/exec-stress.pl, now t/stress.t`](../t/stress.t): passes.
  - `large-subset-difffuzz.pl` (the ShellSubsetLarge session's random strings, run under dash and the executor): 1,800 strings, 1,636 in the subset, 7 differ. Five differ only in the order of lines from parallel pipeline elements (X13), one only in a message prefix in the middle of a line (the script strips prefixes only at line starts), and one is X2 (`$!` of a job that starts no process).
  - Parser tests (pre-0.01): 222/0, 612/0, 142/0.

## 8. Not done, limits

- **Reference cycles broken by hand.** The executor still breaks some of its own cycles by hand at the end of a run (`release_all`, `%$c = ()` in `run`), against the user's rule (known issue X15). They go away in the restructuring below.
- **The restructuring:** a minimal `Proc::Spawner` with the executable graph in a companion module (page "Child Exit Wake-up", R2). Done 2026-11-02: [`pspawn-spawner.md`](pspawn-spawner.md).
- **Word-part handlers** return one string (section 2).
- **`exec` with redirections only,** inside a group or `if` that has redirections of its own, changes only that group's fds; in dash it changes the shell's.
- **`$!`** is empty when a background job starts no process before the `&` returns (X2). So `(exit 3) & wait $!` differs from dash.
