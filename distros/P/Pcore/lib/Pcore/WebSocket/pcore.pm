package Pcore::WebSocket::pcore;

use Pcore -class, -const, -res;
use Pcore::WebSocket::pcore::Request;
use Pcore::Util::Data qw[to_b64];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Scalar qw[is_callback weaken is_plain_arrayref is_plain_coderef];
use Clone qw[];

with qw[Pcore::WebSocket::Handle];

# client attributes
has token    => ();    # authentication token, used on client only
has bindings => ();    # events bindings, used on client only

# callbacks
has on_disconnect => ();    # Maybe [CodeRef], ($self, $status)
has on_auth       => ();    # Maybe [CodeRef], server only: ($self, $token)
has on_ready      => ();    # Maybe [CodeRef], server only: ($self), called after on_auth, not called, if was disconnected in on_auth callback
has on_bind       => ();    # Maybe [CodeRef], ($self, $bindings), must return true for bind event
has on_event      => ();    # Maybe [CodeRef], ($self, $ev)
has on_rpc        => ();    # Maybe [CodeRef], ($self, $req, $tx)

has _conn_ver     => ( 0, init_arg => undef );             # increased on each reset call
has _req_cb       => ( sub { {} }, init_arg => undef );    # HashRef, tid => $cb
has is_ready      => ( init_arg => undef );                # Bool
has _peer_is_text => ( init_arg => undef );                # remote peer message serialization protocol
has _listener     => ( init_arg => undef );                # ConsumerOf['Pcore::Core::Event::Listener']
has _auth_cb      => ( init_arg => undef );

const our $PROTOCOL => 'pcore';

const our $TX_TYPE_AUTH  => 'auth';
const our $TX_TYPE_EVENT => 'event';
const our $TX_TYPE_RPC   => 'rpc';

my $CBOR = Pcore::Util::Data::get_cbor();
my $JSON = Pcore::Util::Data::get_json( utf8 => 1 );

sub auth ( $self, $token, $bindings = undef ) {
    die q[Connection is not ready] if !$self->{is_ready};

    $self->{_auth_cb} = P->cv;

    $self->_reset;

    $self->{token}    = $token;
    $self->{bindings} = $bindings;

    $self->_send_msg( {
        type     => $TX_TYPE_AUTH,
        token    => $token,
        bindings => $bindings,
    } );

    $self->{_auth_cb}->recv;

    return $self;
}

sub rpc_call ( $self, $method, @args ) {

    # parse callback
    my $cb = is_callback $_[-1] ? pop @args : undef;

    if ( !$self->{is_ready} ) {
        my $res = res [ 500, 'Connection is not ready' ];

        if ( defined wantarray ) {
            if   ($cb) { return $cb->($res) }
            else       { return $res }
        }
        else {
            if ($cb) { $cb->($res) }

            return;
        }
    }
    else {
        my $msg = {
            type   => $TX_TYPE_RPC,
            method => $method,
            args   => \@args,
        };

        if ( defined wantarray ) {
            my $cv = P->cv;

            $msg->{tid} = uuid_v1mc_str;

            $self->{_req_cb}->{ $msg->{tid} } = sub ($res) { $cv->( $cb ? $cb->($res) : $res ) };

            $self->_send_msg($msg);

            return $cv->recv;
        }
        else {
            if ($cb) {
                $msg->{tid} = uuid_v1mc_str;

                $self->{_req_cb}->{ $msg->{tid} } = $cb;
            }

            $self->_send_msg($msg);

            return;
        }
    }
}

sub _on_connect ($self) {

    # create events listener
    $self->_create_listener;

    if ( $self->{_is_client} ) {
        $self->{_auth_cb} = P->cv;

        $self->_send_msg( {
            type     => $TX_TYPE_AUTH,
            token    => $self->{token},
            bindings => $self->{bindings},
        } );

        $self->{_auth_cb}->recv;

        return $self;
    }
    else {
        return $self;
    }
}

sub _on_disconnect ( $self ) {
    $self->_reset( res [ $self->{status}, $self->{reason} ] );

    $self->{on_disconnect}->($self) if $self->{on_disconnect};

    return;
}

sub _on_text ( $self, $data_ref ) {
    my $msg = eval { $JSON->decode( $data_ref->$* ) };

    return if $@;

    $self->{_peer_is_text} //= 1;

    $self->_on_message($msg);

    return;
}

sub _on_binary ( $self, $data_ref ) {
    my $msg = eval { $CBOR->decode( $data_ref->$* ) };

    return if $@;

    $self->{_peer_is_text} //= 0;

    $self->_on_message($msg);

    return;
}

sub _on_message ( $self, $msg ) {
    for my $tx ( is_plain_arrayref $msg ? $msg->@* : $msg ) {
        next if !$tx->{type};

        # AUTH
        if ( $tx->{type} eq $TX_TYPE_AUTH ) {

            # auth response, processed on client only
            if ( $tx->{auth} ) {
                $self->_on_auth_response($tx) if $self->{_is_client};
            }

            # auth request, processed on server only
            else {
                $self->_on_auth_request($tx) if !$self->{_is_client};
            }
        }

        # connection is NOT IN the ready state
        elsif ( !$self->{is_ready} ) {

            # 1002 Protocol error
            $self->disconnect( res [ 1012, $Pcore::WebSocket::Handle::WEBSOCKET_STATUS_REASON ] );
        }

        # connection is IN the ready state
        else {

            # EVENT
            if ( $tx->{type} eq $TX_TYPE_EVENT ) {
                $self->{on_event}->( $self, $tx->{event} ) if $self->{on_event};
            }

            # RPC
            elsif ( $tx->{type} eq $TX_TYPE_RPC ) {

                # method is specified, this is rpc call
                if ( $tx->{method} ) {

                    # RPC calls are not supported by this peer
                    if ( !$self->{on_rpc} ) {
                        if ( $tx->{tid} ) {
                            $self->_send_msg( {
                                type   => $TX_TYPE_RPC,
                                tid    => $tx->{tid},
                                result => {
                                    status => 400,
                                    reason => 'RPC calls are not supported',
                                }
                            } );
                        }
                    }

                    # RPC call
                    else {
                        my $req = bless {}, 'Pcore::WebSocket::pcore::Request';

                        # callback is required
                        if ( my $tid = $tx->{tid} ) {
                            my $weak_self = $self;

                            weaken $weak_self;

                            # store current _conn_ver
                            my $conn_ver = $self->{_conn_ver};

                            $req->{_cb} = sub ($res) {
                                return if !defined $weak_self;

                                # check _conn_ver, skip, if connection was reset during rpc call
                                return if $conn_ver != $self->{_conn_ver};

                                $self->_send_msg( {
                                    type   => $TX_TYPE_RPC,
                                    tid    => $tid,
                                    result => $res,
                                } );

                                return;
                            };
                        }

                        Coro::async_pool { $self->{on_rpc}->( $self, $req, $tx ) }->cede_to;
                    }
                }

                # method is not specified, this is callback, tid is required
                elsif ( $tx->{tid} ) {
                    if ( my $cb = delete $self->{_req_cb}->{ $tx->{tid} } ) {

                        # convert result to response object
                        $cb->( bless $tx->{result}, 'Pcore::Util::Result::Class' );
                    }
                }
            }
        }
    }

    return;
}

# server, auth request
sub _on_auth_request ( $self, $tx ) {
    $self->_reset;

    my $conn_ver = $self->{_conn_ver};

    if ( $self->{on_auth} ) {
        weaken $self;

        Coro::async_pool {
            my ( $auth, $bindings ) = $self->{on_auth}->( $self, $tx->{token} );

            return if !$self;

            return if $conn_ver != $self->{_conn_ver};

            $self->{is_ready} = 1;

            # store authentication result
            $self->{auth} = $auth;

            # subscribe client to the server events from client request
            $self->_bind_events( $tx->{bindings} ) if defined $tx->{bindings};

            $self->_send_msg( {
                type     => $TX_TYPE_AUTH,
                auth     => $auth,
                bindings => $bindings,
            } );

            $self->{on_ready}->($self) if $self->{on_ready};

            return;
        }
        ->cede_to;
    }

    # auth is not supported, reject
    else {
        $self->{is_ready} = 1;

        $self->{auth} = undef;

        $self->_send_msg( {
            type => $TX_TYPE_AUTH,
            auth => {
                status => 401,
                reason => 'Unauthorized',
            }
        } );

        $self->{on_ready}->($self) if $self->{on_ready};
    }

    return;
}

# client, auth response
sub _on_auth_response ( $self, $tx ) {
    $self->{is_ready} = 1;

    # create and store auth object
    $self->{auth} = bless $tx->{auth}, 'Pcore::Util::Result::Class';

    # set events listeners
    $self->_bind_events( $tx->{bindings} ) if defined $tx->{bindings};

    # call on_auth
    if ( my $cb = delete $self->{_auth_cb} ) { $cb->() }

    return;
}

sub _bind_events ( $self, $bindings ) {

    # process bindings if has "on_bind" callback defined
    if ( my $cb = $self->{on_bind} ) {
        for my $binding ( is_plain_arrayref $bindings ? $bindings->@* : $bindings ) {
            next if !defined $binding;

            # already bound
            next if exists $self->{_listener}->{bindings}->{$binding};

            $self->{_listener}->bind($binding) if $cb->( $self, $binding );
        }
    }

    return;
}

sub _reset ( $self, $status = undef ) {
    delete $self->{auth};

    # reset events listener
    $self->{_listener}->unbind_all if defined $self->{_listener};

    $self->{is_ready} = 0;
    $self->{_conn_ver}++;

    # call pending callbacks
    if ( $self->{_req_cb}->%* ) {

        # 1012 Service Restart
        $status = res [ 1012, $Pcore::WebSocket::Handle::WEBSOCKET_STATUS_REASON ] if !defined $status;

        for my $tid ( keys $self->{_req_cb}->%* ) {
            my $cb = delete $self->{_req_cb}->{$tid};

            $cb->( Clone::clone($status) );
        }
    }

    # call auth callback
    if ( my $cb = delete $self->{_auth_cb} ) { $cb->() }

    return;
}

sub _send_msg ( $self, $msg ) {
    if ( $self->{_peer_is_text} ) {
        $self->send_text( \$JSON->encode($msg) );
    }
    else {
        $self->send_binary( \$CBOR->encode($msg) );
    }

    return;
}

sub _create_listener ($self) {
    weaken $self;

    $self->{_listener} = P->ev->bind_events(
        undef,
        sub ($ev) {
            return if !defined $self;

            $self->_send_msg( {
                type  => $TX_TYPE_EVENT,
                event => $ev,
            } );

            return;
        }
    );

    return;
}

sub suspend_events ($self) {
    $self->{_listener}->suspend;

    return;
}

sub resume_events ($self) {
    $self->{_listener}->resume;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 111                  | * Private subroutine/method '_on_connect' declared but not used                                                |
## |      | 134                  | * Private subroutine/method '_on_disconnect' declared but not used                                             |
## |      | 142                  | * Private subroutine/method '_on_text' declared but not used                                                   |
## |      | 154                  | * Private subroutine/method '_on_binary' declared but not used                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 166                  | Subroutines::ProhibitExcessComplexity - Subroutine "_on_message" with high complexity score (23)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 207, 224             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::pcore

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
