# NAME

Net::Async::MPD - A non-blocking interface to MPD

# SYNOPSIS

    use Net::Async::MPD;

    my $mpd = Net::Async::MPD->new(
      host => 'localhost',
      auto_connect => 1,
    );

    my @subsystems = qw( player mixer database );

    # Register a listener
    foreach my $subsystem (@subsystems) {
      $mpd->on( $subsystem => sub {
        my ($self) = @_;
        print "$subsystem has changed\n";

        # Stop listening if mixer changes
        $mpd->noidle if $subsystem eq 'mixer';
      });
    }

    # Send a command
    my $stats = $mpd->send( 'stats' );

    # Or in blocking mode
    my $status = $mpd->send( 'status' )->get;

    # Which is the same as
    $status = $mpd->get( 'status' );

    print 'Server is in ', $status->{state}, " state\n";
    print 'Server has ', $stats->get->{albums}, " albums in the database\n";

    # Put the client in looping idle mode
    my $idle = $mpd->idle( @subsystems );

    # Set the emitter in motion, until the next call to noidle
    $idle->get;

# DESCRIPTION

[Net::Async::MPD](https://metacpan.org/pod/Net::Async::MPD) provides a non-blocking interface to an MPD server.

## Command Lists

MPD supports sending command lists to make it easier to perform a series of
steps as a single one. No command is executed until all commands in the list
have been sent, and then the server returns the result for all of them together.
See the
[MPD documentation](https://musicpd.org/doc/protocol/command_lists.html)
for more information.

[Net::Async::MPD](https://metacpan.org/pod/Net::Async::MPD) fully supports sending command lists, and makes it easy to
structure the results received from MPD, or not to if the user so desires. See
the ["send"](#send) method for more information.

## Error Handling

Most operations in this module return [Future](https://metacpan.org/pod/Future) objects, and to keep things
consistent, any errors that are encountered during processing will result in
those futures being failed or canceled as appropriate.

This module _also_ makes use of the events in [Role::EventEmitter](https://metacpan.org/pod/Role::EventEmitter), which
provides it's own method for error handling: the `error` event. Normally,
if a class `does` that role, it is expected that users will register some
listener to the `error` event to handle failures. However, since errors are
alredy being handled by the Futures (one woudl hope), this distribution
registers a dummy listener to the `error` event, and turns into one that is
mostly useful for debugging and monitoring.

Of course, the author cannot really stop overly zealous users from
[unsubscribing](https://metacpan.org/pod/Role::EventEmitter#unsubscribe) the error dummy listener, but
they do so at their own risk.

## Server Responses

MPD normally returns results as a flat list of response lines.
[Net::Async::MPD](https://metacpan.org/pod/Net::Async::MPD) tries to make it easier to provide some structure to these
responses by providing pre-set parser subroutines for each command. Although
the default parser will be fine in most cases, it is possible to override this
with a custom parser, or to disable the parsing entirely to get the raw lines
from the server. For information on how to override the parser, see the
documentation for the ["send"](#send) method.

By default, the results of each command are parsed independently, and passed
to the [Future](https://metacpan.org/pod/Future) returned by the corresponding call to ["send"](#send). This is true
regardless of whether those commands were sent as part of a list or not.

This means that, by default, the [Future](https://metacpan.org/pod/Future) that represents a given call to
["send"](#send) will receive the results of as many commands as were originall sent.

This might not be desireable when eg. sending multiple commands whose results
should be aggregated. In those cases, it is possible to flatten the list by
passing a false value to the `list` option to ["send"](#send) or ["get"](#get).

This means that when calling

    ($stats, $status) = $mpd->get(
      { list => 1 }, # This is the default
      [ 'stats', 'status' ]
    );

`$stats` and `$status` will each have a hash reference with the results
of their respective commands; while when calling

    $combined_list = $mpd->get( { list => 0 }, [
      [ search => artist => '"Tom Waits"'   ],
      [ search => artist => '"David Bowie"' ],
    ]);

`$combined_list` will hold an array reference with the combined results of
both `search` commands.

# ATTRIBUTES

- **host**

    The host to connect to. Defaults to **localhost**.

- **port**

    The port to connect to. Defaults to **6600**.

- **password**

    The password to use to connect to the server. Defaults to undefined, which
    means to use no password.

- **auto\_connect**

    If set to true, the constructor will block until the connection to the MPD
    server has been established. Defaults to false.

# METHODS

- **connect**

    Starts a connection to an MPD server, and returns a [Future](https://metacpan.org/pod/Future) that will be done
    when the connection is complete (or failed if the connection couldn't be
    established). If the client is already connected, this function will return an
    immediately completed Future.

- **send**

        $future = $mpd->send( 'status' );
        $future = $mpd->send( { parser => 'none' }, 'stats' );

        $future = $mpd->send( search => artist => '"Tom Waits"' );

        # Note the dumb string quoting
        $future = $mpd->send( { list => 0 }, [
          [ search => artist => '"Tom Waits"'   ],
          [ search => artist => '"David Bowie"' ],
        ]);

        $future = $mpd->send( \%options, 'stats', sub { ... } );

    Asynchronously sends a command to an MPD server, and returns a [Future](https://metacpan.org/pod/Future). For
    information on what the value of this Future will be, please see the ["Server Responses"](#server-responses) section.

    This method can be called in a number of different ways:

    - If called with a single string, then that string will be sent as the
    command.
    - If called with a list, the list will be joined with spaces and sent as
    the command.
    - If called with an array reference, then the value of each of item in
    that array will be processed as above (with array references instead of plain
    lists).

    If sending multiple commands in one request, the `command_list...` commands
    can be left out and they will be automatically provided for you.

    An optional subroutine reference passed as the last argument will be set as the
    the `on_ready` of the Future, which will fire when there is a response from
    the server.

    A hash reference with additional options can be passed as the _first_
    argument. Valid keys to use are:

    - **list**

        If set to false, results of command lists will be parsed as a single result.
        When set to true, each command in a command list is parsed independently. See
        ["Server Responses"](#server-responses) for more details.

        Defaults to true. This value is ignored when not sending a command list.

    - **parser**

        Specify the parser to use for the _entire_ response. Parser labels are MPD
        commands. If the requested parser is not found, the fallback `none` will be
        used.

        Alternatively, if the value itself is a code reference, then that will be
        called as

            $parser->( \@response_lines, \@command_names );

        Where each element in `@response_lines` is a reference to the list of lines
        received after completing the corresponding element in `@command_names`.

        When setting `list` to false, `@response_lines` will have a single value,
        regardless of how many commands were sent.

    For ease of use, underscores in the final command name will be removed before
    sending to the server (unless the command name requires them). So

        $client->send( 'current_song' );

    is entirely equivalent to

        $client->send( 'currentsong' );

- **get**

    Send a command in a blocking way. Internally calls **send** and immediately
    waits for the response.

- **idle**

    Put the client in idle loop. This sends the `idle` command and registers an
    internal listener that will put the client back in idle mode after each server
    response.

    If called with a list of subsystem names, then the client will only listen to
    those subsystems. Otherwise, it will listen to all of them.

    If you are using this module for an event-based application (see below), this
    will configure the client to fire the events at the appropriate times.

    Returns a [Future](https://metacpan.org/pod/Future). Waiting on this future will block until the next call to
    **noidle** (see below).

- **noidle**

    Cancel the client's idle mode. Sends an undefined value to the future created
    by **idle** and breaks the internal idle loop.

- **version**

    Returns the version number of the protocol spoken by the server, and _not_ the
    version of the daemon.

    As this is provided by the server, this is `undef` until after a connection
    has been established with the `connect` method, or by setting `auto_connect`
    to true in the constructor.

# EVENTS

[Net::Async::MPD](https://metacpan.org/pod/Net::Async::MPD) does the [Role::EventEmitter](https://metacpan.org/pod/Role::EventEmitter) role, and inherits all the
methods defined therein. Please refer to that module's documentation for
information on how to register subscribers to the different events.

## Additional methods

- **until**

    In addition to methods like `on` and `once`, provided by
    [Role::EventEmitter](https://metacpan.org/pod/Role::EventEmitter), this module also exposes an `until` method, which
    registers a listener until a certain condition is true, and then deregisters it.

    The method is called with two subroutine references. The first is subscribed
    as a regular listener, and the second is called only when the first one returns
    a true value. At that point, the entire set is unsubscribed.

## Event descriptions

After calling **idle**, the client will be in idle mode, which means that any
changes to the specified subsystems will trigger a signal. When the client
receives this signal, it will fire an event named like the subsystem that fired
it.

The event will be fired with the client as the first argument, and the response
from the server as the second argument. This can safely be ignored, since the
server response will normally just hold the name of the subsystem that changed,
which you already know.

The existing events are the following, as defined by the MPD documentation.

- **database**

    The song database has been changed after **update**.

- **udpate**

    A database update has started or finished. If the database was modified during
    the update, the **database** event is also emitted.

- **stored\_playlist**

    A stored playlist has been modified, renamed, created or deleted.

- **playlist**

    The current playlist has been modified.

- **player**

    The player has been started stopped or seeked.

- **mixer**

    The volume has been changed.

- **output**

    An audio output has been added, removed or modified (e.g. renamed, enabled or
    disabled)

- **options**

    Options like repeat, random, crossfade, replay gain.

- **partition**

    A partition was added, removed or changed.

- **sticker**

    The sticker database has been modified.

- **subscription**

    A client has subscribed or unsubscribed from a channel.

- **message**

    A message was received on a channel this client is subscribed to.

## Other events

- **close**

    The connection to the server has been closed. This event is not part of the
    MPD protocol, and is fired by [Net::Async::MPD](https://metacpan.org/pod/Net::Async::MPD) directly.

- **error**

    The `error` event is inherited from [Role::EventEmitter](https://metacpan.org/pod/Role::EventEmitter). However, unlike
    stated in that module's documentation, and as explained in ["Error Handling"](#error-handling),
    users are _not_ required to register to this event for safe execution.

# SEE ALSO

- [AnyEvent::Net::MPD](https://metacpan.org/pod/AnyEvent::Net::MPD)

    A previous attempt at writing this distribution, based on [AnyEvent](https://metacpan.org/pod/AnyEvent). Although
    the design is largely the same, it is not as fully featured or as well tested
    as this one.

- [Net::MPD](https://metacpan.org/pod/Net::MPD)

    A lightweight blocking MPD library. Has fewer dependencies than this one, but
    it does not curently support command lists. I took the idea of allowing for
    underscores in command names from this module.

- [AnyEvent::Net::MPD](https://metacpan.org/pod/AnyEvent::Net::MPD)

    The original version of this module, which used [AnyEvent](https://metacpan.org/pod/AnyEvent). The interface on
    both of these modules is virtually identical.

- [Audio::MPD](https://metacpan.org/pod/Audio::MPD)

    The first MPD library on CPAN. This one also blocks and is based on [Moose](https://metacpan.org/pod/Moose).
    However, it seems to be unmaintained at the moment.

- [Dancer::Plugin::MPD](https://metacpan.org/pod/Dancer::Plugin::MPD)

    A [Dancer](https://metacpan.org/pod/Dancer) plugin to connect to MPD. Haven't really tried it, since I
    haven't used Dancer...

- [POE::Component::Client::MPD](https://metacpan.org/pod/POE::Component::Client::MPD)

    A [POE](https://metacpan.org/pod/POE) component to connect to MPD. This uses Audio::MPD in the background.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
