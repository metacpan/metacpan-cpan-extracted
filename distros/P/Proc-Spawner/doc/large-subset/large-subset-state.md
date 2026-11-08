# The large subset: the state of the union (0.09, 2026-11-08; its figures are those of post4-0.04)

This document summarises where `Proc::ShellSubset::Large` (the large parser) stands against dash and bash. Section 1 gives the rules, section 2 the order in which the rules apply, section 3 the figures, section 4 the work list (forms the shells agree on that the parser still rejects), sections 5 and 6 the subtle and the blatant differences, and section 7 whether the accepted samples behave as in the shells. It replaces the yardsticks of `large-subset-ceiling.md` (in Proc-Spawner 0.03), section 6, which sorted our parser's own rejection messages and so measured the parser against itself.

Every figure here is of post4-0.04 (since post3-0.04: bracket expressions with quotes, expansions or `/`, `* ? [` in a `${x:-word}`, `unset NAME[…]` rejected and the detector's feature `unsetarr`. Since post2-0.04: aliases known only when they run (P1), `[ s1 < s2 ]` (rule F). Since post-0.04: `read` with a name from an expansion, `${##}`, 14 noise samples left out by hand, the detector's rows N1–N3. Since 0.04: 3A, functions before regular builtins; the rule-E choices G4, G8, G15, G16 and `break`/`continue` in a subshell; `jobs %N`; X25 fixed. Since 0.03: item P6, `pwd`, rule E and its first choices, more forms both shells run alike, X19 fixed, detector fixes; `../../Changes`) unless it names another version (the labels: [`../README.md`](../README.md), last section). Shells: dash 0.5.12 and `bash --posix` 5.2.21. "The manual" means the Bash Reference Manual of bash 5.2.21, section 6.11 "Bash POSIX Mode", taken from the Debian package `bash-doc`; "M:N" names its item N. Where this document cites a probe ("P:ID"), the probe's ID is in [`dialect-cases/cases.txt`](dialect-cases/cases.txt) or [`dialect-cases/large-subset-dialect-probes2.txt`](dialect-cases/large-subset-dialect-probes2.txt).

## 1. The rules (the user's, 2026-11-02)

- **R-agree.** Where dash and bash agree, the subset must accept the form and behave as they do.
- **R-refuse.** Where both shells refuse a form, the subset refuses it too. "Refuse" covers both a syntax error (`-n`) and an error when the form runs. Forms both shells refuse count as blatant, where the detector can see them (it cannot see errors that happen only at run time, such as `${foo$n}`).
- **R-blatant.** A difference is **blatant** when "either one of them fails or does not match the docs; or they behave in blatantly different ways". Any other difference in how dash and bash behave is **subtle**.
- **Rule F** (the user, 2026-11-03): "When a shell grabs a util but implements it wrong, we should be free to do 'better'." Where a utility (as the program, or as a shell's builtin) behaves wrongly, R-program does not bind us: we take the better behaviour, by the categories of rule E. First use (post3-0.04): `[ s1 \< s2 ]` and `[ s1 \> s2 ]`, which both shells run and POSIX 2024 specifies, but the coreutils program refuses: the executor compares them itself (item 2 below).
- **R-program.** For the commands the subset runs as programs (`echo`, `printf`, `test`, `[`, `kill`, `time`, `pwd`, and `true`, `false`, where the shells agree anyway; `pwd` runs as `/bin/pwd -L`, which prints what both shells print, known issue X23; the base parser's specification, [`doc/parsers/shell-subset-spec.md`](../parsers/shell-subset-spec.md), section 4), the program beats any difference between the shells' builtins. "`test` beats blatant" was decided under item P5 of "Shell Corpus Gaps"; the user extended it to this list on 2026-11-02. In the measurement files these differences are class **X**, together with the differences that a decision of the user settles: the interactive-only builtins (`history`, `fc`, `bind`, `help`, `compopt`, `logout`, `set -o history`) do nothing, by decision B2.
- **The yardsticks.** **Upper** ("nothing bogus found"): both shells parse the sample (`dash -n`, `bash --posix -n`), and it uses no blatant difference. **Lower** ("compatible"): within the upper yardstick, and it uses no subtle difference either. A class-X difference excludes nothing.
- **Who decided.** Every verdict names its basis: P:ID (a probe), M:N (the manual), SC:CODE (ShellCheck says dash lacks the construct, so dash fails), J (Claude's judgement, not yet reviewed), or "user". J verdicts are kept as postponed text, so they count as open. Postponed verdicts are free-form text in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) and count as **open** (O): outside the lower yardstick, inside the upper one. They can be rewritten in short form later without a rescan.

**What the rules are for (the user, 2026-11-05).** The rules above and the order of section 2 were a quick triage: they brought the count of failures down to where decisions can be made one by one, and they classify the rest. They are now mostly of historical interest: they are not to be overhauled, because every change of a rule means running every test and measurement again. New decisions are made case by case, each named (like K0 below), and the classification of what is left is the line of Perl code that handles it.

**Two principles of least surprise, in conflict (the user, 2026-11-05).** For a command the subset runs as a program (`echo`, `printf`, `test`, `[`, `kill`, `pwd`):
1. A call to a tool inside a larger script should give the same result as the same call typed alone (so: the program, whatever the shells' builtins do).
2. A tool may treat edge cases that hardly ever occur when it is called alone in its own way (an empty list of arguments, as `kill $(pgrep x)` gives when nothing matches); inside a script, such a case is common, and there the shells' behaviour is what a script expects.

In the best world the tool would have a switch (say `--strict`) that makes it behave non-interactively, and the subset could leave the work to that flavour; even then, a switch raises its own question (how should the tool treat an operand that is named `--` or `--strict`?). Short of that, the user sees no solution but **a global default that can be flipped, plus a per-tool list of decisions**, so that the choice is left to the caller. Not implemented yet: today the default is the program (R-program), and the per-tool decisions are:

| Decision | Tool | The case | dash / bash / the program | The subset |
|---|---|---|---|---|
| K0 (the user, 2026-11-05) | `kill` | a signal (`-N`, `-NAME`, `-s NAME`) or `--`, and no process ID | usage, status 2 / usage, status 2 / long usage, status 1 | as both shells: dash's text, status 2 (`kill -s` alone, where the shells differ, stays with the program) |
| rule F (the user, 2026-11-03) | `test`, `[` | `s1 \< s2`, `s1 \> s2` alone | 0 or 1 / 0 or 1 / "binary operator expected", 2 | as both shells, compared by bytes |
| Q2, choice B (the user, 2026-11-03) | `printf` | `printf -v NAME …` | "Illegal option", 2 / sets NAME / prints `-v`, warns | the program |
| Z0 (the user, 2026-11-05) | `printf` | `printf '%0.s-'` (a common way to repeat `-`) and every `0` flag with `%s`, `%c`, `%b` (`%0s`, `%05s`) | as glibc's `printf(3)`: the flag ignored (`%05s` pads with blanks), 0 / the same / "invalid conversion specification", 1 | as both shells: the flag is dropped from the format before the program runs (`Proc::ShellSpawn::printf_zero`) |

On `%0.s` (checked 2026-11-05): the `0` flag is defined only for numeric conversions; "For other conversions, the behavior is undefined" (the Linux `printf(3)` page, as C11 7.21.6.1 and POSIX's File Format Notation, which the `printf` utility uses). The glibc manual, on `%s`: "The `-` flag can be used to specify left-justification in the field, but no other flags or type modifiers are defined for this conversion." glibc ignores the flag (gcc warns: "'0' flag used with '%s'"); dash and bash pass the format to it. coreutils 9.4 rejects it on purpose (`src/printf.c`: `case '0': ok['c'] = ok['s'] = 0;`), although its manual, which lists how its `printf` differs from C's, does not say so. So all three are within the standard; dash and bash do what the C library does.
| `$$` (F9) | `kill` | a process ID that is the shell's own | the shell takes the signal | as both shells (also `kill -0 $$` and the signals that do nothing by default, post4-0.04) |

The answers of all three for every call the corpus makes: [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) (section 7).

## 2. Which rule beats which

Proposed order, highest first. Items marked **(question)** need the user's decision.

1. **R-refuse beats R-program** (the user, 2026-11-03: "refusing is better"; Q1 of "Shell Corpus Gaps"). `kill -SIGHUP PID`, `kill -s SIGHUP PID`, `kill -l SIGHUP` and `kill -sighup PID`: both shells refuse the `SIG` prefix (dash: "Illegal option -S"; bash as its manual says, M:38), while the program `/usr/bin/kill` accepts it. The parser rejects them (tests LS:246–250).
2. **Rule F against R-program.** `[ a \< b ]`: both shells answer 0, but the coreutils program fails ("binary operator expected"). Item R1 of "Shell Corpus Gaps" had settled this with a caller's option (`test_lt_gt`); since post3-0.04, rule F: `s1 < s2` and `s1 > s2` alone (also after `!`) are compared by the executor, by bytes, as both shells; longer expressions with `<` or `>` stay rejected unless the caller sets `test_lt_gt` (then the program runs them, and fails).
3. **R-program beats R-blatant and subtle differences.** `echo 'a\nb'`: dash prints two lines; bash and `/bin/echo` print `a\nb`. The subset accepts it and prints `a\nb`.
4. **A program result that is itself bogus (question Q2 of "Shell Corpus Gaps").** `printf -v x %s hi`: bash sets `x`, and dash fails. The coreutils program prints `-v` and a warning about excess arguments, which matches neither shell and serves no purpose. Decided (Q2, the user's choice B, 2026-11-03): it stays with the program, as R-program says. Also `[ -v NAME ]` and unary `[ -a FILE ]`: bash answers, while dash and coreutils fail with different messages. Under R-program the subset fails like coreutils; no change is proposed for these.
5. **Rule E** (the user, 2026-11-03; it replaces R-blatant): where the shells differ, the subset takes the plainly logical behaviour, and rejects the form only where there is none. Each choice names a category (info, error, posix, same, harm, platform, meaning, effect, or none): [`large-subset-logical.md`](large-subset-logical.md). The detector counts a difference settled by rule E as class X (basis `E:CATEGORY`).
6. **Subtle differences:** rule E decides them too, item by item in [`large-subset-logical.md`](large-subset-logical.md) (until 0.03 the page "Shell Dialect Choices" did, by default by rejecting).

**Windows.** R-program assumes the programs exist: coreutils `[`, `/bin/echo`, `printf`, `kill`. A Windows port of `Proc::ShellSpawn` would lack them. It would then have to give the same answers itself (emulate the coreutils behaviour in Perl) or reject these commands. Until then, the rule ties the subset to POSIX systems with coreutils; this is recorded as known issue X21 in [`doc/pspawn-known-issues.md`](../pspawn-known-issues.md).

## 3. The figures

Measured with post4-0.04 over the pinned corpora (fetched again on 2026-11-04, both checksums matching; the stored scan reproduced the figures of post3-0.04 exactly before the change) ([`doc/test-pools.md`](../test-pools.md)): 41,952 samples after leaving out 14 samples marked as noise by hand ([`tools/large-subset-noise.txt`](tools/large-subset-noise.txt), post2-0.04: tldr placeholders such as `exit exit_code`, tldr alternatives written `a|b|c`, NL2Bash here-documents cut off), 2,719 duplicates, the make book (578, a noisy extraction), 163 tldr lines made only of keystrokes, 59 tldr lines with keystrokes next to other text (Y3), and 16 ShellCheck test strings that are wrong where they stand (`return`, `local`, `break` outside their function or loop, which ShellCheck's own tests mark as errors). They were taken on the unreleased post4-0.03 and checked again on 0.04 (the same per-sample results). The figures of 0.03 itself are in this document as shipped in the Proc-Spawner-0.03 distribution.

| Source | Samples | Accepted | Lower | Upper | Rejected within lower | Rejected, subtle or open | Accepted outside upper |
|---|---|---|---|---|---|---|---|
| tldr | 29,440 | 99.3% | 99.3% | 99.3% | 7 | 5 | 1 |
| NL2Bash | 10,620 | 94.5% | 94.6% | 94.8% | 9 | 23 | 1 |
| bash Cookbook | 81 | 32.1% | 30.9% | 35.8% | 0 | 3 | 0 |
| pure-sh-bible | 44 | 97.7% | 97.7% | 100.0% | 0 | 1 | 0 |
| pure-bash-bible | 122 | 40.2% | 41.8% | 41.8% | 2 | 0 | 0 |
| ShellCheck, clean | 879 | 63.3% | 64.8% | 65.6% | 14 | 7 | 0 |
| ShellCheck, warned | 766 | 60.7% | 62.1% | 62.3% | 12 | 1 | 1 |

The samples rejected within the lower yardstick: 304 with early-post-0.02 (2026-11-02), 163 with 0.03, 117 with post-0.03, 106 with post3-0.03, 95 with 0.04, 91 with post-0.04 (functions named `cd`, `continue` in a subshell in a loop), 72 with post2-0.04 (14 samples marked as noise; `read` with a name from an expansion and `${##}` accepted; and the detector counts the decided rows N1–N3 of [`large-subset-logical.md`](large-subset-logical.md) (`${x:?}`, a special builtin's error, `command -v`) as class X, which brings a few samples inside the lower yardstick), 49 with post3-0.04 (aliases known only when they run, `[ s1 < s2 ]`), 44 now (post4-0.04: bracket expressions with quotes or `/` and `${1:-sure? [y/N]}` accepted, 3 samples; `unset foo[$i]`, 2 samples, now seen by the detector as blatant (feature `unsetarr`), and rejected; the ShellCheck percentages fall a little, because 5 such samples were accepted until post3-0.04, wrongly: known issue X26). Rule E settles more samples as class X (the choices of [`large-subset-logical.md`](large-subset-logical.md); detector basis `E:CATEGORY`), and the detector now sees three blatant differences it missed in 0.03 (`set -euo pipefail`, `cd a b`, `jobs` in a pipeline: the last two now settled by rule E). The parser accepts 339 samples whose only differences are class X (post3-0.04, recounted: 338) (programs, the interactive builtins of B2, and rule E).

The 3 samples **accepted outside the upper yardstick** are misreadings by the detector, not parser errors: `$(( ((1+1)) ))` taken for the command `((`, an assignment `source=…`, and `time read` (the program `time` running the program `read`).

With the pinned corpora and these shells, the figures depend only on the parsers, the measurement scripts and the verdicts. The sha256 of those files, concatenated (`cat lib/Proc/ShellSubset.pm lib/Proc/ShellSubset/*.pm doc/large-subset/tools/large-subset-{extract,scan,drops,features,yardsticks}.pl doc/large-subset/tools/large-subset-verdicts.txt doc/large-subset/tools/large-subset-noise.txt | sha256sum`), is `80e40b1ce413ea4c39203a0c5bbd134b800477da8641dca26dc55aa01e693d41` (0.09, which differs from post4-0.04 only in `$VERSION`; 0.08: `3956c46c16d3290baf27f9475da8b72d431f17a194b2ba9fba91e3e0fe863bb8`; 0.07: `3f1c152adeabd6730535ae4380824c41e45c896190d612e75e08f956c15af270`; 0.06: `c19ac884428cba12a90ff7e8d1bfc4dba7b540e621dc72062563a5ce4ec950b1`; 0.05: `743121ae0b5fb7af55b5308fb51c3db9cf61ca74ec2d3a40e98a3dc6cca634cd`; post4-0.04: `aa2734f2147be58073d44713de7f003cdee525f593d5e90f70f9f64e900f08bc`; post3-0.04: `b189e43efd804af3e15e4224d2e7f46a890d7723301dd792fd9094ec8aaf6c59`; post2-0.04: `a23490770df33a87e8cbc1008d7d7301c7bcf567cb56bd2d5b5e13a94e0c4636`; before post2-0.04 the noise list did not exist and was not part of the command: post-0.04 `1b9eac74d672e79d89764f71b1a6125e4a52f4cdc42943a6db39ec3d0b6d95aa`, 0.04 `ecde8b9b9610680560a69e56313f01687f29e51688bcd029c6cef837fa03eeac`). While it is unchanged, the figures hold without measuring again.

## 4. Still rejected although the shells agree (the work list)

There are 44 samples: 42 with no difference found, and 2 whose only differences are class X. By the parser's message (post4-0.04):

| Count | What | Where it is decided |
|---|---|---|
| 2 | `alias :='xargs -I{}'`, `alias p=php -E '$o = …'` (a literal word with `=` that is no alias name) | rejected by B1; since post3-0.04 every word with an expansion, and `alias` anywhere, is accepted (P1: 20 samples until then) |
| 12 | `${foo$n}`, `${{var}`, `${${x%.*}##*/}`, `${ cmd; }` and the like | both shells parse them but fail when they run ("Bad substitution"): right by R-refuse; the detector cannot see run-time failures (`${##}` and `${#!}`, which both shells run, are accepted since post2-0.04). POSIX documents the failure: XCU 2.8.1 calls such a form an **expansion error** (its example: `${x!y}`, "because '!' is not a valid operator"), after which a non-interactive shell shall exit; this covers `${foo$n}`, `${var${n}_…}`, `${${x%.*}##*/}`, `${$(x)//x/y}`, `${1~~}`, `${args[@]@Q}` (a name, then no valid operator). For `${{var}`, `${ cmd; }`, `${.sh.version}` (a first character that is neither a name, a digit nor a special parameter), XCU 2.6.2 says the behaviour is **unspecified**: left to each shell (bash 5.3 and ksh give `${ cmd; }` a meaning). |
| 4 | `read` with an array element, `''`, or zsh's `NAME?prompt` | not POSIX names (a name from an expansion, `read $var`, is accepted since post2-0.04 and checked when it runs) |
| 4 | `ulimit` setting a limit, or `-a` | B3 reads limits only |
| 3 | `NAME[` as a command | bash arrays |
| 4 | `set -o` alone (it lists, 2), and the `set` of other programs (tmux's `set -g`, fish's `set -U`) | stay rejected |
| the rest (15) | `_` as a variable (2), `export foo[$bar]=3`, `export ${foo?}`, `exit -1`, `pwd --help`, `ls ~-`, `hash -v`, `cmd >& $var`, `.` alone, `unset -f ls /bin/ls`, … | one by one |

Bracket expressions with a quote, an expansion or `/` (`grep ^[\>\<]`, `something[^/]*`), 4 samples until post3-0.04, are accepted since post4-0.04; of those 4, `unset foo[$i]` and `unset foo[x${i}y]` are bash's arrays (feature `unsetarr`, blatant). Checked by hand on 2026-11-04, both shells agree on these, so they are gaps of the parser still: `alias :='…'` (an alias named `:`), `export ${foo?}`, `command -` ("not found", 127) and `unset -f ls /bin/ls` (status 0, nothing done). `alias p=php -E '…'` agrees too (both: `-E` and the rest are names to print, "not found", status 1), apart from the message's wording.

Samples marked as noise by hand (14, [`tools/large-subset-noise.txt`](tools/large-subset-noise.txt)) no longer count: the tldr placeholders `exit exit_code`, `jobs %job_id`, `wait instance_id`, `wait process_id`, `wait %job_number`, `shift n`, `return exit_code`, NL2Bash's `exit N`; the tldr alternatives `duf --sort mountpoint|size|…`, `mate-search-tool --sortby=name|folder|…`, `winedump dump -j import|export …`; and the 3 NL2Bash here-documents whose body was cut off (`ssh host <<'EOF'` with nothing after).

## 5. Subtle differences and open verdicts

**Between the shells** (0.04: 58 samples have a subtle difference as their worst one, 4 an open verdict). The counts per feature below include samples that also have a blatant difference, so they add up to more:
- listings (`set`, `export -p`, `trap` alone), also the order of the `alias` listing: 33;
- `local x` without a value: 18;
- traces (`set -x`): 7;
- `${x:?}` statuses, `command -v` statuses, `$PS1`: a few each.

Open verdicts (postponed, free-form in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt)): `$-` (rule E: no plainly logical choice). `$LINENO` is settled since post-0.04 (rule E: as bash, the line number). The other two of Q3 are settled by rule E: `return` outside a function is an error (as bash), and settings with a redirection are redirected first (as dash); `local` outside a function stays rejected, as both shells fail.

**Between the shells and the programs or decisions (class X):**
- `echo`: like bash.
- `[ -v ]`, unary `[ -a ]`: coreutils fails like dash, unlike bash.
- `[ a \< b ]`: coreutils fails, unlike both shells (R1: the option `test_lt_gt`).
- `printf %q`: coreutils quotes as `'a b'`, bash as `a\ b`, and dash fails.
- `printf -v`: decided (Q2, choice B, 2026-11-03): the program `printf` runs it.
- Rule E ([`large-subset-logical.md`](large-subset-logical.md)): `jobs` in a pipeline or `$( )`, `return` outside a function, `cd` with extra operands or without `HOME`, descriptors above 9, `[^…]`, patterns that never match `.` or `..`, settings with a redirection, `getopts` leaving `OPTARG` unset.
- `time`: the program `/usr/bin/time`. It is not installed in Claude's workspace, so `time cmd` fails there with "not found", as in dash, which has no `time` builtin either.
- `history` and the other interactive-only builtins (B2): nothing, as bash mostly does; dash has none of them ("not found"). The caller can choose dash's behaviour (`interactive => 'dash'`) or rejection (`interactive => 'reject'`).

## 6. Blatant differences

With 0.04, 1,455 samples are outside the upper yardstick (0.03: 1,463): 520 because a shell refuses to parse them, the rest because of a blatant difference. Except for the 3 detector misreadings of section 3, the parser rejects them all. The most frequent features:
- bash-only builtins (`source`, `declare`, `let`, …);
- process substitution;
- arrays;
- `[[ … ]]`;
- options of `read`, `local` and `type` that dash lacks;
- `$'…'`;
- brace expansion;
- `(( … ))`.

**❰BUG❱ bash 5.2.21:** M:24 says "If a POSIX special builtin returns an error status, a non-interactive shell exits". In `bash --posix -c`, `shift 3` with fewer arguments and `export "1x=2"` print an error, return 1, and the shell goes on. `set -o nosuch` and `unset -x` do exit (status 2). This is a blatant difference by the definition ("does not match the docs"); known issue X22 in [`doc/pspawn-known-issues.md`](../pspawn-known-issues.md). The subset rejects these forms at parse time where it can see them; where it cannot, the executor follows dash and stops.

## 7. Behaviour: the accepted samples run in dash, bash and ours (post4-0.04)

Sections 3 to 6 say only which samples the parser accepts. This section says whether the accepted ones then **do** what the shells do. Until post4-0.04 nobody had checked that over the corpus: the only checks of behaviour were the batteries ([`t/batteries/`](../../t/batteries), compared with dash alone) and [`doc/parsers/tools/verify.pl`](../parsers/tools/verify.pl) (argv only, the base parser, 2026-10-29).

**How.** [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) runs each of the 40,410 samples the parser accepts three times: in dash, in `bash --posix` and in `Proc::ShellSpawn` ([`t/try.pl`](../../t/try.pl)). Each run starts in a fresh copy of the same small directory (a few files, so that patterns match something), as an unprivileged user of its own, with no network, a 5-second timeout and limits on CPU, file size and processes. `PATH` holds recorders for every program on the system: each logs its name and arguments; the tools that only read or print (`cat`, `grep`, `sed`, `awk`, `sort`, …) then really run, and the programs the subset runs in place of builtins (`echo`, `printf`, `test`, `[`, `true`, `false`, `pwd`, `kill`) run without being logged, as the shells' builtins leave no log. `rm`, `mv`, `cp`, `ln` are only logged. [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl) compares the exit status, standard output, the programs called with their arguments (sorted: pipeline elements run at once), the files left in the directory, and separately the messages: standard error, with each shell's own prefix taken off (`dash: 1: `, `bash: line 1: `, `sh: `), compared as a multiset of characters, because the shells write the messages of pipeline elements in pieces that mix. About 21 minutes with 4 workers. Limits: known issue X27.

The classes: **same** (all three agree); **messages only** (status, output, programs called and files agree in all three, the messages differ: ours worded as dash's, as bash's, or as neither); **ours differs** (dash and bash agree, ours does not, beyond the messages); **shells differ** (dash and bash differ beyond the messages; ours agrees with dash, with bash, or with neither); **timeout**.

**"Coreutils involved"** means that a program the subset runs in place of a builtin (`echo`, `printf`, `test`, `[`, `kill`, `pwd`) takes part: ours handed it a call (seen by [`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-q`, which logs these too and the caller of each), or its name stands where a command does (this catches the calls ours answers itself: K0, rule F, `kill $$`). A call that another program makes (`… | xargs kill`) does not count: there every shell runs the program.

| Samples | Run | Same | Messages only: as dash | as bash | as neither | **Ours differs** | Shells differ: ours as dash | as bash | as neither | Timeout |
|---|---|---|---|---|---|---|---|---|---|---|
| coreutils involved | 1,344 | 892 | 266 | 0 | 47 | **5** | 47 | 58 | 26 | 3 |
| no coreutils | 39,066 | 14,859 | 23,005 | 34 | 44 | **2** | 924 | 40 | 144 | 14 |
| all | 40,410 | 15,751 | 23,271 | 34 | 91 | **7** | 971 | 98 | 170 | 17 |

By source (all samples): tldr 29,232 run, 1 where ours differs; NL2Bash 10,039, 4; ShellCheck 1,021, 2; the bash Cookbook 26, pure-sh-bible 43, pure-bash-bible 49: none. The first run (before the fixes of post4-0.04) found 57 where ours differs; K0 alone removed 29 of them.

**Where dash and bash agree and ours differs (7):** `printf -v` (2; decided, Q2 choice B: the program runs it); `printf '%0.s-'` (1; open, section 1); `(echo …; sleep 1; echo …) | zenity`, where `zenity` is missing and exits at once: in the shells the builtin `echo` writing to the broken pipe kills the whole subshell, in ours only the program `echo` dies and the subshell goes on (a consequence of running the program); and 3 that depend on chance: `{ echo foo; cat bar; } | tee bar` (a race), `/dev/urandom`, `ls -l /` (times of directories that changed between the runs).

**Messages worded as neither (91):** with coreutils (47), the programs' own messages (`[: missing ']'` against dash's `[: missing ]`, `printf: warning: ignoring excess arguments`, `kill: (1): Operation not permitted`); without (44): the interactive builtins (B2: nothing, where dash says "not found" and bash complains), `exec foo` (dash: `exec: foo: not found`, ours: `foo: not found`, the kind of known issue X5), an empty command name (dash: `: Permission denied`, bash: `: command not found`, ours: `: not found`).

**Where the shells differ:** ours as dash (971): 924 are statuses of errors at run time (rule A5, as dash), above all a redirection into a directory that does not exist (`> path/to/out.html`: dash 2, bash 1); the rest features already decided (`time`, `[ -v ]`, `${x:?}`, …). Ours as bash (98): the interactive builtins (B2), `echo -e` and `echo 'a\nb'` (the program), rule-E choices (`return` outside a function, `[^…]`, `.*`, `$LINENO`), `kill` with a word that is no process ID (the program's status 1, as bash; dash 2). Ours as neither (170): mostly runs that cannot agree: `$0` (`dash`, `bash`, `sh`), `date`, `/dev/urandom`, `times`, `$$`, `mkdir /tmp/x` (`/tmp` is shared, so the second shell finds the first one's directory); also `help` (B2) and `time` (no `/usr/bin/time` here).

**Timeouts (17):** 15 never end, in all three shells (endless loops, `tail -F`, `cat /dev/urandom | …`, `grep -R … /`, `yes | sed -n '200000000,…'`); 2 of them ended in dash by the file-size limit first (signal 25), as dash writes its endless messages faster. In one only ours ran out of time: `tail -F xxxx | tee -a yyyy &` (at the end of the string Perl waits for background jobs: known issue X1).

### The atomic calls: dash's builtin, bash's builtin and the program

[`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) takes every distinct call that ours made to `echo`, `printf`, `test`, `[`, `kill` or `pwd` in the run above (`-q`; 757 calls; another 89 made by `xargs` are left out, since there every shell runs the program) and runs it three ways: `dash -c '"$@"' sh NAME ARGS…`, the same with `bash --posix`, and the program alone. Every call with its three answers: [`tools/large-subset-threeway-db.jsonl`](tools/large-subset-threeway-db.jsonl) (the database); those where the three do not agree: [`tools/large-subset-threeway-differences.tsv`](tools/large-subset-threeway-differences.tsv). "Samples" counts the samples that make the call.

| Who agrees | Calls | Samples |
|---|---|---|
| all three | 620 | 1,107 |
| all three, but for the messages | 42 | 46 |
| dash = bash, the program differs | 3 | 3 |
| dash = the program, bash differs | 12 | 14 |
| bash = the program, dash differs | 72 | 89 |
| all three differ | 8 | 9 |

| Tool (samples) | Same | Messages | dash = bash ≠ program | dash = program ≠ bash | bash = program ≠ dash | All differ |
|---|---|---|---|---|---|---|
| `echo` | 692 | 0 | 0 | 0 | 66 | 0 |
| `[` | 167 | 39 | 0 | 13 | 6 | 0 |
| `test` | 24 | 2 | 0 | 1 | 1 | 0 |
| `printf` | 137 | 2 | 3 | 0 | 3 | 7 |
| `kill` | 0 | 3 | 0 | 0 | 13 | 2 |
| `pwd` | 87 | 0 | 0 | 0 | 0 | 0 |

What they are: `echo` (66): `echo -e`, `echo -n -e`, and backslashes (`'a\nb'`, `\5a`): dash's builtin interprets them and prints `-e`, bash and the program do not. `[`, `test`, dash = program (14): the unary `-a`, `-o`, `-v`, `-R`, which bash alone has; bash = program (7): `==` and `-N`, which coreutils takes as bash does. `kill`, bash = program (13): a word that is no process ID, or `%1`: dash status 2, bash and the program 1; all differ (2): `kill -l`. `printf`: dash = bash (3): `%0.s` and `-v` (2); bash = program (3): `%q`, `\x` escapes; all differ (7): `%(…)T` and `-v`. `kill` with no process ID no longer reaches the program (K0), so it is not in the table.

### The atomic calls of external programs

[`large-subset-runreport.pl`](tools/large-subset-runreport.pl) `-x`: every sample that calls an external program (not one of the coreutils above), with the programs it called and their arguments compared as a sorted list, in the classes of the main table. "Dash's calls" counts the calls dash made in those samples.

| Samples | Run | Same | **Ours differs** | Shells differ: ours as dash | as bash | as neither | Timeout |
|---|---|---|---|---|---|---|---|
| coreutils involved | 679 | 658 | **1** | 0 | 4 | 14 | 2 |
| no coreutils | 15,697 | 15,617 | **0** | 15 | 4 | 52 | 9 |
| all | 16,376 | 16,275 | **1** | 15 | 8 | 66 | 11 |
| dash's calls in them | | 22,341 | 1 | 8 | 15 | 120 | 1,090 |

Where dash and bash make the same calls (16,276 samples, 22,342 calls), ours makes every one, with the same arguments, and one more: the second `sleep 1` of `(echo …; sleep 1; echo …) | zenity`, where the program `echo` dies of the broken pipe and our subshell goes on (a coreutils case, above). Where the shells differ: ours as dash in 15 (`time`, a keyword in bash), as bash in 8 (`echo -e … | xargs`, the program; `.[^.]*`, rule E), as neither in 66 (`$0`, `$$`).

### The atomic calls where no program runs

[`large-subset-builtins.pl`](tools/large-subset-builtins.pl): every command of the samples where neither dash nor bash would run a program, as ours ran it, with its words as expanded there (reported by `$Proc::ShellSpawn::ONBUILTIN`): the builtins (also inside function bodies), settings alone (`x=1`), and commands not found. Each distinct one runs alone in dash, `bash --posix` and ours, in the same directory as above; compared: status, output, the files left, and the messages. Calls of functions (114) are not run alone (the commands of their bodies are taken one by one); the coreutils tools are in the table above. A side effect inside an expansion (`: $((z=3))`) is not in the expanded words, so it is lost alone.

| Who agrees | Calls | Samples |
|---|---|---|
| all three | 722 | 1,178 |
| only the messages differ: ours as dash's | 24,589 | 26,529 |
| only the messages differ: ours as neither | 4 | 6 |
| **dash = bash, ours differs** | **0** | **0** |
| dash = ours, bash differs | 81 | 115 |
| bash = ours, dash differs | 33 | 67 |
| all three differ | 42 | 53 |
| ours rejects it alone | 19 | 32 |

The 24,589 are almost all commands not found (dash's `x: not found` against bash's `x: command not found`). Dash = ours: `%job` words (not found in dash, `fg` without job control in bash), statuses of errors at run time (rule A5: `.` of a missing file, `cd`, `shift`), `alias -g`. Bash = ours: the interactive builtins (B2) and `return` outside a function (rule E). All three differ: the interactive builtins again (bash prints help or errors), `times`, and one small real difference: `cd -` with `OLDPWD` unset (dash prints the directory, bash fails, ours does neither: status 0, no output). Rejected alone (19): what makes sense only where it ran (`break`, `continue`, `local`, `.` alone, `read` or `shift` whose operands came from expansions), the listings `set` and `trap` alone, and `alias '=foo'` (B1). Every call that is neither the same nor worded as dash's: [`tools/large-subset-builtins-differences.tsv`](tools/large-subset-builtins-differences.tsv).

### Which samples depend on the environment (known issue X27; post-0.08, 2026-11-07)

The run above gives every sample one fixed environment, so an agreement there is a real one only if the comparison could not come out otherwise elsewhere. [`large-subset-environment.md`](large-subset-environment.md) answers this for every sample, from the parse trees (the user's method: parse in one batch, split into atomic blocks, pass only what is shown unaffected): 365 are **strict** (only how the shell is started is assumed), 2 **held** (assumptions known to hold in every tested environment: `/dev/null`), 34,291 **almost strict** (under named assumptions: 28,322 need only `program`, that a program does the same in each run and the shells look it up alike), 5,752 **undecided** (with the codes of what they may depend on: files, variables, a program's output or status taken by the shell, `/tmp`, the whole tree, time, …). The record, one line per sample by snippet ID: [`large-subset-provenance.tsv`](large-subset-provenance.tsv). That document also has the check of all the samples parsed as one text (known issue X30).


## Files

- [`tools/large-subset-features.pl`](tools/large-subset-features.pl): the detector (features of a text) and the mapping of ShellCheck codes, each with verdict and basis; `-n TESTFILE…` prints the per-test record (redirect it to [`t/parser/large-subset-shells.tsv`](../../t/parser/large-subset-shells.tsv)).
- [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt): verdicts kept by hand, including the postponed free-form ones.
- [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl), [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl), [`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv), [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl), [`tools/large-subset-threeway-db.jsonl`](tools/large-subset-threeway-db.jsonl), [`tools/large-subset-threeway-differences.tsv`](tools/large-subset-threeway-differences.tsv), [`tools/large-subset-builtins.pl`](tools/large-subset-builtins.pl), [`tools/large-subset-builtins-differences.tsv`](tools/large-subset-builtins-differences.tsv), [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl): section 7 and [`large-subset-environment.md`](large-subset-environment.md), with its record [`large-subset-provenance.tsv`](large-subset-provenance.tsv).
- [`tools/large-subset-yardsticks.pl`](tools/large-subset-yardsticks.pl): the figures of section 3. `-o` writes one line per sample; `-c` caches ShellCheck's messages, so later runs need no ShellCheck.
- [`large-subset-dialect-features.md`](large-subset-dialect-features.md): the feature list with every probe result.
- [`../test-pools.md`](../test-pools.md): how to rebuild every test pool and measurement.
