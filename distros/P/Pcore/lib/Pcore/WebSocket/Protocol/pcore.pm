package Pcore::WebSocket::Protocol::pcore;

use Pcore -class, -result, -const;
use JSON::XS qw[];    ## no critic qw[Modules::ProhibitEvilModules]
use CBOR::XS qw[];
use Pcore::Util::UUID qw[uuid_str];
use Pcore::WebSocket::Protocol::pcore::Request;
use Pcore::Util::Text qw[trim];
use Pcore::Util::Scalar qw[blessed weaken];

has protocol => ( is => 'ro', isa => Str, default => 'pcore', init_arg => undef );

has on_rpc          => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $req, $tx)
has on_listen_event => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $ev), should return true if operation is allowed
has on_fire_event   => ( is => 'ro', isa => Maybe [CodeRef] );    # ($ws, $ev), should return true if operation is allowed

has _listeners => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has _callbacks => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

with qw[Pcore::WebSocket::Handle];

const our $TX_TYPE_LISTEN    => 'listen';
const our $TX_TYPE_EVENT     => 'event';
const our $TX_TYPE_RPC       => 'rpc';
const our $TX_TYPE_EXCEPTION => 'exception';

my $CBOR = do {
    my $cbor = CBOR::XS->new;

    $cbor->max_depth(512);
    $cbor->max_size(0);    # max. string size is unlimited
    $cbor->allow_unknown(0);
    $cbor->allow_sharing(0);    # maust be disable for compatibility with JS CBOR
    $cbor->allow_cycles(1);
    $cbor->forbid_objects(0);
    $cbor->pack_strings(0);     # set to 1 decrease speed, but makes size smaller
    $cbor->text_keys(0);
    $cbor->text_strings(0);
    $cbor->validate_utf8(0);
    $cbor->filter(undef);

    $cbor;
};

my $JSON = do {
    my $json = JSON::XS->new;

    $json->utf8(1);
    $json->allow_nonref(1);    # allow scalars
    $json->allow_tags(0);      # use FREEZE / THAW, we don't use this, because non-standard JSON will be generated, use CBOR instead to serialize objects

    # shrink                        => 0,
    # max_depth                     => 512,

    # DECODE
    $json->relaxed(1);    # allows commas and # - style comments

    # filter_json_object            => undef,
    # filter_json_single_key_object => undef,
    # max_size                      => 0,

    # ENCODE
    $json->ascii(1);
    $json->latin1(0);

    # pretty       => 0,    # set indent, space_before, space_after
    $json->canonical(0);       # sort hash keys, slow
    $json->indent(0);
    $json->space_before(0);    # put a space before the ":" separating key from values
    $json->space_after(0);     # put a space after the ":" separating key from values, and after "," separating key-value pairs

    $json->allow_unknown(0);   # throw exception if can't encode item
    $json->allow_blessed(1);   # allow blessed objects
    $json->convert_blessed(1); # use TO_JSON method of blessed objects

    $json;
};

sub rpc_call ( $self, $method, @ ) {
    my $msg = {
        type   => $TX_TYPE_RPC,
        method => $method,
    };

    # detect callback
    if ( ref $_[-1] eq 'CODE' or ( blessed $_[-1] && $_[-1]->can('IS_CALLBACK') ) ) {
        $msg->{data} = [ @_[ 2 .. $#_ - 1 ] ];

        $msg->{tid} = uuid_str();

        $self->{_callbacks}->{ $msg->{tid} } = $_[-1];
    }
    else {
        $msg->{data} = [ @_[ 2 .. $#_ ] ];
    }

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub forward_events ( $self, $events ) {
    $self->_set_listeners($events);

    return;
}

sub listen_events ( $self, $events ) {
    my $msg = {
        type   => $TX_TYPE_LISTEN,
        events => $events,
    };

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub fire_remote_event ( $self, $event, $data = undef ) {
    my $msg = {
        type  => $TX_TYPE_EVENT,
        event => $event,
        data  => $data,
    };

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub before_connect_server ( $self, $env, $args ) {
    if ( $env->{HTTP_PCORE_LISTEN_EVENTS} ) {
        my $events = [ map { trim $_} split /,/sm, $env->{HTTP_PCORE_LISTEN_EVENTS} ];

        $self->_set_listeners($events) if $events->@*;
    }

    if ( $args->{forward_events} ) {
        $self->_set_listeners( $args->{forward_events} );
    }

    my $headers;

    if ( $args->{headers} ) {
        push $headers->@*, $args->{headers}->@*;
    }

    if ( $args->{listen_events} ) {
        my $events = ref $args->{listen_events} eq 'ARRAY' ? $args->{listen_events} : [ $args->{listen_events} ];

        push $headers->@*, 'Pcore-Listen-Events', join ',', $events->@*;
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
        my $events = ref $args->{listen_events} eq 'ARRAY' ? $args->{listen_events} : [ $args->{listen_events} ];

        push $headers->@*, 'Pcore-Listen-Events:' . join ',', $events->@*;
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
        my $events = [ map { trim $_} split /,/sm, $headers->{PCORE_LISTEN_EVENTS} ];

        $self->_set_listeners($events) if $events->@*;
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

sub _set_listeners ( $self, $events ) {
    $events = [$events] if ref $events ne 'ARRAY';

    weaken $self;

    for my $event ( $events->@* ) {
        next if exists $self->{_listeners}->{$event};

        # do not set event listener, if not authorized
        next if $self->{on_listen_event} && !$self->{on_listen_event}->( $self, $event );

        $self->{_listeners}->{$event} = P->listen_events(
            $event,
            sub ( $event, $data ) {
                $self->fire_remote_event( $event, $data ) if $self;

                return;
            }
        );
    }

    return;
}

sub _on_message ( $self, $msg, $is_json ) {
    $msg = [$msg] if ref $msg ne 'ARRAY';

    for my $tx ( $msg->@* ) {
        next if !$tx->{type};

        # forward local events to remote peer
        if ( $tx->{type} eq $TX_TYPE_LISTEN ) {
            $self->_set_listeners( $tx->{events} );

            next;
        }

        # fire local event from remote call
        if ( $tx->{type} eq $TX_TYPE_EVENT ) {

            # ignore event, if not authorized
            next if $self->{on_fire_event} && !$self->{on_fire_event}->( $self, $tx->{event} );

            P->fire_event( $tx->{event}, $tx->{data} );

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
## |    3 | 258                  | Subroutines::ProhibitExcessComplexity - Subroutine "_on_message" with high complexity score (27)               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 308, 330, 345        | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
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
