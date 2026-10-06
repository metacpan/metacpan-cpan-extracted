A tiny workflow manager and logger for Perl, like SnakeMake or NextFlow, but in pure Perl and aimed at making long, error-prone shell pipelines easy to **debug** and **reproduce**.

Every step is a single `task()` call. SimpleFlow checks the inputs before a
command runs and the outputs after, times the command, captures its `stdout`,
`stderr`, exit code and signal, optionally logs a full structured record, and
skips work that has already been done. It can also bound a step with a
[timeout](#timeouts), [retry](#retries) it, rebuild
[out-of-date outputs](#out-of-date-outputs), run it in its own
[directory and environment](#environment-and-directory), make its outputs
[read-only](#protected-outputs), keep a [trace](#tracing) of the whole run,
[lock](#locking) a step against a second copy of the pipeline, run it in a
[container, a conda environment or on a SLURM cluster](#containers-conda-and-clusters),
and [run independent steps at once](#running-steps-in-parallel). A trace
becomes an [HTML report](#reports).

Two subroutines are exported by default: [`task`](#task) and [`say2`](#say2).
Two more are exported on request:
[`parallel`](#running-steps-in-parallel) and [`report`](#reports).

    use SimpleFlow qw(task say2 parallel report);

# Install

With a CPAN client:

    cpanm SimpleFlow

Or from a release tarball, unpacked:

    perl Makefile.PL
    make
    make test
    make install

A git checkout has no `Makefile.PL`: it is written by
[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), so run `dzil build` there
first and install from the tarball it makes, or run the tests in place with
`prove -Ilib t/`.

# Synopsis

The simplest useful case: run a command and confirm it produced its output:

    use SimpleFlow qw(task say2);

    my $t = task(
        cmd           => 'echo hello > hello.txt',
        'output_file' => 'hello.txt',
    );

`task` returns a hash reference describing exactly what happened, and prints
it (here from a script called `example.pl`, run in `/home/you/project`):

    {
        attempts           1,
        cmd                "echo hello > hello.txt",
        cmd.changed        0,
        conda_env          "",
        container          "",
        container_args     [],
        container_engine   "",
        cpu.system         0,
        cpu.user           0,
        die                1,
        dir                "/home/you/project",
        done               "now",
        dry_run            0,
        duration           0.00192999839782715,
        env                {},
        env_secret         [],
        executor           "local",
        executor_args      [],
        exit               0,
        failed.outputs     [],
        input_dirs         [],
        lock               0,
        mem                "",
        note               "",
        out.of.date        0,
        output_dirs        [],
        output_file.size   {
            hello.txt   6
        },
        output_files       [
            [0] "hello.txt"
        ],
        overwrite          0,
        protect            0,
        quiet              0,
        retries            0,
        retry_delay        0,
        signal             0,
        source.file        "example.pl",
        source.line        3,
        stale              0,
        stale_cmd          0,
        start.time         1790446630.13174,
        stderr             "",
        stderr_file        "",
        stdin              "devnull",
        stdout             "",
        stdout_file        "",
        threads            0,
        timed.out          0,
        timeout            0,
        walltime           "",
        will.do            "done",
        wrapped.cmd        "",
        wrapper            []
    }

Run it a second time and `hello.txt` is already there, so the step is skipped:
`done` is `"before"` and `will.do` is `"no"`.

> **Portability note.** SimpleFlow runs whatever shell command you give it via
> `system()`, so the *commands themselves* are your responsibility to keep
> cross-platform (e.g. `which ls` is Unix-only). SimpleFlow's own behaviour —
> exit/signal decoding and coloured output — is cross-platform; see the
> `Changes` file for what was done to make it so.

# `task`

    my $result = task(%args);      # or task(\%args)

Runs one command with checking, timing, capture and logging. Takes either a
flat key/value list or a single hash reference; the only required key is `cmd`.

## Arguments

| Key            | Type             | Default | Description |
|----------------|------------------|---------|-------------|
| `cmd`          | scalar or array  | `undef` | **Required.** The command to run. A string is handed to the shell; an array ref is run [without a shell](#running-without-a-shell). |
| `conda_env`    | name or path     | `undef` | Run the command in this conda environment. See [Containers, conda and clusters](#containers-conda-and-clusters). |
| `container`    | image            | `undef` | Run the command in a container made from this image. |
| `container_args` | array ref      | `[]`    | More arguments for the container engine, before the image. |
| `container_engine` | name         | `'docker'` | `'docker'`, `'podman'`, `'singularity'` or `'apptainer'`. |
| `die`          | bool (`0`/`1`)   | `1`     | Die if the command fails (non-zero exit, a kill by signal, a timeout, or a missing output file). Set to `0` to warn and continue instead. |
| `dir`          | directory        | `undef` | Run the step in this directory; every file it declares is relative to it. See [Environment and directory](#environment-and-directory). |
| `dry_run`      | bool             | `0`     | Print the command (and log it) but do not execute it. |
| `env`          | hash ref         | `{}`    | Environment variables for the command only; a value of `undef` removes one. See [Environment and directory](#environment-and-directory). |
| `env_secret`   | array ref        | `[]`    | Names in `env` whose values are never printed, logged or traced. See [Secrets](#secrets). |
| `executor`     | `'local'`/`'slurm'` | `'local'` | Where the command runs: here, or as a SLURM job step through `srun`. |
| `executor_args` | array ref       | `[]`    | More arguments for the executor (`srun`). |
| `input_dirs`   | scalar or array  | `undef` | Directories that must exist before running, as `input_files` must. |
| `input_dir`    | scalar           | `undef` | Convenience form of `input_dirs` for a **single** directory. |
| `input_files`  | scalar or array  | `undef` | File(s) that must exist and be readable **before** running; otherwise `task` dies (except in a [dry run](#dry-runs), which lists them instead). |
| `input_file`   | scalar           | `undef` | Convenience form of `input_files` for a **single** file. Must be a plain filename (not a reference). Cannot be combined with `input_files`. |
| `on_failure`   | code ref         | `undef` | Called with the record when the command ran and failed, before `task` dies. See [Hooks](#hooks). |
| `on_success`   | code ref         | `undef` | Called with the record when the command ran and succeeded. |
| `output_dirs`  | scalar or array  | `undef` | Directories the step makes, checked like `output_files`. See [Directory outputs](#directory-outputs). |
| `output_dir`   | scalar           | `undef` | Convenience form of `output_dirs` for a **single** directory. Cannot be combined with `output_dirs`. |
| `output_files` | scalar or array  | `undef` | File(s) expected to exist **after** running; used both for the missing-output check and for [skip detection](#skipping-completed-work). |
| `output_file`  | scalar           | `undef` | Convenience form of `output_files` for a **single** file. Must be a plain filename (not a reference). Cannot be combined with `output_files`. |
| `lock`         | bool             | `0`     | Hold a lock on the outputs while the step runs, so that a second copy of the pipeline waits for this one. See [Locking](#locking). |
| `log_fh`       | open filehandle  | `undef` | If given, the full result record is also written here. Must be a real, open filehandle; `task` switches it to autoflush. |
| `mem`          | e.g. `'16G'`     | `undef` | Memory to ask the executor for. |
| `note`         | scalar           | `''`    | Free-text note copied into the result and the log. |
| `overwrite`    | bool             | `0`     | If false and all `output_files` already exist, the command is skipped. Set true to always run. |
| `protect`      | bool             | `0`     | Make the outputs read-only once the step succeeds. See [Protected outputs](#protected-outputs). |
| `quiet`        | bool             | `0`     | Suppress the record printed to the terminal. The log and error messages on `STDERR` are unaffected. See [Quiet runs](#quiet-runs). |
| `retries`      | whole number     | `0`     | Run a failed step again, up to this many more times. See [Retries](#retries). |
| `retry_delay`  | seconds          | `0`     | How long to wait before each retry; may be fractional. |
| `stale`        | bool             | `0`     | Also re-run when an input file is newer than an output file. See [Out-of-date outputs](#out-of-date-outputs). |
| `stale_cmd`    | bool             | `0`     | Also re-run when the command differs from the one that made the outputs. See [Re-running a changed command](#re-running-a-changed-command). |
| `stderr_file`  | path             | `undef` | Write the command's standard error to this file instead of the record. See [Output to files](#output-to-files). |
| `stdin`        | `'devnull'`/`'inherit'` | `'devnull'` | What the command sees on its standard input. The default is the null device; `'inherit'` hands it the caller's own. See [Standard input](#standard-input). |
| `stdout_file`  | path             | `undef` | Write the command's standard output to this file instead of the record. |
| `threads`      | whole number     | `undef` | CPUs the command uses: given to it as `SIMPLEFLOW_THREADS`, and asked of the executor. |
| `timeout`      | whole seconds    | `0`     | Kill the command if it runs longer than this. `0` means no limit. See [Timeouts](#timeouts). |
| `trace_fh`     | open filehandle  | `undef` | Append one line of JSON per task to this filehandle. See [Tracing](#tracing). |
| `walltime`     | e.g. `'2:00:00'` | `undef` | Time to ask the executor for, as SLURM writes it. |
| `wrapper`      | array ref        | `undef` | A command to run the command inside, e.g. `['nice', '-n', '10']`. |

Any key but those naming a particular step can also be given once for the whole
program; see [Defaults for a whole pipeline](#defaults-for-a-whole-pipeline).

Passing an unrecognised key, an undefined or empty filename, a `cmd` that is
neither a string nor an array ref, or a non-filehandle `log_fh` causes `task`
to die: these are usually mistakes worth catching early. Giving both
`output_file` and `output_files` (or both `input_file` and `input_files`), or a
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
| `dir`              | Working directory at execution time: the absolute path of `dir`, if it was given. |
| `done`             | `"now"` (just ran), `"before"` (skipped, outputs already existed), or `"not yet"` (dry run). |
| `will.do`          | `"done"`, `"no"` (skipped), `"no: dry run"`, or `"FAILED"`. `"FAILED"` is set whenever the command exited non-zero, was killed by a signal, timed out, or left a declared output file missing — **whether or not `die` is set**. |
| `duration`         | Wall-clock seconds the command took (`0` for skips/dry runs). With [retries](#retries), the last attempt's. |
| `attempts`         | How many times the command was run: `0` for a skip or a dry run, `1` without retries. |
| `start.time`       | When the last attempt started, in epoch seconds with a fractional part; `0` if none did. |
| `cpu.user`, `cpu.system` | CPU seconds the command, and everything it waited for, spent in user and system mode. The clock counts in ticks of 1/100 s on Linux. Not known to be filled in on Windows. |
| `exit`             | Exit code of the command, or `-1` if it could not be launched at all (`stderr` then says why). |
| `signal`           | Signal number if the command process was killed by a signal, else `0`. A non-zero `signal` makes the step `"FAILED"`, even though `exit` is then `0`. Always `0` on Windows (no POSIX signals). |
| `timed.out`        | `1` if the command was killed for exceeding its `timeout`, else `0`. |
| `out.of.date`      | `1` if `stale` was set and an input was newer than an output, else `0`. |
| `stdout`, `stderr` | Captured output, with trailing whitespace stripped; `''` for a stream sent to `stdout_file` or `stderr_file`. When the command could not be launched at all (`exit` is `-1`), `stderr` says why, e.g. `cannot run "x": No such file or directory`. |
| `conda_env`, `container`, `container_args`, `container_engine`, `die`, `dry_run`, `env`, `env_secret`, `executor`, `executor_args`, `lock`, `mem`, `note`, `overwrite`, `protect`, `quiet`, `retries`, `retry_delay`, `stale`, `stale_cmd`, `stderr_file`, `stdin`, `stdout_file`, `threads`, `timeout`, `walltime`, `wrapper` | The (defaulted) argument values used. A string option not given is `''`, a list `[]`, `env` is `{}`, and `threads` is `0`. The values `env_secret` names are `(secret)` in `env`. The hooks are not recorded: they are code. |
| `output_files`     | Array ref of the output files (a scalar argument, or an `output_file`, is normalised to a one-element array). |
| `output_dirs`      | Array ref of the output directories, normalised as `output_files` is. |
| `input_dirs`       | Array ref of the input directories, normalised the same way; `[]` if none. |
| `cmd.changed`      | `1` if `stale_cmd` was set and the command on record for the outputs was a different one, else `0`. |
| `wrapped.cmd`      | The command as actually run, inside its executor, container, conda environment and wrapper, space-joined; `''` if it ran as it is. |
| `output_file.size` | Hash of `filename => size in bytes` for the outputs, as the command left them (measured before a failed step's outputs are moved aside). |
| `failed.outputs`   | Array ref of the names a failed step's outputs were [moved to](#failure-behaviour), each the output's own name with `.failed` appended; `[]` on every other path. |
| `input_files`      | Array ref of the input files, normalised the same way (present only if you passed `input_files` or `input_file`). |
| `input_file.size`  | Hash of `filename => size in bytes` for the inputs (present only if you passed `input_files` or `input_file`). In a dry run, an input that does not exist yet has `undef`. |
| `source.file`, `source.line` | Where in *your* code the `task` was called: handy when debugging a long pipeline. |

## Skipping completed work

If `overwrite` is false (the default) and every file in `output_files` already
exists, `task` does **not** re-run the command. This makes pipelines
restartable: re-running the script picks up where it left off.

    open my $log, '>', 'logfile.txt';
    my $t = task(
        cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
        'input_files'  => ['em.mdp', 'box.gro', 'topol.top'],
        'output_files' => 'em.tpr',
        'log_fh'       => $log,
    );
    close $log;

On the first run `done` is `"now"`; on a re-run (with `em.tpr` present) `done`
is `"before"` and `will.do` is `"no"`. Pass `overwrite => 1` to force it.

An output file that exists but cannot be **read** does not count as done: it is
not a usable result, and treating it as one would skip the very step that could
replace it. Nor does the output of a step that failed: that is moved aside to
`<file>.failed` (see [Failure behaviour](#failure-behaviour)), so a re-run runs
the step again instead of taking a half-written file as its result.

## Out-of-date outputs

Existence alone is a weak test. If an input file has been edited since the
output was built, the output is stale even though it is present, and by
default `task` will still skip the step, exactly as earlier versions did.

Pass `stale => 1` to get the rule `make` and `snakemake` use: re-run whenever
the newest `input_files` mtime is later than the oldest `output_files` mtime.
The mtimes are compared to the sub-second, where the filesystem records that,
so an input rewritten in the same second as its output still counts as newer.

    my $t = task(
        cmd            => 'gmx grompp -f em.mdp -c box.gro -p topol.top -o em.tpr',
        'input_files'  => ['em.mdp', 'box.gro', 'topol.top'],
        'output_files' => 'em.tpr',
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

Because the command has a process group of its own, a Ctrl-C at the terminal
reaches only your script, not the command. `task` therefore catches `INT`,
`TERM`, `HUP` and `QUIT` while a timed command runs, kills the command's group,
writes the record, and then passes the signal on: to your own handler if you
have one, and otherwise it ends the script as it would have without `task` in
the way. A signal your script ignores stays ignored.

With `stdin => 'inherit'` and a terminal on standard input, the command is
given the terminal's foreground for the duration, as a shell gives it to a job,
so that it can read from the terminal; your script takes it back afterwards.
A Ctrl-Z then suspends the command and your script together, as a shell
suspends a job, with the timeout's clock stopped, and `fg` carries on with
both. The same holds without a `timeout`.

Without a `timeout` the command has a process group of its own as well, so
that a signal reaches the whole of it, not just the shell at its head. A
`TERM` or `HUP` sent to your script, by a batch scheduler or `kill`, is passed
on to the command's group, which is waited for; then the record is written and
the signal passed on to your script, as with a timeout. A Ctrl-C (`INT`) or
`QUIT` is passed on to the group in the same way, but, as under `system`, not
to your script afterwards: the step fails, killed by the signal, and `die`
decides what happens next. A Ctrl-Z stops the command and your script together,
and `fg` or `bg` carries on with both. A command that opens the terminal
itself, as `ssh` or `sudo` do to ask for a password, is given its foreground
while your script has it to give.

If one of your own signal handlers dies while a command runs, the command's
group is killed and waited for before the exception reaches your code.
Before 0.192 the command was left running.

An `alarm` your script already had pending is kept: it is put back when the
command finishes, less the time the command took, and if it fell due while the
command ran it is delivered then.

`timeout` needs `fork()` and POSIX process groups, so it is refused on
`MSWin32`. Leaving it at `0` (the default) changes nothing anywhere.

## Retries

A step that fails for a reason outside its control, such as a flaky network or
a busy licence server, can be run again automatically:

    my $t = task(
        cmd           => 'fetch-data --to data.csv',
        'output_file' => 'data.csv',
        retries       => 3,
        'retry_delay' => 30,
    );

A failed attempt, for any of the reasons in
[Failure behaviour](#failure-behaviour), has its outputs moved aside and is
reported on `STDERR` and in the log (`attempt 1 of 4, retrying in 30s`); then
the command runs again. Only when the last attempt fails does the step fail,
and `die` apply. The record describes the last attempt, and `attempts` says how
many there were. An interrupt under a `timeout` is never retried, since it is a
request for the whole program to stop. This is Nextflow's `errorStrategy
'retry'` and Snakemake's `--retries`.

## Environment and directory

`env` sets environment variables for the command alone, and `dir` runs the step
in another directory:

    my $t = task(
        cmd           => 'make all',
        dir           => 'build',
        env           => { CFLAGS => '-O2', MAKEFLAGS => undef },
        'output_file' => 'a.out',            # that is, build/a.out
    );

A value of `undef` in `env` removes the variable for the command. Your script's
own `%ENV` is untouched: it is put back as soon as the command finishes.

Under `dir` the whole step happens in that directory, the input and output
checks as well as the command, so every name it declares is relative to it, as
the command itself sees it. Your script is back in its own directory when
`task` returns, however it returns, dying included. The record's `dir` is the
absolute path the step ran in.

## Secrets

The record holds the `env` a step was given, and the record is printed, written
to the log and written to the trace. A credential passed in `env` would be
written out with it. `env_secret` names the variables whose values must not be:

    my $t = task(
        cmd          => 'fetch-data --to data.csv',
        env          => { API_TOKEN => $token },
        'env_secret' => ['API_TOKEN'],
    );

The command is given the real value; everywhere else, the record included, it
is `(secret)`, and so it is in the arguments printed with an error. A secret's
value is not part of what [`stale_cmd`](#re-running-a-changed-command)
compares, so a new token does not re-run every step. `env_secret` in
[`%SimpleFlow::DEFAULTS`](#defaults-for-a-whole-pipeline) is combined with a
step's own, as `env` is.

Nothing else is hidden: the command line, `note` and every other `env` value
are written out in full. Pass a credential through `env`, never on the command
line.

## Output to files

A command that prints a great deal is better written to a file than held in
memory and printed in the record:

    my $t = task(
        cmd           => 'aligner --verbose reads.fq',
        'stdout_file' => 'align.out',
        'stderr_file' => 'align.log',
    );

The files are emptied when the step starts and receive the output of every
attempt, in order; the record's `stdout` and `stderr` are then `''`. That holds
even when the file is also a declared output, or is inside one: a failed
attempt that is to be retried leaves such an output where it is, and only a
step that has failed for good moves it aside. Naming the
same file for both puts the two streams in it interleaved, as a terminal would
show them. A step that is skipped, or dry-run, leaves the files alone, so they
still hold the output of the run that made the step's outputs. This is
Snakemake's `log:` directive.

## Directory outputs

A step whose result is a directory declares it with `output_dir` (or a list,
`output_dirs`), as Snakemake's `directory()` does:

    my $t = task(
        cmd          => 'split-by-sample input.bam samples',
        'input_file' => 'input.bam',
        'output_dir' => 'samples',
    );

A declared directory counts as made if it exists, and the step is skipped when
all its outputs, files and directories alike, exist already. A directory that
exists but is empty is warned about, as an empty output file is. When the step
fails, the directory is moved aside to `samples.failed` like any other output.
Under `stale`, a directory is as new as the newest thing in it.

A directory can be an input, too: `input_dir` and `input_dirs` must exist, and
be readable, before the step runs, just as `input_files` must, and under
`stale` an output is out of date if anything in an input directory is newer
than it.

## Protected outputs

`protect => 1` makes a step's outputs read-only once it succeeds, and, for a
directory output, everything in it, as Snakemake's `protected()` does:

    my $t = task(
        cmd           => 'expensive-simulation > result.dat',
        'output_file' => 'result.dat',
        protect       => 1,
    );

Re-running such a step over its outputs, with `overwrite` or `stale`, is then
refused with a message naming them, instead of failing inside the command with
an error that does not say why the file is read-only. Remove them, or make them
writable, to run it again. Symbolic links are left alone. `root` can write to a
read-only file, so for `root` this protects nothing.

## Tracing

`trace_fh` takes a filehandle and appends one line of JSON to it for every
task, on every path (run, skipped, dry-run or failed), in the spirit of
Nextflow's `trace.txt`:

    open my $trace, '>>', 'trace.jsonl' or die $!;
    local %SimpleFlow::DEFAULTS = ('trace_fh' => $trace);

Each line holds every field of the record except `stdout` and `stderr`, which
can be any size, plus `time`, when the line was written: the command line and
`env` included, so see [Secrets](#secrets). Open the file without an encoding
layer: the lines are UTF-8 already.

## Locking

`lock => 1` protects a step against a second copy of the same pipeline running
it at the same time. The first run to reach the step takes a lock on its
outputs; a second run that reaches it meanwhile says it is waiting, waits, and
then finds the outputs made and skips the step:

    my $t = task(
        cmd           => 'long-step > out.txt',
        'output_file' => 'out.txt',
        lock          => 1,
    );

The lock files are kept in `.simpleflow/` in the working directory (the one
`dir` names, if it is given), as Snakemake keeps its locks in `.snakemake/`,
so two runs see each other only when they share a working directory. The files
are left there afterwards, since removing one that another process is waiting
on would let two runs through. A step with no declared outputs has nothing to
lock, and a dry run takes no lock. The locks are `flock` locks, which some
network filesystems do not honour.

An output is locked under its real directory and its own name, so `out` and
`sub/../out`, or a name reached through a linked directory, are one output
here; an output that is itself a symbolic link is locked under what it points
at as well. A step also takes a shared lock on every directory above each of
its outputs, so that a step whose output is a directory, and one whose output
is a file inside it, do not run at once. Two hard links to one file are still
two outputs.

`.simpleflow/`, and `.simpleflow/cmd/` under it, must be directories, not
symbolic links: `task` refuses a link there, and opens nothing inside them
through one. These guard against a link planted by someone else; they do not
make a working directory others can write to safe to run a pipeline in.

## Re-running a changed command

By default a step whose outputs exist is skipped even if its command has been
edited since they were made. `stale_cmd => 1` re-runs it, as Snakemake's
`params` and `code` rerun triggers do:

    my $t = task(
        cmd           => 'bwa mem -t 8 -k 19 ref.fa reads.fq > aln.sam',
        'output_file' => 'aln.sam',
        'stale_cmd'   => 1,
    );

Changing the command, its `env`, its `threads`, or what it runs inside (its
container, conda environment, executor or wrapper) makes `cmd.changed` `1` and
the step run again. What made each set of outputs is kept, as a digest, in
`.simpleflow/cmd/` in the working directory, and written only after a
successful run. Outputs that exist with nothing on record, made before
`stale_cmd` was used, or by hand, are not re-run: the command is recorded
against them, so that the next change is seen.

A step run *without* `stale_cmd` over outputs that have a command on record
still replaces them, so after it succeeds its own command is recorded in place
of the old one, and a later `stale_cmd` run of the old command runs again
rather than taking the other's outputs as its own. With nothing on record, a
step without `stale_cmd` records nothing.

## Hooks

`on_success` and `on_failure` are called with the record once a command has
run, after the record is printed and logged:

    local %SimpleFlow::DEFAULTS = (
        'on_failure' => sub { my $r = shift; notify("$r->{cmd} failed: exit $r->{exit}") },
    );

`on_failure` runs before `task` dies, so it runs under the default `die => 1`
as well. Neither is called for a step that is skipped or dry-run. A hook that
dies stops `task` there, with its own exception. Set in `%SimpleFlow::DEFAULTS`,
they are the pipeline-wide `onsuccess` and `onerror` of Snakemake.

## Containers, conda and clusters

A command can be run inside a container, a conda environment, a SLURM job
step, or any wrapper you name:

    my $t = task(
        cmd       => ['samtools', 'index', 'x.bam'],
        container => 'biocontainers/samtools:1.19',   # with docker, by default
    );
    my $u = task(
        cmd         => 'python train.py',
        'conda_env' => 'analysis',
        executor    => 'slurm',
        threads     => 8,
        mem         => '16G',
        walltime    => '2:00:00',
    );

`container` runs `docker run --rm` (or `podman run`) with the working directory
mounted at its own path and used as the container's working directory, and,
for docker, with your own user and group, so that the files the command makes
are yours. `container_engine => 'singularity'` or `'apptainer'` runs
`singularity exec` with the working directory bound instead. The variables
`env` sets are passed into a docker or podman container by name; singularity
and apptainer pass the whole environment through themselves.

`conda_env` runs `conda run -n <name>`, or `-p <path>` for a path.

`executor => 'slurm'` runs the command through `srun`, which waits for the job
step and passes its exit status back, asking for `threads` CPUs, `mem` memory
and `walltime` time; `executor_args` adds any other `srun` arguments. With
[`parallel`](#running-steps-in-parallel), several steps run on the cluster at
once. `threads` is also given to the command, wherever it runs, as
`SIMPLEFLOW_THREADS`, for it to pass to its own option for threads.

`wrapper` runs the command inside any other command, given as an array ref,
such as `['nice', '-n', '10']` or `['env', 'LC_ALL=C']`.

These nest, outermost first, as executor, container, conda environment,
wrapper. A string `cmd` is run by `/bin/sh -c` (`cmd.exe /c` on MSWin32) inside
all of them, so it keeps its pipes and redirections. The record's `wrapped.cmd`
is what was actually run, and a dry run prints it.

## Running without a shell

Giving `cmd` an array ref runs the command directly, with no shell in between:

    my $t = task(
        cmd           => ['gzip', '-9', $file],   # $file needs no quoting
        'output_file' => "$file.gz",
    );

This is the form to reach for when an argument comes from data — a filename
with a space, a quote, or a `$` in it is passed through untouched instead of
being re-parsed by the shell. You lose shell features (`>`, `|`, `*`, `&&`) in
exchange; use the string form when you want them.

This holds for a one-element array ref too: `cmd => ['gzip -9 x']` looks for a
program literally named `gzip -9 x`, and fails, rather than handing the string
to the shell as Perl's own `system` does with a list of one.

## Quiet runs

Every `task` prints its record to the terminal. Error diagnostics — the
arguments and file lists printed before `task` dies or warns — go to `STDERR`,
so redirecting standard output does not hide them. Over a hundred-step pipeline
that is a lot of scrollback, so `quiet => 1` suppresses it:

    my $t = task(
        cmd      => 'one of very many steps',
        'log_fh' => $log,
        quiet    => 1,
    );

The log filehandle still receives the full record, and error messages still go
to `STDERR`: asking for less noise is not the same as asking to be kept in the
dark about a failure.

## Standard input

The command is run with its standard input on the null device, so a command
that stops to ask a question gets an immediate end-of-file and carries on
instead of waiting for an answer:

    my $t = task(cmd => 'rm -r some/tree');   # "remove write-protected file?"

This matters because `task` captures the command's output. A prompt is written
to standard error, which has been redirected into the capture, so nothing
reaches the terminal: before 0.17 such a command hung with no visible reason —
for ever with no `timeout`, and with one it was killed and reported as
`timed.out`, blaming the clock for what was really an unanswered question.

Shell redirection inside the command is unaffected, since that is the shell's
business rather than `task`'s:

    my $t = task(cmd => 'sort < unsorted.txt > sorted.txt');

To hand the command the caller's own standard input instead — a pipeline step
that really does read the data your script was given — ask for it:

    my $t = task(cmd => 'sort > sorted.txt', stdin => 'inherit');

`'inherit'` is the behaviour of 0.162 and earlier, and comes with its hazards:
the command consumes input your own script can then no longer read, and a
command that prompts will hang exactly as it used to. The caller's standard
input is saved and restored around every run either way, including when the
command dies, and a caller that had closed it keeps it closed. A `STDIN` that
is not descriptor 0, such as one opened on an in-memory scalar, is not the
command's standard input in any case: it is left alone, and descriptor 0 is
pointed at the null device and put back instead.

## Dry runs

Useful for inspecting a pipeline without executing anything expensive:

    my $t = task(
        cmd       => 'a long-running, time-consuming command',
        'dry_run' => 1,
        'log_fh'  => $fh,
    );

The command is printed (and logged) but not run; `will.do` is `"no: dry run"`.
The record is printed and logged as for any other step.

A dry run makes nothing, so a later step's input — an earlier step's output —
is legitimately absent. A dry run therefore does not die over a missing
`input_files` entry, as a real run does; it lists it under "these input files
do not exist yet", and the dry run of the whole pipeline carries on.

## Failure behaviour

By default (`die => 1`) `task` dies if the command exits non-zero, is killed by
a signal, exceeds its `timeout`, or leaves any declared `output_files` missing
afterwards, so a broken step stops the pipeline immediately. The message names
every one of those that happened, for instance
`"make all" exited 2; these output files should have been made but are missing:
a.out, from build.pl line 12`. When the command wrote anything to standard
error, the message ends with its last six lines, which is where a compiler, a
traceback or `make` says what went wrong.

Whichever of those happened, every declared output that *does* exist is moved to
`<file>.failed` (replacing any `.failed` left from before), and the new names are
listed in the record's `failed.outputs` and on `STDERR`. A name declared twice
is moved once; a file inside a declared directory moves with the directory,
under its own name; and when one output is named like another's `.failed`, as
`out` and `out.failed` are, the longer name is moved first, so that neither is
lost. When the message quotes standard error from a `stderr_file` that was one
of the outputs, it is read before the file is moved. A command that fails
part-way often leaves a truncated file behind; left under its own name, it would
pass the [skip test](#skipping-completed-work) on the next run and become the
result for good. Snakemake deletes a failed job's outputs for the same reason;
moving them keeps the partial contents for debugging.

With `die => 0`, `task` instead warns and returns its result hash with
`will.do => "FAILED"`, letting you decide what to do:

    my $t = task(cmd => 'a step that may fail', die => 0);
    if ($t->{'will.do'} eq 'FAILED') {
        ...   # $t->{'exit'}, $t->{signal}, $t->{stderr} and $t->{'timed.out'} say why
    }

## Defaults for a whole pipeline

`%SimpleFlow::DEFAULTS` gives a value to any key a `task` call leaves undefined:

    local %SimpleFlow::DEFAULTS = (
        'dry_run'  => 1,          # dry-run the whole pipeline
        'log_fh'   => $log,
        quiet      => 1,
        env        => { LC_ALL => 'C' },
    );

A task that sets a key itself keeps its own value. `env` is the one exception:
a task's own `env` is merged with the default one, its own entries winning, and its own `env_secret` is added to the default one.
Keys that name a particular step (`cmd`, the `input.*` and `output.*` lists,
`stdout_file` and `stderr_file`) are refused in `%DEFAULTS`, since every step
would then run the same command or claim the same files, and so is any key
`task` does not accept.

## `say2`

    say2($message, $filehandle);

"Say to two places": prints `$message` to standard output **and** to the given
log filehandle, prefixed with the calling file and line number so log entries
are traceable. The filehandle must be open, or `say2` dies.

    open my $log, '>', 'run.log';
    say2('starting equilibration', $log);   # -> STDOUT and run.log
    close $log;

# Running steps in parallel

`parallel` runs independent steps at the same time, at most `jobs` at once,
and returns their records in the order given:

    my @records = parallel(
        jobs  => 4,
        tasks => [
            map { { cmd => "gzip -9 $_", 'input_file' => $_, 'output_file' => "$_.gz" } } @samples
        ],
    );

Each entry of `tasks` is the arguments of one `task`, which runs in full, in a
child process of its own: its checks, its log, its record, its options, and
`%SimpleFlow::DEFAULTS`. Each record's `source.file` and `source.line` are the
`parallel` call's. Output from several steps at once interleaves, a record at
a time, on the terminal, in a shared log and in a shared [trace](#tracing):
each step writes its record holding a lock, so that no two records are mixed
within a line.

When a step fails, and `task` would die, no further step is started; those
already running are left to finish, and then `parallel` dies with every
failure. `'keep_going' => 1` runs every step regardless, and dies at the end if
any failed, as Snakemake's `--keep-going` does. Under `die => 0` a failed step
is only a record with `will.do => "FAILED"`, and `parallel` returns.

A `TERM`, `HUP`, `INT` or `QUIT` sent to your script while `parallel` runs is
passed to every running step, which passes it to its command; once they have
ended, the signal is passed on to your script. A signal your script ignores
stays ignored, by `parallel` and by the commands.

`jobs` above 1 needs a real `fork()`, so it is refused on `MSWin32`, where perl
emulates one with threads. `jobs => 1` runs the steps one after another, and
works everywhere.

The order of steps that depend on each other is still yours: `parallel` runs
the ones it is given at once, so give it only steps that can run together, and
call it again for the next stage.

# Reports

`report` turns a [trace](#tracing) into a single HTML page:

    report(trace => 'trace.jsonl', html => 'report.html', title => 'RNA-seq, batch 3');

The page counts the tasks by status, and lists each with its status, command,
note, start time, duration, CPU time, exit code, signal, attempts and where in
your script it was called, alongside a timeline of when each ran. It is one
self-contained file, with no scripts and nothing fetched, which follows the
reader's light or dark setting, so that it can be mailed or archived as it
is. `report` returns the number of tasks it read, and dies naming the line of
the trace it could not read: one that is not strict JSON in UTF-8, nests more
than 512 deep, or has a time that is not a number of seconds or a command that
is not a string. A `title` may be a character string or UTF-8 bytes.

# Dependencies

Core/runtime modules used by SimpleFlow:

- [`Data::Printer`](https://metacpan.org/pod/Data::Printer) (`DDP`) pretty result/record printing
- [`Devel::Confess`](https://metacpan.org/pod/Devel::Confess) stack traces, in colour on a
  terminal, for errors and warnings raised inside `task` and `say2`. It is
  switched on only for the length of each call, so your own program's `die`
  and `warn` are left exactly as you wrote them.
- `List::Util`, `Scalar::Util`, `Time::HiRes`, `Cwd`, `POSIX`, `File::Spec`,
  `File::Temp`, `File::Find`, `File::Path`, `Fcntl`, `Digest::MD5`, `Storable`
  core utilities; `stdout` and `stderr` are captured with
  `POSIX::dup2` onto temporary files

The test suite additionally uses `Test::More`,
[`JSON::PP`](https://metacpan.org/pod/JSON::PP) (core from perl 5.14) and
[`Test::Exception`](https://metacpan.org/pod/Test::Exception); it captures
output with its own small helper, `t/lib/CaptureStd.pm`.

# Changes

The release notes are in the `Changes` file at the root of the
distribution, in the format CPAN itself reads.

# COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

# Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI, and to Brett Estrade and Hexmeister for help.
