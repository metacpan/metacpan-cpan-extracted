package Pcore::WebSocket::Handle;

use Pcore -const, -role, -res;
use Pcore::Util::Scalar qw[is_ref weaken];
use Pcore::Util::Text qw[decode_utf8 encode_utf8];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Data qw[to_b64 to_xor];
use Pcore::Util::Digest qw[sha1];
use Pcore::AE::Handle qw[];
use Compress::Raw::Zlib;

# Websocket v13 spec. https://tools.ietf.org/html/rfc6455

# compression:
# http://www.iana.org/assignments/websocket/websocket.xml#extension-name
# https://tools.ietf.org/html/rfc7692#page-10
# https://www.igvita.com/2013/11/27/configuring-and-optimizing-websocket-compression/

requires qw[_on_connect _on_disconnect _on_text _on_binary];

has max_message_size => 1_024 * 1_024 * 100;    # PositiveOrZeroInt, 0 - do not check message size
has compression      => ();                     # Bool, use permessage_deflate compression
has pong_timeout     => ();                     # send pong on inactive connection
has on_ping          => ();                     # Maybe [CodeRef], ($self, \$payload)
has on_pong          => ();                     # Maybe [CodeRef], ($self, \$payload)

has id           => sub {uuid_v1mc_str};
has is_connected => ();                         # Bool
has _connect     => ();                         # prepared connect data
has _is_client   => ();
has _h           => ();                         # InstanceOf ['Pcore::AE::Handle']
has _compression => ();                         # Bool, use compression, set after connected
has _send_masked => ();                         # Bool, mask data on send, for websocket client only
has _msg         => ();                         # ArrayRef, fragmentated message data, [$payload, $op, $rsv1]
has _deflate     => ();
has _inflate     => ();

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

our $SERVER_CONN;

sub DESTROY ( $self ) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        $self->disconnect( res [ 1001, $WEBSOCKET_STATUS_REASON ] );
    }

    return;
}

sub accept ( $self, $req ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $env = $req->{env};

    # websocket version is not specified or not supported
    if ( !$env->{HTTP_SEC_WEBSOCKET_VERSION} || $env->{HTTP_SEC_WEBSOCKET_VERSION} ne $WEBSOCKET_VERSION ) {
        $req->return_xxx( [ 400, q[Unsupported WebSocket version] ] );

        return;
    }

    # websocket key is not specified
    if ( !$env->{HTTP_SEC_WEBSOCKET_KEY} ) {
        $req->return_xxx( [ 400, q[WebSocket SEC_WEBSOCKET_KEY header is required] ] );

        return;
    }

    my $protocol = do {
        no strict qw[refs];

        ${ ref($self) . '::PROTOCOL' };
    };

    # check websocket protocol
    if ($protocol) {
        if ( !$env->{HTTP_SEC_WEBSOCKET_PROTOCOL} || $env->{HTTP_SEC_WEBSOCKET_PROTOCOL} !~ /\b$protocol\b/smi ) {
            $req->return_xxx( [ 400, q[Unsupported WebSocket protocol] ] );

            return;
        }
    }
    elsif ( $env->{HTTP_SEC_WEBSOCKET_PROTOCOL} ) {
        $req->return_xxx( [ 400, q[Unsupported WebSocket protocol] ] );

        return;
    }

    # server send unmasked frames
    $self->{_send_masked} = 0;

    # drop compression
    $self->{_compression} = 0;

    # create response headers
    my @headers = (    #
        'Sec-WebSocket-Accept' => $self->_get_challenge( $env->{HTTP_SEC_WEBSOCKET_KEY} ),
        ( $protocol ? ( 'Sec-WebSocket-Protocol' => $protocol ) : () ),
    );

    # check and set extensions
    if ( $env->{HTTP_SEC_WEBSOCKET_EXTENSIONS} ) {

        # use compression, if server and client support compression
        if ( $self->{compression} && $env->{HTTP_SEC_WEBSOCKET_EXTENSIONS} =~ /\bpermessage-deflate\b/smi ) {
            $self->{_compression} = 1;

            push @headers, ( 'Sec-WebSocket-Extensions' => 'permessage-deflate' );
        }
    }

    # accept websocket connection
    my $h = $req->accept_websocket( \@headers );

    # convert to Pcore::AE::Handle
    Pcore::AE::Handle->new(
        fh         => delete $h->{fh},
        on_connect => sub ( $h1, @ ) {
            $h = $h1;

            return;
        }
    );

    # store connestion
    $SERVER_CONN->{ $self->{id} } = $self;

    # start listen
    $self->__on_connect($h);

    return 1;
}

# TODO store connection args for reconnect???
sub connect ( $self, $uri, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $protocol = do {
        no strict qw[refs];

        ${ ref($self) . '::PROTOCOL' };
    };

    $self->{_is_client}   = 1;
    $self->{_send_masked} = 1;

    if ( $uri =~ m[\Awss?://unix:(.+)?/]sm ) {
        $self->{_connect} = [ 'unix/', $1 ];

        $uri = P->uri($uri) if !is_ref $uri;
    }
    elsif ( $uri =~ m[\A(wss?)://[*]:(.+)]sm ) {
        $uri = P->uri("$1://127.0.0.1:$2");

        $self->{_connect} = $uri;
    }
    else {
        $uri = P->uri($uri) if !is_ref $uri;

        $self->{_connect} = $uri;
    }

    my $on_connect_error = sub ($status) {
        $self->_on_disconnect($status);

        return;
    };

    Pcore::AE::Handle->new(
        connect         => $self->{_connect},
        connect_timeout => $args{connect_timeout},
        tls_ctx         => $args{tls_ctx},
        bind_ip         => $args{bind_ip},
        on_error => sub ( $h, $fatal, $reason ) {
            $on_connect_error->( res [ 596, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {

            # start TLS, only if TLS is required and TLS is not established yet
            $h->starttls('connect') if $uri->is_secure && !exists $h->{tls};

            # generate websocket key
            my $sec_websocket_key = to_b64 rand 100_000, q[];

            my $request_path = $uri->path->to_uri . ( $uri->query ? q[?] . $uri->query : q[] );

            my @headers = (    #
                "GET $request_path HTTP/1.1",
                'Host:' . $uri->host,
                "User-Agent:Pcore-HTTP/$Pcore::VERSION",
                'Upgrade:websocket',
                'Connection:upgrade',
                "Sec-WebSocket-Version:$Pcore::WebSocket::Handle::WEBSOCKET_VERSION",
                "Sec-WebSocket-Key:$sec_websocket_key",
                ( $protocol            ? "Sec-WebSocket-Protocol:$protocol"            : () ),
                ( $self->{compression} ? 'Sec-WebSocket-Extensions:permessage-deflate' : () ),
            );

            # client always send masked frames
            $self->{_send_masked} = 1;

            # write headers
            $h->push_write( join( $CRLF, @headers ) . $CRLF . $CRLF );

            # read response headers
            $h->unshift_read(
                http_headers => sub ( $h1, @ ) {
                    my $headers;

                    if ( !$_[1] ) {
                        $on_connect_error->( res [ 596, 'HTTP headers error' ] );

                        return;
                    }
                    else {
                        use Pcore::Handle;

                        $headers = Pcore::Handle->_parse_http_headers( $_[1] );

                        if ( $headers->{len} <= 0 ) {
                            $on_connect_error->( res [ 596, 'HTTP headers error' ] );

                            return;
                        }
                    }

                    my $res_headers = $headers->{headers};

                    # check response status
                    if ( $headers->{status} != 101 ) {
                        $on_connect_error->( res [ $headers->{status}, $headers->{reason} ] );

                        return;
                    }

                    # check response connection headers
                    if ( !$res_headers->{CONNECTION} || !$res_headers->{UPGRADE} || $res_headers->{CONNECTION} !~ /\bupgrade\b/smi || $res_headers->{UPGRADE} !~ /\bwebsocket\b/smi ) {
                        $on_connect_error->( res [ 596, q[WebSocket handshake error] ] );

                        return;
                    }

                    # validate SEC_WEBSOCKET_ACCEPT
                    if ( !$res_headers->{SEC_WEBSOCKET_ACCEPT} || $res_headers->{SEC_WEBSOCKET_ACCEPT} ne $self->_get_challenge($sec_websocket_key) ) {
                        $on_connect_error->( res [ 596, q[Invalid SEC_WEBSOCKET_ACCEPT header] ] );

                        return;
                    }

                    # check protocol
                    if ( $res_headers->{SEC_WEBSOCKET_PROTOCOL} ) {
                        if ( !$protocol || $res_headers->{SEC_WEBSOCKET_PROTOCOL} !~ /\b$protocol\b/smi ) {
                            $on_connect_error->( res [ 596, qq[WebSocket server returned unsupported protocol "$res_headers->{SEC_WEBSOCKET_PROTOCOL}"] ] );

                            return;
                        }
                    }
                    elsif ($protocol) {
                        $on_connect_error->( res [ 596, q[WebSocket server returned no protocol] ] );

                        return;
                    }

                    # drop compression
                    $self->{_compression} = 0;

                    # check compression support
                    if ( $res_headers->{SEC_WEBSOCKET_EXTENSIONS} ) {

                        # use compression, if server and client support compression
                        if ( $self->{compression} && $res_headers->{SEC_WEBSOCKET_EXTENSIONS} =~ /\bpermessage-deflate\b/smi ) {
                            $self->{_compression} = 1;
                        }
                    }

                    # call protocol on_connect
                    $self->__on_connect($h);

                    return;
                }
            );

            return;
        }
    );

    return;
}

sub send_text ( $self, $data_ref ) {
    $self->{_h}->push_write( $self->_build_frame( 1, $self->{_compression}, 0, 0, $WEBSOCKET_OP_TEXT, $data_ref ) );

    return;
}

sub send_binary ( $self, $data_ref ) {
    $self->{_h}->push_write( $self->_build_frame( 1, $self->{_compression}, 0, 0, $WEBSOCKET_OP_BINARY, $data_ref ) );

    return;
}

sub send_ping ( $self, $payload = $WEBSOCKET_PING_PONG_PAYLOAD ) {
    $self->{_h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_PING, \$payload ) );

    return;
}

sub send_pong ( $self, $payload = $WEBSOCKET_PING_PONG_PAYLOAD ) {
    $self->{_h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_PONG, \$payload ) );

    return;
}

sub disconnect ( $self, $status = undef ) {
    return if !$self->{is_connected};

    # mark connection as closed
    $self->{is_connected} = 0;

    $status = res [ 1000, $WEBSOCKET_STATUS_REASON ] if !defined $status;

    # cleanup message data
    undef $self->{_msg};

    # send close message
    $self->{_h}->push_write( $self->_build_frame( 1, 0, 0, 0, $WEBSOCKET_OP_CLOSE, \( pack( 'n', $status->{status} ) . encode_utf8 $status->{reason} ) ) );

    # destroy handle
    $self->{_h}->destroy;

    # remove from conn, on server only
    delete $SERVER_CONN->{ $self->{id} } if !$self->{_is_client};

    # call protocol on_disconnect
    $self->_on_disconnect($status);

    return;
}

# UTILS
sub _get_challenge ( $self, $key ) {
    return to_b64( sha1( ($key) . $WEBSOCKET_GUID ), q[] );
}

sub __on_connect ( $self, $h ) {
    return if $self->{is_connected};

    $self->{is_connected} = 1;

    $self->{_h} = $h;

    weaken $self;

    # set on_error handler
    $self->{_h}->on_error(
        sub ( $h, @ ) {
            $self->disconnect( res [ 1001, $WEBSOCKET_STATUS_REASON ] ) if $self;    # 1001 - Going Away

            return;
        }
    );

    # start listen
    $self->{_h}->on_read( sub ($h) {
        if ( my $header = $self->_parse_frame_header( \$h->{rbuf} ) ) {

            # check protocol errors
            if ( $header->{fin} ) {

                # this is the last frame of the fragmented message
                if ( $header->{op} == $WEBSOCKET_OP_CONTINUATION ) {

                    # message was not started, return 1002 - protocol error
                    return $self->disconnect( res [ 1002, $WEBSOCKET_STATUS_REASON ] ) if !$self->{_msg};

                    # restore message "op", "rsv1"
                    ( $header->{op}, $header->{rsv1} ) = ( $self->{_msg}->[1], $self->{_msg}->[2] );
                }
            }
            else {

                # this is the next frame of the fragmented message
                if ( $header->{op} == $WEBSOCKET_OP_CONTINUATION ) {

                    # message was not started, return 1002 - protocol error
                    return $self->disconnect( res [ 1002, $WEBSOCKET_STATUS_REASON ] ) if !$self->{_msg};

                    # restore "rsv1" flag
                    $header->{rsv1} = $self->{_msg}->[2];
                }

                # this is the first frame of the fragmented message
                else {

                    # store message "op"
                    $self->{_msg}->[1] = $header->{op};

                    # store "rsv1" flag
                    $self->{_msg}->[2] = $header->{rsv1};
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
                        return $self->disconnect( res [ 1009, $WEBSOCKET_STATUS_REASON ] ) if $header->{len} + length $self->{_msg}->[0] > $self->{max_message_size};
                    }
                    else {
                        return $self->disconnect( res [ 1009, $WEBSOCKET_STATUS_REASON ] ) if $header->{len} > $self->{max_message_size};
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
    } );

    # auto-pong on timeout
    if ( $self->{pong_timeout} ) {
        $self->{_h}->on_timeout( sub ($h) {
            return if !$self;

            $self->send_pong;

            return;
        } );

        $self->{_h}->timeout( $self->{pong_timeout} );
    }

    $self->_on_connect;

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

            return $self->disconnect( res [ 1009, $WEBSOCKET_STATUS_REASON ] ) if length $payload_ref->$*;

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
            $self->_on_text($payload_ref) if $payload_ref;
        }

        # BINARY message
        elsif ( $header->{op} == $WEBSOCKET_OP_BINARY ) {
            $self->_on_binary($payload_ref) if $payload_ref;
        }

        # CLOSE message
        elsif ( $header->{op} == $WEBSOCKET_OP_CLOSE ) {
            my ( $status, $reason );

            if ( $payload_ref && length $payload_ref->$* >= 2 ) {
                $status = unpack 'n', substr $payload_ref->$*, 0, 2, q[];

                $reason = decode_utf8 $payload_ref->$* if length $payload_ref->$*;
            }
            else {
                $status = 1006;    # 1006 - Abnormal Closure - if close status was not specified
            }

            $self->disconnect( res [ $status, $reason, $WEBSOCKET_STATUS_REASON ] );
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
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 163                  | * Subroutine "connect" with high complexity score (28)                                                         |
## |      | 373                  | * Subroutine "__on_connect" with high complexity score (23)                                                    |
## |      | 484                  | * Subroutine "_on_frame" with high complexity score (29)                                                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 244                  | Modules::ProhibitConditionalUseStatements - Conditional "use" statement                                        |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 246                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 330, 336, 570        | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 631, 633             | NamingConventions::ProhibitAmbiguousNames - Ambiguously named variable "second"                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 41, 500              | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
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
