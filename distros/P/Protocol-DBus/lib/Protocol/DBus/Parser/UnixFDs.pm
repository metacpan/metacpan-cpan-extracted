package Protocol::DBus::Parser::UnixFDs;

use strict;
use warnings;

sub extract_from_msghdr {
    my ($msg) = @_;

    my @all_control = $msg->cmsghdr();

    my @fhs;

    while (@all_control) {
        my ($level, $type, $data) = splice @all_control, 0, 3;
        if ($level != Socket::SOL_SOCKET()) {
            die "Unknown control message level: $level";
        }

        if ($type != Socket::SCM_RIGHTS()) {
            die "Unknown control message type: $type";
        }

        for my $fd ( unpack 'I!*', $data ) {

            # The mode is immaterial except to
            # avoid Perl complaining about STDOUT
            # being reopened as read or something.
            # The kernel should not care.
            open my $fh, '+<&=', $fd or die "open() to reuse FD $fd: $!";

            # Would it be worthwhile to fcntl()
            # here to determine what the actual
            # access mode is and re-open() with
            # that mode?

            push @fhs, $fh;
        }
    }

    return @fhs;
}

1;
