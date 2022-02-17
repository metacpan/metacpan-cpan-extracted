# NAME

Mojo::IOLoop::ReadWriteFork - Fork a process and read/write from it

# VERSION

2.00

# SYNOPSIS

    my $fork = Mojo::IOLoop::ReadWriteFork->new;

    # Emitted if something terrible happens
    $fork->on(error => sub { my ($fork, $error) = @_; warn $error; });

    # Emitted when the child completes
    $fork->on(finish => sub { my ($fork, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });

    # Emitted when the child prints to STDOUT or STDERR
    $fork->on(read => sub {
      my ($fork, $buf) = @_;
      print qq(Child process sent us "$buf");
    });

    # Need to set "conduit" for bash, ssh, and other programs that require a pty
    $fork->conduit({type => "pty"});

    # Start the application
    $fork->run("bash", -c => q(echo $YIKES foo bar baz));

    # Using promises
    $fork->on(read => sub { ... });
    $fork->run_p("bash", -c => q(echo $YIKES foo bar baz))->wait;

See also
[https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl](https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl)
for an example usage from a [Mojo::Controller](https://metacpan.org/pod/Mojo%3A%3AController).

# DESCRIPTION

This class enable you to fork a child process and ["read"](#read) and ["write"](#write) data
to. You can also [send signals](#kill) to the child and see when the process
ends. The child process can be an external program (bash, telnet, ffmpeg, ...)
or a CODE block running perl.

[Patches](https://github.com/jhthorsen/mojo-ioloop-readwritefork/pulls) that
enable the ["read"](#read) event to see the difference between STDERR and STDOUT are
more than welcome.

# EVENTS

## stderr

    $fork->on(stderr => sub { my ($fork, $buf) = @_; });

Emitted when the child has written a chunk of data to STDERR and ["conduit"](#conduit)
has the "stderr" key set to a true value.

## stdout

    $fork->on(stdout => sub { my ($fork, $buf) = @_; });

Emitted when the child has written a chunk of data to STDOUT and ["conduit"](#conduit)
has the "stdout" key set to a true value.

## asset

    $fork->on(asset => sub { my ($fork, $asset) = @_; });

Emitted at least once when calling ["run\_and\_capture\_p"](#run_and_capture_p). `$asset` can be
either a [Mojo::Asset::Memory](https://metacpan.org/pod/Mojo%3A%3AAsset%3A%3AMemory) or [Mojo::Asset::File](https://metacpan.org/pod/Mojo%3A%3AAsset%3A%3AFile) object.

    $fork->on(asset => sub {
      my ($fork, $asset) = @_;
      # $asset->auto_upgrade(1) is set by default
      $asset->max_memory_size(1) if $asset->can('max_memory_size');
    });

## error

    $fork->on(error => sub { my ($fork, $str) = @_; });

Emitted when when the there is an issue with creating, writing or reading
from the child process.

## drain

    $fork->on(drain => sub { my ($fork) = @_; });

Emitted when the buffer has been written to the sub process.

## finish

    $fork->on(finish => sub { my ($fork, $exit_value, $signal) = @_; });

Emitted when the child process exit.

## read

    $fork->on(read => sub { my ($fork, $buf) = @_; });

Emitted when the child has written a chunk of data to STDOUT or STDERR, and
neither "stderr" nor "stdout" is set in the ["conduit"](#conduit).

## spawn

    $fork->on(spawn => sub { my ($fork) = @_; });

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

## start

    $fork->on(start => sub { my ($fork, $pipes) = @_; });

Emitted right before the child process is forked. Example `$pipes`

    $pipes = {
      # if "stderr" is set in conduit()
      stdin_write => $stderr_fh_w,
      stdout_read => $stderr_fh_r,

      # for both conduit "pipe" and "pty"
      stdin_write => $pipe_fh_r_or_pty_object,
      stdout_read => $pipe_fh_w_or_pty_object,

      # only for conduit "pipe"
      stdin_read   => $pipe_fh_r,
      stdout_write => $pipe_fh_w,
    }

# ATTRIBUTES

## conduit

    $hash = $fork->conduit;
    $fork = $fork->conduit(\%options);

Used to set the conduit options. Possible values are:

- stderr

    This will make [Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) emit "stderr" events, instead of
    "read" events. Setting this to "0" will close STDERR in the child.

- stdout

    This will make [Mojo::IOLoop::ReadWriteFork](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AReadWriteFork) emit "stdout" events, instead of
    "read" events. Setting this to "0" will close STDOUT in the child.

- raw

    Calls ["set\_raw" in IO::Pty](https://metacpan.org/pod/IO%3A%3APty#set_raw) if "typ" is "pty".

- type

    "type" can be either "pipe" or "pty". Default value is "pipe".

## ioloop

    $ioloop = $fork->ioloop;
    $fork = $fork->ioloop(Mojo::IOLoop->singleton);

Holds a [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) object.

## pid

    $int = $fork->pid;

Holds the child process ID. Note that ["start"](#start) will start the process after
the IO loop is started. This means that the code below will not work:

    $fork->run("bash", -c => q(echo $YIKES foo bar baz));
    warn $fork->pid; # pid() is not yet set

This will work though:

    $fork->on(fork => sub { my $fork = shift; warn $fork->pid });
    $fork->run("bash", -c => q(echo $YIKES foo bar baz));

# METHODS

## close

    $fork = $fork->close("stdin");

Close STDIN stream to the child process immediately.

## run

    $fork = $fork->run($program, @program_args);
    $fork = $fork->run(\&Some::Perl::function, @function_args);

Simpler version of ["start"](#start). Can either start an application or run a perl
function.

## run\_and\_capture\_p

    $p = $fork->run_and_capture_p(...)->then(sub { my $asset = shift });

["run\_and\_capture\_p"](#run_and_capture_p) takes the same arguments as ["run\_p"](#run_p), but the
fullfillment callback will receive a [Mojo::Asset](https://metacpan.org/pod/Mojo%3A%3AAsset) object that holds the
output from the command.

See also the ["asset"](#asset) event.

## run\_p

    $p = $fork->run_p($program, @program_args);
    $p = $fork->run_p(\&Some::Perl::function, @function_args);

Promise based version of ["run"](#run). The [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) will be resolved on
["finish"](#finish) and rejected on ["error"](#error).

## start

    $fork = $fork->start(\%args);

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

- conduit

    Either "pipe" (default) or "pty". "pty" will use [IO::Pty](https://metacpan.org/pod/IO%3A%3APty) to simulate a
    "pty", while "pipe" will just use ["pipe" in perlfunc](https://metacpan.org/pod/perlfunc#pipe). This can also be specified
    by using the ["conduit"](#conduit) attribute.

- clone\_winsize\_from

    See ["clone\_winsize\_from" in IO::Pty](https://metacpan.org/pod/IO%3A%3APty#clone_winsize_from). This only makes sense if ["conduit"](#conduit) is set
    to "pty". This can also be specified by using the ["conduit"](#conduit) attribute.

- raw

    See ["set\_raw" in IO::Pty](https://metacpan.org/pod/IO%3A%3APty#set_raw). This only makes sense if ["conduit"](#conduit) is set to "pty".
    This can also be specified by using the ["conduit"](#conduit) attribute.

## write

    $fork = $fork->write($chunk);
    $fork = $fork->write($chunk, $cb);

Used to write data to the child process STDIN. An optional callback will be
called once STDIN is drained.

Example:

    $fork->write("some data\n", sub { shift->close });

## kill

    $bool = $fork->kill;
    $bool = $fork->kill(15); # default

Used to signal the child.

# SEE ALSO

[Mojo::IOLoop::ForkCall](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AForkCall).

[https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl](https://github.com/jhthorsen/mojo-ioloop-readwritefork/tree/master/example/tail.pl)

# COPYRIGHT AND LICENSE

Copyright (C) 2013-2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
