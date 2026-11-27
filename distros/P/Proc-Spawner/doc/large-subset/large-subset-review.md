# The 130 open differences, snippet by snippet: a review

[README's "How close"](../../README.md#my-how-close) sorts the corpus snippets in which ShellSpawn (`Proc::ShellSpawn`) differs from dash or from `bash --posix` in some run into three groups: differences that a ruling of the author allows (*legalized*), results that change from run to run (*chance*), and differences that may turn out to be bugs of ShellSpawn. In the runs of 2026-11-17 these were 1,804 = 1,629 + 45 + 130; of the 130, 88 had a proposed ruling that waits for the author ([`TODO` A12](../../TODO.md#my-a12)) and 42 had no ruling that the match knows of ([TODO A13](../../TODO.md#my-a13)). This review started from those. In the runs of 2026-11-22, with the fixes the review led to, they are 1,802 = 1,633 + 43 + 126, and the 126 are the same 88 and 38 of the 42 ([section 0](#my-section-0)).

This document reviews the 130 one at a time. Each snippet is run again in every environment that the match ([section 11 of `large-subset-environment.md`](large-subset-environment.md#my-section-11)) counts it in. Wherever ShellSpawn is not as both shells, what dash, bash and ShellSpawn did is read, and the difference is put in one of three kinds: a bug of ShellSpawn; a case that an existing ruling already covers; or a question for the author. The document is a log: each review adds its rows to [section 4](#my-section-4) and an entry to [section 6](#my-section-6), with the date and the code it ran. [Section 0](#my-section-0) says where the review stands and where to go on.

Words used below:

- A *snippet* is one text taken from the six public collections of the corpus ([`test-pools.md`](../test-pools.md)); the tools and their records call it a *sample*. Its ID starts with its collection: `TL:` the tldr pages, `NB:` NL2Bash, `SC:` ShellCheck's tests (the others do not occur here). The large parser, `Proc::ShellSubset::Large`, reads each snippet; ShellSpawn runs the snippets it accepts (40,410 in 0.13, 40,409 since D1, below).
- *The match* compares dash, `bash --posix` and ShellSpawn over all the environments of each snippet ([`large-subset-matchreport.pl`](tools/large-subset-matchreport.pl)). Its record, [`large-subset-match.tsv`](tools/large-subset-match.tsv), has one line for each snippet where ShellSpawn is not as both shells in some environment (1,804 in the runs of 2026-11-17, 1,802 in those of 2026-11-22), or where the runs ran out of time (13). Its columns: (1) the snippet ID, (2) the level (how far the environment can change the result: [section 1 of `large-subset-environment.md`](large-subset-environment.md#my-section-1)), (3) the number of environments, (4) whether the shells agree, (5) ShellSpawn where they agree, (6) ShellSpawn where they differ, (7) *why*, (8) the rules found, (9) *stable* (two runs of the base environment in the same class), (10) the class in each environment, (11) the check of `echo`, `printf`, `test`, `[`, `kill` and `pwd` against the programs. Column 7, *why*, is `yes` where a ruling covers every environment in which ShellSpawn is not as both shells, `proposed` where a ruling not yet decided does, `chance` for results that change from run to run, `open` where [`large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) marks the snippet as a known open item of TODO, and `no` where nothing covers it. The 42 of [TODO A13](../../TODO.md#my-a13) were the `no` (38) and the `open` (4) of the runs of 2026-11-17; in those of 2026-11-22 no snippet is `open`.
- *Steps 2 and 3* run again the snippets whose result may depend on the environment, in example environments made for each (step 2 from the dependences the text names, step 3 from where each value from the environment goes; step 1 sorted the snippets by their parse trees alone: [sections 10 and 12 of `large-subset-environment.md`](large-subset-environment.md#my-section-10)).
- An *environment* is one run of a snippet by all three shells: the base run (label `base`), or one of the example setups of steps 2 and 3 (labels `s1`, `s2`, … for step 2; `control/s1`, … and `affects-shell/s1`, … for the two classes of step 3: [section 12 of `large-subset-environment.md`](large-subset-environment.md#my-section-12)).
- A *setup* is what an environment changes for the snippet: files made, variables set, and what the programs answer (step 3 replaces programs by *stand-ins* that print a chosen text, for example `two  words *` or `-n a\b %s`).
- The *class* says how the three compare in one environment, messages not counted ([section 7 of `large-subset-state.md`](large-subset-state.md#my-section-7)): `same`; `=dash` or `=bash` (the shells differ and ShellSpawn does as that one); `neither`; `SHELLSPAWN` (dash and bash agree, ShellSpawn differs).
- The author's rulings and the known issues: A5 (where dash and bash differ at run time, ShellSpawn may do as dash: [`large-subset-spec.md`](large-subset-spec.md)); rule E and its rows, each named by a short word (`cdargs`, `caret`, …: [`large-subset-logical.md`](large-subset-logical.md)); B2 (the interactive builtins `history`, `fc`, `bind`, `help`, `compopt`, `logout` do nothing: [section 1 of `large-subset-state.md`](large-subset-state.md#my-section-1)); D1 (decided 2026-11-21: every grammar refuses `exec` followed by a builtin's name; [section 3 of `large-subset-state.md`](large-subset-state.md#my-section-3)); D3 (decided 2026-11-22: a command run inside Perl that writes into a broken pipe ends its shell, as SIGPIPE does in the shells); X numbers, the known issues ([`pspawn-known-issues.md`](../pspawn-known-issues.md)). "[TODO A12](../../TODO.md#my-a12)" is item 12 of part A of [`TODO`](../../TODO.md) (the decisions that wait for the author); "TODO B" is its part B (work).

## <a id="my-section-0"></a>0. Where the review stands

<a id="my-table-0"></a>

| README's 130 | Snippets | Reviewed |
|---|---|---|
| no ruling ([TODO A13](../../TODO.md#my-a13)) | 42 | all 42, on 2026-11-22 ([section 4](#my-section-4)); after the fixes of that day 38 of them still have no ruling: groups G1, G2 and G3, exactly the 38 not legalized of the full runs of 2026-11-22 ([section 6](#my-section-6)) |
| a proposed ruling ([TODO A12](../../TODO.md#my-a12)) | 88 | none yet |
| all | 130 | 42 |

**Where to go on: the 88 of [TODO A12](../../TODO.md#my-a12).** All 88 wait on the same proposal: `~` with `HOME` empty gives an empty field, as in bash and POSIX (dash drops the word). In [`large-subset-match.tsv`](tools/large-subset-match.tsv) their column 7 reads `proposed`, and in their column 8 that proposal is the only rule marked "(proposed)": it is the only rule there in 64, together with A5 in 23 and with B2 in 1 (64+23+1=88). [TODO A12](../../TODO.md#my-a12) itself says "62 samples": that is the count of the match when it was first made ([`Changes`](../../Changes), under 0.12: "62 awaiting A12"), before the environments of step 3 were counted too. What the difference looks like: `HOME=; printf '[%s]\n' ~ ~/x` prints `[/x]` alone in dash (the word `~` is dropped) and `[]`, `[/x]` in bash and ShellSpawn; in the listing of [`large-subset-envs.pl`](tools/large-subset-envs.pl) such an environment has the class `=bash` and a setup with `HOME [""]`. For each of the 88: run it again as [section 1](#my-section-1) says (the list: `awk -F'\t' '$7=="proposed"' doc/large-subset/tools/large-subset-match.tsv | cut -f1`), and check that in every environment where ShellSpawn is not as both shells, the difference is the one of `~` with `HOME` empty, or one that a ruling already decided, and nothing else. That takes about 6 minutes of runs (about 4 seconds a snippet). Record each snippet as a row of table 2 in [section 4](#my-section-4), in the same columns; a difference of a new kind gets a new mode (M8, …) in table 1 and, where needed, a new group; an entry in [section 6](#my-section-6) says what was run, with which commit.

## <a id="my-section-1"></a>1. How a snippet is run again

From a clone of the repository `https://github.com/ilyaz-ai/Proc-Spawner` (not public; branch `main`, or the commit to be reviewed; the review of 2026-11-22 used 97b63f2), as root on Linux with dash 0.5.12 and bash 5.2.21 (Ubuntu 24.04), with network access for `git`, `pip` and the corpora. For 42 snippets it takes about 5 minutes:

```sh
perl Makefile.PL && make
make corpora corpus-samples                    # the pinned corpora and their samples (seconds)
git fetch origin project-2026-11-03            # the stored scan, reparsed (15 s) instead of scanning again (25 min)
mkdir -p corpus-work/oldscan
for f in large-scan.jsonl sc-cache.jsonl; do
  git show FETCH_HEAD:claude/large-subset-scan-0.03/$f > corpus-work/oldscan/$f; done
pip install shellcheck-py==0.11.0.1
make corpus-parse OLDSCAN=corpus-work/oldscan/large-scan.jsonl SCCACHE=corpus-work/oldscan/sc-cache.jsonl
make corpus-digest                             # must be the digest in section 3 of large-subset-state.md
awk -F'\t' '$7=="no"||$7=="open"' doc/large-subset/tools/large-subset-match.tsv | cut -f1 > corpus-work/ids.txt
sh doc/large-subset/tools/large-subset-rerun.sh corpus-work/ids.txt corpus-work/review
perl doc/large-subset/tools/large-subset-envs.pl corpus-work/review/match.tsv corpus-work/review > corpus-work/review/envs.txt
```

- If the digest differs, the parsers or the measurement scripts changed since the parse results were measured, and the snippets accepted may differ: measure the parse results again first ([section 0 of `test-pools.md`](../test-pools.md#my-section-0)), then compare with the shipped records.
- [`large-subset-rerun.sh`](tools/large-subset-rerun.sh) does for the snippets named what `make corpus-run`, `corpus-step2`, `corpus-step3` and `corpus-match` do for the whole corpus: the base run; the setups of steps 2 and 3, made for the whole corpus so that each setup has the number it has in a full run; the named snippets run in each setup; and the match over these runs (`match.tsv` and `match.txt` in the output directory). It does not do the parts of the full runs that the review does not need: the check of each `echo`, `printf`, `test`, `[`, `kill` and `pwd` call against the programs (column 11 of `match.tsv`; `make corpus-threeway`), the races run 20 times (`make corpus-races`), and ShellSpawn's waiting at exit in each mode (`make corpus-endmodes`).
- [`large-subset-envs.pl`](tools/large-subset-envs.pl) lists, for each snippet, every environment where ShellSpawn is not as both shells: what the setup did, and each shell's status, standard output, messages, and the programs it called.
- To try a text by hand: `perl -Iblib/lib -Iblib/arch t/try.pl 'TEXT'` runs it in ShellSpawn; `dash -c 'TEXT'` and `bash --posix -c 'TEXT'` in the shells.
- Checked on 2026-11-22: for the 42 of [TODO A13](../../TODO.md#my-a13), `match.tsv` came out with the same columns 1 to 10 as the shipped `large-subset-match.tsv`. So the runs of `make corpus-all` of 2026-11-17, which the shipped records come from, hold on another machine. (`make corpus-provenance` is not needed for this. It would rewrite `large-subset-provenance.tsv` without the marks of its column `CALLS`, which only a full behaviour run makes.)

## <a id="my-section-2"></a>2. The modes of failure

<a id="my-table-1"></a>Table 1 counts every environment of the 42 where ShellSpawn is not as both shells, 252 in all, by what the three did (64+92+73+18+2+1+2=252). One snippet can have environments of several modes.

| Mode | What dash, bash and ShellSpawn do | Environments | Snippets | Verdict |
|---|---|---|---|---|
| M1 | `cd` gets, from an expansion, a first operand that starts with `-` and more operands (`cd $(find …)` where the program answers `-n a\b %s`): dash and bash refuse the option, status 2; ShellSpawn says "too many arguments", status 1 | 64 | 26 | **a bug of ShellSpawn: [X80](../pspawn-known-issues.md#my-x80)** ([section 3](#my-section-3)) |
| M2 | `cd` gets more than one operand (`cd $(find …)` where the program answers `two  words *`; `cd bar1 find …` in the text): dash takes the first and ignores the rest; bash and ShellSpawn say "too many arguments", status 1 | 92 | 31 | operands in the text (8 environments, 1 snippet): rule E's row `cdargs`; operands made at run time (84, 30): open, the question of [X54](../pspawn-known-issues.md#my-x54) ([TODO A13](../../TODO.md#my-a13)) |
| M3 | dash and bash differ at run time, ShellSpawn does as dash | 73 | 30 | legalized by A5 |
| M4 | ShellSpawn does as bash, as a row of rule E says: `[^…]` negates (`caret`), a descriptor of two digits (`fdmulti`), `return` outside a function is an error (`returnout`), `$LINENO` in `sh -c` (`lineno`) | 18 | 7 | covered by those rows; [`large-subset-match-known.tsv`](tools/large-subset-match-known.tsv) lacks the lines that would say so |
| M5 | `cd -` with `OLDPWD` unset: dash prints the directory, bash fails, ShellSpawn prints nothing | 2 | 2 | known; ShellSpawn does as dash since the branch `post-0.13-todo` was merged into `main` (2026-11-22) |
| M6 | `exec command -with -flags`: both shells look for a program `command` (127); ShellSpawn runs its builtin | 1 | 1 | X56; since the merge of `post-0.13-todo` the parser refuses the text (decided 2026-11-21, D1) |
| M7 | a builtin writes into a pipe whose reader has gone, in a pipeline element that ShellSpawn runs in Perl: the shells end the element (SIGPIPE), ShellSpawn's write fails and the element goes on | 2 | 1 | [TODO A17](../../TODO.md#my-a17) ([section 5](#my-section-5), P5). Not chance: ShellSpawn gives the same result in every run (20 runs), while dash and bash agree with each other in most runs and only now and then come out as ShellSpawn |

Each of the 42 snippets is in exactly one group (26+4+8+3+1=42):

- **G1, 26**: M1 in some environment (and M2, M3 in others): X80 shows in them.
- **G2, 4**: only M2 with operands made at run time, and M3: the open question of X54.
- **G3, 8**: only cases that a decided row of rule E covers (M2 with operands in the text, M4). They count as having no ruling only because `large-subset-match-known.tsv`, where the match looks up such rows, has no line for them.
- **G4, 3**: M5 and M6, which the branch `post-0.13-todo` settles (merged into `main` on 2026-11-22).
- **G5, 1**: M7.

So the 42 hold one bug of ShellSpawn not known before (X80, in the 26 snippets of G1); no other environment shows a fault of ShellSpawn that was not already known (X56, `cd -`, A17).

## <a id="my-section-3"></a>3. X80: `cd` takes its operands apart before they are expanded

The large parser keeps only the first operand word of `cd`, and a flag that more words follow (`cd_extra`; [`Large.pm`](../../lib/Proc/ShellSubset/Large.pm), in the rule for `cd`). ShellSpawn ([`ShellSpawn.pm`](../../lib/Proc/ShellSpawn.pm), `x_cd`) expands that one word, then checks, in this order: more than one field, or the flag, gives "too many arguments", status 1; a field that starts with `-` (other than `-` itself) gives "bad argument", status 2. Options are read only from the text (`-L`, `-P`; the parser refuses the others). So ShellSpawn goes wrong in three ways. In every row of table 3 but row 5, dash and bash agree with each other and ShellSpawn does not:

1. options made by an expansion are not read as options (rows 1 to 5 of table 3);
2. the operands are counted as words of the text, not as fields after the expansion, so a word that expands to nothing still counts (rows 6 and 7);
3. the words after the first are never expanded: a command substitution in them does not run, `${v:=…}` assigns nothing, `${u?…}` raises no error (rows 8 and 9).

<a id="my-table-3"></a>Table 3, checked by hand on 2026-11-22, each line in a new directory holding a subdirectory `d` (dash 0.5.12, bash 5.2.21; ShellSpawn with the code of `main`, commit 97b63f2, and of `post-0.13-todo`, commit 3f7fecb, alike):

| # | Text | dash | bash | ShellSpawn |
|---|---|---|---|---|
| 1 | `x="-n d"; cd $x` | "Illegal option -n", 2 | "invalid option", 2 | "too many arguments", 1 |
| 2 | `x="-P d"; cd $x` | to `d`, 0 | to `d`, 0 | "too many arguments", 1; stays |
| 3 | `x=-P; HOME=$PWD/d; cd $x` | to `d` (`HOME`), 0 | to `d`, 0 | "bad argument", 2; stays |
| 4 | `x="-- d"; cd $x` | to `d`, 0 | to `d`, 0 | "too many arguments", 1; stays |
| 5 | `x="-e d"; cd $x` | "Illegal option -e", 2 | to `d`, 0 | "too many arguments", 1 (as neither) |
| 6 | `cd $x d` (`x` unset) | to `d`, 0 | to `d`, 0 | "too many arguments", 1; stays |
| 7 | `set --; cd d "$@"` | to `d`, 0 | to `d`, 0 | "too many arguments", 1; stays |
| 8 | `cd d $(echo SUBST >&2)` | prints `SUBST`; to `d`, 0 | the same | "too many arguments", 1; `SUBST` not printed |
| 9 | `cd d ${u?unset-err}` | the message; the shell ends | the same | "too many arguments", 1; the shell goes on |
| 10 | `x=-n; cd $x` | "Illegal option -n", 2 | "invalid option", 2 | "bad argument", 2 (the status as both) |

The corpus runs show only the first way: in 64 environments of the 26 snippets of G1, those where step 3's stand-ins answer `-n a\b %s` (row 1's case with more operands). No snippet of the 42 has a word after the first operand of `cd` that could expand to nothing or has an expansion with an effect.

The fix (proposed, [section 5](#my-section-5), P1): the parser keeps every operand word; ShellSpawn expands them as a command's arguments, reads the options from the fields as both shells do (`-L`, `-P`, both in one word, `--`), refuses as dash does an option that only bash has (`-e`, `-@`; A5), and only then counts the operands (more than one: "too many arguments", status 1, as bash, X54). An unknown option gives status 2, as in both shells, with dash's message `cd: Illegal option -n`. The rows of table 3 become tests in [`t/programs.t`](../../t/programs.t). The 64 environments of M1 would then come out `same`.

## <a id="my-section-4"></a>4. The snippets, one by one

<a id="my-table-2"></a>Table 2: the 42 of [TODO A13](../../TODO.md#my-a13), reviewed on 2026-11-22, by group, then by snippet ID. The third column counts the snippet's environments where ShellSpawn is not as both shells, by mode: "X80" (M1), "as bash, too many operands" (M2), "as dash (A5)" (M3), and the others by their class. Snippet texts are cut at 90 characters; ⏎ stands for a new line.

| Snippet | Text | Environments where ShellSpawn is not as both shells | Group | Cause, and the ruling or issue |
|---|---|---|---|---|
| `NB:12294` | `` cd `find . -name "config"` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:12295` | `` cd $(find . -name config -type d \| sed 1q) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:1936` | `` cd `find . -name file.xml -exec dirname {} \;` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:1937` | `` cd `find . -name file.xml -printf %h` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2029` | `` cd $(dirname $(find . -name $1 \| sed 1q)) `` | X80: 1; as bash, too many operands: 2; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2030` | `` cd $(find . -name $1 \| xargs dirname) `` | X80: 1; as bash, too many operands: 2; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2461` | `` cd $(find . -name Subscription.java -printf '%h\n') `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2462` | `` cd $(find . -name Subscription.java \| xargs dirname) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2463` | `` cd `find . -name Subscription.java \| xargs dirname` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:357` | `` cd $(dirname $(dirname $(which perl)))/lib `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:359` | `` cd $(basename $1 .tar.gz) `` | X80: 1; as bash, too many operands: 1; as dash (A5): 9 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:363` | `` cd $(dirname $(which oracle)) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:364` | `` cd $(dirname `which oracle`) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:366` | `` cd $(which oracle \| xargs dirname) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:371` | `` cd $(readlink /proc/$PID/cwd) `` | X80: 1; as bash, too many operands: 1; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:4730` | `` cd $(ls -d */ \| grep 1670) `` | X80: 1; as bash, too many operands: 1; as dash (A5): 3 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:4731` | `` cd `find . -maxdepth 1 -type d \| grep 1670` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:4732` | `` cd `ls -d */ \| grep 1670` `` | X80: 1; as bash, too many operands: 1; as dash (A5): 3 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:4743` | `` cd $(dirname $(which ls)) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:4747` | `` cd $(git rev-parse --show-cdup) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:509` | `` cd `dirname $TARGET_FILE` `` | X80: 1; as bash, too many operands: 2; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:513` | `` cd `dirname $(which python)` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:529` | `` cd $(dirname $(which ssh)); `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:8019` | `` cd `script` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:9318` | `` cd $(find . -maxdepth 1 -type d -name "folder_*" \| sort -t_ -k2 -n -r \| head -1) `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:9799` | `` cd `find a \|sed '$!d'` `` | X80: 3; as bash, too many operands: 3; as dash (A5): 2 | G1 | **X80** (bug); also X54/A13 for the environments as bash |
| `NB:2773` | `` find . -mtime -1 \| cpio -oa 2>/dev/null \| ( cd $backup_dir && cpio -imd) `` | as bash, too many operands: 2; as dash (A5): 4 | G2 | X54/A13: `cdargs` for operands made at run time |
| `NB:3311` | `` cd ${CURR_DIR} && find . `` | as bash, too many operands: 3; as dash (A5): 2 | G2 | X54/A13: `cdargs` for operands made at run time |
| `NB:354` | `` cd /lib/modules/$(uname -r)/ `` | as bash, too many operands: 6; as dash (A5): 4 | G2 | X54/A13: `cdargs` for operands made at run time |
| `NB:360` | `` cd /home/`whoami` `` | as bash, too many operands: 6; as dash (A5): 2 | G2 | X54/A13: `cdargs` for operands made at run time |
| `NB:10012` | `` cd bar1 find . -maxdepth 1 -name '*foo*' -not -name '*.cc'  -exec echo ln -s $PWD/{} ../ba… `` | as bash, too many operands: 8 | G3 | rule E `cdargs` (operands in the text) |
| `NB:5607` | `` mv /mnt/usbdisk/[^l]* /home/user/stuff/. `` | as bash: 2 | G3 | rule E `caret` |
| `NB:6724` | `` head -<$LINENUM + 10> filename \| tail -20 `` | as bash: 3 | G3 | rule E `fdmulti` |
| `SC:Analytics.hs:prop_checkUseBeforeDefinition7` | `` f() { true; } ⏎ return ⏎ echo "$(f)" ⏎ echo "$(f)" `` | as bash: 1 | G3 | rule E `returnout` |
| `SC:Checks/ShellSupport.hs:prop_checkBashisms27` | `` echo *[^0-9]* `` | as bash: 6 | G3 | rule E `caret` |
| `SC:Checks/ShellSupport.hs:prop_checkBashisms47` | `` #!/bin/dash ⏎ echo foo 42>/dev/null `` | as bash: 1 | G3 | rule E `fdmulti` |
| `SC:Checks/ShellSupport.hs:prop_checkBashisms48` | `` #!/bin/sh ⏎ echo $LINENO `` | as bash: 1 | G3 | rule E `lineno` |
| `SC:Checks/ShellSupport.hs:prop_checkBashisms99` | `` #!/bin/dash ⏎ echo [^f]oo `` | as bash: 4 | G3 | rule E `caret` |
| `NB:4727` | `` cd - `` | as neither shell: 1 | G4 | `cd -` with `OLDPWD` unset; as dash since the merge of `post-0.13-todo` |
| `TL:common/cd.md:24` | `` cd - `` | as neither shell: 1 | G4 | `cd -` with `OLDPWD` unset; as dash since the merge of `post-0.13-todo` |
| `TL:common/exec.md:8` | `` exec command -with -flags `` | the shells agree, ShellSpawn differs: 1 | G4 | X56; refused by the parser since the merge of `post-0.13-todo` (D1) |
| `TL:linux/zenity.md:25` | `` (echo "#1"; sleep 1; echo "50"; echo "#2"; sleep 1; echo "100") \| zenity --progress `` | the shells agree, ShellSpawn differs: 2 | G5 | [TODO A17](../../TODO.md#my-a17): SIGPIPE in a pipeline element run in Perl |

## <a id="my-section-5"></a>5. Proposals

Each is also an item of [`TODO`](../../TODO.md), where it waits.

- **P1 (done 2026-11-22): fix X80** as [section 3](#my-section-3) says. Then `make corpus-all`, since the code of `lib/` changes ([section 0 of `test-pools.md`](../test-pools.md#my-section-0)).
- **P2 (the author confirms; [TODO A13](../../TODO.md#my-a13)): the 8 snippets of G3 are legalized by rows of rule E that are decided and marked done** in [`large-subset-logical.md`](large-subset-logical.md): `cdargs` (`NB:10012`, operands written in the text), `caret` (`NB:5607` and two ShellCheck tests; `NB:74` and `NB:9927` already have that line in [`large-subset-match-known.tsv`](tools/large-subset-match-known.tsv)), `returnout` (one ShellCheck test; two others already have that line), `fdmulti` (`NB:6724` and one ShellCheck test), `lineno` (one ShellCheck test). Once confirmed: one line each in `large-subset-match-known.tsv`, then `make corpus-match` and the counts of README's "How close" (130 would become 122).
- **P3 (a decision; [TODO A13](../../TODO.md#my-a13), the question of X54): does rule E's `cdargs` also cover operands made at run time?** ShellSpawn has answered as bash ("too many arguments", status 1) since X54, as it does for operands written in the text; dash takes the first operand and ignores the rest. This concerns the environments "as bash, too many operands" of the 30 snippets of G1 and G2 (84 environments). If yes: once X80 is fixed, lines in `large-subset-match-known.tsv` for those environments only (in their other environments A5 applies, and X80's would come out `same`), and G2's 4 snippets and G1's 26 become legalized.
- **P4 (done 2026-11-22: merged into `main`): the branch `post-0.13-todo`** settles G4: `cd -` with `OLDPWD` unset does as dash there (then legalized by A5), and the parser refuses `exec command -with -flags` (D1), which leaves the accepted snippets (40,409).
- **P5 (decided 2026-11-22, D3, and done): SIGPIPE in a pipeline element that ShellSpawn runs in Perl.** The difference is wider than the `zenity` snippet: any builtin ShellSpawn runs in Perl (`echo`, `printf`, …) writing into a pipe whose reader has gone, in an element written as `( … )`, as `{ …; }` or as a function, goes on after the failed write, where both shells end the element. Table 4, checked on 2026-11-22 (the same with the code of `post-0.13-todo`):

  <a id="my-table-4"></a>

  | Text | dash and bash | ShellSpawn |
  |---|---|---|
  | `(echo a; sleep 1; echo b; echo after-b >&2) \| true` | `after-b` not printed | `after-b` printed |
  | `{ echo a; sleep 1; echo b; echo after-b >&2; } \| true` | not printed | printed |
  | `(printf 'a\n'; sleep 1; printf 'b\n'; echo after-b >&2) \| true` | not printed | printed |
  | `trap '' PIPE; (echo a; sleep 1; echo b; echo after-b >&2) \| true` | a write error; `after-b` printed | a write error; `after-b` printed (as both) |

  Proposed: do as the shells. When such a write fails with EPIPE and SIGPIPE is not ignored (inherited so, or `trap '' PIPE`), the element ends there, as a process killed by SIGPIPE would: nothing more of it runs, no message, status 141 for that element. With SIGPIPE ignored, keep what ShellSpawn does now, which is what both shells do then.

## <a id="my-section-6"></a>6. Log

- **2026-11-22.** The 42 of [TODO A13](../../TODO.md#my-a13) run again with [`large-subset-rerun.sh`](tools/large-subset-rerun.sh), in every environment of the match, with the code of `main` after 0.13 (commit 97b63f2) and, for comparison, of the branch `post-0.13-todo` (commit 3f7fecb). The match of `main`'s runs is the shipped one, sample by sample, in columns 1 to 10. On `post-0.13-todo` only the 3 snippets of G4 change, and the `zenity` snippet's class in one environment: in one of its runs there dash too ran both `sleep 1`, as ShellSpawn does in every run (the shells vary there, as [section 7 of `large-subset-state.md`](large-subset-state.md#my-section-7) says; ShellSpawn does not). X80 found (G1). The 42 sorted into the modes of table 1 and the groups G1 to G5; proposals P1 to P5. Not done: the 88 of [TODO A12](../../TODO.md#my-a12); `make corpus-all` (no code changed).
- **2026-11-22, later.** P1, P4 and P5 done: X80 fixed, the branch `post-0.13-todo` merged into `main`, D3 (SIGPIPE ends the element) made; on the way X81 (an in-Perl command whose redirected standard error it had let go never ended) found and fixed. The four snippets marked open in `large-subset-match-known.tsv` (G4 and G5) taken out of it. The 42 run again with that code: in the 30 `cd` snippets of G1 and G2 ShellSpawn is now as both shells wherever they agree, and what is left there is X54's question (P3); the 8 of G3 as before (P2); the two `cd -` snippets and the `zenity` snippet legalized by A5 (in one environment of the `zenity` snippet bash ran no `sleep 1` at all, its first `echo` already too late: the shells race there); `exec command -with -flags` no longer accepted (D1). So 38 of the 42 still have no ruling (30+8=38), each waiting on P2 or P3. The counts of README's "How close" change only with the next `make corpus-all`.
- **2026-11-22, the full runs.** `make corpus-all` from an empty work directory, with that code (commit f781213, on the branch `corpus-run-2026-11-22`; 3 h 39 min). The match: 38,594 alike, 1,802 where ShellSpawn is not as both shells (legalized 1,633, awaiting A12 88, chance 43, not legalized 38), 13 timeouts; 38,594+1,802+13=40,409. The 38 not legalized are exactly the snippets of G1, G2 and G3 (checked by their IDs against table 2); of G4 and G5, the two `cd -` and the `zenity` snippet are legalized (A5), and `exec command -with -flags` is not accepted. Against the runs of 2026-11-17 two more snippets changed group, neither of the 42: `find . -print | xargs ls -gilds` (chance) came out alike, and `echo $(date) "0" | tee -a log.csv` went from chance to legalized (section 11 of [`large-subset-environment.md`](large-subset-environment.md#my-section-11)). README's "How close" and the documents it rests on now give these counts. The 88 of [TODO A12](../../TODO.md#my-a12) are unchanged: still the next step (section 0).
