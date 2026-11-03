# The spawn graph (EXPERIMENTAL)

**Status: experimental, free to change without ceremony** (your notes on N7–N10 and W1–W3 of the page "Spawn Graph Notation", 2026-11-01). Decided there: N2, N3, N5–N10 and W1 Go; W2 option C; W3 Go, as part of `Proc::Spawner`. N1 has a note with a question and no mark; N4 is unmarked. Written 2026-11-01.

**Correction, 2026-11-01 13:22:** the first version of this doc described a graph that only mirrored and drew the executor. The user wanted the graph, with on-exit information per node, to be what is executed. **Done 2026-11-02:** the graph is now `lib/Proc/Spawner/Graph.pm`, and it is what runs; the design is in `claude/pspawn-spawner.md`. Sections 2, 5 and 6 below are updated; sections 1, 3 and 4 still hold.

The graph sits between the shell layer (the executor `ShellSpawn`, which runs ShellSubset parse trees) and the future module `Proc::Spawner`. It is not limited to topologies that sh can make (R1).

## 1. What the graph is

- **A process node** is one start of one program (N5): its arguments and its *final* fd table. Each entry of that table is an **edge**: an fd number, how the fd is used (`<`, `>` or `<>`), and an end (N3). Redirections as written are not stored; the shell layer turns them into the final table, and `SpawnGraph::actions` turns the table into dup2 and close actions.
- **An end node** is anything the parent can give a child under an fd number: the read or write half of a pipe, an opened file, or one of the parent's own fds ("Perl's fd N").
- **A pipe is its two halves** (N2), linked to each other. When the parent closes its copy of a half, the half is *forgotten*. The graph mirrors what the OS does only vaguely: the OS pipe may be gone long before both halves are forgotten here, when every process holding it has closed it or exited. "Forgotten" means only that nothing more can be done with the structure.
- **The parent itself** appears as a process named `Perl` while it reads an end (the output of `$( … )`, the `read` builtin).
- **Order (N6).** A process's on-exit action is the continuation the executor already has. For pictures only, a process started from the continuation of another's exit carries `after => [THAT_PROCESS, "exit N"]`, drawn as a dashed orange arrow.

In code a process node is exactly the per-child "handout list" (its final fd table); an end node is the one object such lists share. This answers the question in your note under N1 the way the code does it now; the item stays open until you mark it.

## 2. Code

`lib/Proc/Spawner/Graph.pm` (since 2026-11-02; it replaces `lib/SpawnGraph.pm`). The full list of calls is in `claude/pspawn-spawner.md`, section 2. In short: `new_pipe`, `file_end`, `parent_end`, `hold`, `release` for ends; `start(…, on_exit => HANDLER)` for processes; `perl_read`, `perl_write` for Perl's own use of ends; `parse(TEXT)` for the notation of N7 (section 4); `to_dot(GRAPH, CAPTION)` for pictures (N8, N9); `run(GRAPH, bin => DIR)` for hand-written graphs (section 5). The translation of a fd table into posix_spawn file actions is in `lib/Proc/Spawner.pm`.

In the executor (`lib/ShellSpawn.pm`):

- The ends it keeps for its contexts are the graph's ends. Releasing the last hold closes the parent's copy and marks it forgotten.
- Every child is started through the graph; its node carries the shell's continuation as its on-exit handler.
- An exited process stays in the graph while it shares an end, or a pipe, with a running process or with one of the parent's reads and writes; then it is dropped, so a long loop does not grow the graph.
- When an end is closed is still decided by the counts per end, as before; N4's `keep` flag is not built (N4 is unmarked).
- The executor never announces a process before starting it, so its pictures have no dashed (not started) boxes.

## 3. Pictures: `TRACE=dot`

`TRACE=dot TRACE_DIR=DIR perl try.pl 'CMD'` writes `DIR/trace-001.dot`, `trace-002.dot`, … one per event: a start, an exit, an end closed. Each is captioned with its number and the event. Render with `dot -Tsvg`. States: bold = running; gray with "exited N" = finished; dotted = forgotten end.

## 4. The notation (N7)

One node per line; `#` starts a comment.

```
pipe NAME [r:forgotten] [w:forgotten]      the ends NAME.r and NAME.w
file NAME MODE PATH [forgotten]            MODE: < > >> <> >|
PROC: ARGV ... | EDGES | after PROC WORD | STATE
    EDGES: FD<END FD>END FD<>END; a + after END marks keep
    END: NAME.r NAME.w NAME, or @N for the parent's fd N
    STATE: running, exited N (for drawing); none: not started
Perl: WHAT | <END                          the parent itself reading an end
```

Arguments are split at blanks; quoting is not done yet. `sgraph/graph2dot.pl FILE.sg` draws a file; its output is pixel-identical to the prototype's for Examples 1–6.

## 5. Running hand-written graphs

`Proc::Spawner::Graph::run` starts each process with exactly its edges; fds 0–2 not among them are the parent's. A process with `after P WORD` is started by P's on-exit handler (`Proc::Spawner::Graph::then`): WORD `fail` needs a non-zero status, `ok` zero, anything else any status. A process that will never start is marked `never` and gives up its ends. A state written in the notation (`running`, `exited 0`) is for drawing only; `run` starts from scratch. The parent closes its copy of an end once no process left to start uses it.

`sgraph/run-graph.pl FILE.sg …` runs graphs with every program replaced by `sgraph/reporter`, through symlinks named after the programs. The reporter records its argv, every open fd (what it is, its access mode, close-on-exec), SigIgn, SigBlk, process group and session. It then writes its name to every fd it may write, closes those, and reads every readable pipe or file to its end. The checker compares each process's fds with its edges. Pipes are matched to inodes one to one. It also checks that each pipe carried the names of exactly the processes that write into it.

Result, 2026-11-01, and again 2026-11-02 on the new engine: Examples 1–6 of the page, 17 of 17 processes as drawn, including the loop of Example 2, the fds 3 and 4 of Example 3, `after P1 fail` in Example 1 and Perl's own read in Example 4. With the fd-table translation deliberately broken, the checker reports 0 of 6.

## 6. Not done yet

- N4 (`keep` edges), unmarked.
- Windows (W1–W3), in `Proc::Spawner` now that it exists; none of it can be tested here. W2 is option C: fds 3 and up go through the C runtime's reserved field, and a program on a list of names known to ignore that field (starting with `java`, `javaw`; changeable through the API) is refused such an fd at once.
- Corpus testing with the reporter (X12 in `claude/pspawn-known-issues.md`): the reporter exists now; the corpora are still to be restored.
