package Pcore::AE::Handle;

use Pcore -const, -export,
  { PROXY_TYPE  => [qw[$PROXY_TYPE_HTTP $PROXY_TYPE_CONNECT $PROXY_TYPE_SOCKS5 $PROXY_TYPE_SOCKS4 $PROXY_TYPE_SOCKS4A]],
    PROXY_ERROR => [qw[$PROXY_OK $PROXY_ERROR_CONNECT $PROXY_ERROR_AUTH $PROXY_ERROR_TYPE $PROXY_ERROR_OTHER]],
    PERSISTENT  => [qw[$PERSISTENT_IDENT $PERSISTENT_ANY $PERSISTENT_NO_PROXY]],
  };
use parent qw[AnyEvent::Handle];
use AnyEvent::Socket qw[];
use Pcore::AE::DNS::Cache;
use Pcore::HTTP::Headers;
use HTTP::Parser::XS qw[HEADERS_AS_ARRAYREF HEADERS_NONE];
use Pcore::AE::Handle::Cache;

const our $PROXY_TYPE_HTTP    => 1;
const our $PROXY_TYPE_CONNECT => 2;
const our $PROXY_TYPE_SOCKS4  => 31;
const our $PROXY_TYPE_SOCKS4A => 32;
const our $PROXY_TYPE_SOCKS5  => 33;

const our $PROXY_ERROR_CONNECT => 1;    # proxy should be disabled
const our $PROXY_ERROR_AUTH    => 2;    # proxy should be disabled
const our $PROXY_ERROR_TYPE    => 3;    # invalid proxy type used, proxy type should be banned
const our $PROXY_ERROR_OTHER   => 4;    # unknown error

# $PERSISTENT_IDENT:
#     - no proxy - use cached direct connections;
#     - proxy - use cached connection through same proxy;
#     - proxy pool - use ANY cached connection from the same proxy pool;
#
# $PERSISTENT_ANY
#     - use ANY cached connection (direct or proxied);
#
# $PERSISTENT_NO_PROXY
#     - no proxy - use cached direct connections;
#     - proxy or proxy pool - do not use cache;

const our $PERSISTENT_IDENT    => 1;
const our $PERSISTENT_ANY      => 2;
const our $PERSISTENT_NO_PROXY => 3;

const our $DISABLE_PROXY => 1;

const our $CACHE => Pcore::AE::Handle::Cache->new( { default_keepalive_timeout => 4 } );

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
    my %args = (
        connect_timeout  => 30,
        tcp_no_delay     => 1,
        tcp_so_keepalive => 1,
        bind_ip          => undef,
        proxy            => undef,               # can be a proxy object or proxy pool object
        proxy_wait       => 0,
        proxy_ban_id     => undef,               # ban key
        persistent       => $PERSISTENT_IDENT,
        session          => undef,
        splice @_, 1,
    );

    # convert to AE::Handle attrs
    $args{no_delay}  = delete $args{tcp_no_delay};
    $args{keepalive} = delete $args{tcp_so_keepalive};

    if ( $args{fh} ) {
        $args{on_connect}->( $self->SUPER::new(%args), undef, undef, undef );
    }
    else {

        # parse connect attribute
        $args{connect} = get_connect( $args{connect} );

        my $persistent = delete $args{persistent};

        my $persistent_id = {};

        $persistent_id->{any} = join q[|], $args{connect}->[2], $args{connect}->[0], $args{connect}->[1], $args{session} // q[];

        $persistent_id->{no_proxy} = join q[|], $persistent_id->{any}, 0;

        if ( $args{proxy} ) {
            if ( $args{proxy}->{connect_error} ) {

                # proxy can be removed or has conect error
                # we do not check cache in this case
                $persistent = 0;
            }
            else {
                if ( $args{proxy}->is_proxy_pool ) {
                    $persistent_id->{proxy_pool} = join q[|], $persistent_id->{any}, 1, $args{proxy}->id;
                }
                else {
                    $persistent_id->{proxy_pool} = join q[|], $persistent_id->{any}, 1, $args{proxy}->pool->id;

                    $persistent_id->{proxy} = join q[|], $persistent_id->{any}, 2, $args{proxy}->id;
                }
            }
        }

        # fetch persistent connection and return on success
        if ($persistent) {
            my $effective_persistent_id;

            if ( $persistent == $PERSISTENT_ANY ) {
                $effective_persistent_id = $persistent_id->{any};
            }
            elsif ( $persistent == $PERSISTENT_IDENT ) {
                if ( !$args{proxy} ) {
                    $effective_persistent_id = $persistent_id->{no_proxy};
                }
                elsif ( $args{proxy}->is_proxy_pool ) {
                    $effective_persistent_id = $persistent_id->{proxy_pool};
                }
                else {
                    $effective_persistent_id = $persistent_id->{proxy};
                }
            }
            elsif ( $persistent == $PERSISTENT_NO_PROXY ) {
                $effective_persistent_id = $persistent_id->{no_proxy};
            }
            else {
                die q[Invalid persistent value];
            }

            while ( my $h = $CACHE->fetch($effective_persistent_id) ) {
                next if $args{proxy_ban_id} && $h->{proxy} && $h->{proxy}->is_banned;    # do not use cached connections via banned proxy

                $h->{persistent} = 1;

                $args{on_connect}->( $h, undef, undef, undef );

                return;
            }
        }

        $args{persistent} = 0;

        $args{persistent_id} = [ values $persistent_id->%* ];

        # "on_prepare" wrapper to hanlde "connect_timeout" and "bind_ip"
        if ( $args{connect_timeout} || $args{bind_ip} ) {
            my $conect_timeout = $args{connect_timeout};

            state $ip_pack_cache = {};

            my $bind_ip;

            if ( $args{bind_ip} ) {
                $ip_pack_cache->{ $args{bind_ip} } = Socket::pack_sockaddr_in( 0, Socket::inet_aton( $args{bind_ip} ) ) if !exists $ip_pack_cache->{ $args{bind_ip} };

                $bind_ip = $ip_pack_cache->{ $args{bind_ip} };
            }

            my $on_prepare = $args{on_prepare};

            $args{on_prepare} = sub ($h) {

                # handle bind error, call error callback
                if ($bind_ip) {
                    eval { bind $h->{fh}, $bind_ip or die $! };

                    if ($@) {
                        $h->{on_connect_error}->( $h, 'Bind IP error' );

                        $h->destroy;

                        return;
                    }
                }

                $on_prepare->($h) if $on_prepare;

                if ($conect_timeout) {
                    return $conect_timeout;
                }
                else {
                    return;
                }

            };
        }

        if ( !$args{proxy} ) {
            my $hdl;

            my $on_connect_error = $args{on_connect_error};
            my $on_error         = $args{on_error};
            my $on_connect       = $args{on_connect};

            $args{on_connect_error} = sub ( $h, $reason ) {
                delete $h->{on_connect_error};

                delete $h->{on_connect};

                if ($on_connect_error) {
                    $on_connect_error->( $hdl, $reason );
                }
                elsif ($on_error) {
                    $on_error->( $hdl, 1, $reason );
                }
                else {
                    $on_connect->( undef, undef, undef, undef );
                }

                return;
            };

            $args{on_connect} = sub ( $h, @args ) {
                delete $h->{on_connect_error};

                delete $h->{on_connect};

                $on_connect->( $hdl, @args );

                return;
            };

            $hdl = $self->SUPER::new(%args);
        }
        else {
            if ( !$args{proxy}->is_proxy_pool && $args{proxy}->{connect_error} ) {

                # proxy can already be removed or has connect error
                # do not wait for the slot in this case
                $args{proxy_type} = 0;

                $self->_connect_proxy( \%args );
            }
            elsif ( $args{proxy_type} ) {

                # special case for already defined proxy type
                # we do not get slot, create connection directly
                $self->_connect_proxy( \%args );
            }
            else {
                my $wait_slot = sub {
                    $args{proxy}->get_slot(
                        $args{connect},
                        wait   => $args{proxy_wait},
                        ban_id => $args{proxy_ban_id},
                        sub ( $proxy, $proxy_type ) {
                            $args{proxy} = $proxy;

                            $args{proxy_type} = $proxy_type;

                            $self->_connect_proxy( \%args );

                            return;
                        }
                    );

                    return;
                };

                if ( $args{proxy}->is_proxy_pool ) {
                    $args{proxy}->get_slot(
                        $args{connect},
                        wait   => $args{proxy_wait},
                        ban_id => $args{proxy_ban_id},
                        sub ($proxy) {
                            if ($proxy) {
                                $args{proxy} = $proxy;

                                # add proxy persistent id key here, because we haven't proxy credentials before
                                push $args{persistent_id}->@*, join q[|], $persistent_id->{any}, 2, $proxy->id;

                                $wait_slot->();
                            }
                            else {
                                if ( $args{proxy_wait} ) {

                                    # proxy wasn't found in the pool, no sense to wait for proxy slot
                                    $self->_connect_proxy( \%args );
                                }
                                else {

                                    # TODO we should connect directly here
                                    # because this is not a proxy retrieving error
                                    # proxy is not mandatory
                                    $self->_connect_proxy( \%args );
                                }
                            }

                            return;
                        }
                    );
                }
                else {
                    $wait_slot->();
                }
            }
        }
    }

    return;
}

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        $self->{proxy}->_finish_thread if $self->{proxy} && !$self->{_proxy_keep_thread_on_error};

        $self->SUPER::DESTROY;
    }

    return;
}

# PROXY CONNECTORS
sub _connect_proxy ( $self, $args ) {
    my $hdl;

    my $on_proxy_connect_error = $args->{on_proxy_connect_error};
    my $on_connect_error       = $args->{on_connect_error};
    my $on_error               = $args->{on_error};
    my $on_connect             = $args->{on_connect};
    my $connect                = $args->{connect};
    my $timeout                = $args->{timeout};

    my $on_finish = sub ( $h, $error_reason, $proxy_error ) {
        my $proxy = $args->{proxy};

        # cleanup
        undef $args;

        if ($proxy_error) {
            $h->destroy if $h;

            $proxy->_set_connect_error if $proxy && $proxy_error == $PROXY_ERROR_CONNECT || $proxy_error == $PROXY_ERROR_AUTH;

            if ( $proxy_error && $on_proxy_connect_error ) {
                $on_proxy_connect_error->( $hdl, $error_reason, $proxy_error );
            }
            elsif ($on_connect_error) {
                $on_connect_error->( $hdl, $error_reason );
            }
            elsif ($on_error) {
                $on_error->( $hdl, 1, $error_reason );
            }
            else {
                $on_connect->( undef, undef, undef, undef );
            }
        }
        else {
            delete $h->{on_connect_error};

            delete $h->{on_error};

            delete $h->{on_connect};

            # restore orig. on_error callback
            $h->on_error($on_error);

            $h->{peername} = $connect->[0];

            $h->{connect} = $connect;

            $h->timeout($timeout);

            $on_connect->( $hdl, undef, undef, undef );
        }

        return;
    };

    if ( !$args->{proxy_type} ) {
        $on_finish->( undef, 'Proxy type error', $PROXY_ERROR_TYPE );

        return;
    }

    $args->{on_connect_error} = sub ( $h, $reason ) {
        $on_finish->( @_, $PROXY_ERROR_CONNECT );

        return;
    };

    $args->{on_connect} = sub ( $h, @ ) {
        if ( $args->{proxy_type} == $PROXY_TYPE_HTTP ) {
            $on_finish->( $h, undef, undef );

            return;
        }

        $h->on_error(
            sub ( $h, $fatal, $reason ) {
                $on_finish->( $h, $reason, $PROXY_ERROR_OTHER );

                return;
            }
        );

        if ( $args->{proxy_type} == $PROXY_TYPE_CONNECT ) {
            $h->_connect_proxy_connect( $args->{proxy}, $connect, $on_finish );
        }
        elsif ( $args->{proxy_type} == $PROXY_TYPE_SOCKS4 || $args->{proxy_type} == $PROXY_TYPE_SOCKS4A ) {
            $h->_connect_proxy_socks4( $args->{proxy}, $connect, $on_finish );
        }
        elsif ( $args->{proxy_type} == $PROXY_TYPE_SOCKS5 ) {
            $h->_connect_proxy_socks5( $args->{proxy}, $connect, $on_finish );
        }
        else {
            die q[Invalid proxy type, please report];
        }

        return;
    };

    $args->{connect} = [ $args->{proxy}->host->name, $args->{proxy}->port ];

    $args->{timeout} = $args->{connect_timeout} if $args->{connect_timeout};

    $hdl = $self->SUPER::new( $args->%* );

    return;
}

sub _connect_proxy_connect ( $self, $proxy, $connect, $on_finish ) {
    $self->push_write( q[CONNECT ] . $connect->[0] . q[:] . $connect->[1] . q[ HTTP/1.1] . $CRLF . ( $proxy->userinfo ? q[Proxy-Authorization: Basic ] . $proxy->userinfo_b64 . $CRLF : q[] ) . $CRLF );

    $self->read_http_res_headers(
        headers => 0,
        sub ( $h, $res, $error_reason ) {
            if ($error_reason) {
                $on_finish->( $h, 'Invalid proxy connect response', $PROXY_ERROR_TYPE );
            }
            else {
                if ( $res->{status} == 200 ) {
                    $on_finish->( $h, undef, undef );
                }
                elsif ( $res->{status} == 407 ) {
                    $on_finish->( $h, $res->{status} . q[ - ] . $res->{reason}, $PROXY_ERROR_AUTH );
                }
                else {
                    $on_finish->( $h, $res->{status} . q[ - ] . $res->{reason}, $PROXY_ERROR_OTHER );
                }
            }

            return;
        }
    );

    return;
}

sub _connect_proxy_socks4 ( $self, $proxy, $connect, $on_finish ) {
    AnyEvent::Socket::resolve_sockaddr $connect->[0], $connect->[1], 'tcp', undef, undef, sub {
        my @target = @_;

        unless (@target) {
            $on_finish->( $self, qq[Host name "$connect->[0]" couldn't be resolved], $PROXY_ERROR_OTHER );    # not a proxy connect error

            return;
        }

        my $target = shift @target;

        $self->push_write( qq[\x04\x01] . pack( 'n', $connect->[1] ) . AnyEvent::Socket::unpack_sockaddr( $target->[3] ) . $proxy->userinfo . qq[\x00] );

        $self->unshift_read(
            chunk => 8,
            sub ( $h, $chunk ) {
                my $rep = unpack 'C*', substr( $chunk, 1, 1 );

                # request granted
                if ( $rep == 90 ) {
                    $on_finish->( $h, undef, undef );
                }

                # request rejected or failed, tunnel creation error
                elsif ( $rep == 91 ) {
                    $on_finish->( $h, 'Request rejected or failed', $PROXY_ERROR_OTHER );
                }

                # request rejected becasue SOCKS server cannot connect to identd on the client
                elsif ( $rep == 92 ) {
                    $on_finish->( $h, 'Request rejected becasue SOCKS server cannot connect to identd on the client', $PROXY_ERROR_AUTH );
                }

                # request rejected because the client program and identd report different user-ids
                elsif ( $rep == 93 ) {
                    $on_finish->( $h, 'Request rejected because the client program and identd report different user-ids', $PROXY_ERROR_AUTH );
                }

                # unknown error or not SOCKS4 proxy response
                else {
                    $on_finish->( $h, 'Invalid socks4 server response', $PROXY_ERROR_OTHER );
                }

                return;
            }
        );

        return;
    };

    return;
}

sub _connect_proxy_socks5 ( $self, $proxy, $connect, $on_finish ) {

    # start handshake
    # no authentication or authenticate with username/password
    if ( $proxy->userinfo ) {
        $self->push_write(qq[\x05\x02\x00\x02]);
    }

    # no authentication
    else {
        $self->push_write(qq[\x05\x01\x00]);
    }

    $self->unshift_read(
        chunk => 2,
        sub ( $h, $chunk ) {
            my ( $ver, $auth_method ) = unpack 'C*', $chunk;

            # no valid authentication method was proposed
            if ( $auth_method == 255 ) {
                $on_finish->( $h, 'No authentication method was found', $PROXY_ERROR_AUTH );
            }

            # start username / password authentication
            elsif ( $auth_method == 2 ) {

                # send authentication credentials
                $h->push_write( qq[\x01] . pack( 'C', length $proxy->username ) . $proxy->username . pack( 'C', length $proxy->password ) . $proxy->password );

                # read authentication response
                $h->unshift_read(
                    chunk => 2,
                    sub ( $h, $chunk ) {
                        my ( $auth_ver, $auth_status ) = unpack 'C*', $chunk;

                        # authentication error
                        if ( $auth_status != 0 ) {
                            $on_finish->( $h, 'Authentication failure', $PROXY_ERROR_AUTH );
                        }

                        # authenticated
                        else {
                            _socks5_establish_tunnel( $h, $proxy, $connect, $on_finish );
                        }

                        return;
                    }
                );
            }

            # no authentication is needed
            elsif ( $auth_method == 0 ) {
                _socks5_establish_tunnel( $h, $proxy, $connect, $on_finish );

                return;
            }

            # unknown authentication method or not SOCKS5 response
            else {
                $on_finish->( $h, 'Authentication method is not supported', $PROXY_ERROR_OTHER );
            }

            return;
        }
    );

    return;
}

sub _socks5_establish_tunnel ( $self, $proxy, $connect, $on_finish ) {

    # detect destination addr type
    if ( my $ipn4 = AnyEvent::Socket::parse_ipv4( $connect->[0] ) ) {    # IPv4 addr
        $self->push_write( qq[\x05\x01\x00\x01] . $ipn4 . pack( 'n', $connect->[1] ) );
    }
    elsif ( my $ipn6 = AnyEvent::Socket::parse_ipv6( $connect->[0] ) ) {    # IPv6 addr
        $self->push_write( qq[\x05\x01\x00\x04] . $ipn6 . pack( 'n', $connect->[1] ) );
    }
    else {                                                                  # domain name
        $self->push_write( qq[\x05\x01\x00\x03] . pack( 'C', length $connect->[0] ) . $connect->[0] . pack( 'n', $connect->[1] ) );
    }

    $self->unshift_read(
        chunk => 4,
        sub ( $h, $chunk ) {
            my ( $ver, $rep, $rsv, $atyp ) = unpack( 'C*', $chunk );

            if ( $rep == 0 ) {
                if ( $atyp == 1 ) {                                         # IPv4 addr, 4 bytes
                    $h->unshift_read(                                       # read IPv4 addr (4 bytes) + port (2 bytes)
                        chunk => 6,
                        sub ( $h, $chunk ) {
                            $on_finish->( $h, undef, undef );

                            return;
                        }
                    );
                }
                elsif ( $atyp == 3 ) {                                      # domain name
                    $h->unshift_read(                                       # read domain name length
                        chunk => 1,
                        sub ( $h, $chunk ) {
                            $h->unshift_read(                               # read domain name + port (2 bytes)
                                chunk => unpack( 'C', $chunk ) + 2,
                                sub ( $h, $chunk ) {
                                    $on_finish->( $h, undef, undef );

                                    return;
                                }
                            );

                            return;
                        }
                    );
                }
                if ( $atyp == 4 ) {    # IPv6 addr, 16 bytes
                    $h->unshift_read(    # read IPv6 addr (16 bytes) + port (2 bytes)
                        chunk => 18,
                        sub ( $h, $chunk ) {
                            $on_finish->( $h, undef, undef );

                            return;
                        }
                    );
                }
            }
            else {
                $on_finish->( $h, q[Tunnel creation error], $PROXY_ERROR_OTHER );
            }

            return;
        }
    );

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

        $self->on_read(
            sub ($h) {
                my $total_bytes_readed = $on_read_buf->( \delete $h->{rbuf}, undef );

                if ( !$total_bytes_readed ) {

                    # remove "on_read" callback
                    $h->on_read(undef);

                    # remove "on_eof" callback
                    $h->on_eof(undef);
                }

                return;
            }
        );
    }
    else {    # read body with known length
        $self->on_read(
            sub ($h) {
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
            }
        );
    }

    return;
}

sub read_eof ( $self, $on_read ) {
    $self->read_http_body( $on_read, chunked => 0, length => undef );

    return;
}

# CACHE METHODS
sub store ( $self, $timeout = undef ) {
    $CACHE->store( $self, $timeout );

    return;
}

sub get_connect ($connect) {

    # parse connect attribute
    if ( ref $connect ne 'ARRAY' ) {
        if ( !ref $connect ) {    # parse uri string
            $connect = P->uri( $connect, authority => 1 )->connect;
        }
        else {                    # already uri object
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
## |      | 72                   | * Subroutine "new" with high complexity score (45)                                                             |
## |      | 662                  | * Subroutine "read_http_res_headers" with high complexity score (22)                                           |
## |      | 788                  | * Subroutine "read_http_body" with high complexity score (29)                                                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 185                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 295, 698, 699        | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 57, 482, 529, 534,   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |      | 551, 597, 600, 603   |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 735                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 |                      | Documentation::RequirePodLinksIncludeText                                                                      |
## |      | 1059                 | * Link L<AnyEvent::Handle> on line 1065 does not specify text                                                  |
## |      | 1059                 | * Link L<AnyEvent::Handle> on line 1073 does not specify text                                                  |
## |      | 1059                 | * Link L<AnyEvent::Handle> on line 1101 does not specify text                                                  |
## |      | 1059                 | * Link L<AnyEvent::Handle> on line 1117 does not specify text                                                  |
## |      | 1059                 | * Link L<AnyEvent::Socket> on line 1117 does not specify text                                                  |
## |      | 1059, 1059           | * Link L<Pcore::Proxy> on line 1083 does not specify text                                                      |
## |      | 1059                 | * Link L<Pcore::Proxy> on line 1117 does not specify text                                                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 53, 58, 487, 597,    | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## |      | 600, 603, 609        |                                                                                                                |
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
