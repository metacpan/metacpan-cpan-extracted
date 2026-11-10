# The shell layer on Windows (post-0.10)

`Proc::ShellSpawn` runs on Windows since post-0.10 (the user, 2026-11-09: "Proceed with the shell layer on
Windows"). It stands on the Windows primitive of `Proc::Spawner` ([`pspawn-spawner.md`](pspawn-spawner.md), section 8),
the loop's completion port ([`pspawn-loop.md`](pspawn-loop.md), W5) and the programs done inside Perl (X21, decision
IP1; [`pspawn-known-issues.md`](pspawn-known-issues.md)). This page says what differs from POSIX, what was checked,
and what is still missing.

## 1. What the shell does differently there

Each of these was chosen while porting; the user confirmed them on 2026-11-09 (decision **WS1**: "The remaining issues (including `pwd`) are fine"), with follow-ups in `TODO` (section B: PATH's separator from `%Config`, `~user`, `sh -c`, programs from `%ENV`).

| Where | POSIX | Windows |
|---|---|---|
| a path | absolute if it begins with `/` | absolute with a drive (`C:/x`, `C:\x`) or as a UNC name (`//server/share` or `\\server\share`); `/x` (or `\x`) has no drive: it is `x` at the root of the drive of the shell's directory (with the shell in `C:/a/b`, `/x` is `C:/x`), or of its share (with the shell in `//server/share/a`, `/x` is `//server/share/x`), as Windows itself reads it; `\` separates as `/` does; the shell's own directory keeps Perl's form (`C:/x/y`), so `pwd` and `$PWD` show it so |
| finding a command | `PATH` split at `$Config{path_sep}` (`:`) | `PATH` split at `$Config{path_sep}` (`;`; a `"quoted;entry"` whole, an unclosed quote to the end, as Perl itself and [`win_spawn.h`](../win_spawn.h) read it); in each directory the extensions of `PATHEXT` first, then the name as it is; a name with a directory gets `PATHEXT`'s extensions too |
| a file that cannot run | `Permission denied`, 126 (from `exec`) | the same text and status for a directory or a file without an executable extension (`CreateProcess` would say "not found" or "Exec format error") |
| `/dev/null` in a redirection | itself | `NUL` |
| a script without `#!` | run by `/bin/sh` | not found (there is no `sh`) |
| `umask` | set in the child | not set (Windows has none); the `umask` builtin still keeps the shell's value, which starts at Perl's (0) |
| `~` without `HOME`, `~user` | the password file | `USERPROFILE`; `~user` (post-0.10, the user's follow-up to WS1: "`%USERPROFILE%/../user`"): `USERPROFILE` for one's own name (`USERNAME`), else the sibling of `USERPROFILE` of that name if it is a directory, else as written (no user database; profiles are usually siblings, but a domain profile may be `user.DOMAIN`, and the registry's ProfileList has the real paths) |
| `$PPID` | `getppid` | the parent's process ID from `NtQueryInformationProcess` (Perl's `getppid` is unimplemented there) |
| a pattern from an expansion with `\` | `\` quotes the next character | File::Glob's rule there: `\` quotes only before a glob character or another `\`; elsewhere it separates directories |
| `trap` on a signal Perl lacks there (`USR1`, ...) | – | recorded; only `kill ... $$` sends it; a signal number Windows does not have is outside the subset (the parser takes Perl's signal table) |
| a program inside Perl writing into a closed pipe | death by SIGPIPE, `$?` 141 | the same 141, though Windows has no SIGPIPE (the same answers on every platform) |
| background jobs between `run()` calls | moved on by a deferred SIGCHLD handler | moved on only at the next `run()`, `wait` or `poll` (no SIGCHLD) |
| `ulimit` | reads the limits | not supported (status 248, as other unsupported forms) |
| `cat`, `sort`, `grep` and the like | the programs on `PATH` | (post-0.10, **BIN1**, the user's follow-up to WS1: "Replace them from `%ENV` (inventing suitable fallbacks)", **a temporary workaround**, the user, 2026-11-10) the directories in `PROC_SHELLSPAWN_BIN` (split as `PATH`; `none`: none, since Windows has no empty variables; also on POSIX) are searched before `PATH`; unset: the first of Git for Windows' `usr\bin` (beside `git.exe` on `PATH`, or under `%ProgramFiles%`, `%ProgramW6432%`, `%LOCALAPPDATA%\Programs`), MSYS2's (`%SystemDrive%\msys64\usr\bin`), Cygwin's (`%SystemDrive%\cygwin64\bin`) that has `cat.exe`. Windows' own `sort`, `find`, `timeout`, `expand` (under `%SystemRoot%`) are never taken for the POSIX ones: they are other programs. Not read from the registry. `@Proc::ShellSpawn::BIN` at run time. A `sh` found there is a program `sh` for SH1's `auto` |
| a command `sh` (`sh -c TEXT [NAME ARGS]`, `sh FILE`, `sh -s`) | the program `sh` | (post-0.10, **SH1**, the user's follow-up to WS1: "Should not `sh -c` just call Perl with our module, then? (Configurable)") Perl with this module: `$^X -MPARSER -MProc::ShellSpawn=sh -e0 -- ARGS`, with this Perl's `@INC` and the largest parser loaded here; it reads `-c`, `-s`, a file or stdin, and other option letters as `set` does (`-e`, `-u`, `-x`, ...). `PROC_SHELLSPAWN_SH` (or `$Proc::ShellSpawn::SH`): `auto` (the default: when the command's `PATH` has no `sh`, so on Windows unless Git for Windows or MSYS2 put one there; on POSIX nothing changes), `perl` (always), `program` (never). On Linux the same as dash on 10 strings, apart from dash's line number in its messages (P2). The text after `-c` is an argument: through `system1`, Perl drops every `"` of an argument, and splits one that has blanks too (checked under Wine: `'echo "$0|$1|$#"'` arrives as `'echo'`, `'$0|$1|$#'`; `'echo"$0"'` as `'echo$0'`; [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md), 1; not worked around) |

The programs inside Perl (`echo`, `printf`, `test`, `[`, `true`, `false`, and since post-0.10 `pwd`: IP1 extended, the user confirmed it on 2026-11-09) are the same
code on both platforms; `pwd` runs as `pwd -L` with the shell's directory (X23), so it prints `C:/...` there.

## 2. What was checked

| How | Result |
|---|---|
| [`t/portable.t`](../t/portable.t): the 223 lines of the batteries (`t/batteries/`) that need no program but `perl` and print the same on Linux whatever the directory, `HOME` (also unset) and umask, against what ours printed for them on Linux ([`t/batteries/portable.txt`](../t/batteries/portable.txt)) | under Wine with Strawberry Perl 5.38.2: all 223 the same, through both primitives (`win_spawn.h`, and Perl's own spawn through Run); on Linux too (`PORTABLE_TESTING=1`) |
| the 304 battery lines that need only `perl`, before the filter for machine-dependent lines | 281 the same; the 23 others: the drive in paths (6), `HOME` unset in Wine's environment (3), `ulimit` (3), `umask` starting at 0 (2), signals 10 and 12, `~root`, `/usr` on the current drive, the exit status of `t/try.pl` for a string outside the subset (6; now 255 everywhere), the `\` rule of File::Glob (1) |
| `perl Makefile.PL`, `gmake`, `gmake test` of `t/loop.t`, `t/windows.t`, `t/parsers.t`, `t/programs.t`, `t/portable.t` with Strawberry Perl's own gcc, under Wine | pass |
| [`t/portable.t`](../t/portable.t), Windows only (post-0.10): 19 lines with paths of Windows' own, output written by hand: `cd` to a UNC name with backslashes and with slashes, `..` in it and stopping at the share, a relative `cd` and `test -d` under it, `\x` from it (the root of the share), a child started in it; and `~user` (3 lines: one's own name, `~Public`, a name with no profile and `~..`); `sh` as Perl (4 lines: `-c`, `-s`, nested, `-c TEXT NAME ARGS`: the last TODO through `system1`, Perl's argv bug); BIN1 (5 lines, the stand-in for `cat.exe` a copy of `whoami.exe`: `PROC_SHELLSPAWN_BIN`, Git's `usr\bin` under `%LOCALAPPDATA%\Programs` and beside `git.exe` on `PATH`, `none`, `find.exe` not taken; `%ProgramFiles%` untested: Wine sets it afresh in every process). Wine has no server shares: its device names `\\.\C:\...` are UNC names in form (server `.`, share `C:`) | under Wine: pass, through both primitives. Found by them (ours, not released): `\x` from a UNC directory was taken from the process's own drive; `pwd` at the root of `\\.\C:` printed nothing (the server `.` taken for a `.` component) |
| Linux: the whole suite, also through Run (`PROC_SPAWNER_MISSING="posix_spawn fork"`) | pass |

Not checked: real Windows; a command through `PATHEXT`'s `.bat`, `.cmd` (Wine's `cmd.exe` quotes differently, see
[`perl-win32-system-bugs.md`](perl-win32-system-bugs.md)); Ctrl-C reaching children while the shell waits.

## 3. Still missing there

- `kill` of another process and `time`: programs on POSIX (X21's rest), not found on Windows.
- `ulimit`.
- `cat`, `sort`, `grep` and the like: only a **temporary workaround** so far (BIN1, above; what replaces it is open).
