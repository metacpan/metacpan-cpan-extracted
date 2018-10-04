package Protocol::DBus::Connect;

use strict;
use warnings;

use Socket;

use Protocol::DBus::Path ();

sub create_socket {
    my ($address) = @_;

    if ($address =~ m<\Aunix:path=(.+)>) {
        my $path = $1;
        $path =~ s<%([0-9a-fA-F]{2})><chr hex $1>ge;

        socket my $s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0 or do {
            die "socket(AF_UNIX, SOCK_STREAM): $!";
        };

        connect $s, Socket::pack_sockaddr_un($path) or do {
            die "connect($path): $!";
        };

        return $s;
    }

    die "Unrecognized path: $address";
}

1;
