# Test pools: what they are and how to rebuild them

The distribution has two pools of shell strings taken from public collections ("borrowed"), and one record that classifies every parser test. All scripts named here are in the distribution, and none needs network access once the sources are on disk. Below, CORPORA is the directory made in section 1, and DIST the unpacked distribution; run the commands from DIST unless a step says otherwise. Scripts that load the parsers are run with `perl -Ilib` (or `-I DIST/lib`), as shown; the others need no modules from `lib/`.

| Pool | File | Made by | Size |
|---|---|---|---|
| A. corpus tests of the base parser | `t/parser/shell-subset-corpus-tests.pl` | `doc/parsers/tools/` | 612 tests |
| B. corpus measurement of the large parser | not shipped (made on demand) | `doc/large-subset/tools/` | 45,501 extracted; 41,952 after leaving out duplicates, noise marked by hand (`tools/large-subset-noise.txt`, post2-0.04) and the like (`drops.tsv`; 41,966 for 0.03 to post-0.04) |
| C. the shells' verdict on every parser test | `t/parser/large-subset-shells.tsv` | `doc/large-subset/tools/large-subset-features.pl` | 1,117 lines (post4-0.04; post3-0.04: 1,112; post2-0.04: 1,107; post-0.04: 1,104; 0.04: 1,092; 0.03: 1,066) |

The hand-written tests (`t/parser/shell-subset-tests.pl`, `t/parser/large-subset-tests.pl`) are not borrowed. Their IDs are `OWN:n` and `LS:n`.

## 1. The sources

All pools use the same pinned sources: six Git repositories at fixed commits, plus a PDF of a book. The list, with the licences, is in `doc/parsers/shell-subset-test-provenance.md`, section 3. A shallow fetch of each commit is enough:

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

Each test carries a snippet ID that locates its text in the sources (format: `doc/parsers/shell-subset-test-provenance.md`, section 2).

**Check the pool against the sources** (the main check):

```sh
perl doc/parsers/tools/prov.pl CORPORA --check t/parser/shell-subset-corpus-tests.pl
```

With 0.02 (2026-11-02) and again with 0.03 (2026-11-03) this printed "612 corpus snippets checked, 0 mismatches". Without the book's `make3.txt`, the 21 `MK:` tests fail to restore.

**Rebuild the pool's texts** from the recorded grouping:

```sh
mkdir pool && cd pool && cp DIST/doc/parsers/tools/groups.tsv . && perl DIST/doc/parsers/tools/gentests.pl
```

This needs no corpora. It writes `shell-subset-corpus-tests.pl`, whose 612 IDs and texts are identical to the shipped file. Its expected results (`ok`/`rej`) are those of 2026-10-29. In the file shipped with 0.03, 47 of them have since been changed by hand, as the parser learned more forms.

**Redo the grouping itself:** `extract.pl CORPORA samples.jsonl`, then `run.pl samples.jsonl`, `group.pl`, `gentests.pl`, all in one directory with `perl -I DIST/lib`. This gives a **different** pool, not the shipped one. Grouping keeps one sample per set of samples the parser treats alike, so the groups depend on what the parser accepts. With the parser of 0.03 it gives 577 groups, against 612 on 2026-10-29 (pre-0.01). The parser of 2026-10-29 was not kept (the copy of 2026-10-30, pre-0.01, gives 578), so `groups.tsv` is the record of that grouping.

The scripts, in `doc/parsers/tools/`:

| Script | Does |
|---|---|
| `extract.pl CORPORA [samples.jsonl]` | collects the samples (one-liners and scripts) with their IDs |
| `run.pl samples.jsonl` | parses them with `Proc::ShellSubset`, cuts scripts into pieces, checks accepted text with `dash -n` and `bash -n`; writes `results.jsonl` |
| `group.pl` | groups `results.jsonl` and keeps the shortest sample of each group; writes `groups.tsv` |
| `gentests.pl [HANDWRITTEN]` | writes `shell-subset-corpus-tests.pl` from `groups.tsv`; given the hand-written test file, numbers its tests `OWN:n` (done once) |
| `prov.pl CORPORA ID… \| --check FILE` | restores snippets from their IDs alone, independently of `extract.pl` |
| `verify.pl` | runs each accepted test in dash and bash with every external command replaced by a recorder, and compares the recorded argv with the parse tree |
| `ex.pl`, `top5.pl`, `top5-lines.pl`, `chunkcov.pl`, `chunkcov-lib.pl` | reports used while choosing the base parser's rules (examples per rejection reason, the top reasons, coverage of scripts by accepted pieces) |
| `groups.tsv`, `summary.txt`, `verify.txt` | the outputs of 2026-10-29: the grouping, the run's summary, the recorder check |

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

- `large-subset-scan.pl` runs the base parser `Proc::ShellSubset`, the large parser `Proc::ShellSubset::Large`, `dash -n`, `bash --posix -n` and ShellCheck on every sample.
- After a parser change, `perl -Ilib $T/large-subset-reparse.pl samples.jsonl large-scan.jsonl > new.jsonl` refreshes only the parsers' columns (about 15 seconds); then use `new.jsonl` in place of `large-scan.jsonl`.
- After a change of a verdict (`large-subset-verdicts.txt`) or of the detector (`large-subset-features.pl`), rerun only `large-subset-yardsticks.pl`. With `-c sc-cache.jsonl` it needs no ShellCheck (about 15 seconds).
- `large-subset-remeasure.pl -d drops.tsv large-scan.jsonl` prints the older single ceiling, for comparison.

The figures and what they mean: `doc/large-subset/large-subset-state.md`. The history of the filters: `doc/large-subset/large-subset-ceiling.md` (in Proc-Spawner 0.03).

**Behaviour** (post4-0.04; `doc/large-subset/large-subset-state.md`, section 7): run every accepted sample in dash, `bash --posix` and ours, about 21 minutes. As root (it makes the users `rc0`…`rc3` and runs the samples as them), with no network, after `make`:

```sh
unshare -n perl $T/large-subset-runcompare.pl -j 4 samples.jsonl samples.tsv rundir    # restartable: it skips what rundir has
unshare -n perl $T/large-subset-runcompare.pl -q -j 4 samples.jsonl samples.tsv qdir   # ours only, the programs' calls logged
perl $T/large-subset-runreport.pl -q qdir -l $T/large-subset-run-differences.tsv rundir   # with and without coreutils
unshare -n perl $T/large-subset-threeway.pl -l $T/large-subset-threeway-differences.tsv -db $T/large-subset-threeway-db.jsonl qdir
unshare -n perl $T/large-subset-builtins.pl -l builtins.tsv -db builtins.jsonl qdir   # about 45 minutes; -reuse OLD.jsonl skips known calls
perl $T/large-subset-runreport.pl -x -q qdir rundir                                     # the external calls
```

## 4. Record C: the shells' verdict on every parser test

```sh
perl doc/large-subset/tools/large-subset-features.pl -n t/parser/large-subset-tests.pl \
  t/parser/shell-subset-tests.pl t/parser/shell-subset-corpus-tests.pl > t/parser/large-subset-shells.tsv
```

This needs dash and bash in `PATH` (for their `-n`). It reads only the tests' texts and the shells, never our parser. Its columns are described in `doc/large-subset/large-subset-dialect-features.md`, section 8. Rerun it after adding tests, or after changing the detector or `large-subset-verdicts.txt`.
