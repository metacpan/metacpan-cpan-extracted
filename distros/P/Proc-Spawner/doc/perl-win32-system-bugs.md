# Perl on Windows: `system LIST` — drafts of bug reports (2026-11-07, not yet filed)

Found while making Proc::Spawner start children through Perl's own spawn (`system { FILE } 1, ARGV`, decision M2;
[`doc/pspawn-spawner.md`](pspawn-spawner.md), section 8).  Seen with Strawberry Perl 5.38.2.2 (64-bit) under Wine 9.0 on Ubuntu 24.04;
the code read is `win32/win32.c` of perl v5.38.2.  **Not checked on real Windows**; the reports should say so, or be
checked there first.  Where to file: <https://github.com/Perl/perl5/issues> for 1 and 2; point 3 may be a security
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
