# Proc-Spawner: what is open, in one place

```text
0.12, 2026-11-13.  Every postponed thing, by who has to act.  The full
records behind each line: doc/pspawn-known-issues.md (X..., section "Open"),
doc/large-subset/large-subset-state.md (sections 4-6),
doc/large-subset/large-subset-environment.md (X27), doc/pspawn-spawner.md
(section 8: Windows), Changes.  Keep this file current: when an item is
decided or done, remove it here and record it where it belongs.
The differences of README's "How close" that may be bugs (130 in the
runs of 2026-11-17, 126 in those of 2026-11-22; items 12 and 13 below), reviewed snippet by snippet, with where the review stands
and how to go on: doc/large-subset/large-subset-review.md.
```

## <a id="my-part-a"></a>A. WAITING FOR THE USER'S DECISION

<a id="my-a1"></a>

```text
 1. X27: which samples of the behaviour run (large-subset-state.md,
    section 7) compare meaningfully, in the user's four steps (2026-11-10):
    (1) find the samples the environment cannot affect; (2) for the
    others, describe exactly how they are affected, and run them in a few
    example environments (where only one command of a snippet is
    affected); (3) recognize more such samples by simple programmatic
    tests; (4) leave the rest to deep AI analysis.
    Step 1, done (2026-11-07): the levels from the parse trees alone
    (doc/large-subset/large-subset-environment.md, sections 1-4): strict
    365, held 2, almost strict 34,291 (if programs behave alike in each
    run), undecided 5,752 (before step 3).  Record per sample:
    large-subset-provenance.tsv.
    Step 2, done in part (2026-11-08; section 9): each undecided sample has
    codes naming what kind of thing it depends on (files, vars, path-tmp,
    ...: section 3, "At a glance"), not exactly how (files does not say
    which file).  Example environments were run where one switch of the
    whole environment flips the case (-env of large-subset-runcompare.pl):
    POSIXLY_CORRECT, locale, SIGPIPE, /proc, a fresh /tmp, a fixed
    /dev/urandom, empty /home, /mnt, /var, a private /dev, every logged
    program failing (STANDIN_STATUS) or printing a chosen text
    (STANDIN_OUTPUT), fixed file times (FIXTURE_MTIME); each on every
    sample with its code, not only those with one affected command.  The
    samples that changed: tools/large-subset-env-variants.tsv.  Decided:
    such runs are footnotes to the level totals (EV1); the published table
    is the run with a fresh /tmp, a fixed /dev/urandom and fixed file
    times (A1(b)).
    Step 2 for the codes inside the run, done (2026-11-10, 11; branch
    x27-step2; large-subset-environment.md, section 10):
    large-subset-blocks.pl -d names each undecided sample's dependences
    exactly; the 2,901 samples that depend only on files, variables,
    standard input, arguments, cd or HOME by exact names (the partially
    decided) ran in example setups: 3 each, every combination (9) for two
    dependences, 3 + 3m for more (the user's "3^m tries ... 3+3*m"):
    1,547 kept their class, 1,350 changed it with ShellSpawn still on the side
    of a shell, 4 moved to where ShellSpawn agrees with neither (explained).
    Nine bugs of ours found on the way (X39-X47), all fixed.  Record:
    tools/large-subset-env-setups.tsv.
    The match across environments (the user, 2026-11-10 and 11; section
    11): two trees (the user's layout): every snippet by whether dash and
    bash agree and with which ShellSpawn sides; columns by builtin-vs-coreutils,
    checked command by command (every command ShellSpawn ran, in every
    environment, run alone by coreutils, dash's builtin, bash's builtin
    and ShellSpawn: ShellSpawn = coreutils in all 155); the second tree splits each
    box by legalization.  Messages count nowhere, wherever a redirection
    sends them (the user: compensated before the analysis; the former
    comparison: large-subset-match-raw.md).  Run again post-0.11
    (2026-11-13: the code with X39 to X56 found, the runner waiting for
    background jobs, step 3's environments counted too): of the 1,793
    snippets where ShellSpawn is not as both shells: legalized by rulings 1,620,
    awaiting A12 88, chance 40, not legalized 45 (items 13 and 17; X56,
    and cd -).  large-subset-matchreport.pl prints it all;
    tools/large-subset-match.tsv per snippet.
    Step 3, done (2026-11-12; section 12): large-subset-blocks.pl follows
    every value from the environment to where it lands; of the 5,741 left
    undecided by the codes: pass 664 and split 1,476 (only passing through
    the shell, some split and globbed into a program's words) are almost
    strict now (the user's (a): assumptions passthrough and splitglob,
    probed by make probe-values), so almost strict 36,442, undecided
    3,601; control 2,525 (only through what the run can set: a switch whose
    other state a ruling covers, a program's answer, /tmp); affects-shell
    1,076 (a value from the environment affects what the shell itself
    does).
    Checked against step 2's runs: no counterexample left unexplained.
    Step 2 for the control class, done (2026-11-12; section 12; the user:
    with any program a stand-in): 2,441 samples in 8,862 setups, each run
    in a root of its own (-env cowroot), the programs' answer one more
    dependence; where the environment changed the class, only into a
    difference a ruling legalizes (the one not legalized, cd with extra
    words, is the same in every environment).  Partially decided now
    2,838 of the 3,601 undecided.  Record: large-subset-env-control.tsv.
    Step 2 for the class affects-shell, done (2026-11-12; section 12): 948
    samples, with the same $0 for the three and a PID namespace per run;
    of the 410 where ShellSpawn is not as both shells: legalized 301, awaiting
    A12 67, chance 39 (33 races; 6 persistent results, item 17), not legalized 3
    ([^...], item 13).  X53 found and fixed.  Names with an expansion
    (the user: choose the value and make the file of that name together;
    2026-11-12): 119 of 149 samples got setups (control 34, affects-shell
    85); not legalized among them 31 (cd with extra words 30, a two-digit
    descriptor 1: item 13); X54 found and fixed.  The 33 races, run 20 times
    each (make corpus-races): 14 were a background job that ShellSpawn finishes
    before it ends and the run killed in the shells; decided (A18, the
    user, 2026-11-12): the runner waits for them too, up to 5 s (-after).
    Then 27 the same in every run, 6 races (chance); X55 found and fixed.  Partially decided now
    3,508 of the 3,601 undecided; the other 93, which the setups left out,
    are classified by Claude reading them (item 19).
```

<a id="my-a3"></a>

```text
 3. P2 and P4 (large-subset-state.md, sections 4-5): ${...} forms both
    shells refuse (run 2026-11-26: both fail, but dash with status 2,
    bash 127; item 27); messages with our name and line, and $-.
```

<a id="my-a5"></a>

```text
 5. X2: $! of a background job that starts no process (design question K4).
```

<a id="my-a6"></a>

```text
 6. X7: run() ignores SIGINT and SIGQUIT while it runs, as Perl's system
    does: say if not wanted.
```

<a id="my-a7"></a>

```text
 7. Perl's Windows bugs drafted in doc/perl-win32-system-bugs.md (argv
    quoting, the cmd.exe retry, batch files, inherited handles, every failure
    to start reported as ENOENT): file them, or ask.
```

<a id="my-a8"></a>

```text
 8. Delete the branch run of this repository on GitHub (the proxy refuses
    deletions here); its contents are in ilyaz-ai/run, whose 0.07 is on
    CPAN (the user, 2026-11-10).
```

<a id="my-a9"></a>

```text
 9. X22 (bash's own bug): report it to bug-bash, if wanted.
```

<a id="my-a10"></a>

```text
10. M2: where there is neither posix_spawn nor fork, a missing Run makes
    spawn die (at its first call, not at load).  Act: keep it, or fail
    with $! as an unsupported setting does.
```

<a id="my-a11"></a>

```text
11. Perl's own writes into the graph's own pipes reopen /proc/self/fd/N for
    every write.  Keeping that handle for the pipe's life (closed with the
    end) is safe for the graph's pipes only (not the caller's fds, which
    the module never closes); measured: at most 2.5% even for a loop of
    builtins writing into a pipeline.  Act: do it, or leave it.
```

<a id="my-a12"></a>

```text
12. X27, section 11: ~ with HOME empty.  dash 0.5.12 drops the word (and
    ~/x loses its prefix): ❰BUG❱ dash, as POSIX treats the result of ~ as
    quoted; bash and ShellSpawn give an empty field.  The rule table marks ShellSpawn's
    way "proposed" (62 samples).  Act: confirm (then
    also report it to dash, if wanted), or decide otherwise.
    (The match record, large-subset-match.tsv, has 88 snippets whose only
    open reason is this proposal: alone in 64, with A5 in 23, with B2 in 1;
    the 62 is the match as first made, Changes under 0.12, before step
    3's environments were counted.  These 88 are not yet reviewed one by
    one: large-subset-review.md, section 0.)
```

<a id="my-a13"></a>

```text
13. X27, section 11: 7 snippets where bash = ShellSpawn != dash and no ruling
    legalizes it (and 2 with cd -, in B): [^...] in a pattern (2) and
    return outside a function (1), as rule E but not yet listed under it;
    echo foo 42>/dev/null (dash: one-digit fd numbers only; also, in
    step 3, head -<$LINENUM + 10> filename, NB:6724); echo $LINENO
    after a #! line (dash: empty); cd with extra words (dash ignores them;
    in step 3 also 30 samples where a program's answer gives cd its
    operands, cd $(find . -name config): bash and ShellSpawn, since X54, "too
    many arguments", status 1); [^...] also in step 3 (mv
    /mnt/usbdisk/[^l]* ...);
    races between the elements of a pipeline: ls -a | tee output.file,
    and since the runs of post-0.11 cat lol | sed ... > lol (sed's
    redirection empties lol before or after cat reads it) and NB:12523,
    find $DiskName ... | sort ... >> $TMPFILE given "two  words *"
    (find's pattern sees the file sort's redirection makes, or not); each
    came out otherwise in another run; and, found by the fuzzer, not a
    snippet (the user, 2026-11-12: join it to this list): return || shift
    at the top level, where ShellSpawn follows bash for return (X48) and dash
    for the failed shift (A5) and so ends as neither shell (status 2; both
    give 0).  Act: decide them one by one, with the rules (the user,
    2026-11-11: later).
    Reviewed one by one 2026-11-22 (large-subset-review.md): X80, a bug of
    ShellSpawn found in 26 of them, fixed; the branch post-0.13-todo
    merged (cd - twice as dash, legalized by A5; exec command no longer
    accepted, D1); the zenity snippet done by D3 (A17).  Run again after
    these (large-subset-rerun.sh): 38 still have no ruling; the full runs
    of 2026-11-22 (make corpus-all) gave the same 38 not legalized.  Proposals:
    (a) 8 are covered by decided rows of rule E (cdargs with the operands
    in the text: NB:10012; caret: NB:5607 and two ShellCheck tests;
    returnout 1; fdmulti 2, NB:6724 among them; lineno 1) that
    large-subset-match-known.tsv has no line for: confirm them, then a
    line each; (b) the other 30 (cd given several operands by an
    expansion: ShellSpawn says "too many arguments", status 1, as bash,
    since X54; dash takes the first): decide X54's open question, whether
    rule E's cdargs covers operands made at run time.
```

<a id="my-a15"></a>

```text
15. MetaCPAN shows the .md files rendered (/view/doc/...; relative links
    between them work, checked by the author 2026-11-11) but not their
    tables; the POD's links to them (Proc::Spawner::Docs, to /source/:
    the raw text) did not work.  The experiments for 0.12 (the user,
    2026-11-11 and 12), written post-0.11: Proc::Spawner::Docs links
    each document twice, its name to the rendered file of the newest
    release (/dist/Proc-Spawner/view/doc/...) and, in an =for html
    paragraph, the same file of the same release (../../../doc/... from
    /release/.../view/lib/Proc/Spawner/Docs.pod; it works from
    /release/.../view/ and /dist/.../view/, not from /pod/...); the test
    page doc/metacpan-tables.md has one table as a pipe table, raw HTML,
    preformatted text indented and fenced, and a list.  Act, after 0.12
    is on MetaCPAN: look at Docs and the test page, check both kinds of
    link, choose the table form.
```

<a id="my-a17"></a>

```text
17. X27, step 3: persistent results (the same in every run, which the
    environment does not change), found in the class affects-shell,
    that no ruling covers yet (section 12): the
    environment env and printenv list (5 snippets, since IN1 with v=5 env |
    less: bash adds SHLVL and _; dash and ShellSpawn list the same variables,
    in another order); /proc/$$/cmdline (1: each shell's own command line,
    ShellSpawn a Perl one); times (1: ShellSpawn, Perl, has used CPU time where dash
    shows 0).  Act: rule on them (they are built into the shells and
    into ShellSpawn; the environment does not change them).
    (The zenity snippet of this list, a builtin's echo into a pipe whose
    reader has gone, decided 2026-11-22 (D3) and done: Changes.  Left of
    D3: ShellSpawn's own builtins that print, jobs, type, set, export -p,
    trap, umask, cd -, still fail alone on such a write; the shells'
    builtins die there too.  Rare in the corpus; act if wanted.)
```

<a id="my-a19"></a>

```text
19. X27, step 3: the 93 undecided samples the setups left out, classified
    by Claude (an AI) reading them (2026-11-13; the user's categories: AI- and a category used
    before, and AI-PATH-twister; large-subset-environment.md, section 12;
    record doc/large-subset/tools/large-subset-ai-classes.tsv): AI-strict
    27 (an unmovable stone 18, a device working as expected 9), AI-names
    with an expansion 26, AI-values passed on unchanged 7, AI-values passed
    on split 7, AI-tilde 6, AI-A5 5, AI-glob 4, AI-shells' own variables 4,
    AI-PATH-twister 4, AI-noise 3.  Act: accept each category, or move a
    sample (the work each takes: B).
```

<a id="my-a20"></a>

```text
20. win_spawn.h for Perl's core (post-0.12; another session, prhx, is
    drafting a patch that takes a copy of it into Perl as its posix_spawn
    on Windows; doc/pspawn-spawner.md, section 8, "Done post-0.12").
    Taken from that patch, with changes: the options WIN_OPT_CMD_RAW,
    WIN_OPT_ARGV_RAW, WIN_OPT_KEEP_QUOTED, which Proc::Spawner does not
    set.  Act: keep them, or leave them to Perl's copy.
    Also, a batch file: cmd.exe takes the first word of its command line
    both as what it runs and as %0, so posix_spawn's two names (FILE, what
    runs; argv[0], what the program is called) cannot both reach a batch
    file.  With system { 'rm' } 'swissarmy', 'foo' and rm.cmd found as
    C:\bin\rm.cmd, that first word can be: (1) the path found,
    "C:\bin\rm.cmd" (now; %0 shows the path); (2) FILE as written, rm
    (cmd.exe looks it up again, in the current directory first, then PATH:
    another file may run than the one found and checked); (3) argv[0],
    swissarmy (cmd.exe runs whatever swissarmy names, not FILE at all).
    Perl's own spawn: (3), as far as Claude knows (its command line starts
    with argv[0], and Windows hands a batch file's command line to cmd.exe
    as it is; not checked on real Windows, and under Wine Perl's batch
    files fail); its t/win32/system.t, which expects %0 as written, has
    FILE and argv[0] the same, where (2) and (3) agree.  Act: (1), (2), or
    (2) as an option (Perl's copy, for its old %0).  Claude's view
    (2026-11-14): (1), (2) only as an option, never (3).
```

<a id="my-a21"></a>

```text
21. X61's rest: `read` with backslashes in the line, where dash and bash
    differ from each other (found 2026-11-13 with X61's random cases):
    for the user to decide case by case (pspawn-known-issues.md, X61).
```

<a id="my-a22"></a>

```text
22. Asked 2026-11-18, not yet answered:
    (a) "Convert core README to .md": the top-level README is README.md
        already; which file is meant (Run's README in ilyaz-ai/run?).
    (b) W2's refusal of fds 3 and up for programs known to ignore them
        (java, javaw): decided 2026-11-01, never built (no trace in the
        code; pspawn-spawner.md, section 8, says so): build it, or drop
        it from the documents?
    (c) N1 and N4 of the removed page "Spawn Graph Notation"
        (pspawn-graph.md): still open, or lapsed with the page?
    (d) X63, "the user's choice of 2026-11-14, way A, provisionally":
        does "provisionally" still hold?
```

<a id="my-a25"></a>

```text
25. To consider (the user, 2026-11-18): error messages are not compared
    at all in the runs of the corpus (standard error is left out of the
    classes; lines with a shell's message prefix are dropped from standard
    output and from files: large-subset-matchreport.pl, "messages count
    nowhere", the user's decision of post-0.11).  Whether, or how, to
    compare them after all.
```

<a id="my-a26"></a>

```text
26. Asked 2026-11-18, not yet answered: rename the spawn primitive's
    approaches (called "levels" in the documents until 2026-11-26)?
    Approach 3 ("fork": fork and exec with nothing in between, one for
    tests, since a POSIX system without posix_spawn would define
    posix_spawn) and approach 4 ("system1": Perl's system 1, LIST through Run;
    on Linux Run emulates it).  Claude's proposal: "bare" and "Run".  A
    rename touches $PRIMITIVE, the names PROC_SPAWNER_MISSING takes, the
    tests' labels and the records.
```

<a id="my-a27"></a>

```text
27. Asked 2026-11-26, not yet answered (README.md, "How close", the
    rejected snippets; their run in dash and bash alone, make
    corpus-rejected, record doc/large-subset/tools/large-subset-
    rejected.tsv):
    (a) the 8 of the work list that come out alike, also in the example
    environments, and that no decision keeps rejected (unset -f ls
    /bin/ls, for _ in *, two function definitions never called, command -,
    hash -v, foo[a][b]=3, $(var[i])); ls ~- is out, it differs once
    OLDPWD is set: should the large parser accept them, so that ShellSpawn
    runs them and does what both shells do?
    (b) the 25 of the 30 of the work list where dash and bash differ
    only when they run them (19 both fail with different statuses, 6 one
    fails, 5 other output), not counting the 3 ulimit (B3) and the 2
    set -o kept out: should the large parser accept them, ShellSpawn
    doing what dash does when it runs them (A5): where both fail,
    failing with dash's status?
    The runs in example environments, written by reading the snippets,
    are done (2026-11-26, make corpus-rejected-envs, record
    large-subset-rejected-envs.tsv; large-subset-state.md, section 4):
    of the 25 that differ, 7 are alike in some environments, 12 in none,
    6 read nothing from it.
    (c) the 20 subtle and 313 foreign ones that came out alike are alike
    in one environment only; nothing is proposed for them.
```

## <a id="my-part-b"></a>B. WORK (no decision needed)

<a id="my-b-x86-the-runs-see"></a>

```text
 - X86 (pspawn-known-issues.md; found 2026-11-26; ours, the runner): the runs
   see the machine's whole file system, and snippets that list it put the
   names of its own files (session identifiers under /tmp, other cloned
   repositories) into the records.  Before the next make corpus-all: hide
   /home (but the run's own home), /tmp and /root in every run, or redact
   the records before they are stored in Proc-Spawner-results.
```

<a id="my-b-readme-md-how-close-part"></a>

```text
 - README.md, "How close", part "Counts that do not match" (added
   post-0.13): go over each item and remove it once the counts are
   brought in line: item 3 (the six commands, 1,333 against 1,154:
   reconcile snippet by snippet from corpus-work/q and the threeway
   database); item 4 (one measure of messages in every part; with A25);
   then items 1, 2 and 5, explained, by saying in the parts themselves
   what each count covers.  Also the 20 tests skipped under Wine at
   approach 1 ("Where the tests ran"): how many of each kind (not
   recorded in doc/test-results/).  The aim: a README as short as the
   distribution allows.  Readability, still open there: terms used
   before they are explained (corpus, post-0.13, D3, the shell layer,
   Wine, "masked for tests"); "codes" names both the rulings (A5) and
   the codes a program gives the snippets; the row "no such command" of
   the one run's table; what ignoring SIGINT and SIGQUIT means on
   Windows (Threads).
```

<a id="my-b-x84-pspawn-known-issues-md-fixed-in"></a>

```text
 - X84 (pspawn-known-issues.md; fixed in the runner post-0.13, decided
   2026-11-23 (D6)): the runs of 2026-11-22 are not made again, so
   step 3's counts (large-subset-environment.md, section 12; README's
   "How close") still take 31 control snippets as alike, and the
   variants fail and output did not vary 58 and 59 snippets; the next
   make corpus-all runs them with the stand-ins (-calls).
```

<a id="my-b-the-large-subset-under"></a>

```text
 - The large subset under Wine (pspawn-shell-windows.md, section 2) was
   run with post-0.12 against the Linux runs of 2026-11-17: run it again
   with post-0.13 against those of 2026-11-22 when Wine is set up.
```

<a id="my-b-the-documents-places-the"></a>

```text
 - The documents, places the rewrite of 2026-11-18 could not make clear
   from the records (each kept as written): test-pools.md, "two calls
   more, of timeouts"; shell-subset-spec.md, the "Go" items undefined;
   pspawn-known-issues.md (read by fresh readers 2026-11-18/19; left):
   X11's "Run's wraparound" and its claude/ path (also pspawn-design.md
   section 1), U1-U5's three counts for "two test files", D2's "< f"
   rejected on purpose, X13, X14's two stress tests (heap corruption,
   segmentation faults: the same or not); pspawn-spawner.md, "all 234
   command lines" of 2026-11-02 (the batteries listed sum to 278; 234
   is all but t2.txt: which were compared is not recorded), the 4 of
   Perl's 64 children's places taken under Wine (60 ran at once); pspawn-shell-windows.md section 2, "the 23 others"
   not adding up; large-subset-spec.md, the source of 1,185, "ShellCheck
   clean / warned", two different P1; large-subset-match-raw.md, "4 A5";
   large-subset-state.md (read by fresh readers 2026-11-18; what the
   records no longer settle, all in the run history of section 7): 1,050
   + 9 vs 1,055 (IP1, also in Changes), "as neither" 150/151 between the
   runs of 2026-11-13 to 11-15, which shell came out otherwise for zenity
   on 2026-11-16 (dash, or bash), the class of the race { echo foo; cat
   bar; } | tee bar and the run where ls -lR timed out (2026-11-14 or
   11-15), 650 to 653 calls (the direction of "fewer"), 24,491 calls
   "106 fewer" (109 against 24,600); large-subset-
   environment.md (its own places resolved 2026-11-18 by the reading
   test), NB:6259's orders, 16, 16 and 14 against the known list's 17, 16
   and 20 (which round each is of is not recorded).  Also: the per-test record
   under Wine (doc/test-results/wine-flavors-by-test.txt) is of post-0.12:
   record it again (Linux's was, post-0.13, 2026-11-20), with t/options.t,
   which passes there too: a seventh Windows test file for the records
   and for README.md's "Where the tests ran".
```

<a id="my-b-the-large-subset-under-2"></a>

```text
 - The large subset under Wine (pspawn-shell-windows.md): run it all
   again with the setup of 2026-11-21 (runwine.pl -noenv, -setenv,
   -bridge-drop, -bridge-env-path, -winreal: Git for Windows' programs;
   rerun-s2.sh, rerun-s1pg.sh in Proc-Spawner-results), so far used for
   87 snippets only; give the Windows runner a limit on the size of
   output files, as the Linux runner has (row (s1)).  Under Wine MSYS2's
   fork does not work (Git's xargs hangs, find -exec fails): for xargs
   and find keep the Linux programs behind the stand-ins.
```

<a id="my-b-x77-pspawn-known-issues-md-found-2026-11-19"></a>

```text
 - X77 (pspawn-known-issues.md; found 2026-11-19; ours): BIN1's search
   on Windows (win_posix_bin) reads grep defined, @ENV{qw(ProgramFiles
   ProgramW6432)}, which creates the unset ones in %ENV as undef: children
   get them empty, with warnings.  Fix: map $ENV{$_} instead of the slice,
   and a test that %ENV keeps its keys.
```

<a id="my-b-x79-pspawn-known-issues-md-found-2026-11-21"></a>

```text
 - X79 (pspawn-known-issues.md; found 2026-11-21; ours, the runner): a
   snippet can change or remove its own run's record (log, blog, out, err
   in BASE/wK, owned by rcK).  Fix: the record where rcK cannot write;
   then make corpus-all.
```

<a id="my-b-x71-pspawn-known-issues-md-found-2026-11-19"></a>

```text
 - X71 (pspawn-known-issues.md; found 2026-11-19; ours, a regression of
   post-0.12 in 0.13): on Windows kill -USR1 $$ (any signal Perl lacks
   there) goes to the program kill, so a trap on it never runs, against
   WS1.  The user's choice: which names count for kill ... $$ (proposal:
   those trap accepts); then a Windows-only test line.
```

<a id="my-b-x69-pspawn-known-issues-md-found-2026-11-18"></a>

```text
 - X69 (pspawn-known-issues.md; found 2026-11-18; the user, 2026-11-18:
   later): large-subset-blocks.pl
   counts a variable as set by an assignment in a function body (even if
   the function is not called before the read), in a subshell, a
   pipeline element or $( ).  A fix (the scope of subshells, the order of
   calls) changes the levels: then make corpus-all and every document's
   counts again.  Measured so far: 3 samples for the functions alone.
   The user's decision: when.
```

<a id="my-b-chance-from-every-run"></a>

```text
 - Chance from every run (the user, 2026-11-18: "the info on
   (self-)agreement should accumulate over all runs"): decide that a
   snippet's result changes from run to run from all the runs of it (base
   and base2, the environment variants, the setups of steps 2 and 3, the
   races' 20 runs, the end modes), each shell compared with itself, and use
   that one verdict both in the one run's table (its column "known chance",
   today a list of cases seen by hand) and in the match (its "chance",
   today mostly guessed from the snippet's codes: pid, time, random,
   listing).  From the run records (corpus-work/; make corpus-all rebuilds
   them in a new container), no new run needed for the first count.
```

<a id="my-b-first-in-the-next"></a>
<a id="my-f1"></a>

```text
 - FIRST IN THE NEXT CYCLE (the user, 2026-11-18: after the release, which
   is made in the configuration as tested; all found reading the code, none
   of it run; X67 and the test of closefrom done post-0.13, X68 found so;
   item 1, closefrom as closes where it alone is missing, done post-0.13):
   2. F1, the user's decision: the fork primitive (__spawn_nowait, M2) does
      nothing between fork and exec but the signal mask, as a plain spawn
      would, so setsid, pgroup => 0, tcsetpgrp, sched and cgroup are
      refused, and rlimit, sigignore, nice are flipped in the parent around
      the call (not thread-safe), though the child could do them all
      itself.  (a) keep it; (b) every setting in the child, between fork
      and exec, errors through the exec pipe; (c) (b), and a test-only
      approach keeping today's plain spawn (Claude's view).  Only the fork
      approach reaches __spawn_nowait; its other paths (emulate_actions, the
      settings around the call) are reached by approach 2 and the matrix too.
   3. system1 on Linux refuses rlimit, sigignore and nice, which fork does
      (found 2026-11-18 by t/flavors-outcomes.pl: 6 tests skipped, and 2
      of win_priority): their wrappers in C (M1, around_begin and
      around_end in Spawner.xs) are called around posix_spawn and fork,
      not around Run's start.  Calling them there too would make system1
      as capable (not thread-safe, as for the other two).  But (seen
      post-0.13, reading Spawner.xs): around_begin blocks every signal for
      the time the settings are changed, and the fork primitive's child
      puts the mask back before exec; Run's child would inherit it
      blocked.  So for system1 the signals stay unblocked: a signal ignored
      by sigignore that comes in that moment is lost, not delayed, and our
      handlers may run with the changed limits.  Low value too: on Linux
      system1 is a test approach only.
```

<a id="my-b-w6-and-w7-post-0-12"></a>

```text
 - W6 and W7 (post-0.12; doc/pspawn-spawner.md, section 8): try them with a
   real Ctrl-C and Ctrl-Break (under Wine with a pseudo-terminal, as the
   tricks topic on Wine says, or on Windows): the foreground child gets the
   Ctrl-C, a background job does not; and what Perl's kill TERM does to a
   child in Perl's group (it leads no process group).
```

<a id="my-b-win-spawn-h-and-perl-post-0-12"></a>

```text
 - win_spawn.h and Perl (post-0.12; A20): once the patch to Perl exists,
   use Perl's posix_spawn where Perl has it (by its %Config entry) and keep
   win_spawn.h for older Perls; section 5 of doc/perl-win32-system-bugs.md
   then becomes per Perl version.  Where Perl has system(1, LIST) without
   fork, M2's fallback (system1, through Run) can use it.  Until then,
   after any change to win_spawn.h tell the user, so that Perl's copy
   follows (the interface and names there are not settled).
```

<a id="my-b-the-parser-s-work-list"></a>

```text
 - The parser's work list (large-subset-state.md, section 4, 44 samples):
   the real gaps alias :=, export ${foo?}, command -, unset -f ls /bin/ls.
```

<a id="my-b-x76-cd-with-oldpwd"></a>

```text
 - X76: cd with OLDPWD or PWD read-only ends the shell (both shells go on).
```

<a id="my-b-x1-s-rest-k5-post-0-12"></a>

```text
 - X1's rest (K5, post-0.12: at exit ShellSpawn waits only while it has
   something left to start for a job, then leaves the running processes,
   as the shells do; PROC_SHELLSPAWN_END): a job whose next command ShellSpawn
   still has to start keeps ShellSpawn from exiting until then (the shells leave
   a copy of themselves for it).  To exit at once as they do, ShellSpawn would
   run such a job in a Perl process of its own from the start (sh as Perl,
   SH1), handing it the state it needs (variables, functions, $1..., the
   options, the open descriptors); on Linux only the parent gets a child's
   status, so taking a job over at exit is not possible; on Windows a
   helper could take over the job's process handles (DuplicateHandle).
```

<a id="my-b-the-choices-now-set"></a>

```text
 - The choices now set by environment variables (PROC_SHELLSPAWN_END,
   _ECHO, _SH, _BIN, _INPROC, _ENVNAMES; PROC_SPAWNER_MISSING): a stopgap (the user,
   2026-11-15); eventually each is an argument of the API, with no action
   at a distance.
```

<a id="my-b-x9-the-virtual-directory"></a>

```text
 - X9 the virtual directory passed as a path; X15 reference cycles left in
   the shell layer; X17 messages inside eval; X24 a trap that re-sends its
   own signal.
```

<a id="my-b-settings-posix-spawn-lacks-m1"></a>

```text
 - Settings posix_spawn lacks (M1, M2; pspawn-spawner.md, section 8): a
   helper program that sets in the child what cannot be done around the
   call (setsid, pgroup 0, tcsetpgrp, sched, cgroup).
```

<a id="my-b-windows-doc-pspawn-shell-windows-md-kill-of"></a>

```text
 - Windows (doc/pspawn-shell-windows.md): kill of another process and time
   (X21's rest); ulimit; a test on real Windows.  (The snippet library under Wine
   ran on 2026-11-18/19, all 40,410 snippets through both primitives,
   against the run on Linux: doc/pspawn-shell-windows.md, "The large
   subset under Wine".)  Of the
   user's follow-ups to WS1 (2026-11-09) one remains: cat, sort, grep and
   the like have so far only BIN1, a temporary workaround (the user,
   2026-11-10; PROC_SHELLSPAWN_BIN, else Git for Windows' or MSYS2's
   programs; doc/pspawn-shell-windows.md): what replaces it is open.
```

<a id="my-b-x10-only-linux-is"></a>

```text
 - X10: only Linux is tested (and Windows under Wine).
```

<a id="my-b-through-run-large-subset-state-md-section"></a>

```text
 - "Through Run" (large-subset-state.md, section 7) was run before IP1,
   with the coreutils programs; the table itself is rebuilt for 0.10's
   in-process default, and W5 checked over it on Linux (2026-11-09: no
   change).
```

<a id="my-b-x32-without-proc-perl-s"></a>

```text
 - X32: without /proc, Perl's own writes into a pipe the caller gave can
   block if a child fills the pipe between select and the write (possible,
   not observed; no test yet).
```

<a id="my-b-messages-section-11-of"></a>

```text
 - Messages: section 11 of large-subset-environment.md counts them nowhere
   (post-0.11), section 7 of large-subset-state.md and README.md's run table
   still count a message on standard output or in a file as a difference.
   Bring section 7 in line: large-subset-runreport.pl as matchreport.pl
   (drop the shells' message lines from standard output; files by
   files_nomsg, which needs a new full run); then make docs-check.
```

<a id="my-b-large-subset-difffuzz-pl-what-is-left"></a>

```text
 - large-subset-difffuzz.pl, what is left after seed 3 (-j 4, two hours,
   315,187 strings, 285,676 accepted; it found X50 and X51): of the 826
   where dash and bash agree and ShellSpawn not, 683 have a background job's
   EXIT trap (its output comes after the shell ended, or not at all:
   chance), 119 other strings with & (X2's effects: wait $! gives 0 for a
   job started without a process), 24 without & (X50 and X51, fixed, and
   return || shift, A13); a background job that sends a signal to $$
   ends with the main shell in ShellSpawn, while in the shells it is another
   process and goes on (X2's kind).  Not looked at: the 456 where all three differ.
```

<a id="my-b-x27-step-3-the"></a>

```text
 - X27, step 3, the 93 classified by Claude reading them (A19), what each category
   takes in the setups (large-subset-setups.pl): AI-names with an
   expansion, a value the text itself sets (a for or read variable, an
   assignment: for f in */; do cd "$f"; find | while read d; do cd "$d";
   tmpdir=$(mktemp -d) && cd $tmpdir; 19): follow the value through the
   text (a glob's matches, a stand-in's answer, the fixed word); a program
   at a fixed path not on PATH (2): a stand-in placed there; $HOME/... (5):
   as ~/...; AI-tilde: users added to the run's own /etc/passwd; AI-A5:
   names with .. in the run's own root; AI-shells' own variables: OLDPWD
   varied; AI-PATH-twister: the inherited PATH varied (unset, empty, a
   missing directory); AI-glob: example names for patterns with non-ASCII,
   a / inside, system directories; AI-strict on a device: a private /dev
   with the device absent, a file, not writable.
```

## <a id="my-part-c"></a>C. WATCH (seen once, not reproduced)

<a id="my-c-x8-x13-x20"></a>

```text
 - X8, X13, X20.
```

## <a id="my-part-d"></a>D. REMINDERS (the user, 2026-11-17: "should we keep these as they are?"; mention them now and then, do not insist)

<a id="my-d-jk1-to-jk3-the"></a>

```text
 - JK1 to JK3, the decision page "Executor Idiom Review": its last three
   items (JK1: its text is on the page only).
```

<a id="my-d-jk2-the-user-2026-11-15"></a>

```text
 - JK2 (the user, 2026-11-15): the
   shell layer counts by hand who still needs each open file (hold,
   release, release_all, and $tail: the tables to release once the last
   process has started; 42 calls).  The page said this cannot be left to
   Perl, since the rule of 2026-10-30 (pspawn-design.md, section 5) is to
   forget an open file once every process that could use it has started,
   which comes before the last Perl reference goes (the code waiting for
   the child still refers to the table).  The user thinks it might be,
   with weak references: to investigate whether the waiting code could
   hold the tables weakly, so that the last strong reference goes when
   the last process has started, and what commands would then see a pipe
   closed at another moment ({ false || cat /etc/hostname; } | wc -l is
   the document's example); also X15, the reference cycles left there.
```

<a id="my-d-jk3-the-user-2026-11-15"></a>

```text
 - JK3 (the user, 2026-11-15): whether to rewrite test and [ in
   a Perlish way (Proc::ShellSpawn::Programs).  Today their eight
   functions mirror coreutils 9.4's test.c one for one (posixtest, expr,
   and, term, unary_operator, binary_operator, advance, beyond), which
   keeps the messages (')' expected, found ']') and oddities (-l STRING)
   the same; a rewrite must keep them, checked against the program.
```
