# Proc-Spawner version 0.13 (EXPERIMENTAL)

Compiles and runs shell one-liners (or portable shell scripts) from Perl without `/bin/sh` and "without" fork, matching dash/bash: the snippets are parsed by one of the `Proc::ShellSubset` parsers and run by `Proc::ShellSpawn`, which starts programs with posix_spawn(3) and runs loops, subshells, `$( )` and pipelines of compound commands inside the Perl process. (All the started programs are children of the initial Perl process, as opposed to descendants.)

| Module | What it is |
|---|---|
| [`Proc::Spawner`](lib/Proc/Spawner.pm) | start children (every posix_spawn setting) |
| [`Proc::Spawner::Loop`](lib/Proc/Spawner/Loop.pm) | the event loop, one interface on POSIX and on Windows |
| [`Proc::Spawner::Graph`](lib/Proc/Spawner/Graph.pm) | the executable graph of children, pipes and files |
| [`Proc::ShellSpawn`](lib/Proc/ShellSpawn.pm) | the shell layer |
| [`Proc::ShellSubset`](lib/Proc/ShellSubset.pm), [`Proc::ShellSubset::Small`](lib/Proc/ShellSubset/Small.pm), [`Proc::ShellSubset::Large`](lib/Proc/ShellSubset/Large.pm) | parsers of three sizes of the shell language |

The documents: [`Proc::Spawner::Docs`](lib/Proc/Spawner/Docs.pod), and their map, [`doc/README.md`](doc/README.md).

## <a id="my-what-is-open"></a>What is open

The file [`TODO`](TODO) lists every postponed thing in one place, first the decisions waiting for the author (with where to read and how to act), then the work, then what to watch.

## <a id="my-how-close"></a>How close to dash and bash (0.13; [`doc/large-subset/large-subset-state.md`](doc/large-subset/large-subset-state.md))

Snippet by snippet, across environments, with every difference of ours and the ruling that allows it: [section 11 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-11) (post-0.12). To redo any of these measurements: `make corpus-help` (after `perl Makefile.PL`; Linux, root for the runs; [section 0 of `doc/test-pools.md`](doc/test-pools.md#my-section-0)).

Of 41,952 shell snippets from six public collections (tldr, NL2Bash, ShellCheck's tests, the bash Cookbook, the pure sh and bash bibles), the large parser accepts 40,410. The rest are mostly bash-only syntax, which the subset rejects on purpose; 44 are forms both shells run alike, the work list ([section 4 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-4)).

### <a id="my-one-run-of-every-accepted-snippet"></a>One run of every accepted snippet

Each accepted snippet was run by dash, by `bash --posix` and by `Proc::ShellSpawn` ([section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-7), the run of post-0.12), each run isolated:

- Every program the snippet calls, but the plain text tools (which really run), is replaced by a recorder that logs its arguments and what the snippet feeds it (its size and SHA-256; IN1, post-0.12), and does nothing else. The recorders are only for the programs of a fixed list, so that what the container happens to have installed (Wine, faketime, ShellCheck, …) is "not found" ([`TODO`](TODO) A23).
- Each run gets a fresh `/tmp`, a fixed `/dev/urandom` and fixed file times; background jobs still running when a shell ends are given up to 5 seconds.
- Ours runs `echo`, `printf`, `test`, `[`, `true`, `false` and `pwd` inside Perl, as the coreutils programs behave (its default since 0.10; `pwd` since 0.11): these are not recorders, in all three shells they really run.
- What this run cannot show: known issue [X27](doc/pspawn-known-issues.md#my-x27).

| Snippets | Run | Same | Only the messages differ | dash and bash agree, ours differs | the same, known chance¹ | dash and bash differ |
|---|---|---|---|---|---|---|
| coreutils involved² | 1,333 | 882 | 310 | 3 | 0 | 135 |
| no coreutils | 39,077 | 14,894 | 23,083 | 1 | 3 | 1,085 |
| all | 40,410 | 15,776 | 23,393 | 4 | 3 | 1,220 |

¹ *Known chance*: dash and bash agreed in the run counted here and ours did not, but in repeated runs dash and bash too give other results (races, inode numbers), so ours' difference says nothing.
² *Coreutils involved*: the snippet calls `echo`, `printf`, `test`, `[`, `kill` or `pwd`, which ours runs as the coreutils programs behave, where dash and bash run builtins of their own: these rows compare coreutils' behaviour with the builtins'.

- And 14 snippets that never end, or not in one of the three ([section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-7)).
- "Only the messages differ" is mostly dash's `x: not found` against bash's `x: command not found`.
- Where dash and bash differ, ours follows (coreutils involved + no coreutils) dash in 46+919=965, bash in 64+39=103, and neither in 25+127=152 (mostly `$0`, process IDs, times, and the interactive builtins).
- The 4 where ours differs:
  - `printf -v` (2; legalized, see below);
  - `exec command` (1: known issue [X56](doc/pspawn-known-issues.md#my-x56), a bug of ours, open);
  - `echo` into a broken pipe in a subshell (1; awaiting a ruling, [`TODO`](TODO) A17): ours gives its own result in every run, while dash and bash do not always agree with each other.
- The 3 known chance:
  - the race `ls -a | tee output.file`: whether `ls` lists `output.file` depends on whether `tee` has created it yet; by hand, in 50 runs each, dash listed it 31 times, bash 33, ours 2 (ours starts `tee` a few milliseconds later; kept so, K6);
  - two `head` reading one pipe in turn: how much the first takes depends on timing (all three give both results);
  - the inode numbers `ls -i` prints.
- In earlier runs also the race `{ echo foo; cat bar; } | tee bar`: `bar` ends 4 bytes long if `cat` reads it before `tee` has copied `foo` into it, else 8; by hand, in 200 runs each, dash 4 (188 runs) or 8 (12), bash 8 (189) or 4 (11), ours 8 (all 200).
- *Legalized*: a difference of ours from dash or bash that a ruling of the author allows (the rulings: [section 1 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-1); each difference with the ruling that allows it: [section 11 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-11)).

### <a id="my-how-far-one-run-s-agreement-carries"></a>How far one run's agreement carries

An agreement in one run is a real one only if the snippet could not behave otherwise in another environment (other files, variables, programs' output, `/tmp`, …). [Section 1 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md) sorts the 40,410 snippets by that, into levels. In *N*+*M*, the *N* snippets were sorted programmatically, from their parse trees, the *M* by Claude (an AI) reading them.

- *strict*, 365+27=392: cannot come out otherwise in any environment.
- *held*, 2: cannot, under assumptions known to hold in every environment tested.
- *almost strict*, 34,302: cannot, if [*named assumptions*](doc/large-subset/large-subset-environment.md#my-table-1) hold (its table 1), mostly that a program does the same in each run.
- "*values passed on unchanged*", 664+7=671, and "*values passed on split*", 1,476+7=1,483: the most the shell does with a value it takes from the environment is to pass it on to a command, unchanged, or split at `$IFS` (and matched against file names). So, unless a bug of the shell in that passing is triggered, these are strict too.
- *partially decided*, 3,508: may depend on the environment, but what they depend on is named exactly (one line per snippet: [`large-subset-provenance.tsv`](doc/large-subset/large-subset-provenance.tsv)), and they ran in example environments made for it (below).
- *undecided*, 0+52=52: the rest, which the example environments left out; Claude's reading left them undecided.

### <a id="my-beyond-the-one-run"></a>Beyond the one run

Three checks of what the one run above cannot show:

- **Example environments, for what may depend on the environment** ([sections 10 to 12 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-10)): the partially decided snippets, and 1,220 of those of the levels "values passed on" (270 and 950, taken by step 2 before step 3 put them there), ran again in a few environments made from what each depends on (files present or not, values of variables, a program's output). Every snippet counted over all the environments it ran in ([section 11](doc/large-subset/large-subset-environment.md); messages counted nowhere, wherever a redirection sends them):
  - ours = dash = bash in every environment: 38,593;
  - ours differs from at least one shell somewhere: 1,804 (7 where dash and bash agree, 1,797 where they differ, so that ours cannot be as both);
  - of these, legalized 1,629 (mostly by A5: ours with dash where the shells differ), awaiting a ruling 88, chance 45, not legalized yet 42.
- **The assumptions tried** ([section 9 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-9)): the snippets that rest on an assumption ran again with it broken: a second case of `POSIXLY_CORRECT`, of the locale, of SIGPIPE, of `/proc`; a fresh `/tmp`; a fixed `/dev/urandom`. Few came out otherwise. The levels stay as the parse trees give them; section 1 points to these runs in its footnotes.
- **The six commands, call by call**: each call of `echo`, `printf`, `test`, `[`, `kill` or `pwd` the snippets make was also run by dash's builtin, by bash's builtin and by the coreutils program, whose behaviour ours follows. Of 653 calls (1,156 uses):
  - 518 (997) agree;
  - 41 (45) differ in messages only;
  - 94 (114) differ: mostly `echo -e` and backslashes (dash's builtin against bash and coreutils), unary `-a -o -v` in `[ ]` (bash's builtin against dash and coreutils), and `kill` with a word that is no process ID (dash against bash and coreutils).

  In the example environments too, every such call ran alone four ways (360 distinct calls): ours = coreutils in all. [Section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md) has them all, with the rulings taken so far.

## <a id="my-our-tests"></a>Our tests

The tests of this distribution (the snippets of the collections above are measurements, not tests). They are designed to pass in every environment we could check. Where an environment cannot do what a test needs, the test is *skipped*, with the reason printed. Where a known bug of someone else's makes a test fail there, the test is marked *TODO*: it runs and is reported, but its failure is expected. Each test's outcome per environment and level of the spawn primitive, failures, TODO and skips apart: [`doc/test-results/`](doc/test-results) (`*-flavors-by-test.txt`).

- **Linux** (glibc 2.39): the whole suite, at every level of the spawn primitive: posix_spawn as built; built as if the C library lacked some or all of posix_spawn's extensions (`PROC_SPAWNER_WITHOUT="PIDFD_SPAWN ..." perl Makefile.PL`), as an older one would; without posix_spawn (fork and exec); without fork either (Perl's own spawn through Run). No test is TODO there. The lower levels skip the tests of the settings they cannot do: without posix_spawn, a new session and a new process group; without fork too, also ignored signals, resource limits and the nice value.
- **Without `/proc`**, as on FreeBSD (RT #182479; tested on Linux with `/proc` hidden): [`t/graph.t`](t/graph.t) and two batteries (below) of [`t/dash.t`](t/dash.t) are skipped, and Perl's own writes into a pipe the caller gave may block (known issue [X32](doc/pspawn-known-issues.md#my-x32)).
- **Windows**: under Wine only (Strawberry Perl 5.38.2.2), not on real Windows. The POSIX-only tests are skipped there. Through Perl's own spawn (the level without posix_spawn), 5 tests are TODO: in 4, Perl quotes a command line's arguments otherwise than the C runtime reads them back (❰BUG❱ in Perl: [`doc/perl-win32-system-bugs.md`](doc/perl-win32-system-bugs.md)); in 1, Perl puts a batch file's line in quotes that Wine's `cmd.exe` keeps (real Windows unchecked).
- **Not tested at all**: FreeBSD and the other BSDs themselves, macOS, other C libraries (musl, …), OS/2, VMS.
- **Threads**: the parts that flip process-wide state for a while (umask, signal actions) are safe only without threads.

Tests, among them: [`t/spawner.t`](t/spawner.t) (`Proc::Spawner` and the graph), [`t/graph.t`](t/graph.t) (hand-written graphs), [`t/parsers.t`](t/parsers.t) (1,117 snippets through the parsers), and [`t/dash.t`](t/dash.t) (every snippet of the batteries run by dash and by the shell layer; skipped without dash; [`t/dash-known.txt`](t/dash-known.txt) lists the known differences). Their fixtures are in `t/`: [`t/batteries/`](t/batteries) (the *batteries*: files of hand-written shell snippets, one a line, 701 in 15 files, grouped by topic: fds, signals and the environment, `echo`, the large subset's features, …), [`t/parser/`](t/parser), [`t/sgraph/`](t/sgraph), [`t/try.pl`](t/try.pl) (runs one snippet: `perl t/try.pl 'SNIPPET'`).

## <a id="my-installation"></a>Installation

To install this module type the following:

```sh
perl Makefile.PL
make
make test
make install
```

## <a id="my-dependencies"></a>Dependencies

Only modules that come with Perl. Building needs a C compiler. [`Makefile.PL`](Makefile.PL) finds whether the libc has posix_spawn, and which of its extensions (chdir, fchdir, closefrom, tcsetpgrp, pidfd_spawn, cgroup), by compiling a call to each. What the libc lacks is done in Perl's process around the call where that can be undone (chdir, the fds, the signal mask, ...); the rest fails with `ENOTSUP`, or is dropped, as `%Proc::Spawner::UNSUPPORTED` says. Without posix_spawn the primitive is fork and exec; without fork either, Perl's own spawn through Run 0.07 (`system1`); on Windows, [`win_spawn.h`](win_spawn.h). Resource limits, ignored signals and the nice value, which posix_spawn has no option for, are set around the call too.

## <a id="my-copyright-and-licence"></a>Copyright and licence

Copyright (C) 2026 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.22.2 or, at your option, any later version of Perl 5 you may have available.
