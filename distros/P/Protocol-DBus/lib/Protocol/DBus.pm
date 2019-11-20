package Protocol::DBus;

use strict;
use warnings;

our $VERSION = '0.11';

=encoding utf8

=head1 NAME

Protocol::DBus - D-Bus in pure Perl

=head1 SYNOPSIS

(NB: Examples below assume use of
L<subroutine signatures|perlsub/Signatures>.)

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

=over

=item * L<Protocol::DBus::Client::IOAsync> (for L<IO::Async>)

=item * L<Protocol::DBus::Client::Mojo> (for L<Mojolicious>)

=item * L<Protocol::DBus::Client::AnyEvent> (for L<AnyEvent>)

=back

Example:

    my $loop = IO::Async::Loop->new();

    Protcol::DBus::Client::IOAsync::login_session($loop)->then(
        sub ($dbus) {
            $dbus->send_call( … );  # same arguments as above
        },
    )->finally( sub { $loop->stop() } );

    $loop->run();

You can also interface with a manually-written event loop.
See L<the example|/EXAMPLE USING MANUALLY-WRITTEN EVENT LOOP> below.

=head1 DESCRIPTION

This is an original, pure-Perl implementation of client messaging logic for
L<the D-Bus protocol|https://dbus.freedesktop.org/doc/dbus-specification.html>.

It’s not much more than an implementation of the wire protocol; it doesn’t
know about objects, services, or anything else besides the actual messages.
This is fine, of course, if all you want to do is, e.g., replace
an invocation of C<gdbus> or C<dbus-send> with pure Perl.

If you want an interface that mimics D-Bus’s actual object system,
you’ll need to implement it yourself or use something like L<Net::DBus>.
(See L</DIFFERENCES FROM Net::DBus> below.)

=head1 STATUS

This project is in BETA status. While the API should be pretty stable now,
breaking changes can still happen. If you use this module
in your project, you B<MUST> check the changelog before deploying a new
version. Please file bug reports as appropriate.

=head1 EXAMPLES

See L<Protocol::DBus::Client> and the above samples for a starting point.

Also see the distribution’s F<examples/> directory.

=head1 DIFFERENCES FROM Net::DBus

L<Net::DBus> is an XS binding to
L<libdbus|https://www.freedesktop.org/wiki/Software/dbus/>,
the reference D-Bus implementation. It is CPAN’s most mature D-Bus
implementation.

There are several reasons why you might prefer this module instead,
though, such as:

=over

=item * Net::DBus discerns how to send a method call via D-Bus introspection.
While handy, this costs extra network overhead and requires an XML parser.
With Protocol::DBus you give a signature directly to send a method call,

=item * Protocol::DBus can work smoothly with any event system you like,
including custom-written ones. (The distribution ships with connectors for
three popular ones.) Net::DBus, on the other hand, expects you to use its
own event loop, L<Net::DBus::Reactor>.

=item * Protocol::DBus has a considerably lighter memory footprint.

=item * Protocol::DBus is pure Perl, so on most OSes you can fat-pack it
for easy distribution.

=item * Protocol::DBus exposes a simpler API.

=back

Of course, there are tradeoffs: most notably, Protocol::DBus’s API is
simpler because it doesn’t attempt to implement D-Bus’s object system.
(You never B<need> the object system, but it can be a useful abstraction.)
An XS-powered D-Bus library is also likely to outperform a
pure-Perl one, introspection overhead notwithstanding. YMMV. BYOB.

=head1 NOTES

=over

=item * UNIX FD support requires that L<Socket::MsgHdr> be loaded at
authentication time.

=item * Certain OSes may require L<Socket::MsgHdr> in order to authenticate
via a UNIX socket. (Linux, notably, does not.) It depends if your OS can
send local socket credentials without using C<sendmsg(2)>.

=item * EXTERNAL and DBUS_COOKIE_SHA1 authentications are supported.

=back

=head1 TODO

=over

=item * Improve parsing of bus paths in environment variables.

=item * Add more tests.

=back

=head1 EXAMPLE USING MANUALLY-WRITTEN EVENT LOOP

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

=cut
