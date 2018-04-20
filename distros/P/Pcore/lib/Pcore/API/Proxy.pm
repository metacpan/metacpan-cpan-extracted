package Pcore::API::Proxy;

use Pcore -const, -class, -res, -export => { PROXY_TYPE => [qw[$PROXY_TYPE_HTTP $PROXY_TYPE_HTTPS $PROXY_TYPE_SOCKS4 $PROXY_TYPE_SOCKS4A $PROXY_TYPE_SOCKS5]] };
use Pcore::Util::Scalar qw[is_ref];

has uri        => ( is => 'ro', isa => Str | InstanceOf ['Pcore::Util::URI'], required => 1 );
has is_http    => ( is => 'ro', isa => Bool );
has is_https   => ( is => 'ro', isa => Bool );
has is_socks4  => ( is => 'ro', isa => Bool );
has is_socks4a => ( is => 'ro', isa => Bool );
has is_socks5  => ( is => 'ro', isa => Bool );

has pool => ( is => 'ro', isa => Maybe [Object] );

has threads => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );

const our $PROXY_TYPE_HTTP    => 1;
const our $PROXY_TYPE_HTTPS   => 2;
const our $PROXY_TYPE_SOCKS4  => 3;
const our $PROXY_TYPE_SOCKS4A => 4;
const our $PROXY_TYPE_SOCKS5  => 5;

around new => sub ( $orig, $self, $uri ) {
    my $args;

    $args->{uri} = is_ref $uri ? $uri : P->uri($uri);

    my $scheme = $args->{uri}->scheme;

    if ( $scheme eq 'http' ) {
        $args->{is_http} = 1;
    }
    elsif ( $scheme eq 'https' ) {
        $args->{is_https} = 1;
    }
    elsif ( $scheme eq 'socks4' ) {
        $args->{is_socks4} = 1;
    }
    elsif ( $scheme eq 'socks4a' ) {
        $args->{is_socks4a} = 1;
    }
    elsif ( $scheme eq 'socks5' ) {
        $args->{is_socks5} = 1;
    }

    return $self->$orig($args);
};

sub connect ( $self, $uri, @args ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    $uri = P->uri($uri) if !is_ref $uri;

    my $type;

    if ( $uri->is_http ) {
        $type = 'http'  if !$uri->is_secure && $self->{is_http};
        $type = 'https' if !$type           && $self->{is_https};
    }

    if ( !$type ) {
        if    ( $self->{is_socks4} )  { $type = 'socks4' }
        elsif ( $self->{is_socks4a} ) { $type = 'socks4a' }
        elsif ( $self->{is_socks5} )  { $type = 'socks5' }
    }

    if ($type) {
        my $method = "connect_$type";

        return $self->$method( $uri, @args );
    }
    else {
        my $cb = pop @args;

        $cb->( undef, res [ 500, 'No connect scheme found' ] );

        return;
    }
}

sub connect_http ( $self, $uri, @args ) {
    my $cb = pop @args;

    $uri = P->uri($uri) if !is_ref $uri;

    $self->start_thread;

    Pcore::AE::Handle->new(
        @args,
        connect => $self->{uri},
        on_connect_error => sub ( $h, $reason ) {
            $self->finish_thread;

            $cb->( undef, res [ 600, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $h->{proxy}      = $self;
            $h->{proxy_type} = $PROXY_TYPE_HTTP;

            $cb->( $h, res 200 );

            return;
        },
    );

    return;
}

sub connect_https ( $self, $uri, @args ) {
    my $cb = pop @args;

    $uri = P->uri($uri) if !is_ref $uri;

    $self->start_thread;

    Pcore::AE::Handle->new(
        @args,
        connect => $self->{uri},
        on_connect_error => sub ( $h, $reason ) {
            $self->finish_thread;

            $cb->( undef, res [ 600, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            my $buf = 'CONNECT ' . $uri->host->name . q[:] . $uri->connect_port . q[ HTTP/1.1] . $CRLF;

            $buf .= 'Proxy-Authorization: Basic ' . $self->{uri}->userinfo_b64 . $CRLF if $self->{uri}->userinfo;

            $buf .= $CRLF;

            $h->push_write($buf);

            $h->read_http_res_headers(
                headers => 0,
                sub ( $h1, $res, $error_reason ) {
                    if ($error_reason) {
                        $self->finish_thread;

                        $cb->( undef, res [ 600, 'Invalid proxy connect response' ] );
                    }
                    else {
                        if ( $res->{status} == 200 ) {
                            $h->{proxy}      = $self;
                            $h->{proxy_type} = $PROXY_TYPE_HTTPS;
                            $h->{peername}   = $uri->host;

                            $cb->( $h, res 200 );
                        }
                        else {
                            $self->finish_thread;

                            $cb->( undef, res [ $res->{status}, $res->{reason} ] );
                        }
                    }

                    return;
                }
            );

            return;
        },
    );

    return;
}

sub connect_socks4 ( $self, $uri, @args ) {
    my $cb = pop @args;

    $uri = P->uri($uri) if !is_ref $uri;

    $self->start_thread;

    Pcore::AE::Handle->new(
        @args,
        connect => $self->{uri},
        on_connect_error => sub ( $h, $reason ) {
            $self->finish_thread;

            $cb->( undef, res [ 600, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $h->starttls('connect') if $self->{uri}->is_secure;

            AnyEvent::Socket::resolve_sockaddr $self->{uri}->host->name, $self->{uri}->connect_port, 'tcp', undef, undef, sub {
                my @target = @_;

                unless (@target) {
                    $self->finish_thread;

                    $cb->( undef, res [ 500, qq[Host name "@{[$self->{uri}->host->name]}" couldn't be resolved] ] );

                    return;
                }

                my $target = shift @target;

                $h->push_write( qq[\x04\x01] . pack( 'n', $self->{uri}->connect_port ) . AnyEvent::Socket::unpack_sockaddr( $target->[3] ) . $self->{uri}->userinfo . qq[\x00] );

                $h->unshift_read(
                    chunk => 8,
                    sub ( $h1, $chunk ) {
                        my $rep = unpack 'C*', substr( $chunk, 1, 1 );

                        # request granted
                        if ( $rep == 90 ) {
                            $h->{proxy}      = $self;
                            $h->{proxy_type} = $PROXY_TYPE_SOCKS4;
                            $h->{peername}   = $uri->host;

                            $cb->( $h, res 200 );
                        }

                        # request rejected or failed, tunnel creation error
                        elsif ( $rep == 91 ) {
                            $cb->( undef, res [ 500, 'Request rejected or failed' ] );
                        }

                        # request rejected becasue SOCKS server cannot connect to identd on the client
                        elsif ( $rep == 92 ) {
                            $cb->( undef, res [ 500, 'Request rejected becasue SOCKS server cannot connect to identd on the client' ] );
                        }

                        # request rejected because the client program and identd report different user-ids
                        elsif ( $rep == 93 ) {
                            $cb->( undef, res [ 500, 'Request rejected because the client program and identd report different user-ids' ] );
                        }

                        # unknown error or not SOCKS4 proxy response
                        else {
                            $cb->( undef, res [ 500, 'Invalid socks4 server response' ] );
                        }

                        return;
                    }
                );

                return;
            };

            return;
        },
    );

    return;
}

sub connect_socks5 ( $self, $uri, @args ) {
    my $cb = pop @args;

    $uri = P->uri($uri) if !is_ref $uri;

    $self->start_thread;

    Pcore::AE::Handle->new(
        @args,
        connect => $self->{uri},
        on_connect_error => sub ( $h, $reason ) {
            $self->finish_thread;

            $cb->( undef, res [ 600, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $h->starttls('connect') if $self->{uri}->is_secure;

            # start handshake
            # no authentication or authenticate with username/password
            if ( $self->{uri}->userinfo ) {
                $h->push_write(qq[\x05\x02\x00\x02]);
            }

            # no authentication
            else {
                $h->push_write(qq[\x05\x01\x00]);
            }

            $h->unshift_read(
                chunk => 2,
                sub ( $h1, $chunk ) {
                    my ( $ver, $auth_method ) = unpack 'C*', $chunk;

                    # no valid authentication method was proposed
                    if ( $auth_method == 255 ) {
                        $cb->( undef, res [ 500, 'No authentication method was found' ] );
                    }

                    # start username / password authentication
                    elsif ( $auth_method == 2 ) {

                        # send authentication credentials
                        $h->push_write( qq[\x01] . pack( 'C', length $self->{uri}->username ) . $self->{uri}->username . pack( 'C', length $self->{uri}->password ) . $self->{uri}->password );

                        # read authentication response
                        $h->unshift_read(
                            chunk => 2,
                            sub ( $h, $chunk ) {
                                my ( $auth_ver, $auth_status ) = unpack 'C*', $chunk;

                                # authentication error
                                if ( $auth_status != 0 ) {
                                    $cb->( undef, res [ 500, 'Authentication failure' ] );
                                }

                                # authenticated
                                else {
                                    $self->_socks5_establish_tunnel( $h, $uri, $cb );
                                }

                                return;
                            }
                        );
                    }

                    # no authentication is needed
                    elsif ( $auth_method == 0 ) {
                        $self->_socks5_establish_tunnel( $h, $uri, $cb );

                        return;
                    }

                    # unknown authentication method or not SOCKS5 response
                    else {
                        $cb->( undef, res [ 500, 'Authentication method is not supported' ] );
                    }

                    return;
                }
            );

            return;
        },
    );

    return;
}

sub _socks5_establish_tunnel ( $self, $h, $uri, $cb ) {

    # detect destination addr type
    if ( my $ipn4 = AnyEvent::Socket::parse_ipv4( $uri->host->name ) ) {    # IPv4 addr
        $h->push_write( qq[\x05\x01\x00\x01] . $ipn4 . pack( 'n', $uri->connect_port ) );
    }
    elsif ( my $ipn6 = AnyEvent::Socket::parse_ipv6( $uri->host->name ) ) {    # IPv6 addr
        $h->push_write( qq[\x05\x01\x00\x04] . $ipn6 . pack( 'n', $uri->connect_port ) );
    }
    else {                                                                     # domain name
        $h->push_write( qq[\x05\x01\x00\x03] . pack( 'C', length $uri->host->name ) . $uri->host->name . pack( 'n', $uri->connect_port ) );
    }

    $h->unshift_read(
        chunk => 4,
        sub ( $h1, $chunk ) {
            my ( $ver, $rep, $rsv, $atyp ) = unpack( 'C*', $chunk );

            if ( $rep == 0 ) {
                if ( $atyp == 1 ) {                                            # IPv4 addr, 4 bytes
                    $h->unshift_read(                                          # read IPv4 addr (4 bytes) + port (2 bytes)
                        chunk => 6,
                        sub ( $h1, $chunk ) {
                            $h->{proxy}      = $self;
                            $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
                            $h->{peername}   = $uri->host;

                            $cb->( $h, res 200 );

                            return;
                        }
                    );
                }
                elsif ( $atyp == 3 ) {    # domain name
                    $h->unshift_read(     # read domain name length
                        chunk => 1,
                        sub ( $h1, $chunk ) {
                            $h->unshift_read(    # read domain name + port (2 bytes)
                                chunk => unpack( 'C', $chunk ) + 2,
                                sub ( $h1, $chunk ) {
                                    $h->{proxy}      = $self;
                                    $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
                                    $h->{peername}   = $uri->host;

                                    $cb->( $h, res 200 );

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
                            $h->{proxy}      = $self;
                            $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
                            $h->{peername}   = $uri->host;

                            $cb->( $h, res 200 );

                            return;
                        }
                    );
                }
            }
            else {
                $cb->( undef, res [ 500, q[Tunnel creation error] ] );
            }

            return;
        }
    );

    return;
}

sub start_thread ($self) {
    $self->{threads}++;

    $self->{pool}->start_thread($self) if defined $self->{pool};

    return;
}

sub finish_thread ($self) {
    $self->{threads}--;

    $self->{pool}->finish_thread($self) if defined $self->{pool};

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 202, 275, 280, 297,  | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |      | 347, 350, 353        |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 207, 347, 350, 353,  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## |      | 359                  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
