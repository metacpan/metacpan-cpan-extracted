package Pcore::WebSocket::Protocol::pcore;

use Pcore -class, -result, -const;
use Pcore::Util::Data;
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Text qw[trim];
use Pcore::Util::Scalar qw[is_blessed_ref is_plain_arrayref weaken is_plain_coderef];
use Pcore::WebSocket::Protocol::pcore::Request;

has protocol => ( is => 'ro', isa => Str, default => 'pcore', init_arg => undef );

has on_rpc          => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $req, $tx)
has on_listen_event => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $mask), should return true if operation is allowed
has on_fire_event   => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $key), should return true if operation is allowed

has _listeners => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has _callbacks => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

with qw[Pcore::WebSocket::Handle];

const our $TX_TYPE_LISTEN    => 'listen';
const our $TX_TYPE_EVENT     => 'event';
const our $TX_TYPE_RPC       => 'rpc';
const our $TX_TYPE_EXCEPTION => 'exception';

my $CBOR = Pcore::Util::Data::get_cbor();
my $JSON = Pcore::Util::Data::get_json( utf8 => 1 );

sub rpc_call ( $self, $method, @ ) {
    my $msg = {
        type   => $TX_TYPE_RPC,
        method => $method,
    };

    # detect callback
    if ( is_plain_coderef $_[-1] || ( is_blessed_ref $_[-1] && $_[-1]->can('IS_CALLBACK') ) ) {
        $msg->{data} = [ @_[ 2 .. $#_ - 1 ] ];

        $msg->{tid} = uuid_v1mc_str;

        $self->{_callbacks}->{ $msg->{tid} } = $_[-1];
    }
    else {
        $msg->{data} = [ @_[ 2 .. $#_ ] ];
    }

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub forward_events ( $self, $masks ) {
    $self->_set_listeners($masks);

    return;
}

sub listen_events ( $self, $masks ) {
    my $msg = {
        type  => $TX_TYPE_LISTEN,
        masks => $masks,
    };

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub fire_remote_event ( $self, $key, $data = undef ) {
    my $msg = {
        type => $TX_TYPE_EVENT,
        ev   => {                 #
            key => $key,
        },
    };

    \$msg->{ev}->{data} = \$data;

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub forward_remote_event ( $self, $ev ) {
    my $msg = {
        type => $TX_TYPE_EVENT,
        ev   => $ev,
    };

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub before_connect_server ( $self, $env, $args ) {
    if ( $env->{HTTP_PCORE_LISTEN_EVENTS} ) {
        my $masks = [ map { trim $_} split /,/sm, $env->{HTTP_PCORE_LISTEN_EVENTS} ];

        $self->_set_listeners($masks) if $masks->@*;
    }

    if ( $args->{forward_events} ) {
        $self->_set_listeners( $args->{forward_events} );
    }

    my $headers;

    if ( $args->{headers} ) {
        push $headers->@*, $args->{headers}->@*;
    }

    if ( $args->{listen_events} ) {
        push $headers->@*, 'Pcore-Listen-Events', join ',', ( is_plain_arrayref $args->{listen_events} ? $args->{listen_events}->@* : $args->{listen_events} );
    }

    return $headers;
}

sub before_connect_client ( $self, $args ) {
    if ( $args->{forward_events} ) {
        $self->_set_listeners( $args->{forward_events} );
    }

    my $headers;

    if ( $args->{headers} ) {
        push $headers->@*, $args->{headers}->@*;
    }

    if ( $args->{listen_events} ) {
        push $headers->@*, 'Pcore-Listen-Events:' . join ',', ( is_plain_arrayref $args->{listen_events} ? $args->{listen_events}->@* : $args->{listen_events} );
    }

    if ( $args->{token} ) {
        push $headers->@*, "Authorization:Token $args->{token}";
    }

    return $headers;
}

sub on_connect_server ( $self ) {
    return;
}

sub on_connect_client ( $self, $headers ) {
    if ( $headers->{PCORE_LISTEN_EVENTS} ) {
        my $masks = [ map { trim $_} split /,/sm, $headers->{PCORE_LISTEN_EVENTS} ];

        $self->_set_listeners($masks) if $masks->@*;
    }

    return;
}

sub on_disconnect ( $self, $status ) {

    # clear listeners
    $self->{_listeners} = {};

    # call pending callback
    for my $tid ( keys $self->{_callbacks}->%* ) {
        my $cb = delete $self->{_callbacks}->{$tid};

        $cb->( result [ $status->{status}, $status->{reason} ] );
    }

    return;
}

sub on_text ( $self, $data_ref ) {
    my $msg = eval { $JSON->decode( $data_ref->$* ) };

    if ($@) {
        return;
    }

    $self->_on_message( $msg, 1 );

    return;
}

sub on_binary ( $self, $data_ref ) {
    my $msg = eval { $CBOR->decode( $data_ref->$* ) };

    if ($@) {
        return;
    }

    $self->_on_message( $msg, 0 );

    return;
}

sub _set_listeners ( $self, $masks ) {
    weaken $self;

    for my $mask ( is_plain_arrayref $masks ? $masks->@* : $masks ) {
        next if exists $self->{_listeners}->{$mask};

        # do not set event listener, if not authorized
        next if $self->{on_listen_event} && !$self->{on_listen_event}->( $self, $mask );

        $self->{_listeners}->{$mask} = P->listen_events(
            $mask,
            sub ( $ev ) {
                $self->forward_remote_event($ev) if $self;

                return;
            }
        );
    }

    return;
}

sub _on_message ( $self, $msg, $is_json ) {
    for my $tx ( is_plain_arrayref $msg ? $msg->@* : $msg ) {
        next if !$tx->{type};

        # forward local events to remote peer
        if ( $tx->{type} eq $TX_TYPE_LISTEN ) {
            $self->_set_listeners( $tx->{masks} );

            next;
        }

        # fire local event from remote call
        if ( $tx->{type} eq $TX_TYPE_EVENT ) {

            # ignore event, if not authorized
            next if $self->{on_fire_event} && !$self->{on_fire_event}->( $self, $tx->{ev}->{key} );

            P->forward_event( $tx->{ev} );

            next;
        }

        # exception
        if ( $tx->{type} eq $TX_TYPE_EXCEPTION ) {
            if ( $tx->{tid} ) {
                if ( my $cb = delete $self->{_callbacks}->{ $tx->{tid} } ) {

                    # convert result to response object
                    $cb->( bless $tx->{message}, 'Pcore::Util::Result' );
                }
            }

            next;
        }

        # RPC
        if ( $tx->{type} eq $TX_TYPE_RPC ) {

            # method is specified, this is rpc call
            if ( $tx->{method} ) {
                if ( !$self->{on_rpc} ) {
                    if ( $tx->{tid} ) {
                        my $result = {
                            type    => $TX_TYPE_EXCEPTION,
                            tid     => $tx->{tid},
                            message => result [ 500, 'RPC is not supported' ],
                        };

                        if ($is_json) {
                            $self->send_text( \$JSON->encode($result) );
                        }
                        else {
                            $self->send_binary( \$CBOR->encode($result) );
                        }
                    }
                }
                else {
                    my $req = bless {}, 'Pcore::WebSocket::Protocol::pcore::Request';

                    # callback is required
                    if ( $tx->{tid} ) {
                        my $weak_self = $self;

                        weaken $weak_self;

                        $req->{_cb} = sub ($res) {
                            return if !$weak_self;

                            my $result;

                            if ( $res->is_success ) {
                                $result = {
                                    type   => $TX_TYPE_RPC,
                                    tid    => $tx->{tid},
                                    result => $res,
                                };
                            }
                            else {
                                $result = {
                                    type    => $TX_TYPE_EXCEPTION,
                                    tid     => $tx->{tid},
                                    message => $res,
                                };
                            }

                            if ($is_json) {
                                $weak_self->send_text( \$JSON->encode($result) );
                            }
                            else {
                                $weak_self->send_binary( \$CBOR->encode($result) );
                            }

                            return;
                        };
                    }

                    # combine method with action
                    if ( my $action = delete $tx->{action} ) {
                        $tx->{method} = q[/] . ( $action =~ s[[.]][/]smgr ) . "/$tx->{method}";
                    }

                    $self->{on_rpc}->( $self, $req, $tx );
                }
            }

            # method is not specified, this is callback, tid is required
            elsif ( $tx->{tid} ) {
                if ( my $cb = delete $self->{_callbacks}->{ $tx->{tid} } ) {

                    # convert result to response object
                    $cb->( bless $tx->{result}, 'Pcore::Util::Result' );
                }
            }
        }
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
## |    3 | 216                  | Subroutines::ProhibitExcessComplexity - Subroutine "_on_message" with high complexity score (27)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 264, 286, 301        | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket::Protocol::pcore

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
