# Shell quoting, injection, and data boundaries

## What the argument-array form actually provides

`run 'program', [arguments...]` quotes the argument elements using
Net::OpenSSH::ShellQuoter for the selected shell, then joins them into a command
string. It does not bypass the shell. Keep the program name or path a trusted
constant. Do not put operators, user-controlled program names, or shell source in
that position. Quoting is contextual: a string safe as one argument may be unsafe
inside another interpreter's program or a different shell language.

```perl
# Fixed executable; untrusted data remains an argument.
my $text = 'literal $value; not a command';
my $out = run 'printf', ['%s', $text], auto_die => 1;
```

`run 'sh', ['-c', $script]` still executes `$script` as code. Quoting the outer
argument protects its delivery, not the interpretation performed by `sh`. Prefer
a fixed script whose data arrives through positional parameters or another explicit
input channel. Audit every nested interpreter: shell, Perl, SQL, template engine,
regular expression, and package manager options each have different grammars.

## Separate shell injection from option injection

An argument beginning with `-` may be interpreted as an option even when perfectly
shell-quoted. Validate operands and use the program's documented end-of-options
marker where supported. Do not append `--` indiscriminately to tools that do not
accept it. For controlled filesystem operations, require absolute paths under an
approved root and reject path traversal. String-prefix validation does not prevent
symlink races; enforce filesystem ownership and trusted parent directories too.

Avoid interpolating secrets into command strings. Backend debug logs, automatic
exceptions, shell tracing, process arguments, and application logs can expose them.
Environment variables are not a universal secret-safe replacement; define the
specific tool's protected credential mechanism and lifecycle.

## Review checklist as a procedure

Trace each external value from source to sink. Classify it as data, path, option,
identifier, or executable code. Validate its allowed domain before quoting. Identify
which interpreter receives it and whether another interpreter runs afterward. Test
spaces, quotes, dollar signs, leading dashes, Unicode, newline, empty string, and NUL
at the relevant boundary. Reject NUL in paths; do not silently truncate it.

**Practice:** keep examples explicit about their assumed shell. Do not present a
POSIX quoting helper as safe for cmd.exe, PowerShell, or all remote login shells.

## Evidence and scope

- [lib/Rex/Commands/Run.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Commands/Run.pm)
- [lib/Rex/Interface/Exec/SSH.pm](https://github.com/RexOps/Rex/blob/e2d7836bb9040429b96cf79c213adc9385274c88/lib/Rex/Interface/Exec/SSH.pm)
- [lib/Rex/Interface/Fs/LibSSH.pm](https://github.com/Getty/rex-libssh/blob/32a5db0e8fe49e0caf91793aeb214ca2ded9c0ab/lib/Rex/Interface/Fs/LibSSH.pm)
