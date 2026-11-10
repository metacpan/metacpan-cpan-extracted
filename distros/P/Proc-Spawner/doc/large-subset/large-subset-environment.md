# The corpus samples and the run's environment (known issue X27)

Post-0.08, 2026-11-07. The run-time comparison of [`large-subset-state.md`](large-subset-state.md), section 7, runs each of the 40,410 corpus samples that the large parser accepts once in dash, once in `bash --posix` and once in ours. Every run gets the same almost empty directory, a few fixed variables, no arguments, `/dev/null` as input, and programs that only log their call (but for the plain text tools: [`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl)). An agreement there is a real one only if the comparison could not come out otherwise in another environment. This document says, for every sample, whether that is shown, and if not, on what it may depend. The record, one line per sample: [`large-subset-provenance.tsv`](large-subset-provenance.tsv) (section 2).

The method is the user's (2026-11-07): parse all the samples in one batch, split them into atomic blocks marked with their samples, and sort them with a filter that passes only what is shown unaffected. A pass is meant to be definite (under the assumptions it names); a non-pass is no verdict. The tool: [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl). It works from the parse trees alone: nothing runs. Programs are taken as real and opaque: the tool knows what the shell does with a program (looks it up, hands it words and descriptors, takes its output or its status), not what the program does.

## 1. The answer in short

| Level | Samples | |
|---|---|---|
| **strict** (S): the comparison cannot change with the environment; only how the shell is started is assumed | 365 | 0.9 % |
| **held** (H): the same, under assumptions known to hold in every environment tested (Linux, Linux without `/proc`, Windows under Wine): `devnull`, `heredoc` | 2 | 0.0 % |
| **almost strict** (A): the same, if the named assumptions hold | 34,291 ¹ | 84.9 % |
| **undecided** (U): not shown either way; the codes name what the comparison may depend on | 5,752 ² | 14.2 % |

¹ Tried in another environment (section 9; 2026-11-08): the almost strict samples that need `echo`, `locale`, `pipeline` or `devfd` were run again with the other case (98, 11, 4,159 and 12 samples): 20, 1, 3 and 2 of them came out otherwise beyond the messages (`echo` and `locale`: the program `echo` or `printf`, which ours runs, against the shells' builtins; `pipeline`: 3 endless writers, `yes | … | sed 100q`, that no longer stop; `devfd`: `/dev/stdin` missing without `/proc`); 103 more changed only in the messages under `pipeline`. Those that need `path-var`, `path-home`, `path-mnt` or `path-dev` (899) were run with those places empty or private: none changed. Changes also seen between two runs of the same environment are left out. The level stays as the parse trees give it (the user, 2026-11-08, EV1: the runs go into footnotes, not into the levels).

² Tried in another environment (section 9): of the undecided samples with `path-tmp`, 207 ran with a fresh `/tmp`: 7 came out otherwise (6 had met another run's files there); with `path-random`, 25 ran with a fixed `/dev/urandom`: all 25 now agree (16 had differed by chance). Of those that would also need the assumptions of footnote 1 (345 with `echo`, 14 `locale`, 1,583 `pipeline`, 1 `devfd`, 118 a `path-` place made empty or private), 11, 0, 4, 0 and 2 came out otherwise beyond the messages. With stand-ins (every program the run only logs answering otherwise): of 113 with `prog-status`, run with status 1, none came out otherwise beyond the messages; of 1,014 with `prog-output`, run with a chosen output, 47 did, none with ours against both shells (decided differences of `cd`, `kill`, `test`, and known issue X35, `unset`, fixed since); of 223 with `time`, run with fixed file times, none changed class beyond the noise, and fewer changed between two runs (32 against 50). Undecided they stay (EV1).

By source (S / H / A / U): tldr 62 / 0 / 27,603 / 1,567 of 29,232; NL2Bash 99 / 0 / 6,373 / 3,567 of 10,039; ShellCheck 185 / 1 / 287 / 548 of 1,021; the bash Cookbook, pure-sh-bible and pure-bash-bible 19 / 1 / 28 / 70 of 118. Strict is small because nearly every sample runs a program, and every program needs the assumption `program`.

## 2. The record: [`large-subset-provenance.tsv`](large-subset-provenance.tsv)

One line per accepted sample, sorted by snippet ID, after a header of `#` lines that says what follows and points here:

```
ID<TAB>CODE
```

- `ID`: the snippet ID, which says where the text comes from (format: [`../parsers/shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md), section 2; the texts are remade from the pinned sources by [`tools/large-subset-extract.pl`](tools/large-subset-extract.pl), see section 6).
- `CODE`:
  - `S`: strict.
  - `H:a,…`: held; the assumptions `a`, … are known to hold in every environment tested (section 3, table 1).
  - `A:a,b,…`: almost strict; the comparison cannot change if the assumptions `a`, `b`, … hold (section 3, table 1; held ones may be among them).
  - `U:r,s,…` or `U:r,s,…/a,b,…`: undecided; it may depend on `r`, `s`, … (section 3, table 2); after `/`, the assumptions it would also need if those were settled.

Examples:

```
TL:common/tar.md:13	A:program
NB:4723	A:program,pipeline
NB:10035	A:program,path-system
BC:ch03/func_choice.2	U:vars/program
NB:8081	U:files,prog-output/program,pipeline
NB:10071	U:path-tmp/program
SC:Analytics.hs:prop_checkOverwrittenExitCode7	S
```

Reading it (from the distribution's directory; `F=doc/large-subset/large-subset-provenance.tsv`):

```sh
grep -P '^NB:4723\t' $F                                      # one sample
grep -v '^#' $F | cut -f2 | cut -c1 | sort | uniq -c        # samples by level
grep -v '^#' $F | awk -F'\t' '$2 ~ /^A:/' | cut -f2 | sort | uniq -c | sort -rn   # table 3 below
grep -v '^#' $F | awk -F'\t' '$2 ~ /^U:([^/]*,)?path-tmp([,\/]|$)/'               # undecided by path-tmp
```

## 3. The codes

**At a glance.** Every code, one line each. Level: H held, A almost strict, U undecided. "Samples": for an H or A code, the held or almost strict samples that need it; for an undecided code, the undecided samples that have it (a sample can have several). "Control": whether the run could make the case fixed, or try the other one. Tables 1 and 2 below say more.

| Code | Level | Definition | Samples | Control |
|---|---|---|---|---|
| *programs* | | | | |
| `program` | A | A program is run (any command that is not a builtin or a function of the text); assumed: looked up alike, gets the same words, descriptors and environment, does the same in each run, does not act on the shell | 34,214 | stand-ins only |
| `devnull` | H | a redirection to `/dev/null`: dash and bash have it (POSIX); ours on Windows gets `NUL` (Perl's open, and [`win_spawn.h`](../../win_spawn.h) since X31's fix). Given to a program as a word it is the program's business: no code | 53 | held |
| `devfd` | A | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N` are used (on Linux: needs `/proc`) | 12 | yes |
| `heredoc` | H | a here-document with expansions or of 4,096 bytes or more: bash may use a temporary file (`TMPDIR`, else `/tmp`, which every tested system has); ours uses a pipe | 1 | held |
| *where a program is pointed (an absolute path in its words)* | | | | |
| `path-system` | A | `/etc /usr /bin /sbin /lib* /opt /boot`: read-only for the run's user | 369 | not needed |
| `path-var` | A | `/var` (not `/var/tmp`): logs, spool, web roots | 120 | yes (private mount) |
| `path-home` | A | `/home`, `/root`: absent or closed | 297 | yes (private mount) |
| `path-dev` | A | a device (`/dev/sdX`, ttys): absent or closed | 424 | yes (private `/dev`) |
| `path-mnt` | A | `/mnt`, `/media`, `/srv` | 61 | yes (private mount) |
| `path-absent` | A | a top directory Linux has not (`/path/to/…`; also words like `/re/d` taken for paths) | 977 | yes (make it) |
| `path-tmp` | U | `/tmp`, `/var/tmp`, `/dev/shm` (also redirected to): shared and writable, the runs meet there | 207 | yes (fresh tmpfs) |
| `path-random` | U | `/dev/urandom`, `/dev/random` | 25 | yes (fixed file) |
| `path-proc` | U | `/proc`, `/sys`, `/run`: state of processes and kernel | 49 | no |
| `path-root` | U | `/` itself: the whole tree (`find /`) | 548 | only a container |
| *how the shells are run* | | | | |
| `pipeline` | A | a pipeline: assumes SIGPIPE at its default (a writer whose reader stops early dies silently) | 4,159 | yes |
| `locale` | A | locale-bound forms: bracket expressions or non-ASCII in patterns, `test`'s `<` `>`, `printf %f %q` | 11 | yes (a second locale) |
| `echo` | A | `echo` with a backslash, a leading `-`, or expanded words: assumes `POSIXLY_CORRECT` unset | 98 | yes (one more run) |
| *files and places the shell itself uses* | | | | |
| `files` | U | pathname expansion; a redirection to or from a file (`2>errfile` too); `test -e` and the like; `.`; `./cmd` | 2,285 | yes (fixtures) |
| `directory` | U | `cd`, `pwd`: the working directory, `HOME` | 207 | yes |
| `tilde` | U | `~` (`HOME`), `~user` (the user database) | 269 | partly |
| *values* | | | | |
| `vars` | U | a variable read before the text sets it (from the environment, or unset) | 1,038 | yes (chosen values) |
| `unquoted` | U | an unquoted expansion of a value not known here to be free of `* ? [`; unquoted `$( )` | 631 | yes |
| `args` | U | `$1`, `$@`, … at the top level with no `set` before (none were given) | 218 | yes |
| `start` | U | `$0`, `$-`: how the shell was started | 43 | partly |
| `name` | U | a command name from an expansion | 73 | yes |
| `test-ops` | U | `test` whose expression's shape depends on expanded operands | 68 | yes |
| `eval` | U | `eval` or a trap action of a text not literal, or rejected by the parser | 19 | partly |
| `input` | U | `read` from the run's standard input | 56 | yes (chosen input) |
| `listing` | U | `env`, `printenv`, `export`, `readonly` alone: print the environment | 28 | no |
| *a program's results, taken by the shell* | | | | |
| `prog-output` | U | the shell uses a program's output (`$( )`, a pipe into `read`, a loop, a function) | 1,014 | stand-ins only |
| `prog-status` | U | a program's status decides (`&&`, `||`, `!`, `if`, `while`; `$?` after it; under `set -e`) | 113 | stand-ins only |
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
| `interactive` | U | `history`, `fc`, `bind`, `help`, `compopt`, `logout` (B2) | 107 | partly |

**Table 1: the assumptions of "held" and "almost strict".** "Needed by": held or almost strict samples whose level rests on it (a sample can need several; table 3 has the combinations). "Under our control": whether the run could make the assumption true, or try the other case.

| Code | The assumption | Needed by | Under our control |
|---|---|---|---|
| `program` | An external program (looked up on `PATH`, or named by a path): the three shells look it up alike and hand it the same words, descriptors and environment; it does the same in each run (no clock, no randomness, no process IDs of its own), does not act on the shell (`killall bash`), and does not mind the variables a shell adds to the environment it passes (bash: `SHLVL`, `_`). Its output, status and effects are then the same for all three, as long as the shell does not use them (that is `prog-output`, `prog-status`). Programs known to break it are undecided instead (`time`, `random`, `race`), but that list cannot be complete (`ping`, `top`, network clients). | 34,214 | Only by replacing programs with stand-ins that behave the same in each run, as the run's recorders do (then the programs themselves are not exercised). |
| `pipeline` | A pipeline: its elements run at once; when a reader stops before the end of its input, the writer is killed by SIGPIPE, silently, and only the last element's status counts. That holds with SIGPIPE at its default. If the environment ignores SIGPIPE (it is inherited), a writer instead gets an error and may print a message (bash's builtins print "write error: Broken pipe"), so the messages may differ. | 4,159 | Yes: the runner starts the shells with SIGPIPE at its default ([`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) does). A second run with SIGPIPE ignored would try the other case. |
| `devnull` | **Held.** A redirection to `/dev/null`: a POSIX system has it, so dash and bash do; on Windows ours gets `NUL` from Perl's own `open` (for the shell layer) and from [`win_spawn.h`](../../win_spawn.h) (for `Proc::Spawner`'s open action; X31, fixed and checked under Wine). `/dev/null` given to a program as a word is no code: what the program does with it is the program's business, the same under every shell. | 53 | Held in every tested environment. |
| `devfd` | `/dev/stdin`, `/dev/stdout`, `/dev/stderr`, `/dev/fd/N`: on Linux these are links into `/proc/self/fd`, missing where `/proc` is not mounted (X28's check without `/proc`). bash 5.2.21 does not emulate them then either (it emulates them only where it was built without them; checked 2026-11-08: `echo x > /dev/stderr` with `/proc` hidden fails in all three shells, bash with status 1, dash and ours with 2). | 12 | Yes: `/proc` mounted, or not. |
| `heredoc` | **Held.** A here-document whose body has expansions, or 4,096 bytes or more: bash may then write it to a temporary file (in `$TMPDIR`, else `/tmp`). Smaller literal bodies go through a pipe in all three (checked: bash 5.2 and dash with `TMPDIR=/nonexistent`, bodies of 100, 5,000 and 70,000 bytes, all fine; ours always uses a pipe, `Proc::ShellSpawn`, redirections), so they are strict. | 1 | Yes: `TMPDIR` (the run sets it to the run's directory). |
| `locale` | A bracket expression or non-ASCII text in a pattern, `test`'s `<` and `>`, `printf`'s `%f %e %g %a %q` and its `'` flag: the locale as in the run (`LANG=C`, `LC_ALL=C`). | 11 | Yes: a second run with another locale (`C.UTF-8`) tries the other case for these samples alone. |
| `echo` | `echo` with a backslash, a first word starting with `-`, or words from expansions: `POSIXLY_CORRECT` unset. It changes coreutils `echo` (which ours runs; rule "the program beats the shells' difference") but not dash's or bash's builtin. It is a switch of two values, so one more run of these samples with `POSIXLY_CORRECT=1` settles them: their runs double, nobody else's. (`POSIXLY_CORRECT` also changes other GNU programs, such as `ls dir -l`, but the same way in all three shells: that is within `program`.) | 98 | Yes. |
| `path-system` | A program is given a path under `/etc /usr /bin /sbin /lib* /opt /boot`: read-only for the run's unprivileged user, so the runs cannot change it, and the same in each run unless the system itself changes. | 369 | Nothing needed (a read-only snapshot would make it certain). |
| `path-var` | … under `/var` (not `/var/tmp`): logs, spool, web roots; they change with time, mostly closed to the run's user. | 120 | Yes: a private mount over `/var` for each run (`unshare -m`). |
| `path-home` | … under `/home` or `/root`: absent or closed to the run's user. | 297 | Yes: a private mount. |
| `path-dev` | … a device under `/dev` (disks, ttys, `/dev/input/mice`), not `/dev/null`: absent or closed to the run's user, so every run fails alike. | 424 | Yes: a private `/dev`. |
| `path-mnt` | … under `/mnt`, `/media`, `/srv`: empty mount points or absent. | 61 | Yes: a private mount. |
| `path-absent` | … under a top-level directory a Linux system does not have (`/path/to/…`, `/some/dir`, macOS's `/Users`; also words like a `sed` script `/re/d` or a Windows switch `/v`, taken for paths): nothing is there, so every run fails alike. | 977 | Yes: make it in a private mount namespace, if the sample should be exercised with something there. |

The irreducible part of strict, assumed everywhere: the shell started as in the run (its options, and the variables that steer the shell itself, such as `SHELLOPTS` and the locale), descriptors 0–2 open, no signal from outside, enough memory, processes and disk, and the programs the subset runs in place of builtins (`echo`, `printf`, `test`, `[`, `true`, `false`) present as coreutils (X21; since post-0.09 they run inside Perl by default, decision IP1, so this one no longer depends on the system, apart from X21's differences). Before that, like `devfd` and the `path-` codes, it was a POSIX system's: on Windows (`Proc::ShellSpawn` there is open) it failed, and every sample that runs one of these programs would have to be judged again (142 of the strict ones do).  Closed (the user, 2026-11-10, SP1): since IP1 these programs run the same on every platform, so strict needs no code for them; checked under Wine by [`t/programs.t`](../../t/programs.t) for the programs alone, not on these samples (the library under Wine is `TODO`). `devnull` and `heredoc` are known to hold on Windows too, so they form the level "held": an assumption is held when it is checked to hold in every environment we test; the level can grow as more are checked.

**Table 2: the codes of "undecided".** "Decides": undecided samples that have it / that have no other undecided code.

| Code | What the comparison may depend on | Decides | Under our control |
|---|---|---|---|
| `files` | What the directory holds: a pattern in a word (pathname expansion), a redirection to or from a file (`2>errfile` included: whether it exists, its type, contents, permissions), `test`'s file operators, `.`, a command named by a relative path (`./script`). | 2,285 / 1,972 | Yes: fixtures (the files the samples name). |
| `directory` | The working directory or `HOME`: `cd`, `pwd`. | 207 / 73 | Yes: chosen directories. |
| `vars` | A variable read before the text sets it: from the environment, or unset. | 1,038 / 685 | Yes: chosen values. |
| `unquoted` | An unquoted expansion whose value is not known here to be free of pattern characters (it is split and matched against files); unquoted `$( )`. | 631 / 15 | Yes: chosen values and fixtures. |
| `args` | Positional parameters at the top level with no `set` before them: none were given. | 218 / 121 | Yes: chosen arguments. |
| `start` | `$0`, `$-`: how the shell was started. | 43 / 5 | Partly: the runner names the shells alike (`sh`). |
| `status` | `$?` at the start of a function's body or of a trap action: the status of a command the text does not show. | 4 / 0 | No. |
| `prog-output` | The shell takes a program's output: in `$( )`, or through a pipe into `read`, a loop or a function. | 1,014 / 202 | Only with stand-ins of chosen output. |
| `prog-status` | A program's status decides: `&&`, `||`, `!`, the condition of `if`, `while`, `until`; `$?` after it (also in a loop, from the round before); a command after it under `set -e`. | 113 / 72 | Only with stand-ins of chosen status. |
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
| `interactive` | `history`, `fc`, `bind`, `help`, `compopt`, `logout` (B2): bash reads their state from files and variables. | 107 / 96 | Partly: `HISTFILE`, `INPUTRC`. |
| `path-tmp` | A path under `/tmp`, `/var/tmp`, `/dev/shm`, given to a program or redirected to: shared and writable, so the runs of the three shells meet there (`mkdir /tmp/x`: the second run finds the first one's directory). | 207 / 151 | Yes: a fresh tmpfs on each of them for each run (`unshare -m`). |
| `path-random` | `/dev/urandom`, `/dev/random`. | 25 / 18 | Yes: one fixed file bind-mounted over both for each run. |
| `path-proc` | `/proc`, `/sys`, `/run`: the state of processes and of the kernel (`/proc/self/fd`, PIDs). | 49 / 30 | No: process IDs differ between runs. |
| `path-root` | `/` itself: the whole tree, `/proc` and `/tmp` included (`find / -name x`, `ls -lR /`). | 548 / 475 | Only with a private root (a container or `chroot`). |

**Table 3: held and almost strict samples by the exact set of assumptions they need.** Each such sample is unaffected if all of its assumptions hold; it is counted once, under the whole set.

| Assumptions | Samples |
|---|---|
| `program` | 28,322 |
| `program` `pipeline` | 3,635 |
| `program` `path-absent` | 659 |
| `program` `path-dev` | 373 |
| `program` `pipeline` `path-absent` | 265 |
| `program` `path-system` | 261 |
| `program` `path-home` | 227 |
| `program` `path-var` | 82 |
| `program` `pipeline` `path-system` | 69 |
| `echo` | 56 |
| `program` `pipeline` `path-home` | 50 |
| `program` `path-mnt` | 38 |
| `program` `pipeline` `echo` | 38 |
| `program` `pipeline` `path-var` | 29 |
| `devnull` `program` | 25 |
| `program` `pipeline` `path-dev` | 23 |
| `program` `path-dev` `path-absent` | 16 |
| `program` `path-system` `path-absent` | 11 |
| `locale` | 10 |
| `pipeline` | 10 |
| `program` `pipeline` `devfd` | 9 |
| `devnull` `program` `path-absent` | 8 |
| `devnull` `program` `pipeline` | 7 |
| `program` `path-dev` `path-mnt` | 7 |
| `program` `path-system` `path-home` | 7 |
| `program` `path-home` `path-absent` | 6 |
| `program` `path-system` `path-mnt` | 4 |
| `program` `path-system` `path-var` | 4 |
| `program` `pipeline` `path-mnt` | 4 |
| `devnull` `program` `pipeline` `path-system` | 3 |
| `program` `pipeline` `path-system` `path-absent` | 3 |
| `devnull` | 2 |
| `devnull` `program` `pipeline` `path-absent` | 2 |
| `program` `path-mnt` `path-absent` | 2 |
| `program` `path-system` `path-dev` | 2 |
| `program` `pipeline` `echo` `path-system` | 2 |
| `program` `pipeline` `path-home` `path-absent` | 2 |
| `program` `pipeline` `path-system` `path-mnt` | 2 |
| `devnull` `locale` | 1 |
| `devnull` `program` `path-home` | 1 |
| `devnull` `program` `path-mnt` | 1 |
| `devnull` `program` `path-system` | 1 |
| `devnull` `program` `path-var` | 1 |
| `devnull` `program` `pipeline` `path-home` | 1 |
| `heredoc` `program` | 1 |
| `program` `devfd` | 1 |
| `program` `devfd` `path-absent` | 1 |
| `program` `echo` | 1 |
| `program` `path-dev` `path-mnt` `path-absent` | 1 |
| `program` `path-var` `path-dev` | 1 |
| `program` `path-var` `path-mnt` | 1 |
| `program` `pipeline` `devfd` `echo` | 1 |
| `program` `pipeline` `path-home` `path-dev` | 1 |
| `program` `pipeline` `path-home` `path-mnt` | 1 |
| `program` `pipeline` `path-var` `path-absent` | 1 |
| `program` `pipeline` `path-var` `path-home` | 1 |
| all | 34,293 |

Note: 79 samples need a non-empty set of assumptions none of which is `program`: `echo` 56, `locale` 10, `pipeline` 10, `devnull` 2, `devnull locale` 1. One more run with `POSIXLY_CORRECT=1` or another locale settles most of them. 28,322 samples need only `program`.

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

## 9. What can be done about a code, and the run's environment varied (post-0.09, 2026-11-08)

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
| `posix` | `echo` | 443 | 31 | 13 (+3 noisy) | 29 from "ours as bash" to "ours as dash": with `POSIXLY_CORRECT` set, the program `echo` (which ours runs) interprets backslashes and takes no options, as dash's builtin does; bash's builtin does neither. 2 from "same" to **ours differs**: `echo '\x4a'`, `echo '\xat'`: the program then interprets `\x`, neither shell does. |
| `utf8` | `locale` | 25 | 1 | 2 | `printf "€ %.2f\n" 123.4`: in `C` all three print `€`; in `C.UTF-8` bash and the program print `€`, dash's `printf` has no `\u` ("same" to "ours as bash"). |
| `sigpipe` | `pipeline` | 5,742 | 130 (+18 noisy) | 217 (+75 noisy) | Beyond the messages only 6 timeouts: an endless writer (`yes \| nl \| sed 100q`) no longer dies when its reader stops. The rest are messages: 95 from "messages as dash's" to "as neither": the program `echo` writing into a pipe whose reader is gone (`echo x \| missing`) says "echo: write error: Broken pipe", dash's builtin nothing; and programs' "write error: Broken pipe" that appear or not by timing. |
| `noproc` | `devfd` | 13 | 3 | 1 | `paste /dev/stdin`, `mv … < /dev/stdin` and `tee /dev/stderr` fail in all three (the redirection's status: ours as dash, rule A5). bash does not emulate `/dev/stdin` then (table 1). |
| `tmp` | `path-tmp` | 207 | 7 (+1 noisy) | 5 (+4 noisy) | 6 from "ours as bash" or "as dash" to "same": `mkdir /tmp/foo` and redirections into `/tmp`, where the second and third shell found the first one's file, or another sample's; 1 by timing (`… \| xargs -n 1 grep …`, the calls). |
| `random` | `path-random` | 25 | 16 (all noisy) | 0 | 14 from "ours as neither" to "same", 2 from "timeout" to "same": the same bytes in every run, and `cat /dev/urandom` ends. All 25 now agree. |
| `private` | `path-home`, `path-mnt`, `path-var` | 573 | 2 | 6 (+3 noisy) | None from the variant: both changes are another sample's `/tmp/size.log` (below). |
| `dev` | `path-dev` | 444 | 0 | 0 (+1 noisy) | None. |
| `fail` | `prog-status` | 113 | 3 | 23 | Nothing beyond the messages: with every logged program failing, the three shells still agree. 2 from "messages as dash's" to "same" (the command whose message differed is no longer reached), 1 to "timeout" in all three (`until systemctl is-active -q nginx; do …; done` never ends). |
| `output` | `prog-output` | 1,014 | 62 | 394 (+19 noisy) | 47 beyond the messages, none where ours differs from both shells. 27 `cd $(…)` given several words: dash goes to the first, bash fails with status 1, ours fails with 2 (rule E, `cdargs`, decided). 13 `kill $(…)` given words that are no process IDs: dash status 2, bash and the program 1 (as in the atomic calls, [`large-subset-state.md`](large-subset-state.md), section 7). 2 `[ $? == 0 ]`: the program `test` takes `==`, as bash. 2 `unset $(…)` given words that are not names: dash fails ("bad variable name", status 2), bash takes them for function names (status 0), ours did nothing with status 0: **known issue X35** (ours; fixed since, as dash). 2 by timing (`echo $(date) "0" \| tee -a log.csv`: dash's `*` already sees `log.csv`). 1 `g=$(md5sum $f) > $f.md5` in a loop: dash makes the file before running the substitution, bash after (ours as dash). The other 15 changed only in the messages. |
| `mtime` | `time` | 223 | 0 (+6 noisy) | 10 (+40 noisy) | The point is repeatability: between two base runs 50 of these samples changed some result, between two runs with fixed times 32. What still changes: the shells' own clocks (`time`, `times`, `printf '%(…)T'`), and times of what is not the run's copy (`ls -ld /tmp`, `ls -lR /`, `/proc`). |

Noise (base against base2, 7,003 samples): 122 changed some result, 40 their class.

**Found.**
- `/tmp` is shared not only by the three shells of one sample but by all samples and workers of a run: `NB:3439` (`… >> /tmp/size.log`) made the file as one worker's user, and `NB:3440`, run later by another, failed in all three shells with "Permission denied". The run of `large-subset-state.md`, section 7, had this too; `-env tmp` removes it.
- With `POSIXLY_CORRECT=1` in the environment, the subset's `echo` (the program, rule "the program beats the shells' difference") changes its meaning: it sides with dash for backslashes and `-e`, and differs from both shells for `\x`. Decided (the user, 2026-11-09, EC1): accepted, and a switch added: `PROC_SHELLSPAWN_ECHO=dash` or `bash` makes our `echo` that shell's builtin, which `POSIXLY_CORRECT` does not change (default `coreutils`, as before); [`t/dash.t`](../../t/dash.t) runs ours with `dash` (section 7 of [`large-subset-state.md`](large-subset-state.md), table of section 1).
- Known issue X33 ([`pspawn-known-issues.md`](../pspawn-known-issues.md); ours, fixed): the runner made `/dev/stdout` and `/dev/stderr` unwritable for the run's user.
- Table 1 said bash emulates `/dev/stdin` and the like where `/proc` is missing; bash 5.2.21 does not (corrected above).
- `private` and `dev` changed nothing: in this container those places are absent, empty or closed to the run's user, as the assumptions say. Checked in this container only.

**Not done.** The variants ran one at a time, each only on its own code's samples, in one container; nothing was combined (`-env tmp,random,mtime` for the whole run is the obvious next step). The stand-ins tried one answer each (status 1; one output text), the same for every program the run only logs. The levels of sections 1–3 are not changed by these runs: they come from the parse trees alone; the runs are footnotes to the totals of section 1 (the user, 2026-11-08, EV1). Kinds 3 (inside the run's directory) to 6 are not started.
