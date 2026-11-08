# Proc-Spawner: design notes (EXPERIMENTAL, included for now)

Working documents of the posix_spawn executor (prefix `pspawn-`) and of the large parser (in [`large-subset/`](large-subset)), written while they were designed with Claude.
The newest describe the current state; older ones may use the former module names (table at the top of
[`pspawn-spawner.md`](pspawn-spawner.md): `ShellSpawn` is now `Proc::ShellSpawn`, the binding `PosixSpawn` is part of `Proc::Spawner`, …).

| File | What |
|---|---|
| [`pspawn-spawner.md`](pspawn-spawner.md) | the current architecture: `Proc::Spawner`, `Proc::Spawner::Graph`, `Proc::ShellSpawn`; the rename; what is not done |
| [`pspawn-known-issues.md`](pspawn-known-issues.md) | open and fixed issues (X…, L…, E…) |
| [`pspawn-design.md`](pspawn-design.md) | the executor's internals: posix_spawn, file actions, the event loop, which posix_spawn features are used |
| [`pspawn-graph.md`](pspawn-graph.md) | the spawn-graph notation, its pictures, hand-written graphs ([`t/sgraph/`](../t/sgraph)) |
| [`pspawn-extensions.md`](pspawn-extensions.md) | the extension points (handlers named by sub names, `%KIND`, `%CMD`) and decisions D1–D3, E1–E5 |
| [`perl-signals-findings.md`](perl-signals-findings.md) | Perl's signal model and its defects, met while writing the event loop; candidate Perl bug reports |
| [`large-subset/`](large-subset) | the large parser `Proc::ShellSubset::Large`: its specification, the corpus measurements and their tools, the history (own index: [`large-subset/README.md`](large-subset/README.md)) |
| [`parsers/`](parsers) | the base parser `Proc::ShellSubset` (and `::Small`): its grammar, the provenance of the corpus tests and the scripts that made them ([`parsers/tools/`](parsers/tools)), the first corpus statistics (old module names) |
| `../TODO` | **what is open, in one place**: the decisions waiting for the author (what to read, how to act), the work, what to watch |
| [`test-pools.md`](test-pools.md) | how to rebuild every borrowed test pool and measurement from the pinned sources |
| (removed) | the documents of only historical interest (`pspawn-run-shortcomings.md`, `pspawn-upstream-reports.md`, [`parsers/shell-subset-corpus-stats.md`](https://github.com/ilyaz-ai/Proc-Spawner/blob/project-2026-11-03/claude/shell-subset-corpus-stats.md), and in [`large-subset/`](large-subset) the ceiling, investigation, marks and upstream reports) are in Proc-Spawner 0.03 on CPAN |

| (removed) | the decision pages that are no longer relevant: "Child Exit Wake-up", "Run Graph API" and "Spawn Graph Notation" (the executor; their outcomes are in [`pspawn-spawner.md`](pspawn-spawner.md), [`pspawn-design.md`](pspawn-design.md), [`pspawn-graph.md`](pspawn-graph.md) and [`pspawn-extensions.md`](pspawn-extensions.md)), "Shell Large Subset" (its outcome is [`large-subset/large-subset-spec.md`](large-subset/large-subset-spec.md)) and "Shell Dialect Choices" (it had no marks; every item is decided in [`large-subset/large-subset-logical.md`](large-subset/large-subset-logical.md)). They and their sources are in Proc-Spawner 0.03 on CPAN, under `doc/checklists/` and `doc/large-subset/pages/`. The last one, "Shell Corpus Gaps", left after 0.04, when its last open question (Q2) was decided; it and its sources are in 0.04 (its decisions: [`large-subset/large-subset-state.md`](large-subset/large-subset-state.md) and [`large-subset-logical.md`](large-subset/large-subset-logical.md)). |

## Version labels of the figures

Every measured figure in these documents (corpus acceptance, the yardsticks, battery and test counts) names the code it was measured on:

| Label | The code |
|---|---|
| pre-0.01 | before the first distribution: the modules under their former names (`ShellSubset`, `ShellSubsetLarge`, `ShellSpawn`), 2026-10-27 to the morning of 2026-11-02 |
| 0.01 | the first distribution (2026-11-02) |
| 0.02 | 0.01 plus documentation and tests; its parsers are those of 0.01 (`Changes`) |
| early-post-0.02 | 0.02 plus items P1–P4 of the page "Shell Corpus Gaps", the evening of 2026-11-02; this code was not kept, so its figures cannot be measured again |
| 0.03 | the release of 2026-11-03 (morning) |
| post-0.03 | 0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (`Changes`); unreleased; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| post2-0.03 | post-0.03 plus `pwd` as `/bin/pwd -L` (known issue X23); the parsers are those of post-0.03 |
| post3-0.03 | post2-0.03 plus `jobs` rejected in a pipeline, `$( )` or a compound command, and two more detector features |
| post4-0.03 | post3-0.03 plus rule E ([`large-subset/large-subset-logical.md`](large-subset/large-subset-logical.md); `jobs` there lists the jobs again, as bash), more forms both shells run alike, X19 fixed; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| 0.04 | the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and decision pages of only historical interest removed; the figures of post4-0.03 checked again on it (the same per-sample results) |
| post-0.04 | 0.04 plus 3A (functions before regular builtins), background jobs going on between run() calls (K3, choice B), the rule-E choices G4, G8, G15, G16 and `break`/`continue` in a subshell, `jobs %N`, X25 fixed; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| post2-0.04 | post-0.04 plus `read` with names from expansions, `${##}` and the like, 14 corpus samples marked as noise by hand, the detector rows N1–N3 as class X; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| post3-0.04 | post2-0.04 plus aliases known only when they run (P1: the rest of the text is parsed when it runs) and rule F (`[ s1 < s2 ]` compared by us); measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| post4-0.04 | post3-0.04 plus bracket expressions with quotes, expansions or `/`, `* ? [` in a `${x:-word}`, `unset NAME[…]` rejected (X26); measured 2026-11-05 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| 0.05 | the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of post4-0.04 hold for it (the measured files differ only in `$VERSION`) |
| 0.06 | the release of 2026-11-05 (later): 0.05 plus the fixes for systems without `/proc` (RT #182479, known issue X28) and the measurement of the atomic calls extended; the figures of post4-0.04 hold for it |
| 0.07 | the release of 2026-11-05 (evening): 0.06 plus what the spawn primitive lacks done around the call, [`win_spawn.h`](../win_spawn.h) (not yet built), Z0, the measurement of the atomic calls; the figures of post4-0.04 hold for it |
| 0.08 | the release of 2026-11-06: 0.07 plus the Windows work ([`win_spawn.h`](../win_spawn.h) compared with Perl's spawn, built against Strawberry Perl and run under Wine, batch files, `%Proc::Spawner::WINDOWS`), spawn's scalar result fixed; the figures of post4-0.04 hold for it |
| 0.09 | the release of 2026-11-08: 0.08 plus the settings posix_spawn lacks (M1: `rlimit`, `sigignore`, `nice`), no posix_spawn at all (M2: fork and exec; without fork, Run 0.07 around Perl's own spawn), the Windows handles released, `ulimit` through getrlimit, X27 classified, X29 and X31 fixed, X32 recorded; the figures of post4-0.04 hold for it |

Measured again on 2026-11-03: the corpus figures of 0.01 ([`large-subset/large-subset-ceiling.md`](https://github.com/ilyaz-ai/Proc-Spawner/blob/project-2026-11-03/claude/large-subset-ceiling.md) (in Proc-Spawner 0.03), section 3) and every figure of 0.03 (in [`doc/large-subset/large-subset-state.md`](large-subset/large-subset-state.md) of the Proc-Spawner-0.03 distribution). Every figure was measured on one of the states in this table; pre-0.01 covers many states, so its figures also carry their dates.
