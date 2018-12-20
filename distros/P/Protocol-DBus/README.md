# NAME

Protocol::DBus - D-Bus in pure Perl

# SYNOPSIS

    my $dbus = Protcol::DBus::Client::system();

For blocking I/O:

    # Authentication and “Hello” call/response:
    $dbus->initialize();

    $dbus->send_call(
        path => '/org/freedesktop/DBus',
        interface => 'org.freedesktop.DBus.Properties',
        member => 'GetAll',
        destination => 'org.freedesktop.DBus',
        signature => 's',
        body => [ 'org.freedesktop.DBus' ],
        on_return => sub { my ($msg) = @_ },
    );

    my $msg = $dbus->get_message();

For non-blocking I/O:

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

# DESCRIPTION

This is an original, pure-Perl implementation of client logic for
[the D-Bus protocol](https://dbus.freedesktop.org/doc/dbus-specification.html).

It’s not much more than an implementation of the wire protocol; it doesn’t
know about objects, services, or anything else besides the actual messages.
That said, what’s here already should allow implementation of anything you
can do with D-Bus; moreover, it would not be difficult to implement
convenience logic—e.g., to mimic interfaces like [Net::DBus](https://metacpan.org/pod/Net::DBus)—on top of
what is here now.

Right now this distribution is an experimental effort. If you use it in your
project, be sure to check the changelog before deploying a new version. Please
file bug reports as appropriate.

See [Protocol::DBus::Client](https://metacpan.org/pod/Protocol::DBus::Client) and the above sample for a starting point.

# EXAMPLES

See the distribution’s `examples/` directory.

# NOTES

- UNIX FD support requires that [Socket::MsgHdr](https://metacpan.org/pod/Socket::MsgHdr) be loaded at
authentication time.
- EXTERNAL and DBUS\_COOKIE\_SHA1 authentication is supported.

# TODO

- Add conveniences like match rule logic.
- Improve parsing of bus paths in environment variables.
- Add more tests.

# SEE ALSO

[Net::DBus](https://metacpan.org/pod/Net::DBus) uses libdbus (via XS) as its backend. It’s more mature and
more idiomatic as to how a D-Bus application is normally written, but
it’s also heavier, and it doesn’t appear to support passing filehandles.
