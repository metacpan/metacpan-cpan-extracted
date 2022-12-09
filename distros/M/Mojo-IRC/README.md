# NAME

Mojo::IRC - IRC Client for the Mojo IOLoop

# VERSION

0.46

# SYNOPSIS

    my $irc = Mojo::IRC->new(
                nick => 'test123',
                user => 'my name',
                server => 'irc.perl.org:6667',
              );

    $irc->on(irc_join => sub {
      my($self, $message) = @_;
      warn "yay! i joined $message->{params}[0]";
    });

    $irc->on(irc_privmsg => sub {
      my($self, $message) = @_;
      say $message->{prefix}, " said: ", $message->{params}[1];
    });

    $irc->connect(sub {
      my($irc, $err) = @_;
      return warn $err if $err;
      $irc->write(join => '#mojo');
    });

    Mojo::IOLoop->start;

# DESCRIPTION

[Mojo::IRC](https://metacpan.org/pod/Mojo%3A%3AIRC) is a non-blocking IRC client using [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop) from the
wonderful [Mojolicious](https://metacpan.org/pod/Mojolicious) framework.

It features IPv6 and TLS, with additional optional modules:
[IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) and [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL).

By default this module will only emit standard IRC events, but by
settings ["parser"](#parser) to a custom object it will also emit CTCP events.
Example:

    my $irc = Mojo::IRC->new;
    $irc->parser(Parse::IRC->new(ctcp => 1);
    $irc->on(ctcp_action => sub {
      # ...
    });

It will also set up some default events: ["ctcp\_ping"](#ctcp_ping), ["ctcp\_time"](#ctcp_time),
and ["ctcp\_version"](#ctcp_version).

This class inherits from [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter).

# TESTING

The module [Test::Mojo::IRC](https://metacpan.org/pod/Test%3A%3AMojo%3A%3AIRC) is useful if you want to write tests without
having a running IRC server.

[MOJO\_IRC\_OFFLINE](https://metacpan.org/pod/MOJO_IRC_OFFLINE) (from v0.20) is now DEPRECATED in favor of
[Test::Mojo::IRC](https://metacpan.org/pod/Test%3A%3AMojo%3A%3AIRC).

# EVENTS

## close

    $self->on(close => sub { my ($self) = @_; });

Emitted once the connection to the server closes.

## error

    $self->on(error => sub { my ($self, $err) = @_; });

Emitted once the stream emits an error.

## message

    $self->on(message => sub { my ($self, $msg) = @_; });

Emitted when a new IRC message arrives. Will dispatch to a default handler,
which will again emit ["err\_event\_name"](#err_event_name) ["ctcp\_event\_name"](#ctcp_event_name) and
["irc\_event\_name"](#irc_event_name) below.

Here is an example `$msg`:

    {
      command  => "PRIVMSG",
      event    => "privmsg",
      params   => ["#convos", "hey!"],
      prefix   => "jan_henning",
      raw_line => ":jan_henning PRIVMSG #convos :hey",
    }

## err\_event\_name

Events that start with "err\_" are emitted when there is an IRC response that
indicates an error. See [Mojo::IRC::Events](https://metacpan.org/pod/Mojo%3A%3AIRC%3A%3AEvents) for sample events.

## ctcp\_event\_name

Events that start with "ctcp\_" are emitted if the ["parser"](#parser) can understand
CTCP messages, and there is a CTCP response.

    $self->parser(Parse::IRC->new(ctcp => 1);

See [Mojo::IRC::Events](https://metacpan.org/pod/Mojo%3A%3AIRC%3A%3AEvents) for sample events.

## irc\_event\_name

Events that start with "irc\_" are emitted when there is a normal IRC response.
See [Mojo::IRC::Events](https://metacpan.org/pod/Mojo%3A%3AIRC%3A%3AEvents) for sample events.

# ATTRIBUTES

## connect\_timeout

    $int = $self->connect_timeout;
    $self = $self->connect_timeout(60);

Maximum amount of time in seconds establishing a connection may take before
getting canceled, defaults to the value of the `MOJO_IRC_CONNECT_TIMEOUT`
environment variable or 30.

## ioloop

Holds an instance of [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop).

## local\_address

    $str = $self->local_address;
    $self = $self->local_address("10.20.30.40");

Local address to bind to. See ["local\_address" in Mojo::IOLoop::Client](https://metacpan.org/pod/Mojo%3A%3AIOLoop%3A%3AClient#local_address).

## name

The name of this IRC client. Defaults to "Mojo IRC".

## nick

IRC nick name accessor. Default to ["user"](#user).

## parser

    $self = $self->parser($obj);
    $self = $self->parser(Parse::IRC->new(ctcp => 1));
    $obj = $self->parser;

Holds a [Parse::IRC](https://metacpan.org/pod/Parse%3A%3AIRC) object by default.

## pass

Password for authentication

## real\_host

Will be set by ["irc\_rpl\_welcome"](#irc_rpl_welcome). Holds the actual hostname of the IRC
server that we are connected to.

## server

Server name and, optionally, a port to connect to. Changing this while
connected to the IRC server will issue a reconnect.

## server\_settings

    $hash = $self->server_settings;

Holds information about the server. See
[https://github.com/jhthorsen/mojo-irc/blob/master/t/ua-channel-users.t](https://github.com/jhthorsen/mojo-irc/blob/master/t/ua-channel-users.t) for
example data structure.

Note that this attribute is EXPERIMENTAL and the structure of the values it
holds.

## user

IRC username. Defaults to current logged in user or falls back to "anonymous".

## tls

    $self->tls(undef) # disable (default)
    $self->tls({}) # enable

Default is "undef" which disables TLS. Setting this to an empty hash will
enable TLS and this module will load in default certs. It is also possible
to set custom cert/key:

    $self->tls({ cert => "/path/to/client.crt", key => ... })

This can be generated using

    # certtool --generate-privkey --outfile client.key
    # certtool --generate-self-signed --load-privkey client.key --outfile client.crt

To disable the verification of server certificates, the "insecure" option
can be set:

    $self->tls({insecure => 1});

# METHODS

## connect

    $self = $self->connect(\&callback);

Will log in to the IRC ["server"](#server) and call `&callback`. The
`&callback` will be called once connected or if connect fails. The second
argument will be an error message or empty string on success.

## ctcp

    $str = $self->ctcp(@str);

This message will quote CTCP messages. Example:

    $self->write(PRIVMSG => nickname => $self->ctcp(TIME => time));

The code above will write this message to IRC server:

    PRIVMSG nickname :\001TIME 1393006707\001

## disconnect

    $self->disconnect(\&callback);

Will disconnect form the server and run the callback once it is done.

## new

    $self = Mojo::IRC->new(%attrs);

Object constructor.

## register\_default\_event\_handlers

    $self->register_default_event_handlers;

This method sets up the default ["DEFAULT EVENT HANDLERS"](#default-event-handlers) unless someone has
already subscribed to the event.

## write

    $self->write(@str, \&callback);

This method writes a message to the IRC server. `@str` will be concatenated
with " " and "\\r\\n" will be appended. `&callback` is called once the message is
delivered over the stream. The second argument to the callback will be
an error message: Empty string on success and a description on error.

## write\_p

    $promise = $self->write_p(@str);

Like ["write"](#write), but returns a [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) instead of taking a callback.
The promise will be resolved on success, or rejected with the error message on
error.

# DEFAULT EVENT HANDLERS

## ctcp\_ping

Will respond to the sender with the difference in time.

    Ping reply from $sender: 0.53 second(s)

## ctcp\_time

Will respond to the sender with the current localtime. Example:

    TIME Fri Feb 21 18:56:50 2014

NOTE! The localtime format may change.

## ctcp\_version

Will respond to the sender with:

    VERSION Mojo-IRC $VERSION

NOTE! Additional information may be added later on.

## irc\_nick

Used to update the ["nick"](#nick) attribute when the nick has changed.

## irc\_notice

Responds to the server with "QUOTE PASS ..." if the notice contains "Ident
broken...QUOTE PASS...".

## irc\_ping

Responds to the server with "PONG ...".

## irc\_rpl\_isupport

Used to populate ["server\_settings"](#server_settings) with information about the server.

## irc\_rpl\_welcome

Used to get the hostname of the server. Will also set up automatic PING
requests to prevent timeout and update the ["nick"](#nick) attribute.

## err\_nicknameinuse

This handler will add "\_" to the failed nick before trying to register again.

# COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Marcus Ramberg - `mramberg@cpan.org`

Jan Henning Thorsen - `jhthorsen@cpan.org`
