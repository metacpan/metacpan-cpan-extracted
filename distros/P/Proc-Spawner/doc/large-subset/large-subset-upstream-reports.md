# Reports from the ShellSubsetLarge sessions to other components (2026-11-01)

The parser bugs U1–U5 are fixed in `claude/large-subset-shellsubset.patch` (for `claude/ShellSubset.pm` and its two test files). The posix_spawn session applied it on 2026-11-01 and ported U1, U2, U4 and U5 to `claude/ShellSubsetSmall.pm` (`claude/pspawn-small-u1-u5.patch`). The executor bugs L1–L5 below were fixed by the posix_spawn session on the evening of 2026-11-01 and rechecked here; L6–L8 are open.

## U1. ShellSubset accepts strings that start with `-` or `+`; `sh -c` rejects them

**❰BUG❱** in `claude/ShellSubset.pm` and `claude/ShellSubsetSmall.pm`. Fixed in the patch (test OWN:208–210).

Perl hands a string with metacharacters to `/bin/sh` as `sh -c STRING`, with no `--` before it, after skipping white space at its start. A string whose first other character is `-` or `+` is then read by sh as more options, and sh fails before running anything:

```
$ perl -e 'system("-x foo; true"); print "$?\n"'
sh: 0: Illegal option -
512
```

The same for `" -x foo; true"`, `"\t+x foo; true"` and `"\n-x foo; true"` (checked: 512 each; `bash --posix` fails too). ShellSubset accepted them as a command named `-x`, so an executor would run `-x` and `true` and return 0. Fix: reject a string whose first character other than white space is `-` or `+`.

## U2. A pattern that can match `.` or `..`

**❰BUG❱** in both parsers. Fixed in the patch (OWN:211–216). `ls -d .*` lists `.` and `..` in dash 0.5.12, not in bash 5.2 (`globskipdots`). Both parsers accepted it. Fix: reject a pattern whose file name component starts with a written `.` and can match `.` or `..` (`.*`, `.?`, `"."*`, `x/.*`, `.[!]]*`); `.*perf.*`, `.[!.]*`, `./*` stay accepted. The first version of this fix crashed on `echo .a[]` (a regex built from the bracket expression); the cold review found it, and the check no longer builds a regex from user text.

## U3. `\"` in backquotes inside a double-quoted `${…}`

**❰BUG❱** in `claude/ShellSubset.pm` (option `param_ops`). Fixed in the patch (OWN:218–219). `` echo "${x:-`echo \"q\"`}" `` prints `q` in dash and `"q"` in bash. Fix: reject `\"` inside backquotes there.

## U4. Digits directly before a redirection operator in a redirection target

**❰BUG❱** in both parsers. Fixed in the patch (OWN:220–222). `x >&2>f`, `x >1>f`, `x <&0<f`: dash reads the digits as the descriptor of the next redirection and reports "redirection unexpected"; bash accepts some of them. Both parsers accepted them. Fix: reject a target of digits followed directly by `<` or `>`.

## U5. Settings with names the shell sets itself

**❰BUG❱** in both parsers. Fixed in the patch (OWN:217). `UID=5 echo hi` runs `echo` in dash; bash fails ("UID: readonly variable"). The parsers checked these names in expansions and in assignment-only commands, not in settings before a command. Fix: check them there too (`IFS` stays allowed, for `IFS= read`).

## For ShellSpawn (the posix_spawn executor, `claude/pspawn-ShellSpawn.pm`)

Not bugs: what the executor must add before it can run `ShellSubsetLarge` trees. The full rules are in `claude/large-subset-spec.md`, sections 4 and 5.

- New nodes: `{ func => NAME, body => Command }` (define; a call looks up functions before builtins and programs; positional parameters per call; `return`); `{ export | readonly | local => [NAME, Word or undef, ...] }`; `{ exec => 1, redir => [...] }` (applies the redirections to the shell for the rest of the string); `exec => 1` anywhere (run, then end the shell or subshell).
- `argv->[0]` may be a Word: expand it, then look the first field up as a function, a builtin of the module, a builtin left to sh (stop with status 2, A4), or a program.
- Here-documents `[fd, '<<', Word]`: expand the Word without splitting or patterns and feed it to fd.
- Parameters: `$0` (`sh`), `$1`…, `$#`, `$@`, `$*`, `$$`; `${N := = :? ? % %% # ##}`; `["'", text]` Parts (quoted text in an unquoted `${N:-w}`: not split).
- Builtins: `set` (`-e -u -f -C -a`, `--`), `shift`, `eval` and `.` (parse with `ShellSubsetLarge::parse`; on rejection stop with status 2), `trap`, `wait`, `umask`, `command`, `getopts`, `unset`, `cd -`.
- `$((…))` with assignments.
- Run-time rules A4 and A5 (stop with status 2 where something unsupported shows up; follow dash where the shells differ at run time); `kill … $$` handled by the shell itself.

## Executor bugs found by differential fuzzing (2026-11-01, evening; L1–L5 fixed the same evening)

`claude/large-subset-difffuzz.pl` builds random strings from about 80 snippets of the large subset, runs each under dash 0.5.12 and under the executor of the bundle `claude/pspawn-tree.tar.gz-base64.txt` (`try.pl`, with the project's parsers), in an empty directory, and compares output, messages and status. 2,100 strings in 7 runs; besides differences only in the order of lines from parallel pipeline elements (expected, X13), these remain. Each was then reduced to the example given. All are in `lib/ShellSpawn.pm` (the core, section 3 of `claude/pspawn-extensions.md`).

| ID | What | Example | dash | executor |
|---|---|---|---|---|
| L1 | **❰BUG❱** `"$@"` with no positional parameters gives one empty field instead of none. | `for i in "$@"; do echo "<$i>"; done` | (nothing) | `<>` |
| | | `set --; echo "[$@]" "$@" x` | `[] x` | `[]  x` |
| L2 | **❰BUG❱** Field splitting of unquoted expansions ignores `IFS`; it always splits at blanks (line 363: `split /[ \t\n]+/`). `IFS` was not assignable in the small subset; it is in the large one. `"$*"` and `read` already use `IFS`. | `x=a:b; IFS=:; for i in $x; do echo $i; done` | `a`, `b` | `a:b` |
| | | `IFS=; x="a b"; set -- $x; echo $#` | `1` | `2` |
| L3 | **❰BUG❱** `OPTIND` is not set to 1 at the start. | `echo "$OPTIND"` | `1` | (empty) |
| L4 | **❰BUG❱** `set -u` does not apply to `${x%p}`, `${x%%p}`, `${x#p}`, `${x##p}` (it does to `$x` and `${#x}`). | `set -u; echo ${x%a}; echo after` | `x: parameter not set`, status 2 | empty line, `after` |
| L5 | **❰BUG❱** An EXIT trap of a background job, or of a pipeline element, that has already started a program runs after the job's descriptors were released: its commands fail. | `{ trap "echo T" EXIT; true; } & wait` | `T` | `sh: 3: Bad file descriptor` |
| | | `(trap "echo T" EXIT; sleep 0) \| cat` | `T` | `sh: 6: Bad file descriptor` |

L5's probable cause (not checked in the code): the rule "release the contexts right after the last process the construct can start has started" (`claude/pspawn-design.md`, section 5) does not count the processes an EXIT trap can still start. Without a program before the end of the job, the trap works (`trap "echo T" EXIT & wait` prints `T`).

Also seen, and already known: `shift 2 || sleep 0 & wait $!; echo $?` gives 2 in dash, 0 in the executor, because `$!` is empty when the job starts no process before the `&` returns (X2).

## Second round (2026-11-01, 20:00), against the executor version with L1–L5 fixed

L1–L5 rechecked with the examples above: all agree with dash now, as do five more `IFS` cases (`IFS=": "` with empty fields, leading and trailing `:`, `IFS=` then `unset IFS`, `"$*"` with `IFS=:`). `largebattery.txt` 99/103, parser tests 146/0, 222/0, 612/0, and `PARSER=small|base|large` select the grammar as described.

`large-subset-difffuzz.pl` now has about 110 snippets (functions inside functions, `eval` defining a function, `for NAME` without `in`, here-documents in functions, `IFS` variants, `set -u` with `${x%p}`, EXIT traps in jobs and pipeline elements, `getopts` loops, `local` shadowing, `set -a`, `kill -INT $$` with a trap) and strips message prefixes anywhere in a line. 3,000 strings in 12 runs, 2,651 in the subset, 29 differ. Besides line order (X13) and X2, these remain:

| ID | What | Example | dash | bash | executor |
|---|---|---|---|---|---|
| L6 | **❰BUG❱** `kill … $$` in a subshell or a pipeline element ignores the trap that the main shell set for that signal, and ends the whole string. In sh, `$$` is the main shell, which gets the signal and runs its trap. (Without a trap, all three end with 128+N.) | `trap "echo int" INT; (kill -INT $$); echo after` | `int`, `after`, 0 | `int`, `after`, 0 | 130, nothing printed |
| | | `trap "echo int" INT; kill -INT $$ \| cat; echo after` | same | same | same as above |
| L7 | **❰BUG❱** (minor) `getopts` with new arguments after an earlier `getopts` loop ran to its end. dash starts over; bash returns 1 and sets `OPTIND` to 3; the executor matches neither. By A5, follow dash. | `while getopts ab: o -a -b v; do :; done; getopts ab: o -b v; echo $? $o $OPTIND` | `0 b 3` | `1 ? 3` | `1 ? 4` |
| M1 | (cosmetic) An error inside a builtin lacks dash's builtin-name prefix. | `readonly r=1; readonly r=2` | `readonly: r: is read only` | | `r: is read only` |
| | | `set -u; eval 'echo $x'` | `eval: x: parameter not set` | | `x: parameter not set` |

Three more differences were X2 (`$!` empty when the job starts no process): `set -u; echo ${zz%a} && sleep 0 & wait $!`, `command -v nosuch && sleep 0 & wait $!`, `h && … && sleep 0 & wait $!` with `h` not found (dash 2, 127, 127; executor 0 each).

## Third round (2026-11-02)

With the parser additions of 2026-11-02 (here-documents in `"$( … )"`, `command` alone), 1,500 more strings in 6 runs, 1,281 in the subset, 10 differ: X13 line order, X2, L6 again, and one more small `getopts` difference:

| ID | What | Example | dash | bash | executor |
|---|---|---|---|---|---|
| L8 | (minor) When `getopts` finds no more options, dash leaves `OPTARG` as it was; bash and the executor unset it. By A5, follow dash. | `getopts ab: o -b v; getopts ab: o -b v; echo "[$o] [$OPTARG] $OPTIND"` | `[?] [v] 3` | `[?] [] 3` | `[?] [] 3` |

## Request to the posix_spawn session (2026-11-02): A4's status is 248

Not a bug: the user's decision on A4 (2026-11-02): "2 is too common. What about 250-2=248? (These should be documented.)" When something outside the subset shows up only at run time, the shell (or the subshell, `$( … )`, background job or pipeline element) stops with **248**, documented in `claude/large-subset-spec.md`, section 5, "Exit statuses of the module itself". The executor change is one line in `lib/ShellSpawn/Large.pm`, in `claude/large-subset-a4-status.patch` (made against the bundle of 2026-11-01 evening; tested there: `c=alias; $c ll=ls` and `eval "[[ x ]]"` both give 248 after the message). Statuses that follow dash under A5 stay dash's (2).

Also new: the page "Shell Dialect Choices" (https://claude.ai/artifact/Swk8Miwhex33LGaRjnfyTr) lists every dash/bash difference as an item; until the user chooses, all stay as A3 says (rejected; A5 at run time). Items chosen there will need executor work; each item names its cost.

## Fourth round (2026-11-02, morning), against the bundle with A4 and L6–L8 applied

Checked first: `claude/pspawn-handoff-2026-11-01.md` says A4 (status 248) and the fixes for L6–L8 are in the bundle; this round found none of L6–L8 again. The bundle's `parser/ShellSubsetLarge.pm` and `large-subset-difffuzz.pl` are older than the Project's (they lack here-documents in `"$( … )"` and `command` alone, and ~40 snippets); this round used the Project's copies. **Please refresh both in the bundle.** `large-subset-tests.pl -s`: 0 of 151 unexpected.

1,200 strings (seeds 1–4, 300 each), 1,054 in the subset, 7 differ: 5 line order (X13), and:
- X2 again, in more forms: a background job whose last step starts no process gives `wait $!` status 0. `nosuch & wait $!` (dash 127), `{ nosuch; } &` (127), `(exit 3) &` (3), `f() { return 3; }; f && true &` (3). `sh -c "exit 3" &` is right (3). Waits for the user's K4 decision.
- L9 (minor, message only): under `set -u`, an unset parameter inside `eval` is reported by dash as `eval: x: parameter not set`; the executor drops `eval: `. Status is the same (2).

## L10 (2026-11-02): blocking writes from Perl deadlock the executor

**❰BUG❱** The executor writes the output of its own builtins and its messages with a blocking `POSIX::write`: `lib/ShellSpawn.pm` line 143 (messages to fd 2) and line 529 (`cd -` printing the directory), `lib/ShellSpawn/Large.pm` line 17 (`out`: `umask`, `command -v`, …) and line 21 (A4's message). Small output does not make this safe: it may come **on top of** other output already filling the same pipe. If the pipe is full, the whole event loop stops; if Perl itself is the reader (`$( … )`), it never resumes.

| String | dash | executor |
|---|---|---|
| `x=$(head -c 10000000 /dev/zero & umask; wait); echo ${#x}` | `14` (dash drops NUL bytes) | hangs (killed by `timeout 20`) |
| the same with `echo hi` (a program) in place of `umask` | – | `10000003` |
| the same with `:` (writes nothing) | – | `10000000` |

Suggested fix: every write by Perl goes through the graph's non-blocking writes (`perl_write`), and the builtin calls its continuation only after its write is done, so a later command's output cannot overtake it. The same applies to every future builtin that prints (listing forms, `hash`, `jobs`, …).

## Request to the posix_spawn session (2026-11-02): D2, redirections without a command

Not a bug: the user's decision D2(A). `ShellSubsetLarge` now accepts redirections alone (`> file`), settings with redirections when nothing in the command holds `$` or a backquote (`x=1 >f`), and backslash-newline inside words (removed before parsing). Two new tree forms (spec section 4): `{ argv => [], redir => [...] }` and `{ set => [...], redir => [...] }`. Please apply, against the bundle of 2026-11-02:
- `claude/large-subset-d2-base.patch` (`parser/ShellSubset.pm`, one line: no warning for a command with no words);
- `claude/large-subset-d2-exec.patch` (`lib/ShellSpawn.pm`, `x_set`: redirect first, as dash; a failed redirection sets nothing, status 2);
- and refresh `parser/ShellSubsetLarge.pm`, `parser/large-subset-tests.pl` and `large-subset-difffuzz.pl` from the Project (the bundle's copies are older).
Tested in the bundle: 10 strings agree with dash (`> f`, a failing `> /nonexist/f` with and without `set -e`, `x=1 y=2 2>f >&2`, `ec\<newline>ho`, …); `largebattery.txt` 106/110 and `battery.txt` 42/43 as before; parser tests 222/0, 612/0, 165/0 (`-s`).
