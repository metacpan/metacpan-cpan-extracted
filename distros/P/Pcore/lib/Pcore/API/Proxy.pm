package Pcore::API::Proxy;

use Pcore -const, -class, -res, -export;
use Pcore::Util::Scalar qw[is_ref];

our $EXPORT = { PROXY_TYPE => [qw[$PROXY_TYPE_HTTP $PROXY_TYPE_CONNECT $PROXY_TYPE_SOCKS4 $PROXY_TYPE_SOCKS4A $PROXY_TYPE_SOCKS5]] };

has uri        => ( required => 1 );    # InstanceOf['Pcore::Util::URI']
has is_http    => ();
has is_connect => ();
has is_socks4  => ();
has is_socks4a => ();
has is_socks5  => ();

has pool => ();                         # Maybe [Object]

has threads => ( 0, init_arg => undef );

const our $PROXY_TYPE_HTTP    => 1;
const our $PROXY_TYPE_CONNECT => 2;
const our $PROXY_TYPE_SOCKS4  => 3;
const our $PROXY_TYPE_SOCKS4A => 4;
const our $PROXY_TYPE_SOCKS5  => 5;

around new => sub ( $orig, $self, $uri ) {
    my $args;

    $args->{uri} = is_ref $uri ? $uri : P->uri($uri);

    my $scheme = $args->{uri}->{scheme};

    if ( $scheme eq 'http' ) {
        $args->{is_http} = 1;
    }
    elsif ( $scheme eq 'connect' ) {
        $args->{is_connect} = 1;
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

    if ( $uri->{is_http} ) {
        $type = 'http'    if !$uri->{is_secure} && $self->{is_http};
        $type = 'connect' if !$type             && $self->{is_connect};
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
        return res [ 500, 'No proxy connect method found' ];
    }
}

sub connect_http ( $self, $uri, @args ) {
    $uri = P->uri($uri) if !is_ref $uri;

    # TODO
    # $self->start_thread;
    # $self->finish_thread;

    my $h = P->handle( $self->{uri}, @args );

    # connect error
    return $h if !$h;

    $h->{proxy}      = $self;
    $h->{proxy_type} = $PROXY_TYPE_HTTP;

    return $h;
}

sub connect_connect ( $self, $uri, @args ) {
    $uri = P->uri($uri) if !is_ref $uri;

    # TODO
    # $self->start_thread;
    # $self->finish_thread;

    my $h = P->handle( $self->{uri}, @args );

    # connect error
    return $h if !$h;

    my $buf = "CONNECT $uri->{host}:" . $uri->connect_port . " HTTP/1.1\r\n";

    $buf .= 'Proxy-Authorization: Basic ' . $self->{uri}->userinfo_b64 . "\r\n" if $self->{uri}->{userinfo};

    $buf .= "\r\n";

    $h->write($buf) or return $h;

    my $headers = $h->read_http_res_headers or return $h;

    # connection error
    if ( $headers->{status} != 200 ) {
        $h->set_protocol_error( $headers->{reason} );

        return $h;
    }

    $h->{proxy}      = $self;
    $h->{proxy_type} = $PROXY_TYPE_CONNECT;
    $h->{peername}   = $uri->{host};

    return $h;
}

sub connect_socks4 ( $self, $uri, @args ) {
    $uri = P->uri($uri) if !is_ref $uri;

    # TODO
    # $self->start_thread;
    # $self->finish_thread;

    my $h = P->handle( $self->{uri}, @args );

    # connection error
    return $h if !$h;

    AnyEvent::Socket::resolve_sockaddr $self->{uri}->{host}->{name}, $self->{uri}->connect_port, 'tcp', undef, undef, my $cv = P->cv;

    my @target = $cv->recv;

    if ( !@target ) {
        $h->set_protocol_error(qq[Host name "$self->{uri}->{host}->{name}" can't be resolved]);

        return $h;
    }

    my $target = shift @target;

    my $buf = "\x04\x01" . pack( 'n', $self->{uri}->connect_port ) . AnyEvent::Socket::unpack_sockaddr( $target->[3] );

    $buf .= $self->{uri}->{userinfo} // $EMPTY;

    $buf .= "\x00";

    $h->write($buf) or return $h;

    my $chunk = $h->read_chunk(8) or return $h;

    my $rep = unpack 'C*', substr( $chunk->$*, 1, 1 );

    # request granted
    if ( $rep == 90 ) {
        $h->{proxy}      = $self;
        $h->{proxy_type} = $PROXY_TYPE_SOCKS4;
        $h->{peername}   = $uri->{host};
    }

    # request rejected or failed, tunnel creation error
    elsif ( $rep == 91 ) {
        $h->set_protocol_error('Request rejected or failed');
    }

    # request rejected becasue SOCKS server cannot connect to identd server
    elsif ( $rep == 92 ) {
        $h->set_protocol_error('Request failed because client is not running identd (or not reachable from the server)');
    }

    # request rejected because the client program and identd report different user-ids
    elsif ( $rep == 93 ) {
        $h->set_protocol_error(q[Request failed because client's identd could not confirm the user ID string in the request]);
    }

    # unknown error or not SOCKS4 proxy response
    else {
        $h->set_protocol_error('Invalid socks4 server response');
    }

    return $h;
}

sub connect_socks5 ( $self, $uri, @args ) {
    $uri = P->uri($uri) if !is_ref $uri;

    # TODO
    # $self->start_thread;
    # $self->finish_thread;

    my $h = P->handle( $self->{uri}, @args );

    # connection error
    return $h if !$h;

    # start handshake
    # authenticate with username/password
    if ( $self->{uri}->{userinfo} ) {
        $h->write("\x05\x02\x00\x02") or return $h;
    }

    # no authentication
    else {
        $h->write("\x05\x01\x00") or return $h;
    }

    my $chunk = $h->read_chunk(2) or return $h;

    my ( $ver, $auth_method ) = unpack 'C*', $chunk->$*;

    # no valid authentication method was proposed
    if ( $auth_method == 255 ) {
        $h->set_protocol_error('No authentication method was found');

        return $h;
    }

    # start username / password authentication
    elsif ( $auth_method == 2 ) {

        # send authentication credentials
        $h->write( "\x01" . pack( 'C', length $self->{uri}->{username} ) . $self->{uri}->{username} . pack( 'C', length $self->{uri}->{password} ) . $self->{uri}->{password} ) or return $h;

        # read authentication response
        $chunk = $h->read_chunk(2) or return $h;

        my ( $auth_ver, $auth_status ) = unpack 'C*', $chunk->$*;

        # authentication error
        if ( $auth_status != 0 ) {
            $h->set_protocol_error('Authentication failure');

            return $h;
        }

        # authenticated
        else {
            return $self->_socks5_establish_tunnel( $h, $uri );
        }
    }

    # no authentication is needed
    elsif ( $auth_method == 0 ) {
        return $self->_socks5_establish_tunnel( $h, $uri );
    }

    # unknown authentication method or not SOCKS5 response
    else {
        $h->set_protocol_error('Authentication method is not supported');

        return $h;
    }
}

sub _socks5_establish_tunnel ( $self, $h, $uri ) {

    # detect destination addr type
    # IPv4 addr
    if ( my $ipn4 = AnyEvent::Socket::parse_ipv4( $uri->{host}->{name} ) ) {
        $h->write( "\x05\x01\x00\x01" . $ipn4 . pack( 'n', $uri->connect_port ) ) or return $h;
    }

    # IPv6 addr
    elsif ( my $ipn6 = AnyEvent::Socket::parse_ipv6( $uri->{host}->{name} ) ) {
        $h->write( "\x05\x01\x00\x04" . $ipn6 . pack( 'n', $uri->connect_port ) ) or return $h;
    }

    # domain name
    else {
        $h->write( "\x05\x01\x00\x03" . pack( 'C', length $uri->{host}->{name} ) . $uri->{host}->{name} . pack( 'n', $uri->connect_port ) ) or return $h;
    }

    my $chunk = $h->read_chunk(4) or return $h;

    my ( $ver, $rep, $rsv, $atyp ) = unpack 'C*', $chunk->$*;

    if ( $rep == 0 ) {

        # IPv4 addr, 4 bytes
        if ( $atyp == 1 ) {

            # read IPv4 addr (4 bytes) + port (2 bytes)
            my $ip_port = $h->read_chunk(6) or return $h;

            # connected
            $h->{proxy}      = $self;
            $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
            $h->{peername}   = $uri->{host};

            return $h;
        }

        # domain name
        elsif ( $atyp == 3 ) {

            # read domain name length
            my $len = $h->read_chunk(1) or return $h;

            # read domain name + port (2 bytes)
            my $host_port = $h->read_chunk( unpack( 'C', $len->$* ) + 2 ) or return $h;

            # connected
            $h->{proxy}      = $self;
            $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
            $h->{peername}   = $uri->{host};

            return $h;
        }

        # IPv6 addr, 16 bytes
        elsif ( $atyp == 4 ) {

            # read IPv6 addr (16 bytes) + port (2 bytes)
            $chunk = $h->read_chunk(18) or return $h;

            # connected
            $h->{proxy}      = $self;
            $h->{proxy_type} = $PROXY_TYPE_SOCKS5;
            $h->{peername}   = $uri->{host};

            return $h;
        }
    }

    $h->set_protocol_error(q[Tunnel creation error]);

    return $h;
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
## |    1 | 165, 273, 278, 283   | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
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
