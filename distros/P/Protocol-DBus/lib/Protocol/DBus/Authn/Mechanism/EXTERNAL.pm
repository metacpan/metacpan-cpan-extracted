package Protocol::DBus::Authn::Mechanism::EXTERNAL;

use strict;
use warnings;

use parent 'Protocol::DBus::Authn::Mechanism';

use Protocol::DBus::Socket ();

# The methods of user credential retrieval that the reference D-Bus
# server relies on prefer “out-of-band” methods like SO_PEERCRED
# on Linux rather than SCM_CREDS. (See See dbus/dbus-sysdeps-unix.c.)
# So for some OSes it’s just not necessary to do anything special to
# send credentials.
#
# This list is exposed for the sake of tests.
#
our @_OS_NO_MSGHDR_LIST = (

    # Reference server doesn’t need our help:
    'linux',
    'netbsd',   # via LOCAL_PEEREID, which dbus calls

    # MacOS works, though … ??
    'darwin',

    # 'openbsd', ??? Still trying to test.

    # No way to pass credentials via UNIX socket,
    # so let’s just send EXTERNAL and see what happens.
    # It’ll likely just fail over to DBUS_COOKIE_SHA1.
    'cygwin',
    'mswin32',
);

sub INITIAL_RESPONSE { unpack 'H*', $> }

# The reference server implementation does a number of things to try to
# fetch the peer credentials. .
sub must_send_initial {
    my ($self) = @_;

    if (!defined $self->{'_must_send_initial'}) {

        my $can_skip_msghdr = grep { $_ eq $^O } @_OS_NO_MSGHDR_LIST;

        $can_skip_msghdr ||= eval { my $v = Socket::SO_PEERCRED(); 1 };
        $can_skip_msghdr ||= eval { my $v = Socket::LOCAL_PEEREID(); 1 };

        if (!$can_skip_msghdr) {
            my $ok = eval {
                require Socket::MsgHdr;
                Socket::MsgHdr->VERSION(0.05);
            };

            if (!$ok) {
                $self->{'_failed_socket_msghdr'} = $@;
                $can_skip_msghdr = 1;
            }
        }

        # As of this writing it seems FreeBSD and DragonflyBSD do require
        # Socket::MsgHdr, even though they both have LOCAL_PEERCRED which
        # should take care of that.
        $self->{'_must_send_initial'} = !$can_skip_msghdr;
    }

    return $self->{'_must_send_initial'};
}

sub on_rejected {
    my ($self) = @_;

    if ($self->{'_failed_socket_msghdr'}) {
        warn "EXTERNAL authentication failed. Socket::MsgHdr failed to load earlier; maybe making it available would fix this? (Load failure was: $self->{'_failed_socket_msghdr'})";
    }

    return;
}

sub send_initial {
    my ($self, $s) = @_;

    my $msg = Socket::MsgHdr->new( buf => "\0" );

    # The kernel should fill in the payload.
    $msg->cmsghdr( Socket::SOL_SOCKET(), Socket::SCM_CREDS(), "\0" x 64 );

    local $!;
    my $ok = Protocol::DBus::Socket::sendmsg_nosignal($s, $msg, 0);

    if (!$ok && !$!{'EAGAIN'}) {
        die "sendmsg($s): $!";
    }

    return $ok;
}

1;
