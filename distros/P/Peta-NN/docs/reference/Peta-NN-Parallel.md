# Peta::NN::Parallel

independent pieces of work on several cores

## Synopsis

```perl
use Peta::NN::Parallel qw(in_parallel);

my @rows = in_parallel(4, map { my $rule = $_; sub { train_and_export($rule) } } @rules);
```

## Description

`in_parallel` runs each task in a process of its own and returns their
results in the tasks' order. A result is plain data. `workers` is the number
`PETA_NN_WORKERS` names, or 1.

The examples run their jobs with it, one model's job per process.

## Functions

Both are exported on request.

### in_parallel

`in_parallel($workers, @tasks)`: runs the tasks, at most `$workers` at a
time, and returns what they returned, in the tasks' order. With one worker,
or one task, everything runs in this process. A task that dies fails the
call.

### workers

The number `PETA_NN_WORKERS` names, or 1.

---

From the POD of `lib/Peta/NN/Parallel.pm`; change it there.
