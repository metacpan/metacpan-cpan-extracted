package Pcore::WebSocket::pcore;

use Pcore -class, -const, -res;
use Pcore::WebSocket::pcore::Request;
use Pcore::Util::Data qw[to_b64];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Scalar qw[weaken is_plain_arrayref];
use Clone qw[];

with qw[Pcore::WebSocket::Handle];

# client attributes
has token            => ();    # authentication token
has forward_events   => ();    # Str or ArrayRef[Str]
has subscribe_events => ();    # Str or ArrayRef[Str]

# callbacks
has on_connect    => ();       # Maybe [CodeRef], ($self)
has on_disconnect => ();       # Maybe [CodeRef], ($self, $status)
has on_auth       => ();       # Maybe [CodeRef], server: ($self, $token, $cb), client: ($self, $auth)
has on_subscribe  => ();       # Maybe [CodeRef], ($self, $mask), must return true for subscribe to event
has on_event      => ();       # Maybe [CodeRef], ($self, $ev)
has on_rpc        => ();       # Maybe [CodeRef], ($self, $req, $tx)

has _peer_is_text => ();            # remote peer message serialization protocol
has _req_cb       => sub { {} };    # HashRef, tid => $cb
has _listeners    => ();            # HashRef, events listeners
has _conn_ver     => 0;             # increased on each reset call
has _auth_ver     => ();            # increased on each auth call on server

const our $PROTOCOL => 'pcore';

const our $TX_TYPE_AUTH        => 'auth';
const our $TX_TYPE_SUBSCRIBE   => 'subscribe';
const our $TX_TYPE_UNSUBSCRIBE => 'unsubscribe';
const our $TX_TYPE_EVENT       => 'event';
const our $TX_TYPE_RPC         => 'rpc';

my $CBOR = Pcore::Util::Data::get_cbor();
my $JSON = Pcore::Util::Data::get_json( utf8 => 1 );

sub auth ( $self, $token, %events ) {
    $self->{token} = $token;

    $self->{forward_events}   = $events{forward};
    $self->{subscribe_events} = $events{subscribe};

    $self->_send_msg( {
        type   => $TX_TYPE_AUTH,
        token  => $token,
        events => $self->{subscribe_events},
    } );

    return;
}

sub rpc_call ( $self, $method, $args, $cb ) {
    my $msg = {
        type   => $TX_TYPE_RPC,
        method => $method,
        args   => $args,
    };

    # detect callback
    if ($cb) {
        $msg->{tid} = uuid_v1mc_str;

        $self->{_req_cb}->{ $msg->{tid} } = $cb;
    }

    $self->_send_msg($msg);

    return;
}

# listen for remote events
sub subscribe ( $self, $events ) {
    $self->_send_msg( {
        type   => $TX_TYPE_SUBSCRIBE,
        events => $events,
    } );

    return;
}

# remove remote events subscription
sub unsubscribe ( $self, $events ) {
    $self->_send_msg( {
        type   => $TX_TYPE_UNSUBSCRIBE,
        events => $events,
    } );

    return;
}

sub _on_connect ($self) {
    $self->{on_connect}->($self) if $self->{on_connect};

    if ( $self->{_is_client} ) {
        $self->_send_msg( {
            type   => $TX_TYPE_AUTH,
            token  => $self->{token},
            events => $self->{subscribe_events},
        } );
    }

    return;
}

sub _on_disconnect ( $self, $status ) {
    $self->_reset($status);

    $self->{on_disconnect}->( $self, $status ) if $self->{on_disconnect};

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

        # SUBSCRIBE
        elsif ( $tx->{type} eq $TX_TYPE_SUBSCRIBE ) {
            $self->_on_subscribe( $tx->{events} ) if $tx->{events};
        }

        # UNSUBSCRIBE
        elsif ( $tx->{type} eq $TX_TYPE_UNSUBSCRIBE ) {
            if ( $tx->{events} ) {
                for my $event ( is_plain_arrayref $tx->{events} ? $tx->{events}->@* : $tx->{events} ) {
                    delete $self->{_listeners}->{$event};
                }
            }
        }

        # EVENT
        elsif ( $tx->{type} eq $TX_TYPE_EVENT ) {
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

                    $self->{on_rpc}->( $self, $req, $tx );
                }
            }

            # method is not specified, this is callback, tid is required
            elsif ( $tx->{tid} ) {
                if ( my $cb = delete $self->{_req_cb}->{ $tx->{tid} } ) {

                    # convert result to response object
                    $cb->( bless $tx->{result}, 'Pcore::Util::Result' );
                }
            }
        }
    }

    return;
}

# auth request, processed on server only
sub _on_auth_request ( $self, $tx ) {
    my $auth_ver = ++$self->{_auth_ver};

    if ( $self->{on_auth} ) {
        weaken $self;

        $self->{on_auth}->(
            $self,
            $tx->{token},
            sub ( $auth, %events ) {
                return if !$self;

                # skip, if other auth requests was received during authentication
                return if $self->{_auth_ver} != $auth_ver;

                $self->_reset;

                $self->{auth} = $auth;

                # subscribe client to the server events
                $self->_set_listeners( $events{forward} ) if $events{forward};

                # subscribe client to the server events from client request
                $self->_on_subscribe( $tx->{events} ) if $tx->{events};

                $self->_send_msg( {
                    type   => $TX_TYPE_AUTH,
                    auth   => $auth,
                    events => $events{subscribe},
                } );

                return;
            }
        );
    }

    # auth is not supported, reject
    else {
        $self->_reset;

        $self->{auth} = undef;

        $self->_send_msg( {
            type => $TX_TYPE_AUTH,
            auth => {
                status => 401,
                reason => 'Unauthorized',
            }
        } );
    }

    return;
}

# auth response, processed on client only
sub _on_auth_response ( $self, $tx ) {
    $self->_reset;

    # create auth object
    $self->{auth} = bless $tx->{auth}, 'Pcore::Util::Result';

    # set forward events
    $self->_set_listeners( $self->{forward_events} ) if $self->{forward_events};

    # set events listeners
    $self->_on_subscribe( $tx->{events} ) if $tx->{events};

    # call on_auth
    $self->{on_auth}->( $self, $self->{auth} ) if $self->{on_auth};

    return;
}

sub _on_subscribe ( $self, $events ) {
    if ( my $cb = $self->{on_subscribe} ) {
        for my $event ( is_plain_arrayref $events ? $events->@* : $events ) {
            next if !$event;

            next if exists $self->{_listeners}->{$event};

            $self->_set_listeners($event) if ( $cb->( $self, $event ) );
        }
    }

    return;
}

sub _set_listeners ( $self, $events ) {
    weaken $self;

    for my $event ( is_plain_arrayref $events ? $events->@* : $events ) {
        next if exists $self->{_listeners}->{$event};

        $self->{_listeners}->{$event} = P->listen_events(
            $event,
            sub ( $ev ) {
                if ( defined $self ) {
                    $self->_send_msg( {
                        type  => $TX_TYPE_EVENT,
                        event => $ev,
                    } );
                }

                return;
            }
        );
    }

    return;
}

sub _reset ( $self, $status = undef ) {
    delete $self->{auth};

    delete $self->{_listeners};

    $self->{_conn_ver}++;

    # call pending callbacks
    if ( $self->{_req_cb}->%* ) {
        $status = res [ 1012, $Pcore::WebSocket::Handle::WEBSOCKET_STATUS_REASON ] if !defined $status;

        for my $tid ( keys $self->{_req_cb}->%* ) {
            my $cb = delete $self->{_req_cb}->{$tid};

            $cb->( Clone::clone($status) );
        }
    }

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

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 96                   | * Private subroutine/method '_on_connect' declared but not used                                                |
## |      | 110                  | * Private subroutine/method '_on_disconnect' declared but not used                                             |
## |      | 118                  | * Private subroutine/method '_on_text' declared but not used                                                   |
## |      | 130                  | * Private subroutine/method '_on_binary' declared but not used                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 142                  | Subroutines::ProhibitExcessComplexity - Subroutine "_on_message" with high complexity score (27)               |
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
