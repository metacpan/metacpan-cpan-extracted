package Protocol::DBus::WriteMsg;

use strict;
use warnings;

use Socket ();

use Protocol::DBus::Socket ();

use parent qw( IO::Framed::Write );

my %fh_fds;

sub DESTROY {
    my ($self) = @_;

    my $fh = delete $fh_fds{ $self->get_write_fh() };

    $self->SUPER::DESTROY() if IO::Framed::Write->can('DESTROY');

    return;
}

sub enqueue_message {
    my ($self, $buf_sr, $fds_ar) = @_;

    push @{ $fh_fds{$self->get_write_fh()} }, ($fds_ar && @$fds_ar) ? $fds_ar : undef;

    $self->write(
        $$buf_sr,
        sub {

            # We’re done with the message, so we remove the FDs entry,
            # which by here should be undef.
            shift @{ $fh_fds{$self->get_write_fh()} };
        },
    );

    return $self;
}

# Receives ($fh, $buf)
sub WRITE {

    # Only use sendmsg if we actually need to.
    if (my $fds_ar = $fh_fds{ $_[0] }[0]) {
        die 'Socket::MsgHdr is not loaded!' if !Socket::MsgHdr->can('new');

        my $msg = Socket::MsgHdr->new( buf => $_[1] );

        $msg->cmsghdr(
            Socket::SOL_SOCKET(), Socket::SCM_RIGHTS(),
            pack( 'I!*', @$fds_ar ),
        );

        my $bytes = Protocol::DBus::Socket::sendmsg_nosignal( $_[0], $msg, 0 );

        # NOTE: This assumes that, on an incomplete write, the ancillary
        # data (i.e., the FDs) will have been sent, and there is no need
        # to resend. That appears to be the case on Linux and MacOS, but
        # I can’t find any actual documentation to that effect. <shrug>
        if ($bytes) {
            undef $fh_fds{ $_[0] }[0];
        }

        return $bytes;
    }

    return Protocol::DBus::Socket::send_nosignal( $_[0], $_[1], 0 );
}

1;
