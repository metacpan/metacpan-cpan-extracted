# ShellSubsetLarge: how much more of sh can Perl run itself? (2026-11-01)

Status: investigation of 2026-11-01. Later the same day the parser was written: `claude/ShellSubsetLarge.pm`, rules in `claude/large-subset-spec.md` (the name was changed from ShellLargeSubset.pm at the user's request). The decisions are on the checklist page "Shell Large Subset" (item IDs such as A1, F3 below refer to it; rule names such as V3, B3 are rules of `shell-subset-spec.md`).

## 1. The question

`ShellSubset.pm` (spec: `claude/shell-subset-spec.md`) parses the easy part of sh and rejects the rest, which then goes to `/bin/sh -c`. The new goal: a module `ShellSubsetLarge.pm` that accepts as much as possible, without making the code unreasonably large.

## 2. What changes conceptually

ShellSubset is a parser with static guarantees: it rejects at parse time everything whose effect it cannot pin down from the text (the command name must be literal, `exec` only where nothing can follow, no `$1`, no builtins beyond `: exit cd`, ...). Most of the remaining gaps (functions, `$1`, `"$cmd" args`, `set`, `eval`) cannot be pinned down from the text. So a larger subset is an **interpreter**: it parses, then decides at run time. Consequences:

- Several static rules can go: V3 (literal command name), B3 and V19 (`exec` placement: `exec cmd` simply runs cmd and ends the shell), V5 (settings before `:`/`exit`), the ban on `$1`–`$9`, `$#`, `$@`, `$*`.
- Some decisions can only be made at run time, after side effects. Then falling back to `sh -c` is impossible. Examples: `eval "$x"` where `$x` holds `[[ … ]]`; `$cmd` that turns out to be `shopt`. The interpreter must stop with an error there (checklist A4).
- Some dash/bash differences show only at run time (exit status after a special builtin's error, see section 5). The interpreter must pick one shell's behaviour; following dash extends V6 (checklist A5).
- The parse tree of the large subset can be a superset of ShellSubset's, so one executor runs both (checklist A2).

## 3. Measured headroom

Script: `claude/large-subset-scan.pl` (needs the corpora restored as in `shell-subset-test-provenance.md`, section 4, and `samples.jsonl` from `extract.pl` of `corpus-run.tar.gz-base64.txt`); summary: `claude/large-subset-report.pl`. Samples are deduplicated per source; scripts count as accepted only if accepted whole. dash 0.5.12, bash 5.2.21.

Columns:
- **Subset now**: `ShellSubset::parse` with all options (`assign param_ops if while for case read empty`) accepts it.
- **POSIX ceiling**: `dash -n` and `bash --posix -n` both accept it, and a regex scan finds no bash-only construct in it (`[[`, `((`, `$'`, `<(`, `<<<`, arrays, `${x/…}`, `function f`, `declare`/`let`/`shopt`/…, brace expansion, `&>`, `$RANDOM`/`$BASH…`, `echo -e`, `read -p` etc., `pipefail`). An upper bound for a dash∩bash interpreter: it does not count builtins that stay rejected.
- **bash ceiling**: `bash -n` accepts it.

| Source | Samples | Subset now | POSIX ceiling | bash ceiling |
|---|---|---|---|---|
| tldr (one-liners) | 29,672 | 97.7% | 98.8% | 99.3% |
| NL2Bash (one-liners) | 10,624 | 89.6% | 93.6% | 99.4% |
| bash Cookbook (scripts) | 81 | 14.8% | 43.2% | 95.1% |
| pure-sh-bible (code blocks) | 44 | 47.7% | 93.2% | 100% |
| pure-bash-bible (code blocks) | 122 | 28.7% | 48.4% | 95.9% |
| ShellCheck snippets, clean | 882 | 42.1% | 69.4% | 98.3% |
| ShellCheck snippets, warned | 779 | 45.7% | 71.2% | 98.1% |

All one-liners together: 95.6% now, 97.4% POSIX ceiling, 99.3% bash ceiling.

Reading:
- **For `system` strings (one-liners) the gain is small**: about 2 points towards the POSIX ceiling. The rest of what is rejected in one-liners is bash-only syntax (`<(…)`: 174 NL2Bash lines; `read -p` and the like: 74; `$'…'`: 59) or builtins that are pointless in `sh -c` (`alias` 80, `history` 52, `shopt` 53, `jobs` 27, `bind` 22, `help` 18).
- **For scripts the POSIX tier roughly doubles acceptance** (pure-sh-bible 48% → up to 93%; ShellCheck 42–46% → up to 70%).
- **Bash-flavoured scripts need the bash tier** (Cookbook 43% → 95%, pure-bash-bible 48% → 96%).

Which POSIX features the rejected-but-in-ceiling samples use (crude regex detection; a sample may use several):

| Feature | tldr | NL2Bash | Cookbook | pure-sh | pure-bash | SC clean | SC warned |
|---|---|---|---|---|---|---|---|
| `$1`, `$@`, `$#`, `$*` | 1 | 203 | 15 | 10 | 8 | 43 | 25 |
| function definitions | 3 | – | 1 | 11 | 12 | 48 | 28 |
| `set` | 12 | 50 | 2 | 3 | 1 | 29 | 20 |
| command name from an expansion | 4 | 31 | 10 | 4 | 3 | 21 | 23 |
| `export`, `readonly`, `unset` | 15 | 30 | 1 | – | – | 13 | 14 |
| `command`, `type`, `hash` | 99 | 13 | – | 1 | 2 | 7 | 3 |
| `eval`, `.`, `source` | 26 | 13 | – | – | – | 9 | 4 |
| `eval`, `.` only | 15 | 3 | – | – | – | 8 | 3 |
| `trap` | 9 | – | 1 | 2 | 5 | 9 | 13 |
| `$$` | – | 28 | 1 | 1 | – | – | – |
| `${x%…}`, `${x#…}` | – | 11 | 3 | 2 | 1 | 1 | 3 |
| here-documents | 3 | 3 | 2 | – | – | 5 | 5 |
| `local` | 5 | 1 | – | – | – | 7 | 4 |
| no feature detected | 142 | 218 | 3 | 1 | 4 | 75 | 75 |

"No feature detected" is mostly builtins, extraction noise, and the restrictions on shell-set variable names. Rejected samples within the POSIX ceiling: tldr 344, NL2Bash 576, Cookbook 23, pure-sh 20, pure-bash 25, ShellCheck clean 249, warned 202.

Builtins at which the parser stops (first error), all one-liners: `command` 103, `alias` 80, `set` 63, `shopt` 53, `history` 52, `jobs` 27, `bind` 22, `export` 21, `unset` 21, `help` 18, `source` 17; all scripts: `set` 73, `trap` 31, `declare` 28, `export` 15, `alias` 12, `getopts` 11.

Greedy coverage, adding the features in the best order, for samples whose only gaps are detected POSIX features (an upper bound): ShellCheck clean 42.1% → 61.8% (posparam, functions, `set`, dynamic command names, `export` give 55.6%); NL2Bash 89.6% → 92.9% (posparam alone: 91.2%); tldr 97.7% → 98.4% (`command`: 98.0%).

## 4. Size

Current: `ShellSubset.pm` parser, 308 lines (dense style). No executor exists yet; one for the current subset would be roughly 350–450 lines in the same style (my estimate).

Estimate for the POSIX tier (my estimates, same style; the checklist items carry the same numbers):
- parser: 308 + F1 10 + F2 10 − F3 20 (the B3 check goes) + F4 20 + F10 5 = about 335; budget 330–400;
- executor: 350–450 for the present subset, plus F1 90 (functions, positional parameters, `"$@"`, `shift`), F2 25, F3 10, F4 15, F5 65 (with IFS splitting), F6 45, F7 12, F8 40, F9 15, F10 15, F11 35 (with the pattern-to-regex conversion shared by F2 and `case`), F12 50, A6 40 (forkless: a new perl for a second in-process part) = about 460, so 810–910;
- together about 1,150–1,250 lines (up to 1,300 with the parser at the top of its budget), against about 700 for the present parser plus an executor for it.

Alternative B of A6 (a resumable interpreter driven by an event loop) would cost much more; my rough guess is that the executor about doubles.

The bash tier would add about 400–500 more (`[[ ]]` with patterns, `(( ))` and `for ((…))`, `$'…'`, indexed and associative arrays, `${x/…}` `${x:o:l}` `${x^^}` `${!x}`, `<<<`, `&>`, `|&`, `declare`, `let`, `mapfile`, `read` options, `pipefail`, brace expansion at run time).

Anchors (non-blank, non-comment lines, counted on 2026-11-01): mvdan/sh, a Go library that parses and interprets bash: parser and lexer 3,892, expansion 2,750, interpreter 5,712. BusyBox: `shell/ash.c` 14,871 lines, `shell/hush.c` 12,365 lines of C.

## 5. dash and bash, checked for this note (dash 0.5.12, `bash --posix` 5.2.21)

Agree (so these can be accepted): `f(){ …; }`, `"$@"`, `$#` inside functions; `${x%.*}`, `${x##*.}`, `"${x#"a"}"`; here-documents with expansion; `read` with and without `-r`; IFS splitting (`IFS=:`); `$((x=5))`; `getopts`; `command -v`; `export`; `eval`; `trap … INT` with `kill -INT $$`; `cd -`; `exec 3>&1`; `a=2 :` keeps `a=2`; `x=5 f` (function) does not keep it; 64-bit arithmetic wrap-around.

Differ:
- `local x` without a value: dash keeps the outer value (`[1]`), bash makes it unset (`[]`).
- `set -o pipefail`: dash 0.5.12 says "Illegal option -o pipefail"; bash accepts.
- `$((i++))`: dash "expecting primary"; bash `1 2`.
- `$'a\tb'`: dash 0.5.12 has no `$'…'`.
- `echo "a\tb"`: dash's builtin turns `\t` into a tab, bash's does not (already handled: `echo` runs as `/bin/echo`, B2).
- `type f`: different text. `trap` without arguments: bash also lists `TSTP TTIN TTOU`. `set -x`: dash `+ echo a b`, bash `+ echo 'a b'`. `$-`: dash empty, bash `hBc`. `$LINENO` in `-c`: dash empty, bash `1`.
- `shift 5` with too few arguments and `export 1x=2`: dash stops the shell, `bash --posix` prints an error and goes on.
- `return` outside a function: dash ends the string silently; bash gives an error.
- `cd` with `HOME` unset: dash stays and succeeds, bash fails (already rejected, V15).
- `${x/b/X}`: dash "Bad substitution".

## 6. A bug found in ShellSubset

See `claude/large-subset-upstream-reports.md`, U1: a string that starts with `-` or `+` is accepted, but `sh -c` takes it as options and fails.

## 7. Executing without fork

The large subset adds subshell-like parts that run Perl code (functions in a pipeline, `( … )` with `cd` or assignments inside). Where `fork` exists, the interpreter forks. Without `fork` (Win32 and the forkless mode of `Run` 0.06) there are two ways: start a new `perl` that runs the module on the part of the tree, with the shell state (variables, functions, current directory, umask, traps) passed along; or make the interpreter resumable, so that an event loop in one process can drive several in-process parts at once, as the user's design note for `Run` 0.07 describes. The second costs much more code (checklist A6).
