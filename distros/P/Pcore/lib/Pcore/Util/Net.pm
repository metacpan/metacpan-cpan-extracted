package Pcore::Util::Net;

use Pcore -export;

our $EXPORT = [qw[hostname get_free_port check_port parse_listen]];

sub hostname {
    state $hostname = do {
        require Sys::Hostname;    ## no critic qw[Modules::ProhibitEvilModules]

        Sys::Hostname::hostname();
    };

    return $hostname;
}

sub get_free_port : prototype(;$) ( $ip = undef ) {
    require Socket;

    if ($ip) {
        $ip = Socket::inet_aton $ip;
    }
    else {
        $ip = "\x7f\x00\x00\x01";    # 127.0.0.1
    }

    for ( 1 .. 10 ) {
        socket my $socket, Socket::AF_INET(), Socket::SOCK_STREAM(), 0 or next;

        bind $socket, Socket::pack_sockaddr_in 0, $ip or next;

        my $sockname = getsockname $socket or next;

        my ( $bind_port, $bind_ip ) = Socket::sockaddr_in($sockname);

        return $bind_port;
    }

    return;
}

sub check_port : prototype($$;$) ( $host, $port, $timeout = 1 ) {
    my $cv = P->cv;

    AnyEvent::Socket::tcp_connect(
        $host, $port,
        sub ( $fh = undef, @ ) {
            $cv->( defined $fh );

            return;
        },
        sub {
            return $timeout;
        }
    );

    return $cv->recv;
}

# - /socket/path
# - abstract-socket-name
# - //0.0.0.0:80
# - //127.0.0.1:80
# - //127.0.0.1 - random free port
sub parse_listen : prototype($;$) ( $uri, $default_port = undef ) {
    $uri = P->uri( $uri, base => 'tcp:', listen => 1 );

    if ( $uri->{host} && !$uri->{port} ) {
        $uri->set_port( $default_port || get_free_port $uri->{host} );
    }

    return $uri;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Net

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
