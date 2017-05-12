package Protocol::SocketIO::Handshake;

use strict;
use warnings;

use overload '""' => sub { $_[0]->to_bytes }, fallback => 1;

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;

    return $self;
}

sub to_bytes {
    my $self = shift;

    $self->{transports}
      ||= [qw/websocket flashsocket htmlfile xhr-polling jsonp-polling/];

    my $transports = join ',', @{$self->{transports}};

    for (qw/session_id heartbeat_timeout close_timeout/) {
        die "$_ is required" unless defined $self->{$_};
    }

    return join ':', $self->{session_id}, $self->{heartbeat_timeout},
      $self->{close_timeout}, $transports;
}

1;
__END__

=head1 NAME

Protocol::SocketIO::Handshake - Socket.IO handshake construction

=head1 SYNOPSIS

    my $handshake = Protocol::SocketIO::Handshake->new(
        session_id        => 1234567890,
        heartbeat_timeout => 10,
        close_timeout     => 15,
        transports        => [qw/websocket xhr-polling/]
    );
    $handshake->to_bytes; # '1234567890:10:15:websocket,xhr-polling';

=head1 METHODS

=head2 C<new>

=head2 C<to_bytes>

=cut
