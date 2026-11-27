# The corpus samples and the run's environment (known issue [X27](../pspawn-known-issues.md#my-x27))

**The question.** [Section 7 of `large-subset-state.md`](large-subset-state.md#my-section-7) compares how dash, `bash --posix` and `Proc::ShellSpawn` (*ShellSpawn* below) run shell snippets taken from public collections (the *corpus*). Each of the 40,409 snippets that the large parser (`Proc::ShellSubset::Large`, [section 8](#my-section-8)) accepts, all of which `dash -n` and `bash --posix -n` accept too, is a *sample* below. Each sample runs once in each of the three shells, all in the same environment (*the run*; *the base run* where other runs are compared with it):

- every run starts in a fresh copy of the same small directory, the *fixture* (the files `a.txt`, `b.txt`, `file.txt`, `c.log`, `.hidden`, `empty`, `dir/x.txt`, `dir/sub/y.sh`, and `home/`, which is `HOME`), with a few fixed variables (`PATH`, `HOME`, `LANG=C`, `LC_ALL=C`, `USER`, `LOGNAME`, `TERM=dumb`, `SHELL=/bin/sh`, `TMPDIR`, and the recorders' own), no arguments, and `/dev/null` as its standard input; in the run of the whole library (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)) and in steps 2 and 3 also a fresh `/tmp`, a fixed `/dev/urandom` and fixed file times (`-env tmp,random,mtime`, [section 9](#my-section-9)), but not in the base runs of section 9's variants;
- the programs a sample may call are the names of [`tools/large-subset-programs.txt`](tools/large-subset-programs.txt) (the programs of a Linux system); any other name is "not found" in all three shells (decision A23 (b)); since post-0.13, in step 3 and in the variants `fail`, `output` and `mtime`, each program a sample calls that is not on the list and is no builtin gets a stand-in for that sample's runs alone ([X84](../pspawn-known-issues.md#my-x84), decided 2026-11-23 (D6)), but the runs reported below were made before;
- each of those names is a *recorder* ([`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl)), which logs the call; for most programs it then exits with status 0 and no output (the program is *only logged*); for a fixed list of tools that only read, print or make files (`cat`, `grep`, `sed`, `awk`, `sort`, `xargs`, `ls`, `mkdir`, …; not `rm`, `mv`, `cp`, `ln`), it then runs the real program. The programs ShellSpawn runs in place of the shells' builtins (`echo`, `printf`, `test`, `[`, `true`, `false`, `pwd`, `kill`) are run without a log, as the builtins leave none;
- the recorder of a program only logged reads what the sample feeds it (a pipe, a file given by `<`, a here-document), to the end or to 64 KB, and logs its size and SHA-256 (decision IN1), unless the program never reads its standard input (`rm`, `mv`, …), or is `zcat` naming a file (decision A24 (b)).

An agreement of the three shells in that run is a real one only if the comparison could not come out otherwise in another environment (other files, variables, programs' answers, …). For every sample, this document says whether that is shown, and if not, what the comparison may depend on. The record, one line per sample: [`large-subset-provenance.tsv`](large-subset-provenance.tsv) ([section 2](#my-section-2)). First made 2026-11-07.

**The method** is the user's (2026-11-07): parse all the samples in one batch, split them into *atomic blocks* (single commands and the like, [section 4](#my-section-4)) marked with their samples, and sort the blocks with a filter that passes only what is shown to be unaffected by the environment. A pass is meant to be definite (under the assumptions it names); a block that does not pass gets no verdict either way. The tool, [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl), works from the parse trees alone: it runs nothing. It takes programs as real and opaque: it knows what the shell does with a program (looks it up, hands it words and descriptors, takes its output or its status), not what the program does.

### <a id="my-words-used-below"></a>Words used below

- *Level* of a sample: how far its comparison can change with the environment (strict, held, almost strict, …; [section 1](#my-section-1)).
- *Code*: the name of one thing a comparison needs or may depend on (`program`, `pipeline`, `files`, …; [section 3](#my-section-3)). For a held or almost strict sample its codes are *assumptions*, which must hold for the level to hold; for an undecided sample they name what the comparison may depend on.
- *Class* of a sample in one run (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), with the label the records use:
  - *same* (`same`): all three agree;
  - *messages only*: all three agree but for the error messages, and ShellSpawn's are worded as dash's (`msg=dash`), as bash's (`msg=bash`), or as neither shell's (`msg-own`);
  - *ShellSpawn differs* (`SHELLSPAWN`; `OURS` in reports made before 2026-11-23): dash and bash agree, ShellSpawn does not, beyond the messages;
  - *shells differ*: dash and bash differ beyond the messages, and ShellSpawn agrees with dash (`=dash`), with bash (`=bash`), or with neither (`neither`);
  - *timeout* (`timeout`): a shell ran out of time (5 seconds); the rest is not compared.

  Below, "ShellSpawn as dash" is `=dash`, "ShellSpawn as neither" is `neither`, "messages as dash's" is `msg=dash`, "messages as neither" is `msg-own`, and so on. A sample's class *changes* when another run gives it another label.
- *Messages*: what a shell writes as an error message, worded its own way (dash's `x: not found` against bash's `x: command not found`).
- *Stand-in*: a program replaced by one that gives a chosen output and status, the same in every run. The recorders are stand-ins with status 0 and no output.
- *Setup*: an example environment made for one sample: files made or removed, variables, arguments, input, the programs' answers chosen ([section 10](#my-section-10), [section 12](#my-section-12)).
- *Steps 1 to 4*: the user's plan (2026-11-10; [`TODO`, A1](../../TODO.md#my-a1)): (1) find the samples the environment cannot affect (sections 1–4); (2) for the others, describe exactly how they are affected, and run them in a few example environments (sections 9 and 10; the plan named the samples where only one command is affected, and section 10 also took the 104 where several are); (3) recognize more such samples by simple programmatic tests ([section 12](#my-section-12)); (4) leave the rest to deep AI analysis (Claude reading them, [section 12](#my-section-12)).
- *Ruling*: a decision of the user that allows a given difference between ShellSpawn and dash or bash; a difference so allowed is *legalized*. The rulings: section 1 of [`large-subset-state.md`](large-subset-state.md#my-section-1); those met here, with what each says: the table "The rulings" in [section 11](#my-section-11).
- *Chance*: a result that changes from run to run (races, process IDs, times), so that a difference in it says nothing. *Known chance*: dash and bash agreed and ShellSpawn did not, but in repeated runs dash and bash too give other results.
- Names such as A5, EV1, LV1, K5, IN1: the user's decisions, each recorded where it applies ([`TODO`](../../TODO.md), [`Changes`](../../Changes), section 1 of [`large-subset-state.md`](large-subset-state.md#my-section-1)); X followed by a number: a known issue of ours ([`pspawn-known-issues.md`](../pspawn-known-issues.md)). "[TODO A13](../../TODO.md#my-a13)" is item 13 of part A of [`TODO`](../../TODO.md) (the user's pending decisions). *post-0.12* and the like (also *post2-…*, *post4-…*): the code after release 0.12, before the next release ([`Changes`](../../Changes)).

### <a id="my-names-used-below"></a>Decisions named below

The rulings (A4, A5, B2, G16, Q2, `$0`, rule E, builtin-vs-coreutils, the runner) are in the table "The rulings" of [section 11](#my-section-11). Rule E takes, where dash and bash differ, the behaviour its categories call better; its choices (G2, G12, `cdargs`, …) are the table of [`large-subset-logical.md`](large-subset-logical.md); the match of section 11 applies it only where a line of [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) names it (for a snippet, or for setups that do a given thing, such as `cd` without `HOME`). The other decisions met below:

- A1: the four steps above. A12 (pending): `~` with `HOME` empty, where dash drops the word. A13 (pending): the differences no ruling legalizes yet, to be decided one by one. A17 (pending): results the same in every run that no ruling covers (the order of `env`'s list, `/proc/$$/cmdline`, `times`, the `zenity` subshell). A18: the runner waits up to 5 seconds for each shell's background jobs. A23 (b): the program names of the runs, above; A23 (c): the column `CALLS` ([section 2](#my-section-2)). A24 (b), IN1: the recorders' reading of input, above.
- EC1: ShellSpawn's `echo` may change with `POSIXLY_CORRECT` ([section 9](#my-section-9)). EV1: runs in other environments go into footnotes, not into the levels. IP1: ShellSpawn runs `echo`, `printf`, `test`, `[`, `true`, `false` (and `pwd` since post-0.10) inside Perl, as coreutils does. K3: ShellSpawn's background jobs go on between calls. K5: at exit ShellSpawn leaves its background jobs running, as the shells do. K6: differences of start-up timing are chance. LV1: the samples almost strict only by `passthrough` are counted apart ([section 1](#my-section-1)). NV1: `exit`, `return`, … given an operand that is no number act as the shells. P1: aliases defined at run time are taken when the text gets there. SP1: strict needs no code for the commands of IP1 ([section 3](#my-what-every-level-assumes)).

## <a id="my-section-1"></a>1. The answer in short

| Level | Samples | Share |
|---|---|---|
| **strict** (S): the comparison cannot change with the environment; assumed is only what every level assumes (each shell started as in the run, …: [section 3](#my-what-every-level-assumes)) | 365+27=392 ³ | 1.0 % |
| **held** (H): the same, under assumptions known to hold in every environment tested (Linux, Linux without `/proc`, Windows under Wine): `devnull`, `heredoc` | 2 | 0.0 % |
| **almost strict** (A): the same, if the assumptions named in the sample's code hold ([table 1](#my-table-1)) | 34,301 ¹ | 84.9 % |
| **with values passed on unchanged, not in preceding rows**: the same, if also every value the sample takes from the environment only passes through the shell unchanged (assumption `passthrough`; step 3, [section 12](#my-section-12); the user, 2026-11-12) | 664+7=671 ¹ ³ | 1.7 % |
| **with values passed on split, not in preceding rows**: the same, but some of those values are split into words and matched against file names before they reach a program (assumptions `passthrough` and `splitglob`; no sample needs `splitglob` alone) | 1,476+7=1,483 ¹ ³ | 3.7 % |
| **undecided** (U): not shown to be unaffected (which does not mean it is affected); the codes name what the comparison may depend on | 3,508+52=3,560 ² ³ | 8.8 % |
| of them **partially decided** (P; the user, 2026-11-10): step 3's classes control and affects-shell ([section 12](#my-section-12)): every dependence named exactly (which file, which variable, …), and the sample run in example setups that vary them, where a setup could be made (sections 10 and 12) | 3,508 | 8.7 % |
| of them the rest: 52 of the 93 samples the setups left out; Claude read all 93, put 41 in the rows above (the *M* there: 27+7+7=41) and left these 52 undecided (by category: AI-names with an expansion 26, AI-tilde 6, AI-A5 5, AI-glob 4, AI-shells' own variables 4, AI-PATH-twister 4, AI-noise 3, 26+6+5+4+4+4+3=52; [section 12](#my-section-12)) | 0+52=52 ³ | 0.1 % |

The six rows that are not "of them" take every sample: 392+2+34,301+671+1,483+3,560=40,409. The levels run from the most certain (strict) to the least (undecided), in the order of the table.

¹ These samples were also run in another environment ([section 9](#my-section-9), where the counts are; they are of the runs of 2026-11-22): those that need `echo`, `locale`, `pipeline` or `devfd` with that assumption's other case (`POSIXLY_CORRECT` set, another locale, SIGPIPE ignored, `/proc` hidden); those that need `path-var`, `path-home`, `path-mnt` or `path-dev` with those places empty or private. The two rows "with values passed on …" ran also in the variants of footnote 2, for the codes named inside their `passthrough(…)`. Section 9 says how many came out otherwise, and how. The runs do not change a sample's level, which comes from the texts alone: the parse trees, and Claude's reading for the *M* of footnote 3 (the user, 2026-11-08, EV1: the runs go into footnotes, not into the levels).

² These samples were also run in other environments ([section 9](#my-section-9), as in footnote 1): those with `path-tmp` with a fresh `/tmp`; those with `path-random` with a fixed `/dev/urandom`; those with `prog-status` or `prog-output` with stand-ins (every program only logged answering with status 1, or with a chosen output); those with `time` with fixed file times; those that would also need the assumptions of footnote 1 as there. They stay undecided (EV1).

³ *N*+*M*=*T*: *N* samples were sorted programmatically (from the parse trees and the rules of step 3), *M* by Claude (an AI) reading them (the categories AI-…, the user's, 2026-11-13; [section 12](#my-section-12)). AI-strict counts as strict, AI-values passed on unchanged and AI-values passed on split in those two rows; every other AI- category leaves a sample undecided. Where *M* is 0, *N* alone is given.

The two rows "with values passed on …" are counted apart from almost strict (LV1, the user, 2026-11-13: they do not deserve the same trust). In the record they keep the letter A; their codes `passthrough` and `splitglob` tell them apart. The 93 samples Claude classified keep the letter U in the record, whatever their category ([`tools/large-subset-ai-classes.tsv`](tools/large-subset-ai-classes.tsv) has it), so the record has 3,601 lines `U` (3,560+27+7+7=3,601).

**By source** (*N*+*M*=*T* as in footnote ³):

| Source | strict | held | almost strict | passed on unchanged | passed on split | undecided | all |
|---|---|---|---|---|---|---|---|
| tldr | 62+3=65 | 0 | 27,603 | 99+1=100 | 277+1=278 | 1,178+7=1,185 | 29,231 |
| NL2Bash | 99+17=116 | 0 | 6,383 | 467+5=472 | 1,116+5=1,121 | 1,919+28=1,947 | 10,039 |
| ShellCheck | 185+7=192 | 1 | 287 | 78+1=79 | 79+1=80 | 370+12=382 | 1,021 |
| the bash Cookbook, pure-sh-bible and pure-bash-bible | 19 | 1 | 28 | 20 | 4 | 41+5=46 | 118 |
| all | 392 | 2 | 34,301 | 671 | 1,483 | 3,560 | 40,409 |

Strict is small because nearly every sample runs a program, and every program needs the assumption `program`.

## <a id="my-section-2"></a>2. The record: [`large-subset-provenance.tsv`](large-subset-provenance.tsv)

One line per accepted sample, sorted by snippet ID, after a header of `#` lines that says what follows and points here:

```
ID<TAB>CODE<TAB>CALLS
```

- `ID`: the snippet ID, which says where the text comes from: `TL:` the examples of the tldr pages (29,231), `NB:` the NL2Bash collection of commands with English descriptions (10,039), `SC:` the test cases in ShellCheck's source (1,021), `BC:` the bash Cookbook (26), `PS:` pure-sh-bible (43), `PB:` pure-bash-bible (49) (format: [`../parsers/shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md#my-section-2), section 2; [`tools/large-subset-extract.pl`](tools/large-subset-extract.pl) remakes the texts from the pinned sources, see [section 6](#my-section-6)).
- `CODE`:
  - `S`: strict.
  - `H:a,…`: held; the assumptions `a`, … are known to hold in every environment tested ([section 3](#my-section-3), table 1).
  - `A:a,b,…`: almost strict; the comparison cannot change if the assumptions `a`, `b`, … hold ([section 3](#my-section-3), table 1; held ones may be among them). `passthrough(r,s)`: the assumption `passthrough`, with the undecided codes `r`, `s` whose values only pass through the shell (step 3, [section 12](#my-section-12)).
  - `U:r,s,…` or `U:r,s,…/a,b,…`: undecided; the comparison may depend on `r`, `s`, … ([section 3](#my-section-3), table 2); after `/`, the assumptions it would also need if those were settled.
- `CALLS`: what each sample calls, marked with the shells that called it (A23 (c), the user, 2026-11-17: kept for later use).
  - *The names*: the command names the sample's parse tree runs, space-separated, each once, in the order met. A name is the first word of each command as written (builtins, functions and programs alike); after `command` or `exec`, the name after its options; `cd`, `export`, `readonly` and `local` too, which the parse tree keeps apart from other commands. `?` stands where an expansion makes a command's name. A space, tab, newline, `%`, `!`, `+`, `=`, `?`, `:` or `\` in a name is written `%XX`. [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) `-e` writes the names from the parse trees alone (`make corpus-provenance`, seconds).
  - *The marks*: after the behaviour run (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), [`tools/large-subset-calls.pl`](tools/large-subset-calls.pl) marks each name shell by shell (`make corpus-calls`, part of `make corpus-all`) as `NAME:DBO`, one letter each for dash, bash and ShellSpawn: `p` if that shell's run started a program of that name (the shell itself, or a program it ran, such as `xargs` or `find -exec`, as the recorders logged it); `!` if that shell said the name was not found; `-` if neither. A name with `-` in all three gets no mark: it is a builtin, a function, or not reached. `=NAME:DBO` is a program started, or a name not found, that the text does not write as a command (an expansion made it, or a program started it).
  - *The counts* (the run of 2026-11-22, post-0.13): 48,784 names marked; 26,104 of them `!!!` (not found in all three: the programs not on the runner's list, A23); 22,024 `ppp`; 651 where dash and bash differ; 5 where dash and bash agree and ShellSpawn does not (`--!` 4, `--p` 1); 26,104+22,024+651+5=48,784. Of the 651: `!--` 210, bash's own builtins that dash lacks (`history`, `bind`, `help`, `fc`); `!-!` 194, names that bash reports otherwise (`time`, a keyword in bash; a name with a slash, "No such file or directory"); `-!!` 215, below; 32 others (210+194+215+32=651).
  - *Marks that vary by timing*: dash's "not found" messages of pipeline elements mix with other output by timing, and are then not read as such; they show as `-!!` (215 names) and as names `=not%20found…` (101); both are among the 48,784. So do most `--!`: names such as `path/to/directory` whose messages mixed in both shells.
  - *Other runs*: the run of 2026-11-17 (with IN1 and A24 (b)): 48,800 names, 26,072 `!!!`, 22,024 `ppp`, 694 where dash and bash differ (the other 10: dash = bash ≠ ShellSpawn, `--!` 9, `--p` 1), `-!!` 254, `=not%20found…` 116. The first run of 2026-11-17 (IN1 alone): 48,799 names, 26,075 `!!!`, 22,024 `ppp`, 690 where dash and bash differ (the other 10: dash = bash ≠ ShellSpawn), `-!!` 251, `=not%20found…` 115. The run of 2026-11-16: 48,811, 26,019, 22,024 and 759 (the other 9: dash = bash ≠ ShellSpawn), `-!!` 307, `=not%20found…` 127: the mixed messages came out less often once a program only logged read its input (IN1).

Examples (the first two columns):

```
TL:common/tar.md:13	A:program
NB:4723	A:program,pipeline
NB:10035	A:program,path-system
BC:ch03/func_choice.2	U:vars/program
NB:8081	A:program,pipeline,passthrough(files,prog-output),splitglob
BC:ch14/finding_tools	A:program,path-system,passthrough(prog-output)
NB:10071	U:path-tmp/program
SC:Analytics.hs:prop_checkOverwrittenExitCode7	S
```

Reading it (from the distribution's directory; `F=doc/large-subset/large-subset-provenance.tsv`):

```sh
grep -P '^NB:4723\t' $F                                      # one sample
grep -v '^#' $F | cut -f2 | cut -c1 | sort | uniq -c        # samples by level
grep -v '^#' $F | awk -F'\t' '$2 ~ /^[AH]:/' | cut -f2 | sed 's/([^)]*)//' | sort | uniq -c | sort -rn   # table 3 below
grep -v '^#' $F | awk -F'\t' '$2 ~ /^U:([^/]*,)?path-tmp([,\/]|$)/'               # undecided by path-tmp
grep -v '^#' $F | cut -f3 | tr ' ' '\n' | grep ':!!!$' | sed 's/:.*//' | sort | uniq -c | sort -rn | head   # not found in all three
```

## <a id="my-section-3"></a>3. The codes

**At a glance.** Every code, one line each. "Level": the level the code puts a sample in: H held, A almost strict (`passthrough` and `splitglob`: the rows "with values passed on …" of [section 1](#my-section-1), LV1), U undecided. "Samples": for an H or A code, the samples of the levels held, almost strict and "with values passed on …" that need it; for a U code, the 3,601 samples the record marks U (the undecided, and the 41 that Claude's reading moved, [section 1](#my-section-1)) that have it (a sample can have several codes). "Control": whether the runs could make the case fixed, or try the other one. Tables 1 and 2 below say more.

| Code | Level | Definition | Samples | Control |
|---|---|---|---|---|
| *programs* | | | | |
| `program` | A | A program is run (any command that is not a builtin or a function of the text); assumed: looked up alike, gets the same words, descriptors and environment, does the same in each run, does not act on the shell | 36,252 | stand-ins only |
| `devnull` | H | a redirection to `/dev/null`: dash and bash have it (POSIX); ShellSpawn on Windows gets `NUL` (Perl's open, and [`win_spawn.h`](../../win_spawn.h) since X31's fix). Given to a program as a word it is the program's business: no code | 59 | held |
| `devfd` | A | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N` are used (on Linux: needs `/proc`) | 12 | yes |
| `heredoc` | H | a here-document with expansions or of 4,096 bytes or more: bash may use a temporary file (`TMPDIR`, else `/tmp`, which every tested system has); ShellSpawn uses a pipe | 3 | held |
| *where a program is pointed (an absolute path in its words)* | | | | |
| `path-system` | A | `/etc /usr /bin /sbin /lib* /opt /boot`: read-only for the run's user | 429 | not needed |
| `path-var` | A | `/var` (not `/var/tmp`): logs, spool, web roots | 137 | yes (private mount) |
| `path-home` | A | `/home`, `/root`: absent or closed | 330 | yes (private mount) |
| `path-dev` | A | a device (`/dev/sdX`, ttys): absent or closed | 427 | yes (private `/dev`) |
| `path-mnt` | A | `/mnt`, `/media`, `/srv` | 69 | yes (private mount) |
| `path-absent` | A | a top directory Linux has not (`/path/to/…`; also words like `/re/d` taken for paths) | 1,047 | yes (make it) |
| `path-tmp` | U | `/tmp`, `/var/tmp`, `/dev/shm` (also redirected to): shared and writable, the runs meet there | 207 | yes (fresh tmpfs) |
| `path-random` | U | `/dev/urandom`, `/dev/random` | 25 | yes (fixed file) |
| `path-proc` | U | `/proc`, `/sys`, `/run`: state of processes and kernel | 49 | no |
| `path-root` | U | `/` itself: the whole tree (`find /`) | 532 | only a container |
| *how the shells are run* | | | | |
| `pipeline` | A | a pipeline: assumes SIGPIPE at its default (a writer whose reader stops early dies silently) | 4,777 | yes |
| `locale` | A | locale-bound forms: bracket expressions or non-ASCII in patterns, `test`'s `<` `>`, `printf %f %q` | 15 | yes (a second locale) |
| `echo` | A | `echo` with a backslash, a leading `-`, or expanded words: assumes `POSIXLY_CORRECT` unset | 110 | yes (one more run) |
| *values from the environment (step 3, [section 12](#my-section-12))* | | | | |
| `passthrough` | A | every value from the environment only passes through the shell: quoted into a program's words, into an assignment, a `case` word or a here-document; a program's output going on; a status choosing between branches all alike; `pwd`; bash's interactive builtins (no file options); assumed: the three hand such a value on unchanged, whatever it is | 2,140 | probed |
| `splitglob` | A | such a value split and matched against files in a program's words (or a pattern of the text there); assumed: the three split and match any value alike, but for `[^…]`, `.*` and `//` after a pattern component | 1,476 | probed |
| *files and places the shell itself uses* | | | | |
| `files` | U | pathname expansion; a redirection to or from a file (`2>errfile` too); `test -e` and the like; `.`; `./cmd` | 1,464 | yes (fixtures) |
| `directory` | U | `cd`, `pwd`: the working directory, `HOME` | 147 | yes |
| `tilde` | U | `~` (`HOME`), `~user` (the user database) | 269 | partly |
| *values* | | | | |
| `vars` | U | a variable read before the text sets it (from the environment, or unset) | 402 | yes (chosen values) |
| `unquoted` | U | an unquoted expansion of a value not known here to be free of `* ? [`; unquoted `$( )` | 327 | yes |
| `args` | U | `$1`, `$@`, … at the top level with no `set` before (none were given) | 112 | yes |
| `start` | U | `$0`, `$-`: how the shell was started | 43 | partly |
| `name` | U | a command name from an expansion | 73 | yes |
| `test-ops` | U | `test` whose expression's shape depends on expanded operands | 68 | yes |
| `eval` | U | `eval` or a trap action of a text not literal, or rejected by the parser | 19 | partly |
| `input` | U | `read` from the run's standard input | 56 | yes (chosen input) |
| `listing` | U | `env`, `printenv`, `export`, `readonly` alone: print the environment | 28 | no |
| *a program's results, taken by the shell* | | | | |
| `prog-output` | U | the shell uses a program's output (`$( )`, a pipe into `read`, a loop, a function) | 509 | stand-ins only |
| `prog-status` | U | a program's status decides (`&&`, `\|\|`, `!`, `if`, `while`; `$?` after it; under `set -e`) | 35 | stand-ins only |
| `status` | U | `$?` at the start of a function's body or a trap action: what ran before is not in the text | 4 | no |
| *chance* | | | | |
| `race` | U | the order of events: `&`, `xargs -P`, a compound command or a function writing into a pipe | 86 | no |
| `pid` | U | `$$`, `$!`, `$PPID`; `kill`, `wait`, `jobs`, `fg`, `bg` with operands | 103 | no |
| `time` | U | `times`, `$SECONDS`, bash's `time`, `printf '%(…)T'`, `date`, `stat`, `ls -l` | 223 | partly (fixed file times; stand-ins) |
| `random` | U | `shuf`, `mktemp`, `uuidgen`, `sort -R` | 72 | only stand-ins |
| *the machine's setup* | | | | |
| `lookup` | U | `command -v`, `type`, `hash`: what is installed | 6 | yes (fixed `PATH`) |
| `limits` | U | `ulimit`; `umask` alone | 6 | partly |
| `fd` | U | a descriptor above 2 not opened by the text (`>&3`), `test -t`, `set -m` | 5 | yes |
| `interactive` | U | `history`, `fc`, `bind`, `help`, `compopt`, `logout` (B2) | 22 | partly |

### <a id="my-table-1"></a>Table 1: the assumptions of "held" and "almost strict"

"Needed by": the held or almost strict samples whose level needs the assumption (a sample can need several; table 3 has the combinations). "Under our control": whether the runs could make the assumption true, or try the other case.

| Code | The assumption | Needed by | Under our control |
|---|---|---|---|
| `program` | An external program (looked up on `PATH`, or named by a path): the three shells look it up alike and hand it the same words, descriptors and environment; it does the same in each run (no clock, no randomness, no process IDs of its own), does not act on the shell (`killall bash`), and does not mind the variables a shell adds to the environment it passes (bash: `SHLVL`, `_`). Its output, status and effects are then the same for all three, as long as the shell does not use them (that is `prog-output`, `prog-status`). Programs known to break it are undecided instead (`time`, `random`, `race`), but that list cannot be complete (`ping`, `top`, network clients). | 36,252 | Only by replacing programs with stand-ins that behave the same in each run, as the run's recorders do (then the programs themselves are not exercised). |
| `pipeline` | A pipeline: its elements run at once; when a reader stops before the end of its input, the writer is killed by SIGPIPE, silently, and only the last element's status counts. That holds with SIGPIPE at its default. If the environment ignores SIGPIPE (it is inherited), a writer instead gets an error and may print a message (bash's builtins print "write error: Broken pipe"), so the messages may differ. | 4,777 | Yes: the runner starts the shells with SIGPIPE at its default ([`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) does). A second run with SIGPIPE ignored would try the other case. |
| `devnull` | **Held.** A redirection to `/dev/null`: a POSIX system has it, so dash and bash do; on Windows ShellSpawn gets `NUL` from Perl's own `open` (for the shell layer) and from [`win_spawn.h`](../../win_spawn.h) (for `Proc::Spawner`'s open action; X31, fixed and checked under Wine). `/dev/null` given to a program as a word is no code: what the program does with it is the program's business, the same under every shell. | 59 | Held in every tested environment. |
| `devfd` | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N`: on Linux these are links into `/proc/self/fd`, missing where `/proc` is not mounted (X28's check without `/proc`). bash 5.2.21 does not emulate them then (it emulates them only where it was built without them; checked 2026-11-08: `echo x > /dev/stderr` with `/proc` hidden fails in all three shells, bash with status 1, dash and ShellSpawn with 2). | 12 | Yes: `/proc` mounted, or not. |
| `heredoc` | **Held.** A here-document whose body has expansions, or 4,096 bytes or more: bash may then write it to a temporary file (in `$TMPDIR`, else `/tmp`), which works wherever there is a writable `/tmp`. Smaller literal bodies go through a pipe in all three, so they are strict; ShellSpawn always uses a pipe (`Proc::ShellSpawn`, redirections). The bound is cautious: bash 5.2.21 on Linux (checked 2026-11-18 with `strace`) uses a pipe for bodies up to 65,536 bytes, with expansions or without, and a temporary file beyond, in `/tmp` even with `TMPDIR=/nonexistent`; other versions and systems may differ. | 3 | Held in every tested environment. bash takes `TMPDIR` (the run sets it to the run's directory), and `/tmp` where that is not usable. |
| `locale` | A bracket expression or non-ASCII text in a pattern, `test`'s `<` and `>`, `printf`'s `%f %e %g %a %q` and its `'` flag: the locale as in the run (`LANG=C`, `LC_ALL=C`). | 15 | Yes: a second run with another locale (`C.UTF-8`) tries the other case for these samples alone. |
| `echo` | `echo` with a backslash, a first word starting with `-`, or words from expansions: `POSIXLY_CORRECT` unset. It changes coreutils `echo` (which ShellSpawn runs; rule "the program beats the shells' difference") but not dash's or bash's builtin. It is a switch of two values, so one more run of these samples with `POSIXLY_CORRECT=1` settles them: their runs double, nobody else's. (`POSIXLY_CORRECT` also changes other GNU programs, such as `ls dir -l`, but the same way in all three shells: that is within `program`.) | 110 | Yes. |
| `path-system` | A program is given a path under `/etc /usr /bin /sbin /lib* /opt /boot`: read-only for the run's unprivileged user, so the runs cannot change it, and the same in each run unless the system itself changes. | 429 | Nothing needed (a read-only snapshot would make it certain). |
| `path-var` | … under `/var` (not `/var/tmp`): logs, spool, web roots; they change with time, mostly closed to the run's user. | 137 | Yes: a private mount over `/var` for each run (`unshare -m`). |
| `path-home` | … under `/home` or `/root`: absent or closed to the run's user. | 330 | Yes: a private mount. |
| `path-dev` | … a device under `/dev` (disks, ttys, `/dev/input/mice`), not `/dev/null`: absent or closed to the run's user, so every run fails alike. | 427 | Yes: a private `/dev`. |
| `path-mnt` | … under `/mnt`, `/media`, `/srv`: empty mount points or absent. | 69 | Yes: a private mount. |
| `path-absent` | … under a top-level directory a Linux system does not have (`/path/to/…`, `/some/dir`, macOS's `/Users`; also words like a `sed` script `/re/d` or a Windows switch `/v`, taken for paths): nothing is there, so every run fails alike. | 1,047 | Yes: make it in a private mount namespace, if the sample should be exercised with something there. |
| `passthrough` | Every value the text takes from the environment (a variable read before the text sets it, an argument, a program's output, the working directory, a glob's matches) only passes through the shell: it goes quoted into a program's words, into an assignment, a `case` word or a here-document, or a program's output goes on without the shell reading it; a program's status only chooses between branches whose commands are all alike in the three; `pwd`; bash's `history`, `fc -l`, `bind`, `help` in a non-interactive shell (no file options). The three hand such a value on unchanged, whatever it is. Not passthrough (the sample stays undecided): the value going into another builtin (`set`, `export`, `kill`, `eval`, …), arithmetic, `${x:?}`, `set -u`, `set -e`, the shells' own variables (`PATH`, `PWD`, `SHLVL`, `RANDOM`, …), a value the shell makes itself (`$$`, `$SECONDS`). | 2,140 | Probed: [`tools/large-subset-valueprobe.pl`](tools/large-subset-valueprobe.pl) (`make probe-values`), 22 odd values (NUL bytes, trailing newlines, invalid UTF-8, a leading `-`, 100,000 bytes) through 11 forms: the three alike (2026-11-12). |
| `splitglob` | A value from the environment unquoted in a program's words or a `for` list, or a pattern of the text there: the three split it at `IFS` and match it against the files alike. Known exceptions, each a difference of dash and bash: `[^…]` (dash takes `^` literally; not legalized, [`TODO` A13](../../TODO.md#my-a13); a sample whose own text has a pattern with `[^` there gets no `splitglob` and stays undecided), a pattern for dot names such as `.*` (dash also gives `.` and `..`; rule E, G2: ShellSpawn as bash), `//` after a pattern component (bash collapses it; ShellSpawn as dash, A5). | 1,476 | Probed: the same tool, 45 values in 5 forms with files there: alike but for the three exceptions (the probe also found X52, fixed). |

### <a id="my-what-every-level-assumes"></a>What every level assumes

Every level, strict included, assumes:

- each shell is started as in the run: its options, and the variables that steer the shell itself, such as `SHELLOPTS` and the locale;
- descriptors 0–2 open; no signal from outside; enough memory, processes and disk;
- the commands ShellSpawn runs in place of builtins behave as the programs: `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd` as coreutils (X21), `kill` as procps' `kill`.

Since release 0.10 ShellSpawn runs these commands inside Perl by default (decision IP1; `pwd` since post-0.10; not `kill`, which runs the program), so the last assumption no longer depends on the system, apart from X21's differences and `kill`. Before IP1 it held only on a POSIX system, like `devfd` and the `path-` codes: on Windows it failed, and every sample that runs one of these programs would have to be judged again (142 of the strict ones do). Closed (the user, 2026-11-10, SP1): since IP1 these programs run the same on every platform, so strict needs no code for them. Under Wine, [`t/programs.t`](../../t/programs.t) checks the programs alone, not on these samples (running the library under Wine is in [`TODO`](../../TODO.md)).

`devnull` and `heredoc` are known to hold on Windows too, so they form the level "held": an assumption is *held* when it is checked to hold in every environment we test. The level can grow as more assumptions are checked.

### <a id="my-table-2"></a>Table 2: the codes of "undecided"

"Decides": of the 3,601 samples the record marks U, those that have the code / those that have no other undecided code.

| Code | What the comparison may depend on | Decides | Under our control |
|---|---|---|---|
| `files` | What the directory holds: a pattern in a word (pathname expansion), a redirection to or from a file (`2>errfile` included: whether it exists, its type, contents, permissions), `test`'s file operators, `.`, a command named by a relative path (`./script`). | 1,464 / 1,202 | Yes: fixtures (the files the samples name). |
| `directory` | The working directory or `HOME`: `cd`, `pwd`. | 147 / 47 | Yes: chosen directories. |
| `vars` | A variable read before the text sets it: from the environment, or unset. | 402 / 164 | Yes: chosen values. |
| `unquoted` | An unquoted expansion whose value is not known here to be free of pattern characters (it is split and matched against files); unquoted `$( )`. | 327 / 10 | Yes: chosen values and fixtures. |
| `args` | Positional parameters at the top level with no `set` before them: none were given. | 112 / 41 | Yes: chosen arguments. |
| `start` | `$0`, `$-`: how the shell was started. | 43 / 5 | Partly: each shell gets its own `$0` (its path), unless `-env samearg0` gives all three `sh` ([section 12](#my-section-12)). |
| `status` | `$?` at the start of a function's body or of a trap action: the status of a command the text does not show. | 4 / 0 | No. |
| `prog-output` | The shell takes a program's output: in `$( )`, or through a pipe into `read`, a loop or a function. | 509 / 40 | Only with stand-ins of chosen output. |
| `prog-status` | A program's status decides: `&&`, `\|\|`, `!`, the condition of `if`, `while`, `until`; `$?` after it (also in a loop, from the round before); a command after it under `set -e`. | 35 / 1 | Only with stand-ins of chosen status. |
| `race` | The order of events: a command in the background (`&`), `xargs -P`, a compound command or a function writing into a pipe (if the reader stops early, its later commands die or not, by timing). | 86 / 53 | No. |
| `pid` | `$$`, `$!`, `$PPID`; `kill`, `wait`, `jobs`, `fg`, `bg`, `disown` with operands. | 103 / 54 | No. |
| `time` | `times`, `$SECONDS`, bash's `time`, `printf '%(…)T'`; the programs `date`, `stat`, `ls -l` (`-t`, `-c`, `-u`: each run's copy of the directory has new file times). | 223 / 100 | Partly: the file times of the run's copy can be fixed (`-env mtime`, [section 9](#my-section-9)), and `date` is a stand-in; the shells' own clocks not. |
| `random` | The programs `shuf`, `mktemp`, `uuidgen`, `sort -R`. | 72 / 20 | Only with stand-ins (`shuf`, `mktemp`, `uuidgen` are only logged, so stand-ins already; `sort` runs for real). |
| `input` | `read` from the run's standard input. | 56 / 36 | Yes: chosen input. |
| `listing` | `env` or `printenv` alone (they print the environment the shell passes, which differs between the shells); `export`, `readonly` alone. | 28 / 21 | No: bash adds its own variables. |
| `lookup` | `command -v`, `command -V`, `type`, `hash`: what is installed. | 6 / 6 | Yes: a fixed `PATH`. |
| `limits` | `ulimit`; `umask` alone (the inherited mask). | 6 / 6 | Partly: the runner fixes the CPU, file-size and process limits (`prlimit`); the mask is inherited from the runner. Runs with other limits: not started ([section 9](#my-section-9)). |
| `fd` | A descriptor above 2 that the text did not open (`>&3`), `test -t`, `set -m` (job control needs a terminal). | 5 / 2 | Yes: the runner's descriptors. |
| `tilde` | `~` (`HOME`) and `~user` (the user database). | 269 / 197 | Partly: `HOME` yes. |
| `name` | A command name from an expansion. | 73 / 1 | Yes: chosen values. |
| `test-ops` | `test` or `[` with an unquoted operand from an expansion, or more than 3 operands one of which is an expansion: the shape of the expression is not known here. | 68 / 2 | Yes: chosen values. |
| `eval` | `eval`, or a trap action, of a text that is not literal or that the parser rejects. Literal ones are parsed and judged like the rest. | 19 / 2 | Partly. |
| `interactive` | `history`, `fc`, `bind`, `help`, `compopt`, `logout` (B2): bash reads their state from files and variables. | 22 / 12 | Partly: `HISTFILE`, `INPUTRC`. |
| `path-tmp` | A path under `/tmp`, `/var/tmp`, `/dev/shm`, given to a program or redirected to: shared and writable, so the runs of the three shells meet there (`mkdir /tmp/x`: the second run finds the first one's directory). | 207 / 151 | Yes: a fresh tmpfs on each of them for each run (`unshare -m`). |
| `path-random` | `/dev/urandom`, `/dev/random`. | 25 / 18 | Yes: one fixed file bind-mounted over both for each run. |
| `path-proc` | `/proc`, `/sys`, `/run`: the state of processes and of the kernel (`/proc/self/fd`, PIDs). | 49 / 30 | No: process IDs differ between runs. |
| `path-root` | `/` itself: the whole tree, `/proc` and `/tmp` included (`find / -name x`, `ls -lR /`). | 532 / 464 | Only with a private root (a container or `chroot`). |

### <a id="my-table-3"></a>Table 3: held and almost strict samples by the exact set of assumptions they need

Each such sample is unaffected by the environment if all of its assumptions hold; it is counted once, under its whole set.

| Assumptions | Samples |
|---|---|
| `program` | 28,321 |
| `program` `pipeline` | 3,645 |
| `program` `passthrough` `splitglob` | 953 |
| `program` `path-absent` | 659 |
| `program` `path-dev` | 373 |
| `program` `pipeline` `passthrough` `splitglob` | 347 |
| `program` `passthrough` | 332 |
| `program` `pipeline` `path-absent` | 265 |
| `program` `path-system` | 261 |
| `program` `path-home` | 227 |
| `program` `pipeline` `passthrough` | 193 |
| `passthrough` | 98 |
| `program` `path-var` | 82 |
| `program` `pipeline` `path-system` | 69 |
| `echo` | 56 |
| `program` `pipeline` `path-home` | 51 |
| `program` `path-mnt` | 38 |
| `program` `pipeline` `echo` | 38 |
| `program` `path-absent` `passthrough` `splitglob` | 36 |
| `program` `path-system` `passthrough` `splitglob` | 33 |
| `program` `pipeline` `path-var` | 29 |
| `devnull` `program` | 25 |
| `program` `pipeline` `path-dev` | 23 |
| `program` `pipeline` `path-absent` `passthrough` `splitglob` | 21 |
| `program` `path-home` `passthrough` `splitglob` | 17 |
| `program` `path-dev` `path-absent` | 16 |
| `program` `path-var` `passthrough` `splitglob` | 15 |
| `program` `path-system` `path-absent` | 11 |
| `locale` | 10 |
| `pipeline` | 10 |
| `program` `pipeline` `path-system` `passthrough` `splitglob` | 10 |
| `passthrough` `splitglob` | 9 |
| `program` `pipeline` `devfd` | 9 |
| `program` `pipeline` `path-home` `passthrough` `splitglob` | 9 |
| `devnull` `program` `path-absent` | 8 |
| `program` `path-system` `passthrough` | 8 |
| `devnull` `program` `pipeline` | 7 |
| `program` `path-dev` `path-mnt` | 7 |
| `program` `path-system` `path-home` | 7 |
| `program` `path-home` `path-absent` | 6 |
| `program` `pipeline` `path-absent` `passthrough` | 6 |
| `program` `path-absent` `passthrough` | 5 |
| `program` `path-home` `passthrough` | 5 |
| `program` `pipeline` `path-system` `passthrough` | 5 |
| `program` `path-system` `path-mnt` | 4 |
| `program` `path-system` `path-var` | 4 |
| `program` `pipeline` `path-mnt` | 4 |
| `devnull` `program` `pipeline` `path-system` | 3 |
| `program` `echo` `passthrough` | 3 |
| `program` `path-mnt` `passthrough` `splitglob` | 3 |
| `program` `pipeline` `echo` `passthrough` `splitglob` | 3 |
| `program` `pipeline` `path-mnt` `passthrough` `splitglob` | 3 |
| `program` `pipeline` `path-system` `path-absent` | 3 |
| `devnull` | 2 |
| `devnull` `program` `pipeline` `path-absent` | 2 |
| `echo` `passthrough` `splitglob` | 2 |
| `program` `echo` `passthrough` `splitglob` | 2 |
| `program` `path-mnt` `path-absent` | 2 |
| `program` `path-system` `path-dev` | 2 |
| `program` `pipeline` `echo` `path-system` | 2 |
| `program` `pipeline` `path-home` `path-absent` | 2 |
| `program` `pipeline` `path-system` `path-absent` `passthrough` `splitglob` | 2 |
| `program` `pipeline` `path-system` `path-mnt` | 2 |
| `program` `pipeline` `path-var` `passthrough` `splitglob` | 2 |
| `devnull` `locale` | 1 |
| `devnull` `program` `passthrough` | 1 |
| `devnull` `program` `passthrough` `splitglob` | 1 |
| `devnull` `program` `path-home` | 1 |
| `devnull` `program` `path-home` `passthrough` `splitglob` | 1 |
| `devnull` `program` `path-mnt` | 1 |
| `devnull` `program` `path-system` | 1 |
| `devnull` `program` `path-var` | 1 |
| `devnull` `program` `pipeline` `passthrough` | 1 |
| `devnull` `program` `pipeline` `passthrough` `splitglob` | 1 |
| `devnull` `program` `pipeline` `path-home` | 1 |
| `devnull` `program` `pipeline` `path-system` `passthrough` `splitglob` | 1 |
| `echo` `passthrough` | 1 |
| `heredoc` `program` | 1 |
| `heredoc` `program` `passthrough` | 1 |
| `heredoc` `program` `pipeline` `passthrough` | 1 |
| `locale` `passthrough` | 1 |
| `locale` `passthrough` `splitglob` | 1 |
| `program` `devfd` | 1 |
| `program` `devfd` `path-absent` | 1 |
| `program` `echo` | 1 |
| `program` `echo` `path-system` `passthrough` `splitglob` | 1 |
| `program` `locale` `passthrough` | 1 |
| `program` `locale` `passthrough` `splitglob` | 1 |
| `program` `path-dev` `passthrough` `splitglob` | 1 |
| `program` `path-dev` `path-mnt` `passthrough` | 1 |
| `program` `path-dev` `path-mnt` `path-absent` | 1 |
| `program` `path-var` `path-dev` | 1 |
| `program` `path-var` `path-mnt` | 1 |
| `program` `pipeline` `devfd` `echo` | 1 |
| `program` `pipeline` `path-dev` `passthrough` `splitglob` | 1 |
| `program` `pipeline` `path-home` `path-dev` | 1 |
| `program` `pipeline` `path-home` `path-mnt` | 1 |
| `program` `pipeline` `path-mnt` `passthrough` | 1 |
| `program` `pipeline` `path-var` `path-absent` | 1 |
| `program` `pipeline` `path-var` `path-home` | 1 |
| all | 36,443 |

How table 3 maps to the rows of [section 1](#my-section-1) (LV1):

- the sets without `passthrough`: held (2) and almost strict (34,301);
- with `passthrough` and not `splitglob`: "with values passed on unchanged, not in preceding rows" (664);
- with `splitglob` (always beside `passthrough`): "with values passed on split, not in preceding rows" (1,476).

2+34,301+664+1,476=36,443, the row "all". The 7+7 samples that Claude's reading puts into the two rows "with values passed on …" (section 1) are not in this table: in the record they keep `U`.

191 samples need assumptions none of which is `program` (98+56+10+10+9+2+2+1+1+1+1=191): `passthrough` 98, `echo` 56, `locale` 10, `pipeline` 10, `passthrough splitglob` 9, `devnull` 2, `echo passthrough splitglob` 2, `devnull locale` 1, `echo passthrough` 1, `locale passthrough` 1, `locale passthrough splitglob` 1. For most of those without `passthrough`, one more run with `POSIXLY_CORRECT=1` or another locale settles them. 28,321 samples need only `program`.

## <a id="my-section-4"></a>4. How the levels are found

**The atomic blocks.** The tool splits every sample into blocks. A block is a simple command (with its settings and redirections), the word list of a `for`, the word and the patterns of a `case`, or the redirections of a compound command; a command inside `$( )` is a block of its own. Each block is marked with its place: where its output goes (a pipe, and whether the next element reads it; `$( )`; a file), where its input comes from, whether its status decides something, whether it runs in the background, in a function's body or in a trap action. The 40,409 samples make 52,518 blocks, 46,093 of them distinct (a block and its place). A sample's level is the lowest of its blocks' levels, after the compositions below.

**Strict forms** (blocks strict by themselves): builtins with words that are literal or come from variables set earlier in the text (`x=1; printf '%s\n' "$x"`); `echo` without backslashes, a leading `-` or expanded words (`x=1; echo "$x"` needs `echo`); `printf` with a literal format and no locale-bound conversion; `test` without file operators and without unquoted expansions; assignments, `export`, `readonly`, `local`, `unset`, `set` (options, operands), `shift` after `set`; functions called after their definition; `alias`; `eval` and `trap` of literal text (parsed and judged in turn); loops and conditions over these; `$( )` of these; descriptor copies among 0–2; small literal here-documents.

**Compositions** (how one part of a sample affects others):
- `$?` takes the status of what ran just before. If that was a program (or a function whose status may be a program's), its status decides (`prog-status` on it). In a loop, `$?` may be the status of any command of the loop (from the round before), so all of them count. At the start of a function's body or a trap action, what ran before is not in the text: `status`. So `x=1; echo $?` is strict; `foo; echo $?` is not.
- `set -e` (or `set -o errexit`), until `set +e`: from there on every command's status decides whether the rest runs, so every program after it counts as `prog-status`; so do the programs in function bodies and trap actions anywhere in a text that sets `-e`. The text's last command is exempt: after it there is nothing left to stop. `set -e` alone, or before builtins only, is strict.
- A name is a call of a function only once the walk has passed the function's definition; before that it may be a program (`if ! mycmd; then mycmd() { …; }; fi`).
- A pipe: if the shell itself reads (into `read`, a loop, a function) what a program writes, `prog-output`; a compound command or a function writing into a pipe is a `race`.
- Variables: a read counts as set only if an assignment comes earlier in the text (one in a function's body counts as early, whether or not the function is called before the read; a read in a function's body counts as late, since it runs when the function is called). This is too lax, [X69](../pspawn-known-issues.md#my-x69) (ours, open): an assignment in a function never called first, or in a subshell, does not set the variable for the read. An unquoted read is strict only if every value assigned to the variable is a literal without pattern characters.

## <a id="my-section-5"></a>5. Results by code

Tables 1–3 above give the counts by code.

**The levels against the run.** If the levels are right, a strict or almost strict sample cannot differ between the shells because of the environment, so where it differs it must differ for some other reason. To test this we took the samples that [`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv) lists with a difference beyond the messages (that file lists the samples where ShellSpawn agrees with neither shell; those where it agrees with one were not taken):

- the samples taken: the 159 of the run of post-0.09: 3 where ShellSpawn differs from both shells, 156 where the shells differ and ShellSpawn agrees with neither (3+156=159; post4-0.04's list had 177, with the same outcome);
- the result: 10 of them are strict or almost strict, and each differs by how the shells are made, the same in any environment: the wording of a "not found" message that `2>&1` sends into the output or a file (8, such as `someCommand 2>&1 | tee someFile`), `kill -l` (1), and `printf -v` (1, Q2): 8+1+1=10;
- not done again: the current record lists 159 too (4 where ShellSpawn alone differs, 152 where it agrees with neither shell, 3 known chance: 4+152+3=159), but this test was not repeated on it.

## <a id="my-section-6"></a>6. How to remake it

From the distribution's directory, with dash 0.5.12 and bash 5.2.21. (The levels need no shells, as they come from parsing alone; the shells' versions matter for which samples are accepted: a sample counts only if `dash -n` and `bash --posix -n` accept it too, [`tools/large-subset-yardsticks.pl`](tools/large-subset-yardsticks.pl).)

```sh
# the sources at the pinned commits: ../test-pools.md, section 1 (about 1 minute); call the directory CORPORA
T=doc/large-subset/tools
perl $T/large-subset-extract.pl CORPORA samples.jsonl
# which samples the parser accepts: the stored scan, reparsed (15 s), instead of rescanning (25 min)
git fetch origin project-2026-11-03
git show FETCH_HEAD:claude/large-subset-scan-0.03/large-scan.jsonl > old-scan.jsonl
git show FETCH_HEAD:claude/large-subset-scan-0.03/sc-cache.jsonl > sc-cache.jsonl
perl -Ilib $T/large-subset-reparse.pl samples.jsonl old-scan.jsonl > large-scan.jsonl
pip install shellcheck-py==0.11.0.1
perl $T/large-subset-drops.pl samples.jsonl drops.tsv
perl $T/large-subset-yardsticks.pl -c sc-cache.jsonl -o samples.tsv samples.jsonl large-scan.jsonl drops.tsv
# the levels (8 s): the tables of sections 1 and 3 on standard output
perl -Ilib $T/large-subset-blocks.pl -e doc/large-subset/large-subset-provenance.tsv -p $T/large-subset-step3.tsv -ai $T/large-subset-ai-classes.tsv -s levels.tsv -o blocks.jsonl samples.jsonl samples.tsv
```

- `make corpus-provenance` does the last step.
- `-p` writes step 3's record ([section 12](#my-section-12)); `-ai` reads the classes Claude gave by reading ([section 12](#my-section-12)).
- `-s` writes one line per sample with its level, codes and text; `-o` every distinct block with its level, codes and all its samples; `-batch` adds the test of [section 8](#my-section-8) (about 2 minutes more).
- The marks of `CALLS` ([section 2](#my-section-2)) come after the behaviour run, from `make corpus-calls`.
- `samples.tsv` must say 40,409 samples accepted (its column `large`; 40,410 before post-0.13).
- With the code as distributed, the result is the file in the distribution (checked 2026-11-18: the columns `ID` and `CODE` came out the same); a change of the parser (the samples accepted, and the trees) or of the tool can change it.

## <a id="my-section-7"></a>7. How it was checked, and what was not

- 84 forms written by hand to probe each rule (`echo "$x"` with and without `x=1` before, `2>errfile`, `x=$(ls)`, `ls | while read`, `f() { echo $1; }; f a` and `f "$x"`, `eval 'echo hi'`, `exec 3>&1; echo x >&3`, `foo; echo $?`, `set -e; foo; echo hi`, a path of each class, …): each came out as the rules say.
- Every strict sample, read one by one. The reading found and fixed: a name called before its function's definition (`if ! mycmd --version; then mycmd() { true; }; fi`), `printf -vTODAY '%(%Y)T'` (the attached `-v` hid the format); and `set -m` was added to the code `fd`.
- 150 random almost strict samples among those with more than a lone command, 60 random undecided ones, and samples of each path class: the codes were right, but `set +e` had been taken for `set -e` (fixed). The path classes take any word starting with `/` (or `=/`) for a path, so a `sed` script `/re/d` or a Windows switch `/v` counts as `path-absent`.
- Against the run: [section 5](#my-section-5). This test also found `sort -R` and `xargs -P`, which break the assumption `program` (now codes `random` and `race`).

What the levels do not show:
- When the levels were first made (2026-11-07), nothing was run in another environment; such runs are in sections 9–12.
- Undecided is conservative on purpose: a loop writing into `sort` counts as a `race`; a call inside a function's body to a function defined later counts as a program.
- `program` is an assumption about programs, and is known to fail for some that are not on the short list of exceptions ([section 3](#my-section-3), table 1).

**A first method, dropped.** The first version of the tool (the same day) did the opposite: it tagged the dependences it recognised and called the rest unaffected (81.4 %). Its passes were not definite: reading found wrong ones, and whole kinds it did not look at (`$?`, `set -e`, `2>errfile`, the text of `eval` and `trap`). So it could not narrow the search for the samples that matter; the levels replace it.

## <a id="my-section-8"></a>8. All the samples in one batch

One by one, the 40,409 samples parse in about 4 s. Joined into one text, a line apart, they make one script, and in a script a command can change how the text after it parses. To find which samples do, and whether the others parse the same when joined, we parsed the joined text.

- 198 samples change how the later text parses (5 of them for two reasons: 90+79+18+15+1=203=198+5):
  - 90 define a function: a command of that name anywhere in the text then calls it (`cd` becomes a function call everywhere);
  - 79 define or remove an alias, which applies to the text after it (`alias rm="rm --interactive"` makes every later `rm` an `rm --interactive`);
  - 18 change aliases in a way known only when they run (P1: the parser stops after such a line and leaves the rest of the text to run time; the first, `unalias run-help && autoload run-help`, stood two fifths into the batch, so the three fifths after it went unparsed until these samples were left out);
  - 15 end in a backslash, which joins the next line;
  - 1 is `exec command -with -flags` (nothing may follow an `exec`).
- The other 40,212, joined (1,497,623 characters, 41,412 lines), are accepted and give the same 40,626 top-level commands as one by one. Each sample's part of the joined tree is its own tree (compared without the line numbers that `$LINENO` anywhere in a text adds to every command), but for 2: `x=$(( $? > 0 ))` and `echo $(( ((1+1)) ))` keep the blank before `))` in the arithmetic text where the large grammar parses them, and lose it where the base grammar does. (The large parser, `Proc::ShellSubset::Large`, is the base grammar of `Proc::ShellSubset` and, where that rejects a text, a wider grammar. These two samples alone are parsed by the base grammar; joined, the text around them needs the wider one.) The value is the same: blanks do not matter in arithmetic.
- The joined parse takes 89 to 105 s; without the one sample that uses `$LINENO`, 8.4 s. (Both are slower than the 4 s of the samples alone because the base grammar rejects the joined text and the wider grammar then parses it all again.) With `$LINENO`, each command's line was then counted from the start of the text, so the time grew with the square of the length: known issue [X30](../pspawn-known-issues.md#my-x30), fixed post-0.13 (the joined parse was not timed again).

## <a id="my-section-9"></a>9. What can be done about a code, and the run's environment varied (made 2026-11-08; last run 2026-11-22)

**The six kinds of workaround** ([`TODO`, A1](../../TODO.md#my-a1); the column "Control" of [section 3](#my-section-3) says which kind fits a code):

| Kind | What it does | Codes it fits | State |
|---|---|---|---|
| 1. Nothing | keep the assumption, or leave the sample undecided | any | — |
| 2. A second run, the other case | run the samples again with a switch of the environment set the other way; a sample whose comparison comes out the same both ways does not depend on that switch | `echo` (`POSIXLY_CORRECT=1`), `locale` (`C.UTF-8`), `pipeline` (SIGPIPE ignored), `devfd` (`/proc` hidden) | done: `-env posix`, `utf8`, `sigpipe`, `noproc`; results below |
| 3. Fixtures | what the shells see outside the run's directory made fresh or fixed for each run; inside it, the files the samples name, and their times | `path-absent` (made in a private mount; not done), `path-tmp` (a fresh tmpfs), `path-random` (a fixed file), `path-var`, `path-home`, `path-mnt` (empty), `path-dev` (a private `/dev`); `time` (fixed file times, for `ls -l`, `stat`); `files`, `directory`, `unquoted` (the run's directory) | done for `path-tmp`, `path-random`, `path-var`, `path-home`, `path-mnt`, `path-dev`: `-env tmp`, `random`, `private`, `dev`; for `time`: `-env mtime`; for the files of the run's directory in part, by the setups of sections 10 and 12 (they make the files the samples name; [section 12](#my-section-12) absolute names too, each run in a root of its own, `-env cowroot`) |
| 4. Chosen values | variables, arguments, input, `HOME`, `PATH`, limits, descriptors set for the run (or several sets, one run each) | `vars`, `args`, `input`, `tilde`, `lookup`, `limits`, `fd`, `name`, `test-ops`, `start`, `interactive` (`HISTFILE`, `INPUTRC`; not started) | in part, by the setups of sections 10 and 12: variables, arguments, input, `HOME` chosen; [section 12](#my-section-12) also the same `$0` for the three (`-env samearg0`) and process IDs (`-env pidns`); not started for `PATH`, limits, descriptors |
| 5. Stand-ins for programs | programs replaced by ones of chosen output and status, the same in every run (the recorders are such stand-ins for status 0 and no output) | `program`, `prog-output`, `prog-status`, `time`, `random` | done for `prog-status` and `prog-output`: `-env fail`, `output`, their answer taken from the environment (below); section 12's setups give the programs' answer as one more dependence (four answers); not started beyond these |
| 6. Leave the samples out | of the comparison's counts | those no run can control: `race`, `pid`, `path-proc`, `path-root`, `listing`, `status` | not started |

### <a id="my-how-the-variants-ran"></a>How the variants ran

A *variant* is one change of the environment of every run of the three shells.

- [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-env V,…` makes the change. The variants that mount do it as root, in a mount namespace of each run's own, before dropping to the run's user. The variants are listed in the script's `%ENVV`; a probe of eight samples checked that each variant takes effect in all three shells.
- [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl) `-b BASE VARIANT` puts each sample's class in a base run beside its class in the variant's run, and lists every sample whose class or result changed.
- Each variant ran on the samples that have its code anywhere in their `CODE` in [`large-subset-provenance.tsv`](large-subset-provenance.tsv) (an assumption, an undecided code, after the `/`, or inside `passthrough(…)`; [`tools/large-subset-ids.pl`](tools/large-subset-ids.pl)), so on more samples than section 3 counts for the code at one level. The variants of kinds 2 and 3 but `mtime` were compared with one base run of the 7,003 samples that have any of their codes; `fail`, `output` and `mtime` with a base run of their own (below).
- A second base run measured the *noise*: what changes between two runs in the same environment (times, chance, process IDs).

From the distribution's directory, as root, after `make`, with `samples.jsonl` and `samples.tsv` of [section 6](#my-section-6) (IDS-v: the IDs of the variant's code, one per line):

```sh
T=doc/large-subset/tools
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -only @IDS-all samples.jsonl samples.tsv base
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -workers-from base -only @IDS-all samples.jsonl samples.tsv base2
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -env tmp -workers-from base -only @IDS-path-tmp samples.jsonl samples.tsv v-tmp
perl $T/large-subset-runreport.pl -b base v-tmp
```

`-workers-from base` runs each sample with the *worker* of its base run (a worker: one of the runner's parallel processes, with its own directory `/runcompare/wK` and user `rcK`; X66; `make corpus-env-variants` does so). A base run takes about 6 minutes with 4 workers, all variants together 8 minutes.

**The stand-ins' answers and the fixture's time** come from the runner's own environment, with defaults:

- `STANDIN_STATUS` (`-env fail`; default 1): every program the run only logs (not one of the plain text tools that really run) exits with it;
- `STANDIN_OUTPUT` (`-env output`; default `one  two`, `*`, an empty line and `last` without a newline): it tests splitting, patterns, empty lines and a last line without its newline;
- `FIXTURE_MTIME` (`-env mtime`; seconds since 1970, default 1577836800, 2020-01-01): the access and modification times of every file and directory of the run's copy.

So `STANDIN_STATUS=2 perl …/large-subset-runcompare.pl -env fail …` tries status 2; the values used go to `env.txt` in the run's output directory (the last argument). These three variants ran against base runs of their own (the 1,248 samples with `prog-status`, `prog-output` or `time`, run twice). Every changed sample is in [`tools/large-subset-env-variants.tsv`](tools/large-subset-env-variants.tsv), with a column saying whether it changed between the two base runs too.

### <a id="my-variant-results"></a>Results

"Samples": those with the variant's code anywhere in their `CODE` (above). "Class changed": the sample's class in the variant's run is not the one in the base run. "Other result": the class stayed, but a status, output, call, file or message changed in some shell. "+*n* noisy": *n* more, whose result (any part, messages included, in any shell) also changed between the two base runs, so that the change need not be the variant's; a sample counts in every variant it ran in, so these add up to more than the table "Noise" below.

| Variant | Code | Samples | Class changed | Other result | What changed, in short |
|---|---|---|---|---|---|
| `posix` | `echo` | 443 | 36 | 2 (+3 noisy) | ShellSpawn's `echo` follows `POSIXLY_CORRECT`, the shells' builtins do not |
| `utf8` | `locale` | 25 | 1 | 2 | one `printf` of `\u20AC` |
| `sigpipe` | `pipeline` | 5,742 | 22 (+10 noisy) | 112 (+78 noisy) | endless writers time out; messages of `echo` into a closed pipe |
| `noproc` | `devfd` | 13 | 3 | 1 | `/dev/stdin` and the like missing: fail in all three, with different statuses |
| `tmp` | `path-tmp` | 207 | 7 | 2 (+4 noisy) | all 7 now the same in the three |
| `random` | `path-random` | 25 | 17 (all of them also noisy) | 0 | all 25 now the same in the three |
| `private` | `path-home`, `path-mnt`, `path-var` | 573 | 0 | 4 (+3 noisy) | nothing from the variant |
| `dev` | `path-dev` | 444 | 0 | 0 | nothing |
| `fail` | `prog-status` | 113 | 2 | 23 | nothing beyond the messages, but one loop that never ends |
| `output` | `prog-output` | 1,014 | 62 (+1 noisy) | 374 (+19 noisy) | differences between dash and bash in `cd`, `kill`, `unset`, `[` given the stand-in's words |
| `mtime` | `time` | 223 | 0 (+2 noisy) | 9 (+42 noisy) | what still changes: the shells' own clocks, times outside the run's copy |

### <a id="my-variant-details"></a>What changed, variant by variant

- `posix` (36 class changes):
  - 34 from "ShellSpawn as bash" to "ShellSpawn as dash": with `POSIXLY_CORRECT` set, ShellSpawn's `echo` (coreutils' meaning, inside Perl since IP1) interprets backslashes and takes no options, as dash's builtin does; bash's builtin does neither. 5 of the 34 are `echo -e …` into a program only logged, whose input is compared since IN1 (`| tsort`, `| nc`, `| sudo tee -a …` twice, `| grep -v … | tail -1`).
  - 2 from "same" to "ShellSpawn differs": `echo '\x4a'`, `echo '\xat'`: ShellSpawn then interprets `\x`, neither shell does.
- `utf8` (1): `printf "\u20AC %.2f\n" 123.4`: in `C` all three print `\u20AC` as it is; in `C.UTF-8` bash and ShellSpawn print `€`, while dash's `printf` has no `\u` (from "same" to "ShellSpawn as bash").
- `sigpipe` (32 class changes, 22+10 noisy; 15+15+2=32):
  - 15 changed beyond the messages:
    - 10 timeouts: an endless writer (`yes | nl | sed 100q`, `cat /dev/urandom | … | head -1`) no longer dies when its reader stops;
    - 1 timeout gone: `yes | sed -n '200000000,${=;p};200000005q'` ends near the 5-second limit, and in the base run dash ran out of time (timing);
    - 1, `(echo "#1"; sleep 1; …) | zenity`: in the base run the shells' `echo`, and since D3 ShellSpawn's, ends the subshell when it meets the closed pipe; with SIGPIPE ignored, the subshell runs on in all three (its later `sleep 1` called), and ShellSpawn's `echo` says `write error` (from "messages as dash" to "messages as neither"; noisy, since bash raced in a base run);
    - 3 by chance, all noisy: the times of `ls -ltr`, the inode numbers of `ls -gilds`, the race `{ echo foo; cat bar; } | tee bar`.
  - The rest are messages:
    - 15 to "messages as neither" (`msg-own`; the 16th, `zenity`, is among the 15 above): ShellSpawn's `echo` writing into a pipe whose reader is gone says `echo: write error: Broken pipe` (as coreutils), dash's builtin `I/O error` or nothing. Since IN1 a program only logged reads its input to the end, so this is left only where the reader is not found (`echo … | md5`, the tldr alternatives `a|b|c`) or ends early (`| false`, `| head`);
    - 2 other changes of messages, both noisy races (`sed … index.html | tee index.html`, `echo … | cat - fifo | tee fifo`).
  - Which snippets meet a closed pipe varies from run to run: 23 of the 32 changed class in the runs of 2026-11-17 too (where 44 did, as reported after X82).
  - Other runs: on 2026-11-17, 44 class changes (34+10 noisy) as reported after X82 (53, 38+15, before): 16 beyond the messages (10 timeouts; `zenity`, from "ShellSpawn differs" to "messages as neither", before D3; 5 by chance), 23 to "messages as neither", 5 other changes of messages. In the first run of 2026-11-17, 18 changed beyond the messages, among them also 2 by another sample's `/tmp/size.log` (the variants run without `-env tmp`), two `head` reading one pipe, the times of `ls -1rc`, and the race the recorder made with IN1 alone, `md5sum * | sed '…/e'`, gone with A24 (b) (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)). The messages "as neither" were 30 in the first run of 2026-11-17, 55 in the run of 2026-11-16, 42 in that of 2026-11-15.
- `noproc`: `paste /dev/stdin`, `mv … < /dev/stdin` and `tee /dev/stderr` fail in all three; the redirection's status is ShellSpawn's as dash's (rule A5). `paste` moved from "ShellSpawn as bash" to "same", `mv` from "same" to "ShellSpawn as dash", `tee` from "same" to "messages only" (in the base run of 2026-11-14 its messages already differed, by timing, and in the runs of 2026-11-17 they differed between the two base runs: noisy; not so on 2026-11-22). bash does not emulate `/dev/stdin` then (table 1).
- `tmp`: all 7 to "same", from "ShellSpawn as bash" (5) or "as dash" (2): `mkdir /tmp/foo` and redirections into `/tmp`, where the second and third shell found the first one's file, or another sample's.
- `random`: all 25 now agree. 14+1+2=17 changed class:
  - 14 from "ShellSpawn as neither" to "same" (one of them, `head -200 /dev/urandom | cksum …`, because its input, compared since IN1, differed between the shells in the base runs);
  - 1 from "ShellSpawn as dash" to "same" (`grep -m1 -ao '[0-9]' /dev/urandom`; it was "ShellSpawn differs" in the base run of 2026-11-13 and "ShellSpawn as neither" in that of 2026-11-16: in a base run each shell reads other bytes, so which class it gets there is chance);
  - 2 from "timeout" to "same": the same bytes in every run, and `cat /dev/urandom` ends.
- `private`: none from the variant: messages of pipelines that mix by timing, and the times of `ls -lrt`. No sample changed its class on 2026-11-22. On 2026-11-17 one did, noisy: `find /home/jassi/ … | xargs ls -lrt | awk …`, as one did in the runs of 2026-11-13, 2026-11-15 and 2026-11-16 (in the first run of 2026-11-17 also its twin with `2>&1`). In the run of 2026-11-15 also 2 by another sample's `/tmp/size.log` (`NB:3439`, `NB:3440`, under "Found" below: the variants run without `-env tmp`); since then, those two changed under `sigpipe`.
- `dev`: none (in the run of 2026-11-16, `steamos-chroot -d /dev/sdX -p A|B`, a pipeline of programs not found, changed its messages by timing, noisy).
- `fail`: with every logged program failing, the three shells still agree, beyond the messages:
  - 1 from "messages as dash's" to "same": `gcc -p program.c && ./a.out`, whose command with the differing message is no longer reached (in the run of 2026-11-15 also `set -e shellcheck …`, whose `shellcheck` since A23 is not found in either run);
  - 1 to "timeout": `until systemctl is-active -q nginx; do …; done` never ends, in all three shells alike.
- `output`: 47 changed beyond the messages, that is into a class where the shells differ (22+13+6+2+2+1+1=47):
  - 22 `cd $(…)` given several words: dash goes to the first, bash fails ("too many arguments", status 1), and ShellSpawn as bash since X54 ([`TODO` A13](../../TODO.md#my-a13): not legalized);
  - 13 `kill $(…)` given words that are no process IDs: dash status 2, bash and the program 1 (as in the atomic calls, section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7));
  - 6 `cd "$(…)"` and the like to a name that does not exist: dash 2, bash 1, ShellSpawn as dash (A5);
  - 2 `unset $(…)` given words that are not names: dash fails ("bad variable name", status 2), bash takes them for function names (status 0), ShellSpawn as dash (X35, fixed);
  - 2 `==` in `[` and `test` in a loop (`[ $? == 0 ]`, `test $(…) == …`): ShellSpawn's `test` takes `==`, as bash;
  - 1 `g=$(md5sum $f) > $f.md5` in a loop: dash makes the file before running the substitution, bash after (ShellSpawn as dash);
  - 1 race, `echo $(date) "0" | tee -a log.csv`: the stand-in's answer holds `*`, which lists `log.csv` or not as `tee` has made it or not (not noisy: the two base runs agreed).
  - The other 15 of the 62 (47+15=62) changed in the messages. One of them, `` [ `md5sum …` == `md5sum …` ] ``, went from "ShellSpawn as bash" to "messages only": its `out` and calls changed too, but into agreement. (On 2026-11-17 this section counted it also among the `==` above, as 3 `==`, and the others as 14: 47+14=61 then held only by that double count; it was 46+15.)
  - Noisy, 1: a sample where two `head` read one pipe (a race).
  - Other runs: on 2026-11-17 also noisy `ls -ldt $(find .)`, given `*`, which lists the run's files made in the same second in the order of their nanoseconds (from "same" to "ShellSpawn differs": chance, file times). In the first run of 2026-11-17 also 2 races (alike in all three in the second run): `echo $(date) "0" | tee -a log.csv` and its twin, where the stand-in's answer holds `*`, which lists `log.csv` or not as `tee` has made it or not; and the race the recorder made with IN1 alone, `zcat … | { zcat … | comm -12 /dev/fd/3 - ; } 3<&0`, gone with A24 (b) ([section 11](#my-section-11)). In runs before 2026-11-17 also the clock was noisy (`` touch filename_`/bin/date +%Y%m%d%H%M%S`.txt ``, when the second changes between dash's run and the others').
- `mtime`: the point is repeatability. Between two base runs 47 of these samples changed some result in the run of 2026-11-14 (2026-11-13: 33; not counted again in the runs of 2026-11-17 and 2026-11-22, where at least 50 and 44 did: the noisy ones of the table, 1+49=50 and 2+42=44). What still changes: the shells' own clocks (`time`, `times`, `printf '%(…)T'`), and the times of what is not the run's copy (`ls -ld /tmp`, `ls -lR /`, `/proc`).

### <a id="my-variant-noise"></a>Noise

What changed between the two base runs, in samples:

| Runs | base against base2 (7,003 samples): some result / the class | the stand-ins' base runs (1,248 samples): some result / the class |
|---|---|---|
| 2026-11-22 (the table above) | 99 / 11 ¹ | 56 / 2 |
| 2026-11-17 | 109 / 22 | 60 / 1 |
| 2026-11-17, the first run | 109 / 20 | 57 / 0 |
| 2026-11-16 | 108 / 25 | 57 / 3 |
| 2026-11-15 | 108 / 24 | 56 / 1 |
| 2026-11-14 | 105 / 19 | 56 / 2 |
| 2026-11-13 | 212 / 17 | 42 / 1 |
| post-0.09 | 122 / 40 | |

¹ Counted with the tools after X82; the other rows were counted before it, when messages that ran together on one line in dash or bash were misread (the tools before X82 give 112 / 24 for 2026-11-22).

The noise was not traced sample by sample.

### <a id="my-variant-runs"></a>Which runs the table counts

The runs of 2026-11-22 (`make corpus-env-variants`, part of `make corpus-all` from an empty work directory), with the code of that day (post-0.13, as in section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7): K5, the runner's fixed list of programs, A23, a program only logged reading its input, IN1, unless it never reads it, A24 (b), and the changes of post-0.13, D3 among them). Both base runs and every variant ran in full, each sample with the worker of its base run (X66, below).

The runs of 2026-11-17 ran twice that day:

1. first with IN1 alone;
2. then the first base runs were kept, except for the 4,060 samples that name a program A24 (b) concerns (one that never reads its input), which ran again; the second base runs and every variant ran again in full, each sample with the worker of its base run (known issue [X66](../pspawn-known-issues.md#my-x66): before, a variant mostly ran a sample with another worker, so a result holding the worker's directory `/runcompare/wK` or user `rcK`, such as `pwd`, `$HOME`, `~`, `$USER` or `$0`'s directory, changed for no reason of the variant).

What changed between the runs, as traced:
- 2026-11-22 against the second run of 2026-11-17 (both reported with the tools after X82): `zenity`'s base class (D3, above); the rest by timing, races and the clock (the samples marked noisy, and under `sigpipe` which snippets meet a closed pipe);
- the second run of 2026-11-17 against the first: "other result" fell, mostly by X66 (`posix` 13 to 2, `sigpipe` 192 to 113, `output` 396 to 375, `tmp` 6 to 3, `private` 6 to 4); the races the recorder made are gone (A24 (b)); the rest by timing, races and the clock (the samples marked noisy);
- the first run of 2026-11-17 against 2026-11-16: IN1, whose input is compared (5 samples more under `posix`, 1 under `random`; checked by reporting the same runs with the input's size and SHA-256 taken out of the logs) and read (under `sigpipe` far fewer writers meet a closed pipe; two races the recorder makes, under `sigpipe` and `output`); and timing, races and the clock (the samples marked noisy);
- 2026-11-16 against 2026-11-15: A23 (programs not on the list are not found: more messages under `sigpipe`, one sample less under `fail`); timing, races and the clock (the samples marked noisy); and the counts of noise.

**Found.**
- `/tmp` is shared not only by the three shells of one sample but by all samples and workers of a run: `NB:3439` (`… >> /tmp/size.log`) made the file as one worker's user, and `NB:3440`, run later by another, failed in all three shells with "Permission denied". The run of section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7) had this too, before it took `-env tmp` (post-0.09), which removes it.
- With `POSIXLY_CORRECT=1` in the environment, ShellSpawn's `echo` (the program's behaviour, by the rule "the program beats the shells' difference") changes its meaning: it sides with dash for backslashes and `-e`, and differs from both shells for `\x`. Decided (the user, 2026-11-09, EC1): accepted, and a switch added: `PROC_SHELLSPAWN_ECHO=dash` or `bash` makes ShellSpawn's `echo` that shell's builtin, which `POSIXLY_CORRECT` does not change (default `coreutils`, as before); [`t/dash.t`](../../t/dash.t), which compares ShellSpawn with dash, sets `PROC_SHELLSPAWN_ECHO=dash` (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7), table of [section 1](large-subset-state.md#my-section-1)).
- Known issue X33 ([`pspawn-known-issues.md`](../pspawn-known-issues.md); ours, fixed): the runner made `/dev/stdout` and `/dev/stderr` unwritable for the run's user.
- `private` and `dev` changed nothing: in the container of these runs those places are absent, empty or closed to the run's user, as the assumptions say. Checked in this container only.
- In the runs of 2026-11-13 (`make corpus-env-variants`, with the code of post-0.11 and the runner waiting for background jobs), [`tools/large-subset-ids.pl`](tools/large-subset-ids.pl) chose the samples of a variant by their codes, but did not read the codes inside `passthrough(…)` that step 3 gave the pass and split samples, so `fail` ran first on 35 of its 113 samples and `output` on 511 of its 1,014 (509 undecided, and 2 whose `passthrough(…)` named `prog-output` in the middle of its list) (their base runs on 670 of 1,248); fixed, and the missing ones ran too.

**Not done.**
- The variants ran one at a time, each only on its own code's samples, in one container. They were not combined, but for `-env tmp,random,mtime`, used for the run of the whole library (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)) and in steps 2 and 3 (sections 10 and 12).
- Their stand-ins tried one answer each (status 1; one output text), the same for every program the run only logs (step 3's setups tried four, [section 12](#my-section-12)).  A program not on the runner's list had no stand-in and was "not found" in every run: 58 samples of `fail` and 59 of `output` were so not varied at all ([X84](../pspawn-known-issues.md#my-x84); fixed in the runner post-0.13, these runs not made again).
- These runs do not change the levels of sections 1–3, which come from the texts alone; the runs are footnotes to the totals of [section 1](#my-section-1) (the user, 2026-11-08, EV1).
- Of the six kinds of workaround (the table above): kind 2 is done; kinds 3 and 4 in part (the variants above, and the setups of sections 10 and 12); kind 5 beyond the stand-ins above and section 12's answers, and kind 6, are not started.

## <a id="my-section-10"></a>10. Step 2: exact dependences and example setups (made 2026-11-10; last run 2026-11-22)

Step 2 of the user's four steps ([words used](#my-words-used-below); [`TODO`, A1](../../TODO.md#my-a1)): for the samples the environment may affect, describe exactly how, and run them in a few example environments. [Section 9](#my-section-9) did step 2 for the codes that one switch of the whole environment covers. This section does it for the codes inside the run: `files`, `vars`, `input`, `args`, `directory`, `tilde`, and, where they come with a variable or argument of the same command, `name`, `test-ops`, `eval` and `unquoted`.

**Exactly what.** [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) `-d DEPS.jsonl` records, for every undecided sample, what each undecided code comes from and in which block (command):

- `files`: the glob pattern, or the file a redirection reads (`<`, `<>`) or writes (`>`, `>>`, `>|`), a `test` operator's operand, the file `.` reads, a relative program name (`./run.sh`);
- `vars`: the variable read before the text sets it;
- `input`: a `read` from the run's input;
- `args`: the positional parameter (`$1`, `$@`, `$#`, …);
- `directory`: the operand of `cd` (none: `HOME`);
- `tilde`: the word (`~` alone depends on `HOME` only, `~user` on the user database).

Each with a flag saying whether the name is literal (no expansion in it), and, for each block, the undecided codes that none of these names explains. The levels and [`large-subset-provenance.tsv`](large-subset-provenance.tsv) do not change (regenerated: identical).

**The setups.** [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl) gives each sample whose undecided codes are all among these some example setups. Each dependence has three states besides the base run's; dependences on the same thing (one file, one variable, `HOME`, the arguments, the input) move together:

| Dependence | Base run | State 1 | State 2 | State 3 |
|---|---|---|---|---|
| a file read (`<`, `<>`, `test -e` and the like) | absent (or the fixture's file, if the fixture has one of that name) | a file of two lines (absent, if the fixture has it: state 1 is then the other case) | an empty file | a directory |
| a file `.` reads | absent | a file `echo sourced` | an empty file | a directory |
| a file written (`>`, `>>`, `>\|`) | absent | a file of two lines | a directory | a read-only file |
| a program `./name` | absent | an executable script that prints its arguments | the same, not executable | a directory |
| a glob pattern | the fixture's matches | none (the fixture's matches removed) | one new matching file | two new matching files |
| a variable | unset | empty | `x1` | `two  words *` |
| standard input | `/dev/null` | two lines | a line without its newline | `a b\ c` |
| positional parameters | none | one, empty | `x1` | `two  words`, `*`, `last` |
| `cd NAME` | absent | a directory | a file | a directory with mode 000 |
| `HOME` (`~`, `cd` alone) | the run's home directory | `/nonexistent/home` | empty | unset |

Setups 1, 2 and 3 put every dependence in state 1, 2 and 3. Beyond these:

- a sample with two dependences gets every combination, 3 × 3 = 9 setups (`-full 2`);
- a sample with more gets, after setups 1–3, each dependence alone in each state, the others as in the base run: 3 + 3m setups for m dependences (`-one`).

The user's rule (2026-11-10): "3^m tries" as far as they add at most 25 % to the runs of three setups a sample, and "3+3*m where 3^m is too large". Every combination for all samples would add 269 %, for up to three dependences 28 %, for up to two 18 %. So 2,593 samples got 3 setups, 267 got 9, 34 got 12, 4 got 15, and three got 18, 21 and 30: 2,593×3+267×9+34×12+4×15+18+21+30=10,719 setups in all, 2,016 (23 %) more than three a sample (the runs of 2026-11-22, `make corpus-step2`; in those of 2026-11-13 and 2026-11-17, 2,594 got 3, 10,722 in all, with `NB:10012`, below; before them 2,593 and 10,719).

**Which samples were taken.** Of the 3,262 samples whose undecided codes are all among these, 361 were left out (104+101+88+25+16+5+2+19+1=361):

- 104 whose pattern is absolute (outside the run's directory);
- 101 that read a variable the run sets itself (`HOME`, `PATH`, `USER`, `PWD`, …; 100 before the runs of 2026-11-22: since X80 the parse tree keeps every operand of `cd`, so `NB:10012`, `cd bar1 find . … -exec echo ln -s $PWD/{} ../bar2`, reads `PWD`);
- 88 that name a file or directory by an expansion (section 12 gives them setups: "Names with an expansion");
- 25 `cd` to an absolute path, `.` or `..`;
- 16 patterns for which the tool could make no example file name;
- 5 `~user`;
- 2 `cd -`;
- 19 that read, write or source a file named with `..` or an absolute path;
- 1 naming the run's directory.

The other 2,901 were taken (2,797 where one block has the undecided codes, 104 where several do). (These are samples undecided before step 3; step 3 made 1,220 of them almost strict, the classes pass and split of [section 12](#my-section-12), and its classes control and affects-shell, with the setups of section 12, are the **partially decided** of [section 1](#my-section-1).) Before the runs of 2026-11-13 the counts were 3,245, 344 left out (3 of them with `..` or an absolute name), 2,901 taken: the dependences `-d` writes changed with step 3 ([section 12](#my-section-12), "Not checked").

**How they ran.** [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-setup PREFIX-K.jsonl` applies setup K before each run of the three shells: files made or removed, variables set or unset, standard input, arguments after the text, with `$0` as each shell has it without them, so that the messages keep their prefix ([`t/try.pl`](../../t/try.pl) takes `$0` and arguments after the text, as `sh -c`). All runs used `-env tmp,random,mtime`. The counts below are of the runs of 2026-11-22; earlier rounds, which found the bugs X39 to X47 (all fixed; "Found", below), are not counted.

### <a id="my-step-2-results"></a>Results

Each sample is one of (the class as in section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)):
- *unchanged*: the same class in every setup as in the base run;
- *changed*: another class in some setup, ShellSpawn still agreeing with dash, bash or both;
- *neither*: in some setup a class where ShellSpawn agrees with neither shell, or a timeout, where the base run had another class (a sample `neither` in the base run and in every setup is *unchanged*).

This record compares the messages on standard output and in files (`-raw`), unlike the match of [section 11](#my-section-11).

The record per sample, written by [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) `-record`: [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv).

(The counts by dependence are of these 2,901; table 2 of section 3 counts the samples the record marks U now.)

| Dependence | Samples | Unchanged | Changed | Neither |
|---|---|---|---|---|
| files | 1,814 | 717 | 1,095 | 2 |
| a variable | 640 | 597 | 42 | 1 |
| `~` (`HOME`) | 194 | 36 | 158 | 0 |
| positional parameters | 126 | 111 | 14 | 1 |
| two kinds or more | 80 | 53 | 27 | 0 |
| standard input | 36 | 35 | 1 | 0 |
| `cd` | 11 | 1 | 10 | 0 |
| all (of them several blocks) | 2,901 (104) | 1,550 (77) | 1,347 (27) | 4 (0) |

**Which runs the table counts.** The runs of 2026-11-22 (`make corpus-step2`, part of `make corpus-all` from an empty work directory):
- the code of that day (post-0.13, section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), ShellSpawn at exit as the shells (K5);
- the runner waiting for background jobs (A18), and offering only the programs of its fixed list (A23);
- a program only logged reading its input (IN1), unless the program never reads it (A24 (b)).

**Other runs.**
- The second run of 2026-11-17: unchanged 1,550 (75), changed 1,348 (29), neither 4 (0), of 2,902 (104). Against it, sample by sample: `NB:10012` is no longer taken (above); `"$EDITOR" "$file"` (twice) went from *changed* to *unchanged*, since the message for an empty command name is worded as dash's (X72, D2); `grep -n "" myfile.txt | sort -r -n | gawk …` from *unchanged* to *changed*, by one setup where ShellSpawn's message and `grep`'s ran together on one line (timing).
- The first run of 2026-11-17 (IN1 alone): unchanged 1,549 (75), changed 1,349 (29), neither 4 (0). Between the two runs one sample changed its outcome: the race the recorder made, `md5sum * | sed '…/e'` (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), gone with A24 (b), from *changed* back to *unchanged*.
- 2026-11-11 to 2026-11-16: their totals are in [`Changes`](../../Changes). Between two of them, a few samples (6 to 8) changed their outcome or a setup's class each time: by messages that mix by timing, the races NB:4904 and NB:6406 (below), the recorder's race above, and `regedit -?` (Wine's program, installed in the container, not found since A23). None changed by the input compared since IN1 (checked: the same runs reported with the input's size and SHA-256 taken out of the logs give the same record).

**What the outcomes hold.**
- *Changed* is nearly all known differences coming and going with the setup:
  - a redirection that fails (into a directory that does not exist, as `>path/to/output.png`, into a directory, into a read-only file) fails with status 2 in dash and ShellSpawn (rule A5) and 1 in bash, so such a sample is `=dash` while the redirection fails and `same` or `msg=dash` when it succeeds;
  - `~` with `HOME` changed ([section 11](#my-section-11): G16, and a dash bug).
- *Neither*, the 4 (1+2+1=4):
  - `rev $filename | …` given `two  words *`: all three time out;
  - `ls > foo 2> bar > baz` and `test 2>&1 > cow` with `baz`, `cow` a directory: A5, with the messages in a file or on standard output, each with its shell's prefix;
  - `printf '%q' "$1"`: the program's behaviour (ShellSpawn's `printf` is coreutils'), legalized by builtin-vs-coreutils.
- Other runs, *neither*: in the runs of 2026-11-16 also two by chance, alike in every setup in the runs of 2026-11-17 and 2026-11-22:
  - `cat ${SPOOL_FILE} | tee -a ${LOG_FILE}` given `two  words *` for both (NB:6406; also in the runs of 2026-11-14; in those of 2026-11-15 all three alike): `cat` reads the files `tee` appends to, a race. In the run of 2026-11-14 ShellSpawn's `cat` read about 4 KB of what `tee` wrote, the shells' none; by hand, in one directory: dash read some in 6 runs of 20, bash in 1 of 20, ShellSpawn in none of 40;
  - `find … | xargs ls -lhrt | awk '{print $9}' > log.txt` given a `log.txt` of two lines (NB:4904): ShellSpawn's `log.txt` differs, by the order in which `ls -t` lists files; the sample changes so between two base runs too ([section 9](#my-section-9), `sigpipe`, noisy).

**Found.**
- Bugs of ours, none visible in the base run, each needing a file or a value the base run does not have ([`pspawn-known-issues.md`](../pspawn-known-issues.md)), all fixed (post-0.11):
  - X39: `.` of an empty file or a directory: Perl died;
  - X40: `[[:digit:]]` never matched in pathname expansion;
  - X41: `"${v#$x}"`: `$x`'s value taken literally (in the parser; the parse results, section 3 of [`large-subset-state.md`](large-subset-state.md#my-section-3), measured again: unchanged);
  - X42: `exit`, `return` with `x1`; X43: `set -o` with no such option (decision NV1: as the shells);
  - X44: `cd` into a directory that may not be searched succeeded;
  - X45: `cd` with `HOME` empty failed;
  - by the match report of [section 11](#my-section-11): X46 (`shift` with such an operand) and X47 (the message of a command that does not start went to the shell's own standard error, not to the one the command was given: `nosuch 2>log` left `log` empty).
- A **❰BUG❱ of dash**: with `HOME` empty, `~` is dropped ([section 11](#my-section-11)).
- In [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl): a pattern ending in `/` needs directories; with arguments, `$0` must stay each shell's own (both fixed before the runs counted here).

**Not done.**
- Step 2 for the codes left: `start`, `lookup`, `limits`, `fd`, `interactive` (section 12 gives the three shells the same `$0` for its class affects-shell, `-env samearg0`; the others get no setups there either); `unquoted`, `name`, `test-ops`, `eval` where no variable or argument of the same command brings them; `listing` and `status` (no run can control them, kind 6 of [section 9](#my-section-9)).
- Absolute patterns and the run's own variables ([section 12](#my-section-12) makes absolute names too, under `-env cowroot`, for its two classes, and Claude read the 93 its setups left out).
- Every combination for three dependences or more.

Steps 3 and 4 are done: [section 12](#my-section-12).

```sh
X=doc/large-subset/tools
perl -Ilib $X/large-subset-blocks.pl -d deps.jsonl samples.jsonl samples.tsv > /dev/null       # 10 s
perl -Ilib $X/large-subset-setups.pl -all -full 2 -one deps.jsonl setup   # setup-1.jsonl ... setup-30.jsonl, setup-samples.tsv
cut -f1 setup-samples.tsv | grep -v '^#' > setup.ids
for r in base base2; do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -only @setup.ids samples.jsonl samples.tsv $r; done
for k in $(seq 1 30); do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -setup setup-$k.jsonl samples.jsonl samples.tsv s$k; done
```

About 35 minutes with 4 workers; the record and the match: [section 11](#my-section-11). (Each `setup-K.jsonl` holds only the samples that have a setup K. No `-workers-from` here: the outcomes compare classes, and a class compares the three shells within one run, which share a worker.)

## <a id="my-section-11"></a>11. The match across environments (made 2026-11-11; last run 2026-11-22)

Every sample (a snippet: a script, or a part of one, stored in our library) was run by dash, `bash --posix` and ShellSpawn: in one environment, the base run, or in several: the samples of step 2 in its setups ([section 10](#my-section-10)), and those of step 3's two classes in theirs ([section 12](#my-section-12): each class with its own base run and setups). A snippet counts once, over every environment it ran in: its box in the trees comes from its classes in all of them together, the base run, step 2's setups and step 3's alike (the user, 2026-11-13, adding step 3's environments to the base run and step 2's setups, which were counted so before).

- Tree 1 sorts the snippets by whether dash and bash agree, and which of them ShellSpawn agrees with.
- Tree 2 splits each box of tree 1 by whether a ruling of the user legalizes ShellSpawn's difference.
- A *command* is one call of `echo`, `printf`, `test`, `[`, `kill` or `pwd` inside a snippet ("Snippets and commands", below).
- Messages are not compared in the match: not on standard error, standard output or in files ("How it was measured", at the end of this section; step 2's record, [section 10](#my-section-10), does compare them, `-raw`).

The three columns on the right split each box by the commands its snippets run:
- **≠coreutil**: in every environment where ShellSpawn ≠ a shell, the snippet runs one of the six commands with arguments for which coreutils ≠ that shell's builtin (and ShellSpawn = coreutils);
- **¬coreutil**: the snippet runs none of the six commands;
- **rest**: it runs some, but not so.

**Tree 1: the match.**

```
40,409  all snippets the parser accepts; each run by dash, bash and ShellSpawn
│
│                                                                 ≠coreutil  ¬coreutil  rest
├── 38,594  ShellSpawn = dash = bash, in every environment¹
├──     13  timeout                                                       0         11     2
├──      4  dash = bash; ShellSpawn ≠ them                                2          2     0
└──  1,798  dash ≠ bash, in some or all environments
     ├── 1,268  ShellSpawn = dash                                        14      1,204    50
     ├──   355  ShellSpawn = bash                                       117        234     4
     ├──   128  ShellSpawn ≠ dash, ShellSpawn ≠ bash                      8        103    17
     └──    47  depends on the environment                                1         42     4
                ├── 39  ShellSpawn = dash in some, = bash in others       0         36     3
                ├── 2  ShellSpawn = dash in some, ≠ both in others        0          1     1
                ├── 3  ShellSpawn = bash in some, ≠ both in others        1          2     0
                └── 3  ShellSpawn = dash, = bash, ≠ both, by environment  0          3     0
                                                                  ─────────  ─────────  ────
                                                                        142      1,596    77
```

¹ Their commands were not recorded: nothing in them needs a reason.

**Tree 2: the same, each box split by legalization.** A snippet with several reasons in different environments counts in the last of these that applies to it in some environment: legalized, awaiting a decision, chance, not legalized (so a snippet not legalized in one environment counts as not legalized; [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl)). "Awaiting A12": `~` with `HOME` empty, where dash drops the word; the user's decision A12 is pending ([`TODO`](../../TODO.md)).

```
40,409  all snippets the parser accepts; each run by dash, bash and ShellSpawn
│
│                                                                 ≠coreutil  ¬coreutil  rest
├── 38,594  ShellSpawn = dash = bash, in every environment¹
├──     13  timeout                                                       0         11     2
├──      4  dash = bash; ShellSpawn ≠ them                                2          2     0
│           ├── 3  legalized by rulings²                                  2          1     0
│           └── 1  chance                                                 0          1     0
└──  1,798  dash ≠ bash, in some or all environments
     ├── 1,268  ShellSpawn = dash                                        14      1,204    50
     │          ├── 1,248  legalized by rulings³                         14      1,186    48
     │          ├──    19  ~ with HOME empty: awaiting A12                0         17     2
     │          └──     1  chance                                         0          1     0
     ├──   355  ShellSpawn = bash                                       117        234     4
     │          ├── 283  legalized by rulings⁴                          117        166     0
     │          ├──  64  ~ with HOME empty: awaiting A12                  0         64     0
     │          └──   8  not legalized                                    0          4     4
     ├──   128  ShellSpawn ≠ dash, ShellSpawn ≠ bash                      8        103    17
     │          ├── 88  legalized by rulings⁵                             8         66    14
     │          ├──  1  ~ with HOME empty: awaiting A12                   0          1     0
     │          └── 39  chance                                            0         36     3
     └──    47  depends on the environment                                1         42     4
                ├── 39  ShellSpawn = dash in some, = bash in others       0         36     3
                │      ├──  5  legalized by rulings⁶                      0          3     2
                │      ├──  2  ~ with HOME empty: awaiting A12            0          2     0
                │      ├──  2  chance                                     0          1     1
                │      └── 30  not legalized                              0         30     0
                ├── 2  ShellSpawn = dash in some, ≠ both in others        0          1     1
                │         ~ with HOME empty: awaiting A12
                ├── 3  ShellSpawn = bash in some, ≠ both in others        1          2     0
                │         legalized by rulings⁷
                └── 3  ShellSpawn = dash, = bash, ≠ both, by environment  0          3     0
                          legalized by rulings⁸
                                                                  ─────────  ─────────  ────
                                                                        142      1,596    77
```

¹ As above.
² Q2 2, A4 1.
³ A5 1,246, rule E 2.
⁴ G16 126, builtin-vs-coreutils 117, B2 31, rule E 10.
⁵ $0 36, B2 35, A4 8, builtin-vs-coreutils 8, the runner 1.
⁶ A5 4, rule E 3, builtin-vs-coreutils 2.
⁷ $0 2, builtin-vs-coreutils 1.
⁸ $0 3, A5 3.

The 1,802 snippets where ShellSpawn differs from at least one shell somewhere: 4 where dash = bash, 1,798 where dash ≠ bash (so that ShellSpawn cannot be as both); 4+1,798=1,802. Each is in exactly one of four groups, 1,633+88+43+38=1,802:
- legalized by rulings: 1,633;
- awaiting A12: 88;
- chance: 43;
- not legalized: 38 (below).

Against the runs of 2026-11-17 (1,804 = 1,629+88+45+42), from the two records ([`tools/large-subset-match.tsv`](tools/large-subset-match.tsv)), snippet by snippet:
- 2 left the 1,804: `exec command -with -flags`, which the parser no longer accepts (X56, D1; it was not legalized), and `find . -print | xargs ls -gilds` (chance: the inode numbers; alike in the one environment it ran in);
- 4 became legalized: the 2 `cd -` with `OLDPWD` unset (ShellSpawn now prints the directory, as dash: A5; they were not legalized), the `zenity` subshell (D3: now as dash where bash raced, A5; not legalized before), and `echo $(date) "0" | tee -a log.csv` (builtin-vs-coreutils; chance before, when a time had differed in one environment);
- so 1,629+4=1,633, 45−2=43, 42−4=38; no snippet came in.
- In 29 `cd` snippets given several words by a program's answer (26 of the not legalized below, and 3 legalized by `$0` and A5), the environments where that answer starts with `-n` changed from "ShellSpawn differs" to agreement beyond the messages (X80); their groups did not change.

### <a id="my-snippets-and-commands"></a>Snippets and commands

A command is one call of `echo`, `printf`, `test`, `[`, `kill` or `pwd` inside a snippet, with the arguments we found at run time (`echo -e '1\n2'`). ShellSpawn does these six as the programs do (R-program: where a shell's builtin and the program differ, ShellSpawn does as the program): `echo`, `printf`, `test`, `[` as coreutils, inside Perl since release 0.10 (IP1), and `pwd` so since post-0.10; `kill` by running the program (procps on Linux). dash and bash have builtins of their own. ("coreutils" below means these programs. `true` and `false`, also run so, take no arguments that could differ.) Every command ShellSpawn ran, in every environment of every snippet where ShellSpawn is not as both shells, has been run alone four ways: by coreutils, by dash's builtin, by bash's builtin and by ShellSpawn ([`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) `-ours`; the answers: [`tools/large-subset-match-calls.jsonl`](tools/large-subset-match-calls.jsonl)).

**The commands** (358 distinct ones; status and output compared; 188+145+12+9+4=358). They come from the 1,802 snippets where ShellSpawn is not as both shells, 142 of the column ≠coreutil and 75 of the column rest (the trees' totals, 77, count also 2 of the 13 timeouts, whose commands were not taken):

```
coreutils = dash = bash                  188   (7 of them differ only in the wording of messages)
coreutils = bash ≠ dash                  145
coreutils = dash ≠ bash                   12
coreutils ≠ dash ≠ bash ≠ coreutils        9
coreutils ≠ dash = bash                    4
                                         ───
run by 142 + 75 snippets                 358   ALL: ShellSpawn = coreutils
```

**The rulings**, by how many snippets' records name each ([`tools/large-subset-match.tsv`](tools/large-subset-match.tsv), the rules found, in some environment), whatever the snippet's group in tree 2; builtin-vs-coreutils is named only where no other ruling comes before it (below) (so A5's 1,306 are 1,253 legalized, 23 awaiting A12 and 30 not legalized, and G16's 214 are 126 legalized and 88 awaiting A12; a snippet may need more than one, so the footnotes of tree 2 may add up to more than their box; the rulings themselves: section 1 of [`large-subset-state.md`](large-subset-state.md#my-section-1), and [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) for those given by snippet):

| Ruling | What it says | Snippets |
|---|---|---|
| A5 | where dash and bash differ at run time, ShellSpawn may side with dash | 1,306 |
| G16 | `~` with `HOME` unset: the home from the password file, as bash | 214 |
| builtin-vs-coreutils | R-program (the user, 2026-11-02): ShellSpawn does the six commands as the programs, where dash and bash differ by their builtins; checked command by command (the ≠coreutil column) | 128 |
| B2 | the interactive builtins (`history`, `fc`, `bind`, `help`, ...) do nothing here | 67 |
| `$0` | each shell is started under its own name | 41 |
| rule E | where dash and bash differ, the better behaviour by the categories of rule E: here `return` outside a function, `cd` without `HOME`: errors, as bash; a pattern never matches `.` or `..`; `[^...]` negates (applied only where [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) names it; the not legalized below have other snippets of the same kinds) | 15 |
| A4 | `set`, `export` without operands list what the program's output would be: outside the subset at run time | 9 |
| Q2 | `printf -v` stays with the program | 2 |
| the runner | `. script` sources the runner's own stand-in for the program `script`, which logs the shell's `$0`: a difference of the test, not of the shells | 1 |

Builtin-vs-coreutils holds in 142 snippets in every environment where ShellSpawn ≠ a shell (and in 2 more in some). In 16 of them another ruling is listed first (A5 14, Q2 2: ShellSpawn = coreutils = dash ≠ bash, and `printf -v`), and only that one is named: 142+2−16=128, the table's count. Builtin-vs-coreutils is applied before chance guessed from a snippet's codes (`pid`, `time`, ...): in 59 snippets with such codes the difference is the command's, and repeatable (`printf '%(%s)T' -1`, `echo -e "... $(date)"`). The report knows A4 by ShellSpawn's status 248 and its message. (`exec command -with -flags` had them too until post-0.13, but it was X56, a bug of ShellSpawn, so it was marked open, not A4.)

### <a id="my-not-legalized"></a>Not legalized

Each was run again by hand in dash, `bash --posix` and ShellSpawn where it was new. The last row of the first table is not a sample of the library: [`tools/large-subset-difffuzz.pl`](tools/large-subset-difffuzz.pl), a fuzzer, found it (post-0.11), and it joins the list to be decided with it:

| Snippet | What happens |
|---|---|
| `echo [^f]oo`, `echo *[^0-9]*`, `mv /mnt/usbdisk/[^l]* …` (3) | `[^...]` in a pattern: dash takes `^` literally, bash and ShellSpawn negate (as rule E, platform; these snippets not yet listed under it) |
| `f() { true; }`, `return`, ... (1) | `return` outside a function: dash ends silently, status 0; bash and ShellSpawn: an error, status 2 (as rule E, error; not yet listed) |
| `echo foo 42>/dev/null`; `head -<$LINENUM + 10> filename` (step 3) (2) | dash takes only one-digit fd numbers: `42` is an argument and nothing is printed; bash and ShellSpawn print `foo` (and redirect descriptor 10) (rule E's choice G12, `fdmulti`; not yet listed) |
| `#!/bin/sh`, `echo $LINENO` (1) | dash prints an empty line; bash and ShellSpawn `2` |
| `cd bar1 find . ...`, and 30 `cd` given several words by a program's answer (`cd $(find . -name config)`, step 3) (31) | dash goes to the first word and ignores the others; bash and ShellSpawn (since X54): "too many arguments", status 1 (rule E's choice `cdargs`; not yet listed) |
| `return \|\| shift \|\| unset IFS` at the top level (the fuzzer) | dash ends the script at `return`, status 0; bash fails both and goes on, status 0 at the end; ShellSpawn fails `return` as bash ([X48](../pspawn-known-issues.md#my-x48), rule E) and then ends at the failed `shift` as dash (rule A5), status 2: each ruling right, the combination as neither shell |

To be decided with the rules (the user, 2026-11-11: later).

None is marked open in [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) now. The four marked so in the runs of 2026-11-17 were fixed in post-0.13: `cd -` with `OLDPWD` unset (2 snippets: ShellSpawn printed nothing; now the directory, as dash), `exec command -with -flags` (ShellSpawn ran its builtin `command`: [X56](../pspawn-known-issues.md#my-x56); the parser now refuses the form, D1), and `(echo "#1"; sleep 1; echo "50"; …) | zenity --progress` (ShellSpawn's `echo` failed alone and the subshell went on; since D3 it ends the subshell, as the shells' builtin does).

The 42 not legalized of the runs of 2026-11-17 were reviewed one by one on 2026-11-22: [`large-subset-review.md`](large-subset-review.md), with the proposals for each. The review found one bug of ShellSpawn among them, [X80](../pspawn-known-issues.md#my-x80), fixed the same day, before the runs counted here: in 26 of the 30 `cd` snippets given several words by a program's answer, some environments have a program answer that starts with `-n` (step 3's `-n a\b %s`), where dash and bash refuse the option, status 2, and ShellSpawn said "too many arguments", status 1; now it refuses the option too.

### <a id="my-how-it-was-measured"></a>How it was measured

Two axes (the user, 2026-11-10):
- **The snippet**: a script, or a part of one, stored in our library. Its level comes from the text alone (sections 1–4). Among the undecided, the **partially decided** are step 3's classes control and affects-shell: every dependence named exactly, and the sample run in example environments that vary them where a setup could be made (sections 10 and 12). They stay `U` in [`large-subset-provenance.tsv`](large-subset-provenance.tsv), which comes from the parse trees alone; they are the samples of [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv), [`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv) and [`tools/large-subset-env-affects-shell.tsv`](tools/large-subset-env-affects-shell.tsv) still undecided.
- **The match**, over the environments a snippet ran in (the base run; for the samples with setups also those, of step 2 and of step 3): whether dash and bash agree, whether ShellSpawn agrees with them, or with which, and wherever ShellSpawn is not as both shells, whether a ruling legalizes it.

Messages count nowhere (the user, 2026-11-11): not on standard error (as in section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), and not where a redirection sends them either. A line starting with dash's, bash's or ShellSpawn's message prefix is dropped from standard output, and files compare by their contents without such lines (the same pattern for all three shells, so texts that were equal stay equal). A message piped into another program (`2>&1 | wc -c`) is not compensated.†

† The same tables with messages compared (11 more snippets differ, 5 more are chance, and rulings for messages legalize them): [`large-subset-match-raw.md`](large-subset-match-raw.md), not part of the analysis.

The levels against the match (*N*+*M*=*T*: *N* sorted programmatically, from the parse trees and the rules of step 3, *M* by Claude reading them; AI-strict counts with strict, AI-values passed on unchanged and on split with those rows, the other AI- categories stay undecided; where *M* is 0, *N* alone; [section 1](#my-section-1), footnote ³):

| Level | Snippets | dash and bash agree | agree in some environments | agree in none | timeout |
|---|---|---|---|---|---|
| strict | 365+27=392 | 339+20=359 | N/A | 22+7=29 | 4 |
| held | 2 | 1 | N/A | 1 | 0 |
| almost strict | 34,301 | 34,256 | N/A | 40 | 5 |
| with values passed on unchanged, not in preceding rows | 664+7=671 | 606+5=611 | 0 | 56+2=58 | 2 |
| with values passed on split, not in preceding rows | 1,476+7=1,483 | 1,473+7=1,480 | 0 | 3 | 0 |
| partially decided | 3,508 | 1,846 | 1,535 | 125 | 2 |
| undecided (the rest): classified by Claude reading them as still undecided | 0+52=52 | 0+45=45 | N/A | 0+7=7 | 0 |

- N/A: of the environments the match counts, these ran in one only (the base run; the variants of section 9 do not count here), so the shells cannot agree in some environments and not in others.
- The rows "with values passed on …" (LV1, [section 1](#my-section-1)) hold 1,220 samples (270+950) that step 2 tried before step 3 made them almost strict; dash and bash agreed or disagreed alike in all of their environments.
- A class's tree in [section 12](#my-section-12) counts only that class's own base runs and setups; the match here counts also the whole library's run and step 2's setups. So a sample may be in another box here than there (NB:5776: "ShellSpawn = dash" in the tree of affects-shell, "= dash in some, = bash in others" here), and the row "partially decided" is not the sum of the two classes' trees (agree 1,846 here, 1,324+2+584+2=1,912 there).
- The undecided (the rest) are the 52 of the 93 classified by Claude reading them that stay undecided; the other 41 count in strict (27) and in the rows "with values passed on …" (7 and 7): 27+7+7=41, 52+41=93.

### <a id="my-the-runs-of-the-match"></a>The runs

- The base is the run of the whole library of 2026-11-22 (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), with:
  - the code of that day (post-0.13), ShellSpawn waiting at exit as the shells do (K5);
  - the runner waiting up to 5 s for every shell's background jobs (A18), and offering the samples only the programs of its fixed list (A23);
  - a program only logged reading what the sample feeds it, its size and SHA-256 logged with the call (IN1), unless the program never reads its standard input (A24 (b)).
- Step 2's samples ran again in full in their setups ([section 10](#my-section-10)), step 3's two classes in theirs ([section 12](#my-section-12)); every file was recorded also without message lines.
- The logging runs (`-q`, which log ShellSpawn's calls of the six commands), in the base run and step 2's setups, covered the 1,815 snippets of tree 1 that were not as both shells in some environment, or timed out (1,802+13=1,815); step 3's setups have logging runs of their own ([section 12](#my-section-12)).
- Made by `make corpus-step2 corpus-step3 corpus-races corpus-match` ([`../test-pools.md`](../test-pools.md#my-section-0), section 0), as part of `make corpus-all` from an empty work directory.

### <a id="my-other-runs-of-the-match"></a>Other runs of the match

- The runs of 2026-11-17 (the second run of that day, with A24 (b) for the 4,060 samples it concerned): alike 38,593, ShellSpawn ≠ a shell 1,804 (legalized 1,629, awaiting A12 88, chance 45, not legalized 42); its logging runs covered 1,817 snippets. What moved from it to the counts above: the end of the first part of this section.
- The first run of 2026-11-17 (IN1: the recorders reading the input of every program they log): alike 38,592, ShellSpawn ≠ a shell 1,805 (legalized 1,629, awaiting A12 88, chance 46, not legalized 42); its logging runs covered 1,818 snippets (in the runs of 2026-11-16, 1,806). 6 snippets moved from it to the table above, each traced against that run's records (kept); no new difference of ShellSpawn:
  - the 2 races the recorder made, `md5sum * | sed '…/e'` and `zcat … | { zcat … | comm -12 /dev/fd/3 - ; } 3<&0`, are gone with A24 (b) (from chance to alike everywhere; their lines in the known list removed);
  - 4 moved by timing, each named chance or open already: `find . -print | xargs ls -gilds` (the inode numbers of the run's copy: from alike to "dash = bash, ShellSpawn ≠ them", chance), `ls -a | tee output.file` (from "ShellSpawn = dash" to "dash = bash, ShellSpawn ≠ them", chance, K6), two `head` reading one pipe (from "ShellSpawn = bash" to "ShellSpawn = dash in some, = bash in others", chance) and the `zenity` subshell (from "ShellSpawn = bash" to "dash = bash, ShellSpawn ≠ them", open: [TODO A17](../../TODO.md#my-a17)).
- The runs of 2026-11-11 to 2026-11-16: their totals are in [`Changes`](../../Changes). What moved between them, each traced at the time:
  - timing and races, among them `ls -a | tee output.file`, which ShellSpawn lists the new file in less often, as it starts `tee` later after `ls` than the shells do (kept so, K6, the user, 2026-11-15; the trace in section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)), and `cat ${SPOOL_FILE} | tee -a ${LOG_FILE}` ([section 10](#my-section-10));
  - the input compared since IN1 (`echo -e …` into a program only logged, legalized; and the two races the recorder made, gone with A24 (b), above);
  - by K5, `tail -F xxxx | tee -a yyyy &`, a timeout of ShellSpawn alone before, alike since.

**Found.**
- X46 and X47 ([section 10](#my-section-10)).
- **❰BUG❱ dash** 0.5.12: with `HOME` empty, `~` is dropped and `~/x` loses its prefix (`HOME=; set -- ~ ~/x; echo $# "$1"` gives `1 /x`, checked 2026-11-18). POSIX treats the result of `~` as quoted, so it should give an empty field; bash and ShellSpawn give it (awaiting the user: [TODO A12](../../TODO.md#my-a12)).
- With the runs of post-0.11: X56 (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)); two more races (above); the `zenity` subshell is persistent, not chance.
- With the runs of post-0.12: the races `cat ${SPOOL_FILE} | tee -a ${LOG_FILE}`, `ls -a | tee output.file` and `find … | xargs ls -lhrt … > log.txt` (above).
- In the tools, both fixed: [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) found B2 and `$0` by the undecided codes `U:…` only, not by those inside `passthrough(…)` that step 3 gave the pass and split samples (so 48 `bind`, `history`, … looked not legalized); and its record of the builtins log glued a call to the one before it (section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)).

**Not done.**
- The not legalized (above).
- The `~` rule awaits the user (88 snippets).
- Chance is not a ruling (43 snippets).
- The strict, held, almost strict and the 93 classified by Claude reading them ran in one environment only.
- A message piped into another program is not compensated.

All of it, from fresh runs: `make corpus-step2 corpus-step3 corpus-races corpus-match` ([`../test-pools.md`](../test-pools.md#my-section-0), section 0). By hand, the report alone: the environments by labels, step 3's with the name of their family (`control/`, `affects-shell/`), and each family's setups. Two runs go under the label `base`: the whole library's run (`FULL`), then step 2's base run, whose lines replace the first's for its samples; the logging run of the base serves `base2` too:

```sh
X=doc/large-subset/tools
R="-run base=FULL -run base=base -run base2=base2"; for k in $(seq 1 30); do R="$R -run s$k=s$k"; done
R="$R -run control/base=C/base -run control/base2=C/base2"; for k in $(seq 1 15); do R="$R -run control/s$k=C/s$k"; done   # and affects-shell/ the same
P="-prov doc/large-subset/large-subset-provenance.tsv -setups setup-samples.tsv -setups control=C/setup-samples.tsv -setups affects-shell=A/setup-samples.tsv -known $X/large-subset-match-known.tsv"
perl $X/large-subset-matchreport.pl $P -o match0.tsv $R > /dev/null                  # which snippets: ShellSpawn not as both
grep -v '^#' match0.tsv | cut -f1 | sort -u > q.ids
unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -q -workers-from FULL -only @q.ids samples.jsonl samples.tsv qbase
for k in $(seq 1 30); do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -q -setup setup-$k.jsonl -only @q.ids samples.jsonl samples.tsv qs$k; done
unshare -n perl $X/large-subset-threeway.pl -shellspawn . -db calls.jsonl qbase qs* C/qbase C/qs* A/qbase A/qs*      # 1 minute
Q="-q base=qbase -q base2=qbase"; for k in $(seq 1 30); do Q="$Q -q s$k=qs$k"; done    # and -q control/s$k=C/qs$k, ... as for -run
perl $X/large-subset-matchreport.pl $P -o match.tsv -record setups.tsv -calls calls.jsonl $Q $R   # -raw: large-subset-match-raw.md
```

## <a id="my-section-12"></a>12. Step 3: where the values from the environment land (made 2026-11-12; last run 2026-11-22)

The user's step 3 ([`TODO`, A1](../../TODO.md#my-a1)): recognize more samples by simple programmatic tests. [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) follows every value a sample takes from the environment (a variable read before the text sets it, an argument, a program's output, the working directory, a glob's matches, a file that a redirection, `test` or `cd` names) to where it lands. It puts each sample that its codes leave undecided into one class. The record, one line per sample: [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv) (`-p`; the class, what keeps it from passing, what the run can set, its undecided codes; the text, not shipped since post-0.14, is restored from the corpora by [`tools/large-subset-restore.pl`](tools/large-subset-restore.pl), as the record's header says).

| Class | Where the values land | Samples | Of them among step 2's 2,901 ([section 10](#my-section-10)) |
|---|---|---|---|
| pass | only through the shell: quoted into a program's words, into an assignment, a `case` word or a here-document; a program's output going on; a status choosing between branches all alike; `pwd`; bash's interactive builtins without file options | 664 | 270 |
| split | the same, and some split and matched against files in a program's words or a `for` list | 1,476 | 950 |
| control | the environment acts only through what the run can set (below) | 2,474 | 1,284 |
| affects-shell | a value affects what the shell itself does (another builtin takes it, arithmetic, `${x:?}`, `set -u`, `set -e`, the shells' own variables; process IDs and the clock: `$$`, `$SECONDS`, `kill` and `wait` with operands; the order of events, `race`) | 1,034 | 397 |
| AI-… | classified by Claude reading them (2026-11-13, below): the 93 of control and affects-shell that the example setups left out | 93 | 0 |
| all | | 5,741 | 2,901 |

The classes take all 5,741 (664+1,476+2,474+1,034+93=5,741). Since X80 (post-0.13) `NB:10012`, `cd bar1 find . … $PWD/{} ../bar2`, is of affects-shell, not control: the parse tree now keeps every operand of `cd`, and `$PWD` is one of the shells' own variables.
- 5,741 are the 5,752 samples undecided before step 3, less 11 where `/` was a delimiter (`cut -d /`, `awk -F/`) and was taken for the whole tree; those 11 are almost strict now on their codes alone.
- Pass and split are almost strict since step 3 (the user's (a), 2026-11-12): code `A:…,passthrough(r,s)` and `splitglob` ([section 2](#my-section-2)), the two assumptions in table 1.
- Control and affects-shell stay undecided, and so do the 93 classified by Claude reading them (they were 50 of control and 43 of affects-shell).

**Tested against step 2's runs.** The 2,901 samples of step 2 ran in example environments ([section 10](#my-section-10); record [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv); a class that differs only in messages counted as the same):

- pass: 270 of 270 kept their class in every setup;
- split: 949 of 950. The other: `rev $filename | …`, which timed out in all three given `two  words *` (the program's doing). Other runs: the same in the runs of 2026-11-17; in the first run of 2026-11-17 also `md5sum * | sed '…/e'`, the race the recorder made with IN1 alone, gone with A24 (b) ([section 11](#my-section-11)); in the runs of 2026-11-14 and 2026-11-16 `cat ${SPOOL_FILE} | tee -a ${LOG_FILE}` instead, a race ([section 10](#my-section-10)), which kept its class in those of 2026-11-13, 2026-11-15 and 2026-11-17;
- control: 1,278 of 1,285 kept their class, or changed only between same, `=dash` and `=bash` within the ruling the record names (counted with `NB:10012`, which kept its class and is of affects-shell since X80: so 1,277 of 1,284 now). The other 7: messages in a file or on standard output (6: `2> bar`, `2>&1 | tee`; that record is written by the comparison with messages counted, `-raw`), and `printf '%q'` (legalized by builtin-vs-coreutils, [section 10](#my-section-10)). Affects-shell (397) was not counted in this way. Pass and split were counted again on the runs of 2026-11-17 and 2026-11-22; control was not counted again in this way, but the record's changes since 2026-11-13 among its samples are in the messages, or between same and `=dash` of a failing redirection (A5).

**Rules from counterexamples.** A first version of the classes had counterexamples; they became rules:
- a value into a builtin other than `echo`, `printf` and `test`, or into the format of `printf` or the shape of a `test` expression, keeps a sample from passing (`set -o "$opt"`, `export "$foo"`, `[ "$@" == "" ]`, `printf "%${count}s"`: the value's shape counts there);
- `cd` with no operand (it depends on `HOME`) and a pattern with `[^` do not pass;
- `.*` and `//` after a pattern component are control (G2, A5).

### <a id="my-control-what-the-run-can-set"></a>Control: what the run can set

The 2,475 samples of control (2,474 since X80, above; not counted again) depend on (1,498+934+43=2,475):
- 1,498 only on switches whose other states the named ruling covers: `ruling:A5` 1,255 (a redirection's file absent, present, a directory or read-only; a `cd` target; a `./program`), `ruling:program` 276 (a value into `echo`, `printf` or `test`, which ShellSpawn does as the programs: R-program, the ruling builtin-vs-coreutils), `ruling:G2` 11 (a pattern for dot names);
- 934 only on a program's answer or a place the run fixes (with `-env cowroot`, each run in a root of its own): the whole tree 523, `/tmp` 183, the clock 171, randomness 65, `/proc` and `/sys` 47, `/dev/urandom` 23. The run's stand-ins answer as chosen, and the programs it runs for real (`ls -l`, `stat`, `sort -R`, `cat /proc/…`) can be stand-ins too;
- 43 on both.

A sample counts under each ruling or place it names, so the parts of the first two items add up to more than 1,498 and 934. Since 2026-11-13 the counts leave out the 50 classified by Claude reading them; before: 1,542 (A5 1,298, program 279, G2 11); 938 (the tree 526, `/tmp` 186, the clock 173, randomness 66, `/proc` and `/sys` 48, `/dev/urandom` 23); 45.

### <a id="my-step-2-for-the-control-class"></a>Step 2 for the control class

As the user asked (2026-11-12: "with any program a stand-in"), [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl) `-step3` gave the 2,474 samples example setups:
- the files and directories they name, absolute names too (every run in a root of its own, a copy-on-write overlay of `/`: [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-env cowroot`);
- their variables, arguments and input as in step 2;
- the programs' answer as one more dependence (base: no output, status 0; answer 1: `x1`, status 0; answer 2: the lines `two  words *` and `last`, status 1; answer 3: `-n a\b %s`, status 0); every stand-in of the run answers so, and the programs the step-3 record names are stand-ins in all their runs, also those the runner otherwise runs for real.  In the runs reported here, a program not on the runner's list had no stand-in and was "not found" in every setup: 31 samples count as alike in every environment, though no answer of their program was tried ([X84](../pspawn-known-issues.md#my-x84); since post-0.13 the runner gives such a program a stand-in for the sample's runs, these runs not made again).

9,189 setups in all, 3 to 15 for each of 2,456 samples (9,192 and 2,457 with `NB:10012`, before X80); 18 got none but the base runs (their undecided codes, `unquoted` or `directory`, come from no value a setup chooses: `echo $(false; echo foo)`, ``echo pwd: `pwd` ``). The names with an expansion (34 samples; below) are included. Left out at first, and classified by Claude reading them since 2026-11-13 (below), 50 (15+10+10+5+4+3+3=50): `cd` to `.` or `..` 15, a name in `/dev`, `/proc` or `/sys` 10, the run's own variable 10, a name from a variable the text sets 5, a pattern without a usable example 4, a system path the run needs to run 3 (the loader, `/tmp` itself), 3 others.

The match over them: [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) `-step3`; record [`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv). Every call of the six commands ([section 11](#my-section-11)) that ShellSpawn made was run alone by the program, dash's builtin and bash's: [`tools/large-subset-env-control-calls.jsonl`](tools/large-subset-env-control-calls.jsonl), 185 calls (`echo` 162, `printf` 12, `[` 7, `test` 3, `pwd` 1), ShellSpawn = the program in all. The runs of 2026-11-22, with the code of that day (post-0.13) and the runner waiting for background jobs:

```
2,474  the control class, each in its base and setups
│
├── 1,324  ShellSpawn = dash = bash, in every environment
├──     2  dash = bash; ShellSpawn ≠ them                legalized by Q2
└── 1,148  dash ≠ bash, in some or all environments
     ├── 1,092  ShellSpawn = dash                       legalized by A5 1,091; chance 1 (xargs ls -lhrt, file times)
     ├──    53  ShellSpawn = bash
     │          ├── 52  legalized by rulings            builtin-vs-coreutils 49, rule E 3
     │          └──  1  not legalized                   head … 10> filename (TODO A13)
     ├──     1  ShellSpawn ≠ dash, ShellSpawn ≠ bash    legalized by builtin-vs-coreutils
     └──     2  depends on the environment              legalized: A5 and builtin-vs-coreutils
```

Other runs:
- 2026-11-17: 2,475 with `NB:10012`; dash ≠ bash 1,149, ShellSpawn = bash 54: legalized 51 (builtin-vs-coreutils 48), chance 1 (`echo $(date) "0" | tee -a log.csv`, a race: the stand-in's answer `*` lists `log.csv` or not), not legalized 2 (`NB:10012`, `cd bar1 find …`, the same in every environment, now of affects-shell; and `head … 10> filename`). On 2026-11-22 `echo $(date) …` gave one result in each environment, so the report counts it legalized (builtin-vs-coreutils), not chance.
- 2026-11-16: alike 1,328, dash ≠ bash 1,145, ShellSpawn = dash 1,091, ShellSpawn = bash 50, depends on the environment 3. 9 samples moved from them to the tree above:
  - 4 by the input now compared (IN1), all legalized: `bind -l | grep /` (only bash has `bind`; from alike to "ShellSpawn = dash", A5), `echo -e …` into a program only logged, and two ``echo … `date …` … | bc`` given a stand-in's answer with a backslash (dash's `echo` interprets it; to "ShellSpawn = bash", builtin-vs-coreutils);
  - `echo $(date) "0" | tee -a log.csv`, a race (the stand-in's answer `*` lists `log.csv` or not), now also with ShellSpawn alone differing (dash = bash) in one setup; the tree puts it by its setups where dash ≠ bash (chance);
  - 4 by timing, in one setup's class only (messages, and `cat file | … > file`).
- 2026-11-14: ShellSpawn = bash 51, depends on the environment 2; `echo $(date) "0" | tee -a log.csv` moved, one of its setups then `=dash`; not traced.

So the class held for 2,472 of the 2,474: where a setup changed a sample's class, it changed it only into a difference a ruling legalizes. The 2 others ([`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv)): NB:6724, `head -<$LINENUM + 10> filename`, where a setup made the descriptor number `10` (not legalized, below, "Names with an expansion"), and one by chance, NB:4904 (`xargs ls -lhrt`, file times). (On 2026-11-17 also NB:9728, `echo $(date) "0" | tee -a log.csv`, a race, above; and `cd bar1 find …`, not legalized, was so in the base run too: the environment did not make it.) In the runs of 2026-11-13 one more race was not so: NB:12523, `find $DiskName … | sort … >> $TMPFILE` given `two  words *`, where `sort`'s redirection makes the file `two  words *` that `find`'s pattern sees or not by timing (in dash it did, in bash and ShellSpawn not; in the runs of 2026-11-12 and 2026-11-14 all three alike, so `=dash` by A5 there). The control samples are partially decided now (below, with the class affects-shell).

**Found on the way, in the tools.**
- The logs of the calls (ShellSpawn's and the programs') hold one call a line, but an argument may hold a newline. [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) and the match report now join such lines (the test of the calls had missed those of setups whose answers end in a newline), and the comparison of the programs' calls keeps empty lines (an argument's newline made one, and the sort had dropped it at the end of one shell's log only).
- G2 is also found by a setup's description now ([`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv): a pattern for dot names given matching files).
- A setup that would take from the run what it needs (the loader, `/tmp` itself) is left out, and the runner records a run whose environment cannot be made instead of stopping.

### <a id="my-step-2-for-the-class-affects-shell"></a>Step 2 for the class affects-shell

As the user asked (2026-11-12): the same as for control, with the class's samples (`-class affects-shell`) and three more controls of the runner:
- the same `$0` for the three (`-env samearg0`);
- every run in a PID namespace of its own (`-env pidns`: `$$`, `$PPID`, `$!` the same in every run);
- the variables the shells set themselves varied too (how each takes an inherited value), but not those the run needs (`PATH`, the locale); `HOME` only as the setups of `~` vary it.

A fixed clock (`-env clock`, libfaketime) was tried and dropped: libfaketime 0.9.10 opens its shared memory as descriptors 3 and 4 in every process it is preloaded into (`echo text >&3` then succeeds in dash and bash), and it would fix little (`date` is a stand-in, file times are fixed, `times` counts CPU time).

923 got setups, 4,782 in all, 3 to 15 a sample (922 and 4,773 before `NB:10012` came, above, with 9); 111 got none but the base runs (with `samearg0` and `pidns`): no setup varies what they depend on (by their first code: `race` 53, `listing` 21, `interactive` 12, `lookup` 6, `limits` 6, `start` 5, others 8; 53+21+12+6+6+5+8=111). The names with an expansion (85 samples; below) are included. Left out at first, and classified by Claude reading them since 2026-11-13, 43 (14+13+6+4+2+4=43): the run's own variable 14, a name from a variable the text sets 13, `~user` 6, `cd -` 4, a name from a program not on `PATH` 2, 4 others. Record [`tools/large-subset-env-affects-shell.tsv`](tools/large-subset-env-affects-shell.tsv), calls [`tools/large-subset-env-affects-shell-calls.jsonl`](tools/large-subset-env-affects-shell-calls.jsonl) (128 calls: `echo` 56, `kill` 32, `printf` 19, `[` 16, `test` 5; ShellSpawn = the program in all; 130 on 2026-11-17, when the `zenity` subshell still made its later `echo`s, before D3); the runs of 2026-11-22:

```
1,034  the class affects-shell, each in its base and setups
│
├── 584  ShellSpawn = dash = bash, in every environment
├──   2  timeout (in all three)
├──   2  dash = bash; ShellSpawn ≠ them             A4 1, chance 1 (NB:6259, xargs -P4, a race)
└── 446  dash ≠ bash, in some or all environments
     ├── 129  ShellSpawn = dash                     rulings 109 (A5, rule E), A12 19, chance 1
     ├── 246  ShellSpawn = bash                     rulings 177 (G16, builtin-vs-coreutils, B2, rule E, $0),
     │                                              awaiting A12 64, chance 1, not legalized 4
     ├──  30  ShellSpawn ≠ dash, ShellSpawn ≠ bash  rulings 22 (B2, A4, builtin-vs-coreutils), A12 1, chance 7
     └──  41  depends on the environment            rulings 7, A12 4, not legalized 30
```

The 448 where ShellSpawn differs from at least one shell (2 where dash = bash, 446 where dash ≠ bash) are each in exactly one of four groups (316+88+10+34=448):
- legalized by rulings: 316;
- awaiting A12 (`~` with `HOME` empty): 88;
- chance: 10, as the report counts them. Of these, 3 are races tested by many runs (NB:685, 10 runs each: two readers of one pipe, all three gave both results; NB:6259 and NB:5776, below). The other 7 the report counts as chance by their codes (`listing`, `pid`, `time`: a guess from the text), but they are persistent results (the same in every run, which the environment does not change), and no ruling covers them yet ([`TODO`, A17](../../TODO.md#my-a17)): the environment that `env` and `printenv` list (5: bash adds `SHLVL` and `_`; dash and ShellSpawn list the same variables, in another order; since IN1 also `v=5 env | less`, whose input is now compared), `/proc/$$/cmdline` (1: each shell's own command line, ShellSpawn's a Perl one), `times` (1: ShellSpawn, being Perl, has used CPU time where dash shows 0); 3+5+1+1=10;
- not legalized: 34 (3+30+1=34): `[^…]` 3; `cd` with extra words 30, all from a program's answer in a name with an expansion; and `NB:10012`, `cd bar1 find …`, with extra words in its text, the same in every environment (all [`TODO` A13](../../TODO.md#my-a13)).

Against the runs of 2026-11-17 (447 = 315+88+10+34): the `zenity` subshell went from not legalized (marked open: the box "dash = bash") to legalized ("ShellSpawn = dash", A5), since D3 makes ShellSpawn's subshell end as the shells' do, and in its base run bash raced; `NB:10012` came in, not legalized; the races NB:6259 and NB:685 moved between the boxes (chance either way).

Other runs (the races move between the boxes from run to run, by what they gave):
- The runs of 2026-11-17 (the second of that day): 1,033 samples; 447 (2 and 445), above.
- The first run of 2026-11-17: 448 (2 and 446), with `zcat … | { zcat … | comm -12 /dev/fd/3 - ; } 3<&0`, the race the recorder made with IN1 alone, gone with A24 (b) ([section 11](#my-section-11)), and two `head` reading one pipe, NB:685, then in the box "ShellSpawn = bash", now in "depends on the environment" (chance either way).
- The runs of 2026-11-16: 446 (3 and 443); 6 samples moved from them: `v=5 env | less` (by the input now compared, chance) and the recorder's race above, from alike; the races NB:5776, NB:6259, NB:685 and the `zenity` subshell between the boxes.
- The runs of 2026-11-15: 2 and 444.
- The runs of 2026-11-14: one sample moved from them: `tail -F xxxx | tee -a yyyy &`, a timeout of ShellSpawn alone before (ShellSpawn waited at exit for the endless job), alike now that ShellSpawn exits once it has started the job's programs (K5); the chance ones moved between the boxes of the tree only.
- The runs of 2026-11-13: one sample moved, from "ShellSpawn = bash" to "ShellSpawn as neither", both chance: NB:685, two readers of one pipe.
- Before the runner waited for background jobs (below; the 46 samples of the class with a background job ran again so), the tree had 556 alike and 23 where only ShellSpawn differed.

### <a id="my-the-races-run-many-times"></a>The races, run many times

Made 2026-11-12 by `make corpus-races` ([`tools/large-subset-repeat.pl`](tools/large-subset-repeat.pl); record [`tools/large-subset-env-races.tsv`](tools/large-subset-env-races.tsv)).

- What ran: the 33 samples the report called chance by their code `race` (23 alike in base and base2, 10 not; NB:9420 came with the names with an expansion), 20 times in each environment where ShellSpawn was not as both shells (120 sample-environments). Each shell's results (as the report compares them: status, output, the programs' calls, the files; messages not) were set side by side.
- The first round (17+2+14=33): 17 races (ShellSpawn gave only results a shell gave too), 2 races with a timing of ShellSpawn's that the shells did not show in 20 runs, and 14 where ShellSpawn gave its own result in every run: a background job still running when the text ends.
- Those 14 were not races. Until post-0.12 ShellSpawn finished its background jobs before it ended (`Proc::ShellSpawn`'s `END` block, after K3: `sleep 2 &` took ShellSpawn 2 s, the shells 3 ms; since K5 ShellSpawn exits once it has started the job's programs, as the shells leave theirs: [`pspawn-design.md`](../pspawn-design.md#my-section-6), section 6). Dash and bash end at once and leave the job running, and the run then killed it (`pkill`, or the PID namespace ending with the shell), often before its programs had done anything.
- The user's decision (A18, 2026-11-12): the runner waits for every process of the run, with a reasonable timeout ([`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-after 5`, the default: up to 5 s after the shell ends, then the rest is killed and the run says so; with `-env pidns`, process 1 of the namespace reaps and waits).
- The second round, with that and X55 fixed (below): 2,400 runs of each shell (120×20), none cut by the 5 s:

```
33  races by their code, 20 runs in each environment where ShellSpawn was not as both
│
├── 27  the same in the three in every run (the difference found before was not reproduced)
├──  4  race: ShellSpawn gave only results that dash or bash gave too                           chance
└──  2  race, a timing of ShellSpawn's the shells did not show in 20 runs                       chance
        NB:6259  seq 10 | xargs -P4 …: the order of four parallel echo (16, 16 and 14 different
                 orders in 20 runs of dash, bash and ShellSpawn; the known list says 17, 16 and
                 20: which round each is of is not recorded)
        NB:5776  { echo foo; cat bar; } | tee bar: bar is tee's output and cat's input; it ends at
                 4 bytes if cat reads it before tee has copied foo into it, 8 if after, more if cat
                 reads tee's next copy too (in the runs: 4, 8, 12, 760, 1,344); by hand, 200 runs
                 each: dash 4 (188) or 8 (12), bash 8 (189) or 4 (11), ShellSpawn 8 (200)
```

[`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) names NB:6259 and NB:5776 "chance" with what was seen. The tree above is the round of 2026-11-12.

**Later rounds.**
- 2026-11-13 (`make corpus-races` after the runs above): of the samples the report calls chance by their code `race`, only `(echo "#1"; sleep 1; echo "50"; …) | zenity --progress` was left (the others now agree in every environment, or are named chance by what was seen). In 20 runs ShellSpawn gave its own result every time, one `sleep 1` more than dash and bash: not a race but a persistent difference (the shells' builtin `echo` dies of SIGPIPE and ends the subshell; ShellSpawn's fails alone and the subshell goes on; section 7 of [`large-subset-state.md`](large-subset-state.md#my-section-7)). Marked open in the known list, [`TODO` A17](../../TODO.md#my-a17).
- 2026-11-14 (with `make corpus-all`): the report calls no sample chance by its code `race` any more (the `zenity` subshell is marked open, the others agree or are named chance by what was seen), so there was nothing to repeat. The record [`tools/large-subset-env-races.tsv`](tools/large-subset-env-races.tsv) is now empty but for its header (`make corpus-races` failed on the empty set at first: its loop took the unmatched pattern for a file; fixed).
- 2026-11-15 (the runs with K5) and 2026-11-16: again nothing to repeat. The record has one column more, which shells repeat: `large-subset-repeat.pl` now splits where ShellSpawn varies into "each shell repeats" and "one shell repeats", and counts "both shells vary" apart, as not comparable.

**Found with the races:** X55 (ours; fixed): the deferred SIGCHLD handler that moves background jobs on between `run()` calls reaped through `waitpid`, which sets `$?`, and did not keep the program's `$?`. When a job ended just as `t/try.pl` exited, Perl exited with status 255 and no message (about 1 run in 200 of samples with `… &`; in the first round 4 of the 2,400 runs, not all of them of such samples; none in the second).

**Found on the way:** X53 (ours; fixed): a form of `command` the parser refuses, made only by expansions at run time, ran as a program named after the option (both shells: an error). The 28 samples with `command` of both classes ran again with the fix. The match report now knows A4 by ShellSpawn's status 248 and its message (it knew it only by snippet).

### <a id="my-names-with-an-expansion"></a>Names with an expansion

Made 2026-11-12, as the user asked: choose the value and make the file of that name together. A file or directory whose name only an expansion gives at run time (`cat < "$fname"`, ``cd `dirname $TARGET_FILE` ``, `~/.bashrc`, `$PWD/*`) gets a name the setup chooses:
- every value in it is `x1` (a variable the run reads before it sets it, as its own state 2; `$1`, `$2`, `$@`: the arguments `x1` …; a program's output: the programs' answer `x1`, as their answer 1, that program a stand-in), or the run's own (`~` and `$HOME`: `home/` in the run's directory; `$PWD`, `$(pwd)`: the run's directory; `$$`: 2 in a PID namespace);
- the file of that name then takes the states of its kind (a file with two lines, an empty one, a directory; for `cd`: a directory, a file, a directory not searchable; for a pattern: matching names);
- where no dependence of its own sets the value, the setup sets it as chosen (its description says "chosen: …"); where that dependence never holds the chosen value (`HOME`; `$2` and later), the name gets three setups more, alone.

Of the 149 such samples, 119 got setups (control 34, affects-shell 85). Left out, 30 (18+1+1+2+8=30): a name from a variable the text itself sets (a `for` or `read` variable, an assignment) 18, `~user` 1, from arithmetic 1, from a program not on `PATH` 2, and 8 then left out for another reason (the run's own variable, `cd -`, `cd .`). The setups of every other sample stayed as they were (compared line by line).

Of the 119 (28+38+21+1+31=119): 28 alike in every environment; 38 legalized by rulings (A5 34, G16 3, rule E 1, `$0` 3; a sample may need more than one); awaiting A12 21; chance 1 (NB:9420, a background job); not legalized 31: `cd` with extra words 30, and NB:6724 (below). These counts are of the runs of 2026-11-12: no record marks these samples, so they were not counted again on later runs; the trees above are of the runs of 2026-11-22. (Of the snippets whose group in the match changed on 2026-11-22, section 11, none is among the 119.)

Found with them:
- X54 (ours; fixed): `cd` with more operands made by an expansion at run time said `cd: bad argument`, status 2, as neither shell (dash takes the first operand; bash: "too many arguments", status 1), and not as ShellSpawn did with the operands in the text (as bash, rule E). Now "too many arguments", status 1, either way. The 54 samples of both classes whose `cd` operand holds an expansion ran again with the fix.
- NB:6724 (`head -<$LINENUM + 10> filename`, control): `10>` redirects descriptor 10 in ShellSpawn and bash (G12, the option `fdmulti`), while dash takes `10` as a word; not legalized, as `echo foo 42>/dev/null` ([`TODO` A13](../../TODO.md#my-a13)), where it joins.

So, of the 3,601 left undecided by the programmatic sorting (3,560 after Claude's reading, [section 1](#my-section-1)), 3,508 are partially decided (step 2's samples that are still undecided, and the two classes here); the other 93 (3,508+93=3,601), which the setups left out (control 50, affects-shell 43), are classified by Claude reading them.

### <a id="my-classified-by-claude-reading-them"></a>Classified by Claude reading them

Done 2026-11-13, in the user's categories: `AI-` and the name of a category used before, and `AI-PATH-twister`. The record, [`tools/large-subset-ai-classes.tsv`](tools/large-subset-ai-classes.tsv), has one line a sample: its category, kind and outcome, the class the rules gave, what it depends on, and why. [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) `-ai` writes the category as the class in [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv) (the levels and every setup stay as they were: checked). A new case is one more line. The setups' reasons for leaving them out, and why each was read so: [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl)'s list above.

| Category | Samples | What they are |
|---|---|---|
| AI-strict | 27 | one run is enough: the result depends on nothing a run can change, 18 (`cd /`, `cd ..`, `cd -P .`, `cd /tmp`, `ls -l` of the loader: 16 succeed; `>/` from a placeholder, `./ file`: 2 fail), or on a device working as expected, 9 (reading `/dev/zero`, `/dev/urandom`: 3 succeed; writing `/dev/fd0`, `/dev/tty13`, `2>/dev/nul`: 6 fail here) |
| AI-names with an expansion | 26 | a value the text itself sets (`for f in *; do cd $f`, `… \| while read d; do cd "$d"`, `file='foo bar'; echo foo > $file`; 19), a program at a fixed path not on `PATH` (2), a file under `$HOME` (5) |
| AI-values passed on unchanged | 7 | `$PATH`, `$TMPDIR`, `$USER` quoted into a program's words (`mktemp "${TMPDIR:-/tmp/}…"`) |
| AI-values passed on split | 7 | the same unquoted (`find $HOME/projects/`, `finger ${USER}`) |
| AI-tilde | 6 | `~user`: the user database |
| AI-A5 | 5 | a redirection's file or a `cd` target outside the run's directory (`> ../lpicpio.1`) |
| AI-glob | 4 | patterns the setups found no example name for (`find ./*`; `s/[[:space:]]*$//` split by its quotes; `/usr/bin/python[23]`) |
| AI-shells' own variables | 4 | `cd -` with `OLDPWD` |
| AI-PATH-twister | 4 | the text changes `PATH`, which decides what the shell finds afterwards (`PATH=$PATH:/stuff`, `export PATH=…`) |
| AI-noise | 3 | not shell text: placeholders (`find ~/ [опция_поиска] …`), readline's settings file (`inputrc`) |

The categories take all 93: 27+26+7+7+6+5+4+4+4+3=93. What each category would take is in [`TODO`](../../TODO.md) (B); the classification awaits the user (A).

**Affects-shell, by reason** (the samples with that reason / those with no other; a sample counts under each of its reasons; the reasons are what keeps a sample from passing, the column of [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv), not the codes of table 2, so the second counts differ from table 2's): `~` 269 / 262 (`HOME`: with it empty dash drops the word, [`TODO` A12](../../TODO.md#my-a12)), a variable 133 / 64 (the shells' own, unquoted into a builtin, arithmetic), unquoted into a builtin 122 / 38, `pid` 103 / 67, `race` 86 / 79, files 79 / 38 (`.` of a file, `[^` patterns), a command name from a value 73 / 1, `test-ops` 68 / 10, a program's output read by the shell (`| while read`) 67 / 50, `read` from the run's input 56 / 40, `$0` and `$-` 43 / 33, …

### <a id="my-the-assumptions-probed"></a>The assumptions, probed

With [`tools/large-subset-valueprobe.pl`](tools/large-subset-valueprobe.pl) (`make probe-values`, 2026-11-12):
- `passthrough`: 22 odd values (empty, `-n`, backslashes, trailing newlines, NUL, invalid UTF-8, control characters, 100,000 bytes, …), in the environment or in a file read by `$( )`, through 11 forms (quoted words, assignments, `${X:-d}`, here-documents, `export` of the variable to a program, output going on, a pipe): the three alike.
- `splitglob`: 45 values (blanks, `IFS` characters, pattern characters, backslashes, `//`, a leading dot, non-ASCII) in 5 forms (the default `IFS`, `IFS=:`, `$( )`, a `for` list, `set -f`) with files there: alike but for `[^a]*` (A13), `.*` (G2) and `d*//e` (A5).
- The probe found X52 ([`pspawn-known-issues.md`](../pspawn-known-issues.md); fixed).

**Not checked.**
- The classes come from the rules above, and are only as right as those rules.
- Control and affects-shell ran in their setups, but for the 18 and 111 that got none (above; the 93 the setups left out Claude read one by one), and pass and split in step 2's where they were among its samples (270 and 950). Only the other pass and split samples, 920 (394+526), were checked by Claude reading samples drawn at random from each class (about 150), not by runs.
- The probes try the values listed, not every value.
- The tool's output for `-d` differs from section 10's in two ways: the 11 samples above, which step 3 made almost strict, and block numbers, which change no level (a command with a `$( )` in its words now has its own codes; before, the codes after the `$( )` went to the command inside it).
