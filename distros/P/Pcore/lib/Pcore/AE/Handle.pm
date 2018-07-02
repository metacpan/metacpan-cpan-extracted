package Pcore::AE::Handle;

use Pcore -const, -export;
use parent qw[AnyEvent::Handle];
use AnyEvent::Socket qw[];
use Pcore::AE::DNS::Cache;
use Pcore::HTTP::Headers;
use HTTP::Parser::XS qw[HEADERS_AS_ARRAYREF HEADERS_NONE];
use Pcore::AE::Handle::Cache;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref];
use Pcore::Util::CA;

our $EXPORT = { TLS_CTX => [qw[$TLS_CTX_HIGH $TLS_CTX_LOW]] };

const our $TLS_CTX_LOW  => 0;
const our $TLS_CTX_HIGH => 1;
const our $TLS_CTX      => {
    $TLS_CTX_LOW => {
        $MSWIN ? ( ca_file => Pcore::Util::CA->ca_file ) : (),
        cache           => 1,
        verify          => 0,
        verify_peername => undef,
        sslv2           => 1,
        dh              => undef,    # Diffie-Hellman is disabled
    },
    $TLS_CTX_HIGH => {
        $MSWIN ? ( ca_file => Pcore::Util::CA->ca_file ) : (),
        cache           => 1,
        verify          => 1,
        verify_peername => 'http',
        sslv2           => 0,
        dh              => 'schmorp4096',
    },
};

const our $MAX_READ_SIZE => 131_072;
const our $CONNECT_ARGS  => [qw[fh connect on_connect connect_timeout bind_ip]];

const our $CACHE => Pcore::AE::Handle::Cache->new;

# register "http_headers" read type
AnyEvent::Handle::register_read_type http_headers => sub ( $self, $cb ) {
    return sub {
        return unless defined $_[0]{rbuf};

        if ( ( my $idx_crlf = index $_[0]{rbuf}, $CRLF ) >= 0 ) {
            if ( $idx_crlf == 0 ) {    # first line is empty, no headers, used to read possible trailing headers
                $cb->( $_[0], substr( $_[0]{rbuf}, 0, 2, q[] ) );

                return 1;
            }
            elsif ( ( my $idx = index $_[0]{rbuf}, qq[\x0A\x0D\x0A] ) >= 0 ) {
                $cb->( $_[0], substr( $_[0]{rbuf}, 0, $idx + 3, q[] ) );

                return 1;
            }
            else {
                return;
            }
        }
        else {
            return;
        }
    };
};

sub new ( $self, @ ) {
    my $args = {
        fh         => undef,
        connect    => undef,    # mandatory
        persistent => 0,        # try to fetch handle from cache before connect

        on_connect_error => undef,    # $h, $message
        on_error         => undef,    # $h, $fatal, $message
        on_connect       => undef,    # mandatory, $h, $host, $port, $repeat

        tls_ctx          => $TLS_CTX_HIGH,
        tcp_no_delay     => 1,               # no_delay
        tcp_so_keepalive => 1,               # keepalive

        connect_timeout => 30,
        bind_ip         => undef,
        @_[ 1 .. $#_ ]
    };

    # get connect args
    my $connect_args->@{ $CONNECT_ARGS->@* } = delete $args->@{ $CONNECT_ARGS->@* };

    # process persistent
    if ( !$connect_args->{fh} ) {
        $connect_args->{connect} = get_connect( $connect_args->{connect} );

        if ( $args->{persistent} ) {

            $args->{persistent} = join q[|], $connect_args->{connect}->[2], $connect_args->{connect}->[0], $connect_args->{connect}->[1];

            if ( my $h = $CACHE->fetch( $args->{persistent} ) ) {
                $connect_args->{on_connect}->( $h, undef, undef, undef );

                return;
            }
        }
    }

    # convert to AE::Handle attrs
    $args->{no_delay}  = delete $args->{tcp_no_delay};
    $args->{keepalive} = delete $args->{tcp_so_keepalive};

    # resolve TLS_CTX shortcut
    if ( !$args->{tls_ctx} ) {
        $args->{tls_ctx} = $TLS_CTX->{$TLS_CTX_LOW};
    }
    elsif ( !ref $args->{tls_ctx} ) {
        $args->{tls_ctx} = $TLS_CTX->{ $args->{tls_ctx} };
    }

    my $h = bless $args, $self;

    if ( $connect_args->{fh} ) {
        $h->{fh} = $connect_args->{fh};

        $h->_start;

        delete $h->{on_connect_error};

        $connect_args->{on_connect}->( $h, undef, undef, undef ) if !$h->destroyed;
    }
    else {
        $h->{peername} = $connect_args->{connect}->[0] unless exists $h->{peername};

        if ( $connect_args->{bind_ip} ) {
            state $ip_pack_cache = {};

            $ip_pack_cache->{ $connect_args->{bind_ip} } = Socket::pack_sockaddr_in( 0, Socket::inet_aton( $connect_args->{bind_ip} ) ) if !exists $ip_pack_cache->{ $connect_args->{bind_ip} };

            $connect_args->{bind_ip} = $ip_pack_cache->{ $connect_args->{bind_ip} };
        }

        AnyEvent::Socket::tcp_connect(
            $connect_args->{connect}->[0],
            $connect_args->{connect}->[1],
            sub ( $fh = undef, $host = undef, $port = undef, $retry = undef ) {
                if ($fh) {
                    $h->{fh} = $fh;

                    $h->_start;

                    delete $h->{on_connect_error};

                    $connect_args->{on_connect}->( $h, $host, $port, $retry ) if !$h->destroyed;
                }
                else {
                    $h->_error( $!, 1 );
                }

                return;
            },
            sub ($fh) {
                if ( $connect_args->{bind_ip} ) {
                    bind $fh, $connect_args->{bind_ip} or do {

                        # replace $fh with $fake_fh to interrupt connection process
                        # this can be removed, when original AnyEvent::Socket::tcp_connect will handle exceptions in this call
                        open my $fake_fh, '+<', \'' or die;    ## no critic qw[InputOutput::RequireBriefOpen]

                        $_[0] = $fake_fh;

                        return;
                    };
                }

                return $connect_args->{connect_timeout};
            }
        );
    }

    return;
}

sub _error ( $self, $errno, $fatal = undef, $message = undef ) {
    local $! = $errno;

    $message ||= "$!";

    if ( my $on_connect_error = delete $self->{on_connect_error} ) {
        $self->destroy if $fatal;

        $on_connect_error->( $self, $message );
    }
    elsif ( my $on_error = $self->{on_error} ) {
        $on_error->( $self, $fatal, $message );

        $self->destroy if $fatal;
    }
    else {
        $self->destroy;

        die "AnyEvent::Handle uncaught error: $message";
    }

    return;
}

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        $self->{proxy}->finish_thread if defined $self->{proxy};

        $self->SUPER::DESTROY;
    }

    return;
}

# READERS
sub read_http_res_headers {
    my $self = shift;
    my $cb   = pop;
    my %args = (
        headers  => 0,    # true - create new headers obj, false - do not parse headers, ref - headers obj to add headers to
        trailing => 0,    # read trailing headers, mandatory if trailing headers are expected
        @_,
    );

    $self->unshift_read(
        http_headers => sub ( $h, @ ) {
            if ( $_[1] ) {
                my $res;

                my $headers = $args{trailing} ? 'HTTP/1.1 200 OK' . $CRLF . $_[1] : $_[1];

                # $len = -1 - incomplete headers, -2 - errors, >= 0 - headers length
                ( my $len, $res->{minor_version}, $res->{status}, $res->{reason}, my $parsed_headers ) = HTTP::Parser::XS::parse_http_response( $headers, !$args{headers} ? HEADERS_NONE : HEADERS_AS_ARRAYREF );

                # fallback to pure-perl parser in case of errors
                # TODO can be removed after this issue will be fixed - https://github.com/kazuho/p5-http-parser-xs/issues/10
                # NOTE http://www.bizcoder.com/everything-you-need-to-know-about-http-header-syntax-but-were-afraid-to-ask
                if ( $len == -1 ) {
                    $len = length $headers;

                    my @lines = split /\x0D\x0A/sm, $headers;

                    if ( my $proto = shift @lines ) {
                        if ( $proto =~ m[\AHTTP/\d[.](\d)\s(\d\d\d)\s(.+)]sm ) {
                            $res->{minor_version} = $1;

                            $res->{status} = $2;

                            $res->{reason} = $3;

                            while ( my $header = shift @lines ) {
                                if ( substr( $header, 0, 1 ) eq q[ ] ) {
                                    if ($parsed_headers) {
                                        $parsed_headers->[-1] .= $header;
                                    }
                                    else {
                                        $len = -2;

                                        last;
                                    }
                                }
                                elsif ( $header =~ /(.+?)\s*:\s*(.+)/sm ) {

                                    # TODO remove trailing spaces from the value
                                    push $parsed_headers->@*, $1, $2;
                                }
                            }
                        }
                        else {
                            $len = -2;
                        }
                    }
                    else {
                        $len = -1;
                    }
                }

                if ( $len == -1 ) {
                    $cb->( $h, undef, q[Headers are incomplete] );
                }
                elsif ( $len == -2 ) {
                    $cb->( $h, undef, q[Headers are corrupt] );
                }
                else {
                    if ( $args{headers} ) {
                        $res->{headers} = ref $args{headers} ? $args{headers} : Pcore::HTTP::Headers->new;

                        # repack received headers to the standard format
                        for ( my $i = 0; $i <= $parsed_headers->$#*; $i += 2 ) {
                            $parsed_headers->[$i] = uc $parsed_headers->[$i] =~ tr/-/_/r;
                        }

                        $res->{headers}->add($parsed_headers);
                    }

                    $cb->( $h, $res, undef );
                }
            }
            elsif ( $args{trailing} ) {    # trailing headers can be empty, this is not an error
                $cb->( $h, undef, undef );
            }
            else {
                $cb->( $h, undef, 'No headers' );
            }

            return;
        }
    );

    return;
}

sub read_http_req_headers ( $self, $cb, $env = undef ) {
    $self->unshift_read(
        http_headers => sub ( $h, @ ) {
            if ( $_[1] ) {
                $env //= {};

                my $res = HTTP::Parser::XS::parse_http_request( $_[1], $env );

                if ( $res == -1 ) {
                    $cb->( $h, undef, 'Request is corrupt' );
                }
                elsif ( $res == -2 ) {
                    $cb->( $h, undef, 'Request is incomplete' );
                }
                else {
                    $cb->( $h, $env, undef );
                }
            }
            else {
                $cb->( $h, undef, 'No headers' );
            }

            return;
        }
    );

    return;
}

sub read_http_body ( $self, $on_read, @ ) {
    my %args = (
        chunked  => 0,
        length   => undef,    # false - read until EOF
        headers  => 0,        # false or headers object to read trailing headers
        buf_size => 65_536,
        splice @_, 2,
    );

    my $on_read_buf = sub ( $buf_ref, $error_reason ) {
        state $buf = q[];

        state $total_bytes_readed = 0;

        if ($error_reason) {

            # drop buffer if has data
            return if length $buf && !$on_read->( $self, \$buf, $total_bytes_readed, undef );

            # throw error
            $on_read->( $self, undef, $total_bytes_readed, $error_reason );
        }
        elsif ( defined $buf_ref ) {
            $buf .= $buf_ref->$*;

            $total_bytes_readed += length $buf_ref->$*;

            if ( length $buf > $args{buf_size} ) {
                my $continue = $on_read->( $self, \$buf, $total_bytes_readed, undef );

                $buf = q[];

                return $continue ? $total_bytes_readed : 0;
            }
            else {
                return $total_bytes_readed;
            }
        }
        else {
            # drop buffer if has data
            return if length $buf && !$on_read->( $self, \$buf, $total_bytes_readed, undef );

            $on_read->( $self, undef, $total_bytes_readed, undef );
        }

        return;
    };

    # TODO rewrite chunk reader using single on_read callback
    if ( $args{chunked} ) {    # read chunked body
        my $read_chunk;

        $read_chunk = sub ( $h, @ ) {
            my $chunk_len_ref = \$_[1];

            # valid chunk length
            if ( $chunk_len_ref->$* =~ /\A([[:xdigit:]]+)/sm ) {
                my $chunk_len = hex $1;

                # read chunk body
                if ($chunk_len) {
                    $h->unshift_read(
                        chunk => $chunk_len,
                        sub ( $h, @ ) {
                            my $chunk_ref = \$_[1];

                            if ( !$on_read_buf->( $chunk_ref, undef ) ) {    # transfer was cancelled by "on_body" call
                                undef $read_chunk;

                                return;
                            }
                            else {
                                # read trailing chunk $CRLF
                                $h->unshift_read(
                                    line => sub ( $h, @ ) {
                                        if ( length $_[1] ) {                # error, chunk traililg can contain only $CRLF
                                            undef $read_chunk;

                                            $on_read_buf->( undef, 'Garbled chunked transfer encoding (last chunk)' );
                                        }
                                        else {
                                            $h->unshift_read( line => $read_chunk );
                                        }

                                        return;
                                    }
                                );
                            }

                            return;
                        }
                    );
                }

                # last chunk
                else {

                    # read trailing headers
                    $h->read_http_res_headers(
                        headers  => $args{headers},
                        trailing => 1,
                        sub ( $h, $res, $error_reason ) {
                            undef $read_chunk;

                            if ($error_reason) {
                                $on_read_buf->( undef, 'Garbled chunked transfer encoding (invalid trailing headers)' );
                            }
                            else {
                                $on_read_buf->( undef, undef );
                            }

                            return;
                        }
                    );
                }
            }

            # invalid chunk length
            else {
                undef $read_chunk;

                $on_read_buf->( undef, 'Garbled chunked transfer encoding (invalid chunk length)' );
            }

            return;
        };

        $self->unshift_read( line => $read_chunk );
    }
    elsif ( !$args{length} ) {    # read until EOF
        $self->on_eof(undef);

        $self->on_error(
            sub ( $h, $fatal, $reason ) {

                # remove "on_read" callback
                $h->on_read(undef);

                # remove "on_eof" callback
                $h->on_error(undef);

                $on_read_buf->( undef, undef );

                return;
            }
        );

        $self->on_read( sub ($h) {
            my $total_bytes_readed = $on_read_buf->( \delete $h->{rbuf}, undef );

            if ( !$total_bytes_readed ) {

                # remove "on_read" callback
                $h->on_read(undef);

                # remove "on_eof" callback
                $h->on_eof(undef);
            }

            return;
        } );
    }
    else {    # read body with known length
        $self->on_read( sub ($h) {
            my $total_bytes_readed = $on_read_buf->( \delete $h->{rbuf}, undef );

            if ( !$total_bytes_readed ) {

                # remove "on_read" callback
                $h->on_read(undef);
            }
            else {
                if ( $total_bytes_readed == $args{length} ) {

                    # remove "on_read" callback
                    $h->on_read(undef);

                    $on_read_buf->( undef, undef );
                }
                elsif ( $total_bytes_readed > $args{length} ) {

                    # remove "on_read" callback
                    $h->on_read(undef);

                    $on_read_buf->( undef, q[Readed body length is larger than expected] );
                }
            }

            return;
        } );
    }

    return;
}

sub read_eof ( $self, $on_read ) {
    $self->read_http_body( $on_read, chunked => 0, length => undef );

    return;
}

# CACHE METHODS
sub store ( $self, $timeout ) {
    $CACHE->store( $self, $timeout );

    return;
}

# UTIL
sub get_connect ($connect) {

    # parse connect attribute
    if ( !is_plain_arrayref $connect ) {
        if ( !is_ref $connect ) {    # parse uri string
            $connect = P->uri( $connect, authority => 1 )->connect;
        }
        else {                       # already uri object
            $connect = $connect->connect;
        }
    }
    else {

        # default scheme is "tcp"
        $connect->[2] ||= 'tcp';

        # create connect id, "scheme_port"
        $connect->[3] = $connect->[2] . q[_] . $connect->[1];
    }

    return $connect;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 215                  | * Subroutine "read_http_res_headers" with high complexity score (22)                                           |
## |      | 341                  | * Subroutine "read_http_body" with high complexity score (29)                                                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 251, 252             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 52                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 164                  | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 288                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 |                      | Documentation::RequirePodLinksIncludeText                                                                      |
## |      | 606                  | * Link L<AnyEvent::Handle> on line 612 does not specify text                                                   |
## |      | 606                  | * Link L<AnyEvent::Handle> on line 620 does not specify text                                                   |
## |      | 606                  | * Link L<AnyEvent::Handle> on line 648 does not specify text                                                   |
## |      | 606                  | * Link L<AnyEvent::Handle> on line 664 does not specify text                                                   |
## |      | 606                  | * Link L<AnyEvent::Socket> on line 664 does not specify text                                                   |
## |      | 606, 606             | * Link L<Pcore::Proxy> on line 630 does not specify text                                                       |
## |      | 606                  | * Link L<Pcore::Proxy> on line 664 does not specify text                                                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 48, 53               | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::AE::Handle - L<AnyEvent::Handle> subclass with proxy support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

Refer to the L<AnyEvent::Handle> for the other base class attributes.

=head2 connect_timeout = <seconds>

Connect timeout in seconds.

=head2 proxy = [ <proxy_type>, <proxy> ]

    proxy => [ 'socks5', 'connect://127.0.0.1:8080?socks5' ],

Proxy to use. First argument - is a preferred proxy type. Second argument - L<Pcore::Proxy> object, or HashRef, that will be passed to the L<Pcore::Proxy> constructor.

=head2 on_proxy_connect_error = sub ( $self, $reason, $proxy_error )

    on_proxy_connect_error => sub ( $h, $reason, $proxy_error ) {
        return;
    },

Error callback, called in the case of the proxy connection error.

=head1 CLASS METHODS

=head2 fetch ( $self, $id )

Fetch stored connection from the cache. Return C<undef> if no cached connections for current id was found.

=head1 METHODS

Refer to the L<AnyEvent::Handle> for the other base class methods.

=head2 store ( $self, $id, $timeout = L</$CACHE_TIMEOUT> )

Store connection to the cache.

!!! WARNING !!! - C<on_error>, C<on_eof>, C<on_read> and C<timeout> attributes will be redefined when handle is stored. You need to restore this attributes manually after handle will be fetched from cache.

=head1 PACKAGE VARIABLES

=head2 $CACHE_TIMEOUT = 4

Defaul cache timeout is C<4>.

=head1 SEEE ALSO

L<AnyEvent::Handle>, L<AnyEvent::Socket>, L<Pcore::Proxy>

=cut
