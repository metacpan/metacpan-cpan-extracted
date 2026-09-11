A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to **debug** and **reproduce**.

Every step is a single `task()` call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its `stdout`,
`stderr`, exit code and signal, optionally logs a full structured record, and
skips work that has already been done. It can also bound a step with a
[timeout](#timeouts) and rebuild [out-of-date outputs](#out-of-date-outputs).

Two subroutines are exported by default: [`task`](#task) and [`say2`](#say2).

# Install

With a CPAN client:

    cpanm SimpleFlow

Or from a checkout:

    perl Makefile.PL
    make
    make test
    make install

# Synopsis

The simplest useful case: run a command and confirm it produced its output:

    use SimpleFlow qw(task say2);

    my $t = task(
        cmd            => 'which ls',
        'output.files' => '/tmp/AFK3mnEK8L.log',
    );

`task` returns a hash reference describing exactly what happened:

    {
        cmd            "which ls",
        die            1,
        dir            "/home/con/Scripts/SimpleFlow",
        done           "now",
        dry.run        0,
        duration       0.00191903114318848,
        exit           0,
        note           "",
        output.files   [
            [0] "/tmp/AFK3mnEK8L.log"
        ],
        overwrite      1,
        signal         0,
        source.file    "t/01.t",
        source.line    29,
        stderr         "",
        stdout         "/usr/bin/ls",
        will.do        "done"
    }

> **Portability note.** SimpleFlow runs whatever shell command you give it via
> `system()`, so the *commands themselves* are your responsibility to keep
> cross-platform (e.g. `which ls` is Unix-only). SimpleFlow's own behaviour
> exit/signal decoding and coloured output is cross-platform; see the
> [change log](#change-log).

# `task`

    my $result = task(%args);      # or task(\%args)

Runs one command with checking, timing, capture and logging. Takes either a
flat key/value list or a single hash reference; the only required key is `cmd`.

## Arguments

| Key            | Type             | Default | Description |
|----------------|------------------|---------|-------------|
| `cmd`          | scalar or array  | `undef` | **Required.** The command to run. A string is handed to the shell; an array ref is run [without a shell](#running-without-a-shell). |
| `die`          | bool (`0`/`1`)   | `1`     | Die if the command fails (non-zero exit, timeout, or a missing output file). Set to `0` to warn and continue instead. |
| `dry.run`      | bool             | `0`     | Print the command (and log it) but do not execute it. |
| `input.files`  | scalar or array  | `undef` | File(s) that must exist and be readable **before** running; otherwise `task` dies. |
| `input.file`   | scalar           | `undef` | Convenience form of `input.files` for a **single** file. Must be a plain filename (not a reference). Cannot be combined with `input.files`. |
| `output.files` | scalar or array  | `undef` | File(s) expected to exist **after** running; used both for the missing-output check and for [skip detection](#skipping-completed-work). |
| `output.file`  | scalar           | `undef` | Convenience form of `output.files` for a **single** file. Must be a plain filename (not a reference). Cannot be combined with `output.files`. |
| `log.fh`       | open filehandle  | `undef` | If given, the full result record is also written here. Must be a real, open filehandle; `task` switches it to autoflush. |
| `note`         | scalar           | `''`    | Free-text note copied into the result and the log. |
| `overwrite`    | bool             | `0`     | If false and all `output.files` already exist, the command is skipped. Set true to always run. |
| `quiet`        | bool             | `0`     | Suppress the record printed to the terminal. The log and error messages on `STDERR` are unaffected. See [Quiet runs](#quiet-runs). |
| `stale`        | bool             | `0`     | Also re-run when an input file is newer than an output file. See [Out-of-date outputs](#out-of-date-outputs). |
| `timeout`      | whole seconds    | `0`     | Kill the command if it runs longer than this. `0` means no limit. See [Timeouts](#timeouts). |

Passing an unrecognised key, an undefined or empty filename, a `cmd` that is
neither a string nor an array ref, or a non-filehandle `log.fh` causes `task`
to die: these are usually mistakes worth catching early. Giving both
`output.file` and `output.files` (or both `input.file` and `input.files`), or a
reference where a single filename is expected, dies for the same reason.

## Return value

`task` always returns a hash reference. Every field below except the two
`input.*` ones is present on **every** path, so a caller running under
`use warnings FATAL => 'all'` can read the record after a skip or a dry run
without an uninitialized-value warning turning fatal. On those paths the
execution-only fields simply hold their empty values (`exit` and `signal` are
`0`, `stdout` and `stderr` are `''`, `duration` is `0`).

| Field              | Meaning |
|--------------------|---------|
| `cmd`              | The command that was run. An array-ref `cmd` is recorded space-joined for readability; that is not a shell-quoted round trip, since it never went near a shell. |
| `dir`              | Working directory at execution time. |
| `done`             | `"now"` (just ran), `"before"` (skipped, outputs already existed), or `"not yet"` (dry run). |
| `will.do`          | `"done"`, `"no"` (skipped), `"no: dry run"`, or `"FAILED"`. `"FAILED"` is set whenever the command exited non-zero, timed out, or left a declared output file missing — **whether or not `die` is set**. |
| `duration`         | Wall-clock seconds the command took (`0` for skips/dry runs). |
| `exit`             | Exit code of the command (`-1` if it could not be launched). |
| `signal`           | Signal number if the command process was killed by a signal, else `0`. Always `0` on Windows (no POSIX signals). |
| `timed.out`        | `1` if the command was killed for exceeding its `timeout`, else `0`. |
| `out.of.date`      | `1` if `stale` was set and an input was newer than an output, else `0`. |
| `stdout`, `stderr` | Captured output, with trailing whitespace stripped. |
| `die`, `dry.run`, `overwrite`, `note`, `quiet`, `stale`, `timeout` | The (defaulted) argument values used. |
| `output.files`     | Array ref of the output files (a scalar argument, or an `output.file`, is normalised to a one-element array). |
| `output.file.size` | Hash of `filename => size in bytes` for the outputs. |
| `input.files`      | Array ref of the input files, normalised the same way (present only if you passed `input.files` or `input.file`). |
| `input.file.size`  | Hash of `filename => size in bytes` for the inputs (present only if you passed `input.files` or `input.file`). |
| `source.file`, `source.line` | Where in *your* code the `task` was called: handy when debugging a long pipeline. |

## Skipping completed work

If `overwrite` is false (the default) and every file in `output.files` already
exists, `task` does **not** re-run the command. This makes pipelines
restartable: re-running the script picks up where it left off.

    open my $log, '>', 'logfile.txt';
    my $t = task(
        cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
        'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
        'output.files' => 'em.tpr',
        'log.fh'       => $log,
    );
    close $log;

On the first run `done` is `"now"`; on a re-run (with `em.tpr` present) `done`
is `"before"` and `will.do` is `"no"`. Pass `overwrite => 1` to force it.

An output file that exists but cannot be **read** does not count as done: it is
not a usable result, and treating it as one would skip the very step that could
replace it.

## Out-of-date outputs

Existence alone is a weak test. If an input file has been edited since the
output was built, the output is stale even though it is present — and by
default `task` will still skip the step, exactly as earlier versions did.

Pass `stale => 1` to get the rule `make` and `snakemake` use: re-run whenever
the newest `input.files` mtime is later than the oldest `output.files` mtime.

    my $t = task(
        cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
        'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
        'output.files' => 'em.tpr',
        stale          => 1,
    );

Editing `em.mdp` now rebuilds `em.tpr`; leaving it alone still skips. The
result's `out.of.date` field says which of the two happened. This is off by
default so that upgrading does not silently start re-running steps in pipelines
written against 0.15 and earlier.

## Timeouts

`timeout` gives a step a wall-clock budget in whole seconds:

    my $t = task(
        cmd     => 'a command that sometimes wedges',
        timeout => 600,
        die     => 0,
    );

The command is run in its own process group and, if the budget is exceeded, the
**whole group** is killed — a shell command is usually a pipeline, not a single
process, and killing only the shell would leave its children running. The
result then has `timed.out => 1` and `will.do => "FAILED"`; with the default
`die => 1` the pipeline stops there instead.

`timeout` needs `fork()` and POSIX process groups, so it is refused on
`MSWin32`. Leaving it at `0` (the default) changes nothing anywhere.

## Running without a shell

Giving `cmd` an array ref runs the command directly, with no shell in between:

    my $t = task(
        cmd           => ['gzip', '-9', $file],   # $file needs no quoting
        'output.file' => "$file.gz",
    );

This is the form to reach for when an argument comes from data — a filename
with a space, a quote, or a `$` in it is passed through untouched instead of
being re-parsed by the shell. You lose shell features (`>`, `|`, `*`, `&&`) in
exchange; use the string form when you want them.

## Quiet runs

Every `task` prints its record to the terminal. Over a hundred-step pipeline
that is a lot of scrollback, so `quiet => 1` suppresses it:

    my $t = task(
        cmd      => 'one of very many steps',
        'log.fh' => $log,
        quiet    => 1,
    );

The log filehandle still receives the full record, and error messages still go
to `STDERR`: asking for less noise is not the same as asking to be kept in the
dark about a failure.

## Dry runs

Useful for inspecting a pipeline without executing anything expensive:

    my $t = task(
        cmd       => 'a long-running, time-consuming command',
        'dry.run' => 1,
        'log.fh'  => $fh,
    );

The command is printed (and logged) but not run; `will.do` is `"no: dry run"`.

## Failure behaviour

By default (`die => 1`) `task` dies if the command exits non-zero, exceeds its
`timeout`, or leaves any declared `output.files` missing afterwards, so a broken
step stops the pipeline immediately.

With `die => 0`, `task` instead warns and returns its result hash with
`will.do => "FAILED"`, letting you decide what to do:

    my $t = task(cmd => 'a step that may fail', die => 0);
    if ($t->{'will.do'} eq 'FAILED') {
        ...   # $t->{'exit'}, $t->{stderr} and $t->{'timed.out'} say why
    }

## `say2`

    say2($message, $filehandle);

"Say to two places": prints `$message` to standard output **and** to the given
log filehandle, prefixed with the calling file and line number so log entries
are traceable. The filehandle must be open, or `say2` dies.

    open my $log, '>', 'run.log';
    say2('starting equilibration', $log);   # -> STDOUT and run.log
    close $log;

# Dependencies

Core/runtime modules used by SimpleFlow:

- [`Capture::Tiny`](https://metacpan.org/pod/Capture::Tiny) captures `stdout`/`stderr`
- [`Data::Printer`](https://metacpan.org/pod/Data::Printer) (`DDP`) pretty result/record printing
- [`Devel::Confess`](https://metacpan.org/pod/Devel::Confess) better backtraces on death
- `List::Util`, `Scalar::Util`, `Time::HiRes`, `Cwd`, `POSIX` core utilities

The test suite additionally uses `Test::More` and
[`Test::Exception`](https://metacpan.org/pod/Test::Exception).

# Changes

The release notes are in the `Changes` file at the root of the
distribution, in the format CPAN itself reads.

# COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself
