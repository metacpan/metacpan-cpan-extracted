# NAME

Mojo::IOLoop::ReadWriteFork - Fork a process and read/write from it

# VERSION

0.40

# SYNOPSIS

    my $fork = Mojo::IOLoop::ReadWriteFork->new;

    # Emitted if something terrible happens
    $fork->on(error => sub { my ($fork, $error) = @_; warn $error; });

    # Emitted when the child completes
    $fork->on(close => sub { my ($fork, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });

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
    $fork->on(read => sub { ... })->run_p("bash", -c => q(echo $YIKES foo bar baz))->wait;

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

## before\_fork

    $self->on(before_fork => sub { my ($self, $pipes) = @_; });

Emitted right before the child process is forked. Example `$pipes`

    $pipes = {
      # for both conduit "pipe" and "pty"
      stdin_write => $pipe_fh_1_or_pty_object,
      stdout_read => $pipe_fh_2_or_pty_object,

      # only for conduit "pipe"
      stdin_read => $pipe_fh_3,
      stdout_write => $pipe_fh_4,
    }

## close

    $self->on(close => sub { my ($self, $exit_value, $signal) = @_; });

Emitted when the child process exit.

## error

    $self->on(error => sub { my ($self, $str) = @_; });

Emitted when when the there is an issue with creating, writing or reading
from the child process.

## fork

    $self->on(fork => sub { my ($self) = @_; });

Emitted after `fork()` has been called. Note that the child process might not yet have
been started. The order of things is impossible to say, but it's something like this:

            .------.
            | fork |
            '------'
               |
           ___/ \_________________
          |                       |
          | (parent)              | (child)
      .-------------.             |
      | emit "fork" |    .--------------------.
      '-------------'    | set up filehandles |
                         '--------------------'
                                  |
                          .---------------.
                          | exec $program |
                          '---------------'

See also ["pid"](#pid) for example usage of this event.

## read

    $self->on(read => sub { my ($self, $buf) = @_; });

Emitted when the child has written a chunk of data to STDOUT or STDERR.

# ATTRIBUTES

## conduit

    $hash = $self->conduit;
    $self = $self->conduit({type => "pipe"});

Used to set the conduit and conduit options. Example:

    $self->conduit({raw => 1, type => "pty"});

## ioloop

    $ioloop = $self->ioloop;
    $self = $self->ioloop(Mojo::IOLoop->singleton);

Holds a [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) object.

## pid

    $int = $self->pid;

Holds the child process ID. Note that ["start"](#start) will start the process after
the IO loop is started. This means that the code below will not work:

    $fork->run("bash", -c => q(echo $YIKES foo bar baz));
    warn $fork->pid; # pid() is not yet set

This will work though:

    $fork->on(fork => sub { my $self = shift; warn $self->pid });
    $fork->run("bash", -c => q(echo $YIKES foo bar baz));

# METHODS

## close

    $self = $self->close("stdin");

Close STDIN stream to the child process immediately.

## run

    $self = $self->run($program, @program_args);
    $self = $self->run(\&Some::Perl::function, @function_args);

Simpler version of ["start"](#start). Can either start an application or run a perl
function.

## run\_p

    $p = $self->run_p($program, @program_args);
    $p = $self->run_p(\&Some::Perl::function, @function_args);

Promise based version of ["run"](#run). The [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) will be resolved on
["close"](#close) and rejected on ["error"](#error).

## start

    $self = $self->start(\%args);

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

    $self = $self->write($chunk);
    $self = $self->write($chunk, $cb);

Used to write data to the child process STDIN. An optional callback will be
called once STDIN is drained.

Example:

    $self->write("some data\n", sub {
      my ($self) = @_;
      $self->close;
    });

## kill

    $bool = $self->kill;
    $bool = $self->kill(15); # default

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
