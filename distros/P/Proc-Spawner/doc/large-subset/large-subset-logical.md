# Where dash and bash differ: the logical choices (rule E)

Prefix `large-subset-`. Written 2026-11-03 (0.04) on the user's decision of that day.

## 1. The rule

Where dash and bash agree, the large subset behaves as they do (rule R-agree), and where both refuse a form, it refuses it too (R-refuse). These are the user's rules, and they are the only ones that bind the subset to the shells.

**Rule E** (the user, 2026-11-03, replacing rule A3 of [`large-subset-spec.md`](large-subset-spec.md) and R-blatant of [`large-subset-state.md`](large-subset-state.md)): where the shells differ, the subset takes the behaviour that is plainly the logical one, and rejects the form only where neither is. "Plainly logical" is decided by one of the categories below; every choice names its category, so that it can be checked.

Rule E covers forms both shells parse and run. It does not cover **bash-only syntax and builtins** (the group H1–H14 of the page "Shell Dialect Choices", in Proc-Spawner 0.03: `[[ ]]`, arrays, `${x/a/b}`, `source`, options of `read` that dash lacks, and the like): there dash fails, and "the logical behaviour" would mean adding a bash feature. Those stay rejected unless the user asks for one. The commands the subset runs as programs (R-program: `echo`, `printf`, `test`, `[`, `kill`, `time`, `pwd`, `true`, `false`) are not affected either.

## 2. The categories

| Category | What makes one behaviour plainly logical |
|---|---|
| **info** | The information exists, and one shell reports it while the other reports nothing (an empty answer that hides a real state). |
| **error** | A misuse: one shell reports it as an error with a non-zero status, the other ignores it or succeeds silently. |
| **posix** | POSIX specifies one of the two behaviours (the section is cited). |
| **same** | One shell treats the form like the simpler form next to it (a descriptor `10` like a descriptor `1`); the other gives it a different meaning. |
| **harm** | One reading is a well-known trap that damages files (`rm -r .*` reaching `..`). |
| **platform** | The system's own functions read it as one shell does (glibc's `fnmatch(3)` and `glob(3)`). |
| **meaning** | An exit status keeps its conventional meaning (127: command not found; 2: misuse or error). |
| **effect** | Only one reading gives the written text any effect (the other makes it a no-op). |
| **none** | No plainly logical choice: each behaviour is consistent in its own way. The form stays rejected, or an earlier decision stands. |

## 3. The list

"Item" names where the difference was put to the user: "DC" items are on the page "Shell Dialect Choices" (`doc/checklists/dialect-choices.html` in Proc-Spawner 0.03; every item is decided in the table below), "CG" items on "Shell Corpus Gaps" (`doc/checklists/corpus-gaps.html` in Proc-Spawner 0.04; https://claude.ai/artifact/MXuAmoBmWRkjUAiRVnYtmN, private), "chat" means a message. "Feature" names the detector's feature ([`tools/large-subset-features.pl`](tools/large-subset-features.pl)); for the rows marked done its basis is now `E:CATEGORY`, and the difference counts as class X. A category in parentheses means the row is outside rule E, for the reason given. "Status" is that of post-0.04; a choice not yet implemented keeps the form rejected.

| Item | Feature | The difference: dash / bash | Category | Choice | Status |
|---|---|---|---|---|---|
| chat 2026-11-03 (1A) | jobsctx | `jobs` in a pipeline or `$( )`: lists nothing / lists the shell's jobs | info | bash | done; in `( )` both list nothing, and so does the subset |
| DC G1 | localnoval | `local x` without a value: keeps the outer value / unset | none | — | rejected |
| DC G2 | dotstar | `.*` matches `.` and `..` / never | harm (also allowed by POSIX.1-2024, Austin Group bug 1228: they "may be ignored") | bash | done: patterns never match `.` or `..` |
| DC G3 | atassign | `x=$@` joined with the first character of `IFS` / with blanks | none | — | rejected |
| DC G4 | atpat | `${@#p}`, `${*%p}`: the pattern removed once from the joined string / from each parameter | same (as `"$@"` itself, one per parameter) | bash | done in post-0.04 (also ShellCheck's SC3058) |
| DC G4 | atlen | `${#@}`, `${#*}`: the length of the joined string / the number of parameters | none | — | rejected |
| DC G5 | bqdq | `\"` in backquotes inside `"${…}"`: `q` / `"q"` | none | — | rejected |
| DC G6, CG Q3 A2 | returnout | `return` outside a function: ends quietly, status 0 / prints an error, status 2 | error | bash | done |
| CG Q3 A1 | scope | `local` outside a function: both print an error | (R-refuse: both fail) | — | rejected |
| DC G7 | — | `unset` of a variable a calling function made `local`: unset / the outer value shows again | none | — | rejected |
| DC G8, CG Q3 B | dashflags | `echo "[$-]"`: `[]` / `[hBc]` | none (both list option letters; bash adds its own) | — | rejected |
| DC G8, CG Q3 C | lineno | `$LINENO` in `sh -c`: empty / the line number | info | bash | done in post-0.04: the line where the command starts, also in function bodies and `.` files; in `eval` text and trap actions it stays rejected (bash numbers those lines from the line of the `eval`, which is not plainly logical) |
| DC G9 | trace | `set -x`: `+ echo a b` / `+ echo 'a b'` | none (trace output is read by people) | — | rejected |
| DC G10 | listing | listings of `set`, `export -p`, `trap`: formats differ | none | — | rejected; item B3 of "Shell Corpus Gaps" lists jobs and aliases in dash's format |
| DC G11 | — | `type f` for a function: `f is a shell function` / `f is a function`, then its body | none | dash (item B3 of "Shell Corpus Gaps") | done in 0.03 |
| DC G12 | fdmulti, SC3023 | `echo hi 10>/dev/null`: `10` is an argument of `echo` / descriptor 10 is redirected | posix (XCU 2.10.1: an all-digit word right before `<` or `>` is a descriptor number) | bash | done: the option `fdmulti`, off until post3-0.03, is now on by default (`fdmulti => 0` rejects again) |
| DC G13 | — | `x >&2>f` and `echo hi >&f`: a syntax error / works | (dash refuses to parse it) | — | rejected |
| DC G14 | caret, SC3026 | `[^a]` in a pattern: a literal `^` / negation, like `[!a]` | platform (glibc's `fnmatch(3)` and `glob(3)` read it as negation unless `POSIXLY_CORRECT` is set; regular expressions too) | bash | done: `[^…]` is read as `[!…]` |
| DC G15 | roassign | `UID=5 cmd`: an ordinary variable / `UID: readonly variable` | posix (`UID` is not among the variables of XCU 2.5.3) | dash | done in post-0.04 (detector: `uidassign`); `$UID` may then be read too, where the string sets it; elsewhere reading `$UID` stays rejected (bash sets it: `uidread`) |
| DC G15 | ps1 | reading `$PS1` in `sh -c`: differs | none | — | rejected |
| DC G16 | nohome | `~` with `HOME` unset: a literal `~`, a directory that does not exist / the home from the password file | info | bash | done in post-0.04 (and `HOME` may now be set and unset; `HOME=""` gives an empty `~`, as both) |
| DC G17 | fnreserved | a function named `local` (or `source`): a syntax error / works | (dash refuses to parse it) | — | rejected |
| DC G18 | — | `read -p PROMPT`: the same in both | (R-agree) | — | done in post-0.03 (item P6 of "Shell Corpus Gaps") |
| DC K1–K3 | time, echoopt, jobspec | `time`, `echo`, `kill %1` | (decided earlier: the programs) | — | unchanged |
| DC N1 | specialerr | an error in a special builtin (`shift 3`): the shell exits / goes on | posix (XCU 2.8.1: a special built-in utility error exits a non-interactive shell) | dash | done (rule A5) |
| DC N2 | qmark | `${x:?}` with `x` unset: status 2 / 127 | meaning (127 means "not found") | dash | done (rule A5) |
| DC N3 | cmdv | `command -v nosuch`: status 127 / 1 | none (both mean "no"; POSIX asks only for more than 0) | dash (rule A5 stands) | done |
| DC N4 | — | `cd` with `HOME` unset: stays, status 0 / `cd: HOME not set`, status 1 | error | bash | done |
| DC N5 (L7) | — | `getopts` called again after the end: starts over / does not | none | dash (rule A5 stands) | done |
| DC N5 (L8) | getopts | `OPTARG` after the end, or after an option without an argument: kept, or empty / unset | posix (`getopts`: "If no option was found, or if the option that was found does not have an option-argument, OPTARG shall be unset") | bash | done |
| CG Q3 D | assignredir | `x=$(cmd) 2>/dev/null`: redirects first, so `cmd`'s messages go to `/dev/null` / expands first | effect (POSIX leaves the order open; with no command, the redirection's only other effect is to create or truncate the file) | dash | done: the values are expanded with the redirections in force |
| — | cdargs | `cd a b`: ignores `b` / `cd: too many arguments`, status 1 | error | bash | done |
| — | — | `for v in …; do (cd "$v" \|\| continue; echo x) done`: `continue` ends the subshell, so `echo x` is skipped / `continue` does nothing there, and `echo x` runs | effect | dash | done in post-0.04 (status 0; also in `$( )` and in a pipeline element) |
| — | — | `break` in a subshell inside a loop: the same difference as `continue` above | effect (as `continue`; Claude's extension, post-0.04: not on any page) | dash | done in post-0.04 |
| — | — | a here-document cut off at the end of the string: an empty body, silently / the same, with a warning on standard error | none | — | rejected |
| — | — | a trap action that sends its own signal again (`trap 'kill -INT $$' INT; kill -INT $$`, known issue X24): dash crashes (segmentation fault, status 139) / bash prints nothing, status 0 | (both fail; the parser cannot see it) | — | open (X24) |
| CG Q2 | sc3045-printf-v | `printf -v x %s hi`: an illegal option / sets `x` | (a bash-only option; R-program: the program `printf` runs) | — | unchanged: the program runs (Q2 decided, the user's choice B, 2026-11-03) |

## 4. Earlier decisions checked against rule E

- R1 of "Shell Dialect Choices" (rule A3: reject every difference until it is decided on that page) is replaced by rule E. The page had no marks; its items stood at their defaults (A: reject) and are now decided by the list above.
- K1–K3 (programs for `time`, `echo`, `kill %1`) and R-program stand; rule E does not touch them.
- N1–N5 (rule A5: as dash at run time) stand, except N4 (now as bash: category error) and the `OPTARG` part of N5 (now as bash: category posix).
- Q1 of "Shell Corpus Gaps" (`kill -SIGHUP` rejected: both shells refuse) is R-refuse, not rule E; it stands. So does the rejection of `pwd -x`.
- B3 of "Shell Corpus Gaps" (`jobs`, `type`, … with dash's texts) stands for the formats; rule E only adds that `jobs` lists the jobs in a pipeline and in `$( )`. Since post-0.04 `jobs` also takes `%N`, `%%`, `%+`, `%-` (both shells do), with dash's message for a job that does not exist (status 2; bash: status 1).
- 3A (the user, 2026-11-03, not rule E: both shells agree): a function comes before a regular builtin of its name and before the commands run as programs (POSIX order: only special builtins come first). So functions may be named `cd`, `read`, `jobs`, `echo`, `kill`, …; not `alias` or `unalias`, whose calls must be known at parse time (aliases, B1).

The documents to check a difference quickly: this list (by item); [`large-subset-dialect-features.md`](large-subset-dialect-features.md) (every probed feature with its probe and verdict); [`tools/large-subset-features.pl`](tools/large-subset-features.pl) (the detector, each feature with its verdict and basis); [`tools/large-subset-verdicts.txt`](tools/large-subset-verdicts.txt) (verdicts kept by hand).
