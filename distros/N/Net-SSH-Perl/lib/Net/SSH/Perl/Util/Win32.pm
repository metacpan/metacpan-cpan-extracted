package Net::SSH::Perl::Util::Win32;

use strict;
use warnings;

use Socket ();
use POSIX ();
use if $^O eq 'MSWin32', Win32 => ();

# Taken from AnyEvent::Util
# Thanks, Mark!
sub _socketpair() {
    # perl's socketpair emulation fails on many vista machines, because
    # vista returns fantasy port numbers.

    for (1..10) {
        socket my $l, Socket::AF_INET(), Socket::SOCK_STREAM(), 0
            or next;

        bind $l, Socket::pack_sockaddr_in 0, "\x7f\x00\x00\x01"
            or next;

        my $sa = getsockname $l
            or next;

        listen $l, 1
            or next;

        socket my $r, Socket::AF_INET(), Socket::SOCK_STREAM(), 0
            or next;

        bind $r, Socket::pack_sockaddr_in 0, "\x7f\x00\x00\x01"
            or next;

        connect $r, $sa
            or next;

        accept my $w, $l
            or next;

        # vista has completely broken peername/sockname that return
        # fantasy ports. this combo seems to work, though.
        (Socket::unpack_sockaddr_in getpeername $r)[0]
            == (Socket::unpack_sockaddr_in getsockname $w)[0]
               or (($! = POSIX::EWOULDBLOCK() && POSIX::EINVAL() ), next);

        # vista example (you can't make this shit up...):
        #(Socket::unpack_sockaddr_in getsockname $r)[0] == 53364
        #(Socket::unpack_sockaddr_in getpeername $r)[0] == 53363
        #(Socket::unpack_sockaddr_in getsockname $w)[0] == 53363
        #(Socket::unpack_sockaddr_in getpeername $w)[0] == 53365

        return ($r, $w);
    }

    ()
}

sub _current_user_win32 {
    my $user;
    eval { $user = Win32::LoginName() };
    return $user;
}

1;
