package Pcore::Proxy::Server;

use Pcore -class;
use Pcore::Proxy;
use Pcore::AE::Handle;
use Pcore::Util::Scalar qw[weaken];

has host      => ( is => 'ro',   isa => Str, default => '127.0.0.1' );
has port      => ( is => 'lazy', isa => PositiveInt );
has key_file  => ( is => 'lazy', isa => Str );
has cert_file => ( is => 'lazy', isa => Str );

has on_req => ( is => 'ro', isa => Maybe [CodeRef] );
has on_res => ( is => 'ro', isa => Maybe [CodeRef] );

has _tcp_server => ( is => 'ro', isa => InstanceOf ['Guard'], init_arg => undef );

sub _build_port ($self) {
    return P->sys->get_free_port( $self->host ) // die q[Error get free port];
}

sub _build_key_file ($self) {
    return $ENV->{share}->get('data/proxy.pem');
}

sub _build_cert_file ($self) {
    return $ENV->{share}->get('data/proxy.crt');
}

sub run ($self) {
    weaken $self;

    $self->{_tcp_server} = AnyEvent::Socket::tcp_server( $self->host, $self->port, sub { $self->_on_accept(@_) } );

    return;
}

sub _on_accept ( $self, $fh, $host, $port ) {
    Pcore::AE::Handle->new(
        fh       => $fh,
        on_error => sub ( $h, $fatal, $reason ) {
            return;
        },
        on_connect => sub ( $h1, @ ) {
            $h1->on_read( sub ($h) {
                $h->read_http_req_headers(
                    sub ( $h, $env, $error ) {
                        if ( $env->{REQUEST_METHOD} eq 'CONNECT' ) {
                            my $host = $env->{HTTP_HOST};

                            $h->push_write("HTTP/1.1 200 OK${CRLF}${CRLF}");

                            $h->starttls(
                                'accept',
                                {   cache           => 1,
                                    verify          => undef,
                                    verify_peername => undef,
                                    sslv2           => 1,
                                    dh              => undef,              # Diffie-Hellman is disabled
                                    key_file        => $self->key_file,
                                    cert_file       => $self->cert_file,
                                }
                            );

                            $h->read_http_req_headers(
                                sub ( $h, $env, $error ) {
                                    $self->_read_body(
                                        $h, $env,
                                        sub ($body) {
                                            $self->_proxy_req(
                                                "https://${host}$env->{REQUEST_URI}",
                                                $env, $body,
                                                sub ($res) {
                                                    $self->_return_res( $h, $res );

                                                    undef $h1;

                                                    return;
                                                }
                                            );

                                            return;
                                        }
                                    );

                                    return;
                                }
                            );
                        }
                        else {
                            $self->_read_body(
                                $h, $env,
                                sub ($body) {
                                    $self->_proxy_req(
                                        $env->{REQUEST_URI},
                                        $env, $body,
                                        sub ($res) {
                                            $self->_return_res( $h, $res );

                                            undef $h1;

                                            return;
                                        }
                                    );

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

sub _proxy_req ( $self, $url, $env, $body, $cb ) {
    P->http->request(
        method            => $env->{REQUEST_METHOD},
        url               => $url,
        headers           => { map { $_ => $env->{$_} } grep {/\AHTTP_/sm} keys $env->%* },
        accept_compressed => 0,
        max_redirects     => 0,
        body              => $body,
        tls_ctx           => undef,
        sub ($res) {
            $res->headers->{CONTENT_LENGTH} = length( $res->{body} ? $res->{body}->$* : q[] );
            $res->headers->{CONNECTION} = 'close';
            delete $res->headers->{TRANSFER_ENCODING};

            $self->{on_res}->( $self, $res ) if $self->{on_res};

            $cb->($res);

            return;
        }
    );

    return;
}

sub _return_res ( $self, $h, $res ) {
    my $buf = "HTTP/1.1 $res->{status} $res->{reason}" . $CRLF;

    $buf .= $res->headers->to_string . $CRLF;

    $buf .= $res->{body}->$* if $res->{body};

    $h->push_write($buf);

    $h->destroy;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Proxy::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by zdm.

=cut
