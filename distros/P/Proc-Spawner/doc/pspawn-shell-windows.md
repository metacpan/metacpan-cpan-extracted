# The shell layer on Windows

`Proc::ShellSpawn` runs on Windows since 0.11 (the work labelled post-0.10; the user, 2026-11-09: "Proceed with the
shell layer on Windows"). There it uses:

- the Windows primitive of `Proc::Spawner` ([`pspawn-spawner.md`](pspawn-spawner.md#my-section-8), section 8);
- the event loop's I/O completion port ([`pspawn-loop.md`](pspawn-loop.md), W5);
- the programs that `Proc::ShellSpawn` runs inside Perl (`echo`, `printf`, `test`, ...: known issue [X21](pspawn-known-issues.md#my-x21), decision IP1).

This page says what differs from POSIX, what was checked, and what is still missing.

"The user" is the module's author. Names such as WS1, BIN1, SH1, IP1, A22 are the user's decisions (recorded in
[`Changes`](../Changes) and [`TODO`](../TODO.md)); post-0.10, post-0.12: the work after release 0.10 or 0.12; X followed by
a number: a known issue of [`pspawn-known-issues.md`](pspawn-known-issues.md).

## <a id="my-section-1"></a>1. What the shell does differently there

The differences of the table below were chosen while porting; rows added later name their date and decision in their
sections. The user confirmed those of the first port on 2026-11-09 (decision **WS1**, in the
user's words "The remaining issues (including `pwd`) are fine") and asked for five follow-ups:

- (a) PATH's separator from `%Config`, (b) `~user`, (c) `sh -c`, (e) UNC names with backslashes: done (the table
  below; (e) in [section 2](#my-section-2));
- (d) programs from `%ENV`: so far only BIN1, a temporary workaround for `cat`, `sort`, `grep` and the like; what
  replaces it is open in [`TODO`](../TODO.md) (section B).

| Where | POSIX | Windows |
|---|---|---|
| a path | absolute if it begins with `/` | absolute with a drive or as a UNC name; `/x` is at the root of the shell's drive or share; `\` separates as `/` does ([Paths](#my-paths), below) |
| finding a command | `PATH` split at `$Config{path_sep}` (`:`) | `PATH` split at `$Config{path_sep}` (`;`; a `"quoted;entry"` is one entry, an unclosed quote runs to the end, as Perl itself and [`win_spawn.h`](../win_spawn.h) read it); in each directory the extensions of `PATHEXT` first, then the name as it is; a name with a directory gets `PATHEXT`'s extensions too |
| a file that cannot run | `Permission denied`, 126 (from `exec`) | the same text and status for a directory or a file whose extension is not one Perl takes as executable (`.exe`, `.com`, `.bat`, `.cmd`); `CreateProcess` would say "not found" or "Exec format error" |
| `/dev/null` in a redirection | itself | `NUL` |
| a script without `#!` | run by `/bin/sh` | `Permission denied`, 126, as in the row above, with `#!` or without: Windows runs no script but `.bat` and `.cmd`, and there is no `sh` |
| `umask` | set in the child | not set (Windows has none); the `umask` builtin still keeps the shell's value, which starts at Perl's (0) |
| `~` without `HOME`, `~user` | the password file | `USERPROFILE`; for `~user` see [`~user`](#my-user), below |
| the names of inherited variables | as the environment spells them | as the environment block spells them, except `PATH` ([Variable names](#my-variable-names), below) |
| `test -ef`, and `pwd -L` (does `PWD` still name the current directory?): the same file | the same device and inode numbers | the same volume serial number and file ID ([The same file](#my-the-same-file), below) |
| `$PPID` | `getppid` | the parent's process ID from `NtQueryInformationProcess` (Perl's `getppid` is unimplemented there) |
| a pattern from an expansion with `\` | `\` quotes the next character | File::Glob's rule there: `\` quotes only before a glob character or another `\`; elsewhere it separates directories |
| `trap` on a signal Perl lacks there (`USR1`, ...) | – | recorded; only `kill ... $$` sends it (WS1). **❰BUG❱** since post-0.12 (known issue [X71](pspawn-known-issues.md#my-x71)): `kill -USR1 $$` goes to the program `kill`, which Windows does not have (`sh: kill: not found`, 127; checked under Wine, 2026-11-19), so nothing sends it; a signal number that Perl there does not have is rejected by the parser (it takes Perl's signal table) |
| a program inside Perl writing into a closed pipe | death by SIGPIPE, `$?` 141 | the same 141, although Windows has no SIGPIPE (so the answers are the same on every platform) |
| background jobs between `run()` calls | their ends collected by a deferred SIGCHLD handler | collected only at the next `run()`, `wait` or `poll` (there is no SIGCHLD) |
| `ulimit` | reads the limits | not supported (status 248, as other unsupported forms) |
| `cat`, `sort`, `grep` and the like | the programs on `PATH` (after the directories of `PROC_SHELLSPAWN_BIN`, if it is set) | first the directories of BIN1 ([`cat`, `sort`, `grep`](#my-cat-sort-grep), below) |
| a command `sh` (`sh -c TEXT [NAME ARGS]`, `sh FILE`, `sh -s`) | the program `sh` | Perl with this module, SH1 ([A command `sh`](#my-a-command-sh), below) |

The programs inside Perl (`echo`, `printf`, `test`, `[`, `true`, `false`, and since post-0.10 `pwd`: IP1 extended,
which the user confirmed on 2026-11-09) are the same code on both platforms. `pwd` runs as `pwd -L` with the shell's
directory ([X23](pspawn-known-issues.md#my-x23)), so on Windows it prints `C:/...`.

### <a id="my-paths"></a>Paths

- A path is absolute if it has a drive (`C:/x`, `C:\x`) or is a UNC name (`//server/share` or `\\server\share`).
- `/x` (or `\x`) has no drive. As Windows itself reads it, it is `x` at the root of the drive of the shell's directory
  (with the shell in `C:/a/b`, `/x` is `C:/x`), or at the root of its share (with the shell in `//server/share/a`,
  `/x` is `//server/share/x`).
- `\` separates directories, as `/` does.
- The shell's own directory keeps Perl's form (`C:/x/y`), so `pwd` and `$PWD` show it so.

### <a id="my-user"></a>`~user`

(post-0.10, the user's follow-up to WS1: "`%USERPROFILE%/../user`")

- One's own name (`USERNAME`): `USERPROFILE`.
- Another name: the directory of that name beside `USERPROFILE`, if it is a directory; otherwise `~user` stays as
  written. `~..` too stays as written.

There is no user database. Profiles are usually such siblings, but a domain profile may be `user.DOMAIN`, and the
registry's ProfileList has the real paths.

### <a id="my-variable-names"></a>Variable names

(post-0.12, [X65](pspawn-known-issues.md#my-x65), the user's A22 (a), 2026-11-15)

- The names of inherited variables are spelled as the environment block spells them (read by a small XSUB,
  `GetEnvironmentStringsW`); the values come from `%ENV`.
- The exception is `PATH`, which Windows spells `Path`: the shell sees it as `PATH`, as Cygwin does.
- Before post-0.12 the names were in upper case, as Perl's `%ENV` gives them on Windows, so
  `export z=3; sh -c 'echo $z'` printed nothing.
- `PROC_SHELLSPAWN_ENVNAMES=upper` (or `$Proc::ShellSpawn::ENV_NAMES = 'upper'` before `run`) takes the names as
  `%ENV` gives them (A22 (b)). Then only an upper-case name reaches a shell that `Proc::ShellSpawn` starts.

### <a id="my-the-same-file"></a>The same file: `test -ef`, `pwd -L`

(post-0.12, the user, 2026-11-16) As Microsoft documents it, two names are the same file if, with both opened, they
have the same volume serial number and file ID:

- the 128-bit file ID of `GetFileInformationByHandleEx` (`FileIdInfo`; Windows 8 / Server 2012 and later; ReFS needs
  it);
- else the 64-bit file index of `GetFileInformationByHandle` (Windows XP and later).

An ID of all zeros means "cannot tell": then the 64-bit index is tried, and if that cannot tell either (or a name
cannot be opened), stat's device and inode numbers, or where those are 0, the two paths compared once resolved. By the file IDs two hard links are one file; only that last
way, comparing paths, takes them for two. Checked under
Wine only; not on Windows before 8, nor on ReFS or FAT.

### <a id="my-cat-sort-grep"></a>`cat`, `sort`, `grep` and the like: BIN1

(post-0.10, **BIN1**, the user's follow-up to WS1: "Replace them from `%ENV` (inventing suitable fallbacks)";
**a temporary workaround**, the user, 2026-11-10)

- On every platform, the directories in `PROC_SHELLSPAWN_BIN` are searched before `PATH`. The value is split as `PATH`
  is; `none` means none, since Windows has no empty variables.
- If it is unset: on POSIX, none; on Windows, the first of these that has `cat.exe`:
  - Git for Windows' `usr\bin` (beside `git.exe` on `PATH`, or under `%ProgramFiles%`, `%ProgramW6432%`,
    `%LOCALAPPDATA%\Programs`);
  - MSYS2's (`%SystemDrive%\msys64\usr\bin`);
  - Cygwin's (`%SystemDrive%\cygwin64\bin`).
- Windows' own `sort`, `find`, `timeout`, `expand` are never taken for the POSIX ones, which they are not: in the search
  (BIN1's directories, then `PATH`), a file of one of these names under `%SystemRoot%` is skipped.
- The registry is not read.
- At run time the list is `@Proc::ShellSpawn::BIN`.
- A `sh` found there counts as a program `sh` for SH1's `auto` (below).

### <a id="my-a-command-sh"></a>A command `sh`: SH1

(post-0.10, **SH1**, the user's follow-up to WS1: "Should not `sh -c` just call Perl with our module, then?
(Configurable)")

- A command `sh` runs Perl with this module: `$^X -MPARSER -MProc::ShellSpawn=sh -e0 -- ARGS`, with this Perl's `@INC`;
  PARSER is the largest of the parsers (`Proc::ShellSubset::Large`, `Proc::ShellSubset`, `Proc::ShellSubset::Small`)
  that the calling Perl has loaded. It reads `-c`, `-s`, a file or stdin, and other option letters as `set` does
  (`-e`, `-u`, `-x`, ...).
- `PROC_SHELLSPAWN_SH` (or `$Proc::ShellSpawn::SH`) chooses:
  - `auto` (the default): Perl when neither BIN1's directories nor the `PATH` in force for that command has a `sh`; so on Windows unless one
    of BIN1's directories (Git for Windows, MSYS2, Cygwin) or `PATH` has one; on POSIX, where `sh` is always found,
    nothing changes;
  - `perl`: always;
  - `program`: never.
- On Linux, [`t/programs.t`](../t/programs.t) runs 10 snippets both with the program `sh` (dash) and as Perl: the same,
  apart from dash's line number in its messages (`Proc::ShellSpawn` gives none: [section 8 of
  `pspawn-design.md`](pspawn-design.md#my-section-8)).
- The text after `-c` is an argument. Through `system1` (Perl's own spawn, reached through the module Run where
  `Proc::Spawner` has neither `posix_spawn` nor fork, or is told so: [section 8 of
  `pspawn-spawner.md`](pspawn-spawner.md#my-section-8)), Perl drops every `"` of an argument, and also splits one
  that has both blanks and a `"` (an argument with blanks and no `"` arrives whole). Checked under Wine: `'echo "$0|$1|$#"'` arrives as `'echo'`, `'$0|$1|$#'`; `'echo"$0"'` as
  `'echo$0'` ([`perl-win32-system-bugs.md`](perl-win32-system-bugs.md), 1). This is not worked around.

## <a id="my-section-2"></a>2. What was checked

| How | Result |
|---|---|
| [`t/portable.t`](../t/portable.t): the 250 lines (of 451; 458 now, post-0.13: the 7 new lines are not among those kept) of the batteries ([`t/batteries/`](../t/batteries/)) that need no program but `perl` and print the same on Linux whatever the directory, `HOME` (also unset) and umask, compared with what `Proc::ShellSpawn` printed for them on Linux ([`t/batteries/portable.txt`](../t/batteries/portable.txt)) | under Wine 9.0 with Strawberry Perl 5.38.2 (rerun 2026-11-19, the code of post-0.13): all 250 the same through [`win_spawn.h`](../win_spawn.h); through Perl's own spawn, `system1` (through Run), 248 the same and the 2 lines of the test's list `%SYSTEM1` TODO (Perl's argv bug, [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md), 1); the record made again on Linux the same day is the same file |
| the 327 of the 451 battery lines that need no program but `perl` and print the same in all four variations on Linux (as they are; with only `perl` on `PATH` and another `HOME`; with umask 077; with `HOME` unset), before the filter that leaves out machine-dependent lines (the filter takes 77 of them out) | under Wine, through `win_spawn.h` (2026-11-19), the test's directory on drive C: (File::Temp's default): 297 the same, 30 others, 16 + 4 + 3 + 5 + 1 + 1, all among the 77: files and directories of Linux missing on C: (16; among them 2 lines that on Z: show the drive), the drive in paths (4), `ulimit` (3), signals (5 lines: one that traps the numbers 10 and 12, rejected; three that `kill` USR1 or WINCH to `$$`, which goes to the program `kill`, not found; `kill -TERM $$`, where on Linux `t/try.pl` dies by the signal, as `sh -c` would, and under Wine ends with status 143), `HOME` unset (1), `~root` (1). With the directory on drive Z: (Wine's view of Linux's `/`): 310 the same, 17 others, also all among the 77, 6 + 3 + 5 + 1 + 1 + 1: the drive in paths, `ulimit`, signals, `HOME` unset (`/usr` taken on Z:), `~root`, the `\` rule of File::Glob (on C: hidden: `/etc/hosts` is not there). An older run (post-0.10) counted 304 lines, 281 the same; its record is not kept, and the causes it listed add up to more than its 23 |
| `perl Makefile.PL`, `gmake`, `gmake test` of [`t/loop.t`](../t/loop.t), [`t/windows.t`](../t/windows.t), [`t/parsers.t`](../t/parsers.t), [`t/programs.t`](../t/programs.t), [`t/portable.t`](../t/portable.t) with Strawberry Perl's own gcc, under Wine | pass |
| [`t/portable.t`](../t/portable.t), Windows only (post-0.10): 19 lines with Windows' own paths, their output written by hand ([below](#my-the-windows-only-lines)) | under Wine (2026-11-19): pass through `win_spawn.h`; through `system1` the one line `sh -c TEXT NAME ARGS` is TODO (Perl's argv bug), as below |
| Linux: the whole suite, also through Run (`PROC_SPAWNER_MISSING="posix_spawn fork"`) | pass |
| the large subset: the 40,410 snippets of the corpus runs ([`README.md`](../README.md#my-how-close)), in both ways, against the base run on Linux of 2026-11-17 ([below](#my-the-large-subset-under-wine)) | under Wine 9.0 with Strawberry Perl 5.38.2 (the code of post-0.12): through `win_spawn.h` 39,837 the same and 357 the same apart from how paths are written; 131 say nothing (Linux itself gives no stable result); 6 differences made by the test setup; 79 differences found on Windows, one of them our known bug X71. Through `system1` 39,484, 348, 131, 5 and 442, 368 of these from Perl's own `system` |

### <a id="my-the-windows-only-lines"></a>The Windows-only lines of `t/portable.t`

The 19 lines:

- UNC names (7 lines): `cd` to a UNC name with backslashes and with slashes, `..` in it and stopping at the share, a relative
  `cd` and `test -d` under it, `\x` from it (the root of the share), a child started in it;
- `~user` (3 lines): one's own name; `~Public`; and one line with both a name that has no profile and `~..`, each
  left as written;
- `sh` as Perl (4 lines): `-c`, `-s`, nested, `-c TEXT NAME ARGS` (the last is TODO through `system1`, because of
  Perl's argv bug);
- BIN1 (5 lines, with a copy of `whoami.exe` standing in for `cat.exe`): `PROC_SHELLSPAWN_BIN`, Git's `usr\bin` under
  `%LOCALAPPDATA%\Programs` and beside `git.exe` on `PATH`, `none`, `find.exe` not taken. `%ProgramFiles%` is
  untested (Wine sets it afresh in every process), and so are `%ProgramW6432%`, MSYS2's and Cygwin's directories.

Wine has no server shares. Its device names `\\.\C:\...` have the form of UNC names (server `.`, share `C:`), and the
UNC lines use them.

These lines found two bugs of `Proc::ShellSpawn`, fixed before any release had them:

- `\x` from a UNC directory was taken from the process's own drive;
- `pwd` at the root of `\\.\C:` printed nothing (the server `.` was taken for a `.` component).

**Not checked:** real Windows; a command found through `PATHEXT`'s `.bat`, `.cmd` (Wine's `cmd.exe` quotes
differently, see [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md)); Ctrl-C reaching children while the shell
waits.

### <a id="my-the-large-subset-under-wine"></a>The large subset under Wine

The large subset is the 40,410 snippets of shell text with which [`README.md`](../README.md#my-how-close) measures
`Proc::ShellSpawn` against the shells dash and bash.  The base run is the project's run of them on Linux (`make
corpus-all`, 2026-11-17; its `system1` part 2026-11-18).  Here each snippet was run by `Proc::ShellSpawn` under Wine
9.0, with Strawberry Perl 5.38.2 and the code of post-0.12, in both ways of starting a program (the Linux runs were
made again on 2026-11-22, with the code of post-0.13, over the 40,409 snippets it accepts; the Windows runs were not,
so this part compares with the Linux runs of 2026-11-17):

- by `posix_spawn`: on Windows the module's own, [`win_spawn.h`](../win_spawn.h);
- by Perl's own `system` (`system1`), which the module uses, with the module Run, where there is neither `posix_spawn`
  nor `fork`; the runs of this way set `PROC_SPAWNER_MISSING="posix_spawn fork"`, which makes the module take it, on
  Linux and on Windows.

Each result was compared with the base run's result of the same way: the exit status, the output, the error
messages, the programs called with their arguments, and the files left.  The programs a snippet calls are replaced by
stand-ins that log the call, on Linux by the test runner's recorders, on Windows by small Windows programs.  On
Windows, the stand-ins of the 49 programs whose work the snippets use (`cat`, `sed`, `ls`, `kill`, ...) then run a
program of that name, and the table holds two setups:

- for 72 snippets, Git for Windows' build of the program (PortableGit 2.47.1, `usr\bin`, where BIN1, above, finds
  it): these 72 differed from Linux with the other setup because of it;
- for all others, the Linux program, through files: as Wine cannot run a Linux program as the child of a Windows
  program properly (it neither waits for it nor passes it a pipe), the stand-in writes the program's input to a file,
  has the Linux program run on it, and copies its output back.  With Git's programs some of these snippets may differ
  too: not tested yet ([`TODO`](../TODO.md)).

The table sorts the snippets by what their result says about Windows.  A bracket, `[=...]`, is the sum of the rows
under it.  In the `system1` column the first number of a cell is the `system1` count; the rest of the cell gives
the `win_spawn.h` count, adding the snippets of the `win_spawn.h` row that are in (c) through `system1`.

| Snippets | `win_spawn.h` | `system1`: its count + those of the `win_spawn.h` row that are in (c) through `system1` |
|---|---:|---:|
| The same result on Windows as on Linux | 39,837 | 39,484 + 353 = 39,837 |
| The same, apart from how paths are written | 357 | 348 + 9 = 357 |
| Says nothing: Linux itself gives no stable result | 131 | 131 |
| Differences made by the test setup, not by Windows: | [=6] | [=5 + 1 = 6] |
| &nbsp;&nbsp;(s1) both test runners stop a file at 20 MB; under Wine, a pipeline of Git for Windows' programs does not get there within the 5 seconds | 3 | 3 |
| &nbsp;&nbsp;(s2) on Linux, `PATH` holds the test runner's recorders, shell scripts, which `.` can read | 1 | 1 |
| &nbsp;&nbsp;(s3) environment variables the Windows runs had and the Linux runs did not¹ | 1 | 0 + 1 = 1 |
| &nbsp;&nbsp;(s4) under Wine, Git for Windows' programs cannot start a program with `fork` | 1 | 1 |
| Differences found on Windows: | [=79] | [=442] |
| &nbsp;&nbsp;(a) Windows behaves otherwise, and `Proc::ShellSpawn` passes that on | 50 | 46 + 4 = 50 |
| &nbsp;&nbsp;(b) `Proc::ShellSpawn`'s own design for Windows² | 10 | 10 |
| &nbsp;&nbsp;(c) Perl's own `system` on Windows is at fault | 0 | 368 |
| &nbsp;&nbsp;(d) Git for Windows' `kill` and `comm` differ from Linux's | 18 | 17 + 1 = 18 |
| &nbsp;&nbsp;(e) a known bug of `Proc::ShellSpawn` | 1 | 1 |
| All snippets | 40,410 | 40,410 |

¹ The one snippet shows `ProgramFiles` and `ProgramW6432`.  The Windows runs keep these two only to work around
[X77](pspawn-known-issues.md#my-x77), a known bug of `Proc::ShellSpawn` that is easy to fix: without them every start
of a program warns.

² The choices of [section 1](#my-section-1) of this document.

The rows are disjoint: in each way, each snippet is in one row.  39,837 + 357 + 131 + 6 + 79 = 40,410 and 39,484 +
348 + 131 + 5 + 442 = 40,410.  The counts are in [`test-results/wine-large-subset.txt`](test-results/wine-large-subset.txt);
the records, the tables per snippet and the tools are in repository `ilyaz-ai/Proc-Spawner-results`,
[`proc-spawner/2026-11-19-post-0.12-wine/`](https://github.com/ilyaz-ai/Proc-Spawner-results/tree/main/proc-spawner/2026-11-19-post-0.12-wine).

**The rows**, with counts (`win_spawn.h` / `system1`) where a row has more than one cause:

- **The same result on Windows as on Linux.**  This includes 15 / 13 snippets whose result differs from the base run's
  only because the base run was made in another container: Linux run again in the container Windows ran in gave the
  Windows result.  The two containers differ in the users of `/etc/passwd` and `/etc/group` (9 / 8 snippets read
  them), in the programs installed (`ls /usr/bin`: 3 / 2), in Ubuntu's Perl package (`perl -V`: 1), in an inode number
  (1) and in the kernel's configuration (`/proc/config.gz`: 1).  9 + 3 + 1 + 1 + 1 = 15 and 8 + 2 + 1 + 1 + 1 = 13.
- **The same, apart from how paths are written.**  `Proc::ShellSpawn` on Windows shows paths in Windows' form
  (`Z:\runcompare\w0\run\home` for `~`, `Z:/runcompare/w0/run` for `pwd`; `Z:` is Wine's drive for Linux's `/`).
  Written as `/x/y`, with the quotes some programs put around such a path taken off on both sides, nothing else
  differs.  Windows accepts both forms.
- **Says nothing: Linux itself gives no stable result.**  These snippets give more than one result on Linux alone, so
  a comparison with one Linux run says nothing, whatever the Windows result.  They are the same 131 in both ways:
  - 45 that the project's runs found to be chance (process IDs, times, the environment's variables, races);
  - 13 that never end;
  - 73 more that gave more than one result in Linux runs of one setup, in any record kept (the times of new files in
    `ls -l`, a name made of `$$`, `date` in a file name, how long `grep -R ... /` takes, races).

  45 + 13 + 73 = 131.
- **(s1) both test runners stop a file at 20 MB (`prlimit --fsize`); under Wine, a pipeline of Git for Windows'
  programs does not get there within the 5 seconds.**  `yes 0 | sed '1~2s/0/1/'` and 2 more like it write without end.
  On Linux the limit stops them within about a second (status 153, SIGXFSZ).  Under Wine the same limit stops a Windows
  program too: Git's `yes` alone, writing into a file, was stopped at 20,000,000 bytes after 0.17 seconds (status 153).
  But through a pipe, Git's `yes 0 | sed '1~2s/0/1/'` passed 15.6 to 17.1 MB in 5 seconds (three runs, Wine 9.0,
  PortableGit 2.47.1, one at a time, 2026-11-22), so these snippets run out of the 5 seconds first.  The limit comes from
  the Linux process Wine runs in; the Windows runner itself (job objects) sets no limit on the size of a file.
- **(s2) on Linux, `PATH` holds the test runner's recorders, shell scripts, which `.` can read.**  `. script` reads the
  recorder named `script` on Linux; on Windows the stand-in `script.exe` is no shell script (`cannot open script`).
- **(s3) environment variables the Windows runs had and the Linux runs did not.**  `env` lists the whole environment;
  footnote ¹.  This snippet, and 14 more that then gave the same result as Linux, ran with fewer Windows variables
  than the others: besides the variables the Linux runs have (`HOME`, `LANG`, ...), only `SystemRoot`, `ProgramFiles`
  and `ProgramW6432` (`SystemRoot`, which Windows needs, the stand-in does not pass on), and `PATH` written as
  `/runcompare/quiet;/runcompare/bin`.  The others ran with the variables a Windows process usually has (`USERNAME`,
  `TMP`, `TEMP`, `COMPUTERNAME`, ...); of them, only snippets that list the environment show these, and those are in
  "Says nothing" (5 / 5, among the 45 chance).
- **(s4) under Wine, Git for Windows' programs cannot start a program with `fork`.**  MSYS2's runtime, on which
  Git's programs are built, emulates `fork`, and under Wine 9.0 the emulation does not work: Git's `xargs`, which
  starts its command that way, hangs (`xargs echo x`, with or without input, with `echo` named by its full path or
  not), and Git's `find -exec echo x ';'` fails at once (`find: 'echo': Bad address`); `env echo x`, which needs no
  `fork`, works.  So `find dir -name \*~ | xargs echo rm | ksh -s`, which on Linux ends at once (`ksh: not found`,
  `echo` ended by SIGPIPE), runs out of the 5 seconds on Windows.
- **(a) Windows behaves otherwise, and `Proc::ShellSpawn` passes that on.**  Seen under Wine; not checked on real
  Windows.

  | Cause | `win_spawn.h` | `system1` |
  |---|---:|---:|
  | `Proc::ShellSpawn` finds no program at an absolute Linux path (`/usr/bin/find`, `/bin/sh`): on Windows there is none; under Wine it finds the Linux file but cannot start it (status 126), on real Windows the file is not there (127) | 18 | 16 + 2 = 18 |
  | The Linux programs `find` and `ls` behind the stand-ins, listing the whole file system (`find /`, `ls -lR /`) under Wine, list Wine's files too; on real Windows the tree is Windows' own | 12 | 12 |
  | `Proc::ShellSpawn`'s search for a command finds a program whatever the case of its name, as Windows' file names ignore case: `PATCH` runs `patch`, `HEAD` `head`, `AS` `as`, `KILL` `kill`, `Link` `link` (5 tldr usage lines whose `\|`-separated choices `Proc::ShellSpawn`, as any shell, reads as pipelines) | 5 | 5 |
  | Git for Windows' `ls -l` shows Windows' file system: owner `VM+rc3`, a numeric group, link count 1, directory size 0 | 4 | 4 |
  | `Proc::ShellSpawn`'s `echo $PATH` prints `PATH` with Windows' separator `;` | 3 | 3 |
  | `Proc::ShellSpawn`'s `test -k /tmp` and `[ -k /tmp ]` are false: Windows has no sticky bit | 2 | 2 |
  | Windows takes a command line of at most 32,767 characters: `Proc::ShellSpawn` cannot start `ldd /bin/* /usr/bin/*` ("Argument list too long") | 2 | 0 + 2 = 2 |
  | `Proc::ShellSpawn` opens the file of a redirection, `2>/dev/nul`: on Windows a file named `nul`, in any directory, is the null device, so it succeeds; on Linux `/dev/nul` cannot be made | 1 | 1 |
  | `Proc::ShellSpawn` cannot make the file of the redirection `> file*.txt`: no Windows file name can hold `*` (`Invalid argument`) | 1 | 1 |
  | `Proc::ShellSpawn` cannot open a directory for the redirection `<dir`, as Windows opens no directory as a file (`Permission denied`); Linux can | 1 | 1 |
  | `LD_PRELOAD=./linebufferedstdout.so python ...`: on Linux the dynamic loader complains that the library cannot be preloaded; Windows has no such loader, and nothing complains | 1 | 1 |
  | Total | 50 | 46 + 4 = 50 |

  Through `system1` the other 4 are in (c): in 2 snippets with an absolute path, Perl's own `system` splits the
  arguments of `nawk` (report 1), and it reports the 2 over-long command lines as "not found" (report 6).
- **(b) `Proc::ShellSpawn`'s own design for Windows** (footnote ²):

  | Choice | Snippets |
  |---|---:|
  | `Proc::ShellSpawn`'s `pwd` prints the directory in Windows' form, `Z:/...`, which the snippet takes apart (`pwd \| tr '/' '\n'`) | 2 |
  | `Proc::ShellSpawn`'s builtin `umask` prints 0000, and `umask -S` `u=rwx,g=rwx,o=rwx`, where on Linux it prints 0022 and `u=rwx,g=rx,o=rx`.  On both systems `Proc::ShellSpawn` keeps the value in a variable of its own, which starts, when a run begins, from what Perl's function `umask` returns: on Linux the umask of `Proc::ShellSpawn`'s Perl process (0022 in the Linux runs), on Windows always 0, as Windows has no umask | 3 |
  | `Proc::ShellSpawn`'s builtin `ulimit` is not supported on Windows (status 248) | 3 |
  | `find . -name *.txt -exec ls {} ;\` ends with a command named by a lone backslash, `\`.  On Linux `Proc::ShellSpawn` finds no program of that name (127, not found); on Windows `\` is to it a path, the root directory of the drive, and a directory cannot run (126, `Permission denied`) | 1 |
  | `Proc::ShellSpawn`'s builtin `type ls` prints `ls is Z:\runcompare\bin\ls.EXE`, where on Linux it prints `ls is /runcompare/bin/ls`: on Windows `Proc::ShellSpawn` looks for a command with the extensions of programs (`.COM`, `.EXE`, `.BAT`, `.CMD`) and prints the file it found, with the extension | 1 |
  | Total, in both ways | 10 |
- **(c) Perl's own `system` on Windows is at fault**, in [`perl-win32-system-bugs.md`](perl-win32-system-bugs.md):
  - report 1: a program gets other arguments than it was given (363);
  - report 6: a command line over 32,767 characters is "not found" (2);
  - a child gets only the descriptors 0, 1 and 2, so a redirection of descriptor 3 or above is refused (3).

  363 + 2 + 3 = 368.
- **(d) Git for Windows' `kill` and `comm` differ from Linux's.**
  - Git's `kill` words its messages otherwise than Linux's (procps): `kill: illegal pid: process_id` against `kill:
    failed to parse argument: 'process_id'`, `kill: 16085: No such process` against `kill: (16085): No such process`;
    and `kill -l` lists the signals otherwise (17 / 17);
  - Git's `comm` does not see descriptor 3, which `win_spawn.h` passes in the Windows way: `comm -12 /dev/fd/3 -` (1 /
    0; through `system1` it is in (c)).

  17 + 1 = 18.
- **(e) a known bug of `Proc::ShellSpawn`**: [X71](pspawn-known-issues.md#my-x71) (1 / 1).  In a snippet, `$$` is the
  process ID of `Proc::ShellSpawn`'s own Perl process, which plays the shell, and `kill -s WINCH $$` asks for `WINCH`
  to reach that process, so that the snippet's `trap ... WINCH` runs.  On Windows no program can send `WINCH` to it:
  Perl there has no such signal (its list has `HUP`, `INT`, `QUIT`, ..., `BREAK`, `ABRT`, `STOP`, `CONT`, but no
  `WINCH`, `USR1` or `USR2`), and a console's change of size reaches a Windows program not as a signal but as an
  event in the console's input, which the program sees only when it reads that input.
  - What `Proc::ShellSpawn` should do (decision WS1, [section 1](#my-section-1)): carry out `kill ... $$` for such a
    signal itself, by running the trap.
  - What it does since post-0.12, the bug: it passes the command to the program `kill`, here Git's, which rightly
    answers `kill: 1732: No such process`, as it knows only the processes of MSYS2's runtime.

**The comparison** takes out of the Windows records the warning that each of Git's programs writes first under
Wine (MSYS2's runtime, worded as Cygwin's: "Couldn't compute FAST_CWD pointer"), which real Windows does not write;
and it takes the program's own path off the start of a message on both sides (`/runcompare/real/cat:` on Linux,
`/usr/bin/cat:` from Git's programs).  The snippets with a different result were run 4 more times on each system;
"Says nothing" draws on these Linux runs too.

## <a id="my-section-3"></a>3. Still missing there

- `kill` of another process, and `time`: on POSIX these are still programs (the part of [X21](pspawn-known-issues.md#my-x21)
  not done: the others run inside Perl), and Windows has no such programs.
- `ulimit`.
- `cat`, `sort`, `grep` and the like: only a **temporary workaround** so far (BIN1, above; what replaces it is open).
