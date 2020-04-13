package Pcore::API::Client;

use Pcore -class, -res;

# use Pcore::WebSocket;
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Pcore::Util::Data qw[to_cbor from_cbor to_json from_json];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::HTTP qw[:TLS_CTX];

has uri => ( required => 1 );    # InstanceOf ['Pcore::Util::URI'], http://token@host:port/api/, ws://token@host:port/api/

has token    => ();
has api_ver  => ();              # eg: 'v1', default API version for relative methods
has use_json => ();

has timeout         => ();
has connect_timeout => 10;
has tls_ctx         => $TLS_CTX_HIGH;    # Maybe [ HashRef | Enum [ $TLS_CTX_LOW, $TLS_CTX_HIGH ] ]
has bind_ip         => ();

# WebSocket options
has bindings         => ();
has max_message_size => 1_024 * 1_024 * 100;
has compression      => 0;
has on_connect       => ();                    # Maybe [CodeRef]
has on_disconnect    => ();                    # Maybe [CodeRef]
has on_bind          => ();                    # Maybe [CodeRef]
has on_event         => ();                    # Maybe [CodeRef]
has on_rpc           => ();                    # Maybe [CodeRef]
has on_ping          => ();                    # Maybe [CodeRef]
has on_pong          => ();                    # Maybe [CodeRef]

has _is_http => ( required => 1 );

has _ws             => ( init_arg => undef );
has _get_ws_threads => ( init_arg => undef );
has _get_ws_queue   => ( init_arg => undef );

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
    if ( ( $token // $EMPTY ) ne ( $self->{token} // $EMPTY ) ) {
        $self->{token} = $token;

        my $h = $self->{_ws};

        $h->auth($token) if defined $h;
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
        tls_ctx         => $self->{tls_ctx},
        ( $self->{timeout} ? ( timeout => $self->{timeout} ) : () ),
        headers => [
            Referer        => undef,
            Authorization  => "Token $self->{token}",
            'Content-Type' => $self->{use_json} ? 'application/json' : 'application/cbor',
        ],
        data => $self->{use_json} ? to_json $payload : to_cbor $payload
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
                return bless $tx->{message}, 'Pcore::Util::Result::Class';
            }
            elsif ( $tx->{type} eq 'rpc' ) {
                return bless $tx->{result}, 'Pcore::Util::Result::Class';
            }
        }
    }
}

sub _send_ws ( $self, $method, $args ) {
    my $ws = $self->_get_ws;

    return $ws->rpc_call( $method, $args->@* );
}

sub _get_ws ( $self ) {
    return $self->{_ws} if $self->{_ws};

    if ( $self->{_get_ws_threads} ) {
        my $cv = P->cv;

        push $self->{_get_ws_queue}->@*, $cv;

        return $cv->recv;
    }

    $self->{_get_ws_threads} = 1;

    my $h = Pcore::WebSocket::softvisio->connect(
        $self->{uri},

        # connection
        timeout         => $self->{timeout} // 30,
        connect_timeout => $self->{connect_timeout},
        tls_ctx         => $self->{tls_ctx},
        bind_ip         => $self->{bind_ip},

        # websocket
        max_message_size => $self->{max_message_size},
        compression      => $self->{compression},

        # pcore websocket
        use_json      => $self->{use_json},
        token         => $self->{token},
        bindings      => $self->{bindings},
        on_disconnect => sub { delete $self->{_ws} },
        on_bind       => $self->{on_bind},
        on_event      => $self->{on_event},
        on_rpc        => $self->{on_rpc},
    );

    $self->{_ws} = $h if $h;

    $self->{_get_ws_threads} = 0;

    while ( my $cb = shift $self->{_get_ws_queue}->@* ) {
        $cb->($h);
    }

    return $h;
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
