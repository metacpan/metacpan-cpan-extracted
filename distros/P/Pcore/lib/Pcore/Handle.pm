package Pcore::Handle;

use Pcore -const, -class, -export;
use Pcore::Util::CA;
use HTTP::Parser::XS qw[];
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_arrayref is_plain_coderef is_glob is_plain_hashref];
use AnyEvent::Socket qw[];
use Errno qw[];
use IO::Socket::SSL qw[$SSL_ERROR SSL_WANT_READ SSL_WANT_WRITE SSL_VERIFY_NONE SSL_VERIFY_PEER];
use Coro::EV qw[];
use overload    #
  q[bool]  => sub { return substr( $_[0]->{status}, 0, 1 ) == 2 },
  q[0+]    => sub { return $_[0]->{status} },
  q[""]    => sub { return $_[0]->{status} . q[ ] . $_[0]->{reason} },
  fallback => 1;

our $EXPORT = {
    TLS_CTX => [qw[$TLS_CTX_HIGH $TLS_CTX_LOW]],
    ALL     => [qw[$HANDLE_STATUS_PROTOCOL_ERROR]],
};

const our $TLS_CTX_LOW  => 0;
const our $TLS_CTX_HIGH => 1;
const our $TLS_CTX      => {
    $TLS_CTX_LOW => {
        $MSWIN ? ( SSL_ca_file => Pcore::Util::CA->ca_file ) : (),
        SSL_verify_mode => SSL_VERIFY_NONE,
        dh              => undef,
    },
    $TLS_CTX_HIGH => {
        $MSWIN ? ( SSL_ca_file => Pcore::Util::CA->ca_file ) : (),
        SSL_verify_mode => SSL_VERIFY_PEER,
        dh              => 8192,
    },
};

const our $DH_PARAM => {
    2048 => q[MIIBCAKCAQEAhR5Fn9h3Tgnc+q4o3CMkZtre3lLUyDT+1bf3aiVOt22JdDQndZLc|FeKz8AqliB3UIgNExc6oDtuG4znKPgklfOnHv/a9tl1AYQbV+QFM/E0jYl6oG8tF|Epgxezt1GCivvtu64ql0s213wr64QffNMt3hva8lNqK1PXfqp13PzzLzAVsfghrv|fMAX7/bYm1T5fAJdcah6FeZkKof+mqbs8HtRjfvrUF2npEM2WdupFu190vcwABnN|TTJheXCWv2BF2f9EEr61q3OUhSNWIThtZP+NKe2bACm1PebT0drAcaxKoMz9LjKr|y5onGs0TOuQ7JmhtZL45Zr4LwBcyTucLUwIBAg==],
    4096 => q[MIICCAKCAgEA5WwA5lQg09YRYqc/JILCd2AfBmYBkF19wmCEJB8G3JhTxv8EGvYk|xyP2ecKVUvHTG8Xw/qpW8nRqzPIyV8QRf6YFYSf33Qnx2xYhcnqOumU3nfC0SNOL|/w2q1BA9BbHtW4574P+6hOQx9ftRtbtZ2HPKBMRcAKGjpYZiKopv0+UAM4NpEC2p|bfajp7pyVLeb/Aqm/oWP3L63wPlY1SDp+XRzrOAKB+/uLGqEwV0bBaxxGL29BpOp|O2z1ALGXiDCcLs9WTn9WqUhWDzUN6fahm53rd7zxwpFCb6K2YhaK0peG95jzSUJ8|aoL0KgWuC6v5+gPJHRu0HrQIdfAdN4VchqYOKE46uNNkQl8VJGu4RjYB7lFBpRwO|g2HCsGMo2X7BRmA1st66fh+JOd1smXMZG/2ozTOooL+ixcx4spNneg4aQerWl5cb|nWXKtPCp8yPzt/zoNzL3Fon2Ses3sNgMos0M/ZbnigScDxz84Ms6V/X8Z0L4m/qX|mL42dP40tgvmgqi6BdsBzcIWeHlEcIhmGcsEBxxKEg7gjb0OjjvatpUCJhmRrGjJ|LtMkBR68qr42OBMN/PBB4KPOWNUqTauXZajfCwYdbpvV24ZhtkcRdw1zisyARBSh|aTKW/GV8iLsUzlYN27LgVEwMwnWQaoecW6eOTNKGUURC3In6XZSvVzsCAQI=],
    8192 => q[MIIECAKCBAEA/SAEbRSSLenVxoInHiltm/ztSwehGOhOiUKfzDcKlRBZHlCC9jBl|S/aeklM6Ucg8E6J2bnfoh6CAdnE/glQOn6CifhZr8X/rnlL9/eP+r9m+aiAw4l0D|MBd8BondbEqwTZthMmLtx0SslnevsFAZ1Cj8WgmUNaSPOukvJ1N7aQ98U+E99Pw3|VG8ANBydXqLqW2sogS8FtZoMbVywcQuaGmC7M6i3Akxe3CCSIpR/JkEZIytREBSC|CH+x3oW/w+wHzq3w8DGB9hqz1iMXqDMiPIMSdXC0DaIPokLnd7X8u6N14yCAco2h|P0gspD3J8pS2FpUY8ZTVjzbVCjhNNmTryBZAxHSWBuX4xYcCHUtfGlUe/IGLSVE1|xIdFpZUfvlvAJjVq0/TtDMg3r2JSXrhQVlr8MPJwSApDVr5kOBHT/uABio4z+5yR|PAvundznfyo9GGAWhIA36GQqsxSQfoRTjWssFoR/cu+9aomRwwOLkvObu8nCVVLH|nLdKDk5cIR0TvNs9HZ6ZmkzL7ah7cPzEKl7U6eE6yZLVYMNecnPLS6PSAIG4gxcq|CVQrrZjQLfTDrJn0OGgpShX85RaDsuiRtp2bpDZ23YDqdwr4wRjvIargjqc2zcF+|jIb7dUS6ci7bVG/CGOQUuiMWAiXZ3a1f343SMf9A05/sf1xwnMeco6STBLZ3X+PA|4urU+grtpWaFtS/fPD2ILn8nrJ3WuSKKUeSnVM46mmJQsOkyn7z8l3jNLB17GYKo|qc+0UuU/2PM9qtZdZElSM/ACLV2vdCuaibop4B9UIP9z3F8kfZ72+zKxpGiE+Bo1|x8SfG8FQw90mYIx+qZzJ8MCvc2wh+l4wDX5KxrhwvcouE2tHQlwfDgv/DiIXp173|hAmUCV0+bPRW8IIJvBODdAWtJe9hNwxj1FFYmPA7l4wa3gXV4I6tb+iO1MbwVjZ/|116tD5MdCo3JuSisgPYCHfkQccwEO0FHEuBbmfN+fQimQ8H0dePP8XctwbkplsB+|aLT5hYKmva/j9smEswgyHglPwc3WvZ+2DgKk7A7DHi7a2gDwCRQlHaXtNWx3992R|dfNgkSeB1CvGSQoo95WpC9ZoqGmcSlVqdetDU8iglPmfYTKO8aIPA6TuTQ/lQ0IW|90LQmqP23FwnNFiyqX8+rztLq4KVkTyeHIQwig6vFxgD8N+SbZCW2PPiB72TVF2U|WePU8MRTv1OIGBUBajF49k28HnZPSGlILHtFEkYkbPvomcE5ENnoejwzjktOTS5d|/R3SIOvCauOzadtzwTYOXT78ORaR1KI1cm8DzkkwJTd/Rrk07Q5vnvnSJQMwFUeH|PwJIgWBQf/GZ/OsDHmkbYR2ZWDClbKw2mwIBAg==],
};

const our $HANDLE_STATUS_OK             => 200;
const our $HANDLE_STATUS_TIMEOUT        => 201;
const our $HANDLE_STATUS_CONNECT_ERROR  => 590;
const our $HANDLE_STATUS_TLS_ERROR      => 591;
const our $HANDLE_STATUS_PROTOCOL_ERROR => 596;
const our $HANDLE_STATUS_TIMEOUT_ERROR  => 597;
const our $HANDLE_STATUS_SOCKET_ERROR   => 598;
const our $HANDLE_STATUS_EOF            => 599;

const our $STATUS_REASON => {
    $HANDLE_STATUS_OK             => 'OK',
    $HANDLE_STATUS_TIMEOUT        => 'Timeout',
    $HANDLE_STATUS_CONNECT_ERROR  => 'Connect error',
    $HANDLE_STATUS_TLS_ERROR      => 'TLS handshake error',
    $HANDLE_STATUS_PROTOCOL_ERROR => 'Protocol error',
    $HANDLE_STATUS_TIMEOUT_ERROR  => 'Disconnected on timeout',
    $HANDLE_STATUS_SOCKET_ERROR   => 'Socket error',
    $HANDLE_STATUS_EOF            => 'EOF',
};

our $SCHEME_CACHE = {};

has fh               => ();
has read_size        => 1024 * 1024;
has timeout          => 30;
has timeout_is_fatal => 1;
has connect_timeout  => 10;
has persistent       => ();
has tls_ctx          => $TLS_CTX_HIGH;
has bind_ip          => ();
has peername         => ();
has so_no_delay      => 1;
has so_keepalive     => 1;
has so_oobinline     => 1;

has rbuf => ();
has tls  => ();

# TODO handle persistent
sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {

    }

    return;
}

# TODO persistent
around new => sub ( $orig, $self, $connect, @args ) {

    # wrap fh
    if ( is_glob $connect) {
        $self = $self->$orig(@args);

        $self->{fh} = $connect;

        $self->_set_status($HANDLE_STATUS_OK);
    }

    # connect
    else {
        my ( $uri, $scheme );

        # parse connect
        if ( !is_ref $connect) {
            $uri    = P->uri($connect);
            $scheme = $uri->scheme;

            $connect = [ $uri->host, $uri->port || $uri->default_port ];
        }
        elsif ( !is_plain_arrayref $connect) {
            $uri    = $connect;
            $scheme = $connect->scheme;

            $connect = [ $connect->host, $connect->port || $connect->default_port ];
        }

        if ($scheme) {
            if ( !exists $SCHEME_CACHE->{$scheme} ) {
                my $class = eval { P->class->load( $scheme, ns => 'Pcore::Handle' ) };

                $SCHEME_CACHE->{$scheme} = $class;
            }

            return $SCHEME_CACHE->{$scheme}->new( { @args, uri => $uri } ) if $SCHEME_CACHE->{$scheme};    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]
        }

        $self = $self->$orig(@args);

        $self->{peername} //= $connect->[0];

        my $bind_error;

        my $rouse_cb = Coro::rouse_cb;

        AnyEvent::Socket::tcp_connect(
            $connect->[0],
            $connect->[1],
            sub ( $fh = undef, $host = undef, $port = undef, $retry = undef ) {
                if ($fh) {
                    if ($bind_error) {
                        $self->_set_status( $HANDLE_STATUS_CONNECT_ERROR, qq[Unable to bind socket to the IP address $self->{bind_ip}] );
                    }
                    else {
                        $self->_set_status($HANDLE_STATUS_OK);

                        $self->{fh} = $fh;
                    }
                }
                else {
                    $self->_set_status( $HANDLE_STATUS_CONNECT_ERROR, $! );
                }

                $rouse_cb->();

                return;
            },
            sub ($fh) {
                bind $fh, Socket::pack_sockaddr_in( 0, Socket::inet_aton( $self->{bind_ip} ) ) or $bind_error = 1 if $self->{bind_ip};

                return $self->{connect_timeout};
            }
        );

        Coro::rouse_wait $rouse_cb;
    }

    # configure fh
    if ( $self->{fh} ) {
        AnyEvent::fh_unblock $self->{fh};

        $self->so_no_delay( $self->{so_no_delay} );
        $self->so_oobinline( $self->{so_oobinline} );
        $self->so_keepalive( $self->{so_keepalive} );
    }

    return $self;
};

sub so_no_delay ( $self, $val ) {
    $self->{so_no_delay} = $val;

    setsockopt $self->{fh}, Socket::IPPROTO_TCP(), Socket::TCP_NODELAY(), $val;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

sub so_oobinline ( $self, $val ) {
    $self->{so_oobinline} = $val;

    setsockopt $self->{fh}, Socket::SOL_SOCKET(), Socket::SO_OOBINLINE(), $val or die $!;

    return;
}

sub so_keepalive ( $self, $val ) {
    $self->{so_keepalive} = $val;

    setsockopt $self->{fh}, Socket::SOL_SOCKET(), Socket::SO_KEEPALIVE(), $val or die $!;

    return;
}

sub can_read ( $self, $timeout = $self->{timeout} ) {
    my $res = Coro::EV::timed_io_once $self->{fh}, EV::READ, $timeout;

    return 1 if $res == EV::READ;

    $self->_set_status( $self->{timeout_is_fatal} ? $HANDLE_STATUS_TIMEOUT_ERROR : $HANDLE_STATUS_TIMEOUT ) if $res == EV::TIMER;

    return;
}

sub can_write ( $self, $timeout = $self->{timeout} ) {
    my $res = Coro::EV::timed_io_once $self->{fh}, EV::WRITE, $timeout;

    return 1 if $res == EV::WRITE;

    $self->_set_status( $self->{timeout_is_fatal} ? $HANDLE_STATUS_TIMEOUT_ERROR : $HANDLE_STATUS_TIMEOUT ) if $res == EV::TIMER;

    return;
}

# TODO use ->pending in TLS mode if read_size < 16K
# returns: undef or total bytes read
sub _read ( $self, $read_size = undef, $timeout = undef ) {
    my $bytes;

    while () {
        return if !$self;

        $bytes = sysread $self->{fh}, $self->{rbuf}, $read_size || $self->{read_size}, length $self->{rbuf} // 0;

        if ( defined $bytes ) {

            # EOF
            $self->_set_status($HANDLE_STATUS_EOF) if $bytes == 0;

            last;
        }

        # wait for socket
        if ( $!{EAGAIN} || $!{EINTR} || $!{WSAEWOULDBLOCK} || $!{EWOULDBLOCK} ) {
            $self->can_read($timeout) || last;
        }

        # read error
        else {
            $self->_set_status( $HANDLE_STATUS_SOCKET_ERROR, $! );

            last;
        }
    }

    return $bytes;
}

# returns: undef or buffer ref
# $args{timeout}
# $args{read_size}
sub read ( $self, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return if !$self;

    return \delete( $self->{rbuf} ) if length $self->{rbuf};

    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    $self->_read( $args{read_size}, $args{timeout} ) || return;

    return \delete( $self->{rbuf} );
}

# $args{timeout}
# $args{read_size}
sub read_eof ( $self, %args ) {
    if ($self) {
        while ( $self->_read( $args{read_size}, $args{timeout} ) ) { }
    }

    return \delete( $self->{rbuf} );
}

# returns: undef or buffer ref
# $args{timeout}
# $args{read_size}
# TODO on_read???
sub read_line ( $self, $eol, %args ) {
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    while () {
        my $idx = defined $self->{rbuf} ? index $self->{rbuf}, $eol, 0 : -1;

        if ( $idx == 0 ) {
            substr $self->{rbuf}, 0, length $eol, q[];

            my $buf = q[];

            return \$buf;
        }
        elsif ( $idx > 0 ) {
            my $buf = substr $self->{rbuf}, 0, $idx, q[];

            substr $self->{rbuf}, 0, length $eol, q[];

            return \$buf;
        }

        # pattern not found
        else {
            return if !$self;

            $self->_read( $args{read_size}, $args{timeout} ) || last;
        }
    }

    return;
}

# returns: undef or buffer ref
# $args{timeout}
# $args{read_size}
# $args{on_read}->($buf_ref, $total_bytes_read), returns total bytes or undef if error
sub read_chunk ( $self, $length, %args ) {
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    if ( $args{on_read} ) {
        my $total_bytes = 0;

        while () {
            if ( my $rlen = length $self->{rbuf} ) {
                my $buf = substr $self->{rbuf}, 0, $length, q[];

                $total_bytes += my $blen = length $buf;

                return if !$args{on_read}->( \$buf, $total_bytes );

                $length -= $blen;

                return $total_bytes if !$length;
            }

            return if !$self;

            $self->_read( $args{read_size}, $args{timeout} ) || last;
        }

        return;
    }
    else {
        while () {
            if ( my $rlen = length $self->{rbuf} ) {
                if ( $rlen == $length ) {
                    return \delete( $self->{rbuf} );
                }
                elsif ( $rlen > $length ) {
                    return \substr( $self->{rbuf}, 0, $length, q[] );
                }
            }

            return if !$self;

            $self->_read( $args{read_size}, $args{timeout} ) || last;
        }

        return;
    }
}

# returns: undef or total bytes written
sub write ( $self, $buf, %args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    my $buf_ref;

    if ( is_plain_scalarref $buf) {
        if ( utf8::is_utf8 $buf->$* ) {
            my $tmp_buf = $buf->$*;

            utf8::encode $tmp_buf;

            $buf_ref = \$tmp_buf;
        }
        else {
            $buf_ref = $buf;
        }
    }
    else {
        if ( utf8::is_utf8 $buf ) {
            my $tmp_buf = $buf;

            utf8::encode $tmp_buf;

            $buf_ref = \$tmp_buf;
        }
        else {
            $buf_ref = \$buf;
        }
    }

    my $total_bytes;
    my $ofs  = 0;
    my $size = length $buf_ref->$*;

    while () {
        return if !$self;

        my $bytes = syswrite $self->{fh}, $buf_ref->$*, $size, $ofs;

        if ( defined $bytes ) {
            $total_bytes += $bytes;
            $size -= $bytes;

            # all data written
            last if $size == 0;

            $ofs += $bytes;

            # repeat
            next;
        }

        # wait for socket
        if ( $!{EAGAIN} || $!{EINTR} || $!{WSAEWOULDBLOCK} || $!{EWOULDBLOCK} ) {
            $self->can_write( $args{timeout} ) || last;
        }

        # write error
        else {
            $self->_set_status( $HANDLE_STATUS_SOCKET_ERROR, $! );

            last;
        }
    }

    return $total_bytes;
}

sub starttls ( $self, %args ) {
    die q[TLS is already started] if $self->{tls};

    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    my %ctx = do {
        if ( !defined $self->{tls_ctx} ) {
            ();
        }
        elsif ( is_plain_hashref $self->{tls_ctx} ) {
            $self->{tls_ctx}->%*;
        }
        else {
            $TLS_CTX->{ $self->{tls_ctx} }->%*;
        }
    };

    $ctx{SSL_startHandshake} = 0;
    $ctx{SSL_hostname}       = $ctx{SSL_verifycn_name} = $self->{peername};
    $ctx{SSL_dh}             = $DH_PARAM->{ delete $ctx{dh} } if $ctx{dh};

    $self->{fh} = IO::Socket::SSL->start_SSL( $self->{fh}, %ctx );

    $self->{tls} = 1;

    while () {
        $self->{fh}->connect_SSL && last;

        # NOTE under windows $!{ENOENT} can be returned
        if ( $!{ENOENT} || $!{EAGAIN} || $!{EINTR} || $!{WSAEWOULDBLOCK} || $!{EWOULDBLOCK} ) {
            if ( $SSL_ERROR == SSL_WANT_READ ) {
                $self->can_read( $args{timeout} ) && next;
            }
            elsif ( $SSL_ERROR == SSL_WANT_WRITE ) {
                $self->can_write( $args{timeout} ) && next;
            }
        }

        # TLS error
        $self->_set_status($HANDLE_STATUS_TLS_ERROR);

        last;
    }

    return;
}

sub close ( $self ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    CORE::close $self->{fh};

    undef $self->{fh};

    $self->_set_status( $HANDLE_STATUS_SOCKET_ERROR, 'Disconnected' );

    return;
}

sub shutdown ( $self, $type = 2 ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    CORE::shutdown $self->{fh}, $type;

    undef $self->{fh};

    $self->_set_status( $HANDLE_STATUS_SOCKET_ERROR, 'Disconnected' );

    return;
}

# STATUS METHODS
sub is_connect_error ($self)  { return $self->{status} == $HANDLE_STATUS_CONNECT_ERROR }
sub is_tls_error ($self)      { return $self->{status} == $HANDLE_STATUS_TLS_ERROR }
sub is_protocol_error ($self) { return $self->{status} == $HANDLE_STATUS_PROTOCOL_ERROR }
sub is_socket_error ($self)   { return $self->{status} == $HANDLE_STATUS_SOCKET_ERROR }
sub is_eof ($self)            { return $self->{status} == $HANDLE_STATUS_EOF }
sub is_timeout ($self)        { return $self->{status} == $HANDLE_STATUS_TIMEOUT || $self->{status} == $HANDLE_STATUS_TIMEOUT_ERROR }

sub _set_status ( $self, $status, $reason = undef ) {
    return if $self->{status} && substr( $self->{status}, 0, 1 ) != 2;

    $self->{status} = $status;

    $self->{reason} = $reason // $STATUS_REASON->{$status};

    # fatal error
    if ( $self->{fh} && substr( $status, 0, 1 ) != 2 ) {
        CORE::shutdown $self->{fh}, 2;

        undef $self->{fh};
    }

    return;
}

sub set_protocol_error ( $self, $reason = undef ) {
    $self->_set_status( $HANDLE_STATUS_PROTOCOL_ERROR, $reason );

    return;
}

# HTTP headers methods
# $args{timeout}
# $args{read_size}
sub read_http_req_headers ( $self, %args ) {
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    my $buf_ref = $self->read_line( $CRLF x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

    my $env = {};

    my $res = HTTP::Parser::XS::parse_http_request( $buf_ref->$* . $CRLF . $CRLF, $env );

    # headers are corrupted
    if ( $res == -1 ) {
        $self->set_protocol_error('HTTP headers are corrupted');

        return;
    }

    # headers are incomplete
    elsif ( $res == -2 ) {
        $self->set_protocol_error('HTTP headers are incomplete');

        return;
    }
    else {
        return $env;
    }
}

# $args{timeout}
# $args{read_size}
sub read_http_res_headers ( $self, %args ) {
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    my $buf_ref = $self->read_line( $CRLF x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

    $buf_ref->$* .= $CRLF x 2;

    my $res = $self->_parse_http_headers( $buf_ref->$* );

    # headers are incomplete
    if ( $res->{len} == -1 ) {
        $self->set_protocol_error('HTTP headers are incomplete');

        return;
    }

    # headers are corrupted
    elsif ( $res->{len} == -2 ) {
        $self->set_protocol_error('HTTP headers are corrupted');

        return;
    }
    else {
        return $res;
    }
}

# TODO update HTTP::Parser::XS
sub _parse_http_headers ( $self, $buf ) {
    my $res;

    ( $res->{len}, $res->{minor_version}, $res->{status}, $res->{reason}, $res->{headers} ) = HTTP::Parser::XS::parse_http_response( $buf, HTTP::Parser::XS::HEADERS_AS_HASHREF );

    # fallback to pure-perl parser in case of errors
    # TODO can be removed after this issue will be fixed - https://github.com/kazuho/p5-http-parser-xs/issues/10
    # NOTE http://www.bizcoder.com/everything-you-need-to-know-about-http-header-syntax-but-were-afraid-to-ask
    # if ( $len == -1 ) {
    #     $len = length $headers;

    #     my @lines = split /\x0D\x0A/sm, $headers;

    #     if ( my $proto = shift @lines ) {
    #         if ( $proto =~ m[\AHTTP/\d[.](\d)\s(\d\d\d)\s(.+)]sm ) {
    #             $res->{minor_version} = $1;

    #             $res->{status} = $2;

    #             $res->{reason} = $3;

    #             while ( my $header = shift @lines ) {
    #                 if ( substr( $header, 0, 1 ) eq q[ ] ) {
    #                     if ($parsed_headers) {
    #                         $parsed_headers->[-1] .= $header;
    #                     }
    #                     else {
    #                         $len = -2;

    #                         last;
    #                     }
    #                 }
    #                 elsif ( $header =~ /(.+?)\s*:\s*(.+)/sm ) {

    #                     # TODO remove trailing spaces from the value
    #                     push $parsed_headers->@*, $1, $2;
    #                 }
    #             }
    #         }
    #         else {
    #             $len = -2;
    #         }
    #     }
    #     else {
    #         $len = -1;
    #     }
    # }

    if ( $res->{len} > 0 ) {

        # repack headers
        # TODO update HTTP::Parser::XS
        $res->{headers} = { map { uc s/-/_/smgr, $res->{headers}->{$_} } keys $res->{headers}->%* };    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]
    }

    return $res;
}

# returns: undef or buffer ref
# $args{timeout}
# $args{read_size}
# $args{on_read}
# $args{on_read_len}
# $args{headers}
# $args{on_read}->($buf_ref, $total_bytes_read), returns total bytes or undef if error
sub read_http_chunked_data ( $self, %args ) {
    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    my $buf;
    my $total_bytes_read = 0;

    while () {
        my $length = $self->read_line( $CRLF, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

        # invalid chunk length
        if ( $length->$* =~ /([^[:xdigit:]])/sm ) {
            $self->set_protocol_error('Invalid chunk length');

            return;
        }
        else {
            $length = hex $length->$*;
        }

        # last chunk
        if ( !$length ) {

            # read more data if rbuf is empty
            $self->_read( $args{read_size}, $args{timeout} ) || return if !length $self->{rbuf};

            # no headers
            # 0\r\n\r\n

            # has headers
            # 0\r\nheader1\r\nheader2\r\n\r\n

            # no trailing headers
            if ( index( $self->{rbuf}, $CRLF, 0 ) == 0 ) {
                substr $self->{rbuf}, 0, 2, q[];

                return $args{on_read} ? $total_bytes_read : \$buf;
            }

            my $headers_buf_ref = $self->read_line( $CRLF x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

            # parse and update trailing headers
            if ( $args{headers} ) {
                my $headers = $self->_parse_http_headers( 'HTTP/1.1 200 OK' . $CRLF . $headers_buf_ref->$* . $CRLF . $CRLF );

                # headers are incomplete
                if ( $headers->{len} == -1 ) {
                    $self->set_protocol_error('HTTP trailing headers are incomplete');

                    return;
                }

                # headers are corrupted
                elsif ( $headers->{len} == -2 ) {
                    $self->set_protocol_error('HTTP trailing headers are corrupted');

                    return;
                }
                else {

                    # merge headers
                    while ( my ( $k, $v ) = each $headers->{headers}->%* ) {
                        if ( exists $args{headers}->{$k} ) {
                            $args{headers}->{$k} = [ $args{headers}->{$k} ] if !is_plain_arrayref $args{headers}->{$k};

                            push $args{headers}->{$k}->@*, is_plain_arrayref $v ? $v->@* : $v;
                        }
                        else {
                            $args{headers}->{$k} = $v;
                        }
                    }
                }
            }

            return $args{on_read} ? $total_bytes_read : \$buf;
        }

        # not last chunk
        else {
            if ( $args{on_read_len} ) {
                return if !$args{on_read_len}->( $length, $total_bytes_read + $length );
            }

            my $chunk = $self->read_chunk( $length + 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

            substr $chunk->$*, -2, 2, q[];

            $total_bytes_read += length $chunk->$*;

            if ( $args{on_read} ) {
                return if !$args{on_read}->( $chunk, $total_bytes_read );
            }
            else {
                $buf .= $chunk->$*;
            }
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 487                  | NamingConventions::ProhibitAmbiguousNames - Ambiguously named subroutine "close"                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 663                  | Subroutines::ProhibitExcessComplexity - Subroutine "read_http_chunked_data" with high complexity score (26)    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 724                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 358                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
