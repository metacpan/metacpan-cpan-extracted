# Test pools: what they are and how to rebuild them

The distribution has two pools of shell snippets taken ("borrowed") from public collections, and one record that classifies every parser test:

| Pool | File | Made by | Size |
|---|---|---|---|
| A. corpus tests of the base parser | [`t/parser/shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl) | [`doc/parsers/tools/`](parsers/tools) | 612 tests |
| B. corpus measurement of the large parser | not shipped (made on demand) | [`doc/large-subset/tools/`](large-subset/tools) | 45,501 snippets extracted; 41,952 after leaving out duplicates, noise marked by hand and the like (the reasons: `drops.tsv`). The noise list, [`tools/large-subset-noise.txt`](large-subset/tools/large-subset-noise.txt), exists since post2-0.04; 0.03 to post-0.04 kept 41,966 (the 14 that list leaves out) |
| C. the shells' verdict on every parser test | [`t/parser/large-subset-shells.tsv`](../t/parser/large-subset-shells.tsv) | [`doc/large-subset/tools/large-subset-features.pl`](large-subset/tools/large-subset-features.pl) | 1,117 tests, one a line (post4-0.04, and the same on 2026-11-13, below; post3-0.04: 1,112; post2-0.04: 1,107; post-0.04: 1,104; 0.04: 1,092; 0.03: 1,066) |

The hand-written tests ([`t/parser/shell-subset-tests.pl`](../t/parser/shell-subset-tests.pl), IDs `OWN:n`; [`t/parser/large-subset-tests.pl`](../t/parser/large-subset-tests.pl), IDs `LS:n`) are not borrowed. A *sample* or *snippet* is one shell text taken from a source; a *test* is one entry of a test file.

Version labels such as post4-0.04 name the work after a release, before the next ([the labels](README.md#my-version-labels-of-the-results)). *ShellSpawn* is `Proc::ShellSpawn`, the distribution's shell; the measurement tools call it `shellspawn` in their records and options (`ours` before post-0.13: the stored runs keep that key, and the tools still read it; decided 2026-11-23 (D5)). *The user* is the distribution's author, who makes its decisions. X27 is a known issue ([`pspawn-known-issues.md`](pspawn-known-issues.md)); the decisions (K5, …) and the user's four steps of X27 ("step 3") are explained in [`large-subset-environment.md`](large-subset/large-subset-environment.md), "Words used below".

How to run the commands below:

- All the scripts named here are in the distribution. None needs network access once the sources (section 1) and ShellCheck (`pip install`, section 3) are on disk. Section 1 also needs `pdftotext` (poppler).
- CORPORA is the directory made in [section 1](#my-section-1), and DIST the unpacked distribution. Run the commands from DIST unless a step says otherwise.
- Scripts that load the parsers are run with `perl -Ilib` (or `-I DIST/lib`), as shown; the others need no modules from [`lib/`](../lib).

## <a id="my-section-0"></a>0. With make

`perl Makefile.PL` puts targets for all of this into the `Makefile` (from [`corpus.mk`](corpus.mk)); `make corpus-help` lists them. They are not part of building, installing or `make test`.

What the targets need:

- Linux.
- For the runs: root, since they make the users `rc0`…`rc3` (and `rc9` for [`large-subset-threeway.pl`](large-subset/tools/large-subset-threeway.pl)) and mount file systems, each run in a namespace of its own; no network (`unshare -n`); dash and bash; `make` first.

Work files go to `CORPUS` (default `corpus-work`, ignored by git). The targets marked *(record)* rewrite the shipped file they name, so `git diff` shows what changed. Each target first makes what it needs from the earlier ones; a target that reads a shipped record (as `corpus-calls` reads `large-subset-provenance.tsv`) takes it as it is. The long runs can be restarted: a run skips the samples its directory already has.

In the table, *ShellSpawn* is `Proc::ShellSpawn`, the distribution's shell, which the runs compare with dash and `bash --posix`.

| Target | What it does | Time |
|---|---|---|
| `corpora` | [section 1](#my-section-1): the sources at their pinned commits, and the book ([`large-subset-corpora.pl`](large-subset/tools/large-subset-corpora.pl)) | 1 minute |
| `corpus-pool-a-check`, `corpus-pool-a` | [section 2](#my-section-2): pool A checked against the sources; its texts made again, into `CORPUS/pool` | seconds |
| `corpus-samples`, `corpus-scan`, `corpus-parse` | [section 3](#my-section-3): pool B, the scan (with `OLDSCAN=FILE SCCACHE=FILE`, a stored scan, `large-scan.jsonl` and ShellCheck's `sc-cache.jsonl` of an earlier run, is reparsed instead), the parse results | 25 minutes (15 seconds with `OLDSCAN`) |
| `corpus-digest` | the SHA-256 of the files the parse results depend on ([`large-subset-state.md`](large-subset/large-subset-state.md#my-section-3), section 3) | |
| `corpus-shells` | [section 4](#my-section-4) *(record)* | seconds |
| `corpus-provenance` | the levels (how far each sample's comparison can change with the environment: [`large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-1), section 1), [`large-subset-provenance.tsv`](large-subset/large-subset-provenance.tsv), and step 3's classes, [`large-subset-step3.tsv`](large-subset/tools/large-subset-step3.tsv) *(records)* | 8 seconds |
| `corpus-run`, `corpus-qrun` | the behaviour run ([section 3](#my-section-3)); ShellSpawn alone, with the calls it makes logged | 55 minutes each (less in a faster container: below) |
| `corpus-calls` | what each sample calls (the column CALLS of `large-subset-provenance.tsv`, rewritten in place), marked shell by shell from the behaviour run *(record)* | 15 s |
| `corpus-runreport`, `corpus-threeway`, `corpus-builtins` | the tables of [`large-subset-state.md`](large-subset/large-subset-state.md#my-section-7), section 7, and their records | minutes each, but `corpus-builtins` 45 minutes |
| `corpus-env-variants` | [`large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-9), section 9: [`large-subset-env-variants.tsv`](large-subset/tools/large-subset-env-variants.tsv) *(record)* | hours |
| `corpus-endmodes` | ShellSpawn's wait at exit for its background jobs (K5): each mode of `PROC_SHELLSPAWN_END` (`shell`, `all`, `none`) on the samples with a background job, `ENDRUNS` times each (default 5): [`large-subset-endmodes.tsv`](large-subset/tools/large-subset-endmodes.tsv) *(record)*, the report in `CORPUS/endmodes/repeat.txt` | 10 minutes |
| `corpus-step2`, `corpus-step3`, `corpus-races`, `corpus-match` | sections 10, 12 (with its races, run many times) and 11 of `large-subset-environment.md`: their records; the match over every environment a snippet ran in (the base run, step 2's and step 3's), its report (`CORPUS/match.txt`) and the match with the messages compared too, as it was made before 2026-11-11 (`CORPUS/match-raw.txt`, for [`large-subset-match-raw.md`](large-subset/large-subset-match-raw.md)) | 35 minutes, about an hour, 20 minutes, 10 minutes |
| `corpus-html` | [`large-subset-state.md.html`](large-subset/large-subset-state.md.html) from the `.md` *(record)* | |
| `corpus-all`, `corpus-clean` | everything in order, step 3 and its races included; remove `CORPUS` | about 4½ hours |
| `probe-values` | not the corpus: the assumptions of X27's step 3 (passthrough, splitglob) probed with odd values in dash, `bash --posix` and ShellSpawn ([`large-subset-valueprobe.pl`](large-subset/tools/large-subset-valueprobe.pl); [`large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-12), section 12) | 1 minute |
| `probe-fuzz`, `probe-stress`, `probe-memory` | not the corpus: random snippets made of pieces of the large subset, in dash, `bash --posix` and ShellSpawn ([`large-subset-difffuzz.pl`](large-subset/tools/large-subset-difffuzz.pl); `FUZZ="-n 300 -seed 1"`); children ending while the modules' Perl code runs ([`t/stress.t`](../t/stress.t)); the resident size over 1,500 runs ([`t/memory.t`](../t/memory.t)). The two tests run in `make test` only with `RELEASE_TESTING=1` | 25 s per 300 snippets; 20 s; 10 s |

Variables: `CORPUS`, `CJ` (workers, 4), `CBASE` (the runs' base directory, `/runcompare`), `CENV` (the environment of the main runs, `-env tmp,random,mtime` and `-base` with `CBASE`).

### <a id="my-what-was-checked-through-make"></a>What was checked through make

- On 2026-11-11, with the code post-0.11:
  - the targets up to `corpus-provenance` (with `corpus-shells`), and `corpus-html`, ran and gave the shipped files (the samples' count, the parse results' digest, the provenance, the shells' verdicts);
  - `corpus-env-variants`, `corpus-step2` and `corpus-match` ran over the runs of 2026-11-08 to 11 that were already on disk (a run skips what it has), and gave the shipped records byte for byte, except section 11's match: there 34 samples differed, those that had been run again with their files compared without the messages, and the record of the calls had two more, made by samples that time out;
  - the full runs themselves were not repeated through `make` that day.
- On 2026-11-13, with the code post-0.11: `make corpus-all` ran as root from an empty `CORPUS` in a fresh container; then the variants ran again for the samples that [`large-subset-ids.pl`](large-subset/tools/large-subset-ids.pl) had missed (it did not read the codes inside `passthrough(…)`; fixed that day).
  - It took about 4½ hours with 4 workers; among the steps, the scan took 25 minutes, the two full runs together under an hour in that container, and step 2 to the match about an hour and a half.
  - The parse records (the samples' count, the parse results, the provenance, step 3's classes, the shells' verdicts) came out byte for byte the same.

### <a id="my-when-to-run-again"></a>When to run again

The run results depend on ShellSpawn's code (`lib/`), on the runner ([`large-subset-runcompare.pl`](large-subset/tools/large-subset-runcompare.pl)) and on the shells. After a change to `lib/` or to the runner, `make docs-check` names the parts of the documents that are out of line (their inputs include the files of `lib/`: [`docs-sync.tsv`](docs-sync.tsv)). Then run `make corpus-clean corpus-all` (about 4½ hours; without `corpus-clean` the runs would keep the results they already have):

- with all three shells, not ShellSpawn alone: a change of the runner (for example its waiting for background jobs, `-after`) changes dash's and bash's results too;
- with step 3: the two trees of section 11 of `large-subset-environment.md` count each snippet over the base run and over the setups of steps 2 and 3 (the user, 2026-11-13).

To measure a change before that, ShellSpawn may run alone ("After a change to ShellSpawn", below); the records are made by `corpus-all`.

### <a id="my-keeping-the-documents-in-line"></a>Keeping the documents in line with the results

[`docs-sync.tsv`](docs-sync.tsv) maps each part of a document that shows such results (section 11 of [`large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-11), section 7 of [`large-subset-state.md`](large-subset/large-subset-state.md#my-section-7), the counts in [`README.md`](../README.md), ...) to the records, reports and scripts it draws on, with their SHA-256 at the time the part was last brought in line. The map uses hashes, not file times, because Git keeps no file times.

- `make docs-check` ([`docs-sync.pl`](docs-sync.pl)) names every part whose inputs changed since, and what to redo by hand.
- `make docs-synced DOC=FILE [PART=...]` records the new hashes once that is done.
- `make docs-map` shows the map.

### <a id="my-which-runs-made-each-record"></a>Which runs made each record

The runs themselves are not in the distribution: each `corpus-all` is stored as a collection of the repository [ilyaz-ai/Proc-Spawner-results](https://github.com/ilyaz-ai/Proc-Spawner-results) (`proc-spawner/DATE-NAME/corpus-work.tar.xz`, with a README). [`large-subset-tables-used.tsv`](large-subset/tools/large-subset-tables-used.tsv) says, for each of the 18 records in `doc/large-subset/`, which collection it was made from (with the SHA-256 of its archive), the commit of the code the runs were made with, the commit of the tools that wrote the record, the record's own SHA-256, and which make target writes it again.

- After a new `corpus-all` is stored as a collection: `make corpus-stamp LABEL=DATE-NAME RUN=COMMIT` (RUN: the commit the runs were made with).
- After a change of a report tool, or of [`large-subset-match-known.tsv`](large-subset/tools/large-subset-match-known.tsv): `make corpus-rereport` (the reports again from the stored runs in `CORPUS`, no shell run; a collection unpacked into `CORPUS` works too), then `make corpus-stamp`.
- [`t/records.t`](../t/records.t) (in every `make test`; `make docs-check` runs it too) fails for a record whose content is not the one stamped, and names the make target to run. It checks the commits only in a git clone, and the collections only with a clone of Proc-Spawner-results beside this one (or `PROC_SPAWNER_RESULTS=DIR`); without them it skips those checks.
- With `RELEASE_TESTING=1`, [`t/docs-sync.t`](../t/docs-sync.t) fails while a part is not in line.

## <a id="my-section-1"></a>1. The sources

All pools use the same pinned sources: six Git repositories at fixed commits, plus a PDF of a book. The list, with the licences, is in [`doc/parsers/shell-subset-test-provenance.md`](parsers/shell-subset-test-provenance.md#my-section-3), section 3. A shallow fetch of each commit is enough:

```sh
mkdir corpora && cd corpora
while read d r c; do
  mkdir "$d" && git -C "$d" init -q && git -C "$d" remote add origin "https://github.com/$r" &&
  git -C "$d" fetch -q --depth 1 origin "$c" && git -C "$d" checkout -q FETCH_HEAD
done <<'L'
tldr tldr-pages/tldr f4566462f5996e13a4f3523f21dc2a863aec53c1
nl2bash TellinaTool/nl2bash d6b9f5bdff45621d190134e31ab63b7bf7002190
shellcheck koalaman/shellcheck 919d37c4d77a7ce16cfc76ebdd781dd6e8081fa5
bashcookbook-examples vossenjp/bashcookbook-examples 7fc1db649a85eaa5d6c6631397136100763db70f
pure-sh-bible dylanaraps/pure-sh-bible 26bc7e8d6cfb8716e9ccb97f31c2da80468c5737
pure-bash-bible dylanaraps/pure-bash-bible 8c19d0b482b04d8d50fb72b4c5148b41ce605c6d
L
curl -sSL -o make3.pdf 'https://raw.githubusercontent.com/yjjing/ebooks/master/Managing%20Projects%20with%20GNU%20Make%2C%203rd%20Edition.pdf'
sha256sum make3.pdf      # b188a032481ff3b41a84f96b86a3e89b75b63c847e19344dd2edc04220fd88b0
pdftotext -layout make3.pdf make3.txt
sha256sum make3.txt      # 866d44b86ac8fccc510ed31970b30ea7dc780d12e8681017d6d3f8489d6324d6 with poppler 24.02.0
```

Pool A needs the book. Pool B reads it too, but only to count the samples it then leaves out. On 2026-11-02 all the fetches worked, and both checksums matched.

## <a id="my-section-2"></a>2. Pool A: the corpus tests of the base parser

Each test carries a snippet ID that locates its text in the sources (the format: [`doc/parsers/shell-subset-test-provenance.md`](parsers/shell-subset-test-provenance.md#my-section-2), section 2).

**Check the pool against the sources** (the main check):

```sh
perl doc/parsers/tools/prov.pl CORPORA --check t/parser/shell-subset-corpus-tests.pl
```

With 0.02 (2026-11-02), and again with 0.03 (2026-11-03), this printed "612 corpus snippets checked, 0 mismatches". Without the book's `make3.txt`, the 21 `MK:` tests cannot be restored, and fail.

**Rebuild the pool's texts** from the recorded grouping:

```sh
mkdir pool && cd pool && cp DIST/doc/parsers/tools/groups.tsv . && perl DIST/doc/parsers/tools/gentests.pl
```

This needs no corpora. It writes `shell-subset-corpus-tests.pl` into the current directory (`pool/`), whose 612 IDs and texts are identical to those of the shipped [`t/parser/shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl). Its expected results (`ok`/`rej`) are those of 2026-10-29; in the file shipped with 0.03, 47 of them had since been changed by hand, as the parser learned more forms.

**Redo the grouping itself:** run [`extract.pl`](parsers/tools/extract.pl) `CORPORA samples.jsonl`, then [`run.pl`](parsers/tools/run.pl) `samples.jsonl`, [`group.pl`](parsers/tools/group.pl) and [`gentests.pl`](parsers/tools/gentests.pl), all in one directory, with `perl -I DIST/lib`. This gives a **different** pool, not the shipped one:

- The grouping keeps one sample from each set of samples that the parser treats alike, so the groups depend on what the parser accepts.
- With the parser of 0.03 it gives 577 groups, against 612 on 2026-10-29 (pre-0.01).
- The parser of 2026-10-29 was not kept (the copy of the parser kept from 2026-10-30, pre-0.01, gives 578), so [`groups.tsv`](parsers/tools/groups.tsv) is the record of that grouping.

The scripts, in [`doc/parsers/tools/`](parsers/tools):

| Script | What it does |
|---|---|
| [`extract.pl`](parsers/tools/extract.pl) `CORPORA [samples.jsonl]` | collects the samples (one-liners and scripts) with their IDs |
| [`run.pl`](parsers/tools/run.pl) `samples.jsonl` | parses them with `Proc::ShellSubset`, cuts scripts into pieces, checks the accepted text with `dash -n` and `bash -n`; writes `results.jsonl` |
| [`group.pl`](parsers/tools/group.pl) | groups `results.jsonl` and keeps the shortest sample of each group; writes [`groups.tsv`](parsers/tools/groups.tsv) |
| [`gentests.pl`](parsers/tools/gentests.pl) `[HANDWRITTEN]` | writes [`shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl) from [`groups.tsv`](parsers/tools/groups.tsv); given the hand-written test file, numbers its tests `OWN:n` (done once) |
| [`prov.pl`](parsers/tools/prov.pl) `CORPORA ID… \| --check FILE` | restores snippets from their IDs alone, independently of [`extract.pl`](parsers/tools/extract.pl) |
| [`verify.pl`](parsers/tools/verify.pl) | runs each accepted test in dash and bash with every external command replaced by its own recorder (a stand-in that only logs its arguments), and compares the recorded argv with the parse tree |
| [`ex.pl`](parsers/tools/ex.pl), [`top5.pl`](parsers/tools/top5.pl), [`top5-lines.pl`](parsers/tools/top5-lines.pl), [`chunkcov.pl`](parsers/tools/chunkcov.pl), [`chunkcov-lib.pl`](parsers/tools/chunkcov-lib.pl) | reports used while the base parser's rules were chosen (examples per rejection reason, the top reasons, how much of each script the accepted pieces cover) |
| [`groups.tsv`](parsers/tools/groups.tsv), [`summary.txt`](parsers/tools/summary.txt), [`verify.txt`](parsers/tools/verify.txt) | the outputs of 2026-10-29: the grouping, the summary of `run.pl`, the result of `verify.pl` |

## <a id="my-section-3"></a>3. Pool B: the corpus measurement of the large parser

This pool is not shipped (the samples are 45,501 lines). It is rebuilt from the sources in about 30 minutes.

Where [`corpus.mk`](corpus.mk) has a target for a command of this section, the command is the target's (`make -n TARGET` prints it), except that the target keeps its files in `CORPUS`: `rundir` and `qdir` below are `CORPUS/run` and `CORPUS/q`. The steps "After a change to ShellSpawn" and "Through Run" below have no target. `MK:` names the tests taken from the make book.

```sh
pip install shellcheck-py==0.11.0.1                    # ShellCheck 0.11.0
T=doc/large-subset/tools
perl $T/large-subset-extract.pl CORPORA samples.jsonl                            # corpus-samples
perl -Ilib $T/large-subset-scan.pl samples.jsonl > large-scan.jsonl              # corpus-scan: about 25 minutes
perl $T/large-subset-drops.pl samples.jsonl drops.tsv                            # corpus-parse: what is left out, and why (also large-subset-noise.txt)
perl $T/large-subset-yardsticks.pl -v -c sc-cache.jsonl -o samples.tsv samples.jsonl large-scan.jsonl drops.tsv > parse.txt
```

- [`large-subset-scan.pl`](large-subset/tools/large-subset-scan.pl) runs the base parser `Proc::ShellSubset`, the large parser `Proc::ShellSubset::Large`, `dash -n`, `bash --posix -n` and ShellCheck on every sample.
- After a change to a parser, `perl -Ilib $T/large-subset-reparse.pl samples.jsonl large-scan.jsonl > new.jsonl` refreshes only the parsers' columns (about 15 seconds); then use `new.jsonl` in place of `large-scan.jsonl`.
- After a change to a verdict ([`large-subset-verdicts.txt`](large-subset/tools/large-subset-verdicts.txt)) or to the detector of differences between the shells ([`large-subset-features.pl`](large-subset/tools/large-subset-features.pl)), rerun only [`large-subset-yardsticks.pl`](large-subset/tools/large-subset-yardsticks.pl). With `-c sc-cache.jsonl` it needs no ShellCheck (about 15 seconds).
- [`large-subset-remeasure.pl`](large-subset/tools/large-subset-remeasure.pl) `-d drops.tsv large-scan.jsonl` prints the older single ceiling (before the two yardsticks, one share of samples within reach of the parser; its history below), for comparison.

The parse results and what they mean: [`doc/large-subset/large-subset-state.md`](large-subset/large-subset-state.md). The history of the filters: [`large-subset-ceiling.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md) (in Proc-Spawner 0.03).

### <a id="my-behaviour-the-three-shells-compared"></a>Behaviour: the three shells compared

To compare behaviour, every accepted sample runs in dash, in `bash --posix` and in ShellSpawn. The results are in [section 7 of `doc/large-subset/large-subset-state.md`](large-subset/large-subset-state.md#my-section-7). The comparison was first made with post4-0.04, and last redone on 2026-11-17.

- It takes about 55 minutes. Each run is in a mount namespace of its own, with a fresh `/tmp`, a fixed `/dev/urandom` and fixed file times (the `-env` below); without `-env`, as with post4-0.04, it took 21 minutes.
- Run it as root (it makes the users `rc0`…`rc3` and runs the samples as them; `large-subset-threeway.pl` makes `rc9`), with no network, after `make`:

```sh
E='-env tmp,random,mtime -base /runcompare'   # corpus.mk's CENV, with CBASE
unshare -n perl $T/large-subset-runcompare.pl -j 4 $E samples.jsonl samples.tsv rundir    # corpus-run; restartable: it skips what rundir has
unshare -n perl $T/large-subset-runcompare.pl -q -j 4 $E samples.jsonl samples.tsv qdir   # corpus-qrun: ShellSpawn only, the programs' calls logged
perl $T/large-subset-calls.pl doc/large-subset/large-subset-provenance.tsv rundir      # corpus-calls: the column CALLS
perl $T/large-subset-runreport.pl -q qdir -known $T/large-subset-match-known.tsv -l $T/large-subset-run-differences.tsv rundir > runreport.txt   # corpus-runreport: the table, split by whether a coreutils command takes part
perl $T/large-subset-runreport.pl -x -q qdir -known $T/large-subset-match-known.tsv rundir > runreport-x.txt   # the external calls
unshare -n perl $T/large-subset-threeway.pl -l $T/large-subset-threeway-differences.tsv -db $T/large-subset-threeway-db.jsonl qdir > threeway.txt   # corpus-threeway
unshare -n perl $T/large-subset-builtins.pl -l $T/large-subset-builtins-differences.tsv -db builtins.jsonl qdir > builtins.txt   # corpus-builtins: about 45 minutes; -reuse OLD.jsonl skips known calls
perl -Ilib $T/large-subset-blocks.pl -e doc/large-subset/large-subset-provenance.tsv -p $T/large-subset-step3.tsv -ai $T/large-subset-ai-classes.tsv -s levels.tsv -o blocks.jsonl samples.jsonl samples.tsv > levels.txt   # corpus-provenance (-e and -p write the two records); X27: large-subset-environment.md (8 s; -batch also compares each sample parsed alone and in one text with all the others: 2 min more)
```

### <a id="my-after-a-change-to-shellspawn"></a>After a change to ShellSpawn

To measure a change to ShellSpawn without running dash and bash again, run ShellSpawn alone, each sample in the worker (and so the directory and the user) it had in `rundir`, and join the result with `rundir`'s dash and bash. (The runs "With the programs inside Perl" and "W5", once in section 7 of `large-subset-state.md` and now in [`../Changes`](../Changes), post-0.13, were made this way.) Do it on the day `rundir` was made if you can: `ls -l` shows the dates of what `-env mtime` does not fix (`/tmp`, `/`), so a joined run of another day differs there.

```sh
unshare -n perl $T/large-subset-runcompare.pl -j 4 $E -shells shellspawn -workers-from rundir samples.jsonl samples.tsv shellspawn-new   # (-only @IDS for some)
perl $T/large-subset-runreport.pl -q qdir -x -shellspawn-from shellspawn-new rundir      # the tables with the new ShellSpawn (qdir's logged calls are the old code's: run -q again if the change alters which calls are made)
perl $T/large-subset-runreport.pl -shellspawn-from shellspawn-new -shellspawn-vs rundir rundir # ShellSpawn, sample by sample: what changed
```

What changes between two runs of the same code is noise (process IDs, times, `sort -R`, races, inode numbers). To see it, run ShellSpawn alone twice and compare the two runs with `-shellspawn-vs`.

### <a id="my-the-environment-varied"></a>The environment varied (X27)

To see whether a sample's result depends on a part of the environment, take the samples that have a given code in [`large-subset-provenance.tsv`](large-subset/large-subset-provenance.tsv) (the code names what a sample may depend on; the codes are listed in [section 3 of `large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-3)). Run them three times: a base run, a second base run (its differences from the first are the noise), and the run of the variant, with that part of the environment changed. Then compare them (the results: [`doc/large-subset/large-subset-environment.md`](large-subset/large-subset-environment.md#my-section-9), section 9):

```sh
perl $T/large-subset-ids.pl doc/large-subset/large-subset-provenance.tsv path-tmp > ids.txt   # the samples of the code
B='-base /runcompare'
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -only @ids.txt samples.jsonl samples.tsv base
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -workers-from base -only @ids.txt samples.jsonl samples.tsv base2
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -env tmp -workers-from base -only @ids.txt samples.jsonl samples.tsv v-tmp
perl $T/large-subset-runreport.pl -b base -bl variants.tsv -tag tmp -noise base2 v-tmp > cmp-tmp.txt   # each sample's class in v-tmp against base; every changed sample appended to variants.tsv (an output), the noisy ones marked
```

The variants (`-env`; several are joined with commas):

- `posix`, `utf8`, `sigpipe`, `noproc`, `tmp`, `random`, `private`, `dev`, `fail`, `output`, `mtime`;
- for step 3: `cowroot` (every run in a root of its own, a copy-on-write overlay of `/`), `samearg0` (the three shells get the same `$0`, `sh`), `pidns` (every run in a PID namespace of its own);
- `clock` (a clock standing at `FIXTURE_MTIME`), never used: libfaketime leaks descriptors 3 and 4.

The header of `large-subset-runcompare.pl` says what each variant does, and for which code. The stand-ins' answers and the fixed time come from the environment: `STANDIN_STATUS=2 … -env fail`, `STANDIN_OUTPUT=… -env output`, `FIXTURE_MTIME=… -env mtime`; the values used are in `env.txt` of the run's output directory.

### <a id="my-through-run"></a>Through Run

The option `-run RUNLIB` of `large-subset-runcompare.pl` (Run's `blib/lib`, or the directory of `Run.pm`; Run is the author's module on CPAN, which `Proc::Spawner` uses where there is neither posix_spawn nor fork) makes ShellSpawn start every process through the module Run, as on a system with neither posix_spawn nor fork. Compare the result with a run without it, as above. The results are in section 7 of [`large-subset-state.md`](large-subset/large-subset-state.md#my-section-7), "Through Run".

## <a id="my-section-4"></a>4. Record C: the shells' verdict on every parser test

```sh
perl doc/large-subset/tools/large-subset-features.pl -n t/parser/large-subset-tests.pl \
  t/parser/shell-subset-tests.pl t/parser/shell-subset-corpus-tests.pl > t/parser/large-subset-shells.tsv
```

This needs dash and bash in `PATH` (for their `-n`). It reads only the tests' texts and [`large-subset-verdicts.txt`](large-subset/tools/large-subset-verdicts.txt), and runs only the shells, never the distribution's parsers. Its columns are described in [`doc/large-subset/large-subset-dialect-features.md`](large-subset/large-subset-dialect-features.md#my-section-8), section 8. Rerun it after adding tests, or after changing the detector or [`large-subset-verdicts.txt`](large-subset/tools/large-subset-verdicts.txt).
