package # hide from CPAN
    Riemann::Client::Transport::UDP;

use Moo;

use Riemann::Client::Protocol;

extends 'Riemann::Client::Transport';

use constant MAX_DTGRM_SIZE => 16384;

sub send {
    my ($self, $msg) = @_;

    # Encode the message
    my $encoded  = Msg->encode($msg);

    if (length $encoded > MAX_DTGRM_SIZE) {
        die 'Message too long';
    }

    # Write to the socket
    my $sock = $self->socket;
    $sock->send($encoded) or die $!;
}

1;
