# Proc::ShellSubset::Large: the large parser, its specification and its measurements

Written with Claude by the parser session (file prefix `large-subset-`), 2026-11-01 and 2026-11-02. The module was
called `ShellSubsetLarge` until the distribution moved every module under `Proc::` (2026-11-02). The current
documents below use the new names; the historical ones keep the names of their day.

| File | What |
|---|---|
| `large-subset-spec.md` | **The specification** (current): what the large grammar accepts beyond `Proc::ShellSubset`, the rules where dash and bash differ (A3), the tree additions, the rules for the executor at run time (A4: status 248, A5: as dash), tests and measurements. |
| `large-subset-state.md` | **The state of the union** (current): the rules and which beats which, the yardsticks decided by the shells alone, the figures, the work list, subtle and open verdicts, blatant differences. |
| `large-subset-logical.md` | **Rule E** (current): where dash and bash differ, the plainly logical behaviour, by category, item by item; the earlier decisions checked against it. |
| `large-subset-dialect-features.md` | **dash vs bash, feature by feature** (current): every probed feature, blatant or subtle, with who decided it; the per-test record. |
| `tools/` | The measurement scripts (not run by `make test`): `large-subset-extract.pl` (corpora to `samples.jsonl`), `large-subset-scan.pl` (both shells, ShellCheck, both parsers; `--rx STRING` tries the regex detector), `large-subset-drops.pl` (left-out samples with reasons), `large-subset-remeasure.pl`, `large-subset-yardsticks.pl` (the yardsticks, decided by the shells), `large-subset-features.pl` (the detector of dash/bash differences, and the per-test record), `large-subset-verdicts.txt` (verdicts kept by hand, also postponed free-form ones), `large-subset-noise.txt` (samples left out by hand as noise: placeholders, `a|b|c` alternatives, cut-off here-documents; post2-0.04), `large-subset-reparse.pl` (refresh the parser fields after a parser change). How to run them: `../test-pools.md`. |
| `dialect-cases/` | The probes: the examples of the page "Shell Dialect Choices" (in Proc-Spawner 0.03) (`cases.txt`, `results.txt`) and 86 more (`large-subset-dialect-probes2.txt`, `-results2.txt`), with their output in dash 0.5.12 and `bash --posix` 5.2.21 (`run-cases.sh` reruns them). |
| (removed) | `pages/`, the sources of the checklist page "Shell Corpus Gaps" (in Proc-Spawner 0.04; removed after it with the page). Was: (`../checklists/corpus-gaps.html`): its item texts (`gaps-items.txt`) and lede (`gaps-items.txt.lede`), the builder `build2.pl` (with `parts.css` and `parts.js`, the Parts menu), and `rebuild.pl`, which puts new items into an already built page (used for its second and third rounds). The sources of the pages "Shell Large Subset" and "Shell Dialect Choices", and the older builder `build.pl`, are in Proc-Spawner 0.03. |

The base parser's documents (from an earlier session) are in `../parsers/`: `shell-subset-spec.md` (the grammar of
`Proc::ShellSubset`; `Proc::ShellSubset::Small` is the same grammar with fewer options), `shell-subset-test-provenance.md`
(where the corpus tests in `t/parser/shell-subset-corpus-tests.pl` come from, and how to restore the corpora; the scripts are in `../parsers/tools/`),
`shell-subset-corpus-stats.md` (the first corpus measurements, 2026-10-29/30, pre-0.01; in Proc-Spawner 0.03). They use the old module names.
