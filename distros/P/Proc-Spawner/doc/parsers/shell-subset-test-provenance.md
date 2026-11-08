# Shell subset tests: snippet IDs and provenance

Status: 2026-10-29. Covers the two test files of the shell-subset parser ([`ShellSubset.pm`](../../lib/Proc/ShellSubset.pm)):

- [`shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl): 204 hand-written tests, one rule of [`shell-subset-spec.md`](shell-subset-spec.md) per line.
- [`shell-subset-corpus-tests.pl`](../../t/parser/shell-subset-corpus-tests.pl): 612 tests taken from public collections of shell commands, one per group of very similar commands.

Every test line carries a **snippet ID** that says where its text comes from. (The same IDs name the 40,410 corpus samples of the large parser's measurement: [`../large-subset/large-subset-provenance.tsv`](../large-subset/large-subset-provenance.tsv) has one line per sample, by ID, with what its run-time comparison may depend on, known issue X27; the codes: [`../large-subset/large-subset-environment.md`](../large-subset/large-subset-environment.md).) With the pinned sources below, [`prov.pl`](tools/prov.pl) restores the text of every corpus test from its ID alone; on 2026-10-29 all 612 restored exactly.

## 1. Test line format

```
ok|rej  OPTIONS  ID  TEXT
```

- `ok` / `rej`: the expected result (parsed, or rejected).
- `OPTIONS`: parser options separated by commas, or `-` for none (`nocaret`, `nopwd`, `assign`, `param_ops`, `if`, `while`, `for`, `case`, `read`, `brace`, `empty`, `fdmulti`, `tilde_args`).
- `ID`: the snippet ID (section 2). It contains no blanks.
- `TEXT`: the string given to the parser, after one or two blanks. `@N`, `@T` and `@R` stand for newline, tab and carriage return.

In the corpus file, the line before each test starts with `#` and names its group (section 5).

## 2. Snippet IDs

An ID is `PREFIX:LOCATOR`. The prefix names the source:

| Prefix | Source | Locator | Example |
|---|---|---|---|
| `OWN` | written by hand for this project | test number in [`shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl) | `OWN:17` |
| `TL` | tldr pages | page file under `pages/`, line number | `TL:common/abduco.md:8` |
| `NB` | NL2Bash, `data/bash/all.cm` | line number | `NB:1499` |
| `SC` | ShellCheck unit tests | file under `src/ShellCheck/`, test name, position in the test string | `SC:Analytics.hs:prop_checkSpuriousExec1:1e9` |
| `BC` | bash Cookbook examples | file path, position | `BC:ch10/ad:103c9` |
| `PS` | pure-sh-bible | `README.md`, position | `PS:README.md:426` |
| `PB` | pure-bash-bible | `README.md`, position | `PB:README.md:558c5-559` |
| `MK` | *Managing Projects with GNU Make*, 3rd ed. | kind, PDF page `.` line on that page | `MK:recipe:53.2` |

A **position** in a file or test string is

```
LINE[cCOL][-ENDLINE][eLASTCOL]
```

- `LINE`: the first line (1-based). For `SC`, lines of the test string after its Haskell escapes are undone; for `PS` and `PB`, lines of `README.md`.
- `cCOL`: the snippet starts at this column of the first line (1-based); omitted when it starts at the line's first non-blank character.
- `-ENDLINE`: the snippet ends on this line; omitted when it is a single line.
- `eLASTCOL`: the snippet ends at this column of its last line; omitted when it runs to the end of the line.

The snippet is that span with leading and trailing white space removed. Examples from the table: `BC:ch10/ad:103c9` is line 103 of `ch10/ad` from column 9 to the end of the line; `PB:README.md:558c5-559` runs from line 558, column 5, to the end of line 559; `SC:Analytics.hs:prop_checkSpuriousExec1:1e9` is the first line of that test's string, up to column 9.

`MK` kinds: `prompt` (a line `$ command` in the book's text; the snippet is what follows `$ `), `recipe` (a recipe line of a makefile shown in the book, with its `\` continuation lines), `shell` (the argument of `$(shell …)`; `#K` after the locator counts the occurrences on that line). Page breaks are the form feeds that `pdftotext` writes; the line count restarts on each page.

When the same text occurs in several places, its ID names the first occurrence in this order: TL, NB, SC, BC, PS, PB, MK, and within a source the order in which [`extract.pl`](tools/extract.pl) reads the files.

## 3. Sources (pinned)

The IDs are valid for exactly these versions.

| Prefix | Source | Version | License |
|---|---|---|---|
| TL | https://github.com/tldr-pages/tldr | commit `f4566462f5996e13a4f3523f21dc2a863aec53c1` (2026-10-28) | pages CC BY 4.0 |
| NB | https://github.com/TellinaTool/nl2bash | commit `d6b9f5bdff45621d190134e31ab63b7bf7002190` (2026-04-18) | GPL-3.0 |
| SC | https://github.com/koalaman/shellcheck | commit `919d37c4d77a7ce16cfc76ebdd781dd6e8081fa5` (2026-10-25) | GPL-3.0 |
| BC | https://github.com/vossenjp/bashcookbook-examples | commit `7fc1db649a85eaa5d6c6631397136100763db70f` (2022-04-15) | MIT |
| PS | https://github.com/dylanaraps/pure-sh-bible | commit `26bc7e8d6cfb8716e9ccb97f31c2da80468c5737` (2021-07-22) | MIT |
| PB | https://github.com/dylanaraps/pure-bash-bible | commit `8c19d0b482b04d8d50fb72b4c5148b41ce605c6d` (2020-10-21) | MIT |
| MK | Robert Mecklenburg, *Managing Projects with GNU Make*, 3rd ed. (O'Reilly, 2004), PDF | see below | GNU FDL 1.2 |

The MK PDF: `Managing Projects with GNU Make, 3rd Edition.pdf`, 2,452,105 bytes, 302 pages, SHA-256 `b188a032481ff3b41a84f96b86a3e89b75b63c847e19344dd2edc04220fd88b0`, downloaded from `https://raw.githubusercontent.com/yjjing/ebooks/master/Managing%20Projects%20with%20GNU%20Make%2C%203rd%20Edition.pdf` (the same file is in the repository `a10ncoder/books`). Text made with `pdftotext -layout` from poppler 24.02.0; the resulting `make3.txt` has SHA-256 `866d44b86ac8fccc510ed31970b30ea7dc780d12e8681017d6d3f8489d6324d6`. Another `pdftotext` version may break lines differently and shift the MK locators.

## 4. Restoring the sources

```sh
mkdir corpora && cd corpora
for r in tldr-pages/tldr TellinaTool/nl2bash koalaman/shellcheck \
         vossenjp/bashcookbook-examples dylanaraps/pure-sh-bible dylanaraps/pure-bash-bible; do
  git clone -q https://github.com/$r
done
git -C tldr checkout -q f4566462f5996e13a4f3523f21dc2a863aec53c1
git -C nl2bash checkout -q d6b9f5bdff45621d190134e31ab63b7bf7002190
git -C shellcheck checkout -q 919d37c4d77a7ce16cfc76ebdd781dd6e8081fa5
git -C bashcookbook-examples checkout -q 7fc1db649a85eaa5d6c6631397136100763db70f
git -C pure-sh-bible checkout -q 26bc7e8d6cfb8716e9ccb97f31c2da80468c5737
git -C pure-bash-bible checkout -q 8c19d0b482b04d8d50fb72b4c5148b41ce605c6d
curl -sSL -o make3.pdf 'https://raw.githubusercontent.com/yjjing/ebooks/master/Managing%20Projects%20with%20GNU%20Make%2C%203rd%20Edition.pdf'
sha256sum make3.pdf          # must be b188a032…88b0
pdftotext -layout make3.pdf make3.txt
sha256sum make3.txt          # 866d44b8…24d6 with poppler 24.02.0
```

Then, with the scripts in [`doc/parsers/tools/`](tools) (formerly `corpus-run.tar.gz`; how to rerun them: [`doc/test-pools.md`](../test-pools.md)):

```sh
perl prov.pl CORPORA_DIR TL:common/abduco.md:8      # print one snippet
perl prov.pl CORPORA_DIR --check shell-subset-corpus-tests.pl   # restore and compare all IDs
```

The NL2Bash repository is large (about 220 MB, mostly other data); only `data/bash/all.cm` is used.

## 5. How the samples were taken and the tests chosen

The scripts, in order (all in [`doc/parsers/tools/`](tools), formerly `corpus-run.tar.gz`):

1. [`extract.pl`](tools/extract.pl) `CORPORA_DIR samples.jsonl` collects samples:
   - TL: every line of `pages/common/*.md` and `pages/linux/*.md` that is a command in backquotes. Placeholders are filled in: `{{[-a|--all]}}` becomes `-a` (the first alternative), `{{text}}` becomes `text`.
   - NB: every line of `data/bash/all.cm`.
   - SC: the test string of every line `prop_NAME = verify…` or `verifyNot…` (also `…Tree`) in the Haskell sources, with Haskell escapes undone. `verifyNot` tests are tagged "clean", `verify` tests "warned" (ShellCheck expects a warning).
   - BC: every file under a `chNN/` directory, as a script.
   - PS, PB: every fenced code block in `README.md` marked `sh`, `shell`, `bash` or nothing, as a script.
   - MK: prompt lines `$ command`; recipe lines (lines indented deeper than a preceding `target:` line, minus `endif`, `define`, assignments and similar make syntax), joined with their `\` continuations; and `$(shell …)` arguments. In recipes and `$(shell …)`, make syntax is replaced: leading `@`, `-`, `+` removed, every `$(…)`, `${…}` and automatic variable (`$@ $< $^ $? $* $+ $%`) replaced by the word `MAKEVAR`, and `$$` turned into `$`.
2. [`run.pl`](tools/run.pl) `samples.jsonl` parses each sample. One-line samples are parsed whole. Scripts are cut into pieces: when parsing fails, the text up to the last top-level `;`, `&` or newline before the failure is kept as an accepted piece; the rest of the failing line (up to the end of a here-document, for those) is a rejected piece; parsing goes on after it. Identical samples within a source are dropped. Accepted pieces are also checked with `dash -n` and `bash -n`. Output: `results.jsonl`.
3. [`group.pl`](tools/group.pl) forms the groups. Accepted one-liners, and each line of an accepted script piece that parses on its own, are grouped by their set of features: operators, subshells and groups, special command names, kinds of expansion in words, kinds of redirection. Rejected samples are grouped by error message (builtin, keyword and variable names collapsed), plus, for some messages, the shape of the text at the error. Each group keeps one test: the shortest sample that starts with a letter and has at least 6 characters, or else the shortest sample. Output: [`groups.tsv`](tools/groups.tsv) (result, size, sources, group, ID, text).
4. [`gentests.pl`](tools/gentests.pl) writes [`shell-subset-corpus-tests.pl`](../../t/parser/shell-subset-corpus-tests.pl) from [`groups.tsv`](tools/groups.tsv), and gives the hand-written tests their `OWN:n` IDs.
5. [`verify.pl`](tools/verify.pl) runs each accepted test under dash and bash with a recorder in place of every external command, and compares the recorded argv with the parse tree (see the report of 2026-10-29).

Counts on 2026-10-29: 29,672 TL one-liners, 10,624 NB, 330 MK, 81 BC scripts, 44 PS and 122 PB code blocks, 1,667 SC test strings (after removing duplicates within a source). They give 337 accepted and 275 rejected groups.

## 6. Limits

- The MK extraction is heuristic: some "recipe lines" are prose or make syntax that the filter missed.
- tldr examples contain notation that is not shell syntax (`on|off` for alternatives, `<Ctrl> + c` for keys); such strings are kept as found.
- NL2Bash commands are cut out of larger scripts, so many use `$1` and similar.
- The IDs of the hand-written tests (`OWN:n`) number the lines of [`shell-subset-tests.pl`](../../t/parser/shell-subset-tests.pl); a new hand-written test gets the next free number, and numbers are never reused.
