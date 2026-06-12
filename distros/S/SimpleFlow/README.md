A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to **debug** and **reproduce**.

Every step is a single `task()` call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its `stdout`,
`stderr`, exit code and signal, optionally logs a full structured record, and
skips work that has already been done.

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

    my $t = task({
        cmd            => 'which ls',
        'output.files' => '/tmp/AFK3mnEK8L.log',
    });

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

    my $result = task(\%args);

Runs one shell command with checking, timing, capture and logging. Takes a
**single hash reference**; the only required key is `cmd`.

## Arguments

| Key            | Type             | Default | Description |
|----------------|------------------|---------|-------------|
| `cmd`          | scalar           | `undef` | **Required.** The shell command to run. |
| `die`          | bool (`0`/`1`)   | `1`     | Die if the command fails (non-zero exit) or an output file is missing. Set to `0` to warn and continue instead. |
| `dry.run`      | bool             | `0`     | Print the command (and log it) but do not execute it. |
| `input.files`  | scalar or array  | `undef` | File(s) that must exist and be readable **before** running; otherwise `task` dies. |
| `output.files` | scalar or array  | `undef` | File(s) expected to exist **after** running; used both for the missing-output check and for [skip detection](#skipping-completed-work). |
| `log.fh`       | open filehandle  | `undef` | If given, the full result record is also written here. Must be a real, open filehandle. |
| `note`         | scalar           | `''`    | Free-text note copied into the result and the log. |
| `overwrite`    | bool             | `0`     | If false and all `output.files` already exist, the command is skipped. Set true to always run. |

Passing an unrecognised key, an empty filename, or a non-filehandle `log.fh`
causes `task` to die: these are usually mistakes worth catching early.

## Return value

`task` always returns a hash reference. The fields below are present after a
normal run; the [skip](#skipping-completed-work) and [dry-run](#dry-runs) paths
omit the execution-only fields (`exit`, `signal`, `stdout`, `stderr`).

| Field              | Meaning |
|--------------------|---------|
| `cmd`              | The command that was run. |
| `dir`              | Working directory at execution time. |
| `done`             | `"now"` (just ran), `"before"` (skipped, outputs already existed), or `"not yet"` (dry run). |
| `will.do`          | `"done"`, `"no"` (skipped), `"no: dry run"`, or `"FAILED"`. |
| `duration`         | Wall-clock seconds the command took (`0` for skips/dry runs). |
| `exit`             | Exit code of the command (`-1` if it could not be launched). |
| `signal`           | Signal number if the command process was killed by a signal, else `0`. Always `0` on Windows (no POSIX signals). |
| `stdout`, `stderr` | Captured output, with trailing whitespace stripped. |
| `die`, `dry.run`, `overwrite`, `note` | The (defaulted) argument values used. |
| `output.files`     | Array ref of the output files (a scalar argument is normalised to a one-element array). |
| `output.file.size` | Hash of `filename => size in bytes` for the outputs. |
| `input.files`      | The input argument, as given (present only if you passed `input.files`). |
| `input.file.size`  | Hash of `filename => size in bytes` for the inputs (present only if you passed `input.files`). |
| `source.file`, `source.line` | Where in *your* code the `task` was called: handy when debugging a long pipeline. |

## Skipping completed work

If `overwrite` is false (the default) and every file in `output.files` already
exists, `task` does **not** re-run the command. This makes pipelines
restartable: re-running the script picks up where it left off.

    open my $log, '>', 'logfile.txt';
    my $t = task({
        cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
        'input.files'  => ['em.mdp', 'box.gro', 'topol.top'],
        'output.files' => 'em.tpr',
        'log.fh'       => $log,
    });
    close $log;

On the first run `done` is `"now"`; on a re-run (with `em.tpr` present) `done`
is `"before"` and `will.do` is `"no"`. Pass `overwrite => 1` to force it.

## Dry runs

Useful for inspecting a pipeline without executing anything expensive:

    my $t = task({
        cmd       => 'a long-running, time-consuming command',
        'dry.run' => 1,
        'log.fh'  => $fh,
    });

The command is printed (and logged) but not run; `will.do` is `"no: dry run"`.

## Failure behaviour

By default (`die => 1`) `task` dies if the command exits non-zero or if any
declared `output.files` are missing afterwards, so a broken step stops the
pipeline immediately. With `die => 0`, `task` instead warns and returns its
result hash (with `will.do => "FAILED"`), letting you decide what to do.

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
- [`Term::ANSIColor`](https://metacpan.org/pod/Term::ANSIColor) coloured terminal output
- `List::Util`, `Scalar::Util`, `Time::HiRes`, `Cwd` core utilities

The test suite additionally uses `Test::More` and
[`Test::Exception`](https://metacpan.org/pod/Test::Exception).

# Change log

## 0.13 (2026-06-11)

### Fixed (Claude Opus 4.8 helped)

- **Exit status and signal are now decoded correctly.** `task()` previously
  computed the exit code (`$status >> 8`) and *then* derived the signal as
  `$exit & 127`. Because the signal lives in the low byte of the raw wait
  status, which `>> 8` discards the `signal` field was always wrong: a clean
  `exit 42` was reported as `signal 42`, and a process actually killed by a
  signal reported `signal 0`. The signal is now read from the raw status before
  shifting, so `exit` and `signal` are independent and accurate.

- **No longer dies on a missing output file when `die => 0`.** The zero-size
  check did `(-s $file) == 0`, which is `undef == 0` when a declared output file
  is absent. Under `use warnings FATAL => 'all'` that "uninitialized value"
  warning was fatal, so a task that was meant to *warn* about missing output
  (with `die => 0`) crashed instead. Missing sizes are now treated as `0`, so
  the task warns and returns its result hash as intended.

- **The "already done" result is now logged with its `duration`.** In the
  short-circuit path (output files already exist), `duration` was set *after*
  the record was written to the log, so the logged hash was missing it; the
  duplicate `done => 'before'` assignment was also removed.

### Changed / Windows support

- **Portable exit-status handling.** Decoding now branches on `$^O`: Windows has
  no POSIX signals (`signal` is reported as `0` there), and a `system()` that
  fails to launch the command (`-1`) yields `exit => -1` instead of a garbage
  value from shifting `-1`.

- **ANSI colour is disabled on the legacy Windows console.** `Term::ANSIColor`
  output is suppressed on `MSWin32` unless an ANSI-capable terminal is detected
  (Windows Terminal, ConEmu, or ANSICON), so `cmd.exe` no longer prints raw
  escape sequences and redirected logs stay clean. Unix and modern Windows
  terminals are unaffected.

### Tests

- Rewrote `t/01.t` to be cross-platform: shell commands now invoke the running
  Perl interpreter (`"$^X" -e ...`) instead of Unix-only tools (`which`, `ls`,
  `ln`, `cp`), and temp files use the system temp directory instead of a
  hard-coded `/tmp`.
- Added regression tests for both fixed bugs (exit/signal decoding; surviving a
  missing output file with `die => 0`).
- Added coverage for the `note` field, the `input.file.size` / `output.file.size`
  hashes, scalar-vs-array normalisation of `input.files` / `output.files`, the
  `dir` / `source.file` / `source.line` metadata, captured `stdout` / `stderr`
  (including trailing-whitespace stripping), and argument validation (missing
  `cmd`, unknown keys, bad `log.fh`, missing input files).

## 0.12

exit code now matches what shell would show it as; signal now appears

## 0.11

max string length now corresponds to max of output strings, no more truncated output
added List::Util dependency for string length maxes
memory size now shows when output
directory is now output during dry runs
