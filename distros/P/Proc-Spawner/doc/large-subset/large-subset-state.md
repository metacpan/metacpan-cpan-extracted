# The large subset: the state of the union (the parse results measured with post4-0.04, and the same with post-0.12 on 2026-11-17; the run counts those of 2026-11-22, post-0.13)

This document says where `Proc::ShellSubset::Large` (the large parser: the base parser `Proc::ShellSubset` and, where it rejects a text, a wider grammar) stands against dash and bash:

- [section 1](#my-section-1): the rules;
- [section 2](#my-section-2): the order in which the rules apply;
- [section 3](#my-section-3): the parse results;
- [section 4](#my-section-4): the work list (samples within the lower yardstick that the parser still rejects);
- [sections 5](#my-section-5) and [6](#my-section-6): the subtle and the blatant differences;
- [section 7](#my-section-7): whether the accepted samples behave as in the shells.

Its yardsticks ([section 1](#my-section-1)) replace those of section 6 of [`large-subset-ceiling.md`](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md) (in Proc-Spawner 0.03). Those sorted the parser's own rejection messages, and so measured the parser against itself.

**Versions.** The parse results were measured with post4-0.04, and again with post-0.12 on 2026-11-17: the same ([section 3](#my-section-3)). Every run names its code and its day. A label such as post-0.09 names the code between release 0.09 and the next, which changes from day to day (the labels in order, with their dates: [`../README.md`](../README.md), last section). What changed in the parser, version by version: [`../../Changes`](../../Changes); the history this document held until 2026-11-18 (the parser's changes from 0.03 to post4-0.04, the counts of earlier versions, the runs that the runs here replaced) is there too, under post-0.13.

**Terms used below.**
- *Sample*: one shell snippet taken from the corpora of [section 3](#my-section-3), named by its snippet ID (such as `NB:9731`, from NL2Bash; the format: [section 2 of `../parsers/shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md#my-section-2)).
- *The subset*: the shell language that the large parser accepts.
- *ShellSpawn*: `Proc::ShellSpawn`, the executor, which runs what the parser accepts.
- *The detector*: [`tools/large-subset-features.pl`](tools/large-subset-features.pl), which finds in a sample the features where dash and bash differ, and maps ShellCheck's codes to such features.
- *Shells*: dash 0.5.12 and `bash --posix` 5.2.21.
- *The manual*: the Bash Reference Manual of bash 5.2.21, section 6.11 "Bash POSIX Mode", taken from the Debian package `bash-doc`; "M:N" names its item N.
- *P:ID*: a probe, whose ID is in [`dialect-cases/cases.txt`](dialect-cases/cases.txt) or [`dialect-cases/large-subset-dialect-probes2.txt`](dialect-cases/large-subset-dialect-probes2.txt).
- *LS:N*: test N of the large parser's tests, [`t/parser/large-subset-tests.pl`](../../t/parser/large-subset-tests.pl).
- *"Shell Corpus Gaps"*: a decision page, shipped until 0.04; its decisions (items such as P5, Q1, Q2, R1) are recorded here and in [`large-subset-logical.md`](large-subset-logical.md) ([`../README.md`](../README.md)).

## <a id="my-section-1"></a>1. The rules (the user's, 2026-11-02)

- **R-agree.** Where dash and bash agree, the subset must accept the form and behave as they do.
- **R-refuse.** Where both shells refuse a form, the subset refuses it too. "Refuse" covers both a syntax error (`-n`) and an error when the form runs. Forms both shells refuse count as blatant, where the detector can see them. It cannot see errors that happen only at run time, such as `${foo$n}`.
- **R-blatant.** A difference is **blatant** when "either one of them fails or does not match the docs; or they behave in blatantly different ways". Any other difference in how dash and bash behave is **subtle**.
- **R-program.** For the commands the subset runs as programs, the program beats any difference between the shells' builtins. The commands are:
  - `echo`, `printf`, `test`, `[`, `kill`, `time`, `pwd`;
  - `true` and `false`, where the shells agree anyway.

  `pwd` is `pwd -L`, which prints what both shells print (known issue [X23](../pspawn-known-issues.md#my-x23)). Since post-0.10 it runs inside Perl by default (IP1); with `PROC_SHELLSPAWN_INPROC=none` the program `/bin/pwd -L` runs. See also the base parser's specification, [`doc/parsers/shell-subset-spec.md`](../parsers/shell-subset-spec.md#my-section-4), section 4. "`test` beats blatant" was decided under item P5 of "Shell Corpus Gaps"; the user extended it to this list on 2026-11-02.

  *Class X*: in the measurement files, these differences are class **X**, together with the differences that a decision of the user settles. For example, by decision B2 the interactive-only builtins (`history`, `fc`, `bind`, `help`, `compopt`, `logout`, `set -o history`) do nothing.
- **Rule F** (the user, 2026-11-03): "When a shell grabs a util but implements it wrong, we should be free to do 'better'." Where a utility (as the program, or as a shell's builtin) behaves wrongly, R-program does not bind us: we take the better behaviour, by the categories of rule E ([section 2](#my-section-2), item 5). It was first used in post3-0.04, for `[ s1 \< s2 ]` and `[ s1 \> s2 ]`: both shells run them and POSIX 2024 specifies them, but the coreutils program refuses them. ShellSpawn compares them itself ([section 2](#my-section-2), item 2).
- **The yardsticks.**
  - **Upper** ("nothing bogus found"): both shells parse the sample (`dash -n`, `bash --posix -n`), and it uses no blatant difference.
  - **Lower** ("compatible"): within the upper yardstick, and it uses no subtle difference either.

  A class-X difference puts a sample outside neither yardstick.

  Both yardsticks are judged from the sample's text (the probes, the detector, ShellCheck), not from runs. Within the lower one, dash and bash can still differ when the sample runs, most often in the exit status of a failure: of the 45 samples the parser rejects within it, 30 differ in a run of each in both shells (2026-11-26; [section 4](#my-section-4)).
- **Who decided.** A *verdict* is the class given to a feature, a sample or a test: B (blatant), S (subtle), X, - (no difference), or O (open, below). Every verdict names its basis:
  - P:ID (a probe);
  - M:N (the manual);
  - SC:CODE (ShellCheck says dash lacks the construct, so dash fails);
  - J (Claude's judgement, not yet reviewed);
  - "user".

  J verdicts are kept as postponed text, so they count as open. Postponed verdicts are free-form text in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) and count as **open** (O): outside the lower yardstick, inside the upper one. They can be rewritten in short form later without a rescan.

**What the rules are for (the user, 2026-11-05).** The rules above and the order of [section 2](#my-section-2) were a quick triage. They brought the count of samples rejected within the lower yardstick down to where decisions can be made one by one, and they classify the rest. They are now mostly of historical interest. They are not to be overhauled, because every change of a rule means running every test and measurement again. New decisions are made case by case, each named (like K0 below), and the classification of what is left is the line of Perl code that handles it.

### <a id="my-two-principles-of-least-surprise"></a>Two principles of least surprise, and the decisions per tool

The two principles conflict (the user, 2026-11-05). For a command the subset runs as a program (`echo`, `printf`, `test`, `[`, `kill`, `pwd`):
1. A call to a tool inside a larger script should give the same result as the same call typed alone (so: the program, whatever the shells' builtins do).
2. A tool may treat in its own way edge cases that hardly ever occur when it is called alone (an empty list of arguments, as `kill $(pgrep x)` gives when nothing matches). Inside a script, such a case is common, and there the shells' behaviour is what a script expects.

In the best world the tool would have a switch (say `--strict`) that makes it behave non-interactively, and the subset could leave the work to that flavour. Even then, a switch raises its own question: how should the tool treat an operand that is named `--` or `--strict`? Short of that, the user sees no solution but **a global default that can be flipped, plus a per-tool list of decisions**, so that the choice is left to the caller. The global switch is not implemented yet; the default is the program (R-program), and the per-tool decisions in force are:

| Decision | Tool | The case | dash / bash / the program | The subset |
|---|---|---|---|---|
| K0 (the user, 2026-11-05) | `kill` | a signal (`-N`, `-NAME`, `-s NAME`) or `--`, and no process ID | usage, status 2 / usage, status 2 / long usage, status 1 | as both shells: dash's text, status 2 (`kill -s` alone, where the shells differ, stays with the program) |
| rule F (the user, 2026-11-03) | `test`, `[` | `s1 \< s2`, `s1 \> s2` alone | 0 or 1 / 0 or 1 / "binary operator expected", 2 | as both shells, compared by bytes |
| Q2, choice B (the user, 2026-11-03) | `printf` | `printf -v NAME …` | "Illegal option", 2 / sets NAME / prints `-v`, warns | the program |
| Z0 (the user, 2026-11-05) | `printf` | `printf '%0.s-'` (a common way to repeat `-`) and every `0` flag with `%s`, `%c`, `%b` (`%0s`, `%05s`) | as glibc's `printf(3)`: the flag ignored (`%05s` pads with blanks), 0 / the same / "invalid conversion specification", 1 | as both shells: the flag is dropped from the format before `printf` runs, the program or, since IP1, its emulation inside Perl (`Proc::ShellSpawn::printf_zero`) |
| `$$` (F9 of [`large-subset-spec.md`](large-subset-spec.md)) | `kill` | a process ID that is the shell's own | the shell takes the signal | as both shells (also `kill -0 $$` and the signals that do nothing by default, post4-0.04) |
| EC1 (the user, 2026-11-09) | `echo` | `POSIXLY_CORRECT` in the environment (X27, section 9 of [`large-subset-environment.md`](large-subset-environment.md#my-section-9)) | unchanged / unchanged / backslashes always, options only a first `-n` | the program, as before; `PROC_SHELLSPAWN_ECHO=dash` or `bash` makes ShellSpawn's `echo` behave as that shell's builtin (tested against dash 0.5.12 and bash 5.2.21: [`t/programs.t`](../../t/programs.t), 732 runs, and 24,000 random ones in both locales, with and without `POSIXLY_CORRECT`) |
| NV1 (the user, 2026-11-10) | `exit`, `return`, `break`, `continue`, `set` | an operand known only at run time that is no number (`exit $v`, `v=x1`), or no option (`set -o $v`); X42, X43 | an error, status 2, the shell ends / the same (bash goes on after `break 0`; `exit -1`: 255) / — | as the shells: dash's message and way (the literal forms the parser refuses, as before) |

**What the standards say on `%0.s`** (read 2026-11-05):
- The `0` flag is defined only for numeric conversions; "For other conversions, the behavior is undefined" (the Linux `printf(3)` page, as C11 7.21.6.1 and POSIX's File Format Notation, which the `printf` utility uses).
- The glibc manual, on `%s`: "The `-` flag can be used to specify left-justification in the field, but no other flags or type modifiers are defined for this conversion." glibc ignores the flag (gcc warns: "'0' flag used with '%s'"); dash and bash pass the format to it.
- coreutils 9.4 rejects it on purpose (`src/printf.c`: `case '0': ok['c'] = ok['s'] = 0;`), although its manual, which lists how its `printf` differs from C's, does not say so.

So dash, bash and coreutils are all within the standard; dash and bash do what the C library does.

The answers of dash's builtin, bash's builtin and the program for every such call the corpus makes: [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) ([section 7](#my-section-7)).

## <a id="my-section-2"></a>2. Which rule beats which

The order, highest first.

1. **R-refuse beats R-program** (the user, 2026-11-03: "refusing is better"; Q1 of "Shell Corpus Gaps"). `kill -SIGHUP PID`, `kill -s SIGHUP PID`, `kill -l SIGHUP` and `kill -sighup PID`: both shells refuse the `SIG` prefix (dash: "Illegal option -S"; bash as its manual says, M:38), while the program `/usr/bin/kill` accepts it. The parser rejects them (tests LS:246–250).
2. **Rule F against R-program.** `[ a \< b ]`: both shells answer 0, but the coreutils program fails ("binary operator expected"). Before rule F, item R1 of "Shell Corpus Gaps" had settled this with an option of the caller, `test_lt_gt`. Since post3-0.04 rule F applies: ShellSpawn compares `s1 < s2` and `s1 > s2` alone (also after `!`) itself, by bytes, as both shells do. Longer expressions with `<` or `>` stay rejected unless the caller sets `test_lt_gt`; then `test` runs them as coreutils does (inside Perl since IP1), and fails.
3. **R-program beats R-blatant and subtle differences.** `echo 'a\nb'`: dash prints two lines; bash and `/bin/echo` print `a\nb`. The subset accepts it and prints `a\nb`.
4. **A program result that is itself bogus (question Q2 of "Shell Corpus Gaps").** `printf -v x %s hi`: bash sets `x`, and dash fails. The coreutils program prints `-v` and a warning about excess arguments, which matches neither shell and serves no purpose. Decided (Q2, the user's choice B, 2026-11-03): it stays with the program, as R-program says. The same holds for `[ -v NAME ]` and unary `[ -a FILE ]`: bash answers, while dash and coreutils fail with different messages. Under R-program the subset fails like coreutils; no change is proposed for these.
5. **Rule E** (the user, 2026-11-03; it replaces R-blatant): where the shells differ, the subset takes the plainly logical behaviour, and rejects the form only where there is none. Each choice names a category (info, error, posix, same, harm, platform, meaning, effect, or none): [`large-subset-logical.md`](large-subset-logical.md). The detector counts a difference settled by rule E as class X (basis `E:CATEGORY`).
6. **Subtle differences:** rule E decides them too, item by item in [`large-subset-logical.md`](large-subset-logical.md). Until 0.03 the decision page "Shell Dialect Choices" decided them, by default by rejecting (its items are all decided in [`large-subset-logical.md`](large-subset-logical.md)).

**Windows.** R-program assumes that the programs exist: coreutils `[`, `/bin/echo`, `printf`, `kill`. A Windows port of `Proc::ShellSpawn` would lack them. It would then have to give the same answers itself (emulate the coreutils behaviour in Perl) or reject these commands. Since post-0.09 (released in 0.10) `echo`, `printf`, `test`, `[`, `true` and `false` give these answers inside Perl, on every platform by default (decision IP1; `Proc::ShellSpawn::Programs`, after coreutils 9.4; the differences are listed in X21); `pwd` too since post-0.10. For `kill` this is still open. This is known issue [X21](../pspawn-known-issues.md#my-x21).

## <a id="my-section-3"></a>3. The parse results

We measured with post4-0.04 over the pinned corpora ([`doc/test-pools.md`](../test-pools.md)); the corpora were fetched again on 2026-11-04 and found identical by their checksums, and the stored scan (what the shells, ShellCheck and the parser answered for every sample, kept so that a parser change needs only the parser run again) reproduced the parse results of post3-0.04 exactly before post4-0.04's changes. Measured again with post-0.12 by `make corpus-all` on 2026-11-17: the table below comes out the same from that run's `samples.tsv` (one line per sample: its source, whether both shells parse it, its verdict and features, whether the parser accepts it; [`tools/large-subset-yardsticks.pl`](tools/large-subset-yardsticks.pl) `-o`; recomputed 2026-11-18).

The corpora give 41,952 samples, after we left out:
- 14 samples marked as noise by hand ([`tools/large-subset-noise.txt`](tools/large-subset-noise.txt), since post2-0.04): tldr placeholders such as `exit exit_code`, tldr alternatives written `a|b|c`, NL2Bash here-documents cut off;
- 2,719 duplicates;
- the make book (578, a noisy extraction);
- 163 tldr lines made only of keystrokes, and 59 tldr lines with keystrokes next to other text (decision Y3, [`../../Changes`](../../Changes), 0.03);
- 16 ShellCheck test snippets that are wrong where they stand (`return`, `local`, `break` outside their function or loop, which ShellCheck's own tests mark as errors).

All but the noise were left out on the unreleased post4-0.03 (before 0.04), and checked again on 0.04 (the same per-sample results); the noise list came with post2-0.04. The parse results of 0.03 itself are in this document as shipped in the Proc-Spawner-0.03 distribution.

*ShellCheck, clean* and *warned*: its test cases that ShellCheck's own tests expect to pass without a warning (`verifyNot`) and to warn about.

Since post-0.13 the parser accepts 40,409 samples, one fewer than when the runs of 2026-11-17 and before were made: tldr's `exec command -with -flags` is rejected, since every grammar now refuses `exec` followed by a builtin's name (known issue [X56](../pspawn-known-issues.md#my-x56); decided 2026-11-21, D1). The sample is within the lower yardstick, so the table has 8 samples of tldr rejected within lower, where it had 7; the shares are the same to one decimal. This was measured from the stored scan (the end of this section), and again by `make corpus-all` on 2026-11-22: the same. The behaviour runs of [section 7](#my-section-7), and the levels of [`large-subset-environment.md`](large-subset-environment.md), were made again then, over the 40,409.

| Source | Samples | Accepted | Lower¹ | Upper¹ | Rejected within lower² | Rejected, subtle or open³ | Accepted outside upper⁴ |
|---|---|---|---|---|---|---|---|
| tldr | 29,440 | 99.3% | 99.3% | 99.3% | 8 | 5 | 1 |
| NL2Bash | 10,620 | 94.5% | 94.6% | 94.8% | 9 | 23 | 1 |
| bash Cookbook | 81 | 32.1% | 30.9% | 35.8% | 0 | 3 | 0 |
| pure-sh-bible | 44 | 97.7% | 97.7% | 100.0% | 0 | 1 | 0 |
| pure-bash-bible | 122 | 40.2% | 41.8% | 41.8% | 2 | 0 | 0 |
| ShellCheck, clean | 879 | 63.3% | 64.8% | 65.6% | 14 | 7 | 0 |
| ShellCheck, warned | 766 | 60.7% | 62.1% | 62.3% | 12 | 1 | 1 |

¹ *Lower*, *Upper*: the share of the samples within the lower and within the upper yardstick ([section 1](#my-section-1)).
² *Rejected within lower*: samples within the lower yardstick that the parser rejects: the work list of [section 4](#my-section-4).
³ *Rejected, subtle or open*: samples within the upper yardstick but outside the lower one (a subtle difference or an open verdict) that the parser rejects.
⁴ *Accepted outside upper*: samples outside the upper yardstick that the parser accepts.

Rule E settles some differences between the shells as class X (the choices of [`large-subset-logical.md`](large-subset-logical.md); detector basis `E:CATEGORY`). The parser accepts 339 samples whose only differences are class X: programs, the interactive builtins of B2, and rule E.

The 3 samples **accepted outside the upper yardstick** are misreadings by the detector, not parser errors: `$(( ((1+1)) ))` taken for the command `((`, an assignment `source=…`, and `time read` (taken for the program `time` running the program `read`).

With the pinned corpora and these shells, the parse results depend only on the parsers, the measurement scripts and the verdicts. The sha256 of those files, concatenated (`cat lib/Proc/ShellSubset.pm lib/Proc/ShellSubset/*.pm doc/large-subset/tools/large-subset-{extract,scan,drops,features,yardsticks}.pl doc/large-subset/tools/large-subset-verdicts.txt doc/large-subset/tools/large-subset-noise.txt | sha256sum`), is `e1923995b6a4f39c0de93bd6ab4d6963743860bea32efe3294bd65a37d36b9b5` (0.14, which differs from post-0.13's `d4e0ac534d2f4cfff827eaedb866a8a91f57ae8b475628f5c2351930b3faeaec` only in `$VERSION`; post-0.13's was measured again 2026-11-22 after [X80](../pspawn-known-issues.md#my-x80), which changed only what the large parser keeps of `cd`'s operands: the stored scan reparsed, every sample's verdict is the same as with the digest of 2026-11-21, `a741109fd8206da2aeec7e2c09492517aea16889f5d4aba3cd48a699987bb853`. That one differs from 0.13's, `9c6511c728498ddcc9373934729863de8dec7034c22b998326626079b9d5f646`, in five places: the large parser looks a command's line up instead of counting it, [X30](../pspawn-known-issues.md#my-x30); the base parser's two changes for its option `brace`, which these measurements do not use, [X3](../pspawn-known-issues.md#my-x3); the base parser and its frozen copy `Proc::ShellSubset::Small` refuse `exec` followed by a builtin's name, [X56](../pspawn-known-issues.md#my-x56); the label of the feature `scope`, [X70](../pspawn-known-issues.md#my-x70); and the report lists features of equal count by name, where their order changed from run to run. What was checked: the stored scan of 2026-11-17, 42,204 lines, reparsed with these parsers differs from the stored one in one line, that of the sample `exec command -with -flags`, now rejected; every other sample gives the same tree, or the same rejection, as with 0.13's parsers (45,479 samples compared; tldr has that text on two of its pages, and the scan holds one of them); the parse results made again from the scan differ from the stored ones by that sample, and by the label, in one line of the report and in the 16 samples that have the feature. 0.13 differs from post-0.12, `db2a39a0376fa7bb796d22f222c9121f4bf3d7bcfcffed3fc4234bd07250c735`, only in `$VERSION`; post-0.12 differs from 0.12, `06885fddc5089202adf750a065bd3b393fe6906b1727a9d09d815a9a333ec8ab`, only in a comment of the large parser, which names the version rule F came with; 0.12 differs from post-0.11 only in `$VERSION`; post-0.11's, after X41's fix in the large parser, was measured again 2026-11-10: the stored scan reparsed, the parse results, `samples.tsv` and the scan identical to those of the parser before it; earlier digests: [`Changes`](../../Changes), under each version; before post2-0.04 the noise list did not exist and was not part of the command). While it is unchanged, the parse results hold without measuring again.


## <a id="my-section-4"></a>4. Still rejected within the lower yardstick (the work list)

The parser rejects 45 = 43 + 2 samples within the lower yardstick: 43 in which the detector found no difference, and 2 whose only differences are class X. Not all are forms the shells agree on: the detector does not see a failure at run time that both shells share (12 below, and the one with `exec`), nor every difference (`exit -1`: dash "Illegal number", status 2, bash 255; `NAME[` as a command: bash's arrays); and some stay rejected by decision (B3, `set`). Sorted by the parser's rejection message (post4-0.04), the 45 = 2+12+4+4+3+4+1+15 are (the one with `exec` since post-0.13):

| Count | What | Where it is decided |
|---|---|---|
| 2 | `alias :='xargs -I{}'`, `alias p=php -E '$o = …'` (a literal word with `=` that is no alias name) | rejected under B1 (the base parser expands aliases when it parses, so `alias` needs literal names: [`../parsers/shell-subset-spec.md`](../parsers/shell-subset-spec.md)), though the shells agree on them (below); since post3-0.04 every word with an expansion, and `alias` anywhere, is accepted (P1: 20 samples until then) |
| 12 | `${foo$n}`, `${{var}`, `${${x%.*}##*/}`, `${ cmd; }` and the like | both shells parse them but fail when they run ("Bad substitution"), so R-refuse rejects them rightly (run on 2026-11-26, below: in 9 both fail, but with different statuses, dash 2, bash 127; bash 5.2 runs `${args[@]@Q}`, 2; and `${1~~}` stands in a function that is never called, 1); the detector cannot see failures at run time (`${##}` and `${#!}`, which both shells run, are accepted since post2-0.04). POSIX documents the failure: XCU 2.8.1 calls such a form an **expansion error** (its example: `${x!y}`, "because '!' is not a valid operator"), after which a non-interactive shell shall exit. This covers `${foo$n}`, `${var${n}_…}`, `${${x%.*}##*/}`, `${$(x)//x/y}`, `${1~~}`, `${args[@]@Q}` (a name, then no valid operator). For `${{var}`, `${ cmd; }`, `${.sh.version}` (a first character that is neither a name, a digit nor a special parameter), XCU 2.6.2 says the behaviour is **unspecified**: left to each shell (bash 5.3 and ksh give `${ cmd; }` a meaning). |
| 4 | `read` with an array element, `''`, or zsh's `NAME?prompt` | not POSIX names (a name from an expansion, `read $var`, is accepted since post2-0.04 and checked when it runs) |
| 4 | `ulimit` setting a limit, or `-a` | the base parser's decision B3 reads limits only |
| 3 | `NAME[` as a command | bash arrays |
| 4 | `set -o` alone (it lists, 2), and the `set` of other programs (tmux's `set -g`, fish's `set -U`) | stay rejected |
| 1 | `exec command -with -flags` (`exec` followed by a builtin's name) | rejected by V7, in every grammar since post-0.13 (known issue [X56](../pspawn-known-issues.md#my-x56); decided 2026-11-21, D1): after `exec` both shells look only for a program, find none, and fail alike (`exec: command: not found`, status 127); the detector does not see that |
| the rest (15) | `_` as a variable (2), `export foo[$bar]=3`, `export ${foo?}`, `exit -1`, `pwd --help`, `ls ~-`, `hash -v`, `cmd >& $var`, `.` alone, `unset -f ls /bin/ls`, … | one by one |

Bracket expressions with a quote, an expansion or `/` (`grep ^[\>\<]`, `something[^/]*`): 4 samples rejected until post3-0.04. Since post4-0.04 two of them are accepted, and the other two, `unset foo[$i]` and `unset foo[x${i}y]`, are bash's arrays (feature `unsetarr`, blatant), outside the upper yardstick.

We ran some of the work list by hand in both shells on 2026-11-04. The shells agree on these, so the large parser could accept them (but `export ${foo?}`: in the run of 2026-11-26 below both fail, with different statuses, dash 2, bash 127):
- `alias :='…'` (an alias named `:`);
- `export ${foo?}`;
- `command -` ("not found", 127);
- `unset -f ls /bin/ls` (status 0, nothing done);
- `alias p=php -E '…'` agrees too (both: `-E` and the rest are names to print, "not found", status 1), apart from the message's wording.

Samples marked as noise by hand (14, [`tools/large-subset-noise.txt`](tools/large-subset-noise.txt)) are left out of every count:
- the tldr placeholders `exit exit_code`, `jobs %job_id`, `wait instance_id`, `wait process_id`, `wait %job_number`, `shift n`, `return exit_code`, and NL2Bash's `exit N`;
- the tldr alternatives `duf --sort mountpoint|size|…`, `mate-search-tool --sortby=name|folder|…`, `winedump dump -j import|export …`;
- the 3 NL2Bash here-documents whose body was cut off (`ssh host <<'EOF'` with nothing after).

### <a id="my-the-rejected-samples-run-in-dash-and-bash"></a>The rejected samples, run in dash and bash (2026-11-26)

Every sample the large parser rejects, not only the work list, was run once in dash and in bash, with `make corpus-rejected` ([`tools/large-subset-rejected.pl`](tools/large-subset-rejected.pl); every sample with its outcome: [`tools/large-subset-rejected.tsv`](tools/large-subset-rejected.tsv); the runs: the collection `2026-11-26-post-0.13-rejected` of Proc-Spawner-results). README.md's [How close](../../README.md#my-the-rejected-snippets) has the summary; this is the whole account.

[Section 1](#my-section-1) gives two measures of what dash and bash share, both made from the snippets' text by a detector of differences between the shells (it does not run them): the *lower yardstick* takes in only the forms of shell text on which it finds the two shells agreeing; the *upper yardstick* takes in also the forms on which they differ only subtly, or on which the author has not yet given a verdict. By these measures (the parse results of 2026-11-22, post-0.13) the 1,543 rejected snippets fall into three groups, 1,458+40+45=1,543. Each was also run once in dash and in `bash --posix` (bash, here and below, is always `bash --posix`) alone, on 2026-11-26, in the environment of the one run of the accepted snippets ([One run](../../README.md#my-one-run-of-every-accepted-snippet)). The two come out *alike* (the same, or differing in the wording of their error messages alone, which does not count, as in the result of the accepted snippets in [README.md](../../README.md#my-the-accepted-snippets)), or *differ*, or *did not end*: a shell was still running when the 5 seconds a run is given were over (the same term as for the accepted snippets) (`make corpus-rejected`; every snippet with its outcome: [`large-subset-rejected.tsv`](tools/large-subset-rejected.tsv)).

- **Foreign**, 1,458: outside even the upper yardstick. They are rejected on purpose: the detector finds that dash and bash behave differently there, so there is no shared behaviour that ShellSpawn could follow. By what the shells do with them, 389+938+125+6=1,458 ([section 6](#my-section-6)):
  - 389 only bash can parse: bash's own syntax;
  - 938 both shells parse, but each uses a feature that dash lacks or runs otherwise (found in 833 by the detector of differences between the shells that the measurement uses, [section 1](#my-section-1); in 105 by ShellCheck's warnings alone); the most frequent: bash-only builtins such as `source`, `declare`, `let` (227), `[[ … ]]` (126), options of `read` that dash lacks (66), brace expansion (62), `$'…'` (62), arrays (51);
  - 125 neither shell can parse: other languages, zsh, placeholders such as `<session name>`;
  - 6 only dash can parse: `[[ … ]]` written wrongly, which bash refuses and dash takes for a command named `[[`.

  Run in dash and bash: 1,138 differ, 313 come out alike, 7 did not end. Of the 938 both parse, 750 differ, 186 are alike (72 the same, 114 differing in the messages only), 2 did not end; of the 389 only bash parses, 380 differ, 4 are alike, 5 did not end; the 6 only dash parses all differ; of the 125 neither can parse, 123 are alike, since both refuse them, and 2 differ. Where a foreign snippet comes out alike, it is so in this one environment only, as with the subtle ones below; no example environments were made for them.
- **Subtle**, 40: within the upper yardstick but outside the lower one ([section 5](#my-section-5)). In 37 the two shells differ in detail: listings (`set`, `export -p`, `readonly -p` or `trap` alone, which print the shell's state, each shell in its own format), 26; traces (`set -x`, `set -v`), 7; `$PS1`, 2; `x=$@`, 1; `local x` without a value, 1. In 3, all reading `$-`, the verdict is still open. Run in dash and bash, 20 of the 40 differ (18 listings, 1 `$PS1`, 1 `$-`), and 20 come out alike: 8 listings (in 6 a later command filters the listing to the same lines in both, such as `set | grep ^IFS=`; `trap` alone has nothing to list; and in a tldr usage line, `next build|dev|export|…`, the listing of `export` goes into a pipe to a program that does not exist), the 7 traces (6 have nothing after them to trace; in 1 the traces differ, but they go to standard error, which counts as messages), 1 `$PS1`, `x=$@`, `local x`, and 2 of `$-`. Alike in one environment only: a listing or a trace differs as soon as there is something to list or trace.
- **Work list**, 45: within the lower yardstick, where the parser should accept a snippet unless there is a reason not to (this section). Run in dash and bash, 15 come out alike (8 the same, 7 differing in the messages only) and 30 differ, 15+30=45:
  - Of the 15 alike, 6 stay rejected by decisions of the author: 2 `alias` forms (B1: the parser expands aliases while it parses, so `alias` needs literal names); 1 `ulimit` setting a limit (B3: the parser accepts only `ulimit` reading a limit); 1 `exec` followed by a builtin's name (D1, since post-0.13: every grammar refuses it); 2 `set` of other programs (tmux's `set -g`, fish's `set -U`), which both shells refuse, and which this section keeps rejected (a decision without a name, in the table above). The other 9 the large parser could accept, so that ShellSpawn would run them and do what both shells do: `unset -f ls /bin/ls`, `for _ in *` (the variable `_`), and two texts that only define functions, never called, all four succeeding alike; `command -`, `hash -v`, `ls ~-`, `foo[a][b]=3` and `$(var[i])` (neither `foo[a][b]=3` nor `var[i]` is a program), all five failing alike.
  - Of the 30 that differ, in 19 both shells fail, with different statuses (dash 2; bash 1, 127 or 255): 10 expansion errors (9 such as `${foo$n}` and `${ cmd; }`, and `export ${foo?}`); 4 `read` into a name that is not a POSIX name; `export foo[$bar]=3`, `cmd >& $var`, an assignment to `_`, `exit -1`, and `$@` glued to a word in a redirection. In 6 one shell fails and the other does not: bash runs `${args[@]@Q}` (2), `ulimit -x unlimited`, `ulimit -u 30` and an array assignment `a[$(…)]=n`, which dash refuses; dash runs `.` alone, which bash refuses. In 5 the output differs: `set -o` (2) and `ulimit -a`, which list each shell's own settings, `pwd --help`, and `trap 'echo $SECONDS' EXIT`. 19+6+5=30.
  - Where dash and bash both accept a text and differ only when they run it, ruling A5 ([section 1](#my-section-1): ShellSpawn may do what dash does) would allow ShellSpawn's difference from bash. So the large parser could also accept the 25 of these 30 that no decision keeps out (B3 keeps out the three `ulimit`, and this section the two `set -o`), with ShellSpawn, when it runs them, doing what dash does: where both shells fail, failing with dash's status.
  - All of this comes from one run in one environment, and one environment can hide a difference. `ls ~-`, one of the 9, lists the directory named in `$OLDPWD`: in the run `OLDPWD` was unset, and both shells failed alike; with `OLDPWD=/usr`, bash lists `/usr` and dash still fails, as it does not expand `~-` (checked by hand, 2026-11-26). The accepted snippets were therefore also run in *example environments*: a program read each one's parse tree, found what it depends on (a file, a variable, the input, …), and made a few environments that vary just that ([Runs in example environments](../../README.md#my-beyond-the-one-run)). A rejected snippet has no parse tree, so its example environments would have to be written by reading it. Until that is done, none of these is ready to be accepted. Both questions are [`TODO` A27](../../TODO.md#my-a27).

So the detector's "no difference" for the lower yardstick does not mean that the shells agree when the samples run: most of these differ in the status of a failure, which the detector does not see.

**The work list's candidates in example environments** (2026-11-26; `make corpus-rejected-envs`; the environments, written by reading each snippet: [`tools/large-subset-rejected-setups.jsonl`](tools/large-subset-rejected-setups.jsonl); each snippet's outcome in each: [`tools/large-subset-rejected-envs.tsv`](tools/large-subset-rejected-envs.tsv)). Of the 34 candidates (the 9 alike and the 25 that differ, that no decision keeps out), 25 read something from their environment (a variable, a file, the input, the files a pattern matches) and ran again in one to three environments that vary it, in the states the setups of the accepted snippets use; the other 9 read nothing from it (`exit -1`, `pwd --help`, `${ ls; }` twice, `${.sh.version}`, `.`, `hash -v`, the two function definitions), so their one run stands. Over the base run and every environment, 5 stay alike in every one, 8 are alike in some and differ in others, 12 differ in every one (5+8+12=25):

- of the 9 alike: the 5 that ran again (`unset -f ls /bin/ls`, `for _ in *`, `command -`, `foo[a][b]=3`, `$(var[i])`) stay alike in every environment; `ls ~-` differs as soon as `OLDPWD` is set (bash lists that directory, dash does not expand `~-`). With the 3 that read nothing, 8 of the 9 remain candidates;
- of the 25 that differ: 12 differ in every environment (the 5 expansion errors that ran again, `var=${ foo >> bar; }`, `read REPLY\?…` and `read ''`, `export foo[$bar]=3`, `a[$(…)]=n`, and `eval "${args[@]@Q}"` twice); 7 come out alike in some: `export ${foo?}` with `foo=x1`, `read arr[val]` and `read arr[keykey]` when a file matches the pattern (`arrv`, `arrk`), `cmd >& $var` with `var=1`, `trap 'echo $SECONDS' EXIT` with `SECONDS=5` in the environment, the `while read … <"$fname"` loop when `$fname` names a file, and `find … >> ${jsbuild}$@ \;` when `jsbuild` is set or arguments are given; 6 read nothing (12+7+6=25).

## <a id="my-section-5"></a>5. Subtle differences and open verdicts

**Between the shells.** Measured 2026-11-17 (`samples.tsv`): 52 samples have a subtle difference as their worst one, and 3 an open verdict. By feature (each of the 52 has one: 32+10+7+2+1=52):
- listings (`set`, `export -p`, `trap` alone), also the order of the `alias` listing: 32;
- `local x` without a value: 10;
- traces (`set -x`): 7;
- `$PS1`: 2;
- `x=$@` (the words of `$@` joined in an assignment): 1.

The 3 open ones are `$-` (below).

**Open verdicts** (postponed, free-form in [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt)): `$-` (rule E: no plainly logical choice). The other parts of question Q3 of "Shell Corpus Gaps" are settled ([`large-subset-logical.md`](large-subset-logical.md)):
- `$LINENO`, since post-0.04, by rule E: as bash, the line number;
- `return` outside a function, by rule E: an error (as bash);
- settings with a redirection, by rule E: redirected first (as dash);
- `local` outside a function stays rejected, as both shells fail.

**Between the shells and the programs or decisions (class X):**
- `echo`: like bash.
- `[ -v ]`, unary `[ -a ]`: coreutils fails like dash, unlike bash.
- `[ a \< b ]`, `[ a \> b ]` alone: coreutils fails, unlike both shells. Settled by rule F ([section 1](#my-section-1)): ShellSpawn compares them by bytes, as both shells do. Longer expressions with `<` or `>` stay rejected unless the caller sets the option `test_lt_gt` (item R1, before rule F); then the program runs them, and fails.
- `printf %q`: coreutils quotes as `'a b'`, bash as `a\ b`, and dash fails.
- `printf -v`: legalized (Q2, choice B, 2026-11-03): the program `printf` runs it.
- Rule E ([`large-subset-logical.md`](large-subset-logical.md)): `jobs` in a pipeline or `$( )`, `return` outside a function, `cd` with extra operands or without `HOME`, descriptors above 9, `[^…]`, patterns that never match `.` or `..`, settings with a redirection, `getopts` leaving `OPTARG` unset.
- `time`: the program `/usr/bin/time`. It is not on the list of programs of the runner ([section 7](#my-section-7); [`tools/large-subset-programs.txt`](tools/large-subset-programs.txt), A23), so in every run `time cmd` fails with "not found", as in dash, which has no `time` builtin either.
- `history` and the other interactive-only builtins (B2): they do nothing, as bash mostly does; dash has none of them ("not found"). The caller can choose dash's behaviour (`interactive => 'dash'`) or rejection (`interactive => 'reject'`).

## <a id="my-section-6"></a>6. Blatant differences

Measured 2026-11-17 (`samples.tsv`), 1,461 samples are outside the upper yardstick: 520 because a shell refuses to parse them, 941 because of a blatant difference (520+941=1,461). The parser rejects them all, except the 3 detector misreadings of [section 3](#my-section-3). The most frequent features:
- bash-only builtins (`source`, `declare`, `let`, …);
- process substitution;
- arrays;
- `[[ … ]]`;
- options of `read`, `local` and `type` that dash lacks;
- `$'…'`;
- brace expansion;
- `(( … ))`.

**❰BUG❱ bash 5.2.21:** M:24 says "If a POSIX special builtin returns an error status, a non-interactive shell exits". In `bash --posix -c`, `shift 3` with fewer arguments and `export "1x=2"` print an error, return 1, and the shell goes on. `set -o nosuch` and `unset -x` do exit (status 2). This is a blatant difference by the definition ("does not match the docs"); known issue [X22](../pspawn-known-issues.md#my-x22). The subset rejects these forms at parse time where it can see them; where it cannot, ShellSpawn follows dash and stops.

## <a id="my-section-7"></a>7. Behaviour: the accepted samples run in dash, bash and ShellSpawn

Sections 3 to 6 say only which samples the parser accepts. This section says whether the accepted ones then **do** what the shells do. The first run over the corpus was of post4-0.04; before it, the only tests of behaviour were:
- the batteries ([`t/batteries/`](../../t/batteries): shell snippets written by hand, which [`t/dash.t`](../../t/dash.t) runs in ShellSpawn and in dash, not in bash, and compares);
- [`doc/parsers/tools/verify.pl`](../parsers/tools/verify.pl) (argv only, the base parser, 2026-10-29).

Below, the *library* means the 40,409 samples the parser accepts since post-0.13 ([section 3](#my-section-3)). The runs before 2026-11-22 (post4-0.04 to post-0.12) had 40,410.

**In this section** (each part names the code and the day it was measured on):
- The run of every accepted sample in dash, `bash --posix` and ShellSpawn, in a controlled environment: how it is made, its table, and what the classes hold. The table counts the run of post-0.13 of 2026-11-22 ("The run in the table", below). Its code had the review of the executor's code built in; ShellSpawn ran the programs inside Perl (IP1) and waited at exit only while it had something left to start, leaving its background jobs running as the shells do (K5); a command run inside Perl that writes into a broken pipe ended its shell, as SIGPIPE does in the shells (D3). The runner waited for background jobs (A18), offered only the programs of its fixed list (A23), compared what a sample feeds a program that is only logged (IN1), and did not read the input of a program that never reads it (A24 (b)).
- "ShellSpawn at exit": the modes of K5 (`PROC_SHELLSPAWN_END`) on the samples with a background job, 5 runs each.
- "Through Run": ShellSpawn starting every process through the module Run (`Run.pm`, on CPAN), as it does where there is neither posix_spawn nor fork (M2), against posix_spawn.
- The atomic calls: of `echo`, `printf`, `test`, …, of external programs, and where no program runs (all three from the run of 2026-11-22).
- "Which samples depend on the environment": known issue [X27](../pspawn-known-issues.md#my-x27), the levels from the parse trees, and the runs with the environment varied (section 9 of [`large-subset-environment.md`](large-subset-environment.md#my-section-9)).

The runs that these replaced (of 2026-11-17, -16, -15, -14, post-0.11's, post-0.09's with its rebuild for IP1, W5's) and how the counts changed between them: [`../../Changes`](../../Changes), post-0.13.

How to repeat any of these: [`../test-pools.md`](../test-pools.md), "Behaviour".

### <a id="my-how-the-runs-are-made"></a>How the runs are made

[`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) (*the runner*) runs each of the 40,409 samples the parser accepts three times: in dash, in `bash --posix` and in `Proc::ShellSpawn` ([`t/try.pl`](../../t/try.pl)).

- **Isolation.** Each run starts in a fresh copy of the same small directory (a few files, so that patterns match something), as an unprivileged user (one per parallel worker, `rcK`), with no network, a 5-second timeout and limits on CPU, file size and processes.
- **The environment** (`-env tmp,random,mtime`, since post-0.09, 2026-11-08; the user, A1(b)). Each run gets a fresh `/tmp`, `/var/tmp` and `/dev/shm`, one fixed file over `/dev/urandom` and `/dev/random`, and fixed times on its copy of the directory. So the runs do not meet, and they come out the same when repeated. The post4-0.04 run had none of these: the shells and the samples met in `/tmp`, and 3 of its 7 "ShellSpawn differs" came from chance (`/dev/urandom`, a race, the times of `ls -l /`; a fourth went with decision Z0).
- **Background jobs** (since post-0.11; the user, A18). The runner also waits, up to 5 seconds, for the background jobs of every shell still running when the shell ends (`-after`). Before, they were killed then, often before their programs had done anything. This concerned dash and bash; ShellSpawn, which starts each command of a job itself, waits in `Proc::ShellSpawn`'s `END` block while it has something left to start for a job (K5, below).
- **The programs.** `PATH` holds *recorders*: stand-ins that log each call, its program's name and arguments.
  - There are recorders only for the program names of [`tools/large-subset-programs.txt`](tools/large-subset-programs.txt), whether installed or not (A23 (b), post-0.12). With `-programs system` (the behaviour before A23) there is one for every program on the system's `PATH`.  Since post-0.13 ([X84](../pspawn-known-issues.md#my-x84), decided 2026-11-23 (D6)), in step 3 and in the stand-in variants of [`large-subset-environment.md`](large-subset-environment.md#my-section-9) (`-calls`), each program a sample calls that is not on the list and is no builtin also gets one, for that sample's runs alone.
  - The tools that only read, print or make files (`cat`, `grep`, `sed`, `awk`, `sort`, `ls`, `mkdir`, …) are logged and then really run.
  - The programs the subset runs in place of builtins (`echo`, `printf`, `test`, `[`, `true`, `false`, `pwd`, `kill`) run without being logged, as the shells' builtins leave no log.
  - Every other program is *only logged*: its recorder exits with status 0 and no output (`rm`, `mv`, `cp`, `ln` among them, so that a sample cannot remove what it did not make; `sh` too).
  - **The input of a program that is only logged** (IN1, since post-0.12, 2026-11-17, the user). Its recorder reads what the sample feeds it (a pipe, a file given by `<`, a here-document), to the end or to 64 KB, and logs its size and SHA-256 with the call, so that this input is compared too. So code made at run time and piped into `sh` is compared, not run. The run's own standard input (`/dev/null`, or the input a setup of [`large-subset-environment.md`](large-subset-environment.md#my-section-10) chose) is not read, so that a later `read` still gets it. (Since A24 (b), also not the input of a program that never reads it: "The run in the table", below.)
- **What is compared.** [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl) compares:
  - the exit status;
  - standard output;
  - the programs called, with their arguments (sorted, since pipeline elements run at once);
  - the files left in the directory;
  - separately, the messages: standard error, with each shell's own prefix taken off (`dash: 1: `, `bash: line 1: `, `sh: `), compared as a multiset of characters, because the shells write the messages of pipeline elements in pieces that mix.
- **Time.** About 55 minutes with 4 workers (52 on 2026-11-22; 21 without the mounts of `-env`). The split by "coreutils involved" below needs a second run with `-q` (18 minutes on 2026-11-22).
- **Limits.** Known issue [X27](../pspawn-known-issues.md#my-x27) ([`large-subset-environment.md`](large-subset-environment.md)). [Section 9 there](large-subset-environment.md#my-section-9) has the run with its environment varied, which found that the samples also met in `/tmp` across the run (before `-env tmp`), and X33: `/dev/stdout`, `/dev/stderr` were not writable in the runs (fixed in post-0.09).

### <a id="my-the-classes-and-the-table"></a>The classes and the table

Each sample falls into exactly one class:
- **same**: all three agree;
- **messages only**: the status, the output, the programs called and the files agree in all three, but the messages differ; split by how ShellSpawn's messages are worded: as dash's, as bash's, or as neither (also where dash's and bash's agree);
- **ShellSpawn differs**: dash and bash agree beyond the messages, ShellSpawn does not;
- **known chance** (since 2026-11-18, the user): as "ShellSpawn differs", but [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) names the sample chance. In other runs dash and bash give other results too (a race, an inode number), so one run's agreement of the two says nothing ([`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl) `-known`). Before, these were counted under "ShellSpawn differs".
- **shells differ**: dash and bash differ beyond the messages; split by whether ShellSpawn agrees with dash, with bash, or with neither (messages ignored);
- **timeout**: one of the three ran out of time (5 s); not compared.

**"Coreutils involved"** means that one of the commands the subset runs as a program in place of a builtin (`echo`, `printf`, `test`, `[`, `kill`, `pwd`) takes part in the sample. Either ShellSpawn handed it a call (as [`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-q` shows: a second run in which ShellSpawn itself logs these calls, with the caller of each; the recorders do not), or its name stands where a command does (this catches the calls ShellSpawn answers itself: K0, rule F, `kill $$`). A call that another program makes (`… | xargs kill`) does not count: there every shell runs the program.

| Samples | Run¹ | Same | Messages only: as dash | as bash | as neither | **ShellSpawn differs** | known chance | Shells differ: ShellSpawn as dash | as bash | as neither | Timeout |
|---|---|---|---|---|---|---|---|---|---|---|---|
| coreutils involved | 1,333 | 883 | 266 | 0 | 44 | **2** | 0 | 46 | 64 | 25 | 3 |
| no coreutils | 39,076 | 14,897 | 23,035 | 35 | 11 | **0** | 1 | 922 | 39 | 125 | 11 |
| all | 40,409 | 15,780 | 23,301 | 35 | 55 | **2** | 1 | 968 | 103 | 150 | 14 |

¹ *Run*: the count of samples of the row that ran; the other columns divide it.

### <a id="my-the-run-in-the-table"></a>The run in the table

The table counts the run of post-0.13 of 2026-11-22, made by `make corpus-all` from an empty work directory ([`../test-pools.md`](../test-pools.md#my-section-0), section 0; its part for this table is `make corpus-run corpus-qrun corpus-runreport`): every sample ran in it, none is kept from an earlier run. The code and the runner had:
- the review of the executor's code built in (the decision page "Executor Idiom Review", 2026-11-13 to 11-17; its items in Changes, post-0.12: JC1 to JC3, JH1 to JH5, JQ1, JU1 to JU5, JB1 to JB3; X60 to X63, X65);
- the programs `echo`, `printf`, `test`, `[`, `true`, `false` and `pwd` inside Perl (IP1, the default since 0.10; `pwd` since post-0.10);
- ShellSpawn at exit waiting only while it has something left to start for a background job (K5, the default `shell` of `PROC_SHELLSPAWN_END`; before, it waited until every job had ended);
- the runner waiting for background jobs (A18), which changes dash's and bash's results too wherever a job outlived its shell;
- the runner offering the samples only the programs of its fixed list (A23, below);
- a recorder not reading the input of a program that never reads its standard input (A24 (b), the user, 2026-11-17: `rm`, `mv`, `cp`, `ln` unless asked to prompt, `mkdir`, `touch`, `chmod`, `sleep`, …: the list in [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl); also `ls` and other programs that really run, which matters only where a setup of [`large-subset-environment.md`](large-subset-environment.md#my-section-12) makes them stand-ins), nor that of `zcat` naming a file (not `-`). In the run of 2026-11-17 only the 4,060 samples this concerned ran again with it (a stopgap, the user).

The changes of post-0.13 that change results ([`../../Changes`](../../Changes)):
- `exec` looks up only a program, as in both shells (X56), and the parser refuses `exec` followed by a builtin's name (D1): one sample fewer;
- the message of `exec`'s command that does not start begins with `exec: `, as in both shells; for a command found nowhere, the message names the error the search met, as dash's does (`: Permission denied` for an empty name: X72, D2);
- `cd -` with `OLDPWD` unset prints the directory, as dash (A5); `cd` takes its operands apart after expanding them (X80);
- a command run inside Perl that writes into a broken pipe ends its shell (D3).

Against the run of 2026-11-17, from the two runs' records, both reported with the tools after X82 ([`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv), which lists every sample of the classes ShellSpawn differs, known chance, messages as neither and shells differ as neither):
- ShellSpawn differs, 4 → 2: `exec command -with -flags` is no longer accepted (D1); the zenity subshell now differs in the messages' wording only (D3; below).
- Known chance, 3 → 1: the two others came out otherwise by timing, `find . -print | xargs ls -gilds` the same in all three, the two `head` on one pipe with the shells differing and ShellSpawn as dash. Both stay named chance.
- Messages as neither, 66 → 55 = 66 − 12 + 1. Left: 6 by `exec`'s message, 6 by the message for an empty command name. Came in: the race `cat lol | sed … > lol` (below).
- Shells differ, ShellSpawn as neither, 152 → 150: the two `cd -`, now as dash. ShellSpawn as dash, 965 → 968: these two and the two `head`.
- The record does not list the samples of the other classes, so for those only the net change is known: same +4, messages as dash +8, as bash +1, shells differing with ShellSpawn as bash 0. The named moves account for +6 into same (5 by `exec`'s message, the `find`) and +8 into messages as dash (6 by the empty name, 1 by `exec`'s message, zenity); so some samples also left same, and where they went the records do not say.

By source (all samples):

| Source | Run | ShellSpawn differs | Known chance |
|---|---|---|---|
| tldr | 29,231 | 0 | 0 |
| ShellCheck | 1,021 | 2 | 0 |
| NL2Bash | 10,039 | 0 | 1 |
| bash Cookbook | 26 | 0 | 0 |
| pure-sh-bible | 43 | 0 | 0 |
| pure-bash-bible | 49 | 0 | 0 |
| all | 40,409 | 2 | 1 |

### <a id="my-what-the-classes-hold"></a>What the classes hold

**Where dash and bash agree and ShellSpawn differs (2):** `printf -v` (legalized by Q2, choice B: the program runs it). In both, dash and bash fail alike, status 2 (`printf -v cow $(cmd)`: no format; `printf -v '%s' "$1"`: no valid name), while the program prints `-v`.

The two others of the run of 2026-11-17 are gone:
- `exec command -with -flags`: dash and bash look only for a program named `command` after `exec` (not found, 127), where ShellSpawn ran its builtin `command` (status 248: decision A4): known issue [X56](../pspawn-known-issues.md#my-x56), fixed; the parser now refuses the form (D1).
- The `zenity` subshell, `(echo "#1"; sleep 1; echo "50"; echo "#2"; sleep 1; echo "100") | zenity --progress`. `zenity` is missing and exits at once. In the shells, the builtin `echo` writing into the broken pipe dies of SIGPIPE and takes the whole subshell with it. In ShellSpawn the write failed and ended the `echo` alone, and the subshell went on to the later `sleep 1`. Since D3 ShellSpawn's subshell ends there too: the status, output and calls are the shells', the message worded as dash's.

The review of the executor's code named samples to look at afterwards. ShellSpawn differs in none of them (counted on the run of 2026-11-17; on 2026-11-22 ShellSpawn differs only in the two `printf -v`):
- `read`: 56 samples: same 49, messages as dash 1, the shells differing with ShellSpawn as dash 6;
- `kill` with `$$`: 1, same;
- `test -ef`: 15: same 8, messages as dash 5, shells differing with ShellSpawn as neither 2 (process IDs and `/proc`);
- `pwd -L`: 1, same.

**Known chance (1):** the race `ls -a | tee output.file`. It lists `output.file` if `tee` has created it before `ls` reads the directory. (The two other samples named chance, `find . -print | xargs ls -gilds`, the inode numbers of the run's copy, and two `head` reading one pipe, fell in other classes on 2026-11-22: above.)
  - By hand, 50 runs each: dash listed it 31 times, bash 33, ShellSpawn 2.
  - Why: ShellSpawn starts `tee` later after `ls` than the shells do. They fork the two children back to back. ShellSpawn spawns `ls` (posix_spawn returns once `ls` has started), then sets up the next element of the pipeline in Perl before it spawns `tee`.
  - Traced with `strace -f`, one run each (strace slows every call): from `ls`'s start to `tee`'s, dash took 1.4 ms, ShellSpawn 4.7 ms, while `ls` reads the directory 5 to 6 ms after its start and `tee` creates its file 3 to 4 ms after its own.
  - Kept so (K6, the user, 2026-11-15: "no need to nitpick startup delays"); named chance in [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv).

**Messages worded as neither (55 = 44 + 11):**
- with coreutils (44): the programs' own messages (`[: missing ']'` against dash's `[: missing ]`, `printf: warning: ignoring excess arguments`, procps' `kill: (1): Operation not permitted`), which ShellSpawn words as the programs do (inside Perl as coreutils; `kill` is the program);
- without coreutils (11 = 7 + 2 + 1 + 1):
  - the interactive builtins (B2: nothing, where dash says "not found" and bash complains; 7: `bind` in 3, `history`, `compopt`, `help`, `logout`; 5 of the 7 are tldr's alternatives `a|b|c`);
  - a process ID as a command's name (2: `"$$"`, `${$#}`; the number differs);
  - `eval app …` (1: dash `eval: app: not found`, bash `app: command not found`, ShellSpawn `app: not found`);
  - the race `cat lol | sed -e 's/a/b/g' > lol` (1): in dash and bash the redirection made `lol` before `cat` opened it, in ShellSpawn not, so only ShellSpawn's `cat` says `lol: No such file or directory`. ShellSpawn starts `cat`, then sets up the next element (as in `ls -a | tee output.file`, above). Not in this class on 2026-11-17.

**Where the shells differ:**
- **ShellSpawn as dash (968).** Most are statuses of errors at run time (rule A5, as dash), above all a redirection into a directory that does not exist (`> path/to/out.html`: dash 2, bash 1). The rest are features legalized by rulings already (`time`, `[ -v ]`, `${x:?}`, …).
- **ShellSpawn as bash (103):**
  - the interactive builtins (B2);
  - `echo -e` and `echo 'a\nb'` (the program; since IN1 also where they feed a program that is only logged: 5);
  - rule-E choices (`return` outside a function, `[^…]`, `.*`, `$LINENO`);
  - `kill` with a word that is no process ID (the program's status 1, as bash; dash 2).
- **ShellSpawn as neither (150).** By the samples' codes, 150 = 41+36+25+14+6+2+26 (counted on the 150 of the run of 2026-11-14 and carried forward with the records: `v=5 env | less` and `ls -lR / | tee output.file` came in on 2026-11-17, the two `cd -` with `OLDPWD` unset left on 2026-11-22, now as dash):
  - `$0` (41: `dash`, `bash`, `sh`);
  - the interactive builtins (B2; 36: `history`, `bind`, `help`);
  - process IDs (25: `$$`, `ps`, `pstree`);
  - times (14: `time`, `times`, `ls -l` of places outside the run's copy);
  - listings of `/` and `/proc` (6);
  - `sort -R` and the like (2);
  - 26 others: mostly messages that went to standard output or into a file (`2>&1 | tee log`, `2>file`: this section still counts them as output; to drop them is work in [`TODO`, part B](../../TODO.md#my-part-b)), `printf -v` (2), `kill -l`, `export $foo`, `v=5 env | less` (the environment listed), `seq 10 | xargs -P4 …` (a race).

**Timeouts (14).** 13 do not end by themselves (endless loops, `tail -F`, `grep -R … /`): in 11 all three shells ran out of time; in 2, dash, or dash and bash, were stopped first by the file-size limit (signal 25), as they write their endless output faster, and the others ran out of time. The 14th, `yes | sed -n '200000000,${=;p};200000005q'`, ends near the 5-second limit: on 2026-11-22 dash ran out of time, bash and ShellSpawn ended (timing). Not among the 14:
- `ls -lR / | tee output.file` walks the whole system and also ends near the limit; in the runs of 2026-11-17 and 2026-11-22 it ended in all three, in other runs one or two shells ran out of time (timing).
- `tail -F xxxx | tee -a yyyy &` ends as in the shells: ShellSpawn starts both programs of the job and exits, leaving them running (K5), and the runner kills what is left after 5 s (A18). Before K5 it was a timeout of ShellSpawn alone (known issue [X1](../pspawn-known-issues.md#my-x1)).

### <a id="my-shellspawn-at-exit-the-modes-of-k5-post-0-12-2"></a>ShellSpawn at exit: the modes of K5 (post-0.12, 2026-11-15; run again 2026-11-16 and 2026-11-17, with the code and runner of each day, the last with IN1, then again with A24 (b); post-0.13, 2026-11-22: the same results, sample by sample)

The question (the user, 2026-11-15): would waiting longer at exit make ShellSpawn closer to the shells, by how much, and how does one get it? ShellSpawn starts every command of a background job itself, without fork, so it cannot leave the job behind as the shells do when they exit. What it does at exit is chosen by `PROC_SHELLSPAWN_END` in the environment, or by `$Proc::ShellSpawn::END_WAIT` in the program before it exits ([`../pspawn-design.md`](../pspawn-design.md#my-section-6), section 6; [`t/at-exit.t`](../../t/at-exit.t)):
- `shell` (the default, K5): waits only while ShellSpawn has something left to start for a job, then exits and leaves the job's running programs alone;
- `all`: waits until every job has ended (the behaviour before post-0.12);
- `none`: exits at once, and a job's commands not yet started never start.

Each takes `:SECONDS`, a cap on the wait (`PROC_SHELLSPAWN_END=all:30`).

To measure it, [`tools/large-subset-bgjobs.pl`](tools/large-subset-bgjobs.pl) found, with the parser, the samples with a background job (an and-or list ending in `&`): 44 of the samples the runs take. Each ran 5 times in each mode ([`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) `-end MODE`, the runner waiting up to 5 s for every shell's background jobs, A18), and [`tools/large-subset-repeat.pl`](tools/large-subset-repeat.pl) set the results side by side, with the mode as the environment (record [`tools/large-subset-endmodes.tsv`](tools/large-subset-endmodes.tsv); `make corpus-endmodes`, part of `make corpus-all`). Each row adds up to the 44:

| Mode | ShellSpawn as the shells, every run | ShellSpawn's own result | Shells differing, ShellSpawn as one of them |
|---|---|---|---|
| `shell` (default) | 43 | 0 | 1 |
| `all` | 42 | 1 | 1 |
| `none` | 43 | 0 | 1 |

What came out:
- Waiting longer makes nothing better in the library: no sample comes closer to the shells with `all`, and one comes out worse, `tail -F xxxx | tee -a yyyy &` (NB:9731). There ShellSpawn waits for a job that never ends and runs out of time, as in the runs before K5.
- `none` loses nothing either. So no sample here has a job whose later commands make a visible difference within the run: every job here is one command or one pipeline, which ShellSpawn starts at once (`nohup … &`, `find … | xargs … &`, `tail -F … | tee … &`); none is a list of commands one after another.
- The one sample with the shells differing is `%1 &`: without job control, dash and bash fail in their own ways; ShellSpawn is as one of them, in every run.
- Every sample gave one result per shell in all 5 runs of every mode.

`all` matters for a program that needs a job's results after Perl's own end, or that wants no process of its own left running; it costs the time the jobs take.

### <a id="my-through-run-post-0-09-2026-11-08-again-p"></a>Through Run (post-0.09, 2026-11-08; again post-0.12, 2026-11-18)

Where there is neither posix_spawn nor fork (M2), ShellSpawn starts every process through Run's `start()`, which applies the redirections around Perl's own spawn (`$Proc::Spawner::PRIMITIVE` `system1`). The whole library (with the code of post-0.09 of 2026-11-08, before IP1 came later that day, so with the coreutils programs) ran twice in the same environment (`large-subset-runcompare.pl -env tmp,random,mtime`, section 9 of [`large-subset-environment.md`](large-subset-environment.md#my-section-9)):
- once as usual (posix_spawn);
- once with `-run` (Run 0.07 from repository `ilyaz-ai/run`, commit `a2be65e`, `Run.pm` sha256 `bb490914756f1593…`; `PROC_SPAWNER_MISSING="posix_spawn fork"` for ShellSpawn alone; on Linux Run then emulates the spawn by fork and exec).

| ShellSpawn | Same | Messages only: as dash | as bash | as neither | **ShellSpawn differs** | Shells differ: ShellSpawn as dash | as bash | as neither | Timeout |
|---|---|---|---|---|---|---|---|---|---|
| through posix_spawn | 15,861 | 23,188 | 35 | 88 | **3** | 960 | 104 | 156 | 15 |
| through Run | 15,863 | 23,192 | 34 | 86 | **3** | 962 | 99 | 156 | 15 |

Sample by sample (ShellSpawn's status, output, calls, files and messages, compared as above), ShellSpawn changed between the two runs in 53 = 49 + 4 of the 40,410:
- in 49 of them dash or bash changed too: process IDs (`$$`, `ps`, `pstree`, `/proc/$$`), times (`ls -l /`, `times`), `sort -R`, `xargs -P`;
- in the 4 where ShellSpawn alone changed, the cause is timing as well: the order in which two pipeline elements' messages mix (2), whether `ls` dies of SIGPIPE before `awk` exits (1), and the CPU times `times` prints (1).

So no difference comes from Run. Also passing: Run's own tests (429), and Proc-Spawner's suite through Run (`PROC_SPAWNER_MISSING="posix_spawn fork"`, 71 tests; also with `RUN_AS_WIN32=1`, Run's Win32 code paths). Not tested: Run on a system that really has no fork (Windows ran only the suite's [`t/windows.t`](../../t/windows.t), under Wine).

The run "as usual" was then the run of the library (it replaced post4-0.04's: the user, 2026-11-08, A1(b); its table is in [`../../Changes`](../../Changes), post-0.13).

**Again post-0.12** (2026-11-18, before a release; the code of the run of 2026-11-17, Run 0.07 as on CPAN):
- ShellSpawn alone ran through Run over the whole library (`large-subset-runcompare.pl -run … -shells shellspawn -workers-from`, the environment of `make corpus-run`), joined with that run's dash and bash (`large-subset-runreport.pl -shellspawn-from … -shellspawn-vs …`): ShellSpawn changed in 60 of the 40,410.
- That run was made in another container (its `/etc/passwd`, `/etc/group` and `/usr` differ), so these 60 ran again in the container of 2026-11-18: ShellSpawn through posix_spawn twice, through Run once more.
- Through Run against through posix_spawn, both in that container: 45 differ. Through posix_spawn against through posix_spawn (the primitive we trust): 44 of the same 45 (and through Run against through Run the same 44): process IDs (`$$`, `ps`, `pstree`, `/proc/$$`), times (`times`, `touch` with `date`, `ls -l` outside the run's copy), `sort -R`, `xargs -P`, two `head` on one pipe, inode numbers, `ls -lR /` running out of time.
- The 45th, `find … | xargs ls -lrt | awk print '$9'`, differs in its messages only (`xargs: ls: terminated by signal 13`, given when `ls` writes after `awk` has failed). The message was absent through Run in both runs of the whole library (4 workers at once), and present through both primitives in 6 runs of 6, each run alone: so timing.

No difference comes from Run. Not tested: the run made through fork (posix_spawn missing), and Run on a system that really has no fork (Windows: the library has not run there).

### <a id="my-the-atomic-calls-dash-s-builtin-bash-s-b"></a>The atomic calls: dash's builtin, bash's builtin and the program

The question: ShellSpawn gives `echo`, `printf`, `test`, `[` and `pwd` the behaviour of the coreutils programs, and runs the program `kill`; how far does that set it apart from dash's and bash's builtins? [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl) takes every distinct call that ShellSpawn made to these commands in the run of post-0.13 (`-q`, 2026-11-22) and runs it three ways: `dash -c '"$@"' sh NAME ARGS…`, the same with `bash --posix`, and the program alone.
- The calls: those ShellSpawn ran inside Perl (IP1), and `kill`, which it runs as a program: 650 calls. Another 89, made by `xargs`, are left out, since there every shell runs the program.
- On 2026-11-17 there were 653: since D3 the zenity subshell no longer makes `echo '#2'` and `echo 100` (above), and `. script` (which reads the recorder of the program `script`, whose tests depend on the worker's files) made one test fewer; 13 calls of each run differ from the other run's only in words that vary from run to run (the worker's directory or user, a process ID, the inode number of `/home`).

Every call with its three answers: [`tools/large-subset-threeway-db.jsonl`](tools/large-subset-threeway-db.jsonl) (the database); those where the three do not agree: [`tools/large-subset-threeway-differences.tsv`](tools/large-subset-threeway-differences.tsv). "Samples" sums, over the row's calls, the samples that make each call (a sample that makes several calls counts once for each). The rows are exhaustive: 515+41+2+12+72+8=650 calls, 995+45+2+14+89+9=1,154 samples.

| Who agrees | Calls | Samples |
|---|---|---|
| all three | 515 | 995 |
| all three, but for the messages | 41 | 45 |
| dash = bash, the program differs | 2 | 2 |
| dash = the program, bash differs | 12 | 14 |
| bash = the program, dash differs | 72 | 89 |
| all three differ | 8 | 9 |

| Tool (samples) | Same | Messages | dash = bash ≠ program | dash = program ≠ bash | bash = program ≠ dash | All differ |
|---|---|---|---|---|---|---|
| `echo` | 687 | 0 | 0 | 0 | 66 | 0 |
| `[` | 117 | 38 | 0 | 13 | 6 | 0 |
| `test` | 24 | 2 | 0 | 1 | 1 | 0 |
| `printf` | 80 | 2 | 2 | 0 | 3 | 7 |
| `kill` | 0 | 3 | 0 | 0 | 13 | 2 |
| `pwd` | 87 | 0 | 0 | 0 | 0 | 0 |

What the differences are:
- `echo` (66): `echo -e`, `echo -n -e`, and backslashes (`'a\nb'`, `\5a`): dash's builtin interprets them and prints `-e`, bash and the program do not.
- `[`, `test`: dash = program (14): the unary `-a`, `-o`, `-v`, `-R`, which bash alone has; bash = program (7): `==` and `-N`, which coreutils takes as bash does.
- `kill`: bash = program (13): a word that is no process ID, or `%1`: dash status 2, bash and the program 1; all differ (2): `kill -l`. `kill` with no process ID no longer reaches the program (K0), so it is not in the table.
- `printf`: dash = bash (2): `-v` without a format (both shells fail, status 2; the program prints `-v`); bash = program (3): `%q`, `\x` escapes; all differ (7): `%(…)T` and `-v`.

While making these tables we found that the tools read the call logs wrongly in two ways; this was fixed in 0.12 ([`Changes`](../../Changes)), and the tables above come from the fixed scripts.

### <a id="my-the-atomic-calls-of-external-programs"></a>The atomic calls of external programs

[`large-subset-runreport.pl`](tools/large-subset-runreport.pl) `-x` takes every sample that calls an external program (not one of the coreutils above), compares the programs it called and their arguments as a sorted list, and sorts the samples into the classes of the main table. The row "dash's calls in them" counts the calls dash made in those samples.

| Samples | Run | Same | **ShellSpawn differs** | Shells differ: ShellSpawn as dash | as bash | as neither | Timeout |
|---|---|---|---|---|---|---|---|
| coreutils involved | 677 | 653 | **0** | 0 | 9 | 13 | 2 |
| no coreutils | 15,699 | 15,621 | **0** | 16 | 4 | 52 | 6 |
| all | 16,376 | 16,274 | **0** | 16 | 13 | 65 | 8 |
| dash's calls in them | | 22,349 | 0 | 10 | 24 | 111 | 1,083 |

The table counts the run of post-0.13 of 2026-11-22. Since IN1, a call to a program that is only logged also logs the size and SHA-256 of its input, and since A24 (b) not for a program that never reads it (above).

**Where dash and bash make the same calls** (16,274 samples, 22,349 calls), ShellSpawn makes every one, with the same arguments, and no other. (On 2026-11-17 it made one more, the later `sleep 1` of the `zenity` subshell, before D3: above.)

**Where the shells differ:**
- ShellSpawn as dash in 16 = 15 + 1: `time`, a keyword in bash (15); `bind -P | grep … | perl …`, where only bash's `bind` feeds `perl` something (1).
- ShellSpawn as bash in 13 = 3+5+4+1: `echo -e … | xargs`, the program (3); `echo -e …` into a program only logged (5); `.[^.]*` and `.*`, rule E (4); `printf '\x…'`, the program as bash (1).
- ShellSpawn as neither in 65 (`$0`, `$$`; `v=5 env | less`).

### <a id="my-the-atomic-calls-where-no-program-runs"></a>The atomic calls where no program runs

[`large-subset-builtins.pl`](tools/large-subset-builtins.pl) takes every command of the samples where neither dash nor bash would run a program, as ShellSpawn ran it in the run of post-0.13 (`-q`, 2026-11-22), with its words as expanded there (reported by `$Proc::ShellSpawn::ONBUILTIN`): the builtins (also inside function bodies), settings alone (`x=1`), and commands not found. Each distinct one runs alone in dash, `bash --posix` and ShellSpawn, in the same directory as above. Compared: status, output, the files left, and the messages.
- Calls of functions (114) are not run alone; the commands of their bodies are taken one by one.
- The coreutils tools are in the table above.
- A side effect inside an expansion (`: $((z=3))`) is not in the expanded words, so it is lost when the command runs alone.
- The log is read a line at a time: an argument holding a newline cuts that call short.

| Who agrees | Calls | Samples |
|---|---|---|
| all three | 677 | 1,131 |
| only the messages differ: ShellSpawn as dash's | 24,600 | 26,541 |
| only the messages differ: ShellSpawn as bash's | 0 | 0 |
| only the messages differ: ShellSpawn as neither | 1 | 1 |
| **dash = bash, ShellSpawn differs** | **0** | **0** |
| dash = ShellSpawn, bash differs | 81 | 117 |
| bash = ShellSpawn, dash differs | 34 | 68 |
| all three differ | 41 | 50 |
| ShellSpawn rejects it alone | 18 | 30 |

The table counts the run of post-0.13 of 2026-11-22. Against the run of 2026-11-17 (the records, call by call): 3 calls with an empty command name went from "as neither" to "as dash's" (X72, D2); `cd -` from "all three differ" to "dash = ShellSpawn"; `cd bar1` from "dash = ShellSpawn" to "bash = ShellSpawn", as `cd bar1 find . …`, its whole call since X80 (X54, below); `command -with -flags` (rejected alone) is gone with its sample (D1). The other changes of the counts are calls whose words hold the worker's directory, user or a process ID.

What the classes hold:
- The 24,600 are almost all commands not found (dash's `x: not found` against bash's `x: command not found`).
- As neither (1): `eval app …` (above).
- Dash = ShellSpawn: `%job` words (not found in dash, `fg` without job control in bash), statuses of errors at run time (rule A5: `.` of a missing file, `cd`, `shift`), `alias -g`, `cd -` with `OLDPWD` unset (dash prints the directory, bash fails).
- Bash = ShellSpawn: the interactive builtins (B2), `return` outside a function (rule E), and `cd` with two operands or more (bash fails, dash takes the first: known issue [X54](../pspawn-known-issues.md#my-x54), whether this is allowed is open).
- All three differ: the interactive builtins again (bash prints help or errors), `times`, and `. script`, which reads the program `script` (each fails in its own way).
- Rejected alone (18): what makes sense only where it ran (`break`, `continue`, `local`, `.` alone, `read` or `shift` whose operands came from expansions), the listings `set` and `trap` alone, and `alias '=foo'` (B1).

Every call whose result differs beyond the messages, or that ShellSpawn alone rejects (174 calls), is listed in [`tools/large-subset-builtins-differences.tsv`](tools/large-subset-builtins-differences.tsv); the 24,601 calls that differ in the messages only (24,600 worded as dash's, 1 as neither shell's) are counted in its header, not listed (since post-0.14; each with its answers in the stored runs' `builtins.jsonl`).

### <a id="my-which-samples-depend-on-the-environment"></a>Which samples depend on the environment (known issue [X27](../pspawn-known-issues.md#my-x27); begun post-0.08, 2026-11-07; the levels of post-0.11, 2026-11-13)

The run above gives every sample one fixed environment. So an agreement there is a real one only if the comparison could not come out otherwise elsewhere. [`large-subset-environment.md`](large-subset-environment.md) answers this for every sample, from the parse trees (the user's method: parse in one batch, split into atomic blocks, pass only what is shown unaffected). It sorts the samples into levels. In a count *N*+*M*=*T*, the *N* samples were sorted by [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl), the *M* by Claude (an AI) reading the snippets (categories AI-…; section 1 of [`large-subset-environment.md`](large-subset-environment.md#my-section-1)). The levels, exhaustive (392+2+34,301+671+1,483+3,560=40,409):
- **strict**, 365+27=392: only how the shell is started is assumed;
- **held**, 2: assumptions known to hold in every tested environment (`/dev/null`);
- **almost strict**, 34,301: under named assumptions; 28,321 need only `program`, that a program does the same in each run and the shells look it up alike;
- **with values passed on unchanged, not in preceding rows**, 664+7=671: the same, if also every value from the environment only passes through the shell unchanged (assumption `passthrough`; step 3 of the user's four, section 12 of [`large-subset-environment.md`](large-subset-environment.md#my-section-12));
- **with values passed on split, not in preceding rows**, 1,476+7=1,483: the same, but some of those values are split and globbed into a program's words (`passthrough` and `splitglob`; none needs `splitglob` alone). These two rows are kept apart from almost strict by LV1 (the user, 2026-11-13);
- **undecided**, 3,508+52=3,560: with the codes of what they may depend on (files, variables, a program's output or status taken by the shell, `/tmp`, the whole tree, time, …). The 3,508 of them are *partially decided*: every dependence named exactly and tried in example environments (sections 10 and 12 of [`large-subset-environment.md`](large-subset-environment.md#my-section-10)).

The record, one line per sample by snippet ID: [`large-subset-provenance.tsv`](large-subset-provenance.tsv). [`large-subset-environment.md`](large-subset-environment.md) also has the parse of all the samples as one text (known issue [X30](../pspawn-known-issues.md#my-x30)). Its section 9 has the kinds of workaround for each code and the runs with the environment varied (a second case of `POSIXLY_CORRECT`, the locale, SIGPIPE, `/proc`; a fresh `/tmp`, a fixed `/dev/urandom`, private `/home`, `/var`, `/dev`; stand-ins for programs' status and output; fixed file times), with every changed sample in [`tools/large-subset-env-variants.tsv`](tools/large-subset-env-variants.tsv). Those runs are given as footnotes to the levels' totals (EV1).


## <a id="my-files"></a>Files

- [`tools/large-subset-features.pl`](tools/large-subset-features.pl): the detector (the features of a text) and the mapping of ShellCheck codes, each with verdict and basis; `-n TESTFILE…` prints the per-test record (redirect it to [`t/parser/large-subset-shells.tsv`](../../t/parser/large-subset-shells.tsv)).
- [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt): verdicts kept by hand, including the postponed free-form ones.
- [`tools/large-subset-runcompare.pl`](tools/large-subset-runcompare.pl), [`tools/large-subset-runreport.pl`](tools/large-subset-runreport.pl), [`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv), [`tools/large-subset-threeway.pl`](tools/large-subset-threeway.pl), [`tools/large-subset-threeway-db.jsonl`](tools/large-subset-threeway-db.jsonl), [`tools/large-subset-threeway-differences.tsv`](tools/large-subset-threeway-differences.tsv), [`tools/large-subset-builtins.pl`](tools/large-subset-builtins.pl), [`tools/large-subset-builtins-differences.tsv`](tools/large-subset-builtins-differences.tsv), [`tools/large-subset-programs.txt`](tools/large-subset-programs.txt), [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv), [`tools/large-subset-bgjobs.pl`](tools/large-subset-bgjobs.pl), [`tools/large-subset-repeat.pl`](tools/large-subset-repeat.pl), [`tools/large-subset-endmodes.tsv`](tools/large-subset-endmodes.tsv), [`tools/large-subset-blocks.pl`](tools/large-subset-blocks.pl): [section 7](#my-section-7) and [`large-subset-environment.md`](large-subset-environment.md), with its record [`large-subset-provenance.tsv`](large-subset-provenance.tsv).
- [`tools/large-subset-yardsticks.pl`](tools/large-subset-yardsticks.pl): the parse results of [section 3](#my-section-3). `-o` writes one line per sample; `-c` caches ShellCheck's messages, so later runs need no ShellCheck.
- [`large-subset-dialect-features.md`](large-subset-dialect-features.md): the feature list with every probe result.
- [`../test-pools.md`](../test-pools.md): how to rebuild every test pool and measurement.
