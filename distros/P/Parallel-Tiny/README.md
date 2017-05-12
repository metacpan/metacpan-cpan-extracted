# NAME

Parallel::Tiny

# DESCRIPTION

Provides a simple, no frills fork manager.

# SYNOPSIS

Given an object that provides a `run()` method, you can create a `Parallel::Tiny` fork manager object that will execute that method several times.

    my $obj = My::Handler->new();
    my $forker = Parallel::Tiny->new(
        handler      => $obj,
        workers      => 4,
        worker_total => 32,
    );
    $forker->run();

In the above example we will execute the `run()` method for a `My::Handler` object 4 workers at a time, until 32 total workers have completed/died.

# METHODS

- new()

    Returns a new `Parallel::Tiny` fork manager.

    Takes the following arguments as a hash or hashref:

        {
            handler      => $handler,      # provide an object with a run() method, this will be your worker (required)
            reap_timeout => $reap_timeout, # how long to wait in between reaping children                    (default ".1")
            subname      => $subname,      # a method name to execute for the $handler                       (default "run")
            workers      => $workers,      # the number of workers that can run simultaneously               (default 1)
            worker_total => $worker_total, # the total number of times to run before stopping                (default 1)
        }

    For instance, you could run 100 workers, 4 workers at a time:

        my $forker = Parallel::Tiny->new(
            handler      => $obj,
            workers      => 4,
            worker_total => 100,
        );

    `infinite` can be provided for the `$worker_total` but you will need to manage stopping the fork manager elsewhere.

    If the parent is sent `SIGTERM` it will wait to reap all currently executing children before finishing.

    If the parent is killed, children will receive `SIGHUP`, which you will need to deal with in your `$handler`.

- run()

    Start running a number of parallel workers equal to `$workers`, until a number of workers equal to `$worker_total` have been completed.
