# Perl on Windows: `system LIST` and its handles — drafts of bug reports (2026-11-07, 4 added 2026-11-10; not yet filed)

Found while making Proc::Spawner start children through Perl's own spawn (`system { FILE } 1, ARGV`, decision M2;
[`doc/pspawn-spawner.md`](pspawn-spawner.md), section 8).  Seen with Strawberry Perl 5.38.2.2 (64-bit) under Wine 9.0 on Ubuntu 24.04;
the code read is `win32/win32.c` of perl v5.38.2.  **Not checked on real Windows**; the reports should say so, or be
checked there first.  Where to file: <https://github.com/Perl/perl5/issues> for 1, 2 and 4; point 3 may be a security
issue and goes to Perl's security contact first (see `perlsecpolicy`), not to a public issue.

## 1. `system LIST` / `exec LIST`: the command line is not quoted as the child splits it back

**Summary.** On Windows a child gets one command line, which its C runtime splits back into `argv`
(`CommandLineToArgvW`'s rules: `\"` is a quote character, backslashes before a `"` are halved, `""` is an empty
argument).  `create_command_line()` in `win32/win32.c` puts an argument in quotes only when it contains blanks and no
`"`, and escapes nothing.  So an argument with `"`, or ending in `\` inside quotes, or empty in some positions, does not
arrive as given, although the list form of `system` promises the arguments as they are.

**To reproduce** (`args.pl` is `print join("|", map "[$_]", @ARGV), "\n";`):

```perl
system $^X, 'args.pl', 'a b', 'q"x', 'c\\\\', '', 'x "y" z', 'tail\\', 'd\\"e', '%PATH%', 'a&b';
```

**Expected** (as on Unix): `[a b]|[q"x]|[c\\]|[]|[x "y" z]|[tail\]|[d\"e]|[%PATH%]|[a&b]`

**Got:** `[a b]|[qx c\\ " x y z tail\ d"e %PATH% a&b]` — two arguments instead of nine.

**Suggested fix:** for a program that is not `cmd.exe`, `command.com` or a batch file, quote every argument by the C
runtime's rules (in quotes; each run of backslashes before a `"` doubled and the `"` escaped; trailing backslashes
doubled), as Python's `subprocess.list2cmdline` and Rust's `std::process::Command` do.  An argument that already
starts and ends with `"` is now copied as it is; that special case would go (or stay only for the shell cases).

## 2. `system LIST` of a missing program runs cmd.exe

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

The second form retries with the same program (so no shell runs), but the result is `255 << 8`, not `-1`.

**Suggested fix:** no shell retry for the list form (keep it for `system STRING`, if at all); return `-1` with `$!`
when nothing could be started.

## 3. Batch files (to check, then report privately)

For a `.bat` or `.cmd` program, `create_command_line()` puts the whole line in one pair of quotes and lets
`CreateProcess` start cmd.exe, without escaping the arguments for cmd.  Whether cmd then interprets characters such
as `&`, `|`, `%` in the arguments (the class of CVE-2024-24576, "BatBadBut") was not checked: Wine's cmd.exe does not
even run the batch file this way (it does not strip the outer quotes as Windows' cmd does).  To be checked on real
Windows before anything is reported, and then through the security contact.

## 4. Every child gets every handle: `$^F` is not honoured on Windows

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

## 5. Where this distribution works around them, and what to do when Perl is fixed

All of these concern the primitive `system1` only (Perl's own spawn, used where the module has no `posix_spawn`:
on Windows only when it is masked, `PROC_SPAWNER_MISSING=posix_spawn`); the default primitive there,
[`win_spawn.h`](../win_spawn.h), needs none of them.

| Bug | Where | What is done | When Perl is fixed |
|---|---|---|---|
| 1 (argv) | the module | nothing: arguments are passed as they are (the user: no bug-for-bug workaround) | nothing to do |
| 1 | [`t/windows.t`](../t/windows.t) | the tests of exact argv (and batch files, 3) are TODO under `system1` | they pass: remove the TODO |
| 1 | [`t/try.pl`](../t/try.pl), [`t/portable.t`](../t/portable.t) | the shell string comes from a file (`TRY_FILE`), not from an argument | may stay (also convenient elsewhere) |
| 1 | [`t/spawner.t`](../t/spawner.t) | the Perl programs it starts are written to files (`pe`), not given with `-e` | may go back to `-e` |
| 1 | [`t/portable.t`](../t/portable.t), [`t/loop.t`](../t/loop.t) | a line written without `"` in an argument; a child's words without `"` | may stay |
| 1 | `sh` as Perl (SH1, [`pspawn-shell-windows.md`](pspawn-shell-windows.md)) | nothing: the text after `-c` is an argument; [`t/portable.t`](../t/portable.t)'s line `sh -c 'echo "$0..."' nm a b` is TODO under `system1` | it passes: remove the TODO |
| 2 (cmd.exe retry) | the module (`win_find` in `Spawner.pm`) | the program is looked up before Perl's spawn is called, so a missing one is ENOENT and Perl never retries through cmd.exe | nothing to do (the lookup is posix_spawn's meaning of FILE anyway) |
| 4 (handles) | the module (`system1` in `Spawner.pm`, X38) | our fds from 3 up are made not inheritable around the call and put back after; not thread-safe | remove it for the fixed versions of Perl |

On POSIX, see [`perl-signals-findings.md`](perl-signals-findings.md) for Perl's signal and `waitpid` findings and
what the loop does about them.
