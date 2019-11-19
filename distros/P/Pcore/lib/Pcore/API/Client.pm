package Pcore::API::Client;

use Pcore -class, -res;

# use Pcore::WebSocket;
use Pcore::Lib::Scalar qw[is_callback is_plain_arrayref is_plain_coderef weaken];
use Pcore::Lib::Data qw[to_cbor from_cbor];
use Pcore::Lib::UUID qw[uuid_v1mc_str];
use Pcore::HTTP qw[:TLS_CTX];

has uri => ( required => 1 );    # InstanceOf ['Pcore::Lib::URI'], http://token@host:port/api/, ws://token@host:port/api/

has token   => ();
has api_ver => ();               # eg: 'v1', default API version for relative methods

has tls_ctx         => $TLS_CTX_HIGH;    # Maybe [ HashRef | Enum [ $TLS_CTX_LOW, $TLS_CTX_HIGH ] ]
has connect_timeout => 10;

# HTTP options
has persistent => 600;
has timeout    => ();

# WebSocket options
has compression    => 0;
has bind_events    => ();
has forward_events => ();
has on_connect     => ();                # Maybe [CodeRef]
has on_disconnect  => ();                # Maybe [CodeRef]
has on_rpc         => ();                # Maybe [CodeRef]
has on_ping        => ();                # Maybe [CodeRef]
has on_pong        => ();                # Maybe [CodeRef]

has _is_http => ( required => 1 );

has _ws           => ( init_arg => undef );
has _get_ws_exec  => ( init_arg => undef );
has _get_ws_queue => ( init_arg => undef );

sub DESTROY ( $self ) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        $self->{_ws}->disconnect if $self->{_ws};
    }

    return;
}

sub BUILDARGS ( $self, $uri, %args ) {
    $args{uri} = P->uri($uri);

    $args{token} //= $args{uri}->{userinfo};

    $args{_is_http} = $args{uri}->{is_http};

    return \%args;
}

sub set_token ( $self, $token = undef ) {
    if ( $token // $EMPTY ne $self->{token} // $EMPTY ) {
        $self->{token} = $token;

        $self->disconnect;
    }

    return;
}

sub disconnect ($self) {
    undef $self->{_ws};

    return;
}

sub api_call ( $self, $method, @args ) {

    # add version to relative method id
    if ( substr( $method, 0, 1 ) ne q[/] ) {
        if ( $self->{api_ver} ) {
            $method = "/$self->{api_ver}/$method";
        }
        else {
            die q[You need to define default "api_ver" to use relative methods names];
        }
    }

    if ( $self->{_is_http} ) {
        return $self->_send_http( $method, \@args );
    }
    else {
        return $self->_send_ws( $method, \@args );
    }
}

sub _send_http ( $self, $method, $args ) {
    my $payload = {
        type   => 'rpc',
        method => $method,
        args   => $args,
        ( defined wantarray ? ( tid => uuid_v1mc_str ) : () ),
    };

    my $res = P->http->post(
        $self->{uri},
        connect_timeout => $self->{connect_timeout},

        # persistent      => $self->{persistent},
        tls_ctx => $self->{tls_ctx},
        ( $self->{timeout} ? ( timeout => $self->{timeout} ) : () ),
        headers => [
            Referer        => undef,
            Authorization  => "Token $self->{token}",
            'Content-Type' => 'application/cbor',
        ],
        data => to_cbor($payload)
    );

    if ( !$res ) {
        return res [ $res->{status}, $res->{reason} ];
    }
    else {
        my $msg = eval { from_cbor $res->{data} };

        if ($@) {
            return res [ 500, 'Error decoding response' ];
        }
        else {
            my $tx = is_plain_arrayref $msg ? $msg->[0] : $msg;

            if ( $tx->{type} eq 'exception' ) {
                return bless $tx->{message}, 'Pcore::Lib::Result::Class';
            }
            elsif ( $tx->{type} eq 'rpc' ) {
                return bless $tx->{result}, 'Pcore::Lib::Result::Class';
            }
        }
    }
}

sub _send_ws ( $self, $method, $args ) {
    my ( $ws, $error ) = $self->_get_ws;

    return $error if defined $error;

    return $ws->rpc_call( $method, $args );
}

sub _get_ws ( $self ) {
    return $self->{_ws} if $self->{_ws};

    if ( $self->{_get_ws_exec} ) {
        my $cv = P->cv;

        push $self->{_get_ws_queue}->@*, $cv;

        $cv->recv;

        return;
    }

    $self->{_get_ws_exec} = 1;

    weaken $self;

    my $cv = P->cv;

    Pcore::WebSocket->connect_ws(
        $self->{uri},
        protocol         => 'pcore',
        max_message_size => 0,
        compression      => $self->{compression},
        connect_timeout  => $self->{connect_timeout},
        tls_ctx          => $self->{tls_ctx},
        before_connect   => {
            token          => $self->{token},
            bind_events    => $self->{bind_events},
            forward_events => $self->{forward_events},
        },
        on_listen_event => sub ( $ws, $mask ) {    # API server can listen client events
            return 1;
        },
        on_fire_event => sub ( $ws, $key ) {       # API server can fire client events
            return 1;
        },
        on_connect_error => sub ($res) {
            $cv->( undef, $res );

            return;
        },
        on_connect => sub ( $ws, $headers ) {
            $self->{_ws} = $ws;

            $self->{on_connect}->( $self, $headers ) if defined $self->{on_connect};

            $cv->( $ws, undef );

            return;
        },
        on_disconnect => sub ( $ws, $status ) {
            undef $self->{_ws};

            $self->{on_disconnect}->( $self, $status ) if $self && $self->{on_disconnect};

            return;
        },
        on_ping => do {
            if ( $self->{on_ping} ) {
                sub ( $ws, $payload_ref ) {
                    $self->{on_ping}->( $self, $payload_ref ) if $self && $self->{on_ping};

                    return;
                };
            }
        },
        on_pong => do {
            if ( $self->{on_pong} ) {
                sub ( $ws, $payload_ref ) {
                    $self->{on_pong}->( $self, $payload_ref ) if $self && $self->{on_pong};

                    return;
                };
            }
        },
        on_rpc => do {
            if ( $self->{on_rpc} ) {
                sub ( $ws, $req, $tx ) {
                    $self->{on_rpc}->( $self, $req, $tx ) if $self && $self->{on_rpc};

                    return;
                };
            }
        },
    );

    my ( $ws, $error ) = $cv->recv;

    $self->{_get_ws_exec} = 0;

    while ( my $cb = shift $self->{_get_ws_queue}->@* ) {
        $cb->( $ws, $error );
    }

    return $ws, $error;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Client

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
