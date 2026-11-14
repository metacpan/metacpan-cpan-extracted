# The corpus samples and the run's environment (known issue X27)

Post-0.08, 2026-11-07. The run-time comparison of [`large-subset-state.md`](large-subset-state.md), section 7, runs each of the 40,410 corpus samples that the large parser accepts once in dash, once in `bash --posix` and once in ours. Every run gets the same almost empty directory, a few fixed variables, no arguments, `/dev/null` as input, and programs that only log their call (but for the plain text tools: [`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl)). An agreement there is a real one only if the comparison could not come out otherwise in another environment. This document says, for every sample, whether that is shown, and if not, on what it may depend. The record, one line per sample: [`large-subset-provenance.tsv`](large-subset-provenance.tsv) (section 2).

The method is the user's (2026-11-07): parse all the samples in one batch, split them into atomic blocks marked with their samples, and sort them with a filter that passes only what is shown unaffected. A pass is meant to be definite (under the assumptions it names); a non-pass is no verdict. The tool: [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl). It works from the parse trees alone: nothing runs. Programs are taken as real and opaque: the tool knows what the shell does with a program (looks it up, hands it words and descriptors, takes its output or its status), not what the program does.

## 1. The answer in short

| Level | Samples | |
|---|---|---|
| **strict** (S): the comparison cannot change with the environment; only how the shell is started is assumed | 365+27=392 ³ | 1.0 % |
| **held** (H): the same, under assumptions known to hold in every environment tested (Linux, Linux without `/proc`, Windows under Wine): `devnull`, `heredoc` | 2 | 0.0 % |
| **almost strict** (A): the same, if the named assumptions hold | 34,302 ¹ | 84.9 % |
| **with values passed on unchanged, not in preceding rows**: the same, if also every value from the environment only passes through the shell unchanged (assumption `passthrough`; step 3, section 12; the user, 2026-11-12) | 664+7=671 ¹ ³ | 1.7 % |
| **with values passed on split, not in preceding rows**: the same, but some of those values are split and globbed into a program's words (assumptions `passthrough` and `splitglob`; none needs `splitglob` alone) | 1,476+7=1,483 ¹ ³ | 3.7 % |
| **undecided** (U): not shown either way; the codes name what the comparison may depend on | 3,508+52=3,560 ² ³ | 8.8 % |
| of them **partially decided** (P; the user, 2026-11-10): every dependence named exactly and tried in example environments (sections 10 and 12) | 3,508 | 8.7 % |
| of them classified by reading as still undecided (AI-names with an expansion 26, AI-tilde 6, AI-A5 5, AI-glob 4, AI-shells' own variables 4, AI-PATH-twister 4, AI-noise 3; section 12): the others, which the example environments left out | 0+52=52 ³ | 0.1 % |

¹ Tried in another environment (section 9; run again post-0.11, 2026-11-13; the samples as the levels are now, the three rows together): the samples that need `echo`, `locale`, `pipeline` or `devfd` were run again with the other case (110, 15, 4,777 and 12 samples): 21, 1, 4 and 2 of them came out otherwise beyond the messages (`echo` and `locale`: ours' `echo` or `printf`, coreutils' meaning, against the shells' builtins; `pipeline`: endless writers, `yes | … | sed 100q`, that no longer stop; `devfd`: `/dev/stdin` missing without `/proc`); 49 more changed only in the messages under `pipeline`. Those that need `path-var`, `path-home`, `path-mnt` or `path-dev` (960) were run with those places empty or private: 1 changed, in its messages only. Changes also seen between two runs of the same environment are left out. The level stays as the parse trees give it (the user, 2026-11-08, EV1: the runs go into footnotes, not into the levels).

² Tried in another environment (section 9; run again post-0.11, 2026-11-13): of the undecided samples with `path-tmp`, 207 ran with a fresh `/tmp`: 7 came out otherwise (they had met another run's files there); with `path-random`, 25 ran with a fixed `/dev/urandom`: all 25 now agree (16 had differed by chance). Of those that would also need the assumptions of footnote 1 (333 with `echo`, 10 `locale`, 965 `pipeline`, 1 `devfd`, 57 a `path-` place made empty or private), 10, 0, 5, 0 and 0 came out otherwise beyond the messages. With stand-ins (every program the run only logs answering otherwise): of 113 with `prog-status`, run with status 1, one came out otherwise beyond the messages (a loop waiting for a program to succeed never ends, in all three); of 1,014 with `prog-output`, run with a chosen output, 47 did (and 1 went from a difference to messages only), none with ours against both shells (`cd` given several words, not legalized, [`TODO`](../../TODO) A13; decided differences of `cd`, `kill`, `test`; `unset`, known issue X35, fixed); of 223 with `time`, run with fixed file times, none changed class beyond the noise. Undecided they stay (EV1).

³ N+M=T: N found by the programs (the parse trees, the rules of step 3), M classified by reading (AI-…, the user's categories, 2026-11-13; section 12: AI-strict counts with strict, AI-values passed on unchanged and on split with those rows; the other AI- categories leave a sample undecided), T both. Where M is 0, N alone.

The two rows "with values passed on …" are apart from almost strict since LV1 (the user, 2026-11-13: not the same trust); in the record they keep the letter A, their codes tell them apart (`passthrough`, `splitglob`).

By source (strict / held / almost strict / with values passed on unchanged / with values passed on split / undecided; N+M=T as ³): tldr 62+3=65 / 0 / 27,604 / 99+1=100 / 277+1=278 / 1,178+7=1,185 of 29,232; NL2Bash 99+17=116 / 0 / 6,383 / 467+5=472 / 1,116+5=1,121 / 1,919+28=1,947 of 10,039; ShellCheck 185+7=192 / 1 / 287 / 78+1=79 / 79+1=80 / 370+12=382 of 1,021; the bash Cookbook, pure-sh-bible and pure-bash-bible 19 / 1 / 28 / 20 / 4 / 41+5=46 of 118. Strict is small because nearly every sample runs a program, and every program needs the assumption `program`.

## 2. The record: [`large-subset-provenance.tsv`](large-subset-provenance.tsv)

One line per accepted sample, sorted by snippet ID, after a header of `#` lines that says what follows and points here:

```
ID<TAB>CODE
```

- `ID`: the snippet ID, which says where the text comes from (format: [`../parsers/shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md), section 2; the texts are remade from the pinned sources by [`tools/large-subset-extract.pl`](tools/large-subset-extract.pl), see section 6).
- `CODE`:
  - `S`: strict.
  - `H:a,…`: held; the assumptions `a`, … are known to hold in every environment tested (section 3, table 1).
  - `A:a,b,…`: almost strict; the comparison cannot change if the assumptions `a`, `b`, … hold (section 3, table 1; held ones may be among them). `passthrough(r,s)`: the assumption `passthrough`, with the undecided codes `r`, `s` whose values only pass through the shell (step 3, section 12).
  - `U:r,s,…` or `U:r,s,…/a,b,…`: undecided; it may depend on `r`, `s`, … (section 3, table 2); after `/`, the assumptions it would also need if those were settled.

Examples:

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
grep -v '^#' $F | awk -F'\t' '$2 ~ /^A:/' | cut -f2 | sed 's/([^)]*)//' | sort | uniq -c | sort -rn   # table 3 below
grep -v '^#' $F | awk -F'\t' '$2 ~ /^U:([^/]*,)?path-tmp([,\/]|$)/'               # undecided by path-tmp
```

## 3. The codes

**At a glance.** Every code, one line each. Level: H held, A almost strict (`passthrough`, `splitglob`: the rows "with values passed on …" of section 1, LV1), U undecided. "Samples": for an H or A code, the held or almost strict samples that need it; for an undecided code, the undecided samples that have it (a sample can have several). "Control": whether the run could make the case fixed, or try the other one. Tables 1 and 2 below say more.

| Code | Level | Definition | Samples | Control |
|---|---|---|---|---|
| *programs* | | | | |
| `program` | A | A program is run (any command that is not a builtin or a function of the text); assumed: looked up alike, gets the same words, descriptors and environment, does the same in each run, does not act on the shell | 36,253 | stand-ins only |
| `devnull` | H | a redirection to `/dev/null`: dash and bash have it (POSIX); ours on Windows gets `NUL` (Perl's open, and [`win_spawn.h`](../../win_spawn.h) since X31's fix). Given to a program as a word it is the program's business: no code | 59 | held |
| `devfd` | A | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N` are used (on Linux: needs `/proc`) | 12 | yes |
| `heredoc` | H | a here-document with expansions or of 4,096 bytes or more: bash may use a temporary file (`TMPDIR`, else `/tmp`, which every tested system has); ours uses a pipe | 3 | held |
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
| *values from the environment (step 3, section 12)* | | | | |
| `passthrough` | A | every value from the environment only passes through the shell: quoted into a program's words, into an assignment, a `case` word or a here-document; a program's output going on; a status choosing between branches all alike; `pwd`; bash's interactive builtins (no file options); assumed: the three hand such a value on unchanged, whatever it is | 2,140 | probed |
| `splitglob` | A | such a value split and matched against files in a program's words (or a pattern of the text there); assumed: the three split and match any value alike, but for `[^…]`, `.*` and `//` after a pattern component | 1,476 | probed |
| *files and places the shell itself uses* | | | | |
| `files` | U | pathname expansion; a redirection to or from a file (`2>errfile` too); `test -e` and the like; `.`; `./cmd` | 1,464 | yes (fixtures) |
| `directory` | U | `cd`, `pwd`: the working directory, `HOME` | 147 | yes |
| `tilde` | U | `~` (`HOME`), `~user` (the user database) | 269 | partly |
| *values* | | | | |
| `vars` | U | a variable read before the text sets it (from the environment, or unset) | 401 | yes (chosen values) |
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
| `prog-status` | U | a program's status decides (`&&`, `||`, `!`, `if`, `while`; `$?` after it; under `set -e`) | 35 | stand-ins only |
| `status` | U | `$?` at the start of a function's body or a trap action: what ran before is not in the text | 4 | no |
| *chance* | | | | |
| `race` | U | the order of events: `&`, `xargs -P`, a compound command or a function writing into a pipe | 86 | no |
| `pid` | U | `$$`, `$!`, `$PPID`; `kill`, `wait`, `jobs`, `fg`, `bg` with operands | 103 | no |
| `time` | U | `times`, `$SECONDS`, bash's `time`, `printf '%(…)T'`, `date`, `stat`, `ls -l` | 223 | no (stand-ins) |
| `random` | U | `shuf`, `mktemp`, `uuidgen`, `sort -R` | 72 | no (stand-ins) |
| *the machine's setup* | | | | |
| `lookup` | U | `command -v`, `type`, `hash`: what is installed | 6 | yes (fixed `PATH`) |
| `limits` | U | `ulimit`; `umask` alone | 6 | yes |
| `fd` | U | a descriptor above 2 not opened by the text (`>&3`), `test -t`, `set -m` | 5 | yes |
| `interactive` | U | `history`, `fc`, `bind`, `help`, `compopt`, `logout` (B2) | 22 | partly |

**Table 1: the assumptions of "held" and "almost strict".** "Needed by": held or almost strict samples whose level rests on it (a sample can need several; table 3 has the combinations). "Under our control": whether the run could make the assumption true, or try the other case.

| Code | The assumption | Needed by | Under our control |
|---|---|---|---|
| `program` | An external program (looked up on `PATH`, or named by a path): the three shells look it up alike and hand it the same words, descriptors and environment; it does the same in each run (no clock, no randomness, no process IDs of its own), does not act on the shell (`killall bash`), and does not mind the variables a shell adds to the environment it passes (bash: `SHLVL`, `_`). Its output, status and effects are then the same for all three, as long as the shell does not use them (that is `prog-output`, `prog-status`). Programs known to break it are undecided instead (`time`, `random`, `race`), but that list cannot be complete (`ping`, `top`, network clients). | 36,253 | Only by replacing programs with stand-ins that behave the same in each run, as the run's recorders do (then the programs themselves are not exercised). |
| `pipeline` | A pipeline: its elements run at once; when a reader stops before the end of its input, the writer is killed by SIGPIPE, silently, and only the last element's status counts. That holds with SIGPIPE at its default. If the environment ignores SIGPIPE (it is inherited), a writer instead gets an error and may print a message (bash's builtins print "write error: Broken pipe"), so the messages may differ. | 4,777 | Yes: the runner starts the shells with SIGPIPE at its default ([`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) does). A second run with SIGPIPE ignored would try the other case. |
| `devnull` | **Held.** A redirection to `/dev/null`: a POSIX system has it, so dash and bash do; on Windows ours gets `NUL` from Perl's own `open` (for the shell layer) and from [`win_spawn.h`](../../win_spawn.h) (for `Proc::Spawner`'s open action; X31, fixed and checked under Wine). `/dev/null` given to a program as a word is no code: what the program does with it is the program's business, the same under every shell. | 59 | Held in every tested environment. |
| `devfd` | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N`: on Linux these are links into `/proc/self/fd`, missing where `/proc` is not mounted (X28's check without `/proc`). bash 5.2.21 does not emulate them then either (it emulates them only where it was built without them; checked 2026-11-08: `echo x > /dev/stderr` with `/proc` hidden fails in all three shells, bash with status 1, dash and ours with 2). | 12 | Yes: `/proc` mounted, or not. |
| `heredoc` | **Held.** A here-document whose body has expansions, or 4,096 bytes or more: bash may then write it to a temporary file (in `$TMPDIR`, else `/tmp`). Smaller literal bodies go through a pipe in all three (checked: bash 5.2 and dash with `TMPDIR=/nonexistent`, bodies of 100, 5,000 and 70,000 bytes, all fine; ours always uses a pipe, `Proc::ShellSpawn`, redirections), so they are strict. | 3 | Yes: `TMPDIR` (the run sets it to the run's directory). |
| `locale` | A bracket expression or non-ASCII text in a pattern, `test`'s `<` and `>`, `printf`'s `%f %e %g %a %q` and its `'` flag: the locale as in the run (`LANG=C`, `LC_ALL=C`). | 15 | Yes: a second run with another locale (`C.UTF-8`) tries the other case for these samples alone. |
| `echo` | `echo` with a backslash, a first word starting with `-`, or words from expansions: `POSIXLY_CORRECT` unset. It changes coreutils `echo` (which ours runs; rule "the program beats the shells' difference") but not dash's or bash's builtin. It is a switch of two values, so one more run of these samples with `POSIXLY_CORRECT=1` settles them: their runs double, nobody else's. (`POSIXLY_CORRECT` also changes other GNU programs, such as `ls dir -l`, but the same way in all three shells: that is within `program`.) | 110 | Yes. |
| `path-system` | A program is given a path under `/etc /usr /bin /sbin /lib* /opt /boot`: read-only for the run's unprivileged user, so the runs cannot change it, and the same in each run unless the system itself changes. | 429 | Nothing needed (a read-only snapshot would make it certain). |
| `path-var` | … under `/var` (not `/var/tmp`): logs, spool, web roots; they change with time, mostly closed to the run's user. | 137 | Yes: a private mount over `/var` for each run (`unshare -m`). |
| `path-home` | … under `/home` or `/root`: absent or closed to the run's user. | 330 | Yes: a private mount. |
| `path-dev` | … a device under `/dev` (disks, ttys, `/dev/input/mice`), not `/dev/null`: absent or closed to the run's user, so every run fails alike. | 427 | Yes: a private `/dev`. |
| `path-mnt` | … under `/mnt`, `/media`, `/srv`: empty mount points or absent. | 69 | Yes: a private mount. |
| `path-absent` | … under a top-level directory a Linux system does not have (`/path/to/…`, `/some/dir`, macOS's `/Users`; also words like a `sed` script `/re/d` or a Windows switch `/v`, taken for paths): nothing is there, so every run fails alike. | 1,047 | Yes: make it in a private mount namespace, if the sample should be exercised with something there. |
| `passthrough` | Every value the text takes from the environment (a variable read before the text sets it, an argument, a program's output, the working directory, a glob's matches) only passes through the shell: it goes quoted into a program's words, into an assignment, a `case` word or a here-document, or a program's output goes on without the shell reading it; a program's status only chooses between branches whose commands are all alike in the three; `pwd`; bash's `history`, `fc -l`, `bind`, `help` in a non-interactive shell (no file options). The three hand such a value on unchanged, whatever it is. Not passthrough (the sample stays undecided): the value going into another builtin (`set`, `export`, `kill`, `eval`, …), arithmetic, `${x:?}`, `set -u`, `set -e`, the shells' own variables (`PATH`, `PWD`, `SHLVL`, `RANDOM`, …), a value the shell makes itself (`$$`, `$SECONDS`). | 2,140 | Probed: [`tools/large-subset-valueprobe.pl`](tools/large-subset-valueprobe.pl) (`make probe-values`), 22 odd values (NUL bytes, trailing newlines, invalid UTF-8, a leading `-`, 100,000 bytes) through 11 forms: the three alike (2026-11-12). |
| `splitglob` | A value from the environment unquoted in a program's words or a `for` list, or a pattern of the text there: the three split it at `IFS` and match it against the files alike. Known exceptions, each a difference of dash and bash: `[^…]` (dash takes `^` literally; not legalized, [`TODO`](../../TODO) A13; a pattern of the text with `[^` is not taken), a pattern for dot names such as `.*` (dash also gives `.` and `..`; rule E, G2: ours as bash), `//` after a pattern component (bash collapses it; ours as dash, A5). | 1,476 | Probed: the same tool, 45 values in 5 forms with files there: alike but for the three exceptions (the probe also found X52, fixed). |

The irreducible part of strict, assumed everywhere: the shell started as in the run (its options, and the variables that steer the shell itself, such as `SHELLOPTS` and the locale), descriptors 0–2 open, no signal from outside, enough memory, processes and disk, and the programs the subset runs in place of builtins (`echo`, `printf`, `test`, `[`, `true`, `false`) present as coreutils (X21; since post-0.09 they run inside Perl by default, decision IP1, so this one no longer depends on the system, apart from X21's differences). Before that, like `devfd` and the `path-` codes, it was a POSIX system's: on Windows (`Proc::ShellSpawn` there is open) it failed, and every sample that runs one of these programs would have to be judged again (142 of the strict ones do).  Closed (the user, 2026-11-10, SP1): since IP1 these programs run the same on every platform, so strict needs no code for them; checked under Wine by [`t/programs.t`](../../t/programs.t) for the programs alone, not on these samples (the library under Wine is `TODO`). `devnull` and `heredoc` are known to hold on Windows too, so they form the level "held": an assumption is held when it is checked to hold in every environment we test; the level can grow as more are checked.

**Table 2: the codes of "undecided".** "Decides": undecided samples that have it / that have no other undecided code.

| Code | What the comparison may depend on | Decides | Under our control |
|---|---|---|---|
| `files` | What the directory holds: a pattern in a word (pathname expansion), a redirection to or from a file (`2>errfile` included: whether it exists, its type, contents, permissions), `test`'s file operators, `.`, a command named by a relative path (`./script`). | 1,464 / 1,202 | Yes: fixtures (the files the samples name). |
| `directory` | The working directory or `HOME`: `cd`, `pwd`. | 147 / 48 | Yes: chosen directories. |
| `vars` | A variable read before the text sets it: from the environment, or unset. | 401 / 164 | Yes: chosen values. |
| `unquoted` | An unquoted expansion whose value is not known here to be free of pattern characters (it is split and matched against files); unquoted `$( )`. | 327 / 10 | Yes: chosen values and fixtures. |
| `args` | Positional parameters at the top level with no `set` before them: none were given. | 112 / 41 | Yes: chosen arguments. |
| `start` | `$0`, `$-`: how the shell was started. | 43 / 5 | Partly: the runner names the shells alike (`sh`). |
| `status` | `$?` at the start of a function's body or of a trap action: the status of a command the text does not show. | 4 / 0 | No. |
| `prog-output` | The shell takes a program's output: in `$( )`, or through a pipe into `read`, a loop or a function. | 509 / 40 | Only with stand-ins of chosen output. |
| `prog-status` | A program's status decides: `&&`, `||`, `!`, the condition of `if`, `while`, `until`; `$?` after it (also in a loop, from the round before); a command after it under `set -e`. | 35 / 1 | Only with stand-ins of chosen status. |
| `race` | The order of events: a command in the background (`&`), `xargs -P`, a compound command or a function writing into a pipe (if the reader stops early, its later commands die or not, by timing). | 86 / 53 | No. |
| `pid` | `$$`, `$!`, `$PPID`; `kill`, `wait`, `jobs`, `fg`, `bg`, `disown` with operands. | 103 / 54 | No. |
| `time` | `times`, `$SECONDS`, bash's `time`, `printf '%(…)T'`; the programs `date`, `stat`, `ls -l` (`-t`, `-c`, `-u`: each run's copy of the directory has new file times). | 223 / 100 | No (stand-ins). |
| `random` | The programs `shuf`, `mktemp`, `uuidgen`, `sort -R`. | 72 / 20 | No (stand-ins). |
| `input` | `read` from the run's standard input. | 56 / 36 | Yes: chosen input. |
| `listing` | `env` or `printenv` alone (they print the environment the shell passes, which differs between the shells); `export`, `readonly` alone. | 28 / 21 | No: bash adds its own variables. |
| `lookup` | `command -v`, `command -V`, `type`, `hash`: what is installed. | 6 / 6 | Yes: a fixed `PATH`. |
| `limits` | `ulimit`; `umask` alone (the inherited mask). | 6 / 6 | Yes: the runner sets them. |
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

**Table 3: held and almost strict samples by the exact set of assumptions they need.** Each such sample is unaffected if all of its assumptions hold; it is counted once, under the whole set.

| Assumptions | Samples |
|---|---|
| `program` | 28,322 |
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
| all | 36,444 |

By the rows of section 1 (LV1): the sets without `passthrough` are held (2) and almost strict (34,302); with `passthrough` and not `splitglob`, "with values passed on unchanged, not in preceding rows" (664); with `splitglob` (always beside `passthrough`), "with values passed on split, not in preceding rows" (1,476).

Note: 191 samples need a non-empty set of assumptions none of which is `program`: `passthrough` 98, `echo` 56, `locale` 10, `pipeline` 10, `passthrough splitglob` 9, `devnull` 2, `echo passthrough splitglob` 2, `devnull locale` 1, `echo passthrough` 1, `locale passthrough` 1, `locale passthrough splitglob` 1. Those without `passthrough` are settled for the most part by one more run with `POSIXLY_CORRECT=1` or another locale. 28,322 samples need only `program`.

## 4. How the levels are found

**The atomic blocks.** A block is a simple command (with its settings and redirections), the word list of a `for`, the word and the patterns of a `case`, the redirections of a compound command; a command inside `$( )` is a block of its own. Each block carries its place: where its output goes (a pipe, and whether the next element reads it; `$( )`; a file), where its input comes from, whether its status decides something, whether it runs in the background, in a function's body or in a trap action. The 40,410 samples make 52,519 blocks, 46,094 distinct with their place. A sample's level is the lowest of its blocks', after the compositions below.

**Strict forms**: builtins with words that are literal or come from variables set earlier in the text (`x=1; echo "$x"`); `echo` without backslashes or a leading `-`; `printf` with a literal format and no locale-bound conversion; `test` without file operators and without unquoted expansions; assignments, `export`, `readonly`, `local`, `unset`, `set` (options, operands), `shift` after `set`; functions called after their definition; `alias`; `eval` and `trap` of literal text (parsed and judged in turn); loops and conditions over these; `$( )` of these; descriptor copies among 0–2; small literal here-documents.

**Compositions** (a part's effect on others):
- `$?` takes the status of what ran just before: if that was a program (or a function whose status may be a program's), its status decides (`prog-status` on it). In a loop, `$?` may be the status of any command of the loop (from the round before), so all of them count. At the start of a function's body or a trap action, what ran before is not in the text: `status`. `x=1; echo $?` is strict; `foo; echo $?` is not.
- `set -e` (or `set -o errexit`), until `set +e`: from there on every command's status decides whether the rest runs, so every program after it counts as `prog-status`; so do the programs in function bodies and trap actions anywhere in a text that sets `-e`. The text's last command is exempt: after it there is nothing left to stop. `set -e` alone, or before builtins only, is strict.
- A name is a call of a function only once the walk has passed the function's definition; before that it may be a program (`if ! mycmd; then mycmd() { …; }; fi`).
- A pipe: if the shell itself reads (into `read`, a loop, a function) what a program writes, `prog-output`; a compound command or a function writing into a pipe is a `race`.
- Variables: a read counts as set only if an assignment comes earlier in the text (one in a function's body counts as early; a read in a function's body counts as late, since it runs when called). An unquoted read is strict only if every value assigned to the variable is a literal without pattern characters.

## 5. Results by code

Tables 1–3 above give the counts. A check against the run ([`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv)): take the 159 samples it lists with a difference beyond the messages (in the run of post-0.09: ours differs from both shells: 3; the shells differ and ours agrees with neither: 156; post4-0.04's list had 177, with the same outcome). If the levels are right, a strict or almost strict one among them cannot differ because of the environment, so it must differ for some other reason. 10 of them are strict or almost strict, and each differs by how the shells are made, the same in any environment: the wording of a "not found" message that `2>&1` sends into the output or a file (8, such as `someCommand 2>&1 | tee someFile`), `kill -l`, and `printf -v` (Q2).

## 6. How to remake it

From the distribution's directory, with dash 0.5.12 and bash 5.2.21 (any shells will do for the levels, which only parse; they matter for which samples are accepted):

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
perl -Ilib $T/large-subset-blocks.pl -e doc/large-subset/large-subset-provenance.tsv -s levels.tsv -o blocks.jsonl samples.jsonl samples.tsv
```

`samples.tsv` must say 40,410 samples accepted (its column `large`). `-s` writes one line per sample with its level, codes and text; `-o` every distinct block with its level, codes and all its samples; `-batch` adds the check of section 8 (about 2 minutes more). With the parser of post-0.08 the result is the file in the distribution; a parser change can change it (the samples accepted, and the trees).

## 7. How it was checked, and what was not

- 84 forms written by hand to probe each rule (`echo "$x"` with and without `x=1` before, `2>errfile`, `x=$(ls)`, `ls | while read`, `f() { echo $1; }; f a` and `f "$x"`, `eval 'echo hi'`, `exec 3>&1; echo x >&3`, `foo; echo $?`, `set -e; foo; echo hi`, a path of each class, …): each came out as the rules say.
- Every strict sample, read one by one. The reading found and fixed: a name called before its function's definition (`if ! mycmd --version; then mycmd() { true; }; fi`), `printf -vTODAY '%(%Y)T'` (the attached `-v` hid the format); `set -m` added.
- 150 random almost strict samples among those with more than a lone command, 60 random undecided ones, and samples of each path class: the codes were right; `set +e` had been taken for `set -e` (fixed). The path classes take any word starting with `/` (or `=/`) for a path, so a `sed` script `/re/d` or a Windows switch `/v` counts as `path-absent`.
- Against the run: section 5. This check also found `sort -R` and `xargs -P`, which break `program` (now `random`, `race`).

Not checked: nothing was run again in another environment. Undecided is conservative on purpose: a loop writing into `sort` counts as a `race`; a call inside a function's body to a function defined later counts as a program. `program` is an assumption about programs, and is known to fail for some that are not on the short list (section 3, table 1).

The first version of the tool (the same day) did the opposite: it tagged the dependences it recognised and called the rest unaffected (81.4 %). Its passes were not definite (reading found 1 % wrong, and whole kinds it did not look at: `$?`, `set -e`, `2>errfile`, the text of `eval` and `trap`), so it could not narrow the search for samples that matter; the levels replace it.

## 8. All the samples in one batch

One by one, the 40,410 samples parse in about 4 s. Joined into one text, a line apart, they make one script, and in a script a command can change how the text after it parses. 198 samples do (5 for two reasons): 90 define a function (a command of that name anywhere in the text then calls it: `cd` becomes a function call everywhere), 79 define or remove an alias (it applies to the text after it: `alias rm="rm --interactive"` turns every later `rm` into `rm --interactive`), 18 change aliases in a way known only when they run (P1: the parser leaves the rest of the text to run time; the first, `unalias run-help && autoload run-help`, cut off three fifths of the batch), 15 end in a backslash (it joins the next line), 1 is `exec command -with -flags` (nothing may follow an `exec`). With these 198 set aside, the other 40,212 joined (1,497,623 characters, 41,412 lines) are accepted, give the same 40,626 top-level commands as one by one, and each sample's part of the joined tree is its own tree (compared without the line numbers that `$LINENO` anywhere in a text adds to every command), but for 2: `x=$(( $? > 0 ))` and `echo $(( ((1+1)) ))` keep the blank before `))` in the arithmetic text where the large grammar parses them (the joined text needs it), and lose it where the base grammar does (alone). Same value: blanks do not matter in arithmetic. The joined parse takes 89 to 105 s; without the one sample that uses `$LINENO`, 8.4 s (the large grammar parses the text a second time after the base grammar gives up on it). With `$LINENO`, each command's line is counted from the start of the text, so the time grows with the square of the length: known issue X30.

## 9. What can be done about a code, and the run's environment varied (post-0.09, 2026-11-08; run again post-0.11, 2026-11-13)

**The six kinds of workaround** ([`TODO`](../../TODO), A1; the column "Control" of section 3 says which fits a code):

| Kind | What it does | Codes it fits | State |
|---|---|---|---|
| 1. Nothing | keep the assumption, or leave the sample undecided | any | — |
| 2. A second run, the other case | run the samples again with a switch of the environment turned the other way; a sample whose comparison comes out the same both ways does not depend on that switch | `echo` (`POSIXLY_CORRECT=1`), `locale` (`C.UTF-8`), `pipeline` (SIGPIPE ignored), `devfd` (`/proc` hidden) | done: `-env posix`, `utf8`, `sigpipe`, `noproc`; results below |
| 3. Fixtures | what the shells see outside the run's directory made fresh or fixed for each run; inside it, the files the samples name, and their times | `path-tmp` (a fresh tmpfs), `path-random` (a fixed file), `path-var`, `path-home`, `path-mnt` (empty), `path-dev` (a private `/dev`); `time` (fixed file times, for `ls -l`, `stat`); `files`, `directory`, `unquoted` (the run's directory) | done for the `path-` codes: `-env tmp`, `random`, `private`, `dev`; for `time`: `-env mtime`; not started for the files of the run's directory |
| 4. Chosen values | variables, arguments, input, `HOME`, `PATH`, limits, descriptors set for the run (or several sets, one run each) | `vars`, `args`, `input`, `tilde`, `lookup`, `limits`, `fd`, `name`, `test-ops`, `start` | not started |
| 5. Stand-ins for programs | programs replaced by ones of chosen output and status, the same in every run (the recorders are such stand-ins for status 0 and no output) | `program`, `prog-output`, `prog-status`, `time`, `random` | done for `prog-status` and `prog-output`: `-env fail`, `output`, their answer taken from the environment (below) |
| 6. Leave the samples out | of the comparison's counts | those no run can control: `race`, `pid`, `path-proc`, `path-root`, `listing`, `status` | not started |

**How.** [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-env V,…` changes the environment of every run of the three shells; the variants that mount do it as root in a mount namespace of each run's own, before dropping to the run's user (the variants: the script's `%ENVV`; a probe of eight samples checked that each takes effect in all three shells). [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl) `-b BASE VARIANT` puts each sample's class in a base run beside its class in the variant's run, and lists every sample whose class or result changed. Each variant ran on the samples whose code in [`large-subset-provenance.tsv`](large-subset-provenance.tsv) it is for (as an assumption of an almost strict sample, or anywhere in an undecided one's), against a base run of the same 7,003 samples; a second base run measured the noise (what changes between two runs of the same environment: times, chance, process IDs). From the distribution's directory, as root, after `make`, with `samples.jsonl` and `samples.tsv` of section 6 (IDS-v: the IDs of the variant's code, one per line):

```sh
T=doc/large-subset/tools
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -only @IDS-all samples.jsonl samples.tsv base
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -only @IDS-all samples.jsonl samples.tsv base2
unshare -n perl $T/large-subset-runcompare.pl -base /runcompare -env tmp -only @IDS-path-tmp samples.jsonl samples.tsv v-tmp
perl $T/large-subset-runreport.pl -b base v-tmp
```

About 6 minutes per base run with 4 workers, 8 minutes for all variants.

The stand-ins' answers and the fixture's time are taken from the runner's own environment, with defaults: `STANDIN_STATUS` (`-env fail`; default 1: every program the run only logs, that is not one of the plain text tools that really run, exits with it), `STANDIN_OUTPUT` (`-env output`; default `one  two`, `*`, an empty line and `last` without a newline: it tests splitting, patterns, empty lines and a last line without its newline), `FIXTURE_MTIME` (`-env mtime`; seconds since 1970, default 1577836800, 2020-01-01: the access and modification times of every file and directory of the run's copy). So `STANDIN_STATUS=2 perl …/large-subset-runcompare.pl -env fail …` tries status 2; the values used go to `OUTDIR/env.txt`. These three ran against base runs of their own (the 1,248 samples with `prog-status`, `prog-output` or `time`, twice). Every changed sample: [`tools/large-subset-env-variants.tsv`](tools/large-subset-env-variants.tsv) (with a column saying whether it changed between the two base runs too).

**Results.** "Class changed": the sample's class (section 7 of [`large-subset-state.md`](large-subset-state.md)) in the variant's run is not the one in the base run; "other result": the class stayed, but a status, output, call, file or message changed in some shell. Changes that also happen between the two base runs are counted apart ("+n noisy").

| Variant | Code | Samples | Class changed | Other result | What changed |
|---|---|---|---|---|---|
| `posix` | `echo` | 443 | 31 | 2 (+14 noisy) | 29 from "ours as bash" to "ours as dash": with `POSIXLY_CORRECT` set, ours' `echo` (coreutils' meaning, inside Perl since IP1) interprets backslashes and takes no options, as dash's builtin does; bash's builtin does neither. 2 from "same" to **ours differs**: `echo '\x4a'`, `echo '\xat'`: ours then interprets `\x`, neither shell does. |
| `utf8` | `locale` | 25 | 1 | 2 | `printf "€ %.2f\n" 123.4`: in `C` all three print `€`; in `C.UTF-8` bash and ours print `€`, dash's `printf` has no `\u` ("same" to "ours as bash"). |
| `sigpipe` | `pipeline` | 5,742 | 74 (+12 noisy) | 133 (+155 noisy) | Beyond the messages 9: 6 timeouts, an endless writer (`yes \| nl \| sed 100q`, `cat /dev/urandom \| … \| head -1`) no longer dies when its reader stops; `ls -a \| tee output.file` (a race); 2 by another sample's `/tmp/size.log` (the variants run without `-env tmp`). The rest are messages: 49 to "as neither", where ours' `echo` writing into a pipe whose reader is gone says `echo: write error: Broken pipe` (as coreutils), dash's builtin `I/O error` or nothing; and programs' "write error: Broken pipe" that appear or not by timing. |
| `noproc` | `devfd` | 13 | 3 | 1 | `paste /dev/stdin`, `mv … < /dev/stdin` and `tee /dev/stderr` fail in all three (the redirection's status: ours as dash, rule A5). bash does not emulate `/dev/stdin` then (table 1). |
| `tmp` | `path-tmp` | 207 | 7 | 3 (+6 noisy) | All 7 to "same", from "ours as bash" (5) or "as dash" (2): `mkdir /tmp/foo` and redirections into `/tmp`, where the second and third shell found the first one's file, or another sample's. |
| `random` | `path-random` | 25 | 16 (all noisy) | 0 | 13 from "ours as neither" to "same", 2 from "timeout" to "same", 1 from "ours differs" to "same" (`grep -m1 -ao '[0-9]' /dev/urandom`): the same bytes in every run, and `cat /dev/urandom` ends. All 25 now agree. |
| `private` | `path-home`, `path-mnt`, `path-var` | 573 | 1 | 4 (+5 noisy) | None from the variant: the change is in the messages of a pipeline (`find /home/jassi/ … \| xargs ls -lrt \| awk …`). |
| `dev` | `path-dev` | 444 | 0 | 0 | None. |
| `fail` | `prog-status` | 113 | 3 | 23 | Nothing beyond the messages: with every logged program failing, the three shells still agree. 2 from "messages as dash's" to "same" (the command whose message differed is no longer reached), 1 to "timeout" in all three (`until systemctl is-active -q nginx; do …; done` never ends). |
| `output` | `prog-output` | 1,014 | 63 | 401 (+13 noisy) | 47 beyond the messages, none where ours differs from both shells. 22 `cd $(…)` given several words: dash goes to the first, bash fails ("too many arguments", status 1), and ours as bash since X54 ([`TODO`](../../TODO) A13: not legalized). 13 `kill $(…)` given words that are no process IDs: dash status 2, bash and the program 1 (as in the atomic calls, [`large-subset-state.md`](large-subset-state.md), section 7). 6 `cd "$(…)"` and the like to a name that does not exist: dash 2, bash 1, ours as dash (A5). 2 `unset $(…)` given words that are not names: dash fails ("bad variable name", status 2), bash takes them for function names (status 0), ours as dash (X35, fixed). 1 `[ $? == 0 ]`, 1 `test $(…) == …`: ours' `test` takes `==`, as bash. 1 `g=$(md5sum $f) > $f.md5` in a loop: dash makes the file before running the substitution, bash after (ours as dash). 1 `yes … | grep … | { head -n 1; head -n 1; }`: two readers of one pipe (a race). The other 16 changed in the messages (one of them from "ours as bash" to messages only). |
| `mtime` | `time` | 223 | 0 (+2 noisy) | 25 (+29 noisy) | The point is repeatability: between two base runs 33 of these samples changed some result. What still changes: the shells' own clocks (`time`, `times`, `printf '%(…)T'`), and times of what is not the run's copy (`ls -ld /tmp`, `ls -lR /`, `/proc`). |

Noise (base against base2, 7,003 samples): 212 changed some result, 17 their class (in the runs of post-0.09: 122 and 40; not traced sample by sample); the stand-ins' base runs (1,248 samples): 42 and 1.

**Found.**
- `/tmp` is shared not only by the three shells of one sample but by all samples and workers of a run: `NB:3439` (`… >> /tmp/size.log`) made the file as one worker's user, and `NB:3440`, run later by another, failed in all three shells with "Permission denied". The run of [`large-subset-state.md`](large-subset-state.md), section 7, had this too; `-env tmp` removes it.
- With `POSIXLY_CORRECT=1` in the environment, the subset's `echo` (the program, rule "the program beats the shells' difference") changes its meaning: it sides with dash for backslashes and `-e`, and differs from both shells for `\x`. Decided (the user, 2026-11-09, EC1): accepted, and a switch added: `PROC_SHELLSPAWN_ECHO=dash` or `bash` makes our `echo` that shell's builtin, which `POSIXLY_CORRECT` does not change (default `coreutils`, as before); [`t/dash.t`](../../t/dash.t) runs ours with `dash` (section 7 of [`large-subset-state.md`](large-subset-state.md), table of section 1).
- Known issue X33 ([`pspawn-known-issues.md`](../pspawn-known-issues.md); ours, fixed): the runner made `/dev/stdout` and `/dev/stderr` unwritable for the run's user.
- Table 1 said bash emulates `/dev/stdin` and the like where `/proc` is missing; bash 5.2.21 does not (corrected above).
- `private` and `dev` changed nothing: in this container those places are absent, empty or closed to the run's user, as the assumptions say. Checked in this container only.
- Run again post-0.11 (2026-11-13, `make corpus-env-variants`, with the code of post-0.11 and the runner waiting for background jobs): [`tools/large-subset-ids.pl`](tools/large-subset-ids.pl) chose the samples of a variant by their codes, but did not read the codes inside `passthrough(…)` that step 3 gave the pass and split samples, so `fail` and `output` ran first on 35 and 511 samples; fixed, and the 578 missing samples ran too.

**Not done.** The variants ran one at a time, each only on its own code's samples, in one container; nothing was combined (`-env tmp,random,mtime` for the whole run is the obvious next step). The stand-ins tried one answer each (status 1; one output text), the same for every program the run only logs. The levels of sections 1–3 are not changed by these runs: they come from the parse trees alone; the runs are footnotes to the totals of section 1 (the user, 2026-11-08, EV1). Kinds 3 (inside the run's directory) to 6 are not started.



## 10. Step 2: exact dependences and example setups (post-0.11, 2026-11-10; run again 2026-11-13)

The user's four steps (2026-11-10; [`TODO`](../../TODO), A1): (1) find the samples the environment cannot affect (sections 1–4); (2) for the others, describe exactly how they are affected, and run them in a few example environments where only one command of a snippet is affected; (3) recognize more such samples by simple programmatic tests; (4) leave the rest to deep AI analysis. Section 9 did step 2 for the codes one switch of the whole environment covers. This section does it for the codes inside the run: `files`, `vars`, `input`, `args`, `directory`, `tilde`, and, where they come with a variable or argument of the same command, `name`, `test-ops`, `eval` and `unquoted`.

**Exactly what.** [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) `-d DEPS.jsonl` records, for every undecided sample, what each undecided code comes from and in which block (command): for `files` the glob pattern, or the file a redirection reads (`<`, `<>`) or writes (`>`, `>>`, `>|`), a `test` operator's operand, the file `.` reads, a relative program name (`./run.sh`); for `vars` the variable read before the text sets it; for `input` a `read` from the run's input; for `args` the positional parameter (`$1`, `$@`, `$#`, …); for `directory` the operand of `cd` (none: `HOME`); for `tilde` the word (`~` alone depends on `HOME` only, `~user` on the user database); with a flag saying whether the name is all the text says (no expansion in it), and, by block, the codes no such name accounts for. The levels and [`large-subset-provenance.tsv`](large-subset-provenance.tsv) do not change (regenerated: identical).

**The setups.** [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl) gives each sample whose undecided codes are all of these example setups, from three states per dependence (those of the same name, a file, a variable, `HOME`, the arguments, the input, move together):

| Dependence | Base run | State 1 | State 2 | State 3 |
|---|---|---|---|---|
| a file read (`<`, `<>`, `test -e` and the like) | absent (or the fixture's file) | a file of two lines (absent, if the fixture has it) | an empty file | a directory |
| a file `.` reads | absent | a file `echo sourced` | an empty file | a directory |
| a file written (`>`, `>>`, `>|`) | absent | a file of two lines | a directory | a read-only file |
| a program `./name` | absent | an executable script that prints its arguments | the same, not executable | a directory |
| a glob pattern | the fixture's matches | none (the fixture's matches removed) | one new matching file | two new matching files |
| a variable | unset | empty | `x1` | `two  words *` |
| standard input | `/dev/null` | two lines | a line without its newline | `a b\ c` |
| positional parameters | none | one, empty | `x1` | `two  words`, `*`, `last` |
| `cd NAME` | absent | a directory | a file | a directory with mode 000 |
| `HOME` (`~`, `cd` alone) | the run's home directory | `/nonexistent/home` | empty | unset |

Setups 1, 2, 3 put every dependence in state 1, 2, 3. A sample with two dependences gets every combination, 3 × 3 = 9 setups (`-full 2`); with more, after setups 1–3, each dependence alone in each state, the others as in the base run, 3 + 3m setups (`-one`): the user, 2026-11-10, "3^m tries" as far as they add at most 25 % (every combination for all would add 269 %, for up to three dependences 28 %, for up to two 18 %), and "3+3*m where 3^m is too large". So 2,594 samples got 3 setups, 267 got 9, 34 got 12, 4 got 15, three got 18, 21 and 30: 10,722 setups in all (run again post-0.11, 2026-11-13, `make corpus-step2`; before: 2,593 got 3, 10,719 in all).

Of the 3,262 samples whose undecided codes are all of these, 360 were left out: 104 whose pattern is absolute (outside the run's directory), 100 that read a variable the run sets itself (`HOME`, `PATH`, `USER`, `PWD`, …), 88 with a name from an expansion, 25 `cd` to an absolute path, `.` or `..`, 16 patterns with no usable example name, 5 `~user`, 2 `cd -`, 19 with `..` or an absolute name, 1 naming the run's directory. 2,902 were taken (2,798 where one block carries the undecided codes, 104 where several do; before post-0.11's run again: 3,245, 344 left out, 3 of them with `..` or an absolute name, 2,901 taken: the dependences `-d` writes changed with step 3, section 12, "Not checked"): the **partially decided** (section 11). [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-setup PREFIX-K.jsonl` applies setup K before each run of the three shells (files made or removed, variables set or unset, standard input, arguments after the text, with `$0` as each shell has it without them, so that the messages keep their prefix; [`t/try.pl`](../../t/try.pl) takes `$0` and arguments after the text, as `sh -c`). All runs used `-env tmp,random,mtime`; the runs counted here are of post-0.11's code (2026-11-13: X39 to X55 fixed; the runner waiting for background jobs, A18; earlier rounds, which found the bugs below, are not counted).

**Results.** Per sample (the class of section 7 of [`large-subset-state.md`](large-subset-state.md)): *unchanged*, the same class in every setup as in the base run; *changed*, another class in some setup, ours still on the side of dash, bash or both; *neither*, in some setup a class where ours agrees with neither shell, or a timeout, where the base run had another. Record per sample, written by [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) `-record`: [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv).

| Dependence | Samples | Unchanged | Changed | Neither |
|---|---|---|---|---|
| files | 1,814 | 717 | 1,095 | 2 |
| a variable | 640 | 595 | 44 | 1 |
| `~` (`HOME`) | 194 | 36 | 158 | 0 |
| positional parameters | 126 | 112 | 13 | 1 |
| two kinds or more | 80 | 53 | 27 | 0 |
| standard input | 36 | 35 | 1 | 0 |
| `cd` | 12 | 2 | 10 | 0 |
| all (of them several blocks) | 2,902 (104) | 1,550 (75) | 1,348 (29) | 4 (0) |

The runs of post-0.11 (2026-11-13), with the code of post-0.11 and the runner waiting for background jobs (A18); before (2026-11-11): all 2,901 (103), unchanged 1,547 (74), changed 1,350 (29), neither 4, the same 4.

- *Changed* is nearly all known differences coming and going with the setup: a redirection that fails (into a directory that does not exist, as `>path/to/output.png`, into a directory, into a read-only file) fails with status 2 in dash and ours (rule A5) and 1 in bash, so such a sample is `=dash` while the redirection fails and `same` or `msg=dash` when it succeeds; `~` with `HOME` changed (section 11: G16, and a dash bug).
- *Neither*, the 4: `rev $filename | …` given `two  words *` (all three time out); `ls > foo 2> bar > baz` and `test 2>&1 > cow` with `baz`, `cow` a directory (A5, the messages in a file or on standard output with each shell's prefix); `printf '%q' "$1"` (the program, decided).

**Found.** Bugs of ours, none visible in the base run, each needing a file or a value it does not have ([`pspawn-known-issues.md`](../pspawn-known-issues.md)), all fixed on this branch: X39 (`.` of an empty file or a directory: Perl died), X40 (`[[:digit:]]` never matched in pathname expansion), X41 (`"${v#$x}"`: `$x`'s value taken literally; the parser, the figures measured again: unchanged), X42 and X43 (`exit`, `return` with `x1`; `set -o` with no such option: decision NV1, as the shells), X44 (`cd` into a directory that may not be searched succeeded), X45 (`cd` with `HOME` empty failed); and, by the match report of section 11, X46 (`shift` with such an operand) and X47 (the message of a command that does not start went to the shell's standard error, not the command's). A **❰BUG❱ of dash**: with `HOME` empty, `~` is dropped (section 11). The tool's own: a pattern ending in `/` needs directories; with arguments, `$0` must stay each shell's own (both fixed before the runs counted here).

**Not done.** Step 2 for the codes left (`start`, `lookup`, `limits`, `fd`, `interactive`; `unquoted`, `name`, `test-ops`, `eval` where no variable or argument of the same command brings them), for absolute patterns and the run's own variables; every combination for three dependences or more; steps 3 and 4.

```sh
X=doc/large-subset/tools
perl -Ilib $X/large-subset-blocks.pl -d deps.jsonl samples.jsonl samples.tsv > /dev/null       # 10 s
perl -Ilib $X/large-subset-setups.pl -all -full 2 -one deps.jsonl setup   # setup-1.jsonl ... setup-30.jsonl, setup-samples.tsv
cut -f1 setup-samples.tsv | grep -v '^#' > setup.ids
for r in base base2; do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -only @setup.ids samples.jsonl samples.tsv $r; done
for k in $(seq 1 30); do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -setup setup-$k.jsonl samples.jsonl samples.tsv s$k; done
```

About 35 minutes with 4 workers; the record and the match: section 11.

## 11. The match across environments (post-0.11, 2026-11-11; run again 2026-11-13, with step 3's environments)

Every snippet the parser accepts (a script, or a part of one, stored in our library) was run by dash, `bash --posix` and ours: in one environment, the base run, or in several: the samples of step 2 in its setups (section 10), and those of step 3's two classes in theirs (section 12: each its own base run and setups). A snippet counts once, over every environment it ran in: its box comes from its classes in all of them together, the base run, step 2's setups and step 3's alike, as before for the base run and step 2's setups (the user, 2026-11-13). Tree 1 sorts the snippets by whether dash and bash agree and with which of them ours sides; tree 2 splits each box by whether a ruling of the user legalizes ours' difference. A *command* is one call of `echo`, `printf`, `test`, `[`, `kill` or `pwd` inside a snippet (below). Messages count nowhere (at the end: how it was measured).

**Tree 1: the match.**

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,603  ours = dash = bash, in every environment¹
├──     14  timeout                                                   0         12     2
├──      6  dash = bash; ours ≠ them                                  2          3     1
└──  1,787  dash ≠ bash, in some or all environments
     ├── 1,261  ours = dash                                          14      1,198    49
     ├──   350  ours = bash                                         110        235     5
     ├──   127  ours ≠ dash, ours ≠ bash                              8        102    17
     └──    49  depends on the environment                            1         45     3
                ├── 40  ours = dash in some, = bash in others         0         38     2
                ├── 3  ours = dash in some, ≠ both in others          0          2     1
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                                                              ─────────  ─────────  ────
                                                                    135      1,595    77
```

¹ Their commands were not recorded: nothing in them needs a reason.

- **≠coreutil**: in every environment where ours ≠ a shell, the snippet runs one of the six commands with arguments for which coreutils ≠ that shell's builtin (and ours = coreutils).
- **¬coreutil**: the snippet runs none of the six commands.
- **rest**: it runs some, but not so.

**Tree 2: the same, each box split by legalization.** A snippet with several reasons in different environments counts in the lowest of: legalized, awaiting a decision, chance, not legalized.

```
40,410  all snippets the parser accepts; each run by dash, bash and ours
│
│                                                             ≠coreutil  ¬coreutil  rest
├── 38,603  ours = dash = bash, in every environment¹
├──     14  timeout                                                   0         12     2
├──      6  dash = bash; ours ≠ them                                  2          3     1
│           ├── 3  legalized by rulings²                              2          1     0
│           ├── 1  chance                                             0          1     0
│           └── 2  not legalized (2 already in TODO)                  0          1     1
└──  1,787  dash ≠ bash, in some or all environments
     ├── 1,261  ours = dash                                          14      1,198    49
     │          ├── 1,242  legalized by rulings³                     14      1,181    47
     │          └──    19  ~ with HOME empty: awaiting A12            0         17     2
     ├──   350  ours = bash                                         110        235     5
     │          ├── 276  legalized by rulings⁴                      110        166     0
     │          ├──  64  ~ with HOME empty: awaiting A12              0         64     0
     │          ├──   1  chance                                       0          0     1
     │          └──   9  not legalized                                0          5     4
     ├──   127  ours ≠ dash, ours ≠ bash                              8        102    17
     │          ├── 88  legalized by rulings⁵                         8         66    14
     │          ├──  1  ~ with HOME empty: awaiting A12               0          1     0
     │          ├── 36  chance                                        0         33     3
     │          └──  2  not legalized (2 already in TODO)             0          2     0
     └──    49  depends on the environment                            1         45     3
                ├── 40  ours = dash in some, = bash in others         0         38     2
                │      ├──  5  legalized by rulings⁶                  0          3     2
                │      ├──  2  ~ with HOME empty: awaiting A12        0          2     0
                │      ├──  1  chance                                 0          1     0
                │      └── 32  not legalized                          0         32     0
                ├── 3  ours = dash in some, ≠ both in others          0          2     1
                │      ├── 2  ~ with HOME empty: awaiting A12         0          1     1
                │      └── 1  chance                                  0          1     0
                ├── 3  ours = bash in some, ≠ both in others          1          2     0
                │         legalized by rulings⁷
                └── 3  ours = dash, = bash, ≠ both, by environment    0          3     0
                          legalized by rulings⁸
                                                              ─────────  ─────────  ────
                                                                    135      1,595    77
```

¹ As above.
² Q2 2, A4 1.
³ A5 1,240, rule E 2.
⁴ G16 126, builtin-vs-coreutils 110, B2 31, rule E 10.
⁵ $0 36, B2 35, A4 8, builtin-vs-coreutils 8, the runner 1.
⁶ A5 4, rule E 3, builtin-vs-coreutils 2.
⁷ $0 2, builtin-vs-coreutils 1.
⁸ $0 3, A5 3.

The 1,793 snippets where ours ≠ a shell: legalized by rulings 1,620, awaiting A12 88, chance 40, not legalized 45 (4 of them marked open in [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv): `cd -` 2, X56, the `zenity` subshell; the 41 others below).

**Snippets and commands.** A command is one call of `echo`, `printf`, `test`, `[`, `kill` or `pwd` inside a snippet, with the arguments we detected at run time (`echo -e '1\n2'`). Ours does these six as coreutils does (since 0.10 inside Perl, IP1); dash and bash have builtins of their own. Every command ours ran, in every environment of every snippet where ours is not as both shells, has been run alone four ways: by coreutils, by dash's builtin, by bash's builtin and by ours ([`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) `-ours`; the answers: [`tools/large-subset-match-calls.jsonl`](tools/large-subset-match-calls.jsonl)).

**The commands** (341 distinct ones; status and output compared):

```
coreutils = dash = bash                  181   (7 of them differ only in the wording of messages)
coreutils = bash ≠ dash                  135
coreutils = dash ≠ bash                   12
coreutils ≠ dash ≠ bash ≠ coreutils        9
coreutils ≠ dash = bash                    4
                                         ───
run by 135 + 75 snippets                 341   ALL: ours = coreutils
```

**The rulings**, by how many snippets each legalizes (a snippet may need more than one; the rulings themselves: section 1 of [`large-subset-state.md`](large-subset-state.md), and [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) for those given by snippet):

| Ruling | What it says | Snippets |
|---|---|---|
| A5 | where dash and bash differ at run time, ours may side with dash | 1,302 |
| G16 | `~` with `HOME` unset: the home from the password file, as bash | 214 |
| builtin-vs-coreutils | R-program (class X, the user, 2026-11-02): ours does the six commands as coreutils, where dash and bash differ by their builtins; checked command by command (the ≠coreutil column) | 121 |
| B2 | the interactive builtins (`history`, `fc`, `bind`, `help`, ...) do nothing here | 67 |
| `$0` | each shell is started under its own name | 41 |
| rule E | `return` outside a function, `cd` without `HOME`: errors, as bash; a pattern never matches `.` or `..`; `[^...]` negates | 15 |
| A4 | `set`, `export` without operands list what the program's output would be: outside the subset at run time | 9 |
| Q2 | `printf -v` stays with the program | 2 |
| the runner | `. script` sources the runner's own stand-in for the program `script`, which logs the shell's `$0`: a difference of the test, not of the shells | 1 |

Builtin-vs-coreutils holds in 135 snippets in every environment where ours ≠ a shell (and in 2 more in some); in 16 of them another ruling is listed first (A5 14, Q2 2: ours = coreutils = dash ≠ bash, and `printf -v`). It goes before chance guessed from a snippet's codes (`pid`, `time`, ...): in 56 snippets with such codes the difference is the command's, and repeatable (`printf '%(%s)T' -1`, `echo -e "... $(date)"`). A4 is found by ours' status 248 and its message; `exec command -with -flags` has them too, but it is X56, a bug of ours, so it is marked open, not A4.

**Not legalized.** Run again by hand in dash, `bash --posix` and ours where new. The last row of the first table is not a snippet of the library: [`tools/large-subset-difffuzz.pl`](tools/large-subset-difffuzz.pl) found it (post-0.11), and it joins the list to be decided with it:

| Snippet | What happens |
|---|---|
| `echo [^f]oo`, `echo *[^0-9]*`, `mv /mnt/usbdisk/[^l]* …` (3) | `[^...]` in a pattern: dash takes `^` literally, bash and ours negate (as rule E, platform; not yet listed under it) |
| `f() { true; }`, `return`, ... | `return` outside a function: dash ends silently, status 0; bash and ours: an error, status 2 (as rule E, error; not yet listed) |
| `echo foo 42>/dev/null`; `head -<$LINENUM + 10> filename` (step 3) | dash takes only one-digit fd numbers: `42` is an argument and nothing is printed; bash and ours print `foo` (and redirect descriptor 10) |
| `#!/bin/sh`, `echo $LINENO` | dash prints an empty line; bash and ours `2` |
| `cd bar1 find . ...`, and 30 `cd` given several words by a program's answer (`cd $(find . -name config)`, step 3) | dash takes the first word, or ignores the extra ones; bash and ours (since X54): "too many arguments", status 1 |
| `ls -a \| tee output.file`; `cat lol \| sed … > lol`; `find $DiskName … \| sort … >> $TMPFILE` given `two  words *` (step 3) | races between the elements of a pipeline: whether `tee` has made the file when `ls` lists, whether `sed`'s redirection empties `lol` before `cat` reads it, whether `find`'s pattern already sees the file `sort`'s redirection makes; each came out otherwise in another run |
| `return \|\| shift \|\| unset IFS` at the top level (the fuzzer) | dash ends the script at `return`, status 0; bash fails both and goes on, status 0 at the end; ours fails `return` as bash ([X48](../pspawn-known-issues.md), rule E) and then ends at the failed `shift` as dash (rule A5), status 2: each ruling right, the combination as neither shell |

Marked open in [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) (in [`TODO`](../../TODO)):

| Snippet | What happens |
|---|---|
| `cd -` (2 snippets) | `OLDPWD` unset: dash prints the directory, ours nothing ([`TODO`](../../TODO), B) |
| `exec command -with -flags` | dash and bash look only for a program after `exec` (not found, 127); ours runs its builtin `command` ([X56](../pspawn-known-issues.md), ours, open) |
| `(echo "#1"; sleep 1; echo "50"; …) \| zenity --progress` (`zenity` missing) | the shells' builtin `echo` dies of SIGPIPE and ends the subshell; ours' `echo` fails alone and the subshell goes on (one `sleep 1` more); the same in 20 runs, so not a race ([`TODO`](../../TODO), A17) |

To be decided with the rules (the user, 2026-11-11: later).

### How it was measured

Two axes (the user, 2026-11-10). **The snippet**: a script, or a part of one, stored in our library; its level comes from the text alone (sections 1–4), and among the undecided the **partially decided** are those whose every dependence was named exactly and tried in example environments (sections 10 and 12; they stay `U` in [`large-subset-provenance.tsv`](large-subset-provenance.tsv), which comes from the parse trees alone, and are the samples of [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv), [`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv) and [`tools/large-subset-env-affects-shell.tsv`](tools/large-subset-env-affects-shell.tsv) still undecided). **The match**, over the environments a snippet ran in (the base run; for the samples with setups also those, of step 2 and of step 3): whether dash and bash agree, whether ours agrees with them, or with which, and wherever ours is not as both shells, whether a ruling legalizes it.

Messages count nowhere (the user, 2026-11-11): not on standard error (as in section 7 of [`large-subset-state.md`](large-subset-state.md)), and not where a redirection sends them either: a line starting with dash's, bash's or our message prefix is dropped from standard output, and files compare by their contents without such lines (the same pattern for all three shells, so texts that were equal stay equal). A message piped into another program (`2>&1 | wc -c`) is not compensated.†

† The same tables with messages compared as before (11 more snippets differ, 5 more are chance, and rulings for messages legalize them): [`large-subset-match-raw.md`](large-subset-match-raw.md), not part of the analysis.

| Level | Snippets | dash and bash agree | agree in some environments | agree in none | timeout |
|---|---|---|---|---|---|
| strict | 365+27=392 | 339+20=359 | N/A | 22+7=29 | 4 |
| held | 2 | 1 | N/A | 1 | 0 |
| almost strict | 34,302 | 34,260 | N/A | 37 | 5 |
| with values passed on unchanged, not in preceding rows | 664+7=671 | 607+5=612 | 0 | 55+2=57 | 2 |
| with values passed on split, not in preceding rows | 1,476+7=1,483 | 1,473+7=1,480 | 0 | 3 | 0 |
| partially decided | 3,508 | 1,852 | 1,530 | 123 | 3 |
| undecided (the rest): classified by reading as still undecided | 0+52=52 | 0+45=45 | N/A | 0+7=7 | 0 |

N+M=T: N found by the programs (the parse trees, the rules of step 3), M classified by reading (AI-…, section 12: AI-strict counts with strict, AI-values passed on unchanged and on split with those rows, the other AI- categories stay undecided), T both; where M is 0, N alone (section 1, footnote ³).

N/A: these ran in one environment only (the base run), so the shells cannot agree in some environments and not in others. The rows "with values passed on …" (LV1, section 1) hold 1,220 samples step 2 tried before step 3 made them almost strict (270 and 950); dash and bash agreed or disagreed alike in all of their environments. The undecided (the rest) are the 52 of the 93 classified by reading that stay undecided; the other 41 count in strict (27) and the rows "with values passed on …" (7 and 7).

**The runs.** The base is the run of the whole library of post-0.11 (2026-11-13, section 7 of [`large-subset-state.md`](large-subset-state.md): the code of post-0.11, the runner waiting up to 5 s for every shell's background jobs, A18); step 2's samples ran again in full in their setups (section 10), step 3's two classes in theirs (section 12), every file recorded also without message lines. The logging runs (`-q`) of ours, in the base run and step 2's setups, for the 1,807 snippets that were not as both shells in some environment (in step 3's, its own logging runs: section 12). Made by `make corpus-step2 corpus-step3 corpus-races corpus-match` ([`../test-pools.md`](../test-pools.md), section 0). Before (2026-11-11, base and step 2 only): alike 38,773, ours ≠ a shell 1,622 (legalized 1,498, awaiting A12 62, chance 53, not legalized 9).

**Found.** X46 and X47 (section 10). **❰BUG❱ dash** 0.5.12: with `HOME` empty, `~` is dropped and `~/x` loses its prefix (`HOME=; set -- ~ ~/x; echo $#` gives 1, `/x`); POSIX treats the result of `~` as quoted, so an empty field; bash and ours give it (awaiting the user: TODO A12). With the runs of post-0.11: X56 (section 7 of [`large-subset-state.md`](large-subset-state.md)); two more races (above); the `zenity` subshell is persistent, not chance. In the tools: [`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) found B2 and `$0` by the undecided codes `U:…` only, not by those inside `passthrough(…)` that step 3 gave the pass and split samples (so 48 `bind`, `history`, … looked not legalized), and its record of the builtins log glued a call to the one before it (section 7 there); both fixed.

**Not done.** The not legalized (above); the `~` rule awaits the user (88 snippets); chance is not a ruling (40 snippets); the strict, held, almost strict and the 93 classified by reading ran in one environment only; a message piped into another program is not compensated.

All of it, from fresh runs: `make corpus-step2 corpus-step3 corpus-races corpus-match` ([`../test-pools.md`](../test-pools.md), section 0). By hand, the report alone: the environments by labels, step 3's with the name of their family (`control/`, `affects-shell/`), and each family's setups:

```sh
X=doc/large-subset/tools
R="-run base=FULL -run base=base -run base2=base2"; for k in $(seq 1 30); do R="$R -run s$k=s$k"; done
R="$R -run control/base=C/base -run control/base2=C/base2"; for k in $(seq 1 15); do R="$R -run control/s$k=C/s$k"; done   # and affects-shell/ the same
P="-prov doc/large-subset/large-subset-provenance.tsv -setups setup-samples.tsv -setups control=C/setup-samples.tsv -setups affects-shell=A/setup-samples.tsv -known $X/large-subset-match-known.tsv"
perl $X/large-subset-matchreport.pl $P -o match0.tsv $R > /dev/null                  # which snippets: ours not as both
grep -v '^#' match0.tsv | cut -f1 | sort -u > q.ids
unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -q -workers-from FULL -only @q.ids samples.jsonl samples.tsv qbase
for k in $(seq 1 30); do unshare -n perl $X/large-subset-runcompare.pl -base /runcompare -env tmp,random,mtime -q -setup setup-$k.jsonl -only @q.ids samples.jsonl samples.tsv qs$k; done
unshare -n perl $X/large-subset-threeway.pl -ours . -db calls.jsonl qbase qs* C/qbase C/qs* A/qbase A/qs*      # 1 minute
Q="-q base=qbase -q base2=qbase"; for k in $(seq 1 30); do Q="$Q -q s$k=qs$k"; done    # and -q control/s$k=C/qs$k, ... as for -run
perl $X/large-subset-matchreport.pl $P -o match.tsv -record setups.tsv -calls calls.jsonl $Q $R   # -raw: large-subset-match-raw.md
```

## 12. Step 3: where the values from the environment land (post-0.11, 2026-11-12; run again 2026-11-13)

The user's step 3 ([`TODO`](../../TODO), A1): recognize more samples by simple programmatic tests. [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) follows every value a sample takes from the environment (a variable read before the text sets it, an argument, a program's output, the working directory, a glob's matches, a file that a redirection, `test` or `cd` names) to where it lands, and puts each sample its codes leave undecided into one class. Record, one line per sample: [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv) (`-p`; the class, what keeps it from passing, what the run can set, its undecided codes, the text).

| Class | Where the values land | Samples | Of them partially decided (section 10) |
|---|---|---|---|
| pass | only through the shell: quoted into a program's words, into an assignment, a `case` word or a here-document; a program's output going on; a status choosing between branches all alike; `pwd`; bash's interactive builtins without file options | 664 | 270 |
| split | the same, and some split and matched against files in a program's words or a `for` list | 1,476 | 950 |
| control | the environment acts only through what the run can set (below) | 2,475 | 1,285 |
| affects-shell | a value affects what the shell itself does (another builtin takes it, arithmetic, `${x:?}`, `set -u`, `set -e`, the shells' own variables; process IDs and the clock: `$$`, `$SECONDS`, `kill` and `wait` with operands) | 1,033 | 397 |
| AI-… | classified by reading (2026-11-13, below): the 93 of control and affects-shell that the example setups left out | 93 | 0 |
| all | | 5,741 | 2,902 |

5,741: the 5,752 undecided before step 3 but 11, where `/` was a delimiter (`cut -d /`, `awk -F/`) and was taken for the whole tree; they are almost strict now on their codes alone. Pass and split are almost strict since step 3 (the user's (a), 2026-11-12): code `A:…,passthrough(r,s)` and `splitglob` (section 2), the two assumptions in table 1. Control and affects-shell stay undecided, and so do the 93 classified by reading (they were 50 of control and 43 of affects-shell).

**Checked against step 2's runs.** The 2,902 samples of step 2 ran in example environments (section 10; record [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv); a class that differs only in messages counted as the same):

- pass: 270 of 270 kept their class in every setup;
- split: 949 of 950; the other, `rev $filename | …`, timed out in all three given `two  words *` (the program's doing);
- control: 1,278 of 1,285 kept their class or changed only between same, `=dash` and `=bash` within the ruling the record names; the other 7: messages in a file or on standard output (`2> bar`, `2>&1 | tee`; 6: that record is written by the comparison with messages counted, `-raw`), and `printf '%q'` ([`TODO`](../../TODO), A13).

The counterexamples of a first version became rules: a value into a builtin other than `echo`, `printf` and `test` keeps a sample from passing (`set -o "$opt"`, `export "$foo"`, `[ "$@" == "" ]`, `printf "%${count}s"`: the value's shape counts there); `cd` with no operand (`HOME`, [`TODO`](../../TODO) A12) and a pattern with `[^` do not pass; `.*` and `//` after a pattern component are control (G2, A5).

**Control: what the run can set.** 1,498 samples depend only on switches whose other states the named ruling covers (`ruling:A5` 1,255: a redirection's file absent, present, a directory or read-only, a `cd` target, a `./program`; `ruling:program` 276: a value into `echo`, `printf` or `test`; `ruling:G2` 11: a pattern for dot names); 934 only on a program's answer or a place the run fixes (the whole tree 523, `/tmp` 183, the clock 171, randomness 65, `/proc` and `/sys` 47, `/dev/urandom` 23: the run's stand-ins answer as chosen, and the programs it runs for real, `ls -l`, `stat`, `sort -R`, `cat /proc/…`, can be stand-ins too); 43 on both. (Since 2026-11-13, without the 50 classified by reading; each place counted over every sample that names it; before: 1,542, A5 1,298, program 279, G2 11; 938, the tree 526, `/tmp` 186, the clock 173, randomness 66, `/proc` and `/sys` 48, `/dev/urandom` 23; 45.)

**Step 2 for the control class** (the user, 2026-11-12: with any program a stand-in). [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl) `-step3` gave all 2,475 example setups: the files and directories they name, absolute names too (every run in a root of its own, a copy-on-write overlay of `/`: [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-env cowroot`), their variables, arguments and input as in step 2, and the programs' answer as one more dependence (base: nothing and status 0; then `x1`; `two  words *` and `last` with status 1; `-n a\b %s`), the programs the step-3 record names stand-ins in all their runs; 9,192 setups, 3 to 15 a sample. Names with an expansion (34 samples; below) included. Left out at first, 50, classified by reading since 2026-11-13 (below): `cd` to `.` or `..` 15, a name in `/dev`, `/proc` or `/sys` 10, the run's own variable 10, a name from a variable the text sets 5, a pattern without a usable example 4, a system path the run needs to run 3 (the loader, `/tmp` itself), 3 others. The match over them ([`tools/large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) `-step3`; record [`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv); every call of `echo`, `printf`, `test`, `[` ours made, run alone by coreutils, dash's builtin and bash's: [`tools/large-subset-env-control-calls.jsonl`](tools/large-subset-env-control-calls.jsonl), 173 calls, ours = coreutils in all; the runs of 2026-11-13, the code of post-0.11 and the runner waiting for background jobs):

```
2,475  the control class, each in its base and setups
│
├── 1,328  ours = dash = bash, in every environment
├──     2  dash = bash; ours ≠ them                      legalized by Q2
└── 1,145  dash ≠ bash, in some or all environments
     ├── 1,090  ours = dash                             legalized by A5
     ├──    51  ours = bash
     │          ├── 49  legalized by rulings            builtin-vs-coreutils 46, rule E 3
     │          └──  2  not legalized                   cd bar1 find …, the same in every environment; head … 10> filename (TODO A13)
     ├──     1  ours ≠ dash, ours ≠ bash                legalized by builtin-vs-coreutils
     └──     3  depends on the environment
                ├── 2  legalized                        A5 and builtin-vs-coreutils
                └── 1  not legalized                    NB:12523, a race (below; TODO A13)
```

So the class held for all 2,475: where the environment changed the class, it changed it only into a difference a ruling legalizes, but for one race: NB:12523, `find $DiskName … | sort … >> $TMPFILE` given `two  words *`, where `sort`'s redirection makes the file `two  words *` that `find`'s pattern sees or not by timing (in dash it did, in bash and ours not; in the run of 2026-11-12 all three alike). They are partially decided now (below, with the class affects-shell).

Found on the way, in the tools: the logs of the calls (ours' and the programs') hold one call a line, but an argument may hold a newline; [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) and the match report now join such lines (the check of the calls had missed those of setups whose answers end in a newline), and the comparison of the programs' calls keeps empty lines (an argument's newline made one, and the sort had dropped it at the end of one shell's log only). G2 is also found by a setup's description now ([`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv): a pattern for dot names given matching files). A setup that would take from the run what it needs (the loader, `/tmp` itself) is left out, and the runner records a run whose environment cannot be made instead of stopping.

**Step 2 for the class affects-shell** (the user, 2026-11-12). The same, with the class's samples (`-class affects-shell`) and three more controls of the runner: the same `$0` for the three (`-env samearg0`), every run in a PID namespace of its own (`-env pidns`: `$$`, `$PPID`, `$!` the same in every run), and the variables the shells set themselves varied too (how each takes an inherited value), not the run's own (`PATH`, `HOME`, the locale). A fixed clock (`-env clock`, libfaketime) was tried and dropped: libfaketime 0.9.10 opens its shared memory as descriptors 3 and 4 in every process it is preloaded into (`echo text >&3` then succeeds in dash and bash), and it would fix little (`date` is a stand-in, file times are fixed, `times` counts CPU time). All 1,033 got setups, 4,773 in all (names with an expansion, 85 samples, included: below; left out at first, 43, classified by reading since 2026-11-13: the run's own variable 14, a name from a variable the text sets 13, `~user` 6, `cd -` 4, a name from a program not on `PATH` 2, 4 others), 3 to 15 a sample, 111 none but the base runs. Record [`tools/large-subset-env-affects-shell.tsv`](tools/large-subset-env-affects-shell.tsv), calls [`tools/large-subset-env-affects-shell-calls.jsonl`](tools/large-subset-env-affects-shell-calls.jsonl) (123 calls, ours = coreutils in all; the runs of 2026-11-13):

```
1,033  the class affects-shell, each in its base and setups
│
├── 584  ours = dash = bash, in every environment
├──   3  timeout (in all three)
├──   2  dash = bash; ours ≠ them               A4 1, open 1 (the zenity subshell: TODO A17)
└── 444  dash ≠ bash, in some or all environments
     ├── 128  ours = dash                       rulings 108 (A5, rule E), A12 19, chance 1
     ├── 246  ours = bash                       rulings 177 (G16, builtin-vs-coreutils, B2, rule E, $0),
     │                                          awaiting A12 64, chance 2, not legalized 3
     ├──  29  ours ≠ dash, ours ≠ bash          rulings 22 (B2, A4, builtin-vs-coreutils), A12 1, chance 6
     └──  41  depends on the environment        rulings 7, A12 4, not legalized 30
```

Of the 446 where ours is not as both shells: legalized by rulings 315, awaiting A12 (`~` with `HOME` empty) 88, chance 9, not legalized 34 (`[^…]` 3; `cd` with extra words 30, all from a program's answer in a name with an expansion; both [`TODO`](../../TODO) A13; and `(echo …; sleep 1; echo …) | zenity`, marked open: persistent, below). Of the 9 "chance", 3 are races checked by many runs (NB:685, 10 runs each: two readers of one pipe, all three gave both results; NB:6259, NB:5776, below), and 6 are none: persistent results (the same in every run, which the environment does not change), and no ruling covers them yet ([`TODO`](../../TODO), A17): the environment `env` and `printenv` list (4: bash adds `SHLVL` and `_`; ours as dash), `/proc/$$/cmdline` (1: each shell's own command line, ours a Perl one), `times` (1: ours, Perl, has used CPU time where dash shows 0). The tree is that of the runs with the runner waiting for background jobs (below; the 46 samples of the class with a background job ran again so): before, it had 556 alike and 23 where only ours differed.

**The races, run many times** (post-0.11, 2026-11-12; `make corpus-races`; [`tools/large-subset-repeat.pl`](tools/large-subset-repeat.pl), record [`tools/large-subset-env-races.tsv`](tools/large-subset-env-races.tsv)). The 33 samples the report called chance by their code `race` (23 alike in base and base2, 10 not; NB:9420 came with the names with an expansion) ran 20 times in each environment where ours was not as both shells (120 sample-environments), and each shell's results (as the report compares them: status, output, the programs' calls, the files; messages not) were set side by side. The first round: 17 races (ours gave only results a shell gave too), 2 races with a timing of ours the shells did not show in 20 runs, and 14 where ours gave its own result in every run: a background job still running when the text ends. Those 14 were not races. Ours finishes its background jobs before it ends (`Proc::ShellSpawn`'s `END` block; [`pspawn-design.md`](../pspawn-design.md), section 6, after K3: `sleep 2 &` takes ours 2 s, the shells 3 ms); dash and bash end at once and leave the job running, and the run then killed it (`pkill`, or the PID namespace ending with the shell), often before its programs had done anything. The user's decision (A18, 2026-11-12): the runner waits for every process of the run, with a reasonable timeout ([`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-after 5`, the default: up to 5 s after the shell ends, then the rest is killed and the run says so; with `-env pidns` process 1 of the namespace reaps and waits). The second round, with that and X55 fixed (below), 2,400 runs of each shell, none cut by the 5 s:

```
33  races by their code, 20 runs in each environment where ours was not as both
│
├── 27  the same in the three in every run (the difference seen before did not come again)
├──  4  race: ours gave only results that dash or bash gave too                                 chance
└──  2  race, ours' timing not seen in the shells' 20 runs                                      chance
        NB:6259  seq 10 | xargs -P4 …: the order of four parallel echo (16, 16 and 14 different orders)
        NB:5776  { echo foo; cat bar; } | tee bar: bar is tee's output and cat's input; it ends at
                 4 bytes if cat reads it before tee has copied foo into it, 8 if after, more if cat
                 reads tee's next copy too (in the runs: 4, 8, 12, 760, 1,344); by hand, 200 runs
                 each: dash 4 (188) or 8 (12), bash 8 (189) or 4 (11), ours 8 (200)
```

[`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) names NB:6259 and NB:5776 "chance" with what was seen.

Run again (2026-11-13, `make corpus-races` after the runs above): of the samples the report calls chance by their code `race`, only `(echo "#1"; sleep 1; echo "50"; …) | zenity --progress` was left (the others now agree in every environment, or are named chance by what was seen). In 20 runs ours gave its own result every time, one `sleep 1` more than dash and bash: not a race but a persistent difference (the shells' builtin `echo` dies of SIGPIPE and ends the subshell; ours' fails alone and the subshell goes on; [`large-subset-state.md`](large-subset-state.md), section 7). Marked open in the known list, [`TODO`](../../TODO) A17. The record [`tools/large-subset-env-races.tsv`](tools/large-subset-env-races.tsv) holds that round; the tree above is the round of 2026-11-12. Found with the races: X55 (ours; fixed): the deferred SIGCHLD handler that moves background jobs on between `run()` calls reaped through `waitpid`, which sets `$?`, and did not keep the program's `$?`; when a job ended just as `t/try.pl` exited, Perl exited with status 255 and no message (about 1 run in 200 of such samples; 4 of 2,400 in the first round, none in the second).


Found on the way: X53 (ours; fixed): a form of `command` the parser refuses, made only by expansions at run time, ran as a program named after the option (both shells: an error). The 28 samples with `command` of both classes ran again with the fix. The match report now knows A4 by ours' status 248 and its message (it knew it only by snippet).

**Names with an expansion** (post-0.11, 2026-11-12; the user: choose the value and make the file of that name together). A file or directory whose name only an expansion gives at run time (`cat < "$fname"`, ``cd `dirname $TARGET_FILE` ``, `~/.bashrc`, `$PWD/*`) gets a name the setup chooses: every value in it is `x1` (a variable the run reads before it sets it, as its own state 2; `$1`, `$2`, `$@`: the arguments `x1` …; a program's output: the programs' answer `x1`, as their answer 1, that program a stand-in), or the run's own (`~` and `$HOME`: `home/` in the run's directory; `$PWD`, `$(pwd)`: the run's directory; `$$`: 2 in a PID namespace). The file of that name then takes the states of its kind (a file with two lines, an empty one, a directory; for `cd`: a directory, a file, a directory not searchable; for a pattern: matching names), and where no dependence of its own sets the value, the setup sets it as chosen (its description says "chosen: …"). Where that dependence never holds the chosen value (`HOME`; `$2` and later), the name gets three setups more, alone. Of the 149 such samples, 119 got setups (control 34, affects-shell 85); left out, 30: a name from a variable the text itself sets (a `for` or `read` variable, an assignment) 18, `~user` 1, from arithmetic 1, from a program not on `PATH` 2, and 8 then left out for another reason (the run's own variable, `cd -`, `cd .`). The setups of every other sample stayed as they were (compared line by line). Of the 119: 28 alike in every environment; 38 legalized by rulings (A5 34, G16 3, rule E 1, `$0` 3; a sample may need more than one); awaiting A12 21; chance 1 (NB:9420, a background job); not legalized 31: `cd` with extra words 30, and NB:6724 (below). (These counts are of the runs of 2026-11-12; no record marks these samples, so they were not counted again on those of 2026-11-13, which the trees above are.)

Found with them: X54 (ours; fixed): `cd` with more operands made by an expansion at run time said `cd: bad argument`, status 2, neither shell (dash takes the first operand, bash: "too many arguments", status 1) and not as ours with the operands in the text (as bash, rule E); now "too many arguments", status 1, either way. The 54 samples of both classes whose `cd` operand holds an expansion ran again with the fix. NB:6724 (`head -<$LINENUM + 10> filename`, control): `10>` redirects descriptor 10 in ours and bash (G12, the option `fdmulti`), while dash takes `10` as a word; not legalized, as `echo foo 42>/dev/null` ([`TODO`](../../TODO) A13), where it joins.

So, of the 3,601 undecided, 3,508 are partially decided (step 2's samples that are still undecided, and the two classes here); the other 93, which the setups left out (control 50, affects-shell 43), are classified by reading.

**Classified by reading** (2026-11-13; the user's categories: `AI-` and the name of a category used before, and `AI-PATH-twister`). Record [`tools/large-subset-ai-classes.tsv`](tools/large-subset-ai-classes.tsv), one line a sample: its category, kind and outcome, the class the rules gave, what it depends on, why; [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl) `-ai` writes the category as the class in [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv) (the levels and every setup stay as they were: checked). A new case is one more line. The setups' reasons for leaving them out, and why each was read so: [`tools/large-subset-setups.pl`](tools/large-subset-setups.pl)'s list above.

| Category | Samples | What they are |
|---|---|---|
| AI-strict | 27 | one run is enough: on an unmovable stone, 18 (`cd /`, `cd ..`, `cd -P .`, `cd /tmp`, `ls -l` of the loader: 15 succeed; `>/` from a placeholder, `./ file`: fail), or on a device working as expected, 9 (reading `/dev/zero`, `/dev/urandom`: 3 succeed; writing `/dev/fd0`, `/dev/tty13`, `2>/dev/nul`: 6 fail here) |
| AI-names with an expansion | 26 | a value the text itself sets (`for f in *; do cd $f`, `… \| while read d; do cd "$d"`, `file='foo bar'; echo foo > $file`; 19), a program at a fixed path not on `PATH` (2), a file under `$HOME` (5) |
| AI-values passed on unchanged | 7 | `$PATH`, `$TMPDIR`, `$USER` quoted into a program's words (`mktemp "${TMPDIR:-/tmp/}…"`) |
| AI-values passed on split | 7 | the same unquoted (`find $HOME/projects/`, `finger ${USER}`) |
| AI-tilde | 6 | `~user`: the user database |
| AI-A5 | 5 | a redirection's file or a `cd` target outside the run's directory (`> ../lpicpio.1`) |
| AI-glob | 4 | patterns the setups found no example name for (`find ./*`; `s/[[:space:]]*$//` split by its quotes; `/usr/bin/python[23]`) |
| AI-shells' own variables | 4 | `cd -` with `OLDPWD` |
| AI-PATH-twister | 4 | the text changes `PATH`, which decides what the shell finds afterwards (`PATH=$PATH:/stuff`, `export PATH=…`) |
| AI-noise | 3 | not shell text: placeholders (`find ~/ [опция_поиска] …`), readline's settings file (`inputrc`) |

What each category would take is in [`TODO`](../../TODO) (B); the classification awaits the user (A).

**Affects-shell.** By reason (a sample under each; alone): `~` 269 / 262 (`HOME`: with it empty dash drops the word, [`TODO`](../../TODO) A12), a variable 132 / 63 (the shells' own, unquoted into a builtin, arithmetic), unquoted into a builtin 122 / 38, `pid` 103 / 67, `race` 86 / 79, files 79 / 38 (`.` of a file, `[^` patterns), a command name from a value 73 / 1, `test-ops` 68 / 10, a program's output read by the shell (`| while read`) 67 / 50, `read` from the run's input 56 / 40, `$0` and `$-` 43 / 33, …

**The assumptions, probed** ([`tools/large-subset-valueprobe.pl`](tools/large-subset-valueprobe.pl), `make probe-values`, 2026-11-12): `passthrough`, 22 odd values (empty, `-n`, backslashes, trailing newlines, NUL, invalid UTF-8, control characters, 100,000 bytes, …) in the environment or in a file read by `$( )`, through 11 forms (quoted words, assignments, `${X:-d}`, here-documents, `export`, output going on, a pipe): the three alike. `splitglob`, 45 values (blanks, `IFS` characters, pattern characters, backslashes, `//`, a leading dot, non-ASCII) in 5 forms (the default `IFS`, `IFS=:`, `$( )`, a `for` list, `set -f`) with files there: alike but for `[^a]*` (A13), `.*` (G2) and `d*//e` (A5). The probe found X52 ([`pspawn-known-issues.md`](../pspawn-known-issues.md); fixed).

**Not checked.** The classes rest on the rules above; only the 2,902 of step 2 were checked by runs, the 2,839 others by reading samples drawn at random from each class (about 150). The probes try the values listed, not every value. The tool's output for `-d` differs from section 10's in two ways that leave the levels before step 3 as they were: the 11 samples above, and block numbers (a command with a `$( )` in its words now carries its own codes; before, the codes after the `$( )` went to the command inside it).
