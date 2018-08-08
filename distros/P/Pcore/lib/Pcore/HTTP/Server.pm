package Pcore::HTTP::Server;

use Pcore -class, -const, -res;
use AnyEvent::Socket qw[];
use Pcore::HTTP::Server::Request;

# listen:
# - unix:/socket/path
# - unix:abstract-socket-name
# - *:80
# - 127.0.0.1:80

has listen => ();    # ( is => 'ro', isa => Str, required => 1 );
has app    => ();    # ( is => 'ro', isa => CodeRef | InstanceOf ['Pcore::App::Router'], required => 1 );

has backlog      => 0;    # ( is => 'ro', isa => Maybe [PositiveOrZeroInt], default => 0 );
has so_no_delay  => 1;    # ( is => 'ro', isa => Bool,                      default => 1 );
has so_keepalive => 1;    # ( is => 'ro', isa => Bool,                      default => 1 );

has server_tokens         => "Pcore-HTTP-Server/$Pcore::VERSION";    # ( is => 'ro', isa => Maybe [Str] );
has keepalive_timeout     => 60;                                     # ( is => 'ro', isa => PositiveOrZeroInt, default => 60 ); # 0 - disable keepalive
has client_header_timeout => 60;                                     # ( is => 'ro', isa => PositiveOrZeroInt, default => 60 ); # 0 - do not use
has client_body_timeout   => 60;                                     # ( is => 'ro', isa => PositiveOrZeroInt, default => 60 ); # 0 - do not use
has client_max_body_size  => 0;                                      # 0 - do not check

has _listen_socket => ();                                            # ( is => 'ro', isa => Object, init_arg => undef );

# TODO implement shutdown and graceful shutdown

sub run ($self) {

    # parse listen
    if ( $self->{listen} =~ /\Aunix:(.+)/sm ) {
        my $path = $1;

        $self->{_listen_socket} = AnyEvent::Socket::tcp_server( 'unix/', $path, Coro::unblock_sub { return $self->_on_accept(@_) }, sub { return $self->_on_prepare(@_) } );

        chmod oct 777, $path or die if substr( $path, 0, 1 ) eq '/';
    }
    else {
        my ( $host, $port ) = split /:/sm, $self->{listen};

        die qq[Invalid listen "$self->{listen}"] if !$host || !$port;

        undef $host if $host eq '*';

        $self->{_listen_socket} = AnyEvent::Socket::tcp_server( $host, $port, Coro::unblock_sub { return $self->_on_accept(@_) }, sub { return $self->_on_prepare(@_) } );
    }

    return $self;
}

sub _on_prepare ( $self, $fh, $host, $port ) {
    return $self->{backlog} // 0;
}

sub _on_accept ( $self, $fh, $host, $port ) {
    my $h = P->handle(
        $fh,
        so_no_delay  => $self->{so_no_delay},
        so_keepalive => $self->{so_keepalive},
    );

    # read HTTP headers
  READ_HEADERS: my $env = $h->read_http_req_headers( timeout => $self->{client_header_timeout} );

    # HTTP headers read error
    if ( !$env ) {
        if ( $h->is_timeout ) {
            $self->return_xxx( $h, 408 );
        }
        else {
            $self->return_xxx( $h, 400 );
        }

        return;
    }

    # read HTTP body
    # https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.4
    # Transfer-Encoding has priority before Content-Length

    my $data;

    # chunked body
    if ( $env->{TRANSFER_ENCODING} && $env->{TRANSFER_ENCODING} =~ /\bchunked\b/smi ) {
        my $payload_too_large;

        my $on_read_len = do {
            if ( $self->{client_max_body_size} ) {
                sub ( $len, $total_bytes ) {
                    if ( $total_bytes > $self->{client_max_body_size} ) {
                        $payload_too_large = 1;

                        return;
                    }
                    else {
                        return 1;
                    }
                };
            }
            else {
                undef;
            }
        };

        $data = $h->read_http_chunked_data( timeout => $self->{client_body_timeout}, on_read_len => $on_read_len );

        # HTTP body read error
        if ( !$data ) {

            # payload too large
            if ($payload_too_large) {
                return $self->return_xxx( $h, 413 );
            }

            # timeout
            elsif ( $h->is_timeout ) {
                return $self->return_xxx( $h, 408 );
            }

            # read error
            else {
                return $self->return_xxx( $h, 400 );
            }
        }

        $env->{CONTENT_LENGTH} = length $data->$*;
    }

    # fixed body size
    elsif ( $env->{CONTENT_LENGTH} ) {

        # payload too large
        return $self->return_xxx( $h, 413 ) if $self->{client_max_body_size} && $self->{client_max_body_size} > $env->{CONTENT_LENGTH};

        $data = $h->readchunk( $env->{CONTENT_LENGTH}, timeout => $self->{client_body_timeout} );

        # HTTP body read error
        if ( !$data ) {

            # timeout
            if ( $h->is_timeout ) {
                return $self->return_xxx( $h, 408 );
            }

            # read error
            else {
                return $self->return_xxx( $h, 400 );
            }
        }
    }

    my $keepalive = do {
        if ( !$self->{keepalive_timeout} ) {
            0;
        }
        else {
            if ( $env->{SERVER_PROTOCOL} eq 'HTTP/1.1' ) {
                $env->{HTTP_CONNECTION} && $env->{HTTP_CONNECTION} =~ /\bclose\b/smi ? 0 : 1;
            }
            elsif ( $env->{SERVER_PROTOCOL} eq 'HTTP/1.0' ) {
                !$env->{HTTP_CONNECTION} || $env->{HTTP_CONNECTION} !~ /\bkeep-?alive\b/smi ? 0 : 1;
            }
            else {
                1;
            }
        }
    };

    my $rouse_cb = Coro::rouse_cb;

    Coro::async_pool {

        # create request object
        my $req = bless {
            _server          => $self,
            _h               => $h,
            _cb              => $rouse_cb,
            env              => $env,
            data             => $data,
            keepalive        => $keepalive,
            _response_status => 0,
          },
          'Pcore::HTTP::Server::Request';

        # evaluate application
        eval { $self->{app}->($req); 1; } or do {
            $@->sendlog if $@;
        };
    };

    # keep-alive
    goto READ_HEADERS if !Coro::rouse_wait $rouse_cb && $keepalive;

    return;
}

sub return_xxx ( $self, $h, $status, $close_connection = 1 ) {

    # handle closed, do nothing
    return if !$h;

    $status = 0+ $status;

    my $reason = Pcore::Util::Result::get_standard_reason($status);

    my $buf = "HTTP/1.1 $status $reason\r\nContent-Length:0\r\n";

    $buf .= 'Connection:' . ( $close_connection ? 'close' : 'keep-alive' ) . $CRLF;

    $buf .= "Server:$self->{server_tokens}\r\n" if $self->{server_tokens};

    $h->write( $buf . $CRLF );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 57                   | Subroutines::ProhibitExcessComplexity - Subroutine "_on_accept" with high complexity score (33)                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
