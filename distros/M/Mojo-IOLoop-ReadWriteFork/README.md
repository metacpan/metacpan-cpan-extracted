# NAME

Mojo::IOLoop::ReadWriteFork - Fork a process and read/write from it

# VERSION

2.01

# SYNOPSIS

    use Mojo::Base -strict, -signatures;
    my $rwf = Mojo::IOLoop::ReadWriteFork->new;

    # Emitted if something terrible happens
    $rwf->on(error => sub ($rwf, $error) { warn $error });

    # Emitted when the child completes
    $rwf->on(finish => sub ($rwf, $exit_value, $signal) { Mojo::IOLoop->stop; });

    # Emitted when the child prints to STDOUT or STDERR
    $rwf->on(read => sub ($rwf, $buf) { print qq(Child process sent us "$buf") });

    # Need to set "conduit" for bash, ssh, and other programs that require a pty
    $rwf->conduit({type => 'pty'});

    # Start the application
    $rwf->run('bash', -c => q(echo $YIKES foo bar baz));

    # Using promises
    $rwf->on(read => sub ($rwf, $buf) { ... });
    $rwf->run_p('bash', -c => q(echo $YIKES foo bar baz))->wait;

See also
[https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/tail.pl](https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/tail.pl)
for an example usage from a [Mojo::Controller](https://metacpan.org/pod/Mojo%3A%3AController).

# DESCRIPTION

[Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) enable you to fork a child process and ["read"](#read)
and ["write"](#write) data to. You can also [send signals](#kill) to the child and see
when the process ends. The child process can be an external program (bash,
telnet, ffmpeg, ...) or a CODE block running perl.

## Conduits

[Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) can write to STDIN or a [IO::Pty](https://metacpan.org/pod/IO%3A%3APty) object, and
read from STDOUT or STDERR, depending on the "type" given to ["conduit"](#conduit).

Here is an overview of the different conduits:

- pipe

    The "pipe" type will create a STDIN and a STDOUT conduit using a plain pipe.
    Passing in `stderr` will also create a seperate pipe for STDERR.

        $rwf->conduit({type => 'pipe'});
        $rwf->conduit({type => 'pipe', stderr => 1});
        $rwf->write('some data');        # write to STDIN
        $rwf->on(read   => sub { ... }); # STDOUT and STDERR
        $rwf->on(stdout => sub { ... }); # STDOUT
        $rwf->on(stderr => sub { ... }); # STDERR

    This is useful if you want to run a program like "cat" that simply read/write
    from STDIN, STDERR or STDOUT.

- pty

    The "pty" type will create a STDIN and a STDOUT conduit using [IO::Pty](https://metacpan.org/pod/IO%3A%3APty).
    Passing in "stderr" will also create a seperate pipe for STDERR.

        $rwf->conduit({type => 'pty'});
        $rwf->conduit({type => 'pty', stderr => 1});
        $rwf->write('some data');        # write to STDIN
        $rwf->on(read   => sub { ... }); # STDOUT and STDERR
        $rwf->on(stdout => sub { ... }); # STDOUT
        $rwf->on(stderr => sub { ... }); # STDERR

    The difference between "pipe" and "pty" is that a [IO::Pty](https://metacpan.org/pod/IO%3A%3APty) object will be
    used for STDIN and STDOUT instead of a plain pipe. In addition, it is possible
    to pass in `clone_winsize_from` and `raw`:

        $rwf->conduit({type => 'pty', clone_winsize_from => \*STDOUT, raw => 1});

    This is useful if you want to run "bash" or another program that requires a
    pseudo terminal.

- pty3

    The "pty3" type will create a STDIN, a STDOUT, a STDERR and a PTY conduit.

        $rwf->conduit({type => 'pty3'});
        $rwf->write('some data');        # write to STDIN/PTY
        $rwf->on(pty    => sub { ... }); # PTY
        $rwf->on(stdout => sub { ... }); # STDOUT
        $rwf->on(stderr => sub { ... }); # STDERR

    The difference between "pty" and "pty3" is that there will be a different
    ["read"](#read) event for bytes coming from the pseudo PTY. This type also supports
    "clone\_winsize\_from" and "raw".

        $rwf->conduit({type => 'pty3', clone_winsize_from => \*STDOUT, raw => 1});

    This is useful if you want to run "ssh" or another program that sends password
    prompts (or other output) on the PTY channel. See
    [https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/sshpass](https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/sshpass)
    for an example application.

# EVENTS

## asset

    $rwf->on(asset => sub ($rwf, $asset) { ... });

Emitted at least once when calling ["run\_and\_capture\_p"](#run_and_capture_p). `$asset` can be
either a [Mojo::Asset::Memory](https://metacpan.org/pod/Mojo%3A%3AAsset%3A%3AMemory) or [Mojo::Asset::File](https://metacpan.org/pod/Mojo%3A%3AAsset%3A%3AFile) object.

    $rwf->on(asset => sub ($rwf, $asset) {
      # $asset->auto_upgrade(1) is set by default
      $asset->max_memory_size(1) if $asset->can('max_memory_size');
    });

## drain

    $rwf->on(drain => sub ($rwf) { ... });

Emitted when the buffer has been written to the sub process.

## error

    $rwf->on(error => sub ($rwf, $str) { ... });

Emitted when when the there is an issue with creating, writing or reading
from the child process.

## finish

    $rwf->on(finish => sub ($rwf, $exit_value, $signal) { ... });

Emitted when the child process exit.

## pty

    $rwf->on(pty => sub ($rwf, $buf) { ... });

Emitted when the child has written a chunk of data to a pty and ["conduit"](#conduit) has
"type" set to "pty3".

## prepare

    $rwf->on(prepare => sub ($rwf, $fh) { ... });

Emitted right before the child process is forked. `$fh` can contain the
example hash below or a subset:

    $fh = {
      stderr_read  => $pipe_fh_w_or_pty_object,
      stderr_read  => $stderr_fh_r,
      stdin_read   => $pipe_fh_r,
      stdin_write  => $pipe_fh_r_or_pty_object,
      stdin_write  => $stderr_fh_w,
      stdout_read  => $pipe_fh_w_or_pty_object,
      stdout_read  => $stderr_fh_r,
      stdout_write => $pipe_fh_w,
    };

## read

    $rwf->on(read => sub ($rwf, $buf) { ... });

Emitted when the child has written a chunk of data to STDOUT or STDERR, and
neither "stderr" nor "stdout" is set in the ["conduit"](#conduit).

## spawn

    $rwf->on(spawn => sub ($rwf) { ... });

Emitted after `fork()` has been called. Note that the child process might not yet have
been started. The order of things is impossible to say, but it's something like this:

            .------.
            | fork |
            '------'
               |
           ___/ \_______________
          |                     |
          | (parent)            | (child)
    .--------------.            |
    | emit "spawn" |   .--------------------.
    '--------------'   | set up filehandles |
                       '--------------------'
                                |
                         .---------------.
                         | exec $program |
                         '---------------'

See also ["pid"](#pid) for example usage of this event.

## stderr

    $rwf->on(stderr => sub ($rwf, $buf) { ... });

Emitted when the child has written a chunk of data to STDERR and ["conduit"](#conduit)
has the "stderr" key set to a true value or "type" is set to "pty3".

## stdout

    $rwf->on(stdout => sub ($rwf, $buf) { ... });

Emitted when the child has written a chunk of data to STDOUT and ["conduit"](#conduit)
has the "stdout" key set to a true value or "type" is set to "pty3".

# ATTRIBUTES

## conduit

    $hash = $rwf->conduit;
    $rwf  = $rwf->conduit(\%options);

Used to set the conduit options. Possible values are:

- clone\_winsize\_from

    See ["clone\_winsize\_from" in IO::Pty](https://metacpan.org/pod/IO%3A%3APty#clone_winsize_from). This only makes sense if ["conduit"](#conduit) is set
    to "pty". This can also be specified by using the ["conduit"](#conduit) attribute.

- raw

    See ["set\_raw" in IO::Pty](https://metacpan.org/pod/IO%3A%3APty#set_raw). This only makes sense if ["conduit"](#conduit) is set to "pty".
    This can also be specified by using the ["conduit"](#conduit) attribute.

- stderr

    This will make [Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) emit "stderr" events, instead of
    "read" events. Setting this to "0" will close STDERR in the child.

- stdout

    This will make [Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) emit "stdout" events, instead of
    "read" events. Setting this to "0" will close STDOUT in the child.

- type

    "type" can be either "pipe", "pty" or "pty3". Default value is "pipe".

    See also ["Conduits"](#conduits)

## ioloop

    $ioloop = $rwf->ioloop;
    $rwf    = $rwf->ioloop(Mojo::IOLoop->singleton);

Holds a [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) object.

## pid

    $int = $rwf->pid;

Holds the child process ID. Note that ["start"](#start) will start the process after
the IO loop is started. This means that the code below will not work:

    $rwf->run("bash", -c => q(echo $YIKES foo bar baz));
    warn $rwf->pid; # pid() is not yet set

This will work though:

    $rwf->on(fork => sub ($rwf) { warn $rwf->pid });
    $rwf->run('bash', -c => q(echo $YIKES foo bar baz));

# METHODS

## close

    $rwf = $rwf->close('stdin');

Close STDIN stream to the child process immediately.

## run

    $rwf = $rwf->run($program, @program_args);
    $rwf = $rwf->run(\&Some::Perl::function, @function_args);

Simpler version of ["start"](#start). Can either start an application or run a perl
function.

## run\_and\_capture\_p

    $p = $rwf->run_and_capture_p(...)->then(sub { my $asset = shift });

["run\_and\_capture\_p"](#run_and_capture_p) takes the same arguments as ["run\_p"](#run_p), but the
fullfillment callback will receive a [Mojo::Asset](https://metacpan.org/pod/Mojo%3A%3AAsset) object that holds the
output from the command.

See also the ["asset"](#asset) event.

## run\_p

    $p = $rwf->run_p($program, @program_args);
    $p = $rwf->run_p(\&Some::Perl::function, @function_args);

Promise based version of ["run"](#run). The [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) will be resolved on
["finish"](#finish) and rejected on ["error"](#error).

## start

    $rwf = $rwf->start(\%args);

Used to fork and exec a child process. `%args` can have:

- program

    Either an application or a CODE ref.

- program\_args

    A list of options passed on to ["program"](#program) or as input to the CODE ref.

    Note that this module will start ["program"](#program) with this code:

        exec $program, @$program_args;

    This means that the code is subject for
    [shell injection](https://en.wikipedia.org/wiki/Code_injection#Shell_injection)
    unless invoked with more than one argument. This is considered a feature, but
    something you should be avare of. See also ["exec" in perlfunc](https://metacpan.org/pod/perlfunc#exec) for more details.

- env

    Passing in `env` will override the default set of environment variables,
    stored in `%ENV`.

## write

    $rwf = $rwf->write($chunk);
    $rwf = $rwf->write($chunk, $cb);

Used to write data to the child process STDIN. An optional callback will be
called once the `$chunk` is written.

Example:

    $rwf->write("some data\n", sub ($rwf) { $rwf->close });

## kill

    $bool = $rwf->kill;
    $bool = $rwf->kill(15); # default

Used to signal the child.

# SEE ALSO

[Mojo::IOLoop::ForkCall](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AForkCall).

[https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/tail.pl](https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/examples/tail.pl)

# COPYRIGHT AND LICENSE

Copyright (C) 2013-2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
