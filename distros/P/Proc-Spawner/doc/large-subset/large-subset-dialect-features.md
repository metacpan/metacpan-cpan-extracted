# Dash vs bash: features sorted by how the two shells differ

Prefix `large-subset-`. Started 2026-11-02, revised twice the same day after the user's reviews (the second time with bash's manual). This list replaces the sorting in item Y1 of the page "Shell Corpus Gaps".

## 1. The definition (the user's words, 2026-11-02)

A mismatch between dash and bash is **blatant** when:

> either one of them fails or does not match the docs; or they behave in blatantly different ways.

> Other mismatches in how dash/bash behave are "subtle".

The yardsticks measure features of the shells, never our parser:

- **Upper** ("nothing bogus"): both shells parse the sample (`dash -n`, `bash --posix -n`), and it uses no blatant feature.
- **Lower** ("compatible"): within the upper yardstick, and it uses no subtle feature either.

Where both shells agree, our parser must accept the form; for example, items P1–P4.

**Why Y1 was wrong.** Y1 sorted our parser's rejection messages, so the yardsticks depended on the parser they measure. It also paraphrased the definition as "one shell errors, or the result is clearly different", which is not what the user said.

## 2. Who decided each verdict

Every verdict carries a **basis**:

- **P:ID** (set in stone): a probe run in both shells shows it. ID names the probe in `doc/large-subset/dialect-cases/cases.txt` or `large-subset-dialect-probes2.txt`. Each probe runs in `dash -c` and in `bash --posix -c`, in a fresh empty folder, with stdin from `/dev/null`. A probe settles "one shell refuses what the other runs" and "the results differ".
- **P:-n** (set in stone): a shell refuses to parse the string.
- **M:N** (set in stone): item N of "Bash POSIX Mode" (section 6.11 of the Bash Reference Manual of bash 5.2.21, from the Debian package `bash-doc`; gnu.org is not reachable from Claude's workspace).
- **SC:CODE**: ShellCheck 0.11.0 says dash lacks the construct, so dash fails. Not probed one by one.
- **J** (a judgement by Claude, 2026-11-02, not yet reviewed by the user): the probe shows a difference, but whether it is blatant or subtle is not settled by the probe alone. Such verdicts are kept, as free-form text, in `tools/large-subset-verdicts.txt` and count as open until the user rules.

When the user rules on a verdict, `tools/large-subset-verdicts.txt` records the ruling in short form, with the basis "user"; no rescan is needed.

**Both shells refusing** (the user, 2026-11-02): "both shell refusing means that we should better refuse this too". Such forms are counted as blatant, so they stay outside both yardsticks.

**Class X** (the user, 2026-11-02): for the commands the subset runs as programs (`echo`, `printf`, `test`, `[`, `kill`, `time`), the program beats the shells' difference. Those differences are marked X and exclude nothing. The order of all rules is in `large-subset-state.md`, section 2.

dash 0.5.12 and `bash --posix` 5.2.21 throughout. In the tables, the dash and bash results are separated by "/".

## 3. Blatant: one shell refuses what the other runs (basis: probe)

| Feature | Example | dash / bash | Probe |
|---|---|---|---|
| arrays: list assignment, `${a[i]}`, `${#a[*]}`, `$PIPESTATUS` | `a=(x y); echo ${a[1]}` | syntax error or "Bad substitution" / works | array, pipestatus |
| assigning an array element | `a[1]=x` | "not found" / works | elemassign |
| `[[ … ]]` | `[[ a == a* ]]` | "not found" / works | dbracket |
| `(( … ))` as a command | `((x=1+1))` | a nested subshell, nothing printed / works | dparen |
| `for ((…))` | `for ((i=0;i<2;i++))` | syntax error / works | forarith |
| bash arithmetic operators | `$((2**3))`, `$((16#ff))`, `$((i++))`, `$((1, 2))` | arithmetic error / works | pow, base, incr, comma |
| bash parameter forms | `${x/b/X}`, `${x:1:2}`, `${x^^}`, `${x,,}`, `${!x}`, `${!a*}`, `${@:2}`, `${x@Q}` | "Bad substitution" / works | substr, caselower, indirect, prefixstar, atslice, atQ |
| process substitution | `cat <(echo hi)` | syntax error / works | procsub |
| here-string | `cat <<< hi` | syntax error / works | herestr, herestrq |
| `\|&` | `echo hi \|& cat` | syntax error / works | pipeamp |
| `>&` with a file name | `echo hi >&f` | "Bad fd number" / works | dupfile |
| a digit right after a duplication | `echo x >&2>f` | syntax error / works | redirdigit |
| `{fd}>` | `exec {fd}>f` | "not found" / works | fdvar |
| `function NAME` | `function f { …; }` | syntax error / works | function, fnparen |
| `select` | `select x in a; do …; done` | syntax error / works | select |
| `case` fall-through | `;&`, `;;&` | syntax error / works | casefall, caseamp |
| bash-only builtins | `source`, `declare`, `typeset`, `let`, `pushd`, `shopt`, `mapfile`, `coproc` | "not found" / works | source, declare, typeset, let, pushd, shopt, mapfile, coproc |
| `time` | `time true` | runs a program `time` (absent here: "not found") / keyword | time |
| bash `set` options | `-o pipefail`, `-o posix`, `-o history`, `-B`, `-H` | "Illegal option" / works | pipefail, setposix, sethist, setB, setH |
| `test` extensions | `[ a == a ]`, `[ -a f ]`, `[ -v x ]` | "unexpected operator" / works | testeqeq, testaun, testv |
| `printf` extensions | `%q`, `%(…)T`, `printf -v` | error / works | printfq, printfT, printfv |
| `read` options | `-n`, `-s`, `-t`, `-a`, `-d` | "Illegal option" / works | readn, reads, readt, reada, readd |
| `read` without a name | `read; echo "$REPLY"` | "arg count" / works | readreply |
| `jobs` in a pipeline or `$( )` | `sleep 1 & jobs \| wc -l` | 0 / 1 (dash lists nothing there) | jobspipe, jobsppipe, jobspsubst (post3-0.03) |
| `cd` with extra operands | `cd a b` | ignores `b` / "too many arguments", status 1 | cdargs (post3-0.03) |
| `type` options | `type -p ls`, `type -t ls` | looks up `-p` as a command / works | typep, typet |
| `wait -n` | `wait -n` | "Illegal option" / works | waitn |
| `export -f`, `export -n` | `export -f f` | "Illegal option" / works | exportf, exportn |
| `exec -a` | `exec -a foo cmd` | "not found" / works | execa |
| `local` options | `local -r x=1` | "bad variable name" / works | localr |
| bash signal names in `trap` | `SIGINT`, `ERR`, `DEBUG` | "bad trap" / works | trapsigint, traperr, trapdebug |
| job specs | `kill %1` after `cmd &` | "No such process" / works | job |
| a function named after a keyword or special builtin | `local() { …; }`; `source() { …; }` | syntax error / works; works / error | fnlocal, fnsource |
| a read-only bash variable as an assignment | `UID=5 echo hi` | works / "readonly variable" | uidset |
| `return` outside a function | `echo a; return; echo b` | ends quietly / error | return |

## 4. Blatant: both run it, the results differ (basis: probe, except where marked J)

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
| a pattern operator on `$@`, `$*` | `"${@#?}"` | on the joined string / on each | atpat |
| an escaped `"` in backquotes inside `"${…}"` | ``"${x:-`echo \"q\"`}"`` | `q` / `"q"` | bqdq |
| bash's own variables | `$RANDOM`, `$SECONDS`, `$BASH_VERSION`, `$EUID`, `$UID`, `$HOSTNAME`, `$OSTYPE` | unset / set | bashvar, seconds |
| `$_` | `true foo; echo "$_"` | from the environment / `foo` | underscore |
| `$-` (open) | `echo "$-"` | empty / `hBc`; but a test for `*i*` gives the same answer | dashvar |
| `$LINENO` (open) | `echo "$LINENO"` | empty in `-c` / `1`; that dash's manual documents it is unchecked | lineno |

## 5. Both shells refuse, or misbehave alike (all **J**)

- **`local` outside a function** (probe localout): both give an error. dash stops; bash goes on with the rest of the string (`local` is not a POSIX special builtin, so M:24 does not apply). Open verdict, in `tools/large-subset-verdicts.txt`.
- **A special builtin's error** (probes shiftover, exportbad): `shift 3` with too few arguments, `export "1x=2"`. Both give an error; dash stops, bash goes on. The manual (M:24) says: "If a POSIX special builtin returns an error status, a non-interactive shell exits." So bash does not match its documentation: blatant, basis M:24. **❰BUG❱ bash 5.2.21** (known issue X22). `set -o nosuch` and `unset -x` do stop bash. This cannot be found from a string's text, so the detector does not flag it.
- **`kill -SIGHUP`** (probe killsig): both refuse. This matches bash's manual (M:38: "The `kill` builtin does not accept signal names with a `SIG` prefix"), so it is no bash bug. Both refusing: we refuse too. But the subset runs the program `kill`, which accepts the prefix; which rule wins is a question in `large-subset-state.md`, section 2.
- **`>&3` with fd 3 not open** (probe dupnum): both refuse, with statuses 2 / 1. Counted **subtle**: the same refusal, differing only in the status.

## 6. Subtle (basis: probe, except where marked J)

| Feature | Example | Where the results differ | Probe |
|---|---|---|---|
| `local x` without a value | `x=1; f(){ local x; echo "$x"; }` | dash keeps the outer value, bash empties it; matters only if `x` is read before it is set | local |
| `unset` of another function's local | probe unsetloc | dash removes it; bash shows the outer value | unsetloc |
| `$@` assigned to a variable | `x=$@` | the separator, only when `IFS` does not start with a space | atjoin |
| an assignment with an expansion, plus a redirection (**J**) | `x=$(echo e >&2; echo v) 2>/dev/null` | dash redirects before expanding, bash after | (Y1 text) |
| `~` or `cd` with `HOME` unset | `unset HOME; echo ~` | only when `HOME` is unset | tildehome, cdhome |
| `${x:?msg}` | `echo ${zz:?unset}` | both stop when `x` is unset; status 2 / 127 | qmark |
| an assignment to a read-only variable | `readonly r=1; r=2` | both stop; status 2 / 127 | readonlyas |
| `command -v` of a missing command | `command -v nosuch` | status 127 / 1, false in both | cmdvst |
| `getopts` after a missing option argument | probe getoptsend | `OPTARG` set / empty | getoptsend |
| listings | `set`, `export -p`, `readonly -p`, `trap` alone | quoting, extra lines | listset, listtrap, exportp |
| traces | `set -x` | quoting in the trace | setx |
| `set -m` | `set -m` | dash prints a warning; status 0 in both | setm |
| `$PS1` | `echo "$PS1"` | set in dash, empty in bash | ps1 |

## 7. No difference (probed)

`read -p`, `read -r`, `echo -n`, `echo --`, `printf %b`, `printf %.2f`, `kill -l`, `trap` with a number or `0`, `set -o vi`, `set -o emacs`, `break` and `continue` outside a loop, `local x=2` in a function, `umask -S`, `cd -`, `pwd -P`, `hash`, `command -p`, `ulimit -n`, `>|`, `<>`, `2>&-`, `$((x+=2))`, `$(…)` and `${#x}` inside `$((…))`, `$((010))`, `[ \( … \) -o … ]`, `[ a \< b ]`, `type NAME`, `command -V`, an alias used on the line that defines it.

## 8. The per-test record

`t/parser/large-subset-shells.tsv` gives each test of the four parser test files one line:

| Column | Meaning |
|---|---|
| file | the test file |
| id | the test's snippet ID (`doc/parsers/shell-subset-test-provenance.md`) |
| expected | `ok` or `rej`, as in the test file |
| parse | which shells parse the string (`-n`): `both`, `dash`, `bash` or `none` |
| verdict | `B` blatant, `S` subtle, `X` only differences that a program we run decides, `O` open (a postponed verdict), `-` no difference found |
| features | each difference found, as `id:verdict:basis`; for example, `echobs:X:P:echobs` or `scope:O:open` |
| note | a free-form verdict for this one test, if any |

It is made by `doc/large-subset/tools/large-subset-features.pl -n`. That script holds the table of features: each feature's verdict, basis and the text pattern that finds it. It looks only at the string's text and at the shells' `-n`, never at our parser. Patterns can miss a use, or see one that is not there. Known misses so far: `x+=1`, `~+`, and `${1//…}`; the corpus measurement adds ShellCheck's codes, which catch these.

Totals for 0.04, over 1,092 tests, each parsed by the large parser with no options (0.03: 1,066 tests, 667 / 126 / 0 / 102 / 4 / 18 / 3 / 9 / 28 / 1 / 0 / 108 in the order of this table):

| | the large parser accepts | rejects |
|---|---|---|
| both shells parse, no difference found | 689 | **121** |
| both parse, a blatant difference | 0 | 97 |
| both parse, a subtle difference | 3 | 16 |
| both parse, an open verdict (postponed) | 0 | 3 |
| both parse, only a class-X difference (a program we run, or a decision of the user, also by rule E) | 48 | 7 |
| a shell refuses to parse it | 0 | 108 |

The **121** are the work list for the tests (many are deliberate rejections, such as `ulimit -n 10`, `jobs -l`, or an alias inside a compound command): both shells parse them and the detector finds no difference, so either our parser must accept them, or the detector misses a difference (for example `${foo$n}`, which both shells parse but neither can run). Examples: `pwd --help`, `cd -P -`, `exec` alone, `exit 07`, `# note` alone, and `${x:-~}`.

No test is accepted with a blatant difference any more: the 26 of the first count (early-post-0.02, 2026-11-02) were class X (`echo -e`, `[ a == b ]`, `printf -v`, `time`, `kill %1`), which the rule "the program beats the shells' difference" now covers.

A column `note` carries a free-form verdict for one test ("test:ID" in `tools/large-subset-verdicts.txt`); none is set yet.
