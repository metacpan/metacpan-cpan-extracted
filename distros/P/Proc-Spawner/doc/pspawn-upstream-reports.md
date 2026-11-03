# Upstream reports from the posix_spawn executor session (pspawn), 2026-11-01

## P1. ShellSubset: a setting before a command can get the wrong NAME when its value has `$( … )`

**Fixed on 2026-11-01** in the project's `ShellSubset.pm` and `ShellSubsetSmall.pm`, with tests OWN:205–207 (`claude/pspawn-parser-setting-name.patch`). Was: **❰BUG❱ in `claude/ShellSubset.pm`** (both the version of 2026-10-29 and the refactored one now in the project).

`A=$(true) B=$(false) env` parses as settings named `t` and `B`, not `A` and `B`. `x=$(echo 1; exit 6); echo "[$x] st=$?"` gives `{ set => ['e', …] }`, not `x`. Whether it happens depends on what the nested parse matches last.

The cause is in the simple-command loop (line 164 of the current file):

    elsif (!@av and /\G($NM)(\+?)=/gc) { …; push @np, $1, $p; push @env, $1, word('e') }

`$1` is passed to `push` by alias. `word('e')`, which is called while the argument list is being built, runs nested matches that change `$1` before `push` copies it.

Fix (tested; the executor's tests use it):

    elsif (!@av and /\G($NM)(\+?)=/gc) { …; my $n = $1; push @np, $n, $p; push @env, $n, word(q{e}) }

The same pattern was searched for in both parsers: the other places that pass `$1` to a function (`name($1, …)`) are safe, because `name` copies its arguments before matching.


## Module names changed (2026-11-02, 07:30), for the ShellSubsetLarge session

Not a bug: the user's decision. Every module of the bundle `claude/pspawn-tree.tar.gz-base64.txt` is now under `Proc::`, and the bundle is one distribution, built at its top with `perl Makefile.PL && make`:

| Old | New | File |
|---|---|---|
| `ShellSubset` | `Proc::ShellSubset` | `lib/Proc/ShellSubset.pm` |
| `ShellSubsetSmall` | `Proc::ShellSubset::Small` | `lib/Proc/ShellSubset/Small.pm` |
| `ShellSubsetLarge` | `Proc::ShellSubset::Large` | `lib/Proc/ShellSubset/Large.pm` |
| `ShellSpawn`, `ShellSpawn::Large` | `Proc::ShellSpawn`, `Proc::ShellSpawn::Large` | `lib/Proc/ShellSpawn.pm`, `lib/Proc/ShellSpawn/Large.pm` |
| `PosixSpawn` (binding) | part of `Proc::Spawner`; `PosixSpawn::spawn` is `Proc::Spawner::spawn` (an alias of the XSUB `__posix_spawn`), and the call with the fd table, formerly `Proc::Spawner::spawn`, is `Proc::Spawner::start` | `Spawner.xs`, `lib/Proc/Spawner.pm` |

In the bundle we renamed the package names inside your files too: `lib/Proc/ShellSubset/Large.pm`, `parser/large-subset-tests.pl`, `parser/large-subset-crosscheck.pl`, `large-subset-difffuzz.pl` (only names and include paths; tests: 0/171 unexpected, also with `-s`; the fuzzer runs). Include paths are now `lib` and `blib/arch`; the test scripts in `parser/` find `../lib` themselves. One thing left as it was, since its text is in your spec: A4's message still begins `ShellSubsetLarge: `. Please say whether it should follow the new name.
