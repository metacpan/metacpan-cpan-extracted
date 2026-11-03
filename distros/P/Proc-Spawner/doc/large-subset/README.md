# Proc::ShellSubset::Large: the large parser, its specification and its measurements

Written with Claude by the parser session (file prefix `large-subset-`), 2026-11-01 and 2026-11-02. The module was
called `ShellSubsetLarge` until the distribution moved every module under `Proc::` (2026-11-02). The current
documents below use the new names; the historical ones keep the names of their day.

| File | What |
|---|---|
| `large-subset-spec.md` | **The specification** (current): what the large grammar accepts beyond `Proc::ShellSubset`, the rules where dash and bash differ (A3), the tree additions, the rules for the executor at run time (A4: status 248, A5: as dash), tests and measurements. |
| `large-subset-ceiling.md` | **How the corpus figures are measured** (current): the corpora, what is left out and why, the two yardsticks ("nothing bogus found" and "compatible"), the results of 2026-11-02, how to reproduce them. |
| `large-subset-investigation.md` | The investigation that started the large parser (2026-11-01), with the first ceiling. Historical. |
| `large-subset-upstream-reports.md` | Bugs found in the other components (U1–U5 parser, L1–L10 executor) and requests to the posix_spawn session (A4, D2). Historical record; the open ones are tracked in `../pspawn-known-issues.md`. |
| `large-subset-marks.md` | The marks of the two checklist pages as of 2026-11-02 morning. Historical. |
| `tools/` | The measurement scripts (not run by `make test`): `large-subset-extract.pl` (corpora to `samples.jsonl`), `large-subset-scan.pl` (both shells, ShellCheck, both parsers; `--rx STRING` tries the regex detector), `large-subset-drops.pl` (left-out samples with reasons), `large-subset-remeasure.pl`, `large-subset-yardsticks.pl` (the reports), `large-subset-reparse.pl` (refresh the parser fields after a parser change). Usage in each script's header and in `large-subset-ceiling.md`, section 4. |
| `dialect-cases/` | The examples of the page "Shell Dialect Choices", with their output in dash 0.5.12 and `bash --posix` 5.2.21 (`run-cases.sh` reruns them). |
| `pages/` | Sources of the three checklist pages (`../checklists/large-subset.html`, `dialect-choices.html`, `corpus-gaps.html`): item texts, ledes, and the builders `build.pl`, `build2.pl` (the latter adds the Parts menu). |

The base parser's documents (from an earlier session) are in `../parsers/`: `shell-subset-spec.md` (the grammar of
`Proc::ShellSubset`; `Proc::ShellSubset::Small` is the same grammar with fewer options), `shell-subset-test-provenance.md`
(where the corpus tests in `t/parser/shell-subset-corpus-tests.pl` come from, and how to restore the corpora),
`shell-subset-corpus-stats.md` (the first corpus measurements, 2026-10-29/30). They use the old module names.
