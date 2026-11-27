# Dash vs bash: features sorted by how the two shells differ

This document lists the features in which dash and bash differ, and sorts each difference as *blatant* or *subtle*, by the user's definition ([section 1](#my-section-1)). It was written on 2026-11-02 and revised twice that day after the user's reviews, the second time with bash's manual at hand. It replaces the sorting in item Y1 of the page "Shell Corpus Gaps".

*The user* is the distribution's author, who makes its decisions; items such as Y1, P1–P4, Q1 are those of the decision page "Shell Corpus Gaps" (in Proc-Spawner 0.04), and rule E is the later rule for differences of dash and bash: where they differ, the subset takes the plainly logical behaviour, if there is one, and the difference then counts as class X (section 2; [`large-subset-logical.md`](large-subset-logical.md)). R-refuse (what both shells refuse, the subset refuses) and R-program (for a command the subset runs as a program, the program beats the shells' difference) are rules of section 1 of [`large-subset-state.md`](large-subset-state.md#my-section-1). A version number beside a probe or a verdict ("since 0.05") names the release from which the subset handles the form as the row says. *The detector* is [`tools/large-subset-features.pl`](tools/large-subset-features.pl) (section 8).

*The subset* below means the large parser, `Proc::ShellSubset::Large`, together with `Proc::ShellSpawn`, which runs its trees. dash 0.5.12 and `bash --posix` 5.2.21 throughout. In the tables, the dash and bash results are separated by "/".

## <a id="my-section-1"></a>1. The definition (the user's words, 2026-11-02)

A mismatch between dash and bash is **blatant** when:

> either one of them fails or does not match the docs; or they behave in blatantly different ways.

> Other mismatches in how dash/bash behave are "subtle".

### <a id="my-the-yardsticks"></a>The yardsticks

The two *yardsticks* are the sets of corpus samples (snippets from six public collections, [`../test-pools.md`](../test-pools.md)) against which the large parser's acceptance is measured (the parse results, [section 3 of `large-subset-state.md`](large-subset-state.md#my-section-3)). They are defined by features of the shells alone, never by the parser they measure:

- **Upper** ("nothing bogus"): both shells parse the sample (`dash -n`, `bash --posix -n`), and it uses no blatant feature.
- **Lower** ("compatible"): within the upper yardstick, and it uses no subtle feature either.

Where both shells parse and run a form alike, the large parser must accept it, unless a decision rejects it (as the base parser's decision B3 rejects `ulimit` setting a limit: [section 4 of `large-subset-state.md`](large-subset-state.md#my-section-4)); items P1–P4 of 2026-11-02 were such forms (literal braces, expansions inside `$(( ))`, names the shells set that both let a snippet set, `export $v=…` and `exit N` above 255).

**Why Y1 was wrong.** Y1 sorted the parser's rejection messages, so the yardsticks depended on the parser they measure. It also paraphrased the definition as "one shell errors, or the result is clearly different", which is not what the user said.

## <a id="my-section-2"></a>2. Who decided each verdict

Every verdict carries a **basis**:

- **P:ID** (set in stone): a probe run in both shells shows it. ID names the probe in [`doc/large-subset/dialect-cases/cases.txt`](dialect-cases/cases.txt) or [`large-subset-dialect-probes2.txt`](dialect-cases/large-subset-dialect-probes2.txt). Each probe runs in `dash -c` and in `bash --posix -c`, in a fresh empty folder, with stdin from `/dev/null`. A probe settles "one shell refuses what the other runs" and "the results differ"; whether a difference of results is blatant (section 4) or subtle (section 6) was sorted in the user's reviews of 2026-11-02, and where it is not settled the verdict is J.
- **P:-n** (set in stone): a shell refuses to parse the snippet.
- **M:N** (set in stone): item N of "Bash POSIX Mode", section 6.11 of the Bash Reference Manual of bash 5.2.21. It was read from the Debian package `bash-doc`, since gnu.org could not be reached from the machine where the probes ran.
- **SC:CODE**: ShellCheck 0.11.0 says dash lacks the construct, so dash fails. Not probed one by one.
- **J** (a judgement by Claude, 2026-11-02, not yet reviewed by the user): a difference is shown, but whether it is blatant or subtle is not settled by it. The detector has one such feature, `dashflags` (`$-`); its verdict is kept, as free-form text, in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) and counts as open (O) until the user rules. The two J rows of sections 5 and 6 are not features of the detector (the text alone cannot show them); they are sorted here as the judgement says.

When the user rules on a verdict, [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) records the ruling in short form, with the basis "user"; no rescan is needed.

Two decisions of the user (2026-11-02) say how some differences count:

- **Both shells refusing**: "both shell refusing means that we should better refuse this too". Such forms are counted as blatant, so they stay outside both yardsticks.
- **Class X**: for the commands the subset runs as programs (`echo`, `printf`, `test`, `[`, `kill`, `time`), "the program beats the shells' difference": the subset does what the program does, whatever the shells do (except where both shells refuse the form: there R-refuse wins, as for `kill -SIGHUP` in section 5). Those differences are marked X, and they exclude no sample from either yardstick.

The order in which all the rules apply is in [section 2 of `large-subset-state.md`](large-subset-state.md#my-section-2).

## <a id="my-section-3"></a>3. Blatant: one shell refuses, or lacks, what the other runs (basis: probe)

The verdicts in sections 3 to 6 are those of 2026-11-02 (with a few later notes); the rows of `echo`, `printf`, `test`, `time` and `kill %1` there are class X since the decision above, though listed as blatant; the current verdict and basis of each feature, rule E's class X among them, are in the table of [`tools/large-subset-features.pl`](tools/large-subset-features.pl).

| Feature | Example | dash / bash | Probe |
|---|---|---|---|
| arrays: list assignment, `${a[i]}`, `${#a[*]}`, `$PIPESTATUS` | `a=(x y); echo ${a[1]}` | syntax error or "Bad substitution" / works | array, pipestatus |
| assigning an array element | `a[1]=x` | "not found" / works | elemassign |
| unsetting an array element | `unset a[1]` | "bad variable name", the shell stops / works ("not an array variable" for a plain variable, status 1) | unsetarr (since 0.05) |
| `[[ … ]]` | `[[ a == a* ]]` | "not found" / works | dbracket |
| `(( … ))` as a command | `((x=1+1))` | a nested subshell, nothing printed / works | dparen |
| `for ((…))` | `for ((i=0;i<2;i++))` | syntax error / works | forarith |
| bash arithmetic operators | `$((2**3))`, `$((16#ff))`, `$((i++))`, `$((1, 2))` | arithmetic error / works | pow, base, incr, comma |
| bash parameter forms | `${x/b/X}`, `${x:1:2}`, `${x^^}`, `${x,,}`, `${!x}`, `${!a*}`, `${@:2}`, `${x@Q}` | "Bad substitution" / works | substr (the first three), caselower, indirect, prefixstar, atslice, atQ |
| process substitution | `cat <(echo hi)` | syntax error / works | procsub |
| here-string | `cat <<< hi` | syntax error / works | herestr, herestrq |
| `\|&` | `echo hi \|& cat` | syntax error / works | pipeamp |
| `>&` with a file name | `echo hi >&f` | "Bad fd number" / works | dupfile |
| a redirection right after a duplication's digit, with no blank between | `echo x >&2>f` | syntax error / works | redirdigit |
| `{fd}>` | `exec {fd}>f` | "not found" / works | fdvar |
| `function NAME` | `function f { …; }` | syntax error / works | function, fnparen |
| `select` | `select x in a; do …; done` | syntax error / works | select |
| `case` fall-through | `;&`, `;;&` | syntax error / works | casefall, caseamp |
| bash-only builtins, and the reserved word `coproc` | `source`, `declare`, `typeset`, `let`, `pushd`, `shopt`, `mapfile`, `coproc` | "not found" / works | source, declare, typeset, let, pushd, shopt, mapfile, coproc |
| `time` | `time true` | runs a program `time` (absent here: "not found") / keyword | time |
| bash `set` options | `-o pipefail`, `-o posix`, `-o history`, `-B`, `-H` | "Illegal option" / works | pipefail, setposix, sethist, setB, setH |
| `test` extensions | `[ a == a ]`, `[ -a f ]`, `[ -v x ]` | "unexpected operator" / works | testeqeq, testaun, testv |
| `printf` extensions | `%q`, `%(…)T`, `printf -v` | error / works | printfq, printfT, printfv |
| `read` options | `-n`, `-s`, `-t`, `-a`, `-d` | "Illegal option" / works | readn, reads, readt, reada, readd |
| `read` without a name | `read; echo "$REPLY"` | "arg count" / works | readreply |
| `jobs` in a pipeline or `$( )` | `sleep 1 & jobs \| wc -l` | 0 / 1 (dash lists nothing there) | jobspipe, jobsppipe, jobspsubst (since 0.04) |
| `cd` with extra operands | `cd a b` | ignores `b` / "too many arguments", status 1 | cdargs (since 0.04) |
| `type` options | `type -p ls`, `type -t ls` | looks up `-p` as a command / works | typep, typet |
| `wait -n` | `wait -n` | "Illegal option" / works | waitn |
| `export -f`, `export -n` | `export -f f` | "Illegal option" / works | exportf, exportn |
| `exec -a` | `exec -a foo cmd` | "not found" / works | execa |
| `local` options | `local -r x=1` | "bad variable name" / works | localr |
| bash signal names in `trap` | `SIGINT`, `ERR`, `DEBUG` | "bad trap" / works | trapsigint, traperr, trapdebug |
| job specs | `kill %1` after `cmd &` | "No such process" / works | job |
| a function named after a builtin one shell treats as special (dash: `local`; `bash --posix`: `source`) | `local() { …; }`; `source() { …; }` | syntax error / works; works / error | fnlocal, fnsource |
| a read-only bash variable as an assignment | `UID=5 echo hi` | works / "readonly variable" | uidset (the detector's features: `uidassign` for `UID=`, rule E as dash since 0.05; `uidread` for reading `$UID` where the snippet does not set it) |
| `return` outside a function | `echo a; return; echo b` | ends quietly / error | return |

## <a id="my-section-4"></a>4. Blatant: both run it, the results differ (basis: probe, except where marked J or open)

| Feature | Example | dash / bash | Probe |
|---|---|---|---|
| `echo` with a backslash before a letter it expands (`\a \b \c \f \n \r \t \v \0 \\`) | `echo 'a\nb'` | two lines / `a\nb` | echobs |
| `echo -e`, `-E`, `-ne` | `echo -e 'a\tb'` | prints `-e` and expands / expands | echoe, echoE, echonen |
| `$'…'` | `echo $'a\tb'` | `$a<TAB>b` / `a<TAB>b` | ansi |
| `$"…"` | `echo $"hi"` | `$hi` / `hi` | locale |
| brace expansion | `echo a{b,c} {1..3}` | as written / expanded | brace |
| `$[…]` | `echo $[1+2]` | `$[1+2]` / `3` | dollarbr |
| `&>`, `&>>` | `cmd &>f` | `cmd` in the background, then `f` truncated / both outputs to `f` | ampgt, appendboth |
| `$(<file)` | `echo "$(<f)"` | empty / the file's text | dollarlt |
| `.` with arguments | `. ./s arg` | `$1` not set / `arg` | dotargs |
| a two-digit file descriptor | `echo hi 10>/dev/null` | nothing printed / `hi` | fdmulti |
| a pattern component that can match `.` or `..` | `echo .*` | includes `.` and `..` / leaves them out | dots |
| `[^…]` in a pattern | `case b in [^a])` | `^` is literal / negation | caret |
| `${#@}`, `${#*}` | `set -- a b; echo ${#@}` | `3` / `2` | atlen |
| a pattern operator on `$@`, `$*` | `"${@#?}"` | on the parameters joined into one value / on each | atpat (rule E as bash since 0.05) |
| an escaped `"` in backquotes inside `"${…}"` | ``"${x:-`echo \"q\"`}"`` | `q` / `"q"` | bqdq |
| bash's own variables | `$RANDOM`, `$SECONDS`, `$BASH_VERSION`, `$EUID`, `$UID`, `$HOSTNAME`, `$OSTYPE` | unset / set | bashvar, seconds |
| `$_` | `true foo; echo "$_"` | from the environment / `foo` | underscore |
| `$-` (open) | `echo "$-"` | empty / `hBc`; but a test for `*i*` gives the same answer | dashvar |
| `$LINENO` | `echo "$LINENO"` | empty in `-c` and from stdin / `1`; dash's manual (0.5.12, Ubuntu's package) does not document `$LINENO` (checked 2026-11-19) | lineno (rule E as bash since 0.05) |

## <a id="my-section-5"></a>5. Both shells refuse, or misbehave alike (the basis with each)

- **`local` outside a function** (probe localout): both give an error. dash stops; bash goes on with the rest of the snippet (`local` is not a POSIX special builtin, so M:24 does not apply). Blatant (feature `scope` of [`tools/large-subset-features.pl`](tools/large-subset-features.pl)); the parser rejects it.
- **A special builtin's error** (probes shiftover, exportbad): `shift 3` with too few arguments, `export "1x=2"`. Both give an error; dash stops, bash goes on. The manual (M:24) says: "If a POSIX special builtin returns an error status, a non-interactive shell exits." So bash does not match its documentation: blatant, basis M:24. **❰BUG❱ bash 5.2.21** (known issue [X22](../pspawn-known-issues.md#my-x22)). `set -o nosuch` and `unset -x` do stop bash. This cannot be found from a snippet's text, so the detector does not flag it.
- **`kill -SIGHUP`** (probe killsig; basis M:38): both refuse. This matches bash's manual (M:38: "The `kill` builtin does not accept signal names with a `SIG` prefix"), so it is no bash bug. Both refusing: we refuse too. But the subset runs the program `kill`, which accepts the prefix; decided: R-refuse beats R-program (Q1, the user, 2026-11-03: "refusing is better"), so the parser rejects it ([`large-subset-state.md`](large-subset-state.md#my-section-2), section 2).
- **`>&3` with fd 3 not open** (probe dupnum): both refuse, with statuses 2 / 1. Counted **subtle** (J): the same refusal, differing only in the status. (By the decision "both shells refusing" of section 2 it would count as blatant; the judgement awaits the user.)

## <a id="my-section-6"></a>6. Subtle (basis: probe, except where marked J)

| Feature | Example | Where the results differ | Probe |
|---|---|---|---|
| `local x` without a value | `x=1; f(){ local x; echo "$x"; }` | dash keeps the outer value, bash empties it; matters only if `x` is read before it is set | local |
| `unset` of another function's local | `x=g; f() { local x=1; g; echo "f:[$x]"; }; g() { unset x; echo "g:[$x]"; }; f` | dash removes it; bash shows the outer value | unsetloc |
| `$@` assigned to a variable | `x=$@` | the separator, only when `IFS` does not start with a space | atjoin |
| an assignment with an expansion, plus a redirection (**J**) | `x=$(echo e >&2; echo v) 2>/dev/null` | dash redirects before expanding, bash after | (Y1 text) |
| `~` or `cd` with `HOME` unset | `unset HOME; echo ~` | only when `HOME` is unset | tildehome, cdhome (for `~`, the detector's feature `nohome`: rule E as bash since 0.05) |
| `${x:?msg}` | `echo ${zz:?unset}` | both stop when `x` is unset; status 2 / 127 | qmark |
| an assignment to a read-only variable | `readonly r=1; r=2` | both stop; status 2 / 127 | readonlyas |
| `command -v` of a missing command | `command -v nosuch` | status 127 / 1, false in both | cmdvst |
| `getopts` after a missing option argument | `getopts ab: o -b v; getopts ab: o -b v; echo "[$o] [$OPTARG] $OPTIND"` | `OPTARG` set / empty | getoptsend |
| listings | `set`, `export -p`, `readonly -p`, `trap` alone | quoting, extra lines | listset, listtrap, exportp |
| traces | `set -x` | quoting in the trace | setx |
| `set -m` | `set -m` | dash prints a warning; status 0 in both | setm |
| `$PS1` | `echo "$PS1"` | set in dash, empty in bash | ps1 |

## <a id="my-section-7"></a>7. No difference (probed)

`read -p`, `read -r`, `echo -n`, `echo --`, `printf %b`, `printf %.2f`, `kill -l 2`, `trap` with a number or `0`, `set -o vi`, `set -o emacs`, `break` and `continue` outside a loop, `local x=2` in a function, `umask -S`, `cd -` (`OLDPWD` set), `pwd -P`, `hash`, `command -p`, `ulimit -n`, `>|`, `<>`, `2>&-`, `$((x+=2))`, `$(…)` and `${#x}` inside `$((…))`, `$((010))`, `[ \( … \) -o … ]`, `[ a \< b ]`, `type NAME`, `command -V`, an alias used on the line that defines it.

## <a id="my-section-8"></a>8. The per-test record

[`t/parser/large-subset-shells.tsv`](../../t/parser/large-subset-shells.tsv) gives each test of the three parser test files one line (283 + 612 + 222 = 1,117 tests of [`t/parser/large-subset-tests.pl`](../../t/parser/large-subset-tests.pl), [`t/parser/shell-subset-corpus-tests.pl`](../../t/parser/shell-subset-corpus-tests.pl) and [`t/parser/shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl)):

| Column | Meaning |
|---|---|
| file | the test file |
| id | the test's snippet ID ([`doc/parsers/shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md)) |
| expected | `ok` or `rej`, as in the test file |
| parse | which shells parse the snippet (`-n`): `both`, `dash`, `bash` or `none` |
| verdict | `B` blatant, `S` subtle, `X` only differences that a program the subset runs (or a decision of the user) decides, `O` open (a postponed verdict; its basis reads `open`), `-` no difference found; a test with several features gets `B` if one of them is `B`, else `O` if one is open, else `S`, else `X` (`verdict` in the detector) |
| features | each difference found, as `id:verdict:basis`; for example, `echobs:X:P:echobs` or `dashflags:O:open` (a feature's id and its probe's need not be the same: `dashflags` was probed by `dashvar`) |
| note | a free-form verdict for this one test, if any |

It is made by [`doc/large-subset/tools/large-subset-features.pl`](tools/large-subset-features.pl) `-n`. That script holds the table of features: each feature's verdict, basis and the text pattern that finds it. It looks only at the snippet's text and at the shells' `-n`, never at the parser. Patterns can miss a use, or see one that is not there. Known misses so far: `x+=1`, `~+`, and `${1//…}`; the corpus measurement adds ShellCheck's codes, which catch these.

### <a id="my-the-totals"></a>The totals

The totals for the code labelled post4-0.04 (the labels: the table at the end of [`../README.md`](../README.md)), over 1,117 tests, each parsed by the large parser with no options:

| | the large parser accepts | rejects |
|---|---|---|
| both shells parse, no difference found | 719 | **108** |
| both parse, a blatant difference | 0 | 96 |
| both parse, a subtle difference | 1 | 15 |
| both parse, an open verdict (postponed) | 0 | 2 |
| both parse, only a class-X difference (a program the subset runs, or a decision of the user, also by rule E) | 60 | 8 |
| a shell refuses to parse it | 0 | 108 |

The totals for earlier code, as 12 counts in the order of the table above (row by row: accepts, then rejects):

- post3-0.04: 1,112 tests, 714 / 110 / 0 / 95 / 1 / 15 / 0 / 2 / 59 / 8 / 0 / 108;
- post2-0.04: 1,107 tests, 702 / 117 / 0 / 95 / 1 / 15 / 0 / 2 / 59 / 8 / 0 / 108;
- post-0.04: 1,104 tests, 698 / 118 / 0 / 95 / 3 / 15 / 0 / 2 / 57 / 8 / 0 / 108;
- 0.04: 1,092 tests, 689 / 121 / 0 / 97 / 3 / 16 / 0 / 3 / 48 / 7 / 0 / 108 as published; recounted with post-0.04's counting script, 690 / 120 / …, one test counted otherwise;
- 0.03: 1,066 tests, 667 / 126 / 0 / 102 / 4 / 18 / 3 / 9 / 28 / 1 / 0 / 108.

The **108** in bold (the first row) are the work list for the tests: both shells parse them and the detector finds no difference. For each, one of three holds: the large parser should accept it; the detector misses a difference (for example `${foo$n}`, which both shells parse but neither can run); or it is a deliberate rejection (many are, such as `ulimit -n 10`, `jobs -l`, or an alias inside a compound command). Examples: `pwd --help`, `cd -P -`, `exec` alone, `exit 07`, `# note` alone, and `${x:-~}`.

No test is accepted with a blatant difference any more: the 26 of the first count (code label early-post-0.02, 2026-11-02: code not kept, so not in the list above) were class X (`echo -e`, `[ a == b ]`, `printf -v`, `time`, `kill %1`), which the rule "the program beats the shells' difference" now covers.

A column `note` carries a free-form verdict for one test ("test:ID" in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt)); one is set: LS:299 (a test of `t/parser/large-subset-tests.pl`: functions named `cd`, `read`, `jobs` and `kill`, then called), verdict `-` (no difference), basis the probe fnkill (`kill() { echo K "$@"; }; kill -SIGHUP 1`; `- P:fnkill`).
