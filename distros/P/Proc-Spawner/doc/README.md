# Proc-Spawner: design notes (EXPERIMENTAL, included for now)

Working documents of the posix_spawn executor (prefix `pspawn-`) and of the large parser (in `large-subset/`), written while they were designed with Claude.
The newest describe the current state; older ones may use the former module names (table at the top of
`pspawn-spawner.md`: `ShellSpawn` is now `Proc::ShellSpawn`, the binding `PosixSpawn` is part of `Proc::Spawner`, …).

| File | What |
|---|---|
| `pspawn-spawner.md` | the current architecture: `Proc::Spawner`, `Proc::Spawner::Graph`, `Proc::ShellSpawn`; the rename; what is not done |
| `pspawn-known-issues.md` | open and fixed issues (X…, L…, E…) |
| `pspawn-design.md` | the executor's internals: posix_spawn, file actions, the event loop, which posix_spawn features are used |
| `pspawn-graph.md` | the spawn-graph notation, its pictures, hand-written graphs (`t/sgraph/`) |
| `pspawn-extensions.md` | the extension points (handlers named by sub names, `%KIND`, `%CMD`) and decisions D1–D3, E1–E5 |
| `perl-signals-findings.md` | Perl's signal model and its defects, met while writing the event loop; candidate Perl bug reports |
| `large-subset/` | the large parser `Proc::ShellSubset::Large`: its specification, the corpus measurements and their tools, the history (own index: `large-subset/README.md`) |
| `parsers/` | the base parser `Proc::ShellSubset` (and `::Small`): its grammar, the provenance of the corpus tests and the scripts that made them (`parsers/tools/`), the first corpus statistics (old module names) |
| `test-pools.md` | how to rebuild every borrowed test pool and measurement from the pinned sources |
| (removed) | the documents of only historical interest (`pspawn-run-shortcomings.md`, `pspawn-upstream-reports.md`, `parsers/shell-subset-corpus-stats.md`, and in `large-subset/` the ceiling, investigation, marks and upstream reports) are in Proc-Spawner 0.03 on CPAN |
| `checklists/*.html` | the decision pages of the executor ("Child Exit Wake-up", "Run Graph API", "Spawn Graph Notation") and of the parser session ("Shell Large Subset", "Shell Dialect Choices", "Shell Corpus Gaps"; sources in `large-subset/pages/`): their items and Claude's answers. Self-contained HTML, but the marks and notes lived in the published page's database, so here they show empty. |

## Version labels of the figures

Every measured figure in these documents (corpus acceptance, the yardsticks, battery and test counts) names the code it was measured on:

| Label | The code |
|---|---|
| pre-0.01 | before the first distribution: the modules under their former names (`ShellSubset`, `ShellSubsetLarge`, `ShellSpawn`), 2026-10-27 to the morning of 2026-11-02 |
| 0.01 | the first distribution (2026-11-02) |
| 0.02 | 0.01 plus documentation and tests; its parsers are those of 0.01 (`Changes`) |
| early-post-0.02 | 0.02 plus items P1–P4 of the page "Shell Corpus Gaps", the evening of 2026-11-02; this code was not kept, so its figures cannot be measured again |
| 0.03 | the release of 2026-11-03 (morning) |
| post-0.03 | 0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (`Changes`); unreleased; measured 2026-11-03 (`large-subset/large-subset-state.md`, section 3) |
| post2-0.03 | post-0.03 plus `pwd` as `/bin/pwd -L` (known issue X23); the parsers are those of post-0.03 |
| post3-0.03 | post2-0.03 plus `jobs` rejected in a pipeline, `$( )` or a compound command, and two more detector features |
| post4-0.03 | post3-0.03 plus rule E (`large-subset/large-subset-logical.md`; `jobs` there lists the jobs again, as bash), more forms both shells run alike, X19 fixed; measured 2026-11-03 (`large-subset/large-subset-state.md`, section 3) |
| 0.04 | the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents of only historical interest removed; the figures of post4-0.03 checked again on it (the same per-sample results) |

Measured again on 2026-11-03: the corpus figures of 0.01 (`large-subset/large-subset-ceiling.md` (in Proc-Spawner 0.03), section 3) and every figure of 0.03 (in `doc/large-subset/large-subset-state.md` of the Proc-Spawner-0.03 distribution). Every figure was measured on one of the states in this table; pre-0.01 covers many states, so its figures also carry their dates.
