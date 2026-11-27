# Where dash and bash differ: the logical choices (rule E)

The user decided rule E on 2026-11-03; it first shipped in 0.04. This document records it and every choice made under it.

Below, *the subset* means the large parser, `Proc::ShellSubset::Large`, together with the module that runs its trees, `Proc::ShellSpawn`.

## <a id="my-section-1"></a>1. The rule

Two rules of the user bind the subset to the shells, and only these two:

- **R-agree**: where dash and bash agree, the subset behaves as they do.
- **R-refuse**: where both refuse a form, the subset refuses it too.

**Rule E** (the user, 2026-11-03) covers what these two leave open: where the shells differ, the subset takes the behaviour that is plainly the logical one, and rejects the form only where neither behaviour is. Rule E replaced rule A3 of [`large-subset-spec.md`](large-subset-spec.md) (reject every difference until it is decided) and, for these differences, R-blatant of [`large-subset-state.md`](large-subset-state.md) (which sorts them into blatant and subtle, both kept out of the lower yardstick).

What is "plainly logical" is decided by one of the categories of [section 2](#my-section-2). Every choice names its category, so that a reader can check it.

What rule E does not cover:

- It covers only forms that both shells parse and run. **Bash-only syntax and builtins** are outside it: the group H1–H14 of the page "Shell Dialect Choices" (in Proc-Spawner 0.03), such as `[[ ]]`, arrays, `${x/a/b}`, `source`, and the options of `read` that dash lacks. There dash fails, so "the logical behaviour" would mean adding a bash feature. These forms stay rejected unless the user asks for one.
- The commands the subset runs as programs (rule R-program: `echo`, `printf`, `test`, `[`, `kill`, `time`, `pwd`, `true`, `false`) are not affected either.

## <a id="my-section-2"></a>2. The categories

| Category | What makes one behaviour plainly logical |
|---|---|
| **info** | The information exists, and one shell reports it while the other reports nothing (an empty answer that hides a real state). |
| **error** | A misuse: one shell reports it as an error with a non-zero status, the other ignores it or succeeds silently. |
| **posix** | POSIX specifies one of the two behaviours (the section is cited). |
| **same** | One shell treats the form like the simpler form next to it (`${@#p}` removing the pattern from each parameter, as `"$@"` itself gives one word per parameter); the other gives it a different meaning. |
| **harm** | One reading is a well-known trap that damages files (`rm -r .*` reaching `..`). |
| **platform** | The system's own functions read it as one shell does (glibc's `fnmatch(3)` and `glob(3)`). |
| **meaning** | An exit status keeps its conventional meaning (127: command not found; 2: misuse or error). |
| **effect** | Only one reading gives the written text any effect (the other makes it a no-op). |
| **none** | No plainly logical choice: each behaviour is consistent in its own way. The form stays rejected, or an earlier decision stands. |

## <a id="my-section-3"></a>3. The list

The columns of the table:

- **Item**: where the difference was put to the user.
  - "DC": an item of the page "Shell Dialect Choices" (`doc/checklists/dialect-choices.html` in Proc-Spawner 0.03). Every item of that page is decided in the table below, except the group H1–H14 (section 1) and R1 (after the table).
  - "CG": an item of the page "Shell Corpus Gaps" (`doc/checklists/corpus-gaps.html` in Proc-Spawner 0.04; https://claude.ai/artifact/MXuAmoBmWRkjUAiRVnYtmN, private).
  - "chat": a message (with its item number, as 1A).
- **Feature**: the name of the feature in the detector of differences, [`tools/large-subset-features.pl`](tools/large-subset-features.pl). For the rows decided under rule E and marked done, the feature's basis there is now `E:CATEGORY`, and the difference counts as class X: a difference that a program the subset runs, or a decision of the user, settles, so that it excludes no sample from the yardsticks ([section 2 of `large-subset-dialect-features.md`](large-subset-dialect-features.md#my-section-2)).
- **Category**: the category of [section 2](#my-section-2). A category in parentheses means the row is outside rule E, for the reason given.
- **Choice**: the shell whose behaviour the subset takes; "—" where there is none.
- **Status**: the state in 0.05 (the table was last brought up to date for the code labelled post-0.04, which 0.05 contains; the labels: the table at the end of [`../README.md`](../README.md); later checks are dated in their rows). SC followed by a number is a ShellCheck warning code; rule A5 ([section 4](#my-section-4)): at run time, where the shells differ, as dash. A choice not yet implemented keeps the form rejected.

| Item | Feature | The difference: dash / bash | Category | Choice | Status |
|---|---|---|---|---|---|
| chat 2026-11-03 (1A) | jobsctx | `jobs` in a pipeline or `$( )`: lists nothing / lists the shell's jobs | info | bash | done; in `( )` both list nothing, and so does the subset |
| DC G1 | localnoval | `local x` without a value: keeps the outer value / unset | none | — | rejected |
| DC G2 | dotstar | `.*` matches `.` and `..` / never | harm (also allowed by POSIX.1-2024, Austin Group bug 1228: they "may be ignored") | bash | done: patterns never match `.` or `..` |
| DC G3 | atassign | `x=$@` joined with the first character of `IFS` / with blanks | none | — | rejected |
| DC G4 | atpat | `${@#p}`, `${*%p}`: the pattern removed once from the parameters joined into one value / from each parameter | same (as `"$@"` itself, one per parameter) | bash | done in 0.05 (also ShellCheck's SC3058) |
| DC G4 | atlen | `${#@}`, `${#*}`: the length of the parameters joined into one value / the number of parameters | none | — | rejected |
| DC G5 | bqdq | `\"` in backquotes inside `"${…}"`: `q` / `"q"` | none | — | rejected |
| DC G6, CG Q3 A2 | returnout | `return` outside a function: ends quietly, status 0 / prints an error, status 2 | error | bash | done |
| CG Q3 A1 | scope | `local` outside a function: both print an error | (R-refuse: both fail) | — | rejected |
| DC G7 | — | `unset` of a variable a calling function made `local`: unset / the outer value shows again | none | — | rejected |
| DC G8, CG Q3 B | dashflags | `echo "[$-]"`: `[]` / `[hBc]` | none (each lists its options as it sees them; dash shows none for `-c`) | — | rejected |
| DC G8, CG Q3 C | lineno | `$LINENO` in `sh -c`: empty / the line number | info | bash | done in 0.05: the line where the command starts, also in function bodies and `.` files; in `eval` text and trap actions it stays rejected (bash numbers those lines from the line of the `eval`, which is not plainly logical) |
| DC G9 | trace | `set -x`: `+ echo a b` / `+ echo 'a b'` | none (trace output is read by people) | — | rejected |
| DC G10 | listing | listings of `set`, `export -p`, `trap`: formats differ | none | — | rejected; item B3 of "Shell Corpus Gaps" lists jobs and aliases in dash's format |
| DC G11 | — | `type f` for a function: `f is a shell function` / `f is a function`, then its body | none | dash (item B3 of "Shell Corpus Gaps") | done in 0.03 |
| DC G12 | fdmulti, SC3023 | `echo hi 10>/dev/null`: `10` is an argument of `echo` / descriptor 10 is redirected | posix (XCU 2.10.1: an all-digit word right before `<` or `>` is a descriptor number) | bash | done: the option `fdmulti`, off by default before 0.04, is now on by default (`fdmulti => 0` rejects again) |
| DC G13 | — | `x >&2>f` and `echo hi >&f`: a syntax error / works | (dash refuses to parse it) | — | rejected |
| DC G14 | caret, SC3026 | `[^a]` in a pattern: a literal `^` / negation, like `[!a]` | platform (glibc's `fnmatch(3)` and `glob(3)` read it as negation unless `POSIXLY_CORRECT` is set; regular expressions too) | bash | done: `[^…]` is read as `[!…]` |
| DC G15 | uidassign | `UID=5 cmd`: an ordinary variable / `UID: readonly variable` | posix (`UID` is not among the variables of XCU 2.5.3) | dash | done in 0.05; `$UID` may then be read too, where the snippet sets it; elsewhere reading `$UID` stays rejected (bash sets it: `uidread`) |
| DC G15 | ps1 | reading `$PS1` in `sh -c`: differs | none | — | rejected |
| DC G16 | nohome | `~` with `HOME` unset: a literal `~`, a directory that does not exist / the home from the password file | info | bash | done in 0.05 (and `HOME` may now be set and unset; `HOME=""`: `~` expands to nothing in both, and then dash drops the word where bash keeps an empty word: A12, pending) |
| DC G17 | fnreserved | a function named `local` (or `source`): a syntax error / works | (dash refuses to parse it) | — | rejected |
| DC G18 | — | `read -p PROMPT`: the same in both | (R-agree) | — | done in 0.04 (item P6 of "Shell Corpus Gaps") |
| DC K1–K3 | time, echoopt, jobspec | `time`, `echo`, `kill %1` | (decided earlier: the programs) | — | unchanged |
| DC N1 | specialerr | an error in a special builtin (`shift 3`): the shell exits / goes on | posix (XCU 2.8.1: a special built-in utility error exits a non-interactive shell) | dash | done (rule A5) |
| DC N2 | qmark | `${x:?}` with `x` unset: status 2 / 127 | meaning (127 means "not found") | dash | done (rule A5) |
| DC N3 | cmdv | `command -v nosuch`: status 127 / 1 | none (both mean "no"; POSIX asks only for more than 0) | dash (rule A5 stands) | done |
| DC N4 | — | `cd` with `HOME` unset: stays, status 0 / `cd: HOME not set`, status 1 | error | bash | done |
| DC N5 (L7) | — | `getopts` called again after the end: starts over / does not | none | dash (rule A5 stands) | done |
| DC N5 (L8) | getopts | `OPTARG` after the end, or after an option without an argument: kept, or empty / unset | posix (`getopts`: "If no option was found, or if the option that was found does not have an option-argument, OPTARG shall be unset") | bash | done |
| CG Q3 D | assignredir | `x=$(cmd) 2>/dev/null`: redirects first, so `cmd`'s messages go to `/dev/null` / expands first | effect (POSIX leaves the order open; with bash's order and no command, the redirection does nothing but create or truncate the file) | dash | done: the values are expanded with the redirections in force |
| — | cdargs | `cd a b`: ignores `b` / `cd: too many arguments`, status 1 | error | bash | done |
| — | — | `for v in …; do (cd "$v" \|\| continue; echo x) done`: `continue` ends the subshell, so `echo x` is skipped / `continue` does nothing there, and `echo x` runs | effect | dash | done in 0.05 (status 0; also in `$( )` and in a pipeline element) |
| — | — | `break` in a subshell inside a loop: the same difference as `continue` above | effect (as `continue`; Claude's extension in 0.05, not decided by the user: not on any page) | dash | done in 0.05 |
| — | — | a here-document cut off at the end of the snippet: an empty body, silently / the same, with a warning on standard error | none | — | rejected |
| — | — | a trap action that sends its own signal again (`trap 'kill -INT $$' INT; kill -INT $$`, known issue [X24](../pspawn-known-issues.md#my-x24)): dash and bash both crash (segmentation fault, status 139; checked post-0.13 with the default 8 MB stack) | (not a difference: both fail, so R-refuse would reject it, but the parser cannot see it) | — | open (X24) |
| CG Q2 | sc3045-printf-v | `printf -v x %s hi`: an illegal option / sets `x` | (a bash-only option; R-program: the program `printf` runs) | — | unchanged: the program runs (Q2 decided, the user's choice B, 2026-11-03) |

## <a id="my-section-4"></a>4. Earlier decisions checked against rule E

- R1 of "Shell Dialect Choices" (rule A3: reject every difference until it is decided on that page) is replaced by rule E. The page had no marks; its items stood at their defaults (A: reject) and are now decided by the list above.
- K1–K3 (programs for `time`, `echo`, `kill %1`) and R-program stand; rule E does not touch them.
- N1–N5 (rule A5: as dash at run time) stand, except N4 (now as bash: category error) and the `OPTARG` part of N5 (now as bash: category posix).
- Q1 of "Shell Corpus Gaps" (`kill -SIGHUP` rejected: both shells refuse) is R-refuse, not rule E; it stands (R-refuse beats R-program: the user, Q1, "refusing is better"). So does the rejection of `pwd -x`.
- B3 of "Shell Corpus Gaps" (`jobs`, `type`, … with dash's texts) stands for the formats; rule E only adds that `jobs` lists the jobs in a pipeline and in `$( )`. Since 0.05 `jobs` also takes `%N`, `%%`, `%+`, `%-` (both shells do), with dash's message for a job that does not exist (status 2; bash: status 1).
- 3A (the user, 2026-11-03, not rule E: both shells agree): a function comes before a regular builtin of its name and before the commands run as programs (POSIX order: only special builtins come first). So functions may be named `cd`, `read`, `jobs`, `echo`, `kill`, …; not `alias` or `unalias`, whose calls must be known at parse time (aliases, B1).

### <a id="my-where-to-look-up-a-difference"></a>Where to look up a difference

- This list, by item.
- [`large-subset-dialect-features.md`](large-subset-dialect-features.md): every probed feature, with its probe and verdict.
- [`tools/large-subset-features.pl`](tools/large-subset-features.pl): the detector, each feature with its verdict and basis.
- [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt): the verdicts kept by hand.
