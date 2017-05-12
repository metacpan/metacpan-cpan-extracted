package # hide from CPAN
    Riemann::Client::Transport;

use Moo;
use Scalar::Util 'blessed';
use IO::Socket::INET;

has host   => (is => 'ro', required => 1);
has port   => (is => 'ro', required => 1);
has socket => (is => 'lazy', clearer => 1);

sub send {
    die 'Not implemented';
}

sub _build_socket {
    my $self  = shift;

    my @elems = split /::/, blessed $self;
    my $proto = $elems[-1];

    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto    => $proto,
    ) or die $!;

    return $sock;
}

1;
