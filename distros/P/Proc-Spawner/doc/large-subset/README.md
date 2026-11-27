# Proc::ShellSubset::Large: the large parser, its specification and its measurements

This directory holds the specification of the large parser, `Proc::ShellSubset::Large`, and what was measured on it. The documents and records here have names that start with `large-subset-` (but this README and the probes in `dialect-cases/`). They were begun with Claude on 2026-11-01 and 2026-11-02, by the session that wrote the parser.

The module was called `ShellSubsetLarge` until 2026-11-02, when the distribution moved every module under `Proc::`. The current documents below use the new names; the parts of them that record a past day (dated there) keep the names of that day.

Words used below:

- *Corpus*: the six public collections of shell snippets the measurements use ([`../test-pools.md`](../test-pools.md)); a *sample* is one snippet taken from them.
- *ShellSpawn*: `Proc::ShellSpawn`, the module that runs the parser's trees.
- *The behaviour run*: every sample the parser accepts, run once in dash, in `bash --posix` and in ShellSpawn, and the results compared ([section 7 of `large-subset-state.md`](large-subset-state.md#my-section-7)).
- *Steps 2 and 3*: the samples whose result may depend on the environment, run again in example environments made for each (the user's plan has four: step 1 finds the samples the environment cannot affect; step 4 leaves the rest to Claude reading them; [sections 10 and 12 of `large-subset-environment.md`](large-subset-environment.md#my-section-10)).
- *Legalized*: a difference from dash or bash that a ruling of the user (the distribution's author, who makes its decisions) allows.
- The other words and names (the yardsticks, the levels and classes, the codes, the decisions such as A23, K5, W5, EV1, the version labels such as post-0.12, Run) are explained in the documents named, mostly in "Words used below" of [`large-subset-environment.md`](large-subset-environment.md) and in [`large-subset-state.md`](large-subset-state.md), sections 1 and 7.

## <a id="my-the-documents"></a>The documents

| File | What it holds |
|---|---|
| [`large-subset-spec.md`](large-subset-spec.md) | **The specification** (current): what the large grammar accepts beyond `Proc::ShellSubset`; the rules where dash and bash differ (A3); what it adds to the parse tree; the rules for the executor at run time (A4: a form outside the subset found only at run time ends the snippet with status 248; A5: where the shells differ at run time, as dash); its tests and measurements. |
| [`large-subset-state.md`](large-subset-state.md) | **Where the large parser stands** (current): the rules, and which one wins where several apply; the yardsticks, decided by the shells alone; the parse results; the work list; the subtle differences and the open verdicts; the blatant differences. Its section 7 is **the behaviour run**: the run of 2026-11-17 (made with the code of post-0.12, not run again on 0.13; the earlier runs it replaced, moved on 2026-11-18 into [`../../Changes`](../../Changes), under post-0.13: the run of post-0.09, its rebuild with the programs inside Perl, and the run after W5, the new event loop); ShellSpawn at exit, in each mode of K5; ShellSpawn through Run, a run of its own; the *atomic calls* (each call of `echo`, `printf`, `test`, `[`, `kill`, `pwd` run alone). |
| [`large-subset-logical.md`](large-subset-logical.md) | **Rule E** (current): where dash and bash differ, the plainly logical behaviour, by category, item by item; the earlier decisions checked against it. |
| [`large-subset-environment.md`](large-subset-environment.md) | **The samples and the run's environment** (current; known issue [X27](../pspawn-known-issues.md#my-x27)). For every accepted sample: whether its comparison could come out otherwise in another environment (the levels: strict, almost strict, undecided, …), the codes that say why, and how to remake it. Section 9: the six kinds of workaround for what the run's environment would otherwise change, and the runs with the environment varied (`POSIXLY_CORRECT` set, another locale, SIGPIPE ignored, `/proc` hidden; fresh or private places; stand-ins for programs; fixed file times); these runs are footnotes to the totals of section 1 (decision EV1). |
| [`large-subset-match-raw.md`](large-subset-match-raw.md) | The match across environments (section 11 of `large-subset-environment.md`) with error messages compared as up to 0.11: a message on standard output or in a file counted as a difference (since 0.12 the match compares no messages, wherever they go). Not part of the analysis. |
| [`large-subset-dialect-features.md`](large-subset-dialect-features.md) | **dash against bash, feature by feature** (current): every probed feature, blatant or subtle, with who decided it; the per-test record. |
| [`large-subset-review.md`](large-subset-review.md) | **The review of the open differences** (current): the 130 snippets of README's "How close" that may be bugs of ShellSpawn, run again one by one in all their environments; the modes of failure, the verdict and the proposal for each; where the review stands and how to go on (the 42 of [TODO A13](../../TODO.md#my-a13) done on 2026-11-22; known issue X80 found so). |

The parser documents of the base grammar (written earlier, by another session) are in [`../parsers/`](../parsers):

- [`shell-subset-spec.md`](../parsers/shell-subset-spec.md): the grammar of `Proc::ShellSubset`; `Proc::ShellSubset::Small` is the same grammar with fewer options.
- [`shell-subset-test-provenance.md`](../parsers/shell-subset-test-provenance.md): where the corpus tests in [`t/parser/shell-subset-corpus-tests.pl`](../../t/parser/shell-subset-corpus-tests.pl) come from, and how to restore the corpora; the scripts are in [`../parsers/tools/`](../parsers/tools).
- [`shell-subset-corpus-stats.md`](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/parsers/shell-subset-corpus-stats.md) (in Proc-Spawner 0.03): the first corpus measurements, 2026-10-29 and 2026-10-30, before 0.01.

These use the old module names.

## <a id="my-the-records"></a>The records

| File | What it holds |
|---|---|
| [`large-subset-provenance.tsv`](large-subset-provenance.tsv) | The record of `large-subset-environment.md`: one line per accepted sample, by snippet ID, with a short code and the names it calls (`CALLS`); its header says how to read it. |
| [`tools/large-subset-env-variants.tsv`](tools/large-subset-env-variants.tsv) | Every sample whose result changed when the run's environment was varied ([section 9 of `large-subset-environment.md`](large-subset-environment.md#my-section-9)), by variant. |
| [`tools/large-subset-env-setups.tsv`](tools/large-subset-env-setups.tsv) | Step 2 ([section 10 of `large-subset-environment.md`](large-subset-environment.md#my-section-10)): the 2,902 samples it tried: those undecided by the levels as they stood before step 3 (which made 1,220 of them almost strict) whose every dependence is named exactly (files, variables, standard input, arguments, `cd`, `HOME`). For each: its class (how dash, bash and ShellSpawn compared) in two runs of the base environment (the second shows what varies by itself) and in every example setup, its dependences, and what each setup did (that column is not shipped: [`tools/large-subset-restore.pl`](tools/large-subset-restore.pl) restores it from the corpora, as the record's header says; likewise the snippets' texts of `step3.tsv`, `rejected.tsv`, `rejected-envs.tsv` and the setups of `env-control.tsv` and `env-affects-shell.tsv`). |
| [`tools/large-subset-step3.tsv`](tools/large-subset-step3.tsv) | Step 3 ([section 12 of `large-subset-environment.md`](large-subset-environment.md#my-section-12)): the 5,741 samples undecided by their codes alone, with where their values from the environment end up (classes pass 664, split 1,476, control 2,475, affects-shell 1,033, AI-… 93). |
| [`tools/large-subset-env-control.tsv`](tools/large-subset-env-control.tsv), [`tools/large-subset-env-affects-shell.tsv`](tools/large-subset-env-affects-shell.tsv) | The samples of step 3's classes control and affects-shell, run in example setups, each run in a root of its own. Their commands run alone: [`tools/large-subset-env-control-calls.jsonl`](tools/large-subset-env-control-calls.jsonl), [`tools/large-subset-env-affects-shell-calls.jsonl`](tools/large-subset-env-affects-shell-calls.jsonl). |
| [`tools/large-subset-ai-classes.tsv`](tools/large-subset-ai-classes.tsv) | The 93 undecided samples that step 3's setups left out, classified by Claude reading them (AI- categories; `large-subset-blocks.pl -ai`). |
| [`tools/large-subset-match.tsv`](tools/large-subset-match.tsv) | The match across environments ([section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11)). For every snippet where the shells or ShellSpawn differ in some environment: whether dash and bash agree; with which of them ShellSpawn sides; the rulings that legalize it; the class in each environment; and whether builtin-vs-coreutils holds (ShellSpawn differs only by running `echo`, `printf`, `test`, `[`, `kill` or `pwd` as coreutils does). Messages are not compared, wherever they go. |
| [`tools/large-subset-match-calls.jsonl`](tools/large-subset-match-calls.jsonl) | The commands of those snippets: every `echo`, `printf`, `test`, `[`, `kill`, `pwd` that ShellSpawn ran in them, run alone by coreutils, by dash's builtin, by bash's builtin and by ShellSpawn (status, output, messages). |
| [`tools/large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) | Why ShellSpawn differs from a shell, where the match report cannot tell by itself: a decision or rule by name, or chance ([section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11); `large-subset-runreport.pl -known`). |
| [`tools/large-subset-env-races.tsv`](tools/large-subset-env-races.tsv) | The races, run many times in the same environment (`make corpus-races`, `large-subset-repeat.pl`): whether a difference of ShellSpawn is a race or its own result. |
| [`tools/large-subset-endmodes.tsv`](tools/large-subset-endmodes.tsv) | ShellSpawn at exit (K5): the samples with a background job, each run 5 times in each mode of `PROC_SHELLSPAWN_END`, side by side ([section 7 of `large-subset-state.md`](large-subset-state.md#my-section-7)). |
| [`tools/large-subset-run-differences.tsv`](tools/large-subset-run-differences.tsv) | The samples of the behaviour run where ShellSpawn differs from both shells, or the shells differ and ShellSpawn agrees with neither, or its messages are worded as neither shell's. |
| [`tools/large-subset-programs.txt`](tools/large-subset-programs.txt) | The program names the runs see (A23 (b)): the runner makes a recorder (a stand-in program that logs its call) for each name here, installed or not, and for no other name; since post-0.13, with `-calls` (step 3 and the stand-in variants), also for each other program a sample calls that is no builtin, for that sample's runs alone ([X84](../pspawn-known-issues.md#my-x84)). |

## <a id="my-the-measurement-scripts"></a>The measurement scripts

The scripts are in [`tools/`](tools). `make test` does not run them; `make corpus-help` lists a target for each step ([section 0 of `../test-pools.md`](../test-pools.md#my-section-0)), and [`../test-pools.md`](../test-pools.md) says how to run them.

| Script | What it does |
|---|---|
| [`large-subset-corpora.pl`](tools/large-subset-corpora.pl) | fetches the sources of the corpora at their pinned commits |
| [`large-subset-extract.pl`](tools/large-subset-extract.pl) | turns the corpora into `samples.jsonl` |
| [`large-subset-ids.pl`](tools/large-subset-ids.pl) | lists the snippet IDs whose code names any of the codes given |
| [`large-subset-scan.pl`](tools/large-subset-scan.pl) | runs both shells, ShellCheck and both parsers (`Proc::ShellSubset` and the large one) on every sample; `--rx STRING` tries the regex detector, one of its three detectors of bash-only constructs |
| [`large-subset-drops.pl`](tools/large-subset-drops.pl) | lists the samples left out, with reasons |
| [`large-subset-remeasure.pl`](tools/large-subset-remeasure.pl) | the corpus acceptance and the POSIX ceiling (the samples without a bash-only construct, by ShellCheck) of [section 8 of the specification](large-subset-spec.md#my-section-8), per source |
| [`large-subset-yardsticks.pl`](tools/large-subset-yardsticks.pl) | the yardsticks, decided by the shells |
| [`large-subset-features.pl`](tools/large-subset-features.pl) | the detector of differences between dash and bash, and the per-test record |
| [`large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) | the verdicts kept by hand, also the free-form ones: decisions postponed, counted as open until rewritten in short form |
| [`large-subset-noise.txt`](tools/large-subset-noise.txt) | the samples left out by hand as noise: placeholders, `a\|b\|c` alternatives, cut-off here-documents (these since 0.05) |
| [`large-subset-reparse.pl`](tools/large-subset-reparse.pl) | refreshes the parser fields of the scan (what each parser said of each sample) after a change of the parser |
| [`large-subset-runcompare.pl`](tools/large-subset-runcompare.pl) | the run-time comparison: `-env` varies the environment, `-run` goes through Run, `-shells` and `-workers-from` run ShellSpawn alone after a change of ShellSpawn |
| [`large-subset-runreport.pl`](tools/large-subset-runreport.pl) | reports a run: `-b` against a base run; `-shellspawn-from` joins ShellSpawn's results of such a run with the dash and bash results of an earlier run; `-shellspawn-vs` compares ShellSpawn's results of two runs |
| [`large-subset-threeway.pl`](tools/large-subset-threeway.pl), [`large-subset-builtins.pl`](tools/large-subset-builtins.pl) | the atomic calls: each call of the six commands (`large-subset-threeway.pl`), and of the builtins where no program runs (`large-subset-builtins.pl`), run alone in dash, in bash and by the program or ShellSpawn |
| [`large-subset-blocks.pl`](tools/large-subset-blocks.pl) | the levels of [`large-subset-environment.md`](large-subset-environment.md); `-d`: each undecided sample's exact dependences; `-p`: step 3's classes; `-ai`: the classes Claude gave by reading |
| [`large-subset-setups.pl`](tools/large-subset-setups.pl) | example setups made from those dependences, for `large-subset-runcompare.pl -setup` ([section 10 of `large-subset-environment.md`](large-subset-environment.md)) |
| [`large-subset-matchreport.pl`](tools/large-subset-matchreport.pl) | the match across environments ([section 11 of `large-subset-environment.md`](large-subset-environment.md)) |
| [`large-subset-rerun.sh`](tools/large-subset-rerun.sh), [`large-subset-envs.pl`](tools/large-subset-envs.pl) | some samples run again in every environment of the match and matched, without a full `corpus-all`; each environment where ShellSpawn is not as both shells, with what the three did ([section 1 of `large-subset-review.md`](large-subset-review.md#my-section-1)) |
| [`large-subset-valueprobe.pl`](tools/large-subset-valueprobe.pl) | probes step 3's assumptions `passthrough` and `splitglob` with odd values |
| [`large-subset-repeat.pl`](tools/large-subset-repeat.pl) | runs the same samples many times: is a difference a race, or ShellSpawn's own result? |
| [`large-subset-bgjobs.pl`](tools/large-subset-bgjobs.pl) | lists the samples with a background job, for ShellSpawn at exit (K5) |
| [`large-subset-calls.pl`](tools/large-subset-calls.pl) | fills the column `CALLS` of [`large-subset-provenance.tsv`](large-subset-provenance.tsv) from the behaviour run, shell by shell (A23 (c)) |
| [`large-subset-difffuzz.pl`](tools/large-subset-difffuzz.pl) | differential fuzzing: random snippets of the large subset run in dash, bash and ShellSpawn |

## <a id="my-the-probes"></a>The probes

[`dialect-cases/`](dialect-cases) holds the probes: short snippets run in dash 0.5.12 and in `bash --posix` 5.2.21 to see where the two differ.

- The examples of the checklist page "Shell Dialect Choices" (a page of questions the user answered; in Proc-Spawner 0.03): [`cases.txt`](dialect-cases/cases.txt), with their output in [`results.txt`](dialect-cases/results.txt).
- 102 more: [`large-subset-dialect-probes2.txt`](dialect-cases/large-subset-dialect-probes2.txt), with their output in [`large-subset-dialect-results2.txt`](dialect-cases/large-subset-dialect-results2.txt).
- [`run-cases.sh`](dialect-cases/run-cases.sh) runs them again.

## <a id="my-removed"></a>Removed

`pages/` held the sources of the checklist page "Shell Corpus Gaps" (`../checklists/corpus-gaps.html`, in Proc-Spawner 0.04); it was removed after 0.04, with the page. It held:

- the page's item texts (`gaps-items.txt`) and its lede (`gaps-items.txt.lede`);
- the builder `build2.pl`, with `parts.css` and `parts.js` (the Parts menu);
- `rebuild.pl`, which put new items into a page already built (used for the page's second and third rounds).

The sources of the pages "Shell Large Subset" and "Shell Dialect Choices", and the older builder `build.pl`, are in Proc-Spawner 0.03.
