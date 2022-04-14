# NAME

Protocol::DBus - D-Bus in pure Perl

# SYNOPSIS

(NB: Examples below assume use of
[subroutine signatures](https://metacpan.org/pod/perlsub#Signatures).)

For blocking I/O:

    my $dbus = Protcol::DBus::Client::system();

    # Authentication and “Hello” call/response:
    $dbus->initialize();

    $dbus->send_call(
        path => '/org/freedesktop/DBus',
        interface => 'org.freedesktop.DBus.Properties',
        member => 'GetAll',
        destination => 'org.freedesktop.DBus',
        signature => 's',
        body => [ 'org.freedesktop.DBus' ],
    )->then( sub ($resp_msg) { .. } );

    my $msg = $dbus->get_message();

For non-blocking I/O, it is recommended to use an event loop.
This distribution includes some connectors to simplify that work:

- [Protocol::DBus::Client::IOAsync](https://metacpan.org/pod/Protocol%3A%3ADBus%3A%3AClient%3A%3AIOAsync) (for [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync))
- [Protocol::DBus::Client::Mojo](https://metacpan.org/pod/Protocol%3A%3ADBus%3A%3AClient%3A%3AMojo) (for [Mojolicious](https://metacpan.org/pod/Mojolicious))
- [Protocol::DBus::Client::AnyEvent](https://metacpan.org/pod/Protocol%3A%3ADBus%3A%3AClient%3A%3AAnyEvent) (for [AnyEvent](https://metacpan.org/pod/AnyEvent))

Example:

    my $loop = IO::Async::Loop->new();

    my $dbus = Protcol::DBus::Client::IOAsync::login_session($loop);

    $dbus->initialize()->then(
        sub ($dbus) {
            return $dbus->send_call( … );  # same arguments as above
        },
    )->finally( sub { $loop->stop() } );

    $loop->run();

You can also interface with a manually-written event loop.
See [the example](#example-using-manually-written-event-loop) below.

# DESCRIPTION

<div>
    <a href='https://coveralls.io/github/FGasper/p5-Protocol-DBus?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Protocol-DBus/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

This is an original, pure-Perl implementation of client messaging logic for
[the D-Bus protocol](https://dbus.freedesktop.org/doc/dbus-specification.html).

It’s not much more than an implementation of the wire protocol; it doesn’t
know about objects, services, or anything else besides the actual messages.
This is fine, of course, if all you want to do is, e.g., replace
an invocation of `gdbus` or `dbus-send` with pure Perl.

If you want an interface that mimics D-Bus’s actual object system,
you’ll need to implement it yourself or use something like [Net::DBus](https://metacpan.org/pod/Net%3A%3ADBus).
(See ["DIFFERENCES FROM Net::DBus"](#differences-from-net-dbus) below.)

# STATUS

This project is in BETA status. While the API should be pretty stable now,
breaking changes can still happen. If you use this module
in your project, you **MUST** check the changelog before deploying a new
version. Please file bug reports as appropriate.

# EXAMPLES

See [Protocol::DBus::Client](https://metacpan.org/pod/Protocol%3A%3ADBus%3A%3AClient) and the above samples for a starting point.

Also see the distribution’s `examples/` directory.

# DIFFERENCES FROM Net::DBus

[Net::DBus](https://metacpan.org/pod/Net%3A%3ADBus) is an XS binding to
[libdbus](https://www.freedesktop.org/wiki/Software/dbus/),
the reference D-Bus implementation. It is CPAN’s most mature D-Bus
implementation.

There are several reasons why you might prefer this module instead,
though, such as:

- Net::DBus discerns how to send a method call via D-Bus introspection.
While handy, this costs extra network overhead and requires an XML parser.
With Protocol::DBus you give a signature directly to send a method call.
- Protocol::DBus can work smoothly with any event system you like,
including custom-written ones. (The distribution ships with connectors for
three popular ones.) Net::DBus, on the other hand, expects you to use its
own event loop, [Net::DBus::Reactor](https://metacpan.org/pod/Net%3A%3ADBus%3A%3AReactor).
- Protocol::DBus has a considerably lighter memory footprint.
- Protocol::DBus is pure Perl, so on most OSes you can fat-pack it
for easy distribution.
- Protocol::DBus exposes a simpler API.

Of course, there are tradeoffs: most notably, Protocol::DBus’s API is
simpler because it doesn’t attempt to implement D-Bus’s object system.
(You never **need** the object system, but it can be a useful abstraction.)
An XS-powered D-Bus library is also likely to outperform a
pure-Perl one, introspection overhead notwithstanding. YMMV. BYOB.

# NOTES

- UNIX FD support requires that [Socket::MsgHdr](https://metacpan.org/pod/Socket%3A%3AMsgHdr) be loaded at
authentication time.
- Certain OSes may require [Socket::MsgHdr](https://metacpan.org/pod/Socket%3A%3AMsgHdr) in order to authenticate
via a UNIX socket. (Linux, notably, does not.) It depends if your OS can
send local socket credentials without using [sendmsg(2)](http://man.he.net/man2/sendmsg).
- EXTERNAL and DBUS\_COOKIE\_SHA1 authentications are supported.

# TODO

- Improve parsing of bus paths in environment variables.
- Add more tests.

# EXAMPLE USING MANUALLY-WRITTEN EVENT LOOP

    my $dbus = Protcol::DBus::Client::system();

    $dbus->blocking(0);

    my $fileno = $dbus->fileno();

    # You can use whatever polling method you prefer;
    # the following is just for demonstration:
    vec( my $mask, $fileno, 1 ) = 1;

    while (!$dbus->initialize()) {
        if ($dbus->init_pending_send()) {
            select( undef, my $wout = $mask, undef, undef );
        }
        else {
            select( my $rout = $mask, undef, undef, undef );
        }
    }

    $dbus->send_call( .. );     # same parameters as above

    while (1) {
        my $wout = $dbus->pending_send() || q<>;
        $wout &&= $mask;

        select( my $rout = $mask, $wout, undef, undef );

        if ($wout =~ tr<\0><>c) {
            $dbus->flush_write_queue();
        }

        if ($rout =~ tr<\0><>c) {

            # It’s critical to get_message() until undef is returned.
            1 while $dbus->get_message();
        }
    }

Life is easier if you use someone else’s event loop. :)
