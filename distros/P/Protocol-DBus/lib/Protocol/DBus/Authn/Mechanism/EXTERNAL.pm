package Protocol::DBus::Authn::Mechanism::EXTERNAL;

use strict;
use warnings;

use parent 'Protocol::DBus::Authn::Mechanism';

sub INITIAL_RESPONSE { unpack 'H*', $> }

sub AFTER_OK {
    my ($self) = @_;

    return if $self->{'_skip_unix_fd'};

    return (
        [ 0 => 'NEGOTIATE_UNIX_FD' ],
        [ 1 => \&_consume_agree_unix_fd ],
    );
}

sub new {
    my $self = $_[0]->SUPER::new(@_[ 1 .. $#_ ]);

    $self->{'_skip_unix_fd'} = 1 if !Socket::MsgHdr->can('new') || !Socket->can('SCM_RIGHTS');

    return $self;
}

sub _consume_agree_unix_fd {
    my ($authn, $line) = @_;

    if ($line eq 'AGREE_UNIX_FD') {
        $authn->{'_negotiated_unix_fd'} = 1;
    }
    elsif (index($line, 'ERROR ') == 0) {
        warn "Server rejected unix fd passing: " . substr($line, 6) . $/;
    }

    return;
}

sub skip_unix_fd {
    my ($self) = @_;

    $self->{'_skip_unix_fd'} = 1;

    return $self;
}

sub must_send_initial {
    my ($self) = @_;

    if (!defined $self->{'_must_send_initial'}) {

        # On Linux and BSD OSes this module doesn’t need to make any special
        # effort to send credentials because the server will request them on
        # its own. (Although Linux only sends the real credentials, we’ll
        # send the EUID in the EXTERNAL handshake.)
        #
        my $can_skip_msghdr = Socket->can('SCM_CREDENTIALS');

        # MacOS doesn’t appear to have an equivalent to SO_PASSCRED
        # but does have SCM_CREDS, so we have to blacklist it specifically.
        $can_skip_msghdr ||= Socket->can('SCM_CREDS') && !grep { $^O eq $_ } qw( darwin cygwin );

        $self->{'_must_send_initial'} = !$can_skip_msghdr;
    }

    return $self->{'_must_send_initial'};
}

sub send_initial {
    my ($self) = @_;

    # There are no known platforms where sendmsg will achieve anything
    # that plain write() doesn’t already get us.
    die "Unsupported OS: $^O";
}

1;
