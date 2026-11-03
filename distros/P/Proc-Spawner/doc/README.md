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
| `pspawn-run-shortcomings.md` | why the earlier executor (Run) was replaced |
| `pspawn-upstream-reports.md` | reports to the parser session (`Proc::ShellSubset::Large`) |
| `large-subset/` | the large parser `Proc::ShellSubset::Large`: its specification, the corpus measurements and their tools, the history (own index: `large-subset/README.md`) |
| `parsers/` | the base parser `Proc::ShellSubset` (and `::Small`): its grammar, the provenance of the corpus tests, the first corpus statistics (old module names) |
| `checklists/*.html` | the decision pages of the executor ("Child Exit Wake-up", "Run Graph API", "Spawn Graph Notation") and of the parser session ("Shell Large Subset", "Shell Dialect Choices", "Shell Corpus Gaps"; sources in `large-subset/pages/`): their items and Claude's answers. Self-contained HTML, but the marks and notes lived in the published page's database, so here they show empty. |
