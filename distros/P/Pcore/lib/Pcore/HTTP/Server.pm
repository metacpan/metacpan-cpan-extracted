package Pcore::HTTP::Server;

use Pcore -class, -const, -res;
use Pcore::AE::Handle;
use AnyEvent::Socket qw[];
use Pcore::HTTP::Server::Request;

# listen:
# - unix:/socket/path
# - unix:abstract-socket-name
# - *:80
# - 127.0.0.1:80

has listen => ( is => 'ro', isa => Str, required => 1 );
has app => ( is => 'ro', isa => CodeRef | InstanceOf ['Pcore::App::Router'], required => 1 );

has backlog          => ( is => 'ro', isa => Maybe [PositiveOrZeroInt], default => 0 );
has tcp_no_delay     => ( is => 'ro', isa => Bool,                      default => 1 );
has tcp_so_keepalive => ( is => 'ro', isa => Bool,                      default => 1 );

has server_tokens         => ( is => 'ro', isa => Maybe [Str],       default => "Pcore-HTTP-Server/$Pcore::VERSION" );
has keepalive_timeout     => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );                                    # 0 - disable keepalive
has client_header_timeout => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );                                    # 0 - do not use
has client_body_timeout   => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );                                    # 0 - do not use
has client_max_body_size  => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );                                     # 0 - do not check

has _listen_socket => ( is => 'ro', isa => Object, init_arg => undef );

const our $PSGI_ENV => {
    'psgi.version'      => [ 1, 1 ],
    'psgi.url_scheme'   => 'http',
    'psgi.input'        => undef,
    'psgi.errors'       => undef,
    'psgi.multithread'  => 0,
    'psgi.multiprocess' => 0,
    'psgi.run_once'     => 0,
    'psgi.nonblocking'  => 1,
    'psgi.streaming'    => 1,

    # extensions
    'psgix.io'              => undef,
    'psgix.input.buffered'  => 1,
    'psgix.logger'          => undef,
    'psgix.session'         => undef,
    'psgix.session.options' => undef,
    'psgix.harakiri'        => 0,
    'psgix.harakiri.commit' => 0,
    'psgix.cleanup'         => 0,
};

# TODO implement shutdown and graceful shutdown

sub run ($self) {

    # parse listen
    if ( $self->{listen} =~ /\Aunix:(.+)/sm ) {
        my $path = $1;

        $self->{_listen_socket} = AnyEvent::Socket::tcp_server( 'unix/', $path, sub { return $self->_on_accept(@_) }, sub { return $self->_on_prepare(@_) } );

        chmod oct 777, $path or die if substr( $path, 0, 1 ) eq '/';
    }
    else {
        my ( $host, $port ) = split /:/sm, $self->{listen};

        die qq[Invalid listen "$self->{listen}"] if !$host || !$port;

        undef $host if $host eq '*';

        $self->{_listen_socket} = AnyEvent::Socket::tcp_server( $host, $port, sub { return $self->_on_accept(@_) }, sub { return $self->_on_prepare(@_) } );
    }

    return $self;
}

sub _on_prepare ( $self, $fh, $host, $port ) {
    return $self->backlog // 0;
}

sub _on_accept ( $self, $fh, $host, $port ) {
    Pcore::AE::Handle->new(
        fh              => $fh,
        tcp_no_delay    => $self->tcp_no_delay,
        tcp_so_kepalive => $self->tcp_so_keepalive,
        on_connect      => sub ( $h, @ ) {
            $self->wait_headers($h);

            return;
        }
    );

    return;
}

sub _read_body ( $self, $h, $env, $cb ) {
    my ( $chunked, $content_length ) = ( 0, 0 );

    # https://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.4
    # Transfer-Encoding has priority before Content-Length

    # chunked body
    if ( $env->{TRANSFER_ENCODING} && $env->{TRANSFER_ENCODING} =~ /\bchunked\b/smi ) {
        $chunked = 1;
    }

    # fixed body size
    elsif ( $env->{CONTENT_LENGTH} ) {
        $content_length = $env->{CONTENT_LENGTH};
    }

    # no body
    else {
        $cb->(undef);

        return;
    }

    # set client body timeout
    if ( $self->{client_body_timeout} ) {
        $h->rtimeout_reset;
        $h->rtimeout( $self->{client_body_timeout} );
        $h->on_rtimeout( sub ($h) {

            # client body read timeout
            $self->return_xxx( $h, 408 );

            return;
        } );
    }

    $h->read_http_body(
        sub ( $h1, $buf_ref, $total_bytes_readed, $error_reason ) {

            # read body error
            if ($error_reason) {

                # read body error
                $cb->(400);
            }
            else {

                # read body finished
                if ( !$buf_ref ) {

                    # clear client body timeout
                    $h->rtimeout(undef);

                    $cb->(undef);
                }

                # read body chunk
                else {
                    if ( $self->{client_max_body_size} && $total_bytes_readed > $self->{client_max_body_size} ) {

                        # payload too large
                        $cb->(413);
                    }
                    else {
                        $env->{'psgi.input'} .= $buf_ref->$*;

                        $env->{CONTENT_LENGTH} = $total_bytes_readed;

                        return 1;
                    }
                }
            }

            return;
        },
        chunked  => $chunked,
        length   => $content_length,
        headers  => 0,
        buf_size => 65_536,
    );

    return;
}

sub wait_headers ( $self, $h ) {
    state $destroy = sub ( $h, @ ) {
        $h->destroy;

        return;
    };

    $h->on_error($destroy);
    $h->on_eof(undef);
    $h->on_rtimeout(undef);
    $h->rtimeout_reset;

    # set keepalive timeout
    $h->rtimeout( $self->{keepalive_timeout} || $self->{client_header_timeout} );

    $h->on_read( sub {

        # clear on_read callback
        $h->on_read(undef);

        # set client header timeout
        if ( $self->{client_header_timeout} ) {
            $h->rtimeout_reset;
            $h->rtimeout( $self->{client_header_timeout} );
            $h->on_rtimeout( sub ($h) {

                # client header read timeout
                $self->return_xxx( $h, 408 );

                return;
            } );
        }
        else {

            # clear keepalive timeout
            $h->rtimeout(undef);
        }

        # read HTTP headers
        $h->read_http_req_headers(
            sub ( $h1, $env, $error_reason ) {
                if ($error_reason) {

                    # HTTP headers parsing error, request is invalid
                    # return standard error response and destroy the handle
                    # 400 - Bad Request
                    $self->return_xxx( $h, 400 );
                }
                else {

                    # clear client header timeout
                    $h->rtimeout(undef);

                    # add default psgi env keys
                    $env->@{ keys $PSGI_ENV->%* } = values $PSGI_ENV->%*;

                    # read HTTP body
                    $self->_read_body(
                        $h, $env,
                        sub ($body_error_status) {
                            if ($body_error_status) {

                                # body read error
                                $self->return_xxx( $h, $body_error_status );
                            }
                            else {

                                # create request object
                                my $req = bless {
                                    _server          => $self,
                                    _h               => $h,
                                    env              => $env,
                                    _response_status => 0,
                                  },
                                  'Pcore::HTTP::Server::Request';

                                # evaluate application
                                eval { $self->{app}->($req); 1; } or do {
                                    $@->sendlog if $@;
                                };
                            }

                            return;
                        }
                    );
                }

                return;
            }
        );

        return;
    } );

    return;
}

sub return_xxx ( $self, $h, $status, $use_keepalive = 0 ) {
    $status = 0+ $status;
    my $reason = Pcore::Util::Result::get_standard_reason($status);

    my $buf = "HTTP/1.1 $status $reason\r\nContent-Length:0\r\n";

    $buf .= 'Connection:' . ( $use_keepalive ? 'keep-alive' : 'close' ) . $CRLF;

    $buf .= "Server:$self->{server_tokens}\r\n" if $self->{server_tokens};

    $h->push_write( $buf . $CRLF );

    # process handle
    if   ($use_keepalive) { $self->wait_headers($h) }
    else                  { $h->destroy }

    return;
}

1;
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
