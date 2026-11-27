# Perl on Windows: `system LIST` and its handles — drafts of bug reports (2026-11-07, report 4 added 2026-11-10, a decision on report 2 of 2026-11-13, report 6 added 2026-11-19; not yet filed)

We found these bugs while making Proc::Spawner start children through Perl's own spawn (`system { FILE } 1, ARGV`;
the `1` asks Windows' Perl not to wait, and the call returns the process ID). That is the primitive *system1*, which
Proc::Spawner uses where it has neither `posix_spawn` nor fork (decision M2 of the user, the author of Proc::Spawner;
[`doc/pspawn-spawner.md`](pspawn-spawner.md#my-section-8), section 8).

- **Where observed:** Strawberry Perl 5.38.2.2 (64-bit) under Wine 9.0 on Ubuntu 24.04. The code read is
  `win32/win32.c` of perl v5.38.2 (for report 6 also of blead, 2026-11-19).
- **Not checked on real Windows**, apart from one result the user reported (section 2). The reports should say so,
  or be checked there first.
- **Where to file:** <https://github.com/Perl/perl5/issues> for reports 1, 4 and 6 (report 2 is not to be filed as it
  stands: section 2). Report 3 may be about a security
  issue, so it goes to Perl's security contact first (see `perlsecpolicy`), not to a public issue.

## <a id="my-section-1"></a>1. `system LIST` / `exec LIST`: the command line is not quoted as the child splits it back

**Summary.** On Windows a child gets one command line, which its C runtime splits back into `argv`
(`CommandLineToArgvW`'s rules: `\"` gives a literal `"`, backslashes before a `"` are halved, `""` is an empty
argument).  `create_command_line()` in `win32/win32.c` puts an argument in quotes only when it is empty, or contains blanks and no
`"` (and does not already begin and end with `"`), and escapes nothing (checked in perl v5.38.2's source).  So an argument with `"`, or one with blanks that ends in `\` (the one case the reproduction below lacks), or an empty one where an earlier
`"` left quoting open, does not arrive as given, although the list form of `system` promises the arguments as they are.  In particular:

- an argument with blanks and no `"` gets quotes and arrives whole;
- an argument with blanks and a `"` gets none: the child's runtime takes its `"` as quoting and drops them, and splits
  it at the blanks outside its `"…"` pairs
  (`'echo "$0|$1"'` arrives as two arguments, `echo` and `$0|$1`; checked under Wine, see
  [`pspawn-shell-windows.md`](pspawn-shell-windows.md#my-a-command-sh));
- an argument with a `"` and no blanks arrives whole but without its `"` (`'echo"$0"'` as `echo$0`).

**To reproduce** (`args.pl` is `print join("|", map "[$_]", @ARGV), "\n";`):

```perl
system $^X, 'args.pl', 'a b', 'q"x', 'c\\\\', '', 'x "y" z', 'tail\\', 'd\\"e', '%PATH%', 'a&b';
```

**Expected** (as on Unix): `[a b]|[q"x]|[c\\]|[]|[x "y" z]|[tail\]|[d\"e]|[%PATH%]|[a&b]`

**Got:** `[a b]|[qx c\\ " x y z tail\ d"e %PATH% a&b]` — two arguments instead of nine.

**Suggested fix:** for a program that is not `cmd.exe`, `command.com` or a batch file, quote every argument by the C
runtime's rules (in quotes; each run of backslashes before a `"` doubled and the `"` escaped; trailing backslashes
doubled), as Python's `subprocess.list2cmdline` and Rust's `std::process::Command` do.  An argument that already
starts and ends with `"` is copied as it is by today's Perl; that special case would go (or stay only for the shell cases).

## <a id="my-section-2"></a>2. `system LIST` of a missing program runs cmd.exe

**Summary.** When `CreateProcess` fails, `Perl_do_aspawn()` retries the same argument list through the shell
(`w32_perlshell_vec`, `cmd.exe /x/d/c`, "possible shell-builtin"), also for the list form, which by `perlfunc` does not
involve the shell.  So a missing program is not reported as `-1` with `$!`; cmd.exe runs instead, prints its own
message, and its status comes back.

**To reproduce:**

```perl
my $r = system 'nosuch_prog_xyz', 'a', 'b';            # cmd.exe: "... is not recognized ..."
print "$r $?\n";                                       # under Wine: 12544 12544 (expected: -1, $! ENOENT)
$r = system { 'nosuch_prog_xyz' } 'nosuch_prog_xyz', 'a';
print "$r $?\n";                                       # under Wine: 65280 65280 (expected: -1)
```

The second form, whose block names the program, also retries: `Perl_do_aspawn` puts cmd.exe's words (`cmd.exe /x/d/c`)
before the arguments but starts the program the block names again, so no shell runs; that fails too, and the result
is `255 << 8`, not `-1`.

**Suggested fix:** no shell retry for the list form (keep it for `system STRING`, if at all); return `-1` with `$!`
when nothing could be started.

**Not to be reported as it stands.** The user decided (2026-11-13, in the work on a patch to Perl's spawn on
Windows: "`dir` is sacrosanct") that the shell's own commands must keep working in the list form, as in
`system 'dir', '/b'`.  Two more facts from that work:

- On real Windows the first call above returns 256 (the user's report), not Wine's 12544.
- `system 1, STRING`, with one string after the 1, reaches the shell only through this retry, and `IPC::Open3` relies
  on that (`system 1, @_`).

## <a id="my-section-3"></a>3. Batch files (to check, then report privately)

For a `.bat` or `.cmd` program, `create_command_line()` puts the whole line in one pair of quotes and lets
`CreateProcess` start cmd.exe, without escaping the arguments for cmd.  Whether cmd then interprets characters such
as `&`, `|`, `%` in the arguments (the class of CVE-2024-24576, "BatBadBut") was not checked: Wine's cmd.exe does not
even run the batch file this way (it does not strip the outer quotes as Windows' cmd does).  To be checked on real
Windows before anything is reported, and then through the security contact.

## <a id="my-section-4"></a>4. Every child gets every handle: `$^F` is not honoured on Windows

(Found 2026-11-09, X38 in [`pspawn-known-issues.md`](pspawn-known-issues.md).)

**Summary.** `perlvar` says that file descriptors above `$^F` (2) are not passed to `exec()`ed processes.  On Windows
they are passed to every child Perl starts.  Perl's close-on-exec (`Perl_setfd_cloexec` in `doio.c`) is built on
`fcntl(F_SETFD)`, which Windows lacks, so it does nothing there, and `pipe` and `open` give inheritable handles.  The
spawn (`do_spawnvp_handles` in `win32/win32.c`) calls `CreateProcess` with `bInheritHandles` TRUE and no list of
handles.  A child then holds, unseen, any handle of its parent: for one, the write end of the pipe it reads as its
stdin, so it never sees end of file.  `win32_popen` itself avoids this for its own pipe (`O_NOINHERIT`, then only
the child's end made inheritable), so the danger is known there.  `perlport` does not mention `$^F`.

**To reproduce** (under Wine the child waits for ever; with the write end made not inheritable through
`Win32API::File::SetHandleInformation`, it sees end of file and ends):

```perl
pipe my $r, my $w or die;
open my $save, '<&', \*STDIN or die; open STDIN, '<&', $r or die;
my $pid = system 1, $^X, '-e', '1 while <STDIN>; print qq(child: eof\n)';
open STDIN, '<&', $save or die; close $r; close $w;
for (1 .. 50) { if (waitpid($pid, 1) == $pid) { print "parent: child ended\n"; exit } select undef, undef, undef, 0.1 }
print "parent: child still waiting for end of file after 5 s\n"; kill 'KILL', $pid;
```

**Suggested fix:** give `setfd_cloexec` and `setfd_inhexec` a Windows counterpart (`SetHandleInformation` with
`HANDLE_FLAG_INHERIT`), so that handles above `$^F` are not inherited, as on POSIX; or pass the spawn's handles as
`PROC_THREAD_ATTRIBUTE_HANDLE_LIST` (Vista and later), which is also thread-safe.  At the least, `perlvar` and
`perlport` should say that `$^F` has no effect on Windows.

## <a id="my-section-5"></a>5. Where this distribution works around them, and what to do when Perl is fixed

All of these concern only the primitive `system1`: Perl's own spawn, which Proc::Spawner uses where it has neither a
`posix_spawn` (on Windows its own, `win_spawn.h`) nor fork, so on Windows only when its `posix_spawn` is masked (`PROC_SPAWNER_MISSING=posix_spawn`; Perl's emulated fork on
Windows is not used).
The default primitive on Windows, [`win_spawn.h`](../win_spawn.h), needs none of these workarounds.

| Bug | Where | What is done | When Perl is fixed |
|---|---|---|---|
| 1 (argv) | the module | nothing: arguments are passed as they are (the user: no bug-for-bug workaround) | nothing to do |
| 1 | [`t/windows.t`](../t/windows.t) | the tests of exact argv (and batch files, 3) are TODO under `system1` | they pass: remove the TODO (for the batch-file tests, once report 3 is settled too) |
| 1 | [`t/try.pl`](../t/try.pl), [`t/portable.t`](../t/portable.t) | the shell snippet comes from a file (`TRY_FILE`), not from an argument | may stay (also convenient elsewhere) |
| 1 | [`t/spawner.t`](../t/spawner.t) | the Perl programs it starts are written to files (its function `pe`), not given with `-e` | may go back to `-e` |
| 1 | [`t/portable.t`](../t/portable.t), [`t/loop.t`](../t/loop.t) | a line written without `"` in an argument; a child's words without `"` | may stay |
| 1 | a command `sh` run as Perl with Proc::ShellSpawn (decision SH1, [`pspawn-shell-windows.md`](pspawn-shell-windows.md#my-a-command-sh)) | nothing: the text after `-c` is an argument; [`t/portable.t`](../t/portable.t)'s Windows-only line `sh -c 'echo "$0..."' nm a b` is TODO under `system1`, and so are two of the lines it takes from [`t/batteries/`](../t/batteries/), `A=1 B=$(true)$A sh -c 'echo "[$B]"'` and `A=1 B=$(echo $A) sh -c 'echo "[$B]"'` (the test's list `%SYSTEM1`): each passes `sh -c` a text with both blanks and `"`, which arrives split (section 1); `sh -c` texts with blanks and no `"` arrive whole and pass | they pass: remove the TODO |
| 2 (cmd.exe retry) | the module (`win_find` in `Spawner.pm`) | the program is looked up before Perl's spawn is called (`posix_spawnp`'s meaning of FILE: `PATH` and `PATHEXT`, not Perl's), so a missing one fails at once with ENOENT, before Perl's retry (`system1` uses the block form, whose retry starts the same program again with cmd.exe's words before its arguments: section 2); the retry itself stays in Perl | nothing to do (the lookup is what `posix_spawnp` does with FILE anyway; so a command of cmd.exe, such as `dir`, is not found through `system1`: Proc::Spawner starts programs; the decision "`dir` is sacrosanct" of section 2 was made for Perl's own `system`) |
| 4 (handles) | the module (`system1` in `Spawner.pm`, X38) | the calling process's fds from 3 up are made not inheritable for the call and put back after it; not thread-safe | remove it for the fixed versions of Perl |
| 6 (errno) | the module | nothing: `system1` passes on the error Perl's spawn gives (ENOENT), and Proc::ShellSpawn reports a spawn failing with ENOENT as "not found", status 127, as `sh` does; so a command line longer than Windows takes, started through `system1`, is "not found", where [`win_spawn.h`](../win_spawn.h) gives "Argument list too long" (it checks the length itself: more than 32,766 characters and the terminating NUL is E2BIG); seen in the corpus run under Wine (2026-11-18 and 19) in 2 snippets, both `ldd /bin/* /usr/bin/* \| ...` | nothing to do |

On POSIX, see [`perl-signals-findings.md`](perl-signals-findings.md) for Perl's signal and `waitpid` findings and
what the loop does about them.

## <a id="my-section-6"></a>6. `system LIST`: every failure of `CreateProcess` is reported as ENOENT

(Found 2026-11-19, in the corpus run under Wine: through `system1`, `ldd /bin/* /usr/bin/*`, whose words expand to a
command line longer than Windows takes, was "not found"; through `win_spawn.h` the same snippet gave "Argument list too
long".)

**Summary.** When `CreateProcess` fails, the spawn (`do_spawnvp_handles` in `win32/win32.c`) sets `errno = ENOENT`
whatever the failure was, without looking at `GetLastError()`, although the same file has `translate_to_errno()` for
this.  So a program that exists but cannot be started (access denied, not an executable) and a command line longer
than Windows takes (32,767 characters, the program's name included) all come back as "No such file or directory"
(read in the source: every failure of the call takes this path; only the long command line was tried).  The ENOENT
also starts the retry of report 2 ("possible shell-builtin", `Perl_do_aspawn`); with the block form, as below and as
`system1` calls it, the retry starts the same program again with cmd.exe's words before the arguments, a longer line
still, which fails too, so the caller gets `255 << 8` with `$!` ENOENT, not `-1`.  Checked in the source: the line `errno = ENOENT;` after `CreateProcess` fails is line 4640 in
perl v5.38.2 and line 4655 in blead (2026-11-19).

**To reproduce** (`$prog` is any program; checked under Wine with a five-line program of ours that prints the code page
and ignores its arguments, at `Z:\runwin\acp.exe`):

```perl
for my $n (32700, 32800) {
    my $r = system { $prog } $prog, 'x' x $n;
    printf "%d characters: returned %d, \$! %d (%s), \$^E %d\n", $n, $r, $! + 0, $!, $^E + 0;
}
```

**Got** under Wine: 32,700 characters start the program (returned 0); 32,800 return 65280, with `$!` 2 (No such
file or directory) and `$^E` 87 (ERROR_INVALID_PARAMETER: read after the retry, so it may be the retry's error; the
first call's is not visible to the caller).  Not checked on real Windows, which may give another Windows error for
the long line; Perl discards it either way.

**Expected:** for a failure other than a missing program, no retry and `-1`, with `$!` saying why: E2BIG for the long
command line (as `execve` gives on POSIX), EACCES for access denied, ENOEXEC for a file that is not a program.  (A
missing program is report 2's case.)

**Suggested fix:** set `errno` from `GetLastError()` (`translate_to_errno()`, with ERROR_BAD_EXE_FORMAT as ENOEXEC
added), and check the command line's length before the call (E2BIG); then the retry of report 2, as long as it stays,
happens only for a program really not found.

