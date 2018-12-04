package Protocol::DBus;

use strict;
use warnings;

our $VERSION = '0.06';

=encoding utf8

=head1 NAME

Protocol::DBus - D-Bus in pure Perl

=head1 SYNOPSIS

    my $dbus = Protcol::DBus::Client::system();

For blocking I/O:

    $dbus->do_authn();

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

    while (!$dbus->do_authn()) {
        if ($dbus->authn_pending_send()) {
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

=head1 DESCRIPTION

This is an original, pure-Perl implementation of client logic for
L<the D-Bus protocol|https://dbus.freedesktop.org/doc/dbus-specification.html>.

It’s not much more than an implementation of the wire protocol; it doesn’t
know about objects, services, or anything else besides the actual messages.
That said, what’s here already should allow implementation of anything you
can do with D-Bus; moreover, it would not be difficult to implement
convenience logic—e.g., to mimic interfaces like L<Net::DBus>—on top of
what is here now.

Right now this distribution is an experimental effort. If you use it in your
project, be sure to check the changelog before deploying a new version. Please
file bug reports as appropriate.

See L<Protocol::DBus::Client> and the above sample for a starting point.

=head1 EXAMPLES

See the distribution’s F<examples/> directory.

=head1 NOTES

=over

=item * UNIX FD support requires that L<Socket::MsgHdr> be loaded at
authentication time.

=item * Currently EXTERNAL is the only supported authentication mechanism.

=back

=head1 TODO

=over

=item * Add conveniences like match rule logic.

=item * Improve parsing of bus paths in environment variables.

=item * Add DBUS_COOKIE_SHA1 authentication.

=item * Add more tests.

=back

=head1 SEE ALSO

L<Net::DBus> uses libdbus (via XS) as its backend. It’s more mature and
more idiomatic as to how a D-Bus application is normally written, but
it’s also heavier, and it doesn’t appear to support passing filehandles.

=cut
