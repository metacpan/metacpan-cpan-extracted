use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Transport::TCP v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use IO::Select;
    use Errno;
    field $socket : param : reader;
    field $write_buffer     = '';
    field $read_buffer_size = 0;                    # Track inbound buffer growth
    field $connecting : param  = 1;
    field $filter     : reader = undef;
    my $MAX_WRITE_BUFFER_SIZE = 4 * 1024 * 1024;    # 4 MB
    my $MAX_READ_BUFFER_SIZE  = 4 * 1024 * 1024;    # 4 MB post-handshake inbound limit
    ADJUST {
        if ( $socket && $socket->opened ) {
            $socket->blocking(0);
        }
    }

    method clear_listeners ($event) {

        # This will need to be updated to clear $on from Emitter if needed
        # but Emitter currently doesn't provide a way to clear.
        # For now, let's keep it but it might be broken until Emitter is improved.
    }

    method set_filter ($f) {
        $filter = $f;
    }

    method send_data ($data) {
        if ( $filter && $filter->can('encrypt_data') && $filter->state eq 'PAYLOAD' ) {
            $data = $filter->encrypt_data($data);
        }

        # warn "    [DEBUG] TCP::send_data: " . length($data) . " bytes\n";
        $write_buffer .= $data;
        if ( length($write_buffer) > $MAX_WRITE_BUFFER_SIZE ) {
            $self->_emit_log( 'error', 'Write buffer exceeded maximum size, disconnecting slow peer' );

            # M13: Clear entire buffer to prevent stale data leakage before socket close
            $write_buffer = '';
            $self->_emit('disconnected');
            return 0;
        }
        $self->_flush_write_buffer();
        return length $data;
    }

    method send_raw ($data) {
        $write_buffer .= $data;
        if ( length($write_buffer) > $MAX_WRITE_BUFFER_SIZE ) {
            $self->_emit_log( 'error', 'send_raw: Write buffer exceeded maximum size, disconnecting' );
            $write_buffer = '';
            $self->_emit('disconnected');
            return 0;
        }
        $self->_flush_write_buffer();
        return length $data;
    }

    method _flush_write_buffer () {
        return unless length $write_buffer;
        return if $connecting;
        my $sent = $socket->syswrite($write_buffer);
        if ( defined $sent && $sent > 0 ) {
            substr( $write_buffer, 0, $sent, '' );
        }
        elsif ( defined $sent && $sent == 0 ) {

            # syswrite returned 0 but it's not an error. It does signal no progress was made; retry on next tick
        }
        elsif ( !defined $sent && $! != Errno::EWOULDBLOCK && $! != Errno::EAGAIN ) {
            $self->_emit_log( 'debug', 'TCP write error: ' . $! );
            $self->_emit('disconnected');
        }
    }

    method tick () {
        return unless $socket && $socket->opened;
        if ($connecting) {
            my $sel = IO::Select->new($socket);
            if ( $sel->can_write(0) ) {

                # Check for actual connection success
                use Socket qw[SOL_SOCKET SO_ERROR];
                my $error = $socket->getsockopt( SOL_SOCKET, SO_ERROR );
                if ( $error == 0 ) {
                    $connecting = 0;

                    # warn "    [DEBUG] TCP connection established to " . $socket->peerhost . ":" . $socket->peerport . "\n";
                    $self->_emit('connected');
                }
                else {
                    $! = $error;
                    $self->_emit_log( 'debug', 'TCP connection failed to ' . $socket->peerhost . ':' . $socket->peerport . ": $!" );
                    $self->_emit('disconnected');
                    return;
                }
            }
            else {
                return;
            }
        }

        # If we have a filter, it might have data to send (handshake)
        if ( $filter && $filter->can('write_buffer') ) {
            my $f_buf = $filter->write_buffer();
            if ( length $f_buf ) {
                $write_buffer .= $f_buf;
            }
        }
        $self->_flush_write_buffer();
        my $len = $socket->sysread( my $buffer, 65535 );
        if ( defined $len && $len > 0 ) {
            $read_buffer_size += $len;
            if ( $read_buffer_size > $MAX_READ_BUFFER_SIZE ) {
                $self->_emit_log( 'error', 'Inbound buffer exceeded maximum size, disconnecting' );
                $read_buffer_size = 0;
                $self->_emit('disconnected');
                return;
            }

            # warn "    [DEBUG] TCP::tick received $len bytes\n";
            if ($filter) {
                my $decrypted = $filter->receive_data($buffer);
                if ( $filter->state eq 'PLAINTEXT_FALLBACK' ) {
                    $self->_emit_log( 'debug', 'Transport filter requested plaintext fallback' );
                    my $leftover = $filter->buffer_in;
                    $filter = undef;
                    $self->_emit( 'filter_failed', $leftover );
                    $self->receive_data($leftover);
                    return;
                }
                elsif ( $filter->state eq 'FAILED' ) {
                    $self->_emit_log( 'error', 'Transport filter handshake FAILED' );
                    my $leftover = $filter->buffer_in;
                    $filter = undef;
                    $self->_emit( 'filter_failed', $leftover );

                    # We don't call receive_data($leftover) here because it might be MSE garbage
                    return;
                }
                if ( defined $decrypted && length $decrypted ) {
                    $self->receive_data($decrypted);
                }

                # After receiving, filter might have more to send
                my $f_buf = $filter->write_buffer();
                if ( length $f_buf ) {
                    $write_buffer .= $f_buf;
                    $self->_flush_write_buffer();
                }
            }
            else {
                $self->receive_data($buffer);
            }
            $read_buffer_size = 0 if defined $len;    # Reset after successful processing
        }
        elsif ( defined $len && $len == 0 ) {
            $self->_emit_log( 'debug', 'TCP remote closed connection' );
            $self->_emit('disconnected');
        }
        elsif ( !defined $len && $! != Errno::EWOULDBLOCK && $! != Errno::EAGAIN ) {
            $self->_emit_log( 'debug', "TCP read error: $!" );
            $self->_emit('disconnected');
        }
    }

    method receive_data ($data) {
        $self->_emit( 'data', $data );
    }

    method close () {
        if ( $socket && $socket->opened ) {
            eval { $socket->shutdown(2) };    # SHUT_RDWR
            $socket->close();
        }
    }

    method state () {
        return $socket && $socket->opened ? 'CONNECTED' : 'CLOSED';
    }
};
1;
