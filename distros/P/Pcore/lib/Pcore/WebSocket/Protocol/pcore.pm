package Pcore::WebSocket::Protocol::pcore;

use Pcore -class, -result, -const;
use CBOR::XS qw[];
use Pcore::Util::UUID qw[uuid_str];
use Pcore::WebSocket::Protocol::pcore::Request;
use Pcore::Util::Text qw[trim];

has protocol => ( is => 'ro', isa => Str, default => 'pcore', init_arg => undef );

has on_rpc_call => ( is => 'ro', isa => CodeRef );    # ($h, $req, $method, $data)

has _listeners => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has _callbacks => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

with qw[Pcore::WebSocket::Handle];

const our $MSG_TYPE_LISTEN => 'listen';
const our $MSG_TYPE_EVENT  => 'event';
const our $MSG_TYPE_RPC    => 'rpc';

my $CBOR = do {
    my $cbor = CBOR::XS->new;

    $cbor->max_depth(512);
    $cbor->max_size(0);    # max. string size is unlimited
    $cbor->allow_unknown(0);
    $cbor->allow_sharing(1);
    $cbor->allow_cycles(1);
    $cbor->pack_strings(0);    # set to 1 affect speed, but makes size smaller
    $cbor->validate_utf8(0);
    $cbor->filter(undef);

    $cbor;
};

sub rpc_call ( $self, $method, @ ) {
    my $msg = {
        type   => $MSG_TYPE_RPC,
        method => $method,
    };

    if ( ref $_[-1] eq 'CODE' ) {
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
        type   => $MSG_TYPE_LISTEN,
        events => $events,
    };

    $self->send_binary( \$CBOR->encode($msg) );

    return;
}

sub fire_remote_event ( $self, $event, $data = undef ) {
    my $msg = {
        type  => $MSG_TYPE_EVENT,
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

    if ( $args->{listen_events} ) {
        my $events = ref $args->{listen_events} eq 'ARRAY' ? $args->{listen_events} : [ $args->{listen_events} ];

        push $headers->@*, 'Pcore-Listen-Events:' . join ',', $events->@*;
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
    return;
}

sub on_binary ( $self, $data_ref ) {
    my $msg = eval { $CBOR->decode( $data_ref->$* ) };

    if ($@) {
        return;
    }

    $self->_on_message($msg);

    return;
}

sub on_pong ( $self, $data_ref ) {
    return;
}

sub _set_listeners ( $self, $events ) {
    $events = [$events] if ref $events ne 'ARRAY';

    for my $event ( $events->@* ) {
        next if exists $self->{_listeners}->{$event};

        $self->{_listeners}->{$event} = P->listen_events(
            $event,
            sub ( $event, $data ) {
                $self->fire_remote_event( $event, $data );

                return;
            }
        );
    }

    return;
}

sub _on_message ( $self, $msg ) {
    return if !$msg->{type};

    if ( $msg->{type} eq $MSG_TYPE_LISTEN ) {
        $self->_set_listeners( $msg->{events} );
    }
    elsif ( $msg->{type} eq $MSG_TYPE_EVENT ) {
        P->fire_event( $msg->{event}, $msg->{data} );
    }
    elsif ( $msg->{type} eq $MSG_TYPE_RPC ) {

        # method is specified, this is rpc call
        if ( $msg->{method} ) {
            if ( $self->{on_rpc_call} ) {
                my $req = bless {}, 'Pcore::WebSocket::Protocol::pcore::Request';

                # callback is required
                if ( $msg->{tid} ) {
                    $req->{_cb} = sub ($res) {
                        my $msg = {
                            type   => $MSG_TYPE_RPC,
                            tid    => $msg->{tid},
                            result => $res,
                        };

                        $self->send_binary( \$CBOR->encode($msg) );

                        return;
                    };
                }

                $self->{on_rpc_call}->( $self, $req, $msg->{method}, $msg->{data} );
            }
        }

        # method is not specified, this is callback, tid is required
        elsif ( $msg->{tid} ) {
            if ( my $cb = delete $self->{_callbacks}->{ $msg->{tid} } ) {

                # convert result to response object
                $cb->( bless $msg->{result}, 'Pcore::Util::Result' );
            }
        }
    }

    return;
}

1;
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
