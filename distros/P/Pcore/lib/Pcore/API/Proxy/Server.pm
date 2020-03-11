package Pcore::API::Proxy::Server;

use Pcore -class;
use Pcore::API::Proxy;

has listen => '//127.0.0.1';

has proxy => ();    # upstream proxy

has on_accept    => ();
has backlog      => 0;
has so_no_delay  => 1;
has so_keepalive => 1;

has _listen_socket => ( init_arg => undef );

sub BUILD ( $self, $args ) {
    $self->{proxy} = Pcore::API::Proxy->new( $self->{proxy} ) if $self->{proxy};

    $self->{listen} = P->net->parse_listen( $self->{listen} );

    $self->{_listen_socket} = &AnyEvent::Socket::tcp_server(    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
        $self->{listen}->connect,
        sub {
            Coro::async_pool sub { return $self->_on_accept(@_) }, @_;

            return;
        },
        sub {
            return $self->_on_prepare(@_);
        }
    );

    chmod( oct 777, $self->{listen}->{path} ) || die $! if !defined $self->{listen}->{host} && substr( $self->{listen}->{path}, 0, 2 ) ne "/\x00";

    return;
}

sub set_proxy ( $self, $proxy ) {
    $self->{proxy} = Pcore::API::Proxy->new($proxy);

    return;
}

sub _on_prepare ( $self, $fh, $host, $port ) {
    return $self->{backlog} // 0;
}

sub _on_accept ( $self, $fh, $host, $port ) {
    if ( my $on_accept = $self->{on_accept} ) {
        return if !$on_accept->( $self, $fh, $host, $port );
    }

    my $h = P->handle(
        $fh,
        so_no_delay  => $self->{so_no_delay},
        so_keepalive => $self->{so_keepalive},
    );

    my $chunk = $h->read_chunk(1);
    return if !$h;

    if ( $chunk->$* eq "\x05" ) {
        $self->_socks5( $h, $chunk->$* );
    }
    elsif ( $chunk->$* eq "\x04" ) {
        $self->_socks4( $h, $chunk->$* );
    }
    else {
        $self->_http( $h, $chunk->$* );
    }

    return;
}

# TODO
sub _socks4 ( $self, $h, $first ) {
    return;
}

# TODO
sub _socks5 ( $self, $h, $first ) {
    my $chunk = $h->read_chunk(1);
    return if !$h;

    my $nauth = unpack 'C*', $chunk->$*;

    $chunk = $h->read_chunk($nauth);
    return if !$h;

    $h->write("\x05\x00") or return;

    $chunk = $h->read_chunk(4);
    return if !$h;

    ( my $ver, my $cmd, my $rsv, my $type ) = unpack 'C*', $chunk->$*;    ## no critic qw[Variables::ProhibitUnusedVariables]

    my ( $target_host, $target_port );

    # TODO ipv4, 4 bytes
    if ( $type == 1 ) {
        $chunk = $h->read_chunk(6);
        return if !$h;

        die 'ipv4 not implemented';
    }

    # domain, 1 byte of name length followed by 1–255 bytes the domain name
    elsif ( $type == 3 ) {
        $chunk = $h->read_chunk(1);
        return if !$h;

        my $len = unpack 'C*', $chunk->$*;

        $chunk = $h->read_chunk( $len + 2 );
        return if !$h;

        ( $target_host, $target_port ) = unpack "a[$len]n", $chunk->$*;
    }

    # TODO ipv6, 16 bytes
    elsif ( $type == 4 ) {
        $chunk = $h->read_chunk(18);
        return if !$h;

        die 'ipv6 not implemented';
    }
    else {
        return;
    }

    my $proxy_h;

    # establish a TCP/IP stream connection
    if ( $cmd == 1 ) {

        # nas upstream proxy
        if ( my $proxy = $self->{proxy} ) {

            # upstream socks proxy
            if ( $proxy->{is_socks} ) {
                $proxy_h = $proxy->connect_socks5("//$target_host:$target_port");
            }

            # upstream http proxy
            else {
                # TODO if $target_port == 80 - need to parse HTTP request, substitute first header to full url

                $proxy_h = $proxy->connect_connect("//$target_host:$target_port");
            }
        }

        # no upstream proxy
        else {
            $proxy_h = P->handle("tcp://$target_host:$target_port");
        }

        if ( !$proxy_h ) {
            return;
        }
        else {
            $h->write( "\x05\x00\x00\x03" . pack( 'C', length $target_host ) . $target_host . pack( 'n', $target_port ) ) or return;
        }
    }

    # TODO establish a TCP/IP port binding
    elsif ( $cmd == 2 ) {
        die 'not supported';
    }

    # TODO associate a UDP port
    elsif ( $cmd == 3 ) {
        die 'not supported';
    }
    else {
        return;
    }

    $self->_run_tunnel( $h, $proxy_h );

    return;
}

# TODO maybe remove all oroxy-related headers
sub _http ( $self, $h, $first ) {
    my $chunk = $h->read_line("\r\n");
    return if !$h;

    $first .= $chunk->$*;

    my $proxy_h;

    my ( $method, $url, $proto ) = split /\s/sm, $first;

    # has upstream proxy
    if ( my $proxy = $self->{proxy} ) {

        # upstream http proxy
        if ( $proxy->{is_http} ) {
            if ( $method eq 'CONNECT' ) {

                # create CONNECT tunnel
                $proxy_h = $proxy->connect_connect("//$url");
                return if !$proxy_h;

                # read CONNECT request
                $h->{rbuf} = "\r\n$h->{rbuf}";
                $chunk = $h->read_line("\r\n\r\n");
                return if !$h;

                # write CONNECT response
                $h->write("HTTP/1.1 200 OK \r\n\r\n") or return;
            }
            else {

                # connect proxy
                $proxy_h = $proxy->connect_http($url);
                return if !$proxy_h;

                my $buf = "$first\r\n";

                $buf .= 'Proxy-Authorization: Basic ' . $proxy->{uri}->userinfo_b64 . "\r\n" if $proxy->{uri}->{userinfo};

                $proxy_h->write($buf) or return;
            }
        }

        # upstream socks proxy
        else {
            if ( $method eq 'CONNECT' ) {

                # create socks tunnel
                $proxy_h = $proxy->connect_socks("//$url");
                return if !$proxy_h;

                # read CONNECT request
                $h->{rbuf} = "\r\n$h->{rbuf}";
                $chunk = $h->read_line("\r\n\r\n");
                return if !$h;

                # write CONNECT response
                $h->write("HTTP/1.1 200 OK \r\n\r\n") or return;
            }
            else {

                # create socks tunnel
                $proxy_h = $proxy->connect_socks($url);
                return if !$proxy_h;

                $url = P->uri($url);

                $proxy_h->write( "$method " . $url->path_query . " $proto\r\n" ) or return;
            }
        }
    }

    # has no upstream proxy
    else {
        if ( $method eq 'CONNECT' ) {
            $proxy_h = P->handle("//$url");
            return if !$proxy_h;

            # read CONNECT request
            $h->{rbuf} = "\r\n$h->{rbuf}";
            $chunk = $h->read_line("\r\n\r\n");
            return if !$h;

            # write CONNECT response
            $h->write("HTTP/1.1 200 OK \r\n\r\n") or return;
        }
        else {
            $url = P->uri($url);

            $proxy_h = P->handle($url);
            return if !$proxy_h;

            $proxy_h->write( "$method " . $url->path_query . " $proto\r\n" ) or return;

            # TODO maybe remove all oroxy-related headers
        }
    }

    $self->_run_tunnel( $h, $proxy_h );

    return;
}

sub _run_tunnel ( $self, $h1, $h2 ) {

    # listen browser
    Coro::async_pool {
        while () {
            my $buf = $h1->read( timeout => undef );

            last             if !$h2;
            $h2->write($buf) if $buf;

            last if !$h1;
        }

        $h1->shutdown;
        $h2->shutdown;

        return;
    };

    # listen proxy
    Coro::async_pool {
        while () {
            my $buf = $h2->read( timeout => undef );

            last             if !$h1;
            $h1->write($buf) if $buf;

            last if !$h2;
        }

        $h1->shutdown;
        $h2->shutdown;

        return;
    };

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 82                   | * Subroutine "_socks5" with high complexity score (24)                                                         |
## |      | 185                  | * Subroutine "_http" with high complexity score (28)                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 162                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
