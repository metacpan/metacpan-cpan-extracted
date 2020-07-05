package Pcore::App::Controller::API;

use Pcore -role, -const;
use Pcore::Util::Data qw[from_json to_json from_cbor to_cbor];
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Pcore::WebSocket::softvisio;

with qw[Pcore::App::Controller];

const our $WS_MAX_MESSAGE_SIZE => 1_024 * 1_024 * 100;    # 100 Mb
const our $WS_COMPRESSION      => 0;

const our $TX_TYPE_RPC => 'rpc';

sub run ( $self, $req ) {
    return 404 if defined $req->{path};

    # WebSocket API request
    if ( $req->is_websocket_connect_request ) {

        # create connection and accept websocket connect request
        return Pcore::WebSocket::softvisio->accept(
            $req,
            max_message_size => $WS_MAX_MESSAGE_SIZE,
            compression      => $WS_COMPRESSION,
            on_auth          => sub ( $h, $token ) {
                return $self->{app}->{api}->authenticate($token);
            },
            on_bind => sub ( $h, $binding ) {
                return $self->on_bind( $h, $binding );
            },
            on_event => sub ( $h, $ev ) {
                return $self->on_event( $h, $ev );
            },
            on_rpc => sub ( $h, $tx ) {
                my $auth = $h->{auth} //= $self->{app}->{api}->authenticate;

                return $auth->api_call( $tx->{method}, $tx->{args}->@* );
            }
        );
    }

    # HTTP API request
    else {
        my $env = $req->{env};

        my $msg;

        my $CBOR = 0;

        # decode API request
        if ( !$env->{CONTENT_TYPE} || $env->{CONTENT_TYPE} =~ m[\bapplication/json\b]smi ) {
            $msg = eval { from_json $req->{data} };

            # content decode error
            return 400, q[Error decoding JSON request body] if $@;
        }

        elsif ( $env->{CONTENT_TYPE} =~ m[\bapplication/cbor\b]smi ) {
            $msg = eval { from_cbor $req->{data} };

            # content decode error
            return 400, q[Error decoding JSON request body] if $@;

            $CBOR = 1;
        }

        # invalid content type
        else {
            return 415;
        }

        # authenticate request
        my $auth = $req->authenticate;

        my $response = $self->_http_api_router( $auth, $msg );

        if ($CBOR) {

            # write HTTP response
            return 200, [ 'Content-Type' => 'application/cbor' ], to_cbor $response;
        }
        else {

            # write HTTP response
            return 200, [ 'Content-Type' => 'application/json' ], to_json $response;
        }
    }
}

sub _http_api_router ( $self, $auth, $data ) {
    my $response;

    my $cv = P->cv->begin;

    for my $tx ( is_plain_arrayref $data ? $data->@* : $data ) {
        next if !$tx->{type};

        # check message type, only rpc calls are enabled here
        if ( $tx->{type} eq $TX_TYPE_RPC ) {

            # method is not specified, this is callback, not supported in HTTP API server
            if ( !$tx->{method} ) {
                push $response->@*,
                  { type   => $TX_TYPE_RPC,
                    id     => $tx->{id},
                    result => {
                        status => 400,
                        reason => 'Method is required',
                    },
                  };

                next;
            }

            my $id = $tx->{id};

            $cv->begin if $id;

            Coro::async_pool {
                my $res = $auth->api_call( $tx->{method}, $tx->{args}->@* );

                if ($id) {
                    push $response->@*,
                      { type   => $TX_TYPE_RPC,
                        id     => $tx->{id},
                        result => $res,
                      };

                    $cv->end;
                }

                return;
            };
        }
    }

    $cv->end->recv;

    return $response;
}

sub on_connect ( $self, $ws ) {
    return;
}

sub on_subscribe_event ( $self, $h, $event ) {
    return;
}

sub on_event ( $self, $h, $ev ) {
    return;
}

sub get_nginx_cfg ($self) {
    my $tmpl = <<'NGINX';
    # api "<: $location :>"
: if $location == '/' {
    location =/ {
        error_page 418 = @backend;
        return 418;
    }

    # serve static
    location / {
        rewrite ^/favicon.ico$ /cdn/favicon.ico last;
        rewrite ^/robots.txt$ /cdn/robots.txt last;

        return 404;
    }
: } else {
    location =<: $location :> {
        error_page 418 = @backend;
        return 418;
    }

    location =<: $location :>/ {
        error_page 418 = @backend;
        return 418;
    }

    location <: $location :>/ {
        return 404;
    }
: }
NGINX

    return P->tmpl->( \$tmpl, { location => $self->{path} } )->$*;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
