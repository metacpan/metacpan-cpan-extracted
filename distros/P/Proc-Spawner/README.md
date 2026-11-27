# Proc-Spawner version 0.14 (EXPERIMENTAL)

Compiles and runs shell one-liners (or portable shell scripts) from Perl without `/bin/sh` and, where the platform has posix_spawn, without forking the Perl process, doing what dash and bash do (where the two differ, what dash does in 1,268 of the 1,798 corpus snippets in which they differ: [How close](#my-how-close)): the snippets are parsed by one of the `Proc::ShellSubset` parsers and run by `Proc::ShellSpawn`, which starts programs with posix_spawn(3) (where a platform lacks it: fork and exec, or else Perl's own spawn through [Run](https://metacpan.org/dist/Run); on Windows a posix_spawn of our own, [`win_spawn.h`](win_spawn.h); each of these can be forced for tests: [the approaches](#my-the-approaches), below) and runs loops, subshells, `$( )` and pipelines of compound commands inside the Perl process. (All the started programs are children of the initial Perl process, as opposed to descendants.)

| Module | What it is |
|---|---|
| [`Proc::Spawner`](lib/Proc/Spawner.pm) | starts an individual child with every setting posix_spawn can give it (and the umask, resource limits, ignored signals, the nice value); what the platform's way of starting a child lacks, it does *around the call*: in Perl's own process just before the call, undone just after it |
| [`Proc::Spawner::Loop`](lib/Proc/Spawner/Loop.pm) | the event loop, one interface on POSIX and on Windows |
| [`Proc::Spawner::Graph`](lib/Proc/Spawner/Graph.pm) | creates and updates the spawn graph: the children, pipes and files in use now, and what the end of each child sets off (more children, closed pipes, …) |
| [`Proc::ShellSpawn`](lib/Proc/ShellSpawn.pm) | runs the parsers' trees (the shell's expansions, redirections, builtins, control flow) by building the spawn graph: the interface between the parsers and the rest |
| [`Proc::ShellSubset`](lib/Proc/ShellSubset.pm), [`Proc::ShellSubset::Small`](lib/Proc/ShellSubset/Small.pm), [`Proc::ShellSubset::Large`](lib/Proc/ShellSubset/Large.pm) | parsers of three sizes of the shell language: `Small`, the base parser `Proc::ShellSubset`, and `Large`, the *large parser* below |

The documents: [`Proc::Spawner::Docs`](lib/Proc/Spawner/Docs.pod), and their map, [`doc/README.md`](doc/README.md).

## <a id="my-how-close"></a>How close to dash and bash (0.14; [`doc/large-subset/large-subset-state.md`](doc/large-subset/large-subset-state.md))

To find out, we took 41,952 shell snippets from six public collections (tldr, NL2Bash, ShellCheck's tests, the bash Cookbook, the pure sh and bash bibles). The large parser (`Proc::ShellSubset::Large`) accepts 40,409 of them and rejects 1,543. A rejected snippet cannot be run by `Proc::ShellSpawn` (*ShellSpawn* below): it refuses it with an error before it starts anything. So for a rejected snippet the question is only whether it should have been accepted, and that is answered by running it in dash and bash alone: where the two agree, the large parser could accept it (and ShellSpawn would then run it, doing what both shells do), unless a decision of the author keeps it out. The rest of the section, from [The accepted snippets](#my-the-accepted-snippets) on, compares runs of the 40,409 accepted ones in dash, bash and ShellSpawn.

**The records of every run**, snippet by snippet, with how each run was made and how to redo it, are in the repository [**Proc-Spawner-results**](https://github.com/ilyaz-ai/Proc-Spawner-results).

### <a id="my-the-rejected-snippets"></a>The rejected snippets: foreign, subtle, and the work list

[Section 1 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-1) gives two measures of what dash and bash share, both made from the snippets' text by a detector of differences between the shells (it does not run them): the *lower yardstick* takes in only the forms of shell text on which it finds the two shells agreeing; the *upper yardstick* takes in also the forms on which they differ only subtly, or on which the author has not yet given a verdict. By these measures (the parse results of 2026-11-22, post-0.13) the 1,543 rejected snippets fall into three groups, 1,458+40+45=1,543:

- **Foreign**, 1,458: outside even the upper yardstick, rejected on purpose, since the detector finds that dash and bash behave differently there; in 1,327 of them because they use bash's own syntax or features.
- **Subtle**, 40: between the two yardsticks; in 37 the shells differ in detail (listings such as `set` alone, traces, …), in 3 (all reading `$-`) the verdict is open.
- **Work list**, 45: within the lower yardstick, where the parser should accept a snippet unless there is a reason not to.

Each was also run once in dash and in `bash --posix` alone (2026-11-26, `make corpus-rejected`). They come out *alike* (the same, or differing only in the wording of error messages), *differ*, or *did not end* (a shell still running when the 5 seconds a run is given were over):

| Group | Snippets | Alike | Differ | Did not end |
|---|---:|---:|---:|---:|
| foreign | 1,458 | 313 | 1,138 | 7 |
| subtle | 40 | 20 | 20 | 0 |
| work list | 45 | 15 | 30 | 0 |

Of the work list, 9 of the 15 alike are candidates (no decision keeps them out), and 25 of the 30 that differ, with ShellSpawn doing what dash does (ruling A5). One run in one environment can hide a difference, so the 25 candidates that read something from their environment ran again in example environments written by reading them: 8 of the 9 alike stay alike in every environment (`ls ~-` differs once `OLDPWD` is set); of the 25 that differ, 7 come out alike in some environments and 12 differ in every one. Whether the large parser should accept them: [TODO A27](TODO.md#my-a27). Every snippet, the lists and the reasons: [the whole account in section 4 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-the-rejected-samples-run-in-dash-and-bash), and the record [`large-subset-rejected.tsv`](doc/large-subset/tools/large-subset-rejected.tsv).

### <a id="my-the-accepted-snippets"></a>The accepted snippets: alike, different, did not end

We ran every accepted snippet in dash, in `bash --posix` and in ShellSpawn, and compared what the three did: the exit status, the output, the programs called with their arguments, the files left. A *run* is one snippet run by all three, each isolated (as described under [One run](#my-one-run-of-every-accepted-snippet), below). Error messages do not count: a run in which the three differ only in their messages counts as agreement, since each shell words its messages its own way (dash's `x: not found` against bash's `x: command not found`). (The table under One run shows such runs in a column of their own.) A snippet whose result may depend on the environment (files, variables, what programs answer) also had runs in example environments made for it (see Runs in example environments, under [Three further measurements](#my-beyond-the-one-run), below).

A difference of ShellSpawn's is *legalized* where a ruling of the author allows it. The rulings, listed in [section 1 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-1), are named by short codes: for example A5 (where the two shells differ at run time, ShellSpawn does what dash does), Q2 or K6. A question still waiting for the author's decision is named by its entry in [`TODO`](TODO.md), as "[TODO A12](TODO.md#my-a12)". Names such as X56 are known issues ([`doc/pspawn-known-issues.md`](doc/pspawn-known-issues.md)).

The result of the runs of 2026-11-22 (post-0.13), each snippet counted over all its runs (the one run and the runs in example environments; a run in which any of the three did not end is not compared), 38,594+1,802+13=40,409:

- **Alike**, 38,594: ShellSpawn does what both shells do, in every run.
- **Different**, 1,802: ShellSpawn differs from at least one shell, in some run. In 1,798 of them dash and bash also differ from each other, so ShellSpawn cannot do what both do: it does what dash does in 1,268, what bash does in 355, neither in 128, and which of these depends on the environment in 47 (1,268+355+128+47=1,798). In the other 4 the two shells agree and ShellSpawn does not (they are in the groups below: 3 legalized, 1 chance). Each of the 1,802 is in exactly one of three groups, 1,633+43+126=1,802:
  - **Legalized**, 1,633. By the shell ShellSpawn follows (of the counts just above, the legalized ones): dash, 1,248 (by A5, but 2 by rule E: where the shells differ, the behaviour that the author's categories of rule E judge better, [`large-subset-logical.md`](doc/large-subset/large-subset-logical.md)); bash, 283 (G16, `~` with `HOME` unset gives the home from the password file, 126; the six commands `echo`, `printf`, `test`, `[`, `kill`, `pwd` done as the coreutils programs, 117; B2, the interactive builtins such as `history` do nothing, 31; rule E, 10; these add up to 284, as one snippet needs two rulings); neither shell, 88 (`$0`, each shell started under its own name, 36; B2, 35; A4, a form outside the subset met at run time stops the run, 8; the six commands, 8; a difference made by the test runner itself, 1); dash in some runs, bash or neither in others, 11; and 3 where dash and bash agree (`printf -v`, Q2, 2; A4, 1). 1,248+283+88+11+3=1,633. What each ruling says: the table "The rulings" in [section 11 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-11).
  - **Chance**, 43: snippets whose result is expected to change from run to run, so that the comparison says nothing about them either way. 38 were judged so from their text alone, by the codes a program gives each snippet from its parse tree ([section 3 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-3)): they print process IDs (25), times, random numbers, the environment's variables, or what is under `/proc` or `/`; these were not run again. 5 were judged so by repeated runs: in 4 races, run 10 to 200 times each, dash and bash themselves gave more than one result; in the 5th, `ls -lhrt` of files the snippet writes, the result changed between two runs in the same environment.
  - **Open**, 126: differences that may turn out to be our bugs; none has been decided yet.
    - 88 wait for the author's ruling on one proposal: `~` with `HOME` empty gives an empty word, as in bash and POSIX ([`TODO` A12](TODO.md#my-a12)). They have not been reviewed one by one yet.
    - 38 have no ruling at all ([TODO A13](TODO.md#my-a13)): 30 are `cd` given two words or more by a program's answer, where ShellSpawn answers as bash, "too many arguments" (known issue [X54](doc/pspawn-known-issues.md#my-x54)); 8 are cases that rows of rule E already decide (`[^…]` negates, a descriptor of two digits, `return` outside a function, `$LINENO`, `cd` with two operands in its text), but the list in which the counting program looks rulings up ([`large-subset-match-known.tsv`](doc/large-subset/tools/large-subset-match-known.tsv)) has no line for them yet, so it does not count them as legalized.
    - The 38 were reviewed one by one by Claude (an AI), each run again in every environment, on 2026-11-22: [`doc/large-subset/large-subset-review.md`](doc/large-subset/large-subset-review.md), which also says how to go on with the 88.
- **Did not end**, 13 = 10+2+1: in every run of these, at least one of the three was still running when the 5 seconds a run is given were over, so there is nothing to compare. In 10, endless loops (`while`, `until`, `tail -f`, …), none of the three ended. 2 write without end: the run's limit on a file's size (20 MB) stopped dash (in one of them bash too) before the 5 seconds were over, while ShellSpawn did not end. The 13th, `yes | sed -n '200000000,…'`, takes about 5 seconds to finish: in its run bash and ShellSpawn finished in time, dash did not.

The runs of 2026-11-22 were made after the bugs of ours that the earlier runs and the review had found were fixed, among them [X56](doc/pspawn-known-issues.md#my-x56) (`exec` followed by a builtin's name; found by the runs of 2026-11-17) and [X80](doc/pspawn-known-issues.md#my-x80) (`cd` read its options and counted its operands before they were expanded; found by the review).

The rest of this section shows how these counts were made, each in a part of its own below:

- [**One run**](#my-one-run-of-every-accepted-snippet): the results of one run of every accepted snippet, in a single environment;
- [**How far one run's agreement carries**](#my-how-far-one-run-s-agreement-carries): the snippets sorted into *levels* by how far an agreement in that one run holds in other environments;
- [**Three further measurements**](#my-beyond-the-one-run) of what the one run cannot show: runs in example environments, runs with an assumption flipped, and the six commands one call at a time;
- [**Other ways of starting a child, and Windows**](#my-other-ways-and-windows): the snippets run with ShellSpawn starting its children otherwise, and under Wine;
- [**Counts that do not match**](#my-counts-that-do-not-match): where the counts of these parts seem to disagree, and why.

Each of ShellSpawn's differences, with the ruling that allows it, is listed in [section 11 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-11). To redo any of these measurements, run `make corpus-help` (after `perl Makefile.PL`; Linux, root for the runs; [section 0 of `doc/test-pools.md`](doc/test-pools.md#my-section-0)).

### <a id="my-one-run-of-every-accepted-snippet"></a>One run of every accepted snippet

Each accepted snippet was run once by dash, by `bash --posix` and by ShellSpawn, on 2026-11-22 ([section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-7)). Each run was isolated:

- Every program the snippet calls is replaced by a *recorder*, which logs its arguments and the size and SHA-256 of what the snippet feeds it. For most programs the recorder does nothing more; for about 40 that only read, print or make files (`cat`, `grep`, `sed`, `awk`, `sort`, `ls`, `mkdir`, …) it then runs the program; `rm`, `mv`, `cp` and `ln` are only logged, so that a snippet cannot remove what it did not make. There are recorders only for the programs of a fixed list ([`large-subset-programs.txt`](doc/large-subset/tools/large-subset-programs.txt)): a program not on it is "not found" in all three shells, even where the machine of the run has it installed, so that the runs do not depend on what that machine has.
- `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd` and `kill` are not replaced by recorders: dash and bash run their own builtins; ShellSpawn runs Perl code that behaves as the coreutils programs do, and for `kill` the `kill` program.
- Each run gets a fresh `/tmp`, a `/dev/urandom` that gives the same bytes every time, and one fixed modification time for the files it starts with; background jobs still running when a shell ends are given up to 5 more seconds.
- A single run cannot show whether an agreement holds in other environments (known issue [X27](doc/pspawn-known-issues.md#my-x27)); the next two parts take that up.

| Snippets | Run | Same | Only the messages differ | dash and bash agree, ShellSpawn differs | dash and bash agree, ShellSpawn differs: known chance¹ | dash and bash differ | Did not end |
|---|---|---|---|---|---|---|---|
| the six commands² | 1,333 | 883 | 310 | 2 | 0 | 135 | 3 |
| no such command | 39,076 | 14,897 | 23,081 | 0 | 1 | 1,086 | 11 |
| all | 40,409 | 15,780 | 23,391 | 2 | 1 | 1,221 | 14 |

¹ *Known chance*: dash and bash agreed in this run and ShellSpawn did not, but repeated runs showed that dash and bash themselves give other results here (a race), so ShellSpawn's difference says nothing. This 1 is among the 43 of the result above. (Deciding chance from all the runs of each snippet, not from runs repeated by hand, is work to do: [`TODO`, part B](TODO.md#my-part-b).)
² *The six commands*: the snippet calls `echo`, `printf`, `test`, `[`, `kill` or `pwd`, where dash and bash run builtins of their own and ShellSpawn behaves as the programs (coreutils', and `kill`): these rows compare the programs' behaviour with the builtins'. (`true` and `false`, which also run inside Perl, are not among them.)

- *Did not end*: 14 = 11+2+1 snippets. In 11 none of the three shells ended; in 2, loops that write without end, the run's file-size limit stopped dash (in one, bash too) first, and ShellSpawn did not end; in 1, `yes | sed -n '200000000,…'`, which ends near the limit, dash did not end and the other two did. One of the 11, `grep -Ril … /`, which reads the whole file system, ended in the runs in example environments, alike in all three: so the result above counts 13, not 14.
- "Only the messages differ": in 23,135 of the 23,391, dash says `x: not found` where bash says `x: command not found`.
- Where dash and bash differ (135+1,086=1,221), ShellSpawn follows (the six commands + no such command) dash in 46+922=968, bash in 64+39=103, and neither in 25+125=150. By the codes that the program sorting snippets into levels (below) gives their text, each snippet counted under the first of these that it has: `$0` 41, process IDs 25, times 15, the interactive builtins 36; the other 33 have none of these codes.
- The 2 where ShellSpawn differs: `printf -v` (legalized by ruling Q2: ShellSpawn does what the `printf` program does, which prints `-v` and warns). Two more of the run of 2026-11-17 are gone: `exec command` (known issue [X56](doc/pspawn-known-issues.md#my-x56), our bug, fixed; the parser now refuses it), and `echo` into a broken pipe in a subshell (the shells' builtin `echo` dies of SIGPIPE and ends the subshell; ShellSpawn's `echo` failed alone and the subshell went on; since decision D3, 2026-11-22, it ends the subshell too).
- The 1 known chance: the race `ls -a | tee output.file`: whether `ls` lists `output.file` depends on whether `tee` has created it yet; by hand, in 50 runs each, dash listed it 31 times, bash 33, ShellSpawn 2 (ShellSpawn starts `tee` a few milliseconds later; kept so by decision K6).
- Two other races are among the 43 of chance too; in the one run dash and bash differed in them, so the table counts them under "dash and bash differ": two `head` reading one pipe in turn (how much the first takes depends on timing; all three give both results), and `{ echo foo; cat bar; } | tee bar`, where `bar` ends 4 bytes long if `cat` reads it before `tee` has copied `foo` into it, else 8; by hand, in 200 runs each, dash gave 4 in 188 runs and 8 in 12, bash 8 in 189 and 4 in 11, ShellSpawn 8 in all 200. (The inode numbers `ls -i` prints, a known chance on 2026-11-17, came out alike.)

### <a id="my-how-far-one-run-s-agreement-carries"></a>How far one run's agreement carries

An agreement in one run is a real one only if the snippet could not behave otherwise in another environment (other files, variables, programs' output, `/tmp`, …). [Section 1 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md) sorts the 40,409 snippets by that into *levels*. Where a level has two numbers, *N*+*M*, the *N* snippets were sorted into levels by a program ([`large-subset-blocks.pl`](doc/large-subset/tools/large-subset-blocks.pl)), from their parse trees, and the *M* by Claude (an AI) reading them; where it has one, all were sorted by the program. The levels cover all 40,409 snippets: 392+2+34,301+671+1,483+3,508+52.

- *strict*, 365+27=392: cannot come out otherwise in any environment.
- *held*, 2: cannot, under assumptions that hold in every environment we tested (such as `/dev/null` existing).
- *almost strict*, 34,301: cannot, if the assumptions it needs hold: each snippet needs some of the 15 [*named assumptions*](doc/large-subset/large-subset-environment.md#my-table-1) of table 1 there. Of the snippets of this level and of the two levels "values passed on" below (34,301+671+1,483=36,455), 36,252 need the assumption that an external program (for example one of coreutils) does the same in each run when given the same arguments, input and environment. Others need that a pipeline's writer dies silently when its reader stops (4,777), or that the files and directories a snippet uses inside `/usr`, `/etc`, `/dev`, `/home`, … are the same in every run, or missing in every run (so that every run fails alike).
- *values passed on*, two levels: the most the shell does with a value it takes from the environment is to pass it on to a command. They are "*unchanged*", 664+7=671, and "*split*", 1,476+7=1,483, where the value is split at `$IFS` and the pieces are matched against file names. We assume that the three shells do this passing alike, whatever the value and the files, and probed it (`make probe-values`); so these snippets need only the assumptions of almost strict about the programs they call; beyond them, they come out the same everywhere unless a bug of a shell in that passing is triggered.
- *partially decided*, 3,508: may depend on the environment, but for each of them the same program, `large-subset-blocks.pl`, finds in its parse tree exactly what it depends on: a file (one that a redirection reads or writes, that `test` checks, that `.` reads, or that is run by a relative name such as `./run.sh`); the files that a pattern matches; a variable that the snippet reads before it sets it; the positional parameters (`$1`, `$@`, …); what `read` takes from the input; the directory that `cd` goes to; the home directory that `~` stands for (each snippet's level and codes, one line per snippet: [`large-subset-provenance.tsv`](doc/large-subset/large-subset-provenance.tsv); the exact dependences, and the environments made from them: [section 10 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-10)). We check that dependence by running each again several times, each time with the parts of the environment it depends on changed in a way made for it (see Runs in example environments, below).
- *undecided*, 0+52=52: the rest. No example environment could be made for them; Claude read all 52 and could not decide them either. They had only the one run.

### <a id="my-beyond-the-one-run"></a>Three further measurements

The one run above compares the three shells in a single environment, and its agreement carries only as far as the levels above say. We made three further measurements, each of something the one run cannot show: other environments; the environment's switches flipped; and the six commands apart from the snippets that call them.

**Runs in example environments.** A snippet that reads a file, a variable or a program's output may behave otherwise when these are different. So each such snippet ran again several times, each time in an environment made for that snippet: a file it reads present or absent, a variable it reads with different values, a program it calls printing different things. These were the 3,508 partially decided snippets, and 270+950=1,220 of the "values passed on" (unchanged + split), which had such runs from before they were sorted into that level. A snippet counts as alike (ShellSpawn does what both shells do) only if that holds in every one of its runs: the counts of the result, under [The accepted snippets](#my-the-accepted-snippets), are those of these runs together with the one run. Error messages are not compared here either, wherever they are written: standard error is not compared, and in standard output and in files the lines that start as a shell's messages do (`dash: 1:`, `bash: line 1:`, `sh:`) are left out; whether to compare them is to be reconsidered ([`TODO` A25](TODO.md#my-a25)). Details: [sections 10 to 12 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-10).

**Runs with an assumption flipped.** An "almost strict" snippet is sure to compare the same in every environment only while its assumptions hold. Four of the assumptions are switches of the environment: `POSIXLY_CORRECT` unset, the locale `C`, SIGPIPE at its default action, `/proc` present. For each switch we ran again, with the switch flipped, every snippet whose text it could affect, whatever its level (for `POSIXLY_CORRECT`: the 443 snippets with an `echo` whose meaning it changes; for SIGPIPE: the 5,742 with a pipeline), to see whether ShellSpawn's agreement with dash and bash survives. For nearly all snippets it did. The comparison changed (ShellSpawn then agrees with another shell than before, or with none, or the run no longer ends) only:
  - with `POSIXLY_CORRECT` set, in 36 of 443: ShellSpawn's `echo` then does what dash's does, no longer what bash's does;
  - with SIGPIPE ignored, in 22 of 5,742: among them endless writers (`yes | nl | sed 100q`) that no longer stop when their reader stops, and do not end in any of the three;
  - in the locale `C.UTF-8`, in 1 of the 25 with a form whose meaning depends on the locale (a bracket expression, `printf`'s `%f`, non-ASCII text in a pattern, …): `printf "\u20AC %.2f\n" 123.4`: bash and ShellSpawn print `€`, dash's `printf`, which has no `\u`, prints `\u20AC` as it is;
  - with `/proc` hidden, in 3 of the 13 that use `/dev/stdin`, `/dev/fd/N` or the like: `/dev/stdin` and the like are missing then, and the snippets fail in all three: 2 with different statuses, 1 with different messages only.

  Each change is explained in [section 9 of `large-subset-environment.md`](doc/large-subset/large-subset-environment.md#my-section-9).

**The six commands, one call at a time.** ShellSpawn does not run the programs `echo`, `printf`, `test`, `[` and `pwd`: it does their work itself, in Perl code that behaves as the coreutils programs do. For `kill` it does run the `kill` program. Dash and bash run builtins of their own, which differ from the programs, and from each other. To see how far this sets ShellSpawn apart from the shells, each distinct call of these commands that ShellSpawn made in the one run was run again on its own, outside its snippet: by dash's builtin, by bash's builtin and by the program (coreutils', or `kill`). Of these 650 calls (in parentheses, how many snippets make each kind; summed over the calls, so that a snippet making two of them counts twice: 1,154 in all):
  - 515 (995) agree in all three;
  - 41 (45) differ in messages only;
  - 94 (114) differ; in parentheses here, snippets: `echo -e` and backslashes (66; dash's builtin against bash and coreutils); the unary `-a -o -v -R` of `[` and `test` (14; bash's builtin against dash and coreutils); `kill` with a word that is no process ID, or `%1` (13; dash against bash and the program); and 21 others: `printf`'s `%q`, `\x`, `%(…)T` and `-v` (12), `==` and `-N` in `[` and `test` (7), `kill -l` (2). 66+14+13+12+7+2=114.

  ShellSpawn itself was not given these 650 calls on their own. It was given, each on its own, the 358 distinct calls made in the runs in example environments (with those environments' values), and gave the same result as the program in every one. [Section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-7) has every call, with the rulings taken so far.

### <a id="my-other-ways-and-windows"></a>Other ways of starting a child, and Windows

All the runs above were made on Linux, where ShellSpawn starts its children by posix_spawn (approach 1 of [the approaches of starting a child](#my-the-approaches), below). The other approaches and Windows were measured with the code of post-0.12, over the 40,410 snippets it accepted (one more than now: `exec command -with -flags`, refused since D1), against the Linux runs of 2026-11-17 ([section 7 of `large-subset-state.md`](doc/large-subset/large-subset-state.md#my-section-7), "Through Run"; [`doc/pspawn-shell-windows.md`](doc/pspawn-shell-windows.md#my-the-large-subset-under-wine), "The large subset under Wine"):

- **Linux, through Run** (approach 4: the module [Run](https://metacpan.org/dist/Run), where Run emulates Perl's `system 1, LIST` by fork and exec), 2026-11-18: no difference comes from Run. 45 snippets came out otherwise than through posix_spawn, messages compared too; 44 of them also come out otherwise between two runs through posix_spawn (process IDs, times, races); the 45th differs only in a message whose presence depends on timing.
- **Linux, posix_spawn with the redirections only, and fork** (approaches 2 and 3): not run over the snippets; only the tests ([Where the tests ran](#my-where-the-tests-ran), below).
- **Windows, under Wine** (Wine 9.0, Strawberry Perl 5.38.2.2), 2026-11-18/19: ShellSpawn alone ran every snippet, at approach 1 (the module's own posix_spawn, [`win_spawn.h`](win_spawn.h)) and at approach 4 (Perl's own `system 1, LIST`, through Run), and each result was compared with the Linux run's. Every difference was traced to a cause; none is left unexplained:

| Snippets | `win_spawn.h` | Perl's `system` |
|---|---:|---:|
| the same as on Linux (also: the same apart from how paths are written) | 40,194 | 39,832 |
| say nothing: Linux itself gives no stable result | 131 | 131 |
| differences made by the test setup, not by Windows | 6 | 5 |
| (a) Windows behaves otherwise, and ShellSpawn passes that on | 50 | 46 |
| (b) ShellSpawn's own design for Windows | 10 | 10 |
| (c) Perl's own `system` on Windows is at fault | 0 | 368 |
| (d) Git for Windows' `kill` and `comm` differ from Linux's | 18 | 17 |
| (e) a known bug of ShellSpawn, [X71](doc/pspawn-known-issues.md#my-x71), open | 1 | 1 |
| all | 40,410 | 40,410 |

Of these causes only (a) cannot be removed: Windows itself differs (no program at a Linux path such as `/usr/bin/find`, 18; file names that ignore case, 5; no sticky bit; `;` in `PATH`; a command line of at most 32,767 characters; …). (b) are choices of the module (`pwd` in Windows' form, `umask` 0000, no `ulimit`, …). (c) are Perl's bugs ([`doc/perl-win32-system-bugs.md`](doc/perl-win32-system-bugs.md)), which approach 1, the one used by default, avoids. (d) are other programs' differences, not the module's. Each row is listed snippet by snippet in [`doc/pspawn-shell-windows.md`](doc/pspawn-shell-windows.md#my-the-large-subset-under-wine); the counts are in [`doc/test-results/wine-large-subset.txt`](doc/test-results/wine-large-subset.txt).

### <a id="my-counts-that-do-not-match"></a>Counts that do not match

We apologize for the counts of this section that seem to disagree with each other. The distribution has been developing fast: its measurements were made at different times, with different code and different tools, and the parts of this document have not all been brought back in line with each other. The ones known, with what has been found about each; what is still open is work in [`TODO`, part B](TODO.md#my-part-b):

1. **2 + 1 in the table of the one run against the 4 of the result** (dash and bash agree, ShellSpawn differs). Explained: the table counts only the one run, the result every environment of a snippet. The 4th, NB:9614 (the 9,614th snippet of NL2Bash, `command $(zcat input1.txt.gz) $(zcat input2.txt)`, legalized by A4), comes out the same in all three in the one run, and differs only in an example environment.
2. **1,221 in the table of the one run against the 1,798 of the result** (dash and bash differ). Explained: of the 1,798, dash and bash differ already in the one run in 1,206, and only in an example environment in 592 (1,206+592=1,798). The table's 15 more (1,221 = 1,206+15) are messages that a shell wrote into its output or into a file (as with `2>&1`): the table compares them as output, the result leaves such lines out, as it does all messages.
3. **The six commands: 1,333 snippets in the table of the one run against the 1,154 of "one call at a time".** Not reconciled. The two count different things: the table counts every snippet in which ShellSpawn ran one of the six commands, or in which one of their names stands where a command does; the 1,154 counts, for each distinct call that ShellSpawn made, the snippets that made it (a snippet once for each of its calls); the 650 calls, and so the 1,154, leave out the 89 calls made by `xargs`. Whether that accounts for the whole difference has not been checked.
4. **Messages in the runs with an assumption flipped.** The result counts a run that differs only in the messages as agreement; the runs with an assumption flipped count a change into "only the messages differ" as a change of the comparison (one of the 3 under `/proc` hidden). The two parts use different measures.
5. **Windows' 131 that "say nothing" against the 43 of chance and the 13 that did not end.** Explained: the Windows runs were compared with the Linux runs of 2026-11-17, not with those of 2026-11-22; the 131 are the 45 snippets of chance of those runs, their 13 that did not end, and 73 more that gave more than one result in Linux runs of one environment ([`doc/pspawn-shell-windows.md`](doc/pspawn-shell-windows.md#my-the-large-subset-under-wine)).

## <a id="my-our-tests"></a>Our tests

These are the tests of this distribution; the snippets of the collections above are measurements, not tests. The tests are meant to pass on every platform we could check. Where a platform cannot do what a test needs, the test is *skipped*, and the reason is printed. Where a known bug in someone else's code makes a test fail, the test is marked *TODO*: it still runs and is reported, but its failure is expected. Each test's outcome on each platform and at each approach of starting a child (below), with failures, TODO and skips counted apart, is recorded in [`doc/test-results/`](doc/test-results) (`*-flavors-by-test.txt`).

### <a id="my-the-approaches"></a>How a child is started: four approaches

`Proc::Spawner` can start a child in one of four ways, which we call *approaches*, from the most capable down. It uses the most capable one the platform has; a test run may choose a less capable one (`PROC_SPAWNER_MISSING`, as [`t/flavors.pl`](t/flavors.pl) does), so that one machine can test them all:

1. posix_spawn as built: every setting for which the C library's posix_spawn has an option is given to posix_spawn, which applies it to the new process; the rest is made in Perl's own process around the call, or refused ([Threads](#my-threads), below, setting by setting).
2. posix_spawn with the redirections only (`dup2`, `close`, `open`), every other setting made around the call or refused: as an older C library would be. Standing for a posix_spawn that does nothing but the redirections, it also turns off the module's own C code that sets ignored signals, resource limits and the nice value around the call, and refuses these. It cannot make a new session or a new process group led by the child either: neither can be made around the call (a new session cannot be undone in Perl's own process, and a new group needs the child's process ID, known only after the call). The tests of these settings are skipped at this approach.
3. fork and exec (our own code, in C), with nothing done between them: every setting it makes, it makes around the call. `Proc::Spawner` would use this approach on a POSIX system without posix_spawn; such a system would rather define posix_spawn itself, so in practice this is an approach for tests, which exercises our code that makes settings around the call. Since it does nothing between fork and exec, it cannot make a new session or a new process group led by the child (whether it should do them there: [`TODO`, F1](TODO.md#my-f1)).
4. Perl's own `system 1, LIST`, through the module Run (*system1*), where there is neither posix_spawn nor fork. On Windows, approach 1 is our own posix_spawn ([`win_spawn.h`](win_spawn.h)), and this approach is used only when that is masked for tests; there it is Perl's real `system 1, LIST`. Perl on Linux has no `system 1, LIST`, and Run emulates it with fork and exec, so there this approach tests Run's machinery. It cannot make what approach 2 cannot.

### <a id="my-where-the-tests-ran"></a>Where the tests ran

So far the tests made before each release have run only on Linux (glibc 2.39, Perl 5.38.2), and, for Windows, under Wine on that Linux. Other systems we model on Linux: an older C library by approach 2 and by [`t/missing-matrix.pl`](t/missing-matrix.pl), which takes posix_spawn's settings away one at a time; a system where Perl's own `system 1, LIST` is the only way to start a child by approach 4; a BSD system by hiding `/proc`.

- **Linux.** The whole suite passes at all four approaches (with the skips each approach brings, above), and no test is TODO.
- **Without `/proc`, as on FreeBSD.** A BSD system has no `/proc` (a failure on FreeBSD, RT #182479 on rt.cpan.org, showed what that breaks). We model it on Linux by mounting an empty file system over `/proc` in a private mount namespace, as root: `unshare -m --propagation private sh -c 'mount -t tmpfs none /proc && make disttest'`; this run is part of every release. There [`t/graph.t`](t/graph.t) and two batteries (below) of [`t/dash.t`](t/dash.t) are skipped, since they read `/proc`. One problem of the library remains possible there, though not reproduced: Perl's own writes into a pipe the caller gave may block (known issue [X32](doc/pspawn-known-issues.md#my-x32)). Other differences of the BSDs (no `/bin/true`, another `ulimit`) are not modeled.
- **Windows.** The tests have run under Wine only (Strawberry Perl 5.38.2.2), never on real Windows, at approaches 1, 2 and 4 (Windows has no fork). Seven of the test files run there: [`t/loop.t`](t/loop.t), [`t/windows.t`](t/windows.t), [`t/parsers.t`](t/parsers.t), [`t/programs.t`](t/programs.t), [`t/portable.t`](t/portable.t), [`t/win_spawn.t`](t/win_spawn.t), [`t/options.t`](t/options.t); the others are not run there. Of their 244 tests at approach 1, 25 are skipped: comparisons with dash, bash, `/bin/sh` or the coreutils programs, which Windows lacks, and checks of what Windows does not have (an execute bit, SIGINT to ignore, `*` in a file name); how many of each is not recorded. At approach 4, where Perl's own `system 1, LIST` starts the child, 5 tests are TODO because of Perl's bugs ([`doc/perl-win32-system-bugs.md`](doc/perl-win32-system-bugs.md)). In 4 of them, Perl writes the arguments into the child's command line in a form the child's C runtime reads back otherwise. In 1, Perl puts a batch file's line in quotes, and Wine's `cmd.exe` keeps them (real Windows unchecked).
- **Not tested at all:** FreeBSD and the other BSDs themselves, macOS, other C libraries (musl, …), OS/2, VMS.

### <a id="my-the-test-files"></a>The test files

The main test files:

| Test file | What it checks |
|---|---|
| [`t/spawner.t`](t/spawner.t) | `Proc::Spawner`: each setting of a child, and the graph's reactions |
| [`t/graph.t`](t/graph.t) | hand-written spawn graphs ([`t/sgraph/`](t/sgraph)): every process gets exactly the fds and pipe contents drawn |
| [`t/parsers.t`](t/parsers.t) | the parsers: 1,117 snippets ([`t/parser/`](t/parser)) accepted or rejected as expected, some whole trees |
| [`t/dash.t`](t/dash.t) | the shell layer against dash: every snippet of the batteries (below), run by both, compared (skipped without dash; [`t/dash-known.txt`](t/dash-known.txt) lists the known differences) |
| [`t/portable.t`](t/portable.t) | the shell layer on any platform, Windows included: the battery snippets that need no program but perl, against outputs recorded on Linux |
| [`t/programs.t`](t/programs.t) | `echo`, `printf`, `test`, `[` run inside Perl, against what GNU coreutils did |
| [`t/loop.t`](t/loop.t), [`t/windows.t`](t/windows.t), [`t/win_spawn.t`](t/win_spawn.t) | the event loop on POSIX and Windows; starting a child on Windows; [`win_spawn.h`](win_spawn.h) on its own |

The *batteries* ([`t/batteries/`](t/batteries)) are 708 shell snippets we wrote by hand, one per line, in 15 files by topic: fds, signals and the environment, `echo`, the large subset's features, and so on. To run one snippet by hand: `perl t/try.pl 'SNIPPET'` ([`t/try.pl`](t/try.pl)).

## <a id="my-what-is-open"></a>What is open

Everything postponed is in [`TODO`](TODO.md): first the decisions waiting for the author, then the work, then what to watch. Every known bug, open or fixed, is in [`doc/pspawn-known-issues.md`](doc/pspawn-known-issues.md).

## <a id="my-installation"></a>Installation

To install this module type the following:

```sh
perl Makefile.PL
make
make test
make install
```

## <a id="my-dependencies"></a>Dependencies

Only modules that come with Perl, and, only where there is neither posix_spawn nor fork, Run 0.07 from CPAN. Building needs a C compiler. [`Makefile.PL`](Makefile.PL) finds whether the libc has posix_spawn, and which of its extensions (chdir, fchdir, closefrom, tcsetpgrp, pidfd_spawn, cgroup), by compiling a call to each. What the libc lacks is done in Perl's process around the call where that can be undone (chdir, the fds, the signal mask, ...); the rest fails with `ENOTSUP` by default, or is dropped where the caller asks so for that setting (`%Proc::Spawner::UNSUPPORTED`). Without posix_spawn the primitive is fork and exec; without fork either, Perl's own spawn through Run 0.07 (`system1`); on Windows, [`win_spawn.h`](win_spawn.h). The umask, resource limits, ignored signals and the nice value, which posix_spawn has no option for, are set around the call too.

## <a id="my-threads"></a>Threads: what starting a child, and running a snippet, change in Perl's process

The modules can be used in a program with several threads, as long as the other threads do not rely, at those moments, on the parts of the process's state that a start or a run changes for a while. This section says which parts those are, when, and for how long, so that the damage can be kept local. None of it has been tested with threads: the tests use one thread.

**Starting a child.** A child is started by one call of the *primitive*: posix_spawn, fork and exec, or Perl's own `system 1, LIST` (on Windows, `CreateProcessW` inside [`win_spawn.h`](win_spawn.h)); which one depends on the approach ([the four approaches](#my-the-approaches), above). At run time, `$Proc::Spawner::PRIMITIVE` says which primitive is used (`posix_spawn`, `fork` or `system1`), and the keys of `%Proc::Spawner::MISSING` are the settings it lacks. Each setting asked of the child is made in one of three ways:

- **C**, by the call: it is given to the primitive, which applies it to the new process. Nothing of Perl's process changes (but for the two exceptions named below: note 2, and Windows' handles).
- **A**, around the call: Perl's own process is changed just before the call, so that the child inherits the change, and put back just after it. For that moment every thread sees the change (but where the state belongs to each thread: notes 4 and 6); two threads doing this at once could each put back what the other changed.
- **R**, refused: no child is started, and the call fails: `start` returns undef, and `spawn` the empty list, with `$!` set to `ENOTSUP`. A caller can have a refused setting dropped instead, setting by setting: `unsupported => { NAME => 'drop' }` given to `start` for one call, or, for every call, `$Proc::Spawner::UNSUPPORTED{NAME} = 'drop'` (its key `'*'` covers the settings not named; the default is `'*' => 'fail'`). The child is then started without that setting.

Two letters in a cell (`CA`, `CR`, `AR`) mean that which way is taken depends on the C library or on the value (the notes). On POSIX:

| Setting of the child | 1: posix_spawn as built | 2: posix_spawn, redirections only | 3: fork and exec | 4: system1, through Run |
|---|---|---|---|---|
| descriptors: `dup2`, `close`, `open` | C | C | A | A¹ |
| `closefrom` | C² | C² | A | A¹ |
| directory: `chdir`, `fchdir` | CA³ | A | A | A |
| signal mask: `sigmask` | C | A⁴ | A⁴ | A⁴ |
| `sigdefault` (an ignored signal back to its default) | C | A | A | A |
| `pgroup => PGID` (joining a group that exists) | C | A | A | A |
| `resetids` (the effective ids set to the real ones) | C | A | A | A |
| `pgroup => 0` (a new group), `sched` (a scheduling policy) | C | R⁵ | R⁵ | R⁵ |
| `setsid`, `tcsetpgrp`, `cgroup` | CR³ | R⁵ | R⁵ | R⁵ |
| `umask` | A | A | A | A |
| `sigignore`, `rlimit`, `nice` | AR⁶ | R⁷ | AR⁶ | R⁷ |

What A changes in Perl's process, by row (the two rows of descriptors alike): its descriptors are arranged as the child should have them (a descriptor to be closed gets close-on-exec) and put back; it changes directory and comes back; its signal mask; the action of an ignored signal; its process group; its effective user and group ids; its umask; its ignored signals, resource limits and nice value. While its descriptors, directory, signal actions, group or ids are changed, the calling thread blocks every signal, so that no signal handler of Perl's in that thread sees the change (signals delivered to other threads are not blocked). `search` (a lookup in `PATH`) and `pidfd` change nothing of Perl's process at any approach: the lookup is done in Perl before the call, the pidfd opened after it.

¹ Run makes them around Perl's own spawn, and puts Perl's descriptors back.
² Where the C library lacks `closefrom` (glibc before 2.34, musl), and always at approach 2, it is given to the call as a `close` of each descriptor the child would have from that number up: a descriptor that another thread opens meanwhile stays open in the child.
³ C where the C library has the option (glibc: `chdir` and `fchdir` both since 2.29, `setsid` 2.26, `tcsetpgrp` 2.35, `cgroup` 2.39; [Dependencies](#my-dependencies)); otherwise A for the directory, R for the others.
⁴ On Linux the signal mask belongs to each thread: only the calling thread's mask changes.
⁵ Neither can be made around the call: a new session cannot be undone; a new group, and the terminal's foreground group, need the child's process ID, known only after the call; a scheduling policy and a cgroup cannot be put back reliably.
⁶ A, made by the module's code in the C language right around the call; R where the change could not be put back: a hard limit lower than Perl's own without `CAP_SYS_RESOURCE`, a higher nice value unless `CAP_SYS_NICE` or `RLIMIT_NICE` allows lowering it back, a CPU limit Perl's process has used up, ignoring SIGCHLD. On Linux the nice value belongs to each thread; ignored signals and limits to the whole process.
⁷ Approach 2 stands for a posix_spawn that does only the redirections, so it turns off the code of note 6; at approach 4, Run's spawn is called without that code.

On Windows (no fork, so no approach 3), at approach 1 the descriptors, the directory, a new process group, and the nice value and limits (as the child's own priority class and job; a limit Windows has no counterpart for is R) are given to `CreateProcessW`: C. `closefrom` is part of the list of handles passed: C. `sigmask`, `sigdefault` and `resetids` need nothing there (a Windows child inherits no signal mask or signal actions, and Windows has no set-user-ID). One exception to C: the inheritable copies of the handles to be passed exist in Perl's process during the call, so a child that another thread starts at that moment with inherited handles could take them. The umask is A if asked for, as on POSIX (ShellSpawn does not ask for it on Windows); `setsid`, `tcsetpgrp`, `sched` and `cgroup` are R, and so is `sigignore`, except for SIGPIPE, and SIGINT in a new process group, which need nothing on Windows. At approach 2 the descriptors are as at approach 1, with the same exception. At approach 4 Run makes the descriptors around Perl's own spawn, and for every call Perl's descriptors from 3 up are made not inheritable and put back after it: A. The rest: [section 8 of `doc/pspawn-spawner.md`](doc/pspawn-spawner.md).

**Running a snippet** (a shell command string given to `Proc::ShellSpawn`'s `run()`). ShellSpawn starts every program of a snippet with the snippet's umask (not on Windows), with the signals Perl ignores set back to their default (except those that were ignored already when ShellSpawn was loaded, those the snippet ignores itself, and SIGINT and SIGQUIT in a background job), and in the snippet's directory where it differs from Perl's: so on POSIX each start changes Perl's umask around the call, and, by the table, its signal actions and directory at approaches 2 to 4. Besides, at every approach:
- while `run()` runs: SIGINT, SIGQUIT and SIGPIPE are ignored, and the snippet's traps are set in `%SIG`;
- while a redirection's file is opened: Perl's umask is the snippet's;
- on POSIX, while the event loop waits for children, and between `run()` calls while background jobs remain: the loop installs its own SIGCHLD handler in place of the program's. It waits only for its own children, each by its process ID.

**So, with several threads:**
- A start whose settings are all C (at approach 1: no `umask`, `sigignore`, `rlimit` or `nice`, and the C library has every option asked for) changes nothing of Perl's process (but for note 2, and Windows' handles), so such starts may be made in several threads at once.
- Any other start, and every run of a snippet, should be made from one thread at a time: two at once could put back each other's changes. For the moment of such a start, the other threads should not use the parts of Perl's process that its A settings change: write to its descriptors, use its directory (a relative file name), create a file (the umask), rely on its signal mask or signal actions, its process group, its effective ids, its limits or its nice value, or start a child of their own.
- While a snippet runs, the other threads cannot rely on Perl's actions for SIGINT, SIGQUIT and SIGPIPE, on `%SIG` (the snippet's traps), or, while a redirection's file is opened, on the umask; on POSIX, while the loop waits and while background jobs of a snippet remain, on SIGCHLD.
- A design note: an explicit `fork()` could move all of this out of Perl's process: the settings into the child before its exec, and the shell's own state into a child that runs the snippet. The modules do neither: approach 3 forks, but does nothing in the child before its exec ([`TODO`, F1](TODO.md#my-f1)).

## <a id="my-copyright-and-licence"></a>Copyright and licence

Copyright (C) 2026 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.22.2 or, at your option, any later version of Perl 5 you may have available.
