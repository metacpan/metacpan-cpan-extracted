# The POSIX ceiling, and the steps taken to make the corpus figures honest (2026-11-02)

## 1. What is measured

For each corpus sample we ask whether `Proc::ShellSubset::Large` accepts it, and compare with a **ceiling**: the share that a
dash-and-bash interpreter could accept at most. A sample is inside the ceiling when

1. `dash -n` and `bash --posix -n` both accept it, and
2. it uses no construct that only bash runs.

Condition 2 needs a detector. Until 2026-11-01 it was a regex scan (`large-subset-scan.pl`, first version). The
investigation of 2026-11-02 found that this made the figures misleading in both directions:

- **Ceiling too high** (bash-only samples counted as POSIX): `dash -n` checks syntax only, so it passes many
  bash-only forms that fail later or read as ordinary words (`x+=1`, `$((i++))`, `${*//a/b}`, `trap f ERR`,
  `read -u 3`, `foo{1,2,3}`, `if [[ … ]]`). The regex missed them. Then rejections by the large grammar inside the
  ceiling looked like gaps in our parser when they were not. On the ShellCheck snippets this inflated the gap from
  about 1 point to 11–15 points.
- **Ceiling too low** (POSIX samples counted as bash-only): the regex also looked inside quoted text
  (`ag '^ca(t|r)$'` was taken for `$'…'`, `"**/*.{js,ts}"` for brace expansion) and took the POSIX `${x:-default}`
  for a bash form. Then the large grammar accepted samples outside the ceiling (33 in tldr).
- **Samples that are not shell at all** in the denominator: tldr writes keystrokes of interactive programs in the
  same backquotes as commands (`<q>`, `<Ctrl c>`, `<ArrowLeft>|<ArrowRight>`).

## 2. The steps

| # | Step | Where | Effect |
|---|---|---|---|
| 1 | tldr: a line of key notation only is not a command and is left out (regex `KEYS` in the script) | `large-subset-extract.pl` | 163 tldr lines out of 29,672 unique |
| 2 | tldr: an argument or pipeline element `...` ("and so on") is dropped | `large-subset-extract.pl` | 899 lines (counting duplicates) lose a `...`; most were accepted already, with `...` as a literal word; of those rejected before, 17 change and 3 become valid (`read variable1 variable2`); the original is kept as `orig` |
| 3 | ShellCheck as the detector of bash-only constructs: `shellcheck -s dash` (shellcheck-py 0.11.0.1); any portability warning SC3xxx puts the sample outside the ceiling | `large-subset-scan.pl` (`sc`) | the ceiling's definition from now on |
| 4 | The regex detector kept as a cross-check, fixed: quoted text blanked first (`'…'` always; `"…"` except the `$( )` and `${ }` in it); `${x:-…}` no longer a bash form; command position also after `if`, `while`, `until`; new forms: `$"…"`, `$[…]`, `++`/`--` in arithmetic, `NAME+=`, `${*/…}`/`${@/…}`, `foo{a,b}` (also after a word), `{fd}>`, `>& word`, `$(<file)`, `trap … ERR`/`SIGxxx`/`-l`/`-p`, bash-only options of `export wait local exec hash jobs umask readonly unset cd type set -o` | `large-subset-scan.pl` (`rx`) | reported as column `ceil-rx`, and where the two disagree |
| 5 | Our own parser's messages that name bash, as a second cross-check | `large-subset-scan.pl` (`pm`) | column `pm-only`: samples the parser calls bash-only but ShellCheck does not |
| 6 | Samples the large grammar accepts outside the ceiling are counted (should be near 0) | `large-subset-remeasure.pl` (`out`) | catches a detector that is too eager, or a parser that is too lenient |
| 7 | The genuine POSIX gaps found on the way are closed in the parser (D2(A)): redirections without a command, settings with redirections (when no `$` or backquote can show the shells' different order), backslash-newline inside words | `lib/Proc/ShellSubset/Large.pm`, spec section 3 | about 12 ShellCheck snippets, 1 tldr line |
| 8 | ShellCheck test strings that are wrong where they stand are left out: `return`, `local`, `break`, `continue` outside their function or loop, an `exit` or `return` status outside 0–255 (ShellCheck's own codes SC2104–2106, SC2151, SC2152, SC2168, SC2242). Its "error" level in general is no guide: it is also given to valid code such as an unquoted `$@` (SC2068) | `large-subset-drops.pl` | 16 snippets (3 clean, 13 warned) |
| 9 | Every left-out sample is recorded with its reason in `drops.tsv` (source, ID, reason): make book, duplicates (with the ID kept), tldr key notation, ShellCheck scope errors; `large-subset-remeasure.pl -d drops.tsv` leaves them out and counts them by reason. Exclusions are not part of the headline figures, as before for duplicates | `large-subset-drops.pl`, `large-subset-remeasure.pl` | 2,719 duplicates, 163 key-notation lines, 16 scope errors |

Not done: the make book stays out of the scan (its extraction is noisy); NL2Bash and the scripts get no filters.

## 3. Results

Measured 2026-11-02 with `Proc::ShellSubset::Large` including D2 (and the three D2 corrections of section 2, step 7), on 42,025 samples (after the exclusions of steps 1, 8, 9).

| Source | Samples | Proc::ShellSubset | **Proc::ShellSubset::Large** | **Ceiling** (ShellCheck) | Ceiling (regex) | Large, outside | Inside, rejected |
|---|---|---|---|---|---|---|---|
| tldr | 29,509 | 98.3% | **98.8%** | **99.2%** | 99.1% | 13 | 126 |
| NL2Bash | 10,624 | 89.5% | **92.1%** | **94.6%** | 93.5% | 36 | 302 |
| bash Cookbook | 81 | 14.8% | **30.9%** | **37.0%** | 38.3% | 0 | 5 |
| pure-sh-bible | 44 | 47.7% | **95.5%** | **100%** | 95.5% | 0 | 2 |
| pure-bash-bible | 122 | 28.7% | **39.3%** | **44.3%** | 46.7% | 0 | 6 |
| ShellCheck, clean | 879 | 42.1% | **58.7%** | **67.2%** | 65.3% | 13 | 88 |
| ShellCheck, warned | 766 | 46.2% | **57.6%** | **61.7%** | 64.4% | 22 | 54 |

Before these steps (spec section 8, 2026-11-02 morning: old regex, no tldr rules, no D2) the pairs large/ceiling were: tldr 98.3/98.8, NL2Bash 92.1/93.6, Cookbook 30.9/43.2, pure-sh 93.2/93.2, pure-bash 38.5/48.4, ShellCheck clean 58.4/69.4, warned 56.5/71.2.

**Samples the large grammar accepts outside the ceiling (84)** are all forms where the subset runs a program in place of dash's builtin, so ShellCheck's portability warning applies to dash, not to us: `echo` options (48, SC3036; decision K2: `/bin/echo`), `[`/`test` operators (29: SC3014 `==`, SC3015 `=~`, SC3016 `-v`, SC3017 unary `-a`, SC3062–3064; the program `/usr/bin/[` of coreutils, see section 5), `printf` options (6, SC3045, SC3050), `time` (1, SC3061; decision K1).

**Where the detectors disagree** (samples that dash and bash accept): the regex alone flags 256, mostly constructs dash actually runs (`read -p`, `local -x`) or builtin names that are arguments of other programs (`select`, `help` in tldr's descriptions of interactive tools); ShellCheck alone flags 91, mostly forms the regex never knew (`[^…]` in patterns SC3026, `${x//a/b}` inside `$( )` in strings, `$RANDOM`-like variables). ShellCheck is the better detector; the regex stays as a cross-check. Our parser names bash where ShellCheck sees nothing in 23 samples (`pm-only`): these are not bash-only syntax but forms both shells accept with different meanings, which ShellCheck does not look for: an input redirection without a command (10), `NAME[` as a command (8), `$@` where it is not split (2), settings with a redirection and `$` (2), `&>` (1).

**What is still rejected inside the ceiling** (583 samples) is, by the parser's messages: builtins left to sh (tldr 72 of 126, NL2Bash 168 of 302: `alias`, `history`, `jobs`, `type`, `source`, …), argument forms of builtins (`read $var`, `export -p`, `local -r`), listing forms (`set`, `trap`), shell-set variables (`PS1=`, `_=`), dialect items of "Shell Dialect Choices" (`$@` and `${@%p}` forms, `[^…]`, `.*`, `local` without a value) (ShellCheck's scope errors are left out since step 8).


## 4. How to reproduce

1. Restore the corpora as in `doc/parsers/shell-subset-test-provenance.md` section 4 (a shallow `git fetch --depth 1 origin COMMIT` per repository is enough; the make book is not needed).
2. `pip install shellcheck-py==0.11.0.1` (puts `shellcheck` 0.11.0 in PATH).
3. With the parsers of the pspawn bundle (`parser/`, D2 patches applied) and the scripts from `claude/large-subset-measure.tar.gz-base64.txt`:
   ```sh
   perl large-subset-extract.pl CORPORA samples.jsonl
   perl -Ilib large-subset-scan.pl samples.jsonl > large-scan.jsonl    # about 25 minutes
   perl large-subset-drops.pl samples.jsonl drops.tsv                           # reasons for leaving samples out
   perl large-subset-remeasure.pl -v -d drops.tsv large-scan.jsonl
   perl -Ilib large-subset-scan.pl --rx 'STRING' …                    # try the regex detector
   ```

Columns of `large-subset-remeasure.pl`: `subset` Proc::ShellSubset with all options; `large` Proc::ShellSubset::Large; `ceiling`
dash and bash accept, ShellCheck no SC3xxx; `ceil-rx` the same with the regex detector; `out` accepted by the large
grammar but outside the ceiling; `in-rej` inside the ceiling but rejected; `sc-only`/`rx-only` samples that dash
and bash accept where only one detector sees a bash-only construct; `pm-only` our parser names bash, ShellCheck sees nothing.

## 5. Found on the way

- **D2 regressions, fixed the same day.** Accepting redirections without a command let three bash/dash differences through, which the cross-check (column `out`) showed at once: `cmd &>file` (dash: `cmd &`, then `>file`; bash: both outputs to the file), `$(<file)` and `` `<file` `` (dash: empty; bash: the file's text), and, unrelated to D2 but found the same way, `/dev/tcp/…` and `/dev/udp/…` as targets (bash opens a socket; checked before Proc::ShellSubset too, which took them for files). All three are now rejected (tests LS:206–211).
- **`[` and `test` (open, for the user).** The subset runs the program `/usr/bin/[` (coreutils), not dash's builtin. They differ: `[ a == a ]` is 0 in coreutils and bash, an error (2) in dash; `test a \< b` is 0 in dash and bash, an error (2) in coreutils; `[ -v HOME ]` is 0 in bash only. This is a difference like K2 (`echo`), not yet on the page "Shell Dialect Choices".

## 6. Two yardsticks (2026-11-02, the user's definition; replaces the single ceiling for the headline figures)

- **Upper, "nothing bogus found":** `dash -n` and `bash --posix -n` both accept the sample, ShellCheck (`-s dash`) gives no SC3xxx warning, and our parser did not reject it for a difference where one shell errors or gives a blatantly different result.
- **Lower, "compatible":** in addition, our parser did not reject it for a subtle difference (listing formats, `.*`, `[^…]`, `$@` joining, `local x`, the order of assignment and redirection, `read -p`, …).

Which parser messages count as blatant or subtle is a judgement, listed in `large-subset-yardsticks.pl` (`@BLATANT`, `@SUBTLE`) and put to the user as item Y1 on the page "Shell Corpus Gaps" (https://claude.ai/artifact/MXuAmoBmWRkjUAiRVnYtmN), together with the next filters and parser additions. Checked in both shells: `set -o vi`/`emacs` and `break`/`continue` outside a loop are no difference; `trap … SIGINT` fails in dash ("bad trap").

| Source | Samples | Accepted | Lower | Upper | Within lower, rejected |
|---|---|---|---|---|---|
| tldr | 29,509 | 98.8% | 99.1% | 99.1% | 105 |
| NL2Bash | 10,624 | 92.1% | 93.9% | 94.5% | 235 |
| bash Cookbook | 81 | 30.9% | 34.6% | 35.8% | 3 |
| pure-sh-bible | 44 | 95.5% | 97.7% | 97.7% | 1 |
| pure-bash-bible | 122 | 39.3% | 41.8% | 41.8% | 3 |
| ShellCheck, clean | 879 | 58.7% | 61.5% | 63.5% | 38 |
| ShellCheck, warned | 766 | 57.6% | 56.9% | 58.1% | 17 |

Usage: `perl large-subset-yardsticks.pl [-v] samples.jsonl large-scan.jsonl drops.tsv`.
