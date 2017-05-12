package Net::Marathon::Events;

use AnyEvent::Handle;
use IO::All '-tie';

sub new {
    my ( $class, $parent ) = @_;
    return bless { callbacks => [], parent => $parent };
}

sub register {
    my ($self, $callback) = @_;
    push @{$self->callbacks}, $callback;
}

sub callbacks {
    my ($self) = @_;
    return wantarray ? @{$self->{callbacks}} : $self->{callbacks};
}

sub start {
    my ($self, $cv) = @_;

    my ($addr) = $self->{parent}{_url} =~ m{ https?://([^/]+) }x;
    my $addr_port = $addr;
    if ($addr !~ /:/) {
        if ($marathon_url =~ /^https/) {
            $addr_port .= '443';
        }
        else { # =~ /^http/
            $addr_port .= ':80';
        }
    }

    my $io = io($addr_port);
    $io->print("GET /v2/events HTTP/1.1\nAccept: text/event-stream\nHost: $addr\n\n");
    while (<$io>) {
        last if /^\s*$/;
    }
    my $watcher = AE::io $io->io_handle, 0, sub {
        my $text = <$io>;
        foreach ( $self->callbacks ) {
            $_->($text);
        }
    };
    return $watcher;
}

1;
