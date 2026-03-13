use v5.36;
package Remote::Perl::FlowControl;
our $VERSION = '0.003';

# Credit-based flow control.  Each stream has a budget of bytes the sender
# is allowed to transmit before the receiver must grant more.
#
# "send credits"  -- bytes we are allowed to send on a given stream
#                   (incremented when remote sends CREDIT messages to us)
# "recv pending"  -- bytes we have received but not yet acknowledged back;
#                   once this crosses half the window we issue a CREDIT grant

sub new($class, %args) {
    return bless {
        window_size   => $args{window_size} // 65_536,
        send_credits  => {},   # stream_id => bytes remaining
        recv_pending  => {},   # stream_id => bytes consumed since last grant
    }, $class;
}

# Called at handshake time: remote has granted us $credits bytes on $stream.
sub init_stream($self, $stream, $credits = undef) {
    $credits //= $self->{window_size};
    $self->{send_credits}{$stream} = $credits;
    $self->{recv_pending}{$stream} = 0;
}

# How many bytes we may currently send on $stream.
sub send_credit($self, $stream) {
    return $self->{send_credits}{$stream} // 0;
}

# Deduct $n bytes from our send budget.  Dies if budget is insufficient.
sub consume_send_credit($self, $stream, $n) {
    my $have = $self->{send_credits}{$stream} // 0;
    die "Flow control: send credit exhausted on stream $stream "
      . "(have $have, want $n)\n"
      if $n > $have;
    $self->{send_credits}{$stream} = $have - $n;
}

# Remote sent us a CREDIT message granting $n more bytes on $stream.
sub add_send_credit($self, $stream, $n) {
    $self->{send_credits}{$stream} = ($self->{send_credits}{$stream} // 0) + $n;
}

# We just received $n bytes of data on $stream.
# Returns the number of bytes to grant back (0 if not yet time).
# Caller must send a CREDIT message with this value when non-zero.
sub receive_data($self, $stream, $n) {
    $self->{recv_pending}{$stream} = ($self->{recv_pending}{$stream} // 0) + $n;
    if ($self->{recv_pending}{$stream} >= $self->{window_size} / 2) {
        my $grant = $self->{recv_pending}{$stream};
        $self->{recv_pending}{$stream} = 0;
        return $grant;
    }
    return 0;
}

# Force-grant all outstanding pending bytes back (e.g. at stream close).
sub flush_recv_pending($self, $stream) {
    my $grant = $self->{recv_pending}{$stream} // 0;
    $self->{recv_pending}{$stream} = 0;
    return $grant;
}

1;

__END__

=head1 NAME

Remote::Perl::FlowControl - credit-based flow control (internal part of Remote::Perl)

=head1 DESCRIPTION

Tracks per-stream send and receive credits for the protocol pipe.  Senders block
when credits are exhausted; the remote grants more credits as it consumes data.

=head1 INTERNAL

Not public API.  This is an internal module used by L<Remote::Perl>; its interface
may change without notice.

=cut
