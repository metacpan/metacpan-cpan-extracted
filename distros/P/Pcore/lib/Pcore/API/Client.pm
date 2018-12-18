package Pcore::API::Client;

use Pcore -class, -res;
use Pcore::WebSocket;
use Pcore::Util::Scalar qw[is_callback is_plain_arrayref is_plain_coderef weaken];
use Pcore::Util::Data qw[to_cbor from_cbor];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::HTTP qw[:TLS_CTX];

has uri => ( required => 1 );    # InstanceOf ['Pcore::Util::URI'], http://token@host:port/api/, ws://token@host:port/api/

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

has _get_ws_cb => ( init_arg => undef );
has _ws        => ( init_arg => undef );

sub DESTROY ( $self ) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {
        $self->{_ws}->disconnect if $self->{_ws};
    }

    return;
}

around BUILDARGS => sub ( $orig, $self, $uri, @ ) {
    my %args = ( splice @_, 3 );

    $args{uri} = P->uri($uri);

    $args{token} = $args{uri}->{userinfo} if !$args{token};

    $args{_is_http} = $args{uri}->{is_http};

    return $self->$orig( \%args );
};

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
            die q[You need to defined default "api_ver" to use relative methods names];
        }
    }

    # parse callback
    my $cb = is_plain_coderef $_[-1] || is_callback $_[-1] ? pop : undef;

    if ( defined wantarray ) {
        my $cv = P->cv;

        if ( $self->{_is_http} ) {
            $self->_send_http( $method, \@args, $cv );
        }
        else {
            $self->_send_ws( $method, \@args, $cv );
        }

        my $res = $cv->recv;

        return $cb ? $cb->($res) : $res;
    }
    else {
        if ( $self->{_is_http} ) {
            $self->_send_http( $method, \@args, undef );
        }
        else {
            $self->_send_ws( $method, \@args, undef );
        }

        return;
    }
}

sub _send_http ( $self, $method, $args, $cb ) {
    my $payload = {
        type   => 'rpc',
        method => $method,
        data   => $args,
        ( $cb ? ( tid => uuid_v1mc_str ) : () ),
    };

    P->http->post(
        $self->{uri},
        connect_timeout => $self->{connect_timeout},
        persistent      => $self->{persistent},
        tls_ctx         => $self->{tls_ctx},
        ( $self->{timeout} ? ( timeout => $self->{timeout} ) : () ),
        headers => [
            Referer        => undef,
            Authorization  => "Token $self->{token}",
            'Content-Type' => 'application/cbor',
        ],
        data => to_cbor($payload),
        sub ($res) {
            if ( !$res ) {
                $cb->( res [ $res->{status}, $res->{reason} ] ) if $cb;
            }
            else {
                my $msg = eval { from_cbor $res->{data} };

                if ($@) {
                    $cb->( res [ 500, 'Error decoding response' ] ) if $cb;
                }
                elsif ($cb) {
                    my $tx = is_plain_arrayref $msg ? $msg->[0] : $msg;

                    if ( $tx->{type} eq 'exception' ) {
                        $cb->( bless $tx->{message}, 'Pcore::Util::Result::Class' );
                    }
                    elsif ( $tx->{type} eq 'rpc' ) {
                        $cb->( bless $tx->{result}, 'Pcore::Util::Result::Class' );
                    }
                }
            }

            return;
        },
    );

    return;
}

sub _send_ws ( $self, $method, $args, $cb ) {
    $self->_get_ws(
        sub ( $ws, $error ) {
            if ( defined $error ) {
                $cb->($error) if $cb;
            }
            else {
                $ws->rpc_call( $method, $args, $cb );
            }

            return;
        }
    );

    return;
}

sub _get_ws ( $self, $cb ) {
    if ( $self->{_ws} ) {
        $cb->( $self->{_ws}, undef );
    }
    else {
        push $self->{_get_ws_cb}->@*, $cb;

        return if $self->{_get_ws_cb}->@* > 1;

        weaken $self;

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
                while ( my $cb = shift $self->{_get_ws_cb}->@* ) {
                    $cb->( undef, $res );
                }

                return;
            },
            on_connect => sub ( $ws, $headers ) {
                $self->{_ws} = $ws;

                $self->{on_connect}->( $self, $headers ) if $self->{on_connect};

                while ( my $cb = shift $self->{_get_ws_cb}->@* ) {
                    $cb->( $ws, undef );
                }

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
    }

    return;
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
