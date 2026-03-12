use v5.42.0;
use feature 'class';
no warnings 'experimental::class';
#
class Noise::Stream v0.0.1 {
    use Noise::CipherState;
    use IO::Socket::INET;
    use Errno qw[EAGAIN EWOULDBLOCK];
    #
    field $socket : param : reader;
    field $c_send : param;    # Noise::CipherState
    field $c_recv : param;    # Noise::CipherState
    field $raw_recv_buffer  = '';
    field $decrypted_buffer = '';
    field $initial_buffer : param //= $raw_recv_buffer;
    #
    ADJUST {
        $socket->blocking(0);
    }

    method write_bin ($data) {
        my $payload  = $c_send->encrypt_with_ad( '', $data );
        my $prefixed = pack( 'n', length($payload) ) . $payload;
        my $written  = 0;
        while ( $written < length($prefixed) ) {
            my $res = syswrite( $socket, $prefixed, length($prefixed) - $written, $written );
            if    ( defined $res )            { $written += $res; }
            elsif ( $! != 11 && $! != 10035 ) { die "SecureStream write error: $!"; }
        }
    }

    method _try_read_frame () {
        if ( length($raw_recv_buffer) < 2 ) {
            my $bytes_read = sysread( $socket, my $buf, 2 - length($raw_recv_buffer) );
            if ( !defined $bytes_read ) {
                return 0 if $! == EAGAIN || $! == EWOULDBLOCK || $! == 10035;
                warn "SecureStream read error (prefix): $!";
                return 0;
            }
            return 0 if $bytes_read == 0;    # EOF
            $raw_recv_buffer .= $buf;
        }
        return 0 if length($raw_recv_buffer) < 2;
        my $len = unpack( 'n', substr( $raw_recv_buffer, 0, 2 ) );
        if ( length($raw_recv_buffer) < ( $len + 2 ) ) {
            my $to_read    = ( $len + 2 ) - length($raw_recv_buffer);
            my $bytes_read = sysread( $socket, my $buf, $to_read );
            if ( !defined $bytes_read ) {
                return 0 if $! == EAGAIN || $! == EWOULDBLOCK || $! == 10035;
                warn "SecureStream read error (payload): $!";
                return 0;
            }
            return 0 if $bytes_read == 0;    # EOF
            $raw_recv_buffer .= $buf;
        }
        if ( length($raw_recv_buffer) >= ( $len + 2 ) ) {
            my $frame = substr( $raw_recv_buffer, 2, $len );
            substr( $raw_recv_buffer, 0, $len + 2, '' );

            # CipherState handles tag extraction and nonce increment
            my $pt = $c_recv->decrypt_with_ad( '', $frame );
            $decrypted_buffer .= $pt;
            return 1;
        }
        return 0;
    }

    method read_bin ( $len = undef ) {
        $self->_try_read_frame();
        if ( defined $len ) {
            return undef if length($decrypted_buffer) < $len;
            my $res = substr( $decrypted_buffer, 0, $len );
            substr( $decrypted_buffer, 0, $len, '' );
            return $res;
        }
        my $res = $decrypted_buffer;
        $decrypted_buffer = '';
        return $res;
    }
    method rekey_send () { $c_send->rekey() }
    method rekey_recv () { $c_recv->rekey() }
    method close ()      { $socket->close() }
};
#
1;
