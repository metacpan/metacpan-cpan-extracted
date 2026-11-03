# Shell subset: corpus coverage and failure statistics

Status: measured on 2026-10-29/30 with `ShellSubset.pm` of 2026-10-29 (options `assign`, `param_ops`, `if`, `while`, `for`, `case`, `read` implemented). Sources and snippet IDs: `shell-subset-test-provenance.md`. Scripts: `corpus-run.tar.gz-base64.txt` (`chunkcov.pl`, `top5.pl`, `top5-lines.pl`).

"Default" means no options; "all options" means the seven options above turned on.

## 1. One-liners accepted

| Source | One-liners | Accepted (default) | Accepted (all options) |
|---|---|---|---|
| tldr | 29,672 | 97.6% | 97.7% |
| NL2Bash | 10,624 | 86.4% | 89.6% |
| GNU make book | 330 | 73.3% | 76.1% |

## 2. Scripts: chunk model

The model: the executor runs each maximal accepted stretch of a script itself and hands each rejected top-level construct to `sh`. A rejected construct ends at the shortest run of whole lines that `bash -n` accepts, so a whole `if … fi`, function or here-document is one piece. Lines are non-blank, non-comment lines.

Columns:
- **Line coverage**: the share of lines in accepted pieces.
- **Prefix**: the share of lines before the first rejected piece. This is what an executor gets if it hands over only once.
- **Handoffs**: runs of consecutive rejected pieces per script, at least 1 for every script not accepted whole. The last column covers only scripts with both accepted and rejected parts.

### 2a. All scripts

| Source | Scripts | Line coverage | Prefix | Accepted whole |
|---|---|---|---|---|
| bash Cookbook examples | 81 | 6% → 19% | 2% → 12% | 2 → 12 |
| pure-sh/bash-bible (code blocks) | 151 | 26% → 37% | 25% → 35% | 37 → 48 |
| ShellCheck test snippets | 1,651 | 34% → 47% | 32% → 46% | 554 → 782 |

(default → all options)

### 2b. Only scripts not accepted as a whole

| Source | Scripts | Line coverage | Prefix | Nothing accepted | At least half accepted | Handoffs/script | Handoffs (mixed scripts) |
|---|---|---|---|---|---|---|---|
| bash Cookbook | 79 → 69 of 81 | 5% → 11% | 1% → 4% | 59 → 37 | 2 → 6 | 1.2 → 1.3 | 1.8 → 1.6 |
| pure-sh/bash-bible | 114 → 103 of 151 | 5% → 9% | 3% → 6% | 103 → 88 | 8 → 10 | 1.0 → 1.0 | 1.0 → 1.1 |
| ShellCheck snippets | 1,097 → 869 of 1,651 | 2% → 3% | 0% → 1% | 1,077 → 841 | 14 → 22 | 1.0 → 1.0 | 1.1 → 1.1 |

Other measurements:
- **Rejected lines inside multi-line constructs:** 83–93% for the cookbook and the bibles, 6–7% for the ShellCheck snippets.
- **Delegating only the offending inner line would recover little:** of the lines in the rejected multi-line pieces of the cookbook and the bibles (all options), only 272 of 1,568 parse on their own.
- **State dependencies:** a rejected piece sets a variable or function, or does a `cd`, that a later accepted piece uses. This was found in 13 cookbook scripts, 2–4 bible blocks and 3–5 ShellCheck snippets (heuristic). No `cd` dependencies were found.

## 3. Why the parser stops: scripts

Each rejected piece (after an accepted stretch, or at the start of a script) is counted under the error the parser gives for it. Percentages are of the source's rejected pieces; the share of rejected lines is in brackets. The constructs are interpretations of the parser's messages.

### All options

| Source (rejected pieces / lines) | #1 | #2 | #3 | #4 | #5 |
|---|---|---|---|---|---|
| bash Cookbook (184 / 1,282) | `$1`, `${x%…}` and other parameter forms: 26% [15%] | lone `{`, mostly function bodies: 10% [18%] | `export`: 8% [1%] | `function f`: 7% [7%] | `((…))`: 6% [8%] |
| pure-sh/bash-bible (153 / 457) | function definition `f() {`: 42% [67%] | parameter forms (`${key##…}`): 9% [5%] | brace expansion `{0..100}`: 9% [4%] | command name from an expansion (`"$EDITOR" file`): 9% [6%] | `((…))`: 5% [2%] |
| ShellCheck snippets (940 / 983) | parameter forms (`${!var}`, `$@`): 15% [15%] | command name from an expansion: 15% [15%] | function definitions, `( $@ )`: 12% [12%] | `set`: 8% [7%] | brace expansion `{1,2,3}`: 5% [6%] |

### Default options

| Source (rejected pieces / lines) | #1 | #2 | #3 | #4 | #5 |
|---|---|---|---|---|---|
| bash Cookbook (259 / 1,486) | only assignments (`DBLIST=$(…)`): 21% [4%] | parameter forms: 17% [11%] | `if`: 8% [9%] | lone `{`: 7% [16%] | `export`: 5% [1%] |
| pure-sh/bash-bible (178 / 536) | function definition: 34% [56%] | only assignments: 9% [3%] | parameter forms: 8% [4%] | `for`: 8% [8%] | brace expansion: 8% [3%] |
| ShellCheck snippets (1,128 / 1,172) | only assignments: 19% [19%] | parameter forms: 13% [13%] | command name from an expansion: 11% [11%] | `set`: 7% [6%] | function definitions: 6% [6%] |

## 4. Why the parser stops: one-liners (all options)

Percentages are of the source's rejected one-liners.

| Source (rejected) | #1 | #2 | #3 | #4 | #5 |
|---|---|---|---|---|---|
| tldr (676 of 29,672 = 2.3%) | a builtin: 49% (`command` 14%, `help` 3%, `set` 2%, `eval` 2%, `source` 2%) | tldr notation for keys (`<q>`, `<ArrowUp>`): 28% | command name from an expansion, mostly `[[ … ]]`: 4% | lone `{` (`{ cmd1; cmd2; ...; }`, `{*}`): 3% | `(`, mostly SQL or prose: 2% |
| NL2Bash (1,110 of 10,624 = 10.4%) | a builtin: 30% (`alias` 7%, `set` 5%, `shopt` 4%, `history` 4%) | `$$`, `$1`, `$@`: 23% | process substitution `<(…)`: 15% | `read` with options other than `-r`: 7% | `$'…'`: 5% |
| GNU make book (79 of 330 = 24%) | comment only (prose picked up by the extraction): 32% | `$@`, `$1` and the like: 27% | a builtin (`export`, `shopt`, `command`): 9% | stray `)` from the extraction: 8% | `(` in prose: 6% |

With default options the picture is almost the same. The options removed three buckets:
- NL2Bash: 19% "only assignments" and 6% keywords.
- The make book: 18% keywords.
- tldr: 5% keywords.

## 5. Conclusions

- **Function definitions are the largest gap in scripts,** together with `$1` and the like, which mostly occur inside functions. Next come command names that come from an expansion, and `((…))`.
- **One-liner rejections are mostly not shell-subset gaps.** They are builtins that are pointless in `system()` (`alias`, `history`, `help`), notation that is not shell, or extraction noise. The real gaps there are positional parameters and bash-only syntax.
- **Report two numbers, not one:** the share of scripts accepted whole, and line coverage within the rest. Mixing them hides how little chunking recovers today.

## 6. Caveats

- These are static line counts, not weighted by how often a line runs.
- The corpora are tutorial and test code.
- The make-book extraction is noisy.
- The dependency check is a heuristic based on patterns.
