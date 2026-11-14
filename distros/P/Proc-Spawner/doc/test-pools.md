# Test pools: what they are and how to rebuild them

The distribution has two pools of shell strings taken from public collections ("borrowed"), and one record that classifies every parser test. All scripts named here are in the distribution, and none needs network access once the sources are on disk. Below, CORPORA is the directory made in section 1, and DIST the unpacked distribution; run the commands from DIST unless a step says otherwise. Scripts that load the parsers are run with `perl -Ilib` (or `-I DIST/lib`), as shown; the others need no modules from [`lib/`](../lib).

| Pool | File | Made by | Size |
|---|---|---|---|
| A. corpus tests of the base parser | [`t/parser/shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl) | [`doc/parsers/tools/`](parsers/tools) | 612 tests |
| B. corpus measurement of the large parser | not shipped (made on demand) | [`doc/large-subset/tools/`](large-subset/tools) | 45,501 extracted; 41,952 after leaving out duplicates, noise marked by hand ([`tools/large-subset-noise.txt`](large-subset/tools/large-subset-noise.txt), post2-0.04) and the like (`drops.tsv`; 41,966 for 0.03 to post-0.04) |
| C. the shells' verdict on every parser test | [`t/parser/large-subset-shells.tsv`](../t/parser/large-subset-shells.tsv) | [`doc/large-subset/tools/large-subset-features.pl`](large-subset/tools/large-subset-features.pl) | 1,117 lines (post4-0.04; post3-0.04: 1,112; post2-0.04: 1,107; post-0.04: 1,104; 0.04: 1,092; 0.03: 1,066) |

The hand-written tests ([`t/parser/shell-subset-tests.pl`](../t/parser/shell-subset-tests.pl), [`t/parser/large-subset-tests.pl`](../t/parser/large-subset-tests.pl)) are not borrowed. Their IDs are `OWN:n` and `LS:n`.

## 0. With make

`perl Makefile.PL` puts targets for all of this into the `Makefile` (from [`corpus.mk`](corpus.mk)); `make corpus-help` lists them. They are not part of building, installing or `make test`. Linux only; the runs need root (they make the users `rc0`…`rc3` and mount, each run in a namespace of its own), no network (`unshare -n`), dash and bash; `make` first. Work files go to `CORPUS` (default `corpus-work`, ignored by git); the targets marked *(record)* rewrite the shipped file they name, so `git diff` shows what changed. Each takes what it needs from the earlier ones, and the long runs are restartable (a run skips the samples its directory has).

| Target | Does | Time |
|---|---|---|
| `corpora` | section 1: the sources at their pinned commits, and the book ([`large-subset-corpora.pl`](large-subset/tools/large-subset-corpora.pl)) | 1 minute |
| `corpus-pool-a-check`, `corpus-pool-a` | section 2: pool A against the sources; its texts again, into `CORPUS/pool` | seconds |
| `corpus-samples`, `corpus-scan`, `corpus-figures` | section 3: pool B, the scan (`OLDSCAN=FILE SCCACHE=FILE`: a stored scan reparsed instead), the parse figures | 25 minutes (15 seconds with `OLDSCAN`) |
| `corpus-digest` | the digest the parse figures depend on ([`large-subset-state.md`](large-subset/large-subset-state.md), section 3) | |
| `corpus-shells` | section 4 *(record)* | seconds |
| `corpus-provenance` | the levels, [`large-subset-provenance.tsv`](large-subset/large-subset-provenance.tsv) *(record)* | 8 seconds |
| `corpus-run`, `corpus-qrun` | the behaviour run; ours alone with its calls logged | 55 minutes each |
| `corpus-runreport`, `corpus-threeway`, `corpus-builtins` | the tables of [`large-subset-state.md`](large-subset/large-subset-state.md), section 7, and their records | minutes; 45 minutes |
| `corpus-env-variants` | [`large-subset-environment.md`](large-subset/large-subset-environment.md), section 9: [`large-subset-env-variants.tsv`](large-subset/tools/large-subset-env-variants.tsv) *(record)* | hours |
| `corpus-step2`, `corpus-step3`, `corpus-races`, `corpus-match` | sections 10, 12 and 11 there: their records; the match over every environment a snippet ran in (the base run, step 2's and step 3's), its report (`CORPUS/match.txt`) and the former comparison of messages (`CORPUS/match-raw.txt`, for [`large-subset-match-raw.md`](large-subset/large-subset-match-raw.md)) | 35 minutes, about an hour, 20 minutes, 10 minutes |
| `corpus-html` | [`large-subset-state.md.html`](large-subset/large-subset-state.md.html) from the `.md` *(record)* | |
| `corpus-all`, `corpus-clean` | everything in order, step 3 and its races included; remove `CORPUS` | many hours |
| `probe-fuzz`, `probe-stress`, `probe-memory` | not the corpus: random strings of large-subset pieces in dash, `bash --posix` and ours ([`large-subset-difffuzz.pl`](large-subset/tools/large-subset-difffuzz.pl); `FUZZ="-n 300 -seed 1"`), children ending while our Perl code runs ([`t/stress.t`](../t/stress.t)), the resident size over 1,500 runs ([`t/memory.t`](../t/memory.t)); the two tests also run with `RELEASE_TESTING=1` | 25 s per 300 strings; 20 s; 10 s |

Variables: `CORPUS`, `CJ` (workers, 4), `CBASE` (the runs' base directory, `/runcompare`), `CENV` (the environment of the main runs). Checked (post-0.11, 2026-11-11): the targets up to `corpus-provenance`, `corpus-shells` and `corpus-html` ran and gave the shipped files (the samples, the figures' digest, the provenance, the shells' verdicts); `corpus-env-variants`, `corpus-step2` and `corpus-match` ran over the runs of 2026-11-08 to 11 (a run skips what it has) and gave the shipped records byte for byte (section 11's match: but for the 34 samples rerun with files compared without messages, and two calls more, of timeouts). The full runs themselves were not repeated through `make` then; they were on 2026-11-13 (post-0.11): `make corpus-all` as root from an empty `CORPUS` in a fresh container, then the variants again for the samples [`large-subset-ids.pl`](large-subset/tools/large-subset-ids.pl) had missed; about 4½ hours with 4 workers (the scan 25 minutes, the two full runs together under an hour here, step 2 to the match about an hour and a half), and the parse records (samples, figures, provenance, step 3, the shells' verdicts) came out byte for byte the same.

**When to run again.** The run results depend on ours (`lib/`), on the runner ([`large-subset-runcompare.pl`](large-subset/tools/large-subset-runcompare.pl)) and on the shells. After a change of ours, or of the runner, `make docs-check` names the parts out of line; run `corpus-all` again (about 4½ hours): all three shells, not ours alone (a change of the runner, as its waiting for background jobs, -after, changes dash's and bash's results too), and step 3 with them (section 11's trees count each snippet over the base run and the setups of steps 2 and 3; the user, 2026-11-13).

**The documents in line.** [`docs-sync.tsv`](docs-sync.tsv) maps each part of a document that shows such results (section 11 of [`large-subset-environment.md`](large-subset/large-subset-environment.md), section 7 of [`large-subset-state.md`](large-subset/large-subset-state.md), the figures in [`README`](../README), ...) to the records, reports and scripts it draws on, with their SHA-256 when the part was last brought in line. `make docs-check` ([`docs-sync.pl`](docs-sync.pl)) names every part whose inputs changed since, and what to redo by hand; `make docs-synced DOC=FILE [PART=...]` records the new hashes once it is done; `make docs-map` shows the map. Hashes, not file times: Git keeps no times. With `RELEASE_TESTING=1`, [`t/docs-sync.t`](../t/docs-sync.t) fails while a part is not in line.

## 1. The sources

All pools use the same pinned sources: six Git repositories at fixed commits, plus a PDF of a book. The list, with the licences, is in [`doc/parsers/shell-subset-test-provenance.md`](parsers/shell-subset-test-provenance.md), section 3. A shallow fetch of each commit is enough:

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

Pool A needs the book; pool B reads it too, but only to count the samples it then leaves out. Checked on 2026-11-02: all fetches worked, and both checksums matched.

## 2. Pool A: the corpus tests of the base parser

Each test carries a snippet ID that locates its text in the sources (format: [`doc/parsers/shell-subset-test-provenance.md`](parsers/shell-subset-test-provenance.md), section 2).

**Check the pool against the sources** (the main check):

```sh
perl doc/parsers/tools/prov.pl CORPORA --check t/parser/shell-subset-corpus-tests.pl
```

With 0.02 (2026-11-02) and again with 0.03 (2026-11-03) this printed "612 corpus snippets checked, 0 mismatches". Without the book's `make3.txt`, the 21 `MK:` tests fail to restore.

**Rebuild the pool's texts** from the recorded grouping:

```sh
mkdir pool && cd pool && cp DIST/doc/parsers/tools/groups.tsv . && perl DIST/doc/parsers/tools/gentests.pl
```

This needs no corpora. It writes [`shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl), whose 612 IDs and texts are identical to the shipped file. Its expected results (`ok`/`rej`) are those of 2026-10-29. In the file shipped with 0.03, 47 of them have since been changed by hand, as the parser learned more forms.

**Redo the grouping itself:** [`extract.pl`](parsers/tools/extract.pl) `CORPORA samples.jsonl`, then [`run.pl`](parsers/tools/run.pl) `samples.jsonl`, [`group.pl`](parsers/tools/group.pl), [`gentests.pl`](parsers/tools/gentests.pl), all in one directory with `perl -I DIST/lib`. This gives a **different** pool, not the shipped one. Grouping keeps one sample per set of samples the parser treats alike, so the groups depend on what the parser accepts. With the parser of 0.03 it gives 577 groups, against 612 on 2026-10-29 (pre-0.01). The parser of 2026-10-29 was not kept (the copy of 2026-10-30, pre-0.01, gives 578), so [`groups.tsv`](parsers/tools/groups.tsv) is the record of that grouping.

The scripts, in [`doc/parsers/tools/`](parsers/tools):

| Script | Does |
|---|---|
| [`extract.pl`](parsers/tools/extract.pl) `CORPORA [samples.jsonl]` | collects the samples (one-liners and scripts) with their IDs |
| [`run.pl`](parsers/tools/run.pl) `samples.jsonl` | parses them with `Proc::ShellSubset`, cuts scripts into pieces, checks accepted text with `dash -n` and `bash -n`; writes `results.jsonl` |
| [`group.pl`](parsers/tools/group.pl) | groups `results.jsonl` and keeps the shortest sample of each group; writes [`groups.tsv`](parsers/tools/groups.tsv) |
| [`gentests.pl`](parsers/tools/gentests.pl) `[HANDWRITTEN]` | writes [`shell-subset-corpus-tests.pl`](../t/parser/shell-subset-corpus-tests.pl) from [`groups.tsv`](parsers/tools/groups.tsv); given the hand-written test file, numbers its tests `OWN:n` (done once) |
| [`prov.pl`](parsers/tools/prov.pl) `CORPORA ID… \| --check FILE` | restores snippets from their IDs alone, independently of [`extract.pl`](parsers/tools/extract.pl) |
| [`verify.pl`](parsers/tools/verify.pl) | runs each accepted test in dash and bash with every external command replaced by a recorder, and compares the recorded argv with the parse tree |
| [`ex.pl`](parsers/tools/ex.pl), [`top5.pl`](parsers/tools/top5.pl), [`top5-lines.pl`](parsers/tools/top5-lines.pl), [`chunkcov.pl`](parsers/tools/chunkcov.pl), [`chunkcov-lib.pl`](parsers/tools/chunkcov-lib.pl) | reports used while choosing the base parser's rules (examples per rejection reason, the top reasons, coverage of scripts by accepted pieces) |
| [`groups.tsv`](parsers/tools/groups.tsv), [`summary.txt`](parsers/tools/summary.txt), [`verify.txt`](parsers/tools/verify.txt) | the outputs of 2026-10-29: the grouping, the run's summary, the recorder check |

## 3. Pool B: the corpus measurement of the large parser

This pool is not shipped (the samples are 45,501 lines). It is rebuilt from the sources in about 30 minutes:

```sh
pip install shellcheck-py==0.11.0.1                    # ShellCheck 0.11.0
T=doc/large-subset/tools
perl $T/large-subset-extract.pl CORPORA samples.jsonl
perl -Ilib $T/large-subset-scan.pl samples.jsonl > large-scan.jsonl              # about 25 minutes
perl $T/large-subset-drops.pl samples.jsonl drops.tsv                            # what is left out, and why (also large-subset-noise.txt)
perl $T/large-subset-yardsticks.pl -v -c sc-cache.jsonl -o samples.tsv samples.jsonl large-scan.jsonl drops.tsv
```

- [`large-subset-scan.pl`](large-subset/tools/large-subset-scan.pl) runs the base parser `Proc::ShellSubset`, the large parser `Proc::ShellSubset::Large`, `dash -n`, `bash --posix -n` and ShellCheck on every sample.
- After a parser change, `perl -Ilib $T/large-subset-reparse.pl samples.jsonl large-scan.jsonl > new.jsonl` refreshes only the parsers' columns (about 15 seconds); then use `new.jsonl` in place of `large-scan.jsonl`.
- After a change of a verdict ([`large-subset-verdicts.txt`](large-subset/tools/large-subset-verdicts.txt)) or of the detector ([`large-subset-features.pl`](large-subset/tools/large-subset-features.pl)), rerun only [`large-subset-yardsticks.pl`](large-subset/tools/large-subset-yardsticks.pl). With `-c sc-cache.jsonl` it needs no ShellCheck (about 15 seconds).
- [`large-subset-remeasure.pl`](large-subset/tools/large-subset-remeasure.pl) `-d drops.tsv large-scan.jsonl` prints the older single ceiling, for comparison.

The figures and what they mean: [`doc/large-subset/large-subset-state.md`](large-subset/large-subset-state.md). The history of the filters: [`large-subset-ceiling.md` (0.03)](https://metacpan.org/release/ILYAZ/Proc-Spawner-0.03/view/doc/large-subset/large-subset-ceiling.md) (in Proc-Spawner 0.03).

**Behaviour** (post4-0.04, run again post-0.09; [`doc/large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 7): run every accepted sample in dash, `bash --posix` and ours, about 55 minutes (each run in a mount namespace of its own: a fresh `/tmp`, a fixed `/dev/urandom`, fixed file times; without `-env`, 21 minutes, as post4-0.04). As root (it makes the users `rc0`…`rc3` and runs the samples as them), with no network, after `make`:

```sh
E='-env tmp,random,mtime -base /runcompare'   # the table of post-0.09
unshare -n perl $T/large-subset-runcompare.pl -j 4 $E samples.jsonl samples.tsv rundir    # restartable: it skips what rundir has
unshare -n perl $T/large-subset-runcompare.pl -q -j 4 $E samples.jsonl samples.tsv qdir   # ours only, the programs' calls logged
perl $T/large-subset-runreport.pl -q qdir -l $T/large-subset-run-differences.tsv rundir   # with and without coreutils
unshare -n perl $T/large-subset-threeway.pl -l $T/large-subset-threeway-differences.tsv -db $T/large-subset-threeway-db.jsonl qdir
unshare -n perl $T/large-subset-builtins.pl -l builtins.tsv -db builtins.jsonl qdir   # about 45 minutes; -reuse OLD.jsonl skips known calls
perl $T/large-subset-runreport.pl -x -q qdir rundir                                     # the external calls
perl -Ilib $T/large-subset-blocks.pl -batch -e doc/large-subset/large-subset-provenance.tsv samples.jsonl samples.tsv   # X27: large-subset-environment.md (8 s; -batch: 2 min more)
```

**After a change of ours** (post-0.10; how section 7's "With the programs inside Perl" and "W5" were made): run ours alone, each sample in the worker (so the directory and user) it had in `rundir`, and join it with `rundir`'s dash and bash. Do it on the day of `rundir` if you can: `ls -l` shows the date of what `-env mtime` does not fix (`/tmp`, `/`), and a joined run of another day differs there.

```sh
unshare -n perl $T/large-subset-runcompare.pl -j 4 $E -shells ours -workers-from rundir samples.jsonl samples.tsv ours-new   # (-only @IDS for some)
perl $T/large-subset-runreport.pl -q qdir -x -ours-from ours-new rundir      # the tables with the new ours
perl $T/large-subset-runreport.pl -ours-from ours-new -ours-vs rundir rundir # ours, sample by sample: what changed
```

What changes between two runs of the same code is noise (process IDs, times, `sort -R`, races, inode numbers): run ours alone twice and compare the two with `-ours-vs` to see it.

**The environment varied** (X27; [`doc/large-subset/large-subset-environment.md`](large-subset/large-subset-environment.md), section 9): the samples of a code, a base run, a second base run (the noise) and the variant's run, compared:

```sh
grep -v '^#' doc/large-subset/large-subset-provenance.tsv | awk -F'\t' -v c=path-tmp '{ n = split($2, a, /[:,\/]/); for (i = 2; i <= n; i++) if (a[i] == c) { print $1; break } }' > ids.txt
B='-base /runcompare'
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -only @ids.txt samples.jsonl samples.tsv base
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -only @ids.txt samples.jsonl samples.tsv base2
unshare -n perl $T/large-subset-runcompare.pl -j 4 $B -env tmp -only @ids.txt samples.jsonl samples.tsv v-tmp
perl $T/large-subset-runreport.pl -b base v-tmp     # classes against the base run, and every sample that changed
perl $T/large-subset-runreport.pl -b base base2     # the noise
```

The variants (`-env`, several with commas): `posix`, `utf8`, `sigpipe`, `noproc`, `tmp`, `random`, `private`, `dev`, `fail`, `output`, `mtime`; the script's header says what each does and for which code. The stand-ins' answers and the fixed time come from the environment: `STANDIN_STATUS=2 … -env fail`, `STANDIN_OUTPUT=… -env output`, `FIXTURE_MTIME=… -env mtime`; the values used are in `OUTDIR/env.txt`.

**Through Run** (section 7, "Through Run"): `-run RUNLIB` (Run's `blib/lib`, or the directory of `Run.pm`) makes ours start every process through Run, as where there is neither posix_spawn nor fork; compare with a run without it, as above.

## 4. Record C: the shells' verdict on every parser test

```sh
perl doc/large-subset/tools/large-subset-features.pl -n t/parser/large-subset-tests.pl \
  t/parser/shell-subset-tests.pl t/parser/shell-subset-corpus-tests.pl > t/parser/large-subset-shells.tsv
```

This needs dash and bash in `PATH` (for their `-n`). It reads only the tests' texts and the shells, never our parser. Its columns are described in [`doc/large-subset/large-subset-dialect-features.md`](large-subset/large-subset-dialect-features.md), section 8. Rerun it after adding tests, or after changing the detector or [`large-subset-verdicts.txt`](large-subset/tools/large-subset-verdicts.txt).
