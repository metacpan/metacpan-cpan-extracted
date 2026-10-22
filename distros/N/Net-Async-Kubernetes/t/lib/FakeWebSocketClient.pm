package FakeWebSocketClient;
# A stand-in for Net::Async::WebSocket::Client: records what the session
# sends, lets the test emit frames, and optionally answers writes (on_send).
use strict;
use warnings;
use parent 'IO::Async::Notifier';
use Future;

sub configure {
    my ($self, %params) = @_;
    for my $name (qw(
        on_binary_frame on_text_frame on_close_frame
        on_read_error on_write_error on_closed
    )) {
        $self->{$name} = delete $params{$name} if exists $params{$name};
    }
    $self->SUPER::configure(%params);
}

# With $FakeWebSocketClient::HOLD set, connect stays pending and the
# client is queued in @FakeWebSocketClient::PENDING for the test to release.
our $HOLD;
our @PENDING;

sub connect {
    my ($self, %args) = @_;
    $self->{connect_args} = \%args;
    if ($HOLD) {
        my $f = Future->new;
        push @PENDING, [$self, $f];
        return $f;
    }
    return Future->done($self);
}

sub connect_args { $_[0]->{connect_args} }
sub on_send      { $_[0]->{on_send} = $_[1] }

sub send_binary_frame {
    my ($self, $bytes) = @_;
    push @{$self->{sent_binary}}, $bytes;
    $self->{on_send}->($self, $bytes) if $self->{on_send};
    return Future->done(1);
}

sub send_close_frame {
    my ($self, $bytes) = @_;
    push @{$self->{sent_close}}, $bytes;
    return Future->done(1);
}

sub close_when_empty { $_[0]->{closed_when_empty}++ }

sub sent_binary       { $_[0]->{sent_binary} || [] }
sub sent_close        { $_[0]->{sent_close}  || [] }
sub closed_when_empty { $_[0]->{closed_when_empty} || 0 }

sub emit_binary {
    my ($self, $bytes) = @_;
    $self->{on_binary_frame}->($self, $bytes) if $self->{on_binary_frame};
}

sub emit_close {
    my ($self, $payload) = @_;
    $self->{on_close_frame}->($self, $payload // '') if $self->{on_close_frame};
}

1;
