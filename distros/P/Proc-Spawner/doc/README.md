# Proc-Spawner: design notes (working documents, included for now; they may change or go)

These are the working documents written, with Claude, while the modules were designed:

- those of the *executor*, the modules that start programs and run parse trees (`Proc::Spawner`, `Proc::Spawner::Graph`, `Proc::ShellSpawn`): the files whose names start with `pspawn-`;
- those of the large parser `Proc::ShellSubset::Large`, in [`large-subset/`](large-subset);
- those of the base parser `Proc::ShellSubset` (and `::Small`, a smaller variant of it), in [`parsers/`](parsers);
- and, besides these, drafts of reports of Perl's own bugs, the open work, how the measurements are remade, and the test results (the table below).

The documents of the table describe the current code, except some parts of the older ones, dated in their status lines (such as `pspawn-design.md`, 2026-11-01), which describe the state of their day and may use the modules' former names: for example, `ShellSpawn` is now `Proc::ShellSpawn`, and the binding `PosixSpawn` is now part of `Proc::Spawner`. The rename table near the top of [`pspawn-spawner.md`](pspawn-spawner.md) lists them all.

Names such as W5, K3, A23 or rule E are the decisions of the user (the distribution's author), each explained where it applies; an A… name is an item of [`TODO`](../TODO.md), kept as the decision's name once decided. The *executor* is the part that starts programs and runs parse trees (above), the *shell layer* is `Proc::ShellSpawn`. Other terms of the table at the end:

- *both shells*: dash and `bash --posix`, the shells the subset is measured against;
- *the detector*: the script that finds the differences of dash and bash in a snippet, [`large-subset/tools/large-subset-features.pl`](large-subset/tools/large-subset-features.pl); its *class X*: a difference that a program the subset runs, or a decision of the user, settles (not the known issues X…);
- *battery snippets*: the test snippets in the files of [`t/batteries/`](../t/batteries);
- *decision pages*: pages on which the user answered questions item by item (P1, Q2, … are their items); their *marks* are the answers;
- *Run*: the user's module `Run` (in repository `ilyaz-ai/run`, on CPAN), through which `Proc::Spawner` starts programs where it has neither posix_spawn nor fork;
- *the atomic calls*: each distinct call of one command with its arguments that the corpus snippets made, run alone by dash, by bash and as the program ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-7), section 7);
- *the digest*: the sha256 of the files the parse results depend on ([section 3 of `large-subset-state.md`](large-subset/large-subset-state.md#my-section-3)); while it is unchanged, the parse results hold.

## <a id="my-the-documents"></a>The documents

| File | What it holds |
|---|---|
| [`pspawn-spawner.md`](pspawn-spawner.md) | the current architecture: how `Proc::Spawner`, `Proc::Spawner::Graph` and `Proc::ShellSpawn` divide the work; the rename of the modules; what is not done yet |
| [`pspawn-loop.md`](pspawn-loop.md) | the event loop `Proc::Spawner::Loop` (decision W5), one interface on POSIX and on Windows: how it works (the I/O completion port, Ctrl-C, `alarm`) and what was checked |
| [`pspawn-shell-windows.md`](pspawn-shell-windows.md) | `Proc::ShellSpawn` on Windows: what the shell layer does differently there (paths, `PATH`/`PATHEXT`, `NUL`, ...), what was checked ([`t/portable.t`](../t/portable.t)), what is missing |
| [`pspawn-known-issues.md`](pspawn-known-issues.md) | every known issue, open or fixed, with its ID (X…, L…, E…) |
| [`pspawn-design.md`](pspawn-design.md) | the executor's internals: posix_spawn, file actions, the event loop, which posix_spawn features are used |
| [`pspawn-graph.md`](pspawn-graph.md) | the notation for spawn graphs (the children, pipes and files in use, and what the end of each child sets off), its pictures, and the hand-written graphs of the tests ([`t/sgraph/`](../t/sgraph)) |
| [`pspawn-extensions.md`](pspawn-extensions.md) | the extension points (handlers named by sub names, `%Proc::ShellSpawn::KIND`, `%Proc::ShellSpawn::CMD`) and their decisions D1–D3, E1–E5 (not the known issues E…, nor rule E) |
| [`perl-signals-findings.md`](perl-signals-findings.md) | Perl's signal model and its defects, found while writing the event loop; candidates for bug reports to Perl |
| [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md) | drafts of bug reports to Perl about its spawn on Windows (argv quoting, the retry through cmd.exe, batch files, inherited handles, every failure to start reported as ENOENT), not yet filed; [its section 5](perl-win32-system-bugs.md#my-section-5) lists every workaround in this distribution and what to do when Perl is fixed |
| [`large-subset/`](large-subset) | the large parser `Proc::ShellSubset::Large`: its specification, the corpus measurements and their tools, the history (its own index: [`large-subset/README.md`](large-subset/README.md)) |
| [`large-subset/large-subset-review.md`](large-subset/large-subset-review.md) | **the review of the open differences**: the corpus snippets where ShellSpawn may have a bug, run again and judged one by one; what each is, the proposals, and where the review stands and how to go on |
| [`parsers/`](parsers) | the base parser `Proc::ShellSubset` (and `::Small`): its grammar, where its corpus tests come from, and the scripts that made them ([`parsers/tools/`](parsers/tools)) |
| [`../TODO.md`](../TODO.md) | **everything that is open, in one place**: first the decisions waiting for the author (what to read, how to act), then the work, then what to watch, then the author's reminders |
| [`test-pools.md`](test-pools.md) | how to rebuild, from the pinned sources, every test pool taken from public collections and every measurement made on them |
| [`corpus.mk`](corpus.mk) | the make targets that [section 0 of `test-pools.md`](test-pools.md#my-section-0) describes (`make corpus-help` lists them) |
| [`docs-sync.pl`](docs-sync.pl), [`docs-sync.tsv`](docs-sync.tsv) | the check that every part of the documents listed in `docs-sync.tsv` is in line with the records, reports and scripts it draws on (`make docs-check`) |
| [`test-results/`](test-results) | the test results on Linux and under Wine: what did not pass in [`t/flavors.pl`](../t/flavors.pl) (the spawn primitive's approaches, defined in [the top `README.md`](../README.md#my-the-approaches)) and in [`t/missing-matrix.pl`](../t/missing-matrix.pl), and the outcome of each test file at each level; the counts of the large subset under Wine ([`pspawn-shell-windows.md`](pspawn-shell-windows.md#my-the-large-subset-under-wine)) |
| [`metacpan-tables.md`](metacpan-tables.md) | a test page: one table in five forms, to see which MetaCPAN shows well ([`TODO`, item A15](../TODO.md#my-a15)) |

### <a id="my-documents-no-longer-shipped"></a>Documents no longer shipped

- **Documents of only historical interest** are in Proc-Spawner 0.03 on CPAN: [`pspawn-run-shortcomings.md`](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/pspawn-run-shortcomings.md), [`pspawn-upstream-reports.md`](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/pspawn-upstream-reports.md), [`shell-subset-corpus-stats.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/parsers/shell-subset-corpus-stats.md), and, in `doc/large-subset/` of 0.03, the large parser's ceiling ([`large-subset-ceiling.md`](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md)), its investigation, its marks (the decision pages' answers) and its upstream reports.
- **Decision pages that are no longer relevant**, with their sources, are in Proc-Spawner 0.03 on CPAN, under `doc/checklists/` and `doc/large-subset/pages/`:
  - of the executor: "Child Exit Wake-up", "Run Graph API" and "Spawn Graph Notation"; their outcomes are in [`pspawn-spawner.md`](pspawn-spawner.md), [`pspawn-design.md`](pspawn-design.md), [`pspawn-graph.md`](pspawn-graph.md) and [`pspawn-extensions.md`](pspawn-extensions.md);
  - "Shell Large Subset"; its outcome is [`large-subset/large-subset-spec.md`](large-subset/large-subset-spec.md);
  - "Shell Dialect Choices"; it had no marks, and every item is decided in [`large-subset/large-subset-logical.md`](large-subset/large-subset-logical.md).
- **The last decision page, "Shell Corpus Gaps"**, was removed after 0.04, once its last open question (Q2) was decided. It and its sources are in Proc-Spawner 0.04; its decisions are recorded in [`large-subset/large-subset-state.md`](large-subset/large-subset-state.md) and [`large-subset-logical.md`](large-subset/large-subset-logical.md).

## <a id="my-version-labels-of-the-results"></a>Version labels of the results

Every measured result in these documents (the corpus parse results, the yardsticks defined in [section 1 of `large-subset-state.md`](large-subset/large-subset-state.md#my-section-1), the counts of battery snippets and of tests) names the code it was measured on, by one of the labels below. The labels post-N, post2-N, … (the last row) and early-post-0.02 name unreleased code.

| Label | The code |
|---|---|
| pre-0.01 | before the first distribution: the modules under their former names (`ShellSubset`, `ShellSubsetLarge`, `ShellSpawn`), 2026-10-27 to the morning of 2026-11-02 |
| 0.01 | the first distribution (2026-11-02) |
| 0.02 | the release of 2026-11-02: 0.01 plus documentation and tests; its parsers are those of 0.01 (`Changes`) |
| early-post-0.02 | 0.02 plus items P1–P4 of the page "Shell Corpus Gaps", the evening of 2026-11-02; this code was not kept, so its results cannot be measured again |
| 0.03 | the release of 2026-11-03 (morning) |
| post-0.03 | 0.03 plus item P6 of "Shell Corpus Gaps" and three fixes of the detector (`Changes`); unreleased; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| post2-0.03 | post-0.03 plus `pwd` run as `/bin/pwd -L` (known issue [X23](pspawn-known-issues.md#my-x23)); the parsers are those of post-0.03 |
| post3-0.03 | post2-0.03 plus `jobs` rejected in a pipeline, in `$( )` or in a compound command, and two more features of the detector |
| post4-0.03 | post3-0.03 plus rule E ([`large-subset/large-subset-logical.md`](large-subset/large-subset-logical.md); under it, `jobs` there lists the jobs again, as bash does), more forms that both shells run alike, X19 fixed; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| 0.04 | the release of 2026-11-03: post4-0.03 with the version number 0.04, and with the documents and decision pages of only historical interest removed; the parse results of post4-0.03 were measured again on it (the same result for every sample) |
| post-0.04 | 0.04 plus 3A (functions before regular builtins), background jobs that go on between run() calls (K3, choice B), the rule-E choices G4, G8, G15, G16 and `break`/`continue` in a subshell, `jobs %N`, X25 fixed; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| post2-0.04 | post-0.04 plus `read` with names from expansions, `${##}` and the like, 14 corpus samples marked as noise by hand, the detector's rows N1–N3 as class X; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| post3-0.04 | post2-0.04 plus aliases known only when they run (the user's P1 of 2026-11-03, not the item P1 of early-post-0.02: the rest of the text is parsed when it runs) and rule F (`[ s1 < s2 ]` compared by ShellSpawn itself, not by the program); measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| post4-0.04 | post3-0.04 plus bracket expressions with quotes, expansions or `/`, `* ? [` in a `${x:-word}`, `unset NAME[…]` rejected (X26); measured 2026-11-05 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) |
| 0.05 | the release of 2026-11-05: post4-0.04 with the version number 0.05; the parse results of post4-0.04 hold for it (the measured files differ only in `$VERSION`) |
| 0.06 | the release of 2026-11-05 (later): 0.05 plus the fixes for systems without `/proc` (RT #182479, known issue [X28](pspawn-known-issues.md#my-x28)) and the measurement of the atomic calls extended; the parse results of post4-0.04 hold for it |
| 0.07 | the release of 2026-11-05 (evening): 0.06 plus the posix_spawn settings a C library lacks (`chdir`, the fd actions), made around the call, [`win_spawn.h`](../win_spawn.h) (not yet built), Z0, the atomic calls measured with that code; the parse results of post4-0.04 hold for it |
| 0.08 | the release of 2026-11-06: 0.07 plus the Windows work ([`win_spawn.h`](../win_spawn.h) compared with Perl's spawn, built against Strawberry Perl and run under Wine, batch files, `%Proc::Spawner::WINDOWS`), spawn's scalar result fixed; the parse results of post4-0.04 hold for it |
| 0.09 | the release of 2026-11-08: 0.08 plus the settings posix_spawn has no option for (M1: `rlimit`, `sigignore`, `nice`), no posix_spawn at all (M2: fork and exec; without fork, Run 0.07 around Perl's own spawn), the Windows handles released, `ulimit` through getrlimit, X27 classified, X29 and X31 fixed, X32 recorded; the parse results of post4-0.04 hold for it |
| 0.10 | the release of 2026-11-08 (later): 0.09 plus `Spawner.so` loading with perl before 5.34 (X36, RT #182809, reported by Slaven Rezic), `echo`, `printf`, `test`, `[`, `true`, `false` run inside Perl, as coreutils 9.4 runs them (X21, partly), the Windows priority class and job limits (W4) and X34 fixed, X27's environment variants, the run-time comparison redone (A1(b)), X33 and X35 fixed; the parse results of post4-0.04 hold for it |
| 0.11 | the release of 2026-11-10: 0.10 plus the shell layer on Windows (WS1, [`t/portable.t`](../t/portable.t)), the event loop in a module of its own with a Windows backend on an I/O completion port (W5), `sh` run as Perl (SH1), `cat`, `sort`, `grep` from `PROC_SHELLSPAWN_BIN` or Git for Windows (BIN1, temporary), `pwd` inside Perl too, a choice of whose `echo` the one inside Perl imitates (EC1), X37 and X38 fixed, drafts of reports of Perl's Windows bugs, with the workarounds in this distribution listed; checked under Wine, not on real Windows; the parse results of post4-0.04 hold for it |
| 0.12 | the release of 2026-11-13: 0.11 plus X27's steps 2 and 3 (example environments for the undecided samples, the match across environments with every difference's ruling, the 93 samples the environments leave out classified by Claude reading them: [`large-subset/large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-10), sections 10 to 12), the runner waiting for background jobs (A18), every run result redone (2026-11-13), X39 to X55 fixed, X56 found; the parse results of post4-0.04 hold for it (digest `06885fdd…`; the files it covers differ from those of post-0.11, measured again, only in `$VERSION`) |
| 0.13 | the release of 2026-11-18: post-0.12 with the version number 0.13. Since 0.12: the review of the executor's code; K5 (at exit, ShellSpawn waits for a background job only while it still has something to start for it, as the shells do); W6 and W7; X57, X58, X64, X65; the corpus runner offers only the programs of a fixed list (A23), compares what a snippet feeds a logged program (IN1, A24 (b)), X66; each test's outcome at each level of the spawn primitive recorded; the documents cleaned up, with anchors for linking sections, tables and known issues; the parse results of post4-0.04 hold for it (digest `9c6511c7…`; since 0.12 only `$VERSION` and a comment changed in the files it covers) |
| 0.14 | the release of 2026-11-27: post-0.13 with the version number 0.14, and the shipped records without what the tools make again (`large-subset-restore.pl`). Since 0.13: in ShellSpawn, `exec` followed by a builtin's name refused (X56, D1), `cd`'s operands taken apart after expansion (X80), a command run inside Perl that writes into a broken pipe ends its shell (D3); in Proc::Spawner, `closefrom` done as closes where it alone is missing, the fd actions emulated per call (X67); the corpus runs made again (2026-11-22) and kept in Proc-Spawner-results, with a table of which runs made each record; the snippets the parser rejects run in dash and bash; README's "How close" and "Threads" rewritten; the ways of starting a child called approaches; `TODO.md` with linked items; the parse results of 2026-11-22 hold for it (digest `e1923995…`; since post-0.13 only `$VERSION` changed in the files it covers) |
| post-N (unreleased) | N plus the entries under post-N in `Changes` (likewise post2-N, ...: the work after the release N, before the next one) |

Each result was measured on code named by one of these labels. The label pre-0.01 covers many states of the code, so its results also carry their dates.

Two sets of results were measured again on 2026-11-03, as a check:

- the corpus results of 0.01 ([`large-subset-ceiling.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md), section 3, in Proc-Spawner 0.03): 0.01's parsers on a new scan of the shells and ShellCheck; every count the same but one (tldr's last column, 123 against 126, not explained);
- every result of 0.03 ([`large-subset-state.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-state.md), in Proc-Spawner 0.03), first taken before the release, again on the released 0.03 later that morning: every count the same.
