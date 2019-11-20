package Pcore::Handle;

use Pcore -const, -class, -export;
use Pcore::Core::Patch::AnyEvent::DNSCache;
use Pcore::Lib::CA;
use HTTP::Parser::XS qw[];
use Pcore::Lib::Scalar qw[is_ref is_uri is_plain_scalarref is_plain_arrayref is_plain_coderef is_glob is_plain_hashref];
use AnyEvent::Socket qw[];
use Errno qw[];
use IO::Socket::SSL qw[$SSL_ERROR SSL_WANT_READ SSL_WANT_WRITE SSL_VERIFY_NONE SSL_VERIFY_PEER];
use Coro::EV qw[];
use overload    #
  'bool'   => sub { return $_[0]->{is_connected} },
  '0+'     => sub { return $_[0]->{status} },
  '""'     => sub { return $_[0]->{status} . $SPACE . $_[0]->{reason} },
  fallback => 1;

our $EXPORT = {
    TLS_CTX => [qw[$TLS_CTX_HIGH $TLS_CTX_LOW]],
    ALL     => [qw[$HANDLE_STATUS_PROTOCOL_ERROR]],
};

const our $TLS_CTX_LOW  => 0;
const our $TLS_CTX_HIGH => 1;
const our $TLS_CTX      => {
    $TLS_CTX_LOW => {
        $MSWIN ? ( SSL_ca_file => Pcore::Lib::CA->ca_file ) : (),
        SSL_verify_mode => SSL_VERIFY_NONE,
        SSL_dh_file     => undef,
        SSL_dh          => undef,
        SSL_ecdh_curve  => undef,             # if you don't want to have ECDH key exchange this could be set to undef
    },
    $TLS_CTX_HIGH => {
        $MSWIN ? ( SSL_ca_file => Pcore::Lib::CA->ca_file ) : (),
        SSL_verify_mode => SSL_VERIFY_PEER,
        SSL_dh_file     => $ENV->{share}->get('data/dhparam-4096.pem'),

        # SSL_ecdh_curve  => 'X25519:secp521r1:secp384r1:prime256v1', # lets OpenSSL pick the best settings
    },
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
    $HANDLE_STATUS_OK             => 'Connected',
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
has timeout          => 30;              # undef - no timeout
has timeout_is_fatal => 1;
has connect_timeout  => 10;              # undef - no timeout
has persistent       => ();
has tls_ctx          => $TLS_CTX_HIGH;
has bind_ip          => ();
has peername         => ();
has so_no_delay      => 1;
has so_keepalive     => 1;
has so_oobinline     => 1;
has on_disconnect    => ();              # CodeRef->($h)

has is_connected => 1;
has rbuf         => ();
has tls          => ();

# TODO handle persistent
sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {

    }

    return;
}

# TODO persistent
around new => sub ( $orig, $self, $uri, @args ) {

    # wrap fh
    if ( is_glob $uri) {
        $self = $self->$orig(@args);

        $self->{fh} = $uri;

        $self->_set_status($HANDLE_STATUS_OK);
    }

    # connect
    else {
        my @connect;

        if ( is_plain_arrayref $uri) {
            @connect = $uri->@*;

            $self = $self->$orig(@args);

            $self->{peername} //= $connect[0];
        }
        else {

            # convert to URI object
            $uri = P->uri( $uri, base => 'tcp:' ) if !is_uri $uri;

            my $scheme = $uri->{scheme};

            if ($scheme) {
                if ( !exists $SCHEME_CACHE->{$scheme} ) {
                    my $class = eval { P->class->load( $scheme, ns => 'Pcore::Handle' ) };

                    $SCHEME_CACHE->{$scheme} = $class;
                }

                return $SCHEME_CACHE->{$scheme}->new( { @args, uri => $uri } ) if $SCHEME_CACHE->{$scheme};
            }

            $self = $self->$orig(@args);

            $self->{peername} //= $uri->{host}->{name} if defined $uri->{host};

            @connect = $uri->connect;
        }

        my $bind_error;

        my $cv = P->cv;

        &AnyEvent::Socket::tcp_connect(    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
            @connect,
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

                $cv->();

                return;
            },
            sub ($fh) {
                bind $fh, Socket::pack_sockaddr_in( 0, Socket::inet_aton( $self->{bind_ip} ) ) or $bind_error = 1 if $self->{bind_ip};

                return $self->{connect_timeout};
            }
        );

        $cv->recv;
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

    setsockopt $self->{fh}, Socket::SOL_SOCKET(), Socket::SO_OOBINLINE(), $val;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

sub so_keepalive ( $self, $val ) {
    $self->{so_keepalive} = $val;

    setsockopt $self->{fh}, Socket::SOL_SOCKET(), Socket::SO_KEEPALIVE(), $val;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

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
        return if !$self->{is_connected};

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
    return if !$self->{is_connected};

    return \delete( $self->{rbuf} ) if length $self->{rbuf};

    $args{timeout} = $self->{timeout} if !exists $args{timeout};

    $self->_read( $args{read_size}, $args{timeout} ) || return;

    return \delete( $self->{rbuf} );
}

# $args{timeout}
# $args{read_size}
sub read_eof ( $self, %args ) {
    if ($self) {
        $args{timeout} = $self->{timeout} if !exists $args{timeout};

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
            substr $self->{rbuf}, 0, length $eol, $EMPTY;

            my $buf = $EMPTY;

            return \$buf;
        }
        elsif ( $idx > 0 ) {
            my $buf = substr $self->{rbuf}, 0, $idx, $EMPTY;

            substr $self->{rbuf}, 0, length $eol, $EMPTY;

            return \$buf;
        }

        # pattern not found
        else {
            return if !$self->{is_connected};

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
                my $buf = substr $self->{rbuf}, 0, $length, $EMPTY;

                $total_bytes += my $blen = length $buf;

                return if !$args{on_read}->( \$buf, $total_bytes );

                $length -= $blen;

                return $total_bytes if !$length;
            }

            return if !$self->{is_connected};

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
                    return \substr $self->{rbuf}, 0, $length, $EMPTY;
                }
            }

            return if !$self->{is_connected};

            $self->_read( $args{read_size}, $args{timeout} ) || last;
        }

        return;
    }
}

# returns: undef or total bytes written
# $args{timeout}
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
        return if !$self->{is_connected};

        my $bytes = syswrite $self->{fh}, $buf_ref->$*, $size, $ofs;

        if ( defined $bytes ) {
            $total_bytes += $bytes;
            $size        -= $bytes;

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

# args: timeout, http2
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

    $ctx{SSL_npn_protocols} = ['h2'] if $args{http2};

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
    return if !$self->{is_connected};

    $self->{is_connected} = 0;

    CORE::close $self->{fh} if defined $self->{fh};

    $self->{status} = $HANDLE_STATUS_SOCKET_ERROR;

    $self->{reason} = 'Disconnected';

    if ( my $cb = delete $self->{on_disconnect} ) { $cb->($self) }

    return;
}

sub shutdown ( $self, $type = 2 ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return if !$self->{is_connected};

    $self->{is_connected} = 0;

    CORE::shutdown $self->{fh}, $type if defined $self->{fh};

    $self->{status} = $HANDLE_STATUS_SOCKET_ERROR;

    $self->{reason} = 'Disconnected';

    if ( my $cb = delete $self->{on_disconnect} ) { $cb->($self) }

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
    return if !$self->{is_connected};

    $self->{status} = $status;

    $self->{reason} = $reason // $STATUS_REASON->{$status};

    # fatal error
    if ( substr( $status, 0, 1 ) != 2 ) {
        $self->{is_connected} = 0;

        CORE::shutdown $self->{fh}, 2 if defined $self->{fh};

        if ( my $cb = delete $self->{on_disconnect} ) { $cb->($self) }
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

    my $buf_ref = $self->read_line( "\r\n" x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

    my $env = {};

    my $res = HTTP::Parser::XS::parse_http_request( $buf_ref->$* . "\r\n\r\n", $env );

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

    my $buf_ref = $self->read_line( "\r\n" x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

    $buf_ref->$* .= "\r\n" x 2;

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

sub _parse_http_headers ( $self, $buf ) {
    my $res;

    ( $res->{len}, $res->{minor_version}, $res->{status}, $res->{reason}, $res->{headers} ) = HTTP::Parser::XS::parse_http_response( $buf, HTTP::Parser::XS::HEADERS_AS_HASHREF );

    $res->{version} = "1.$res->{minor_version}" if defined $res->{minor_version};

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
    #                 if ( substr( $header, 0, 1 ) eq $SPACE ) {
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
        my $length = $self->read_line( "\r\n", read_size => $args{read_size}, timeout => $args{timeout} ) // return;

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
            if ( index( $self->{rbuf}, "\r\n", 0 ) == 0 ) {
                substr $self->{rbuf}, 0, 2, $EMPTY;

                return $args{on_read} ? $total_bytes_read : \$buf;
            }

            my $headers_buf_ref = $self->read_line( "\r\n" x 2, read_size => $args{read_size}, timeout => $args{timeout} ) // return;

            # parse and update trailing headers
            if ( $args{headers} ) {
                my $headers = $self->_parse_http_headers( "HTTP/1.1 200 OK\r\n" . $headers_buf_ref->$* . "\r\n\r\n" );

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

            substr $chunk->$*, -2, 2, $EMPTY;

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
## |    3 | 495                  | NamingConventions::ProhibitAmbiguousNames - Ambiguously named subroutine "close"                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 679                  | Subroutines::ProhibitExcessComplexity - Subroutine "read_http_chunked_data" with high complexity score (26)    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 740                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
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
