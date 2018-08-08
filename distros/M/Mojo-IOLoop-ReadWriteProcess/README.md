[![Build Status](https://travis-ci.org/mudler/Mojo-IOLoop-ReadWriteProcess.svg?branch=master)](https://travis-ci.org/mudler/Mojo-IOLoop-ReadWriteProcess) [![Coverage Status](http://codecov.io/github/mudler/Mojo-IOLoop-ReadWriteProcess/coverage.svg?branch=master)](https://codecov.io/github/mudler/Mojo-IOLoop-ReadWriteProcess?branch=master)
# NAME

Mojo::IOLoop::ReadWriteProcess - Execute external programs or internal code blocks as separate process.

# SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess;

    # Code fork
    my $process = Mojo::IOLoop::ReadWriteProcess->new(sub { print "Hello\n" });
    $process->start();
    print "Running\n" if $process->is_running();
    $process->getline(); # Will return "Hello\n"
    $process->pid(); # Process id
    $process->stop();
    $process->wait_stop(); # if you intend to wait its lifespan

    # Methods can be chained, thus this is valid:
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $output = process( sub { print "Hello\n" } )->start()->wait_stop->getline;

    # Handles seamelessy also external processes:
    my $process = process(execute=> '/path/to/bin' )->args(qw(foo bar baz));
    $process->start();
    my $line_output = $process->getline();
    my $pid = $process->pid();
    $process->stop();
    my @errors = $process->error;

    # Get process return value
    $process = process( sub { return "256"; } )->start()->wait_stop;
    # We need to stop it to retrieve the exit status
    my $return = $process->return_status;

    # We can access directly to handlers from the object:
    my $stdout = $process->read_stream;
    my $stdin = $process->write_stream;
    my $stderr = $process->error_stream;

    # So this works:
    print $stdin "foo bar\n";
    my @lines = <$stdout>;

    # There is also an alternative channel of communication (just for forked processes):
    my $channel_in = $process->channel_in; # write to the child process
    my $channel_out = $process->channel_out; # read from the child process
    $process->channel_write("PING"); # convenience function

# DESCRIPTION

Mojo::IOLoop::ReadWriteProcess is yet another process manager.

# EVENTS

[Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess) inherits all events from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter) and can emit
the following new ones.

## start

    $process->on(start => sub {
      my ($process) = @_;
      $process->is_running();
    });

Emitted when the process starts.

## stop

    $process->on(stop => sub {
      my ($process) = @_;
      $process->restart();
    });

Emitted when the process stops.

## process\_error

    $process->on(process_error => sub {
      my ($e) = @_;
      my @errors = @{$e};
    });

Emitted when the process produce errors.

## process\_stuck

    $process->on(process_stuck => sub {
      my ($self) = @_;
      ...
    });

Emitted when `blocking_stop` is set and all attempts for killing the process
in `max_kill_attempts` have been exhausted.
The event is emitted before attempting to kill it with SIGKILL and becoming blocking.

## SIG\_CHLD

    $process->on(SIG_CHLD => sub {
      my ($self) = @_;
      ...
    });

Emitted when we receive SIG\_CHLD.

## SIG\_TERM

    $process->on(SIG_TERM => sub {
      my ($self) = @_;
      ...
    });

Emitted when the child forked process receives SIG\_TERM, before exiting.

## collected

    $process->on(collected => sub {
      my ($self) = @_;
      ...
    });

Emitted right after status collection.

## collect\_status

    $process->on(collect_status => sub {
      my ($self) = @_;
      ...
    });

Emitted when on child process waitpid.
It is used internally to get the child process status.
Note: events attached to it are wiped when process has been stopped.

# ATTRIBUTES

[Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess) inherits all attributes from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter) and implements
the following new ones.

## execute

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(execute => "/usr/bin/perl");
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

`execute` should contain the external program that you wish to run.

## code

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" } );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

It represent the code you want to run in background.

You do not need to specify `code`, it is implied if no arguments is given.

    my $process = Mojo::IOLoop::ReadWriteProcess->new(sub { print "Hello" });
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

## args

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello ".shift() }, args => "User" );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop();

    # The process will print "Hello User"

Array or arrayref of options to pass by to the external binary or the code block.

## blocking\_stop

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" }, blocking_stop => 1 );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop(); # Will wait indefinitely until the process is stopped

Set it to 1 if you want to do blocking stop of the process.

## channels

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" }, channels => 0 );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop(); # Will wait indefinitely until the process is stopped

Set it to 0 if you want to disable internal channels.

## session

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(sub { print "Hello" });
    my $session = $process->session;
    $session->enable_subreaper;

Returns the current [Mojo::IOLoop::ReadWriteProcess::Session](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess::Session) singleton.

## subreaper

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello ".shift() }, args => "User" );
    $process->subreaper(1)->start();
    $process->on( stop => sub { $_->disable_subreaper } );
    $process->stop();

    # The process will print "Hello User"

Mark the current process (not the child) as subreaper on start.
It's on invoker behalf to disable subreaper when process stops, as it marks the current process and not the
child.

## ioloop

    my $loop    = $process->ioloop;
    $subprocess = $process->ioloop(Mojo::IOLoop->new);

Event loop object to control, defaults to the global [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) singleton.

## max\_kill\_attempts

    use Mojo::IOLoop::ReadWriteProcess;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello" }, max_kill_attempts => 50 );
    $process->start();
    $process->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $process->stop(); # It will attempt to send SIGTERM 50 times.

Defaults to `5`, is the number of attempts before bailing out.

It can be used with blocking\_stop, so if the number of attempts are exhausted,
a SIGKILL and waitpid will be tried at the end.

## collect\_status

Defaults to `1`, If enabled it will automatically collect the status of the children process.
Disable it in case you want to manage your process child directly, and do not want to rely on
automatic collect status. If you won't overwrite your `SIGCHLD` handler,
the `SIG_CHLD` event will be still emitted.

## serialize

Defaults to `0`, If enabled data returned from forked process will be serialized with Storable.

## kill\_sleeptime

Defaults to `1`, it's the seconds to wait before attempting SIGKILL when blocking\_stop is setted to 1.

## separate\_err

Defaults to `1`, it will create a separate channel to intercept process STDERR,
otherwise it will be redirected to STDOUT.

## verbose

Defaults to `1`, it indicates message verbosity.

## set\_pipes

Defaults to `1`, If enabled, additional pipes for process communication are automatically set up.

## internal\_pipes

Defaults to `1`, If enabled, additional pipes for retreiving process return and errors are set up.
Note: If you disable that, the only information provided by the process will be the exit\_status.

## autoflush

Defaults to `1`, If enabled autoflush of handlers is enabled automatically.

## error

Returns a [Mojo::Collection](https://metacpan.org/pod/Mojo::Collection) of errors.
Note: errors that can be captured only at the end of the process

# METHODS

[Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess) inherits all methods from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo::EventEmitter) and implements
the following new ones.

## start()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;

Starts the process

## stop()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start->stop;

Stop the process. Unless you use `wait_stop()`, it will attempt to kill the process
without waiting the process to finish. By defaults it send `SIGTERM` to the child.
You can change that by defining the internal attribute `_default_kill_signal`.
Note, if you want to be \*sure\* that the process gets killed, you can enable the
`blocking_stop` attribute, that will attempt to send `SIGKILL` after `max_kill_attempts`
is reached.

## restart()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->restart;

It restarts the process if stopped, or if already running, it stops it first.

## is\_running()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start;
    $p->is_running;

Boolean, it inspect if the process is currently running or not.

## exit\_status()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( execute => "/path/to/bin" )->start;

    $p->wait_stop->exit_status;

Inspect the process exit status, it does the shifting magic, to access to the real value
call `_status()`.

## return\_status()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process( sub { return 42 } )->start;

    my $s = $p->wait_stop->return_status; # 42

Inspect the codeblock return.

## enable\_subreaper()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process()->enable_subreaper;

Mark the current process (not the child) as subreaper.
This is used typically if you want to mark further childs as subreapers inside other forks.

    my $master_p = process(
      sub {
        my $p = shift;
        $p->enable_subreaper;

        process(sub { sleep 4; exit 1 })->start();
        process(
          sub {
            sleep 4;
            process(sub { sleep 1; })->start();
          })->start();
        process(sub { sleep 4; exit 0 })->start();
        process(sub { sleep 4; die })->start();
        my $manager
          = process(sub { sleep 2 })->subreaper(1)->start();
        sleep 1 for (0 .. 10);
        $manager->stop;
        return $manager->session->all->size;
      });

    $master_p->subreaper(1);

    $master_p->on(collected => sub { $status++ });

    # On start we setup the current process as subreaper
    # So it's up on us to disable it after process is done.
    $master_p->on(stop => sub { shift()->disable_subreaper });
    $master_p->start();

## disable\_subreaper()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process()->disable_subreaper;

Unset the current process (not the child) as subreaper.

## prctl()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process();
    $p->prctl($option, $arg2, $arg3, $arg4, $arg5);

Internal function to execute and wrap the prctl syscall, accepts the same arguments as prctl.

## diag()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" });
    $p->on( stop => sub { shift->diag("Done!") } );
    $p->start->wait_stop;

Internal function to print information to STDERR if verbose attribute is set or either DEBUG mode enabled.
You can use it if you wish to display information on the process status.

## to\_ioloop()

    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $p = process(sub {  print "Hello from first process\n"; sleep 1 });

    $p->start(); # Start and sets the handlers
    my $stream = $p->to_ioloop; # Get the stream and demand to IOLoop
    my $output;

    # Hook on Mojo::IOLoop::Stream events
    $stream->on(read => sub { $output .= pop;  $p->is_running ...  });

    Mojo::IOLoop->singleton->start() unless Mojo::IOLoop->singleton->is_running;

Returns a [Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo::IOLoop::Stream) object and demand the wait operation to [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop).
It needs `set_pipes` enabled. Default IOLoop can be overridden in `ioloop()`.

## wait()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" })->wait;
    # ... here now you can mangle $p handlers and such

Waits until the process finishes, but does not performs cleanup operations (until stop is called).

## wait\_stop()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { print "Hello\n" })->start->wait_stop;
    # $p is not running anymore, and all possible events have been granted to be emitted.

Waits until the process finishes, and perform cleanup operations.

## errored()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { die "Nooo" })->start->wait_stop;
    $p->errored; # will return "1"

Returns a boolean indicating if the process had errors or not.

## write\_pidfile()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { die "Nooo" } );
    $p->pidfile("foobar");
    $p->start();
    $p->write_pidfile();

Forces writing PID of process to specified pidfile in the attributes of the object.
Useful only if the process have been already started, otherwise if a pidfile it's supplied
as attribute, it will be done automatically.

## write\_stdin()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub { my $a = <STDIN>; print STDERR "Hello my name is $a\n"; } )->start;
    $p->write_stdin("Larry");
    $p->read_stderr; # process STDERR will contain: "Hello my name is Larry\n"

Write data to process STDIN.

## write\_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          my $self = shift;
                          my $parent_output = $self->channel_out;
                          my $parent_input  = $self->channel_in;

                          while(defined(my $line = <$parent_input>)) {
                            print $parent_output "PONG\n" if $line =~ /PING/i;
                          }
                      } )->start;
    $p->write_channel("PING");
    my $out = $p->read_channel;
    # $out is PONG
    my $child_output = $p->channel_out;
    while(defined(my $line = <$child_output>)) {
        print "Process is replying back with $line!\n";
        $p->write_channel("PING");
    }

Write data to process channel. Note, it's not STDIN, neither STDOUT, it's a complete separate channel
dedicated to parent-child communication.
In the parent process, you can access to the same pipes (but from the opposite direction):

    my $child_output = $self->channel_out;
    my $child_input  = $self->channel_in;

## read\_stdout()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print "Boo\n"
                      } )->start;
    $p->read_stdout;

Gets a single line from process STDOUT.

## read\_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          my $self = shift;
                          my $parent_output = $self->channel_out;
                          my $parent_input  = $self->channel_in;

                          print $parent_output "PONG\n";
                      } )->start;
    $p->read_channel;

Gets a single line from process channel.

## read\_stderr()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;
    $p->read_stderr;

Gets a single line from process STDERR.

## read\_all\_stdout()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print "Boo\n"
                      } )->start;
    $p->read_all_stdout;

Gets all the STDOUT output of the process.

## read\_all\_channel()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          shift->channel_out->write("Ping")
                      } )->start;
    $p->read_all_channel;

Gets all the channel output of the process.

## read\_all\_stderr()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process(sub {
                          print STDERR "Boo\n"
                      } )->start;
    $p->read_all_stderr;

Gets all the STDERR output of the process.

## send\_signal()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use POSIX;
    my $p = process( execute => "/path/to/bin" )->start;

    $p->send_signal(POSIX::SIGKILL);

Send a signal to the process

# EXPORTS

## parallel()

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $pool = parallel sub { print "Hello\n" } => 5;
    $pool->start();
    $pool->on( stop => sub { print "Process: ".(+shift()->pid)." finished"; } );
    $pool->stop();

Returns a [Mojo::IOLoop::ReadWriteProcess::Pool](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess::Pool) object that represent a group of processes.

It accepts the same arguments as [Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess), and the last one represent the number of processes to generate.

## batch()

    use Mojo::IOLoop::ReadWriteProcess qw(batch);
    my $pool = batch;
    $pool->add(sub { print "Hello\n" });
    $pool->on(stop => sub { shift->_diag("Done!") })->start->wait_stop;

Returns a [Mojo::IOLoop::ReadWriteProcess::Pool](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess::Pool) object generated from supplied arguments.
It accepts as input the same parameter of [Mojo::IOLoop::ReadWriteProcess::Pool](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess::Pool) constructor ( see parallel() ).

## process()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process sub { print "Hello\n" };
    $p->start()->wait_stop;

or even:

    process(sub { print "Hello\n" })->start->wait_stop;

Returns a [Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess) object that represent a process.

It accepts the same arguments as [Mojo::IOLoop::ReadWriteProcess](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess).

## queue()

    use Mojo::IOLoop::ReadWriteProcess qw(queue);
    my $q = queue;
    $q->add(sub { return 42 } );
    $q->consume;

Returns a [Mojo::IOLoop::ReadWriteProcess::Queue](https://metacpan.org/pod/Mojo::IOLoop::ReadWriteProcess::Queue) object that represent a queue.

# DEBUGGING

You can set the MOJO\_EVENTEMITTER\_DEBUG environment variable to get some advanced diagnostics information printed to STDERR.

    MOJO_EVENTEMITTER_DEBUG=1

Also, you can set MOJO\_PROCESS\_DEBUG environment variable to get diagnostics about the process execution.

    MOJO_PROCESS_DEBUG=1

# LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ettore Di Giacinto <edigiacinto@suse.com>
