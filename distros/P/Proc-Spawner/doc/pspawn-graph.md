# The spawn graph (EXPERIMENTAL)

**Status: experimental, free to change without ceremony** (the user's notes on N7–N10 and W1–W3 of the page "Spawn
Graph Notation", 2026-11-01; a page of questions the user answered, in Proc-Spawner 0.03). Decided there, every item
N1–N10, W1–W3:

- N2, N3, N5–N10 and W1: Go;
- W2: option C;
- W3: Go, as part of `Proc::Spawner`;
- N1 has a note with a question and no mark; N4 is unmarked.

Written 2026-11-01.

**Correction, 2026-11-01 13:22.** The first version of this document described a graph that only mirrored what the
executor did, and drew it. The user wanted the graph, with what to do at each node's exit, to be what is executed.
**Done 2026-11-02:** the graph is now [`lib/Proc/Spawner/Graph.pm`](../lib/Proc/Spawner/Graph.pm), and it is what
runs; its design is in [`pspawn-spawner.md`](pspawn-spawner.md). Sections 2, 5 and 6 below are brought up to date;
sections 1, 3 and 4 still hold as written, except where a note says what changed.

The graph sits between the shell layer (the executor `ShellSpawn`, which runs the parse trees of `ShellSubset`) and the
module `Proc::Spawner`. It can describe connections that sh cannot make (item R1 of that page: "Allow any connection graph, not only those a
shell line can make").

## <a id="my-section-1"></a>1. What the graph is

- **A process node** is one start of one program (N5): its arguments and its *final* fd table.
  - Each entry of that table is an **edge**: an fd number, how the fd is used (`<`, `>` or `<>`), and an end (N3).
  - Redirections as written are not stored. The shell layer turns them into the final table, and
    `Proc::Spawner::actions` (until 2026-11-02 `SpawnGraph::actions`) turns the table into `dup2` and `close`
    actions.
- **An end node** is anything the parent can give a child under an fd number: the read or write half of a pipe, an
  opened file, or one of the parent's own fds ("Perl's fd N").
- **A pipe is its two halves** (N2), linked to each other. When the parent closes its copy of a half, the half is
  *forgotten*: nothing more can be done with it in the graph. The graph follows the OS only loosely: the OS pipe may
  be gone (every process holding it has closed it or exited) long before both its halves are forgotten here.
- **The parent itself** appears as a process named `Perl` while it reads an end (the output of `$( … )`, the `read`
  builtin).
- **Order (N6).** What a process does when it exits is the continuation the executor already has. For pictures
  (and, since 2026-11-02, for `run` of a hand-written graph: section 5), a process started from the continuation of another's exit carries `after => [THAT_PROCESS, WORD]` (WORD: that process's end, such as `exited 0`; in the notation of section 4, `fail`, `ok` or another word), drawn as a
  dashed orange arrow.

In the code, a process node is exactly the per-child "handout list" (its final fd table), and an end node is the one
object such lists share. This is the code's answer to the question in the user's note under N1; the item stays open
until the user marks it.

## <a id="my-section-2"></a>2. Code

The code is [`lib/Proc/Spawner/Graph.pm`](../lib/Proc/Spawner/Graph.pm) (since 2026-11-02; it replaces
`lib/SpawnGraph.pm`). The full list of calls is in [`pspawn-spawner.md`](pspawn-spawner.md#my-section-2), section 2.
In short:

| Calls | For |
|---|---|
| `new_pipe`, `file_end`, `parent_end`, `hold`, `release` | ends |
| `start(…, on_exit => HANDLER)` | processes |
| `perl_read`, `perl_write` | Perl's own use of ends |
| `parse(TEXT)` | the notation of N7 ([section 4](#my-section-4)) |
| `to_dot(GRAPH, CAPTION)` | pictures (N8, N9) |
| `run(GRAPH, bin => DIR)` | hand-written graphs ([section 5](#my-section-5)) |

The translation of an fd table into posix_spawn file actions is in [`lib/Proc/Spawner.pm`](../lib/Proc/Spawner.pm).

How the executor ([`lib/Proc/ShellSpawn.pm`](../lib/Proc/ShellSpawn.pm); on 2026-11-01 `lib/ShellSpawn.pm`) uses the
graph:

- The ends it keeps for its contexts are the graph's ends. Releasing the last hold closes the parent's copy and marks
  the end forgotten.
- It starts every child through the graph; the child's node carries the shell's continuation as its on-exit handler.
- An exited process stays in the graph while it shares an end, or a pipe, with a running process or with one of the
  parent's reads and writes; then it is dropped, so that a long loop does not make the graph grow.
- When an end is closed is still decided by its hold count, as before. N4's `keep` flag is not built (N4 is
  unmarked).
- The executor never adds a process to the graph before starting it, so its pictures have no dashed (not yet started)
  boxes.

## <a id="my-section-3"></a>3. Pictures: `TRACE=dot`

`TRACE=dot TRACE_DIR=DIR perl t/try.pl 'CMD'` writes one picture per event (a start, an exit, an end closed):
`DIR/trace-001.dot`, `trace-002.dot`, … Each picture is captioned with its number and the event. Render them with
`dot -Tsvg`. What the drawing shows:

- bold: a running process;
- gray, with "exited N": a finished process;
- dotted: a forgotten end.

## <a id="my-section-4"></a>4. The notation (N7)

One node per line; `#` starts a comment.

```
pipe NAME [r:forgotten] [w:forgotten]      the ends NAME.r and NAME.w
file NAME MODE PATH [forgotten]            MODE: < > >> <> >|
PROC: ARGV ... | EDGES | after PROC WORD | STATE
    EDGES: FD<END FD>END FD<>END; a + after END marks keep (only drawn: keep is not built)
    END: NAME.r NAME.w NAME, or @N for the parent's fd N
    STATE: running, exited N (for drawing); none: not started (`never`: set by `run` when the condition of `after` does not hold, section 5)
Perl: WHAT | <END                          the parent itself reading an end (>END: writing to it)
```

Arguments are split at blanks; quoting is not done yet. [`sgraph/graph2dot.pl`](../t/sgraph/graph2dot.pl) `FILE.sg`
draws a file; its output is pixel-identical to the prototype's (an earlier drawing script, not kept) for Examples 1–6 of the page.

## <a id="my-section-5"></a>5. Running hand-written graphs

`Proc::Spawner::Graph::run` starts each process with exactly its edges; fds 0–2 not among them are the parent's.

- A process with `after P WORD` is started by P's on-exit handler (`Proc::Spawner::Graph::then`): WORD `fail` needs a
  non-zero status, `ok` a zero status, any other word any status.
- A process that will never start is marked `never` and gives up its ends.
- A state written in the notation (`running`, `exited 0`) is for drawing only; `run` starts from scratch.
- The parent closes its copy of an end once no process left to start uses it.

**The checker.** [`sgraph/run-graph.pl`](../t/sgraph/run-graph.pl) `FILE.sg …` runs graphs with every program
replaced by `sgraph/reporter` (through symlinks named after the programs).

- The reporter records its argv, every open fd (what it is, its access mode, close-on-exec), SigIgn, SigBlk, its
  process group and session. Then it writes its name to every fd it may write, closes those, and reads every readable
  pipe or file to its end.
- The checker compares each process's fds with its edges, matching pipes to inodes one to one. It also checks that
  each pipe carried the names of exactly the processes that write into it.

Result, on 2026-11-01 and again on 2026-11-02 on the new engine: Examples 1–6 of the page, 17 of 17 processes as
drawn. They include the loop of Example 2, the fds 3 and 4 of Example 3, `after P1 fail` in Example 1 and Perl's own
read in Example 4. With the fd-table translation deliberately broken, the checker reports 0 of 6 processes as drawn (in the run made then; which examples it ran is not recorded).

## <a id="my-section-6"></a>6. Not done yet, and what was done since

- N4 (`keep` edges), unmarked.
- Windows (W1–W3): done, in `Proc::Spawner` ([`win_spawn.h`](../win_spawn.h); tested under Wine, not on real Windows:
  [`pspawn-spawner.md`](pspawn-spawner.md#my-section-8), section 8).
- Testing on the corpus with the reporter (X12 in [`pspawn-known-issues.md`](pspawn-known-issues.md)): closed
  2026-11-07, done another way by the run comparison, which runs every accepted corpus sample in dash, in
  `bash --posix` and in `Proc::ShellSpawn` ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-7),
  section 7).
