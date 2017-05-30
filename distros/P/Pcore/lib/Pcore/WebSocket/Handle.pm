package Pcore::WebSocket::Handle;

use Pcore -const, -role, -result;
use Pcore::Util::Scalar qw[weaken refaddr];
use Pcore::Util::Text qw[decode_utf8 encode_utf8];
use Pcore::Util::Data qw[to_b64 to_xor];
use Compress::Raw::Zlib;
use Pcore::Util::Digest qw[sha1];

# Websocket v13 spec. https://tools.ietf.org/html/rfc6455

# compression:
# http://www.iana.org/assignments/websocket/websocket.xml#extension-name
# https://tools.ietf.org/html/rfc7692#page-10
# https://www.igvita.com/2013/11/27/configuring-and-optimizing-websocket-compression/

requires qw[protocol before_connect_server before_connect_client on_connect_server on_connect_client on_disconnect on_text on_binary];

has max_message_size => ( is => 'ro', isa => PositiveOrZeroInt, default => 1_024 * 1_024 * 100 );    # 0 - do not check message size
has pong_interval    => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );                      # 0 - do not pong automatically
has compression      => ( is => 'ro', isa => Bool,              default => 0 );                      # use permessage_deflate compression
has on_disconnect => ( is => 'ro', isa => Maybe [CodeRef], reader => undef );                        # ($ws, $status)
has on_ping       => ( is => 'ro', isa => Maybe [CodeRef], reader => undef );                        # ($ws, $status)
has on_pong       => ( is => 'ro', isa => Maybe [CodeRef], reader => undef );                        # ($ws, $status)

has h => ( is => 'ro', isa => InstanceOf ['Pcore::AE::Handle2'], init_arg => undef );
has is_connected => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

# mask data on send, for websocket client only
has _send_masked => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

has _msg => ( is => 'ro', isa => ArrayRef, init_arg => undef );                                      # fragmentated message data, [$payload, $op, $rsv1]
has _deflate => ( is => 'ro', init_arg => undef );
has _inflate => ( is => 'ro', init_arg => undef );

const our $WEBSOCKET_VERSION => 13;
const our $WEBSOCKET_GUID    => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

const our $WEBSOCKET_PING_PONG_PAYLOAD => "\xFF";

# http://www.iana.org/assignments/websocket/websocket.xml#opcode
const our $WEBSOCKET_OP_CONTINUATION => 0;
const our $WEBSOCKET_OP_TEXT         => 1;
const our $WEBSOCKET_OP_BINARY       => 2;
const our $WEBSOCKET_OP_CLOSE        => 8;
const our $WEBSOCKET_OP_PING         => 9;
const our $WEBSOCKET_OP_PONG         => 10;

# http://www.iana.org/assignments/websocket/websocket.xml#close-code-number
const our $WEBSOCKET_STATUS_REASON => {
    1000 => 'Normal Closure',
    1001 => 'Going Away',                   # удалённая сторона «исчезла». Например, процесс сервера убит или браузер перешёл на другую страницу
    1002 => 'Protocol error',
    1003 => 'Unsupported Data',
    1004 => 'Reserved',
    1005 => 'No Status Rcvd',
    1006 => 'Abnormal Closure',
    1007 => 'Invalid frame payload data',
    1008 => 'Policy Violation',
    1009 => 'Message Too Big',
    1010 => 'Mandatory Ext.',
    1011 => 'Internal Error',
    1012 => 'Service Restart',
    1013 => 'Try Again Later',
    1015 => 'TLS handshake',
};

sub DEMOLISH ( $self, $global ) {
    if ( !$global ) {
        $self->disconnect( result [ 1001, $WEBSOCKET_STATUS_REASON ] );
    }

    return;
}

sub send_text ( $self, $data_ref ) {
    $self->{h}->push_write( $self->_build_frame( 1, $self->{compression}, 0, 0, $WEBSOCKET_OP_TEXT, $data_ref ) );

    return;
}

sub send_binary ( $self, $data_ref ) {
    $self->{h}->push_write( $self->_build_frame( 1, $self->{compression}, 0, 0, $WEBSOCKET_OP_BINARY, $data_ref ) );

    return;
}

sub send_ping ( $self, $payload = $WEBSOCKET_PING_PONG_PAYLOAD ) {
    $self->{h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_PING, \$payload ) );

    return;
}

sub send_pong ( $self, $payload = $WEBSOCKET_PING_PONG_PAYLOAD ) {
    $self->{h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_PONG, \$payload ) );

    return;
}

sub disconnect ( $self, $status = undef ) {
    return if !$self->{is_connected};

    # mark connection as closed
    $self->{is_connected} = 0;

    $status = result [ 1000, $WEBSOCKET_STATUS_REASON ] if !defined $status;

    # cleanup message data
    undef $self->{_msg};

    # send close message
    $self->{h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_CLOSE, \( pack( 'n', $status->{status} ) . encode_utf8 $status->{reason} ) ) );

    # destroy handle
    $self->{h}->destroy;

    # remove from cache, affect only server handles
    delete $Pcore::WebSocket::HANDLE->{ refaddr $self};

    # call protocol on_disconnect
    $self->on_disconnect($status);

    # call on_disconnect callback, if defined
    $self->{on_disconnect}->( $self, $status ) if $self->{on_disconnect};

    return;
}

# UTILS
sub get_challenge ( $self, $key ) {
    return to_b64( sha1( ($key) . $WEBSOCKET_GUID ), q[] );
}

sub on_connect ( $self, $h ) {
    return if $self->{is_connected};

    $self->{is_connected} = 1;

    $self->{h} = $h;

    weaken $self;

    # set on_error handler
    $self->{h}->on_error(
        sub ( $h, @ ) {
            $self->disconnect( result [ 1001, $WEBSOCKET_STATUS_REASON ] ) if $self;    # 1001 - Going Away

            return;
        }
    );

    # start listen
    $self->{h}->on_read(
        sub ($h) {
            if ( my $header = $self->_parse_frame_header( \$h->{rbuf} ) ) {

                # check protocol errors
                if ( $header->{fin} ) {

                    # this is the last frame of the fragmented message
                    if ( $header->{op} == $WEBSOCKET_OP_CONTINUATION ) {

                        # message was not started, return 1002 - protocol error
                        return $self->disconnect( result [ 1002, $WEBSOCKET_STATUS_REASON ] ) if !$self->{_msg};

                        # restore message "op", "rsv1"
                        ( $header->{op}, $header->{rsv1} ) = ( $self->{_msg}->[1], $self->{_msg}->[2] );
                    }

                    # this is the single-frame message
                    else {

                        # set "rsv1" flag
                        $header->{rsv1} = $self->{compression} && $header->{rsv1} ? 1 : 0;
                    }
                }
                else {

                    # this is the next frame of the fragmented message
                    if ( $header->{op} == $WEBSOCKET_OP_CONTINUATION ) {

                        # message was not started, return 1002 - protocol error
                        return $self->disconnect( result [ 1002, $WEBSOCKET_STATUS_REASON ] ) if !$self->{_msg};

                        # restore "rsv1" flag
                        $header->{rsv1} = $self->{_msg}->[2];
                    }

                    # this is the first frame of the fragmented message
                    else {

                        # store message "op"
                        $self->{_msg}->[1] = $header->{op};

                        # set and store "rsv1" flag
                        $self->{_msg}->[2] = $header->{rsv1} = $self->{compression} && $header->{rsv1} ? 1 : 0;
                    }
                }

                # empty frame
                if ( !$header->{len} ) {
                    $self->_on_frame( $header, undef );
                }
                else {

                    # check max. message size, return 1009 - message too big
                    if ( $self->{max_message_size} ) {
                        if ( $self->{_msg} && $self->{_msg}->[0] ) {
                            return $self->disconnect( result [ 1009, $WEBSOCKET_STATUS_REASON ] ) if $header->{len} + length $self->{_msg}->[0] > $self->{max_message_size};
                        }
                        else {
                            return $self->disconnect( result [ 1009, $WEBSOCKET_STATUS_REASON ] ) if $header->{len} > $self->{max_message_size};
                        }
                    }

                    if ( length $h->{rbuf} >= $header->{len} ) {
                        $self->_on_frame( $header, \substr $h->{rbuf}, 0, $header->{len}, q[] );
                    }
                    else {
                        $h->unshift_read(
                            chunk => $header->{len},
                            sub ( $h, $payload ) {
                                $self->_on_frame( $header, \$payload );

                                return;
                            }
                        );
                    }
                }
            }

            return;
        }
    );

    # start autopong
    if ( my $pong_interval = $self->pong_interval ) {
        $self->{h}->on_timeout(
            sub ($h) {
                $self->send_pong;

                return;
            }
        );

        $self->{h}->timeout($pong_interval);
    }

    return;
}

sub _on_frame ( $self, $header, $payload_ref ) {
    if ($payload_ref) {

        # unmask
        $payload_ref = \to_xor( $payload_ref->$*, $header->{mask} ) if $header->{mask};

        # decompress
        if ( $header->{rsv1} ) {
            my $inflate = $self->{_inflate} ||= Compress::Raw::Zlib::Inflate->new(
                -WindowBits => -15,
                ( $self->{max_message_size} ? ( -Bufsize => $self->{max_message_size} ) : () ),
                -AppendOutput => 0,
                -ConsumeInput => 1,
                -LimitOutput  => 1,
            );

            $payload_ref->$* .= "\x00\x00\xff\xff";

            $inflate->inflate( $payload_ref, my $out );

            return $self->disconnect( result [ 1009, $WEBSOCKET_STATUS_REASON ] ) if length $payload_ref->$*;

            $payload_ref = \$out;
        }
    }

    # this is message fragment frame
    if ( !$header->{fin} ) {

        # add frame to the message buffer
        $self->{_msg}->[0] .= $payload_ref->$* if $payload_ref;
    }

    # message completed, dispatch message
    else {
        if ( $self->{_msg} ) {
            $payload_ref = \( $self->{_msg}->[0] . $payload_ref->$* ) if $payload_ref && defined $self->{_msg}->[0];

            # cleanup fragmentated message data
            undef $self->{_msg};
        }

        # TEXT message
        if ( $header->{op} == $WEBSOCKET_OP_TEXT ) {
            if ($payload_ref) {
                return $self->disconnect( result [ 1003, 'UTF-8 decode error', $WEBSOCKET_STATUS_REASON ] ) if $@;

                $self->on_text($payload_ref);
            }
        }

        # BINARY message
        elsif ( $header->{op} == $WEBSOCKET_OP_BINARY ) {
            $self->on_binary($payload_ref) if $payload_ref;
        }

        # CLOSE message
        elsif ( $header->{op} == $WEBSOCKET_OP_CLOSE ) {
            my ( $status, $reason );

            if ( $payload_ref && length $payload_ref->$* >= 2 ) {
                $status = unpack( 'n', substr $payload_ref->$*, 0, 2, q[] );

                $reason = decode_utf8 $payload_ref->$* if length $payload_ref->$*;
            }
            else {
                $status = 1006;    # 1006 - Abnormal Closure - if close status was not specified
            }

            $self->disconnect( result [ $status, $reason, $WEBSOCKET_STATUS_REASON ] );
        }

        # PING message
        elsif ( $header->{op} == $WEBSOCKET_OP_PING ) {

            # reply pong automatically
            $self->send_pong( $payload_ref ? $payload_ref->$* : q[] );

            $self->{on_ping}->( $self, $payload_ref || \q[] ) if $self->{on_ping};
        }

        # PONG message
        elsif ( $header->{op} == $WEBSOCKET_OP_PONG ) {
            $self->{on_pong}->( $self, $payload_ref || \q[] ) if $self->{on_pong};
        }
    }

    return;
}

sub _build_frame ( $self, $fin, $rsv1, $rsv2, $rsv3, $op, $payload_ref ) {
    my $masked = $self->{_send_masked};

    # deflate
    if ($rsv1) {
        my $deflate = $self->{_deflate} ||= Compress::Raw::Zlib::Deflate->new(
            -Level        => Z_DEFAULT_COMPRESSION,
            -WindowBits   => -15,
            -MemLevel     => 8,
            -AppendOutput => 0,
        );

        $deflate->deflate( $payload_ref, my $out ) == Z_OK or die q[Deflate error];

        $deflate->flush( $out, Z_SYNC_FLUSH );

        substr $out, -4, 4, q[];

        $payload_ref = \$out;
    }

    # head
    my $head = $op + ( $fin ? 128 : 0 );
    $head |= 0b01000000 if $rsv1;
    $head |= 0b00100000 if $rsv2;
    $head |= 0b00010000 if $rsv3;

    my $frame = pack 'C', $head;

    # small payload
    my $len = length $payload_ref->$*;

    if ( $len < 126 ) {
        $frame .= pack 'C', $masked ? ( $len | 128 ) : $len;
    }

    # extended payload (16-bit)
    elsif ( $len < 65_536 ) {
        $frame .= pack 'Cn', $masked ? ( 126 | 128 ) : 126, $len;
    }

    # extended payload (64-bit with 32-bit fallback)
    else {
        $frame .= pack 'C', $masked ? ( 127 | 128 ) : 127;

        $frame .= pack 'Q>', $len;
    }

    # mask payload
    if ($masked) {
        my $mask = pack 'N', int( rand 9 x 7 );

        $payload_ref = \( $mask . to_xor( $payload_ref->$*, $mask ) );
    }

    return $frame . $payload_ref->$*;
}

sub _parse_frame_header ( $self, $buf_ref ) {
    return if length $buf_ref->$* < 2;

    my ( $first, $second ) = unpack 'C*', substr $buf_ref->$*, 0, 2;

    my $masked = $second & 0b10000000;

    my $header;

    ( my $hlen, $header->{len} ) = ( 2, $second & 0b01111111 );

    # small payload
    if ( $header->{len} < 126 ) {
        $hlen += 4 if $masked;

        return if length $buf_ref->$* < $hlen;

        # cut header
        my $full_header = substr $buf_ref->$*, 0, $hlen, q[];

        $header->{mask} = substr $full_header, 2, 4, q[] if $masked;
    }

    # extended payload (16-bit)
    elsif ( $header->{len} == 126 ) {
        $hlen = $masked ? 8 : 4;

        return if length $buf_ref->$* < $hlen;

        # cut header
        my $full_header = substr $buf_ref->$*, 0, $hlen, q[];

        $header->{mask} = substr $full_header, 4, 4, q[] if $masked;

        $header->{len} = unpack 'n', substr $full_header, 2, 2, q[];
    }

    # extended payload (64-bit with 32-bit fallback)
    elsif ( $header->{len} == 127 ) {
        $hlen = $masked ? 14 : 10;

        return if length $buf_ref->$* < $hlen;

        # cut header
        my $full_header = substr $buf_ref->$*, 0, $hlen, q[];

        $header->{mask} = substr $full_header, 10, 4, q[] if $masked;

        $header->{len} = unpack 'Q>', substr $full_header, 2, 8, q[];
    }

    # FIN
    $header->{fin} = ( $first & 0b10000000 ) == 0b10000000 ? 1 : 0;

    # RSV1-3
    $header->{rsv1} = ( $first & 0b01000000 ) == 0b01000000 ? 1 : 0;
    $header->{rsv2} = ( $first & 0b00100000 ) == 0b00100000 ? 1 : 0;
    $header->{rsv3} = ( $first & 0b00010000 ) == 0b00010000 ? 1 : 0;

    # opcode
    $header->{op} = $first & 0b00001111;

    return $header;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 88, 94, 342          | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 134                  | * Subroutine "on_connect" with high complexity score (27)                                                      |
## |      | 252                  | * Subroutine "_on_frame" with high complexity score (30)                                                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 403, 405             | NamingConventions::ProhibitAmbiguousNames - Ambiguously named variable "second"                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 39, 268              | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 313                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::Handle

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
