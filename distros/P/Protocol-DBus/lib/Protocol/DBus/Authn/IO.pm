package Protocol::DBus::Authn::IO;

use strict;
use warnings;

use Socket ();

use constant _BUFSIZE => 32768;

sub read_line_from_socket {
    my $from = recv( $_[0], my $buf, _BUFSIZE(), Socket::MSG_PEEK() );
    if (!defined $from) {
        die "recv($_[0], MSG_PEEK): $!";
    }

    my $crlf_at = index $buf, "\r\n";

    my $line;

    if (-1 == $crlf_at) {
        if (length($buf) == _BUFSIZE) {
            die sprintf("No CRLF in %d bytes!", _BUFSIZE());
        }
    }
    else {
        sysread( $_[0], $line, 2 + $crlf_at ) or do {
            die "read($_[0]): $!";
        };
    }

    return $line;
}

1;
